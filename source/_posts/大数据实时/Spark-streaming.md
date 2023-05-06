---
title: Spark-streaming
categories:
- 大数据实时
---
ssc.socketTextStream(“hadoop102”，9999)	端口socket采集器

ssc.textFileStream("in")	文本文件采集器

ssc.queueStream(rddQueue)

ssc.receiverStream(new MyReceiver("hadoop102",9999))	自定义采集器

KfkaUtils.createStream(ssc,Map(),Map(),StorageLevel.MEMORY_ONLY)



transform（）、updateStateByKey（）、window（）



System.exit（0）关闭当前线程



# 1.概述

离线：以分钟，小时为单位
实时：数据时效性，以毫秒为单位

流式：数据从流中过来，来一条处理一条
批处理：将数据作缓冲，一次性传入

spark是微批次处理（按时间段对采集的数据进行封装处理），对rdd进行抽象形成DStream。

![333](F:/Typora/图片/333-1565091684919.PNG)

	

	Spark Streaming支持的数据输入源很多，例如：Kafka、Flume（SparkSink）、Twitter、ZeroMQ（基于c语言的消息队列）和简单的TCP套接字（socket）等等。输出的hdfs、mysql、hbase等

	Spark Streaming使用离散化流(discretized stream)作为抽象表示，叫作DStream。每个时间区间收到的数据都作为 RDD 存在，而DStream是由这些RDD所组成的序列。

![444](F:/Typora/图片/444.PNG)

	接收器是长期运行的用户线程，通过接收器不断消费kafka数据或监听端口的数据然后封装成DStream发送给StreamingContext。所以spark streaming只是对流式数据进行封装处理，将RDD提交给Driver，处理数据还是通过Spark Engine。

	在main方法中启动采集器，ssc.start()。主线程创建上下文，如果主线程停止了，那么采集到的数据无法通过Driver进行包装和切分分配任务，所以Driver和采集器线程都不能停。Driver程序等待采集器的执行完毕，ssc.awaitTermination()。



# 2.DStream的用法和采集器

监听端口，并从socket流中获取采集DStream：

```scala
/*需要先开启natcat，命令为nc -lk 9999占用端口，采集器才能监听该端口*/
object SparkStreaming011{
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("stream").setMaster("local[*]")
    val ssc = new StreamingContext(conf,Seconds(3))
	//每三秒更新一次DStream中封装的RDD，所以DStream一直是同一个，只是对内部的RDD进行处理
    val dstream: ReceiverInputDStream[String] = ssc.socketTextStream("hadoop102",9999)
    val flatDS: DStream[String] = dstream.flatMap {
      line => line.split(",")
    }
    val mapDS: DStream[(String, Long)] = flatDS.map {
      word => (word, 1L)
    }
    val result: DStream[(String, Long)] = mapDS.reduceByKey(_+_)
    result.print()
	//开启采集器线程
    ssc.start()
    //main线程即是Driver线程，如果Driver线程结束，则采集器的数据无法处理，所以采集器线程结束后才能结束
    ssc.awaitTermination()
  }
}
//每三秒更新一次DStream中封装的RDD，所以DStream一直是同一个，只是对内部的RDD进行处理
```

	如果日志信息过多，可以将spark中的log4j文件放到classpath路径下，修改打印日志级别为ERROR。



	如果流计算应用中运行 10 个接收器，那么至少需要为应用分配 11 个 CPU 核心，为接收器和Driver都配置一个核心。



从文件中采集：

```scala
object SparkStreaming0111 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("stream").setMaster("local[*]")
    val ssc = new StreamingContext(conf, Seconds(3))

    val dstream: DStream[String] = ssc.textFileStream("in")
    val flatDS: DStream[String] = dstream.flatMap {
      line => line.split(" ")
    }
    val mapDS: DStream[(String, Int)] = flatDS.map((_,1))
    val resultDS: DStream[(String, Int)] = mapDS.reduceByKey(_+_)
    resultDS.print()

    ssc.start()
    ssc.awaitTermination()
  }
}
```



自定义采集器：

```scala
//自定义采集器，实现socket采集功能
object MyReceiver_Socket {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("stream").setMaster("local[*]")
    val ssc = new StreamingContext(conf,Seconds(3))

    val lineDS: ReceiverInputDStream[String] = ssc.receiverStream(new MyReceiver("hadoop102",9999))
    val wordDS: DStream[String] = lineDS.flatMap {
      line => line.split(" ")
    }
    val resultDS: DStream[(String, Int)] = wordDS.map((_,1)).reduceByKey(_+_)
    resultDS.print()

    ssc.start()
    ssc.awaitTermination()
  }
}
class MyReceiver(host:String,port:Int) extends Receiver[String](StorageLevel.MEMORY_ONLY){

//  var socket : Socket = null

  def storeData = {
    var socket = new Socket(host,port)
    val inputStream: InputStream = socket.getInputStream()
    val reader = new BufferedReader(new InputStreamReader(inputStream))

    var s : String = null

    Breaks.breakable{
      while((s = reader.readLine()) != null){
        if("===END===".equals(s)){
          Breaks.break()
        }
        store(s)
      }
    }
  }

  override def onStart(): Unit = {

    new Thread(new Runnable{
      override def run(): Unit = storeData
    }).start()
  }

  override def onStop(): Unit = {
//    if(socket != null){
//      if(socket.isClosed){
//        socket.close()
//      }
//    }
  }
}
```



kafka采集器：

```scala
object KafkaToSparkStreaming {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("kafkaCJ").setMaster("local[*]")
    val ssc = new StreamingContext(conf,Seconds(3))
    //连接kafka
    val kafkaDStream: ReceiverInputDStream[(String, String)] = KafkaUtils.createStream[String, String, StringDecoder, StringDecoder](
      ssc,
      Map(
        "zookeeper.connect" -> "hadoop102:2181",
        ConsumerConfig.GROUP_ID_CONFIG -> "190311_CJ",
        ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG -> "org.apache.kafka.common.serialization.StringDeserializer",
        ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG -> "org.apache.kafka.common.serialization.StringDeserializer"
      ), 
      Map(
        "kafkaToSparkStream_CJ" -> 3
      ),
      StorageLevel.MEMORY_ONLY
    )
    //获取并打印获取到达kafka数据
    val valueDStream : DStream[String] = kafkaDStream.map(_._2)
    valueDStream.print()

    ssc.start()
    ssc.awaitTermination()
  }
}
```



# 3.DStream转换

无状态：单独处理RDD，不保存数据。
有状态：将RDD保存下来，可以与其他RDD一起操作。

updateStateByKey()有状态操作是依赖于检查点完成的，需要设置检查点保存位置  **ssc.checkpoint("路径")**

updateStateByKey()，将历史结果存储在文件中，可以在处理当前RDD时得到数据。需要k-v类型才能使用。
以下程序是程序自带的缓存机制，也可以用redis等第三方库来缓存数据。

```scala
object UpdateStateByKey1 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("usbk").setMaster("local[*]")
    val ssc = new StreamingContext(conf,Seconds(3))
    ssc.checkpoint("ck")

    val socketDS: ReceiverInputDStream[String] = ssc.socketTextStream("hadoop102",9999)
    val wordDS: DStream[(String, Int)] = socketDS.flatMap {
      line => line.split(" ")
    }.map((_, 1))
    val resultDS: DStream[(String, Int)] = wordDS.updateStateByKey/*[Int]*/ {
      (seq: Seq[Int], buffer: Option[Int]) =>
        //将rdd按key进行聚合，key的value存放在Seq中；Option类为缓存区中的key对应的value值
        var sum = seq.sum + buffer.getOrElse(0) 
        Option(sum)
    }
    resultDS.print()

    ssc.start()
    ssc.awaitTermination()
  }
}
```

窗口滑动函数window：

```scala
object Window {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("usbk").setMaster("local[*]")
    val ssc = new StreamingContext(conf,Seconds(3))

    val lineDS: ReceiverInputDStream[String] = ssc.socketTextStream("hadoop102",9999)

    val wordDS: DStream[(String, Int)] = lineDS.flatMap {
      line => line.split(" ")
    }.map((_, 1))
	//window操作会等待指定批次的数据进入后进行整合，再进行处理，所以间隔时间变长
    val windowDS: DStream[(String, Int)] = wordDS.window(Seconds(6),Seconds(3))

    windowDS.reduceByKey(_+_).print()

    ssc.start()
    ssc.awaitTermination()
  }
}
```



窗口函数实际应用（最近60秒内每10秒的点击数统计）：

```scala
object MeiFenZhongDianJiShu {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("kafkaCJ").setMaster("local[*]")
    val ssc = new StreamingContext(conf, Seconds(1))

    val lineDS: ReceiverInputDStream[(String, String)] = KafkaUtils.createStream[String, String, StringDecoder, StringDecoder](
      ssc,
      Map(
        "zookeeper.connect" -> "hadoop102:2181",
        ConsumerConfig.GROUP_ID_CONFIG -> "Kafka_CJ",
        ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG -> "org.apache.kafka.common.serialization.StringDeserializer",
        ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG -> "org.apache.kafka.common.serialization.StringDeserializer"
      ),
      Map(
        "kafkaToSparkStream_CJ" -> 3
      ),
      StorageLevel.MEMORY_ONLY
    )
    val windowDS: DStream[(String, String)] = lineDS.window(Seconds(60), Seconds(10))

    val timeToCountDS: DStream[(String, Long)] = windowDS.map {
      case (key, value) => (value.substring(0, value.length - 4) + "0000", 1L)
    }
    timeToCountDS.reduceByKey(_+_).print()

    ssc.start()
    ssc.awaitTermination()
  }
}
//生成数据
object Kafka_Produer {
  def main(args: Array[String]): Unit = {

    val properties = new Properties()
    properties.setProperty(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "hadoop102:9092")
    properties.setProperty(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer")
    properties.setProperty(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer")

    val producer = new KafkaProducer[String, String](properties)

    while (true) {
      for (elem <- 1 until Random.nextInt(50)) {
        val time = System.currentTimeMillis()
        val record = new ProducerRecord[String, String]("kafkaToSparkStream_CJ", time.toString)

        producer.send(record)
        println(time)
      }
      Thread.sleep(2000)
    }
  }
}
```



transform：

```scala
//每次读取流时都会执行一次代码；transform与map区别在于，transform可以写周期性在Driver中执行的逻辑。

	//Coding(在Driver线程中执行)
    lineDS.map{
      string =>
        //Coding(在各个执行器中执行)
        string
    }
    //Coding(在Driver线程中执行)
    lineDS.transform{
      rdd =>
        //Coding(每次微批次处理执行1次)
        rdd.map{
        string =>
          //Coding(在各个执行器中执行)
          string
      }
    }

//例如可以实现dstream.print()的时间打印效果。其实foreachRDD也能做到。
val stringDS: DStream[String] = lineDS.transform {
      rdd => {
        //Coding(每次微批次处理执行1次)
        println("------ 这是时间：" + System.currentTimeMillis() + "-------")
        rdd.map {
          string =>
            //Coding(在各个执行器中执行)
            string
        }
      }
}
```

Join：连接操作（leftOuterJoin, rightOuterJoin, fullOuterJoin也可以），可以连接Stream-Stream，windows-stream to windows-stream、stream-dataset



# 3.DStream的输出：

dstream.print() :在驱动节点上打印DStream中的每批次数据的前10个元素，可以修改打印数量的参数。
saveAsTextFiles：
saveAsObjectFiles：
saveAsHadoopFiles
foreachRDD

可以输出到实时性较高的数据库中，如mysql，hbase，tidb中。



	tidb和mysql几乎完全兼容，所以我们的程序没有任何改动就完成了数据库从mysql到TiDb的转换，TiDB 是一个分布式 NewSQL (SQL 、 NoSQL 和 NewSQL 的优缺点比较 )数据库。它支持水平弹性扩展、ACID 事务、标准 SQL、MySQL 语法和 MySQL 协议，具有数据强一致的高可用特性，是一个不仅适合 OLTP 场景还适合 OLAP 场景的混合数据库。兼容 MySQL，支持无限的水平扩展，具备强一致性和高可用性。TiDB 的目标是为 OLTP(Online Transactional Processing) 和 OLAP (Online Analytical Processing) 场景提供一站式的解决方案。

![tidb](F:/Typora/图片/tidb.png)

# 4.优雅的关闭

```scala
conf.set("spark.streaming.stopGracefullyOnShutdown","true")	//配置文件中配置优雅关闭
    
//开启子线程，满足条件则关闭上下文环境
new Thread(new Runnable {
      override def run(): Unit = {

        while(true) {
          val fs: FileSystem = FileSystem.get(new URI("hdfs://hadoop102:9000"), new Configuration(), "root")

          val state: StreamingContextState = ssc.getState()
          if(state == StreamingContextState.ACTIVE) {
            if (fs.exists(new Path("hdfs://hadoop102:9000/closeSC"))) {
              ssc.stop(true, true)
              System.exit(0)
            }
          }
        }
        Thread.sleep(5000)
      }
    }).start()

```
