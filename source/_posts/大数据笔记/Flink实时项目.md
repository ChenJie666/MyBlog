---
title: Flink实时项目
categories:
- 大数据笔记
---
##准备
**依赖**
```xml
    <properties>
        <flink.version>1.12.0</flink.version>
        <scala.binary.version>2.11</scala.binary.version>
        <kafka.version>2.2.0</kafka.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-streaming-scala_${scala.binary.version}</artifactId>
            <version>${flink.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-clients_${scala.binary.version}</artifactId>
            <version>${flink.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-table-api-scala-bridge_${scala.binary.version}</artifactId>
            <version>${flink.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-table-planner-blink_${scala.binary.version}</artifactId>
            <version>${flink.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-cep-scala_${scala.binary.version}</artifactId>
            <version>${flink.version}</version>
        </dependency>

        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-connector-kafka_${scala.binary.version}</artifactId>
            <version>${flink.version}</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>net.alchim31.maven</groupId>
                <artifactId>scala-maven-plugin</artifactId>
                <version>4.4.0</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>compile</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <artifactId>maven-assembly-plugin</artifactId>
                <configuration>
                    <descriptorRefs>
                        <descriptorRef>jar-with-dependencies</descriptorRef>
                    </descriptorRefs>
                </configuration>
                <executions>
                    <execution>
                        <id>make-assembly</id>
                        <phase>package</phase>
                        <goals>
                            <goal>single</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
```

**工具类**
将文件写入到Kakfa中
```scala
object KafkaProducerUtil {
  def main(args:Array[String]):Unit = {
    writeToKafka("hotitems")
  }

  def writeToKafka(topic: String): Unit = {
    val properties = new Properties()
    properties.setProperty("bootstrap.servers","192.168.32.242:9092")
    properties.setProperty("key.serializer","org.apache.kafka.common.serialization.StringSerializer")
    properties.setProperty("value.serializer","org.apache.kafka.common.serialization.StringSerializer")

    val producer = new KafkaProducer[String, String](properties)

    // 从文件读取数据，逐行写入kafka
    val bufferedSource = io.Source.fromFile("C:\Users\Administrator\Desktop\不常用的项目\UserBehaviorAnalysis\HotItemsAnalysis\src\main\resources\UserBehavior.csv")

    for (line <- bufferedSource.getLines()) {
      val record = new ProducerRecord[String, String](topic, line)
      producer.send(record)
    }

    producer.close()
  }

}
```

<br>
##需求一：每五秒钟输出最近一个小时的topN点击商品  
>步骤：1.转换为样例类，设置水位线 2.过滤点击事件，开1小时5分钟的滑动窗口对同类商品进行聚合 3.对同窗口的商品进行排序
>从Kafka中读取数据，指定时间戳为EventTime，默认为顺序数据，水位线与事件时间持平。
- 以下是通过DataStream的API实现
```scala
package com.hxr.hotitems_analysis

import java.sql.Timestamp
import java.util.Properties

import org.apache.flink.api.common.functions.AggregateFunction
import org.apache.flink.api.common.serialization.SimpleStringSchema
import org.apache.flink.api.common.state.{ListState, ListStateDescriptor}
import org.apache.flink.api.java.tuple.{Tuple, Tuple1}
import org.apache.flink.configuration.Configuration
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.api.scala.function.WindowFunction
import org.apache.flink.streaming.api.windowing.time.Time
import org.apache.flink.streaming.api.windowing.windows.TimeWindow
import org.apache.flink.streaming.connectors.kafka.FlinkKafkaConsumer
import org.apache.flink.util.Collector

import scala.collection.mutable.ListBuffer

/**
 * @Description: 需求：每五秒钟输出最近一个小时的topN点击商品  (步骤：1.转换为样例类，设置水位线 2.过滤点击事件，开1小时5分钟的滑动窗口对同类商品进行聚合 3.对同窗口的商品进行排序)
 * @Author: CJ
 * @Data: 2020/12/25 16:42
 */
// 定义输入数据样例类
case class UserBehavior(userId: Long, itemId: Long, catagoryId: Int, behavior: String, timestamp: Long)

// 定义窗口聚合结果样例类
case class ItemViewCount(itemId: Long, windowEnd: Long, count: Long)

object Hotitems {
  def main(args: Array[String]): Unit = {
    val env: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(1)
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

    // 从文件中读取数据并转换成样例类,并指定当前时间戳为事件时间
    //    val inputStream: DataStream[String] = env.readTextFile("C:\Users\Administrator\Desktop\不常用的项目\UserBehaviorAnalysis\HotItemsAnalysis\src\main\resources\UserBehavior.csv")
    // 从Kafka中读取数据
    val properties = new Properties()
    properties.setProperty("bootstrap.servers", "192.168.32.242:9092")
    properties.setProperty("group.id","consumer-group")
    properties.setProperty("key.deserializer","org.apache.kafka.common.serialization.StringDeserializer")
    properties.setProperty("value.deserializer","org.apache.kafka.common.serialization.StringDeserializer")
    val myConsumer = new FlinkKafkaConsumer[String]("hotitems", new SimpleStringSchema(), properties)
    // myConsumer.setStartFromEarliest() // 从头开始读取
    myConsumer.setStartFromLatest() // 从末尾开始读取

    val inputStream = env.addSource(myConsumer)

    val dataStream: DataStream[UserBehavior] = inputStream
      .map(data => {
        val split = data.split(",")
        UserBehavior(split(0).toLong, split(1).toLong, split(2).toInt, split(3), split(4).toLong)
      })
      .assignAscendingTimestamps(_.timestamp * 1000L)

    // 得到窗口的聚合结果
    val aggStream: DataStream[ItemViewCount] = dataStream
      .filter(_.behavior == "pv") // 过滤pv行为
      .keyBy("itemId")
      .timeWindow(Time.hours(1), Time.minutes(5))
      .aggregate(new CountAgg(), new ItemViewWindowResult())

    //
    val resultStream = aggStream
      .keyBy("windowEnd")
      .process(new TopNHotItems(10))

    resultStream.print()

    env.execute("hot items")
  }
}

// 自定义预聚合函数Aggregate
class CountAgg() extends AggregateFunction[UserBehavior, Long, Long] {
  override def createAccumulator: Long = 0L

  override def add(in: UserBehavior, acc: Long): Long = acc + 1

  override def getResult(acc: Long): Long = acc

  override def merge(acc1: Long, acc2: Long): Long = acc1 + acc2
}

// 自定义窗口全局函数
class ItemViewWindowResult extends WindowFunction[Long, ItemViewCount, Tuple, TimeWindow] {
  def apply(key: Tuple, window: TimeWindow, input: Iterable[Long], out: Collector[ItemViewCount]): Unit = {
    val itemId = key.asInstanceOf[Tuple1[Long]].f0 // 因为key只有一个，所以Tuple是Tuple1类型的，转型后获取值
    val windowEnd = window.getEnd // 获取窗口的结束时间
    val count = input.iterator.next() // 全局窗口函数会记录所有的输入值，此处是传入的acc值，只有一个

    out.collect(ItemViewCount(itemId, windowEnd, count))
  }
}

// 自定义的KeyedProcessFunction,进行状态编程
class TopNHotItems(topSize: Int) extends KeyedProcessFunction[Tuple, ItemViewCount, String] {

  // 先定义状态： ListState
  private var itemViewCountListState: ListState[ItemViewCount] = _

  override def open(parameters: Configuration): Unit = {
    // 初始化状态
    itemViewCountListState = getRuntimeContext.getListState(new ListStateDescriptor[ItemViewCount]("itemViewCountList", classOf[ItemViewCount]))
  }

  // 数据处理并设置定时器
  override def processElement(value: ItemViewCount, ctx: KeyedProcessFunction[Tuple, ItemViewCount, String]#Context, out: Collector[String]): Unit = {
    //每来一条数据，直接加入ListState
    itemViewCountListState.add(value)
    //注册一个windowEnd + 1 之后出发的定时器
    ctx.timerService().registerEventTimeTimer(value.windowEnd + 1)
  }

  // 出发定时器时处理
  override def onTimer(timestamp: Long, ctx: KeyedProcessFunction[Tuple, ItemViewCount, String]#OnTimerContext, out: Collector[String]): Unit = {
    val allItemViewCounts: ListBuffer[ItemViewCount] = ListBuffer()

    val iter = itemViewCountListState.get().iterator()
    while (iter.hasNext) {
      allItemViewCounts += iter.next()
    }

    itemViewCountListState.clear()

    // 获取前topSize名的商品
    val sortedItemViewCounts = allItemViewCounts.sortBy(_.count)(Ordering.Long.reverse).take(topSize) // 科里化

    // 格式化为String类型
    val result: StringBuffer = new StringBuffer
    result.append("窗口结束时间: ").append(new Timestamp(timestamp - 1)).append("
")
    for (i <- sortedItemViewCounts.indices) {
      val currentItemViewCount = sortedItemViewCounts(i)
      result.append("NO").append(i + 1).append(": 	")
        .append("商品ID = ").append(currentItemViewCount.itemId).append("	")
        .append("热门度 = ").append(currentItemViewCount.count).append("
")
    }

    result.append("====================================

")

    Thread.sleep(1000)

    out.collect(result.toString)
  }

}
```

- 以下是通过Table API和SQL实现
```scala
package com.hxr.networkflowanalysis

import java.net.Socket
import java.sql.Timestamp
import java.text.SimpleDateFormat

import org.apache.flink.api.common.functions.AggregateFunction
import org.apache.flink.api.common.state.{ListState, ListStateDescriptor}
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.streaming.api.functions.timestamps.BoundedOutOfOrdernessTimestampExtractor
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.api.scala.function.WindowFunction
import org.apache.flink.streaming.api.windowing.time.Time
import org.apache.flink.streaming.api.windowing.windows.TimeWindow
import org.apache.flink.util.Collector

import scala.collection.mutable.ListBuffer

/**
 * @Description: 热门页面浏览量统计
 * @Author: CJ
 * @Data: 2020/12/28 15:27
 */
case class ApacheLogEvent(ip: String, userId: String, timestamp: Long, method: String, url: String)

case class PageViewCount(url: String, windowEnd: Long, cnt: Long)

object HotPagesNetworkFlow {
  def main(args: Array[String]): Unit = {
    val env: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(1)
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

    //    val inputStream = env.readTextFile("C:\Users\Administrator\Desktop\不常用的项目\UserBehaviorAnalysis\NetworkFlowAnalysis\src\main\resources\apache.log")
    val inputStream = env.socketTextStream("192.168.32.242", 7777)
    val dataStream = inputStream.map(data => {
      val arr = data.split(" ")
      val ts = new SimpleDateFormat("dd/MM/yyyy:HH:mm:ss").parse(arr(3)).getTime
      ApacheLogEvent(arr(0), arr(1), ts, arr(5), arr(6))
    })
      .assignTimestampsAndWatermarks(new BoundedOutOfOrdernessTimestampExtractor[ApacheLogEvent](Time.minutes(1)) {
        override def extractTimestamp(element: ApacheLogEvent): Long = element.timestamp
      })

    val aggStream = dataStream
      .filter(_.method == "GET")
      .filter(data => {
        val pattern = "^((?!\.(css|js)$).)*$".r
        (pattern findFirstIn data.url).nonEmpty
      })
      .keyBy(_.url)
      .timeWindow(Time.minutes(10), Time.seconds(5))
      .aggregate(new PageCountAgg(), new PageViewCountWindowResult())

    val resultStream = aggStream
      .keyBy(_.windowEnd)
      .process(new TopNHotPages(10))

    dataStream.print("dataStream")
    aggStream.print("aggStream")
    resultStream.print("resultStream")

    env.execute("hot page")
  }
}

class PageCountAgg() extends AggregateFunction[ApacheLogEvent, Long, Long] {
  def createAccumulator: Long = 0

  def add(in: ApacheLogEvent, acc: Long): Long = acc + 1

  def getResult(acc: Long): Long = acc

  def merge(acc1: Long, acc2: Long): Long = acc1 + acc2
}

class PageViewCountWindowResult() extends WindowFunction[Long, PageViewCount, String, TimeWindow] {
  override def apply(key: String, window: TimeWindow, input: Iterable[Long], out: Collector[PageViewCount]): Unit = {
    out.collect(PageViewCount(key, window.getEnd, input.iterator.next()))
  }
}

class TopNHotPages(topSize: Int) extends KeyedProcessFunction[Long, PageViewCount, String] {

  lazy val pageViewCountListState: ListState[PageViewCount] = getRuntimeContext.getListState(new ListStateDescriptor[PageViewCount]("pageViewCount-list", classOf[PageViewCount]))

  override def processElement(input: PageViewCount, ctx: KeyedProcessFunction[Long, PageViewCount, String]#Context, out: Collector[String]): Unit = {
    pageViewCountListState.add(input)
    ctx.timerService().registerProcessingTimeTimer(input.windowEnd + 1)
  }

  override def onTimer(timestamp: Long, ctx: KeyedProcessFunction[Long, PageViewCount, String]#OnTimerContext, out: Collector[String]): Unit = {
    val allPageListCounts: ListBuffer[PageViewCount] = ListBuffer()
    val iterator = pageViewCountListState.get().iterator()
    while (iterator.hasNext) {
      allPageListCounts += iterator.next()
    }

    pageViewCountListState.clear()

    // 排序
    val sortedPageListCounts = allPageListCounts.sortWith(_.cnt > _.cnt).take(topSize)
    // 格式化为String类型
    val result: StringBuffer = new StringBuffer
    result.append("窗口结束时间: ").append(new Timestamp(timestamp - 1)).append("
")
    for (i <- sortedPageListCounts.indices) {
      val currentPageCounts = sortedPageListCounts(i)
      result.append("NO").append(i + 1).append(": 	")
        .append("页面url = ").append(currentPageCounts.url).append("	")
        .append("热门度 = ").append(currentPageCounts.cnt).append("
")
    }

    result.append("====================================

")

    Thread.sleep(1000)

    out.collect(result.toString)
  }
}
```

##需求二：热门页面浏览量统计

- 以下是通过DataStream的API实现
>**原流程：**从文件读取数据，设定为事件时间，水位线延迟时间为1m，滑动窗口大小为10m，步长为5s。先根据url和窗口进行预聚合，然后设置定时器为对同一窗口中的数据进行排序取TopN。
>**改进后：**为了快速处理出结果，将水位线延迟时间设为1s，`允许最大延迟时间`为1m，1m外的数据放入`侧输出流`中。滑动窗口大小还是为10m，步长为5s。
>需要注意的是，迟到数据也会触发预聚合输出累加器的结果，定时器中需要再次进行排序，因此状态只能在该窗口关闭时进行清空。且为了防止url重复，需要保存url和count的值，因此使用MapState。
```scala
package com.hxr.networkflowanalysis

import java.sql.Timestamp
import java.text.SimpleDateFormat

import org.apache.flink.api.common.functions.AggregateFunction
import org.apache.flink.api.common.state.{ListState, ListStateDescriptor, MapState, MapStateDescriptor}
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.streaming.api.functions.timestamps.BoundedOutOfOrdernessTimestampExtractor
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.api.scala.function.WindowFunction
import org.apache.flink.streaming.api.windowing.time.Time
import org.apache.flink.streaming.api.windowing.windows.TimeWindow
import org.apache.flink.util.Collector

import scala.collection.mutable.ListBuffer

/**
 * @Description: 热门页面浏览量统计
 * @Author: CJ
 * @Data: 2020/12/28 15:27
 */
case class ApacheLogEvent(ip: String, userId: String, timestamp: Long, method: String, url: String)

case class PageViewCount(url: String, windowEnd: Long, cnt: Long)

object HotPagesNetworkFlow {
  def main(args: Array[String]): Unit = {
    val env: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(1)
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

    //    val inputStream = env.readTextFile("C:\Users\Administrator\Desktop\不常用的项目\UserBehaviorAnalysis\NetworkFlowAnalysis\src\main\resources\apache.log")
    val inputStream = env.socketTextStream("192.168.32.242", 7777)
    val dataStream = inputStream.map(data => {
      val arr = data.split(" ")
      val ts = new SimpleDateFormat("dd/MM/yyyy:HH:mm:ss").parse(arr(3)).getTime
      ApacheLogEvent(arr(0), arr(1), ts, arr(5), arr(6))
    })
      .assignTimestampsAndWatermarks(new BoundedOutOfOrdernessTimestampExtractor[ApacheLogEvent](Time.seconds(1)) {
        override def extractTimestamp(element: ApacheLogEvent): Long = element.timestamp
      })

    val aggStream = dataStream
      .filter(_.method == "GET")
      .filter(data => {
        val pattern = "^((?!\.(css|js)$).)*$".r
        (pattern findFirstIn data.url).nonEmpty
      })
      .keyBy(_.url)
      .timeWindow(Time.minutes(10), Time.seconds(5))
      .allowedLateness(Time.minutes(1))
      .sideOutputLateData(new OutputTag[ApacheLogEvent]("late"))
      .aggregate(new PageCountAgg(), new PageViewCountWindowResult())

    val resultStream = aggStream
      .keyBy(_.windowEnd)
      .process(new TopNHotPages(10))

    dataStream.print("dataStream")
    aggStream.print("aggStream")
    aggStream.getSideOutput(new OutputTag[ApacheLogEvent]("late")).print("late")
    resultStream.print("resultStream")

    env.execute("hot page")
  }
}

class PageCountAgg() extends AggregateFunction[ApacheLogEvent, Long, Long] {
  def createAccumulator: Long = 0

  def add(in: ApacheLogEvent, acc: Long): Long = acc + 1

  def getResult(acc: Long): Long = acc

  def merge(acc1: Long, acc2: Long): Long = acc1 + acc2
}

class PageViewCountWindowResult() extends WindowFunction[Long, PageViewCount, String, TimeWindow] {
  override def apply(key: String, window: TimeWindow, input: Iterable[Long], out: Collector[PageViewCount]): Unit = {
    out.collect(PageViewCount(key, window.getEnd, input.iterator.next()))
  }
}

class TopNHotPages(topSize: Int) extends KeyedProcessFunction[Long, PageViewCount, String] {

  //  lazy val pageViewCountListState: ListState[PageViewCount] = getRuntimeContext.getListState(new ListStateDescriptor[PageViewCount]("pageViewCount-list", classOf[PageViewCount]))
  lazy val pageViewCountMapState: MapState[String, Long] = getRuntimeContext.getMapState(new MapStateDescriptor[String, Long]("pageViewCount-map", classOf[String], classOf[Long]))

  override def processElement(input: PageViewCount, ctx: KeyedProcessFunction[Long, PageViewCount, String]#Context, out: Collector[String]): Unit = {
    //    pageViewCountListState.add(input)
    pageViewCountMapState.put(input.url, input.cnt)
    // 定义两个定时器，一个用于计算结果，一个用于清空状态
    ctx.timerService().registerEventTimeTimer(input.windowEnd + 1)
    ctx.timerService().registerEventTimeTimer(input.windowEnd + 60000L)
  }

  override def onTimer(timestamp: Long, ctx: KeyedProcessFunction[Long, PageViewCount, String]#OnTimerContext, out: Collector[String]): Unit = {
    //    val allPageListCounts: ListBuffer[PageViewCount] = ListBuffer()
    //    val iterator = pageViewCountListState.get().iterator()
    //    while (iterator.hasNext) {
    //      allPageListCounts += iterator.next()
    //    }

    val allPageListCounts: ListBuffer[(String,Long)] = ListBuffer()
    val iter = pageViewCountMapState.entries().iterator()
    while(iter.hasNext){
      val element = iter.next()
      allPageListCounts += ((element.getKey,element.getValue))
    }

    //如果窗口关闭，则清空状态
    if (ctx.getCurrentKey + 60000L == timestamp) {
      pageViewCountMapState.clear()
      return
    }

    // 排序
    val sortedPageListCounts = allPageListCounts.sortWith(_._2 > _._2).take(topSize)
    // 格式化为String类型
    val result: StringBuffer = new StringBuffer
    result.append("窗口结束时间: ").append(new Timestamp(timestamp - 1)).append("
")
    for (i <- sortedPageListCounts.indices) {
      val currentPageCounts = sortedPageListCounts(i)
      result.append("NO").append(i + 1).append(": 	")
        .append("页面url = ").append(currentPageCounts._1).append("	")
        .append("热门度 = ").append(currentPageCounts._2).append("
")
    }

    result.append("====================================

")

    Thread.sleep(1000)

    out.collect(result.toString)
  }
}
```


##网站总浏览量（PV）的统计
PV：PageView，用户访问页面的总次数。
UP：UniqueView，访问页面的用户数，每个用户只统计一次。

- PageView
```scala
package com.hxr.networkflowanalysis

import org.apache.flink.api.common.functions.{AggregateFunction, MapFunction}
import org.apache.flink.api.common.state.{ValueState, ValueStateDescriptor}
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.api.scala.function.WindowFunction
import org.apache.flink.streaming.api.windowing.time.Time
import org.apache.flink.streaming.api.windowing.windows.TimeWindow
import org.apache.flink.util.Collector

import scala.util.Random

/**
 * @Description: 需求：实现一小时内网站总浏览量PV的统计
 * @Author: CJ
 * @Data: 2020/12/29 15:29
 */
case class UserBehavior(userId: Long, itemId: Long, catagoryId: Int, behavior: String, timestamp: Long)

case class PvCount(windowEnd: Long, count: Long)

object PageView {
  def main(args: Array[String]): Unit = {
    val env: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(4)
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

    val resource = getClass.getResource("/UserBehavior.csv")
    val inputStream = env.readTextFile(resource.getPath)

    val dataStream = inputStream
      .map(data => {
        val arr = data.split(",")
        UserBehavior(arr(0).toLong, arr(1).toLong, arr(2).toInt, arr(3), arr(4).toLong)
      })
      .assignAscendingTimestamps(_.timestamp * 1000)

    val aggStream = dataStream
      .filter(_.behavior == "pv")
      .map(new MyMapper)
      .keyBy(_._1)
      .timeWindow(Time.hours(1))
      .aggregate(new PvCountAgg, new PvCountWindowResult)

    //    aggStream.print("aggStream")

    val resultStream = aggStream
      .keyBy(_.windowEnd)
      .process(new PvCountProcessResult)

    resultStream.print("result")

    env.execute("pv count")
  }
}

class MyMapper extends MapFunction[UserBehavior, (String, Long)] {
  override def map(userBehavior: UserBehavior): (String, Long) = {
    (Random.nextString(10), 1)
  }
}

class PvCountAgg extends AggregateFunction[(String, Long), Long, Long] {
  override def createAccumulator(): Long = 0L

  override def add(in: (String, Long), acc: Long): Long = acc + 1

  override def getResult(acc: Long): Long = acc

  override def merge(acc: Long, acc1: Long): Long = acc + acc1
}

class PvCountWindowResult extends WindowFunction[Long, PvCount, String, TimeWindow] {
  override def apply(key: String, window: TimeWindow, input: Iterable[Long], out: Collector[PvCount]): Unit = {
    out.collect(PvCount(window.getEnd, input.head))
  }
}

class PvCountProcessResult extends KeyedProcessFunction[Long, PvCount, PvCount] {

  lazy val totalPvCountResultState: ValueState[Long] = getRuntimeContext.getState(new ValueStateDescriptor[Long]("ValueState", classOf[Long]))

  override def processElement(value: PvCount, ctx: KeyedProcessFunction[Long, PvCount, PvCount]#Context, out: Collector[PvCount]): Unit = {
    val count = totalPvCountResultState.value()
    totalPvCountResultState.update(count + value.count)

    ctx.timerService().registerEventTimeTimer(value.windowEnd + 1)
  }

  override def onTimer(timestamp: Long, ctx: KeyedProcessFunction[Long, PvCount, PvCount]#OnTimerContext, out: Collector[PvCount]): Unit = {
    val totalPvCount = totalPvCountResultState.value()
    out.collect(PvCount(ctx.getCurrentKey.toLong, totalPvCount))
    totalPvCountResultState.clear()
  }
}
```

- UniqueView
>**原逻辑：**需要记录用户的访问次数，如果将用户存储在内存中，用户数量在千万级，那么单个任务占用的内存达到1G。
>**改进：**1.因为只需要知道用户id是否存在而不需要知道其值，就可以使用`布隆过滤器`，一条记录原需要8B空间，现只需要1bit空间，共计12.5MB（2^8 *1b ），为了避免哈希碰撞，可以设置为64MB。存储到Redis需要用到bitmap在哈希值对应的偏移量上置1表示该用户已存在。
>2.为了避免窗口中数据堆积，就定义触发器，每条数据会触发一次计算操作。
>**问题：**1.每条数据都会连接redis导致redis压力过大 2.如何解决读取redis的bitmap公共变量时产生的并发问题。
```scala
package com.hxr.networkflowanalysis

import java.time.format.DateTimeFormatter
import java.time.{LocalDateTime, ZoneId}

import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.api.scala.function.ProcessWindowFunction
import org.apache.flink.streaming.api.windowing.time.Time
import org.apache.flink.streaming.api.windowing.triggers.{Trigger, TriggerResult}
import org.apache.flink.streaming.api.windowing.windows.TimeWindow
import org.apache.flink.util.Collector
import redis.clients.jedis.Jedis

/**
 * @Description: 统计UV，使用布隆过滤器保存用户信息
 * @Author: CJ
 * @Data: 2020/12/30 9:24
 */
case class UvCount(window: Long, count: Long)

object UniqueView {
  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(1)
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

    val source = getClass.getResource("/UserBehavior.csv")
    val inputStream = env.readTextFile(source.getPath)

    val dataStream = inputStream
      .map(data => {
        val arr = data.split(",")
        UserBehavior(arr(0).toLong, arr(1).toLong, arr(2).toInt, arr(3), arr(4).toLong)
      })
      .assignAscendingTimestamps(_.timestamp * 1000)

    dataStream
      .filter("pv" == _.behavior)
      .map(user => ("pv", user.userId))
      .keyBy(_._1)
      .timeWindow(Time.hours(1))
      .trigger(new MyTrigger)
      .process(new UvCountWithBloom)

    env.execute("uv count")
  }
}

class MyTrigger extends Trigger[(String, Long), TimeWindow] {
  override def onElement(element: (String, Long), timestamp: Long, window: TimeWindow, ctx: Trigger.TriggerContext): TriggerResult = TriggerResult.FIRE_AND_PURGE

  override def onProcessingTime(time: Long, window: TimeWindow, ctx: Trigger.TriggerContext): TriggerResult = TriggerResult.CONTINUE

  override def onEventTime(time: Long, window: TimeWindow, ctx: Trigger.TriggerContext): TriggerResult = TriggerResult.CONTINUE

  override def clear(window: TimeWindow, ctx: Trigger.TriggerContext): Unit = {}
}

class Bloom(size: Long) {
  private val cap = size

  def hash(value: String, seed: Int): Long = {
    var result = 0L
    for (i <- 0 until value.length) {
      result = value.charAt(i) + result * seed
    }
    // 结果需要在size范围内
    (cap - 1) & result
  }
}

class UvCountWithBloom extends ProcessWindowFunction[(String, Long), UvCount, String, TimeWindow] {

  lazy val jedis: Jedis = new Jedis("116.62.148.11", 6380)

  lazy val bloom = new Bloom(1 << 29)

  override def process(key: String, context: Context, elements: Iterable[(String, Long)], out: Collector[UvCount]): Unit = {
    val now = LocalDateTime.now(ZoneId.of("Asia/Shanghai"))
    val date = DateTimeFormatter.ofPattern("yyyy-MM-dd").format(now)

    val hkey = date + "_count"
    val bkey = date + "_bitmap"
    val windowEnd = context.window.getEnd.toString
    // 使用hash结构存储统计值
    val result = jedis.hget(hkey, windowEnd)
    var count = 0L
    if (result != null) {
      count = result.toLong
    }

    // 判断userId是否存在，如果不存在，则统计结果加一并存入bitmap中
    val lastEle: (String, Long) = elements.last
    val offset = bloom.hash(lastEle._2.toString, 61)
    val isExist: Boolean = jedis.getbit(bkey, offset)

    if (!isExist) {
      jedis.setbit(bkey, offset, true)
      jedis.hset(hkey, windowEnd, (count+1).toString)
    }
  }
}
```

##分渠道统计用户行为（需要自定义数据源编造数据）
>主要是如何自定义数据源编造数据，然后对用户行为和渠道进行分组分窗进行统计。此处会缓存窗口中所有到达的数据并得到数据量，消耗内存较大，建议使用累加的方式（即.aggregate中使用累加器保存中间变量）。
```scala
package com.hxr.market_analysis

import java.util.UUID

import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.source.{RichSourceFunction, SourceFunction}
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.api.scala.function.ProcessWindowFunction
import org.apache.flink.streaming.api.windowing.time.Time
import org.apache.flink.streaming.api.windowing.windows.TimeWindow
import org.apache.flink.util.Collector

import scala.util.Random

/**
 * @Description:
 * @Author: CJ
 * @Data: 2020/12/30 15:01
 */
case class MarketUserBehavior(userId: String, behavior: String, channel: String, timestamp: Long)

case class MarketCount(windowStart: String, windowEnd: String, channel: String, behavior: String, count: Long)

class SimulatedSource() extends RichSourceFunction[MarketUserBehavior] {
  // 标志位
  var running = true
  // 定义用户行为和渠道的集合
  val behaviorSet: Seq[String] = Seq("view", "click", "download", "install", "uninstall")
  val channelSet: Seq[String] = Seq("appstore", "weibo", "wechat", "tieba")
  val rand: Random = Random

  override def run(ctx: SourceFunction.SourceContext[MarketUserBehavior]): Unit = {
    // 定义生成数据最大数量
    val maxCounts = Long.MaxValue
    var count = 0L

    // 产生数据
    while (running && count < maxCounts) {
      val id = UUID.randomUUID().toString
      val behavior = behaviorSet(rand.nextInt(behaviorSet.size))
      val channel = channelSet(rand.nextInt(channelSet.size))
      val ts = System.currentTimeMillis()

      ctx.collect(MarketUserBehavior(id, behavior, channel, ts))
      count += 1
      Thread.sleep(50)
    }

  }

  override def cancel(): Unit = running = false
}

object AppMarketByChannel {
  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(1)
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

    val inputStream = env.addSource(new SimulatedSource)

    val dataStream = inputStream
      .assignAscendingTimestamps(_.timestamp)

    val resultStream = dataStream
      .filter(_.behavior != "uninstall")
      .keyBy(data => (data.behavior, data.channel))
      .timeWindow(Time.days(1), Time.seconds(5))
      .process(new AppMarketCount)

    resultStream.print("result")

    env.execute("app market")
  }
}

class AppMarketCount extends ProcessWindowFunction[MarketUserBehavior,MarketCount,(String,String),TimeWindow] {
  override def process(key: (String, String), context: Context, elements: Iterable[MarketUserBehavior], out: Collector[MarketCount]): Unit = {
    val start = context.window.getStart.toString
    val end = context.window.getEnd.toString
    val behavior = key._1
    val channel = key._2
    val count = elements.size

    out.collect(MarketCount(start,end,channel,behavior,count))
  }
}
```

##对一天内点击100次以上相同广告的用户输出为黑名单
>通过过程函数统计一天内相同用户点击相同广告的次数，如果次数大于100次，则拦截后续的该用户点击该广告的日志，并输出该用户到黑名单。
```scala
package com.hxr.adclick_analysis

import org.apache.flink.api.common.functions.AggregateFunction
import org.apache.flink.api.common.state.{ValueState, ValueStateDescriptor}
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.api.scala.function.ProcessWindowFunction
import org.apache.flink.streaming.api.windowing.time.Time
import org.apache.flink.streaming.api.windowing.windows.TimeWindow
import org.apache.flink.util.Collector

/**
 * @Description: 对一天内点击100次以上相同广告的用户输出为黑名单
 * @Author: CJ
 * @Data: 2020/12/30 15:51
 */
case class AdClickLog(userId: Long, adId: Long, province: String, city: String, timestamp: Long)

case class AdClickCountByProvince(windowEnd: String, province: String, count: Long)

case class FilterBlackListUser(userId: Long, adId: Long, msg: String)

object AdClickAnalysis {
  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(1)
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

    val source = getClass.getResource("/AdClickLog.csv")
    val inputStream = env.readTextFile(source.getPath)

    val dataStream = inputStream
      .map(data => {
        val arr = data.split(",")
        AdClickLog(arr(0).toLong, arr(1).toLong, arr(2), arr(3), arr(4).toLong)
      })
      .assignAscendingTimestamps(_.timestamp * 1000)

    // 判断用户是否多次点击同一广告，如果是则拦截日志并输出黑名单
    val processStream = dataStream
      .keyBy(data => (data.userId, data.adId))
      .process(new FliterBlackListUserResult(100))

    // 统计每个广告的用户点击数
    val resultStream = processStream
      .keyBy(_.province)
      .timeWindow(Time.hours(1), Time.seconds(5))
      .aggregate(new AdCountAgg, new AdCountAggWindowResult)

    processStream.getSideOutput(new OutputTag[FilterBlackListUser]("black-list-user")).print("warn")
    resultStream.print("result")

    env.execute("ad black list")
  }
}

// 同一用户一天内点击相同广告maxClick次，将该用户输出为黑名单。并拦截该用户对该广告的点击日志。
class FliterBlackListUserResult(maxClick: Long) extends KeyedProcessFunction[(Long, Long), AdClickLog, AdClickLog] {
  // 需要记录的状态有1.统计次数 2.该用户是否已经输出 3.
  lazy val countState: ValueState[Long] = getRuntimeContext.getState(new ValueStateDescriptor[Long]("countState", classOf[Long]))

  lazy val isContained: ValueState[Boolean] = getRuntimeContext.getState(new ValueStateDescriptor[Boolean]("isContained", classOf[Boolean]))

  override def processElement(value: AdClickLog, ctx: KeyedProcessFunction[(Long, Long), AdClickLog, AdClickLog]#Context, out: Collector[AdClickLog]): Unit = {
    val curCount = countState.value()
    // 如果计数个数为0，说明第一次点击该广告，定义到当天24:00的定时器
    if (curCount == 0) {
      val ts = (System.currentTimeMillis() / (1000 * 60 * 60 * 24) + 1) * (1000 * 60 * 60 * 24)
      ctx.timerService().registerEventTimeTimer(ts)
    }

    // 如果计数大于maxClick个，判断是否已经输出该用户，如果没有，则输出到侧输出流
    if (curCount >= maxClick) {
      if (!isContained.value()) {
        isContained.update(true)
        ctx.output(new OutputTag[FilterBlackListUser]("black-list-user"), FilterBlackListUser(ctx.getCurrentKey._1, ctx.getCurrentKey._2, "该用户重复点击" + maxClick))
      }
      // 如果点击超过限制，该条日志不传到下游
      return
    }

    countState.update(curCount + 1)
    out.collect(value)
  }

  // 触发器中，清空保存的状态
  override def onTimer(timestamp: Long, ctx: KeyedProcessFunction[(Long, Long), AdClickLog, AdClickLog]#OnTimerContext, out: Collector[AdClickLog]): Unit = {
    isContained.update(false)
    countState.update(0)
  }
}

class AdCountAgg extends AggregateFunction[AdClickLog, Long, Long] {
  override def createAccumulator(): Long = 0L

  override def add(in: AdClickLog, acc: Long): Long = acc + 1

  override def getResult(acc: Long): Long = acc

  override def merge(acc: Long, acc1: Long): Long = acc + acc1
}

class AdCountAggWindowResult extends ProcessWindowFunction[Long, AdClickCountByProvince, String,TimeWindow]{
  override def process(key: String, context: Context, elements: Iterable[Long], out: Collector[AdClickCountByProvince]): Unit = {
    out.collect(AdClickCountByProvince(context.window.getEnd.toString,key,elements.head))
  }
}
```

## 筛选出乱序数据中的两秒内连续两次登录失败数据
>**思考**
1.如果只是timeWindow进行开窗，水位线是生效的，但是逻辑不对。不合适；
2.如果不使用开窗直接使用process函数，符合逻辑，但是水位线不生效，需要缓存数据自定义触发。不合适；
3.可以使用CEP函数，进行数据匹配，水位线是生效的。底层逻辑：如果begin匹配上数据后注册定时器，如果定时器时间内符合条件直接输出，定时器触发后清空状态，同时兼顾了时间语义和水位线。
**依赖**
```xml
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-cep-scala_${scala.binary.version}</artifactId>
            <version>${flink.version}</version>
        </dependency>
```
```scala
package com.hxr.loginfaildetect

import java.util

import org.apache.flink.cep.PatternSelectFunction
import org.apache.flink.cep.scala.CEP
import org.apache.flink.cep.scala.pattern.Pattern
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.timestamps.BoundedOutOfOrdernessTimestampExtractor
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.api.windowing.time.Time

/**
 * @Description:
 * @Author: CJ
 * @Data: 2021/1/6 14:54
 */
object LoginFailCEP {
  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(1)
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

    val source = getClass.getResource("/LoginLog.csv")
    val inputStream = env.readTextFile(source.getPath)

    val dataStream = inputStream
      .map(data => {
        val arr = data.split(",")
        LoginLog(arr(0).toLong, arr(1), arr(2), arr(3).toLong)
      })
      .assignTimestampsAndWatermarks(new BoundedOutOfOrdernessTimestampExtractor[LoginLog](Time.seconds(2)) {
        override def extractTimestamp(element: LoginLog): Long = element.timestamp * 1000
      })

    val pattern = Pattern
      .begin[LoginLog]("firstFail").where(_.eventType.equals("fail"))
      .next("secondFail").where(_.eventType.equals("fail"))
      .within(Time.seconds(2))

    val resultStream = CEP.pattern(dataStream.keyBy(_.userId), pattern)
      .select(new PatternSelectResult)

    resultStream.print("warning")

    env.execute("login fail cep")
  }
}

class PatternSelectResult extends PatternSelectFunction[LoginLog,LoginFailWarning] {
  override def select(map: util.Map[String, util.List[LoginLog]]): LoginFailWarning = {
    val firstFailLog = map.get("firstFail").get(0)
    val secondFailLog = map.get("secondFail").get(0)
    LoginFailWarning(firstFailLog.userId,firstFailLog.timestamp,secondFailLog.timestamp,"login fail warning")
  }
}
```

##订单支付实时监控
>匹配同一订单号的create行为和pay行为，分别输出支付订单和超时未支付的订单。
```scala
package com.hxr.orderpaydetect

import java.util

import org.apache.flink.cep.{PatternSelectFunction, PatternTimeoutFunction}
import org.apache.flink.cep.scala.CEP
import org.apache.flink.cep.scala.pattern.Pattern
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.api.windowing.time.Time

/**
 * @Description: 订单支付实时监控(业务逻辑：匹配同一订单号的create行为和pay行为。如果超时未支付则输出报警。)
 * @Author: CJ
 * @Data: 2021/1/6 15:37
 */
case class OrderLog(orderId: Long, eventType: String, txId: String, timestamp: Long)

case class OrderResult(orderId: Long, resultMsg: String)

object OrderTimeout {
  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(1)
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

    val resource = getClass.getResource("/OrderLog.csv")
    val inputStream = env.readTextFile(resource.getPath)

    val dataStream = inputStream
      .map(data => {
        val arr = data.split(",")
        OrderLog(arr(0).toLong, arr(1), arr(2), arr(3).toLong)
      })
      .assignAscendingTimestamps(_.timestamp * 1000L)

    val pattern = Pattern
      .begin[OrderLog]("create").where(_.eventType.equals("create"))
      .next("pay").where(_.eventType.equals("pay"))
      .within(Time.minutes(15))

    val outputTag = new OutputTag[OrderResult]("order-timeout")

    val resultStream = CEP
      .pattern(dataStream.keyBy(_.orderId), pattern)
      .select(outputTag, new OrderTimeoutResult, new OrderCompleteResult)

    resultStream.getSideOutput(outputTag).print("timeout")
    resultStream.print("success")

    env.execute("order timeout")
  }
}

class OrderTimeoutResult extends PatternTimeoutFunction[OrderLog,OrderResult]{
  override def timeout(map: util.Map[String, util.List[OrderLog]], l: Long): OrderResult = {
    val create = map.get("create").get(0)
    OrderResult(create.orderId,"timeout:" + l)
  }
}

class OrderCompleteResult extends PatternSelectFunction[OrderLog,OrderResult]{
  override def select(map: util.Map[String, util.List[OrderLog]]): OrderResult = {
    val create = map.get("create").get(0)
    val pay = map.get("pay").get(0)
    OrderResult(create.orderId,"create:"+ create.timestamp + "--pay:" + pay.timestamp)
  }
}
```

<br>
**思路2：**
>只需要匹配create和pay两条数据即可，无需关注数据顺序，所以对于这种特殊情况，可以取巧用process函数进行处理。
>**逻辑：**不用管create和pay到达顺序，只需要时间间隔在15min内即可。如果pay到达，create没到达，则设置定时器时间为pay的时间；如果create到达，pay没到达，则设置定时器时间为create时间15分钟后；如果create到达，pay也已经到达。

>**问题：**create到达后会设置一个15分钟的定时器，理应只有在pay记录到达并将水位线推进到15分钟后才会打印 "支付时间超过订单有效时间，发生异常"，其他情况触发的定时器都会清空状态导致，导致不会打印 "支付时间超过订单有效时间，发生异常"。
>**但是实际情况是，通过文件和通过nc端口进行处理的如下数据，会得到不同的结果。数据如下：**
>![image.png](Flink实时项目.assets\57132594aee843609bdf76bfd7ebfc2e.png)
**如果读取的是文件，打印如下：**
>![image.png](Flink实时项目.assets\45365c1066954bb098abbcb1bb8e92ce.png)
>**如果读取的nc端口，打印如下：**
>![image.png](Flink实时项目.assets\39a58ce56b12413ea6f664cb1d109f4b.png)
>**原因：**因为默认的watermark生成机制是定时生成（200ms），如果直接读取文件，读取速度太快会导致watermark推进的跨度太大，导致虽然到达的记录已经过期，但是watermark没有推进并触发定时器；
而从端口读取，生成数据的时间慢，watermark密度大跨度小，所以更加准确。
>总结：`因此还是需要比较到达的数据的时间戳判断是否是过期数据，原因有两点①避免过期数据推进watermark并触发定时器的情况，因为这样会先进入逻辑判断，然后触发定时器 ②避免数据读取过快，水位线之间数据量太大，过期数据到达但是水位线没有推进，没有触发定时器，导致将过期数据作为正常数据进行处理的情况。`
```scala
package com.hxr.orderpaydetect

import org.apache.flink.api.common.state.{ValueState, ValueStateDescriptor}
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.KeyedProcessFunction
import org.apache.flink.streaming.api.scala._
import org.apache.flink.util.Collector

/**
 * @Description:
 * @Author: CJ
 * @Data: 2021/1/6 16:40
 */
object OrderTimeoutUseProcess {
  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(1)
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

    val resource = getClass.getResource("/OrderLog.csv")
    val inputStream = env.readTextFile(resource.getPath)

    val dataStream = inputStream
      .map(data => {
        val arr = data.split(",")
        OrderLog(arr(0).toLong, arr(1), arr(2), arr(3).toLong)
      })
      .assignAscendingTimestamps(_.timestamp * 1000L)

    val resultStream = dataStream
      .keyBy(_.orderId)
      .process(new OrderProcessResult)

    resultStream.getSideOutput(new OutputTag[OrderResult]("order-timeout")).print("warning")
    resultStream.print("success")


    env.execute("order timeout")
  }
}

// 只需要匹配create和pay两条数据即可，
class OrderProcessResult extends KeyedProcessFunction[Long, OrderLog, OrderResult] {
  lazy val createState: ValueState[Boolean] = getRuntimeContext.getState(new ValueStateDescriptor[Boolean]("create-state", classOf[Boolean]))
  lazy val payState: ValueState[Boolean] = getRuntimeContext.getState(new ValueStateDescriptor[Boolean]("pay-state", classOf[Boolean]))
  lazy val timerTsState: ValueState[Long] = getRuntimeContext.getState(new ValueStateDescriptor[Long]("timer-ts", classOf[Long]))

  val outputTag = new OutputTag[OrderResult]("order-timeout")

  override def processElement(value: OrderLog, ctx: KeyedProcessFunction[Long, OrderLog, OrderResult]#Context, out: Collector[OrderResult]): Unit = {
    val isCreate = createState.value()
    val isPayed = payState.value()
    val timerTs = timerTsState.value()

    // 1 当前到达的是订单创建记录
    if (value.eventType.equals("create")) {
      if (isPayed) {
        // 1.1 到达的订单已经支付完成，清空状态并输出支付完成记录
        ctx.timerService().deleteEventTimeTimer(timerTs)
        createState.clear()
        payState.clear()
        timerTsState.clear()
        out.collect(OrderResult(value.orderId, "order completed!"))
      } else {
        // 1.2 到达的订单未支付，需要等待支付记录达到
        val ts = value.timestamp * 1000L + 15 * 60000
        ctx.timerService().registerEventTimeTimer(ts)
        timerTsState.update(ts)
        createState.update(true)
      }
    }
    // 2 当前到达的是订单支付记录
    else if (value.eventType.equals("pay")) {
      if (isCreate) {
        // 2.1 如果已经创建订单了，则匹配成功。还要判断一下支付时间是否超过了定时器时间
        if (value.timestamp * 1000L <= timerTs) {
          // 2.1.1 如果支付时间小于定时器时间，正常输出
          ctx.timerService().deleteEventTimeTimer(timerTs)
          out.collect(OrderResult(value.orderId, "order completed!"))
        } else {
          // 2.1.2 如果支付时间大于定时器时间，则超时，输出到侧输出流
          ctx.output(outputTag, OrderResult(value.orderId, "支付时间超过订单有效时间，发生异常"))
        }
        createState.clear()
        payState.clear()
        timerTsState.clear()
      } else {
        // 2.2 如果订单未创建，那么可能是无序数据造成的，设置定时器触发时间为支付时间，等待水位线漫过当前支付时间时触发
        val ts = value.timestamp * 1000L
        ctx.timerService().registerEventTimeTimer(ts)
        timerTsState.update(ts)
        payState.update(true)
      }
    }
  }

  // 定时器触发有两种场景 1.订单创建但是没有支付，会注册一个定时器； 2.已支付但是没有创建订单。
  override def onTimer(timestamp: Long, ctx: KeyedProcessFunction[Long, OrderLog, OrderResult]#OnTimerContext, out: Collector[OrderResult]): Unit = {
    // 1.订单创建但是没有支付，会注册一个定时器；
    if (createState.value()) {
      ctx.output(outputTag, OrderResult(ctx.getCurrentKey, "order timeout(not found pay log)"))
    }
    // 2.有支付数据但是没有创建数据，会注册一个定时器；
    else if(payState.value()) {
      ctx.output(outputTag, OrderResult(ctx.getCurrentKey, "order timeout(not found create log)"))
    }

    createState.clear()
    payState.clear()
    timerTsState.clear()
  }

}
```


## 双流join 匹配支付和流水记录
>一条流中是平台的支付行为记录，另一条流中是第三方的流水记录，支付和流水记录有相同流水单号的进行匹配。
>**双流join的API区别：**connect允许数据类型不同的流进行join；union只允许数据类型相同的流进行join；window join和interval join是固定的格式，可定制化不高。
>**逻辑：**哪条先到达，就先存到状态中，另一条到达后再进行输出并清空状态。

### 方法一：使用connect
```scala
package com.hxr.orderpaydetect

import org.apache.flink.api.common.state.{ValueState, ValueStateDescriptor}
import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.co.CoProcessFunction
import org.apache.flink.streaming.api.scala._
import org.apache.flink.util.Collector

/**
 * @Description:
 * @Author: CJ
 * @Data: 2021/1/8 18:51
 */
case class ReceiptEvent(txId: String, payChannel: String, timestamp: Long)

object TxMatch {
  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(1)
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

    val orderResource = getClass.getResource("/OrderLog.csv")
    val orderInputStream = env.readTextFile(orderResource.getPath)
    val orderDataStream = orderInputStream
      .map(data => {
        val arr = data.split(",")
        OrderLog(arr(0).toLong, arr(1), arr(2), arr(3).toLong)
      })
      .assignAscendingTimestamps(_.timestamp * 1000L)


    val receiptResource = getClass.getResource("/ReceiptLog.csv")
    val ReceiptInputStream = env.readTextFile(receiptResource.getPath)
    val receiptDataStream = ReceiptInputStream
      .map(data => {
        val arr = data.split(",")
        ReceiptEvent(arr(0), arr(1), arr(2).toLong)
      })
      .assignAscendingTimestamps(_.timestamp * 1000L)


    val resultStream = orderDataStream.filter(_.eventType.equals("pay")).keyBy(_.txId)
      .connect(receiptDataStream.keyBy(_.txId))
      .process(new TxPayMatchResult())

    resultStream.print("info")
    resultStream.getSideOutput(new OutputTag[OrderLog]("unmatched-order")).print("unmatched-order")
    resultStream.getSideOutput(new OutputTag[ReceiptEvent]("unmatched-pay")).print("unmatched-pay")

    env.execute("tx match")
  }
}

// 双流connect，将符合条件的信息缓存在状态中，然后进行匹配输出
class TxPayMatchResult() extends CoProcessFunction[OrderLog, ReceiptEvent, (OrderLog, ReceiptEvent)] {
  lazy val payEventState: ValueState[OrderLog] = getRuntimeContext.getState(new ValueStateDescriptor[OrderLog]("pay-event", classOf[OrderLog]))
  lazy val receiptEventState: ValueState[ReceiptEvent] = getRuntimeContext.getState(new ValueStateDescriptor[ReceiptEvent]("receipt-event", classOf[ReceiptEvent]))

  override def processElement1(value: OrderLog, ctx: CoProcessFunction[OrderLog, ReceiptEvent, (OrderLog, ReceiptEvent)]#Context, out: Collector[(OrderLog, ReceiptEvent)]): Unit = {
    val receiptEvent: ReceiptEvent = receiptEventState.value()
    if (receiptEvent == null) {
      payEventState.update(value)
      ctx.timerService().registerEventTimeTimer(value.timestamp*1000L + 5*1000L)
    } else {
      out.collect((value,receiptEvent))
      payEventState.clear()
      receiptEventState.clear()
    }
  }

  override def processElement2(value: ReceiptEvent, ctx: CoProcessFunction[OrderLog, ReceiptEvent, (OrderLog, ReceiptEvent)]#Context, out: Collector[(OrderLog, ReceiptEvent)]): Unit = {
    val payEvent: OrderLog = payEventState.value()
    if (payEvent == null) {
      receiptEventState.update(value)
      ctx.timerService().registerEventTimeTimer(value.timestamp*1000L + 3*1000L)
    } else {
      out.collect((payEvent,value))
      payEventState.clear()
      receiptEventState.clear()
    }
  }

  override def onTimer(timestamp: Long, ctx: CoProcessFunction[OrderLog, ReceiptEvent, (OrderLog, ReceiptEvent)]#OnTimerContext, out: Collector[(OrderLog, ReceiptEvent)]): Unit = {
    val order = payEventState.value()
    val receipt = receiptEventState.value()

    if(order != null) {
      ctx.output(new OutputTag[OrderLog]("unmatched-order"),order)
    }else if (receipt != null) {
      ctx.output(new OutputTag[ReceiptEvent]("unmatched-pay"),receipt)
    }
  }
}
```

###方法二：使用 join 算子处理
>**join算子分为window join 和 interval join：**
>- **窗口连接（连接该记录所在窗口中的另一条流的记录）：**stream.join(otherStream).where(<KeySelector>).equalTo(<KeySelector>).window(<WindowAssigner>).apply(<JoinFunction>)
>- **间隔连接（连接记录前后相隔固定时间内的另一条流的记录）：**stream.keyBy(...).intervalJoin( otherStream.keyBy(...) ).between( Time.milliseconds(-2) ), Time.milliseconds(1) ).process(new ProcessJoinFunction)

>**逻辑：**通过intervalJoin，匹配流中的记录的前3s和后5s时间间隔内的数据。匹配上的数据进入ProcessJoinFunction类中进行输出。
```scala
package com.hxr.orderpaydetect

import org.apache.flink.streaming.api.TimeCharacteristic
import org.apache.flink.streaming.api.functions.co.ProcessJoinFunction
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.api.windowing.time.Time
import org.apache.flink.util.Collector

/**
 * @Description:
 * @Author: CJ
 * @Data: 2021/1/11 15:27
 */
object TxMatchUseJoin {
  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(1)
    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

    val orderResource = getClass.getResource("/OrderLog.csv")
    val orderInputStream = env.readTextFile(orderResource.getPath)
    val orderDataStream = orderInputStream
      .map(data => {
        val arr = data.split(",")
        OrderLog(arr(0).toLong, arr(1), arr(2), arr(3).toLong)
      })
      .assignAscendingTimestamps(_.timestamp * 1000L)

    val receiptResource = getClass.getResource("/ReceiptLog.csv")
    val ReceiptInputStream = env.readTextFile(receiptResource.getPath)
    val receiptDataStream = ReceiptInputStream
      .map(data => {
        val arr = data.split(",")
        ReceiptEvent(arr(0), arr(1), arr(2).toLong)
      })
      .assignAscendingTimestamps(_.timestamp * 1000L)


    val resultStream = orderDataStream.filter(_.eventType.equals("pay")).keyBy(_.txId)
      .intervalJoin(receiptDataStream.keyBy(_.txId))
      .between(Time.seconds(-3), Time.seconds(5))
      .process(new TxMatchWithJoinResult)

    resultStream.print("success")

    env.execute("tx match join")
  }
}

class TxMatchWithJoinResult extends ProcessJoinFunction[OrderLog, ReceiptEvent, (OrderLog, ReceiptEvent)] {
  override def processElement(left: OrderLog, right: ReceiptEvent, ctx: ProcessJoinFunction[OrderLog, ReceiptEvent, (OrderLog, ReceiptEvent)]#Context, out: Collector[(OrderLog, ReceiptEvent)]): Unit = {
    out.collect((left,right))
  }
}
```


<br>
<br>
##总结
1. **.process(new ProcessWindowFunction(...)) 和 .aggregate(new AggregateFunction(...),new WindowFunction(...)) 的区别：**
- .process中会保存所有数据，并在窗口触发计算(即窗口关闭或触发器触发)时调用process方法进行数据处理。这样会保存所有的窗口数据导致内存消耗过大，可以通过设置触发器，以事件触发并清空窗口数据，将结果进行持久化来进行优化。
- .aggregate方法可以定义累加器，累加器以事件触发。窗口关闭后会将累加器结果给到WindowFunction函数进行处理，这样完成了窗口的数据统计，也没有缓存所有的窗口数据。

2. 可以通过自定义trigger类自定义触发机制，默认触发机制是来一条记录触发一次处理逻辑。

3. 需要比较到达的数据的时间戳判断是否是过期数据，原因有两点①避免过期数据推进watermark并触发定时器的情况，因为这样会先进入逻辑判断，然后触发定时器 ②避免数据读取过快，水位线之间数据量太大，过期数据到达但是水位线没有推进，没有触发定时器，导致将过期数据作为正常数据进行处理的情况。
