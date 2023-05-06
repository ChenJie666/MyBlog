---
title: Flink实时项目
categories:
- 大数据实时
---
Flink实时项目

**flink实现精准一次消费，env.enableCheckpointing(1000)**  **//开启checkpoint检查点，默认exactly once**

用户行为数据：由用户ID、商品ID、商品类目ID、行为类型和时间戳组成  服务器的日志数据：由访问者的IP、userId、访问时间、访问方法以及访问的url组成

数据源：

## 需求一：每隔5分钟输出最近一小时内点击量最多的前N个商品

要点：  ①热点即为对pv行为进行统计  ②时间窗口区间为左闭右开  ③用ProcessFunction定义KeyedStream的处理逻辑  onTimer定时器定时调用  ④FlinkKafkaConsumer可以直接读取kafka中的数据  val dataStream: DataStream[String] = env.addSource(new FlinkKafkaConsumer[String](%22kafka1%22,new%20SimpleStringSchema(),prop))

<pre spellcheck="false" class="md-fences md-end-block ty-contain-cm modeLoaded" lang="" contenteditable="true" cid="n9" mdtype="fences" style="box-sizing: border-box; overflow: visible; font-family: var(--monospace); font-size: 0.9em; display: block; break-inside: avoid; text-align: left; white-space: normal; background-image: inherit; background-position: inherit; background-size: inherit; background-repeat: inherit; background-attachment: inherit; background-origin: inherit; background-clip: inherit; background-color: rgb(248, 248, 248); position: relative !important; border: 1px solid rgb(231, 234, 237); border-radius: 3px; padding: 8px 4px 6px; margin-bottom: 15px; margin-top: 15px; width: inherit; color: rgb(51, 51, 51); font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; text-decoration-style: initial; text-decoration-color: initial;">需求实现：
1.设定Time类型为EventTime   env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

2.从kafka中读取数据（Flink有）
val dataStream: DataStream[String] = env.addSource(new FlinkKafkaConsumer[String]("kafka1",new SimpleStringSchema(),prop))
包装成样例类。

3.设置eventTime和延迟时间。

4.将pv事件过滤出来，然后keyBy(_.item)进行分区(即进入对应的executor中)，然后进行开窗timeWindow(Time.hours(1), Time.minutes(5))

5.对开窗后的流进行聚合，因为需要将输出类型转为样例类
windowStream.aggregate(new CountAgg(), new MyWindow())
要点：
1）需要自定义预聚合类，根据需求对窗口内的进行计数
2）需要自定义窗口函数，重写apply方法，将计数结果和窗口结束时间WindowEnd封装为样例类然后输出。

6.按WindowEnd进行聚合，在聚合后调用process方法
要点：
在open方法中设置状态变量
listState = getRuntimeContext.getListState[ItemViewCount](
 new ListStateDescriptor[ItemViewCount]("itemViewCount",classOf[ItemViewCount])
在processElement方法中将数据存入状态变量中，并注册定时器
listState.add(value)
ctx.timerService().registerEventTimeTimer(value.windowEnd + 100L)
在onTimer方法中设置定时器被水位没过后调用的执行方法。
将状态变量中的元素按count进行排序，然后取前n个，out.collect(strBuffer.toString)输出</pre>

## 需求二 实时流量统计

过程与需求一相似。

每隔5秒，输出最近10分钟内访问量最多的前N个URL

<pre spellcheck="false" class="md-fences md-end-block ty-contain-cm modeLoaded" lang="scala" contenteditable="true" cid="n14" mdtype="fences" style="box-sizing: border-box; overflow: visible; font-family: var(--monospace); font-size: 0.9em; display: block; break-inside: avoid; text-align: left; white-space: normal; background-image: inherit; background-position: inherit; background-size: inherit; background-repeat: inherit; background-attachment: inherit; background-origin: inherit; background-clip: inherit; background-color: rgb(248, 248, 248); position: relative !important; border: 1px solid rgb(231, 234, 237); border-radius: 3px; padding: 8px 4px 6px; margin-bottom: 15px; margin-top: 15px; width: inherit; color: rgb(51, 51, 51); font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; text-decoration-style: initial; text-decoration-color: initial;">需求实现
1.指定为事件时间    env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)
2.从kafka中读取数据，包装成样例类
3.设置事件时间和延迟时间   assignTimestampsAndWatermarks
4.按url进行分组，然后开窗，窗口大小为10分钟，步长为5秒
assignDS.keyBy(_.url).timeWindow(Time.minutes(10), Time.seconds(5))
5.对不同key和不同窗口的数据进行count聚合
aggregate(new CountAgg(), new MyWindow())
6.以窗口结束时间进行分组，然后通过process方法进程状态编程
aggDS.keyBy(_.windowEnd).process(new MyProcess(5))</pre>

## 需求三 恶意登陆监控

同一用户（可以是不同IP）在2秒之内连续两次登录失败

**方式一**：通过对userid进行分组，然后调用process方法，在processElement方法中，判断eventType是否为fail，如果为fail则创建计时器并将数据加入到listState中，如果为success，则清空listState。在onTimer中，判断状态变量中的数据数是否大于2，大于2输出报警信息。  缺点：必须要2s后才会进行报警

**方式二**：用到cep 复杂函数编程

<pre spellcheck="false" class="md-fences md-end-block ty-contain-cm modeLoaded" lang="scala" contenteditable="true" cid="n21" mdtype="fences" style="box-sizing: border-box; overflow: visible; font-family: var(--monospace); font-size: 0.9em; display: block; break-inside: avoid; text-align: left; white-space: normal; background-image: inherit; background-position: inherit; background-size: inherit; background-repeat: inherit; background-attachment: inherit; background-origin: inherit; background-clip: inherit; background-color: rgb(248, 248, 248); position: relative !important; border: 1px solid rgb(231, 234, 237); border-radius: 3px; padding: 8px 4px 6px; margin-bottom: 15px; margin-top: 15px; width: inherit; color: rgb(51, 51, 51); font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; text-decoration-style: initial; text-decoration-color: initial;">方式二 实现需求
1.env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)
2.从kafka读取数据，并设置事件时间和延迟时间，按userid进行keyBy
3.用CEP（complex event processing）进行改进
要点：
//匹配规则为以eventType为fail的事件开始，在2s内匹配到严格紧邻的另一个fail事件。
val pattern: Pattern[LoginEvent, LoginEvent] = Pattern.begin[LoginEvent]("begin")
 .where(_.eventType == "fail").next("next").where(_.eventType == "fail")
 .within(Time.seconds(2))
//每次匹配到后都会放入流中，从流中获取匹配到的数据
val patternStream: PatternStream[LoginEvent] = CEP.pattern(keyedStream, pattern)
val warningStream: DataStream[Warning1] = patternStream.select(new PatternSelect())

//自定义select类，提取匹配到的数据
class PatternSelect() extends PatternSelectFunction[LoginEvent, Warning1] {
 override def select(map: util.Map[String, util.List[LoginEvent]]): Warning1 = {
 val begins: util.List[LoginEvent] = map.get("begin")//list中只有一个，因为没有time多次匹配
 val begin: LoginEvent = begins.iterator().next()
 val nexts: util.List[LoginEvent] = map.get("next")
 val next: LoginEvent = nexts.iterator().next()
 Warning1(begin.userId.toString, begin.eventTime, next.eventTime, "连续两次登陆失败")
 }
}</pre>

## 需求四 订单支付实时监控

设置一个失效时间（比如15分钟），如果下单后一段时间仍未支付，订单就会被取消。

方式一：通过CEP进行匹配，将为匹配上的数据输出到侧输出流，匹配到的数据输出到主流。

<pre spellcheck="false" class="md-fences md-end-block ty-contain-cm modeLoaded" lang="scala" contenteditable="true" cid="n26" mdtype="fences" style="box-sizing: border-box; overflow: visible; font-family: var(--monospace); font-size: 0.9em; display: block; break-inside: avoid; text-align: left; white-space: normal; background-image: inherit; background-position: inherit; background-size: inherit; background-repeat: inherit; background-attachment: inherit; background-origin: inherit; background-clip: inherit; background-color: rgb(248, 248, 248); position: relative !important; border: 1px solid rgb(231, 234, 237); border-radius: 3px; padding: 8px 4px 6px; margin-bottom: 15px; margin-top: 15px; width: inherit; color: rgb(51, 51, 51); font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; text-decoration-style: initial; text-decoration-color: initial;">方式一 需求实现：
1.env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)
2.转为样例类并设置事件时间和延迟时间
3.按orderId进行分组
4.通过cep，匹配到从下单开始到10分钟内完成支付的订单，输出到主流
//匹配模式
val pattern: Pattern[OrderEvent, OrderEvent] = Pattern.begin[OrderEvent]("begin")
 .where(_.eventType == "create").followedBy("followedBy").where(_.eventType == "pay")
 .within(Time.minutes(10))
//对流中的数据进行匹配
val patternStream: PatternStream[OrderEvent] = CEP.pattern(keyByStream, pattern)
//得到匹配完成的主流的数据，并将匹配超时的数据输出到测输出流
val resultStream: DataStream[OrderResult] = patternStream.select(new OutputTag[OrderResult]("orderTimeOut")) {
 (pattern: collection.Map[String, Iterable[OrderEvent]], timestamp: Long) => {
 val begin: OrderEvent = pattern("begin").iterator.next()
 OrderResult(begin.orderId, "order timeout")
 }
 } {
 (pattern: collection.Map[String, Iterable[OrderEvent]]) => {
 val begin: OrderEvent = pattern("begin").iterator.next()
 OrderResult(begin.orderId, "pay success")
 }
 }
//从主流中得到侧输出流的数据
val timeOutStream: DataStream[OrderResult] = resultStream.getSideOutput(new              OutputTag[OrderResult]("orderTimeOut"))

resultStream.print()  //主流只打印匹配上的数据，不打印侧输出流的数据
timeOutStream.print()  //侧输出流可以从主流中获得</pre>

方式二：通过process函数实现

<pre spellcheck="false" class="md-fences md-end-block ty-contain-cm modeLoaded" lang="scala" contenteditable="true" cid="n28" mdtype="fences" style="box-sizing: border-box; overflow: visible; font-family: var(--monospace); font-size: 0.9em; display: block; break-inside: avoid; text-align: left; white-space: normal; background-image: inherit; background-position: inherit; background-size: inherit; background-repeat: inherit; background-attachment: inherit; background-origin: inherit; background-clip: inherit; background-color: rgb(248, 248, 248); position: relative !important; border: 1px solid rgb(231, 234, 237); border-radius: 3px; padding: 8px 4px 6px; margin-bottom: 15px; margin-top: 15px; width: inherit; color: rgb(51, 51, 51); font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; text-decoration-style: initial; text-decoration-color: initial;">方式二 需求实现
1.env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)
2.转为样例类并设置事件时间和延迟时间
3.按orderId进行分组
4.通过process方法
process(new MyProcess())

//对无序数据的四种不同情况的分析
class MyKeyedProcess(interval: Long) extends KeyedProcessFunction[Long, OrderEvent, OrderResult] {
 //定义两个状态
 lazy private val isPayed: ValueState[Boolean] = getRuntimeContext.getState(new ValueStateDescriptor[Boolean]("isPayed", classOf[Boolean]))
 lazy private val currTime: ValueState[Long] = getRuntimeContext.getState(new ValueStateDescriptor[Long]("currTime", classOf[Long]))

 override def processElement(value: OrderEvent, ctx: KeyedProcessFunction[Long, OrderEvent, OrderResult]#Context, out: Collector[OrderResult]): Unit = {

 if (value.eventType == "create") {
 if (isPayed.value()) {
 //已支付；输出结果并删除计时器
 if (currTime.value < value.eventTime * 1000 + interval * 60 * 1000) {
 println(currTime.value + "b")
 println(value.eventTime * 1000 + interval * 60 * 1000)
 out.collect(OrderResult(ctx.getCurrentKey, "pay-create success"))
 ctx.timerService().deleteEventTimeTimer(currTime.value())
 currTime.clear()
 isPayed.clear()
 }
 } else {
 //未支付;创建计时器等待pay到来
 val timestamp: Long = value.eventTime * 1000 + interval * 60 * 1000
 currTime.update(timestamp)
 ctx.timerService().registerEventTimeTimer(timestamp)
 }
 } else if (value.eventType == "pay") {
 if (currTime.value() == 0) {
 //计时器未创建，create未到达;创建计时器，等待create到达
 val timestamp: Long = value.eventTime * 1000 //create先创建，未到达可以等待几秒
 isPayed.update(true)
 currTime.update(timestamp)
 ctx.timerService().registerEventTimeTimer(timestamp)
 } else {
 //计时器已创建，create已到达;输出结果并删除计时器
 if (value.eventTime * 1000 < currTime.value()) {
 out.collect(OrderResult(ctx.getCurrentKey, "create-pay success"))
 ctx.timerService().deleteEventTimeTimer(currTime.value())
 currTime.clear()
 isPayed.clear()
 }
 }
 }
 }

 override def onTimer(timestamp: Long, ctx: KeyedProcessFunction[Long, OrderEvent, OrderResult]#OnTimerContext, out: Collector[OrderResult]): Unit = {
//写入到侧输出流
 if (!isPayed.value) {
 ctx.output(new OutputTag[OrderResult]("orderresult"), OrderResult(ctx.getCurrentKey, "order timeout"))
 } else {
 ctx.output(new OutputTag[OrderResult]("orderresult"), OrderResult(ctx.getCurrentKey, "创建订单表丢失"))
 }

 currTime.clear()
 isPayed.clear()
 }

}</pre>

对于订单支付事件，用户支付完成其实并不算完，我们还得确认平台账户上是否到账了。而往往这会来自不同的日志信息，所以我们要同时读入两条流的数据来做合并处理。这里我们利用connect将两条流进行连接，然后用自定义的CoProcessFunction进行处理。

实时对账：

<pre spellcheck="false" class="md-fences md-end-block ty-contain-cm modeLoaded" lang="scala" contenteditable="true" cid="n32" mdtype="fences" style="box-sizing: border-box; overflow: visible; font-family: var(--monospace); font-size: 0.9em; display: block; break-inside: avoid; text-align: left; white-space: normal; background-image: inherit; background-position: inherit; background-size: inherit; background-repeat: inherit; background-attachment: inherit; background-origin: inherit; background-clip: inherit; background-color: rgb(248, 248, 248); position: relative !important; border: 1px solid rgb(231, 234, 237); border-radius: 3px; padding: 8px 4px 6px; margin-bottom: 15px; margin-top: 15px; width: inherit; color: rgb(51, 51, 51); font-style: normal; font-variant-ligatures: normal; font-variant-caps: normal; font-weight: 400; letter-spacing: normal; orphans: 2; text-indent: 0px; text-transform: none; widows: 2; word-spacing: 0px; -webkit-text-stroke-width: 0px; text-decoration-style: initial; text-decoration-color: initial;">object TxMatch {

 val unmatchedPays = new OutputTag[OrderEvent1]("unmatchedPays")
 val unmatchedReceipts = new OutputTag[ReceiptEvent1]("unmatchedReceipts")

 def main(args: Array[String]): Unit = {
 val env: StreamExecutionEnvironment = StreamExecutionEnvironment.getExecutionEnvironment
 env.setParallelism(1)
 env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime)

 val orderEventStream = env.fromCollection(
 List(
 OrderEvent1(1, "create", "", 1558430842),
 OrderEvent1(2, "create", "", 1558430843),
 OrderEvent1(1, "pay", "111", 1558430844),
 OrderEvent1(2, "pay", "222", 1558430848),
 OrderEvent1(3, "create", "", 1558430849),
 OrderEvent1(3, "pay", "333", 1558430849)
 )
 ).assignTimestampsAndWatermarks(new BoundedOutOfOrdernessTimestampExtractor[OrderEvent1](Time.seconds(5)) {
 override def extractTimestamp(element: OrderEvent1): Long = element.eventTime * 1000
 }).filter(_.txId != "").keyBy(_.txId)

 val ReceiptEventStream = env.fromCollection(
 List(
 ReceiptEvent1("111", "wechat", 1558430847),
 ReceiptEvent1("222", "alipay", 1558430845),
 ReceiptEvent1("444", "alipay", 1558430850)
 )
 ).assignTimestampsAndWatermarks(new BoundedOutOfOrdernessTimestampExtractor[ReceiptEvent1](Time.seconds(5)) {
 override def extractTimestamp(element: ReceiptEvent1): Long = element.eventTime * 1000
 }).keyBy(_.txId)

 val connectedStream: ConnectedStreams[OrderEvent1, ReceiptEvent1] = orderEventStream.connect(ReceiptEventStream)

 val processStream: DataStream[orderDetail] = connectedStream.process(new MyProcessFun())

 processStream.print("match")
 processStream.getSideOutput(unmatchedPays).print("unmatchorder")
 processStream.getSideOutput(unmatchedReceipts).print("unmatchreceipt")

 env.execute()
 }

 //相同txId会进入同一个处理
 class MyProcessFun() extends CoProcessFunction[OrderEvent1, ReceiptEvent1, orderDetail] {

 lazy val orderEvent: ValueState[OrderEvent1] = getRuntimeContext.getState(new ValueStateDescriptor[OrderEvent1]("orderevent", classOf[OrderEvent1]))
 lazy val receiptEvent: ValueState[ReceiptEvent1] = getRuntimeContext.getState(new ValueStateDescriptor[ReceiptEvent1]("receiptevent", classOf[ReceiptEvent1]))

 override def processElement1(value: OrderEvent1, ctx: CoProcessFunction[OrderEvent1, ReceiptEvent1, orderDetail]#Context, out: Collector[orderDetail]): Unit = {
 val receipt: ReceiptEvent1 = receiptEvent.value()
 if (receipt != null) {
 //如果receipt存在，说明这两个能相互匹配上
 out.collect(orderDetail(value.userId, value.eventType, receipt.payChannel, receipt.eventTime))
 receiptEvent.clear()
 } else {
 //如果receipt不存在，则等待receipt到达，如果在延迟时间内未到达，则未匹配上
 orderEvent.update(value)
 ctx.timerService().registerEventTimeTimer(value.eventTime * 1000)
 }

 }

 override def processElement2(value: ReceiptEvent1, ctx: CoProcessFunction[OrderEvent1, ReceiptEvent1, orderDetail]#Context, out: Collector[orderDetail]): Unit = {
 val order: OrderEvent1 = orderEvent.value()
 if (order != null) {
 //如果order存在，说明这两个能相互匹配上
 out.collect(orderDetail(order.userId, order.eventType, value.payChannel, value.eventTime))
 orderEvent.clear()
 } else {
 //如果order不存在，则等待order到达，如果在延迟时间内未到达，则未匹配上
 receiptEvent.update(value)
 ctx.timerService().registerEventTimeTimer(value.eventTime * 1000)
 }
 }

 override def onTimer(timestamp: Long, ctx: CoProcessFunction[OrderEvent1, ReceiptEvent1, orderDetail]#OnTimerContext, out: Collector[orderDetail]): Unit = {
 val order = orderEvent.value()
 val receipt = receiptEvent.value()


 if (order != null) {
 ctx.output(unmatchedPays, order)
 }
 if (receipt != null) {
 ctx.output(unmatchedReceipts, receipt)
 }

 orderEvent.clear()
 receiptEvent.clear()
 }
 }

}

case class OrderEvent1(userId: Long, eventType: String, txId: String, eventTime: Long)

case class ReceiptEvent1(txId: String, payChannel: String, eventTime: Long)

case class orderDetail(userId: Long, eventType: String, payChannel: String, eventTime: Long)</pre>
