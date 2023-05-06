---
title: Flink异常
categories:
- 大数据笔记
---
**1、**Checkpoint失败：Checkpoint expired before completing
        env.enableCheckpointing(1000L)
        val checkpointConf = env.getCheckpointConfig
        checkpointConf.setMinPauseBetweenCheckpoints(30000L)
        checkpointConf.setCheckpointTimeout(8000L)
>原因是因为`checkpointConf.setCheckpointTimeout(8000L)`设置的太小了，默认是10min，这里只设置了8sec。当一个Flink App背压的时候（例如由外部组件异常引起），Barrier会流动的非常缓慢，导致Checkpoint时长飙升。

**2、**在Flink中，资源的隔离是通过Slot进行的，也就是说多个Slot会运行在同一个JVM中，这种隔离很弱，尤其对于生产环境。Flink App上线之前要在一个单独的Flink集群上进行测试，否则一个不稳定、存在问题的Flink App上线，很可能影响整个Flink集群上的App。

**3 、**Flink App抛出`The assigned slot container_e08_1539148828017_15937_01_003564_0 was removed.`此类异常，通过查看日志，一般就是某一个Flink App内存占用大，导致TaskManager（在Yarn上就是Container）被Kill掉。如果代码写的没问题，就确实是资源不够了，其实1G Slot跑多个Task（Slot Group Share）其实挺容易出现的。因此有两种选择。可以根据具体情况，权衡选择一个。

- 将该Flink App调度在Per Slot内存更大的集群上。
- 通过`slotSharingGroup("xxx")`，减少Slot中共享Task的个数
```
org.apache.flink.util.FlinkException: The assigned slot container_e08_1539148828017_15937_01_003564_0 was removed.
    at org.apache.flink.runtime.resourcemanager.slotmanager.SlotManager.removeSlot(SlotManager.java:786)
    at org.apache.flink.runtime.resourcemanager.slotmanager.SlotManager.removeSlots(SlotManager.java:756)
    at org.apache.flink.runtime.resourcemanager.slotmanager.SlotManager.internalUnregisterTaskManager(SlotManager.java:948)
    at org.apache.flink.runtime.resourcemanager.slotmanager.SlotManager.unregisterTaskManager(SlotManager.java:372)
    at org.apache.flink.runtime.resourcemanager.ResourceManager.closeTaskManagerConnection(ResourceManager.java:803)
    at org.apache.flink.yarn.YarnResourceManager.lambda$onContainersCompleted$0(YarnResourceManager.java:340)
    at org.apache.flink.runtime.rpc.akka.AkkaRpcActor.handleRunAsync(AkkaRpcActor.java:332)
    at org.apache.flink.runtime.rpc.akka.AkkaRpcActor.handleRpcMessage(AkkaRpcActor.java:158)
    at org.apache.flink.runtime.rpc.akka.FencedAkkaRpcActor.handleRpcMessage(FencedAkkaRpcActor.java:70)
    at org.apache.flink.runtime.rpc.akka.AkkaRpcActor.onReceive(AkkaRpcActor.java:142)
    at org.apache.flink.runtime.rpc.akka.FencedAkkaRpcActor.onReceive(FencedAkkaRpcActor.java:40)
    at akka.actor.UntypedActor$$anonfun$receive$1.applyOrElse(UntypedActor.scala:165)
    at akka.actor.Actor$class.aroundReceive(Actor.scala:502)
    at akka.actor.UntypedActor.aroundReceive(UntypedActor.scala:95)
    at akka.actor.ActorCell.receiveMessage(ActorCell.scala:526)
    at akka.actor.ActorCell.invoke(ActorCell.scala:495)
    at akka.dispatch.Mailbox.processMailbox(Mailbox.scala:257)
    at akka.dispatch.Mailbox.run(Mailbox.scala:224)
    at akka.dispatch.Mailbox.exec(Mailbox.scala:234)
    at scala.concurrent.forkjoin.ForkJoinTask.doExec(ForkJoinTask.java:260)
    at scala.concurrent.forkjoin.ForkJoinPool$WorkQueue.runTask(ForkJoinPool.java:1339)
    at scala.concurrent.forkjoin.ForkJoinPool.runWorker(ForkJoinPool.java:1979)
    at scala.concurrent.forkjoin.ForkJoinWorkerThread.run(ForkJoinWorkerThread.java:107)
```
**4、**抛出`Caused by: java.io.IOException: Too many open files`异常，一般是因为存在Flink App在结束的时候没有释放资源，这里指的是例如忘记关闭连接池，线程池等资源。如果一个Flink App结束的时候没有释放资源，又因为异常被重启多次后，很容易出现`Too many open files`异常，从而拖垮整个TaskManager上的Flink App。
- 重写RichFunction的Close()方法，加上例如：`suishenRedisTemplate.quit()`，`hbaseClient.shutdown().join(TimeUnit.SECONDS.toMillis(30))`等。由于现在Scala Api不支持RichAsyncFunction，没有Close方法，无法释放资源，这是一件很蛋疼的事情。。。
```
    at org.apache.flink.streaming.runtime.tasks.StreamTask.invoke(StreamTask.java:296)
    at org.apache.flink.runtime.taskmanager.Task.run(Task.java:712)
    at java.lang.Thread.run(Thread.java:748)
Caused by: io.netty.channel.ChannelException: failed to open a new selector
    at io.netty.channel.nio.NioEventLoop.openSelector(NioEventLoop.java:156)
    at io.netty.channel.nio.NioEventLoop.<init>(NioEventLoop.java:147)
    at io.netty.channel.nio.NioEventLoopGroup.newChild(NioEventLoopGroup.java:126)
    at io.netty.channel.nio.NioEventLoopGroup.newChild(NioEventLoopGroup.java:36)
    at io.netty.util.concurrent.MultithreadEventExecutorGroup.<init>(MultithreadEventExecutorGroup.java:84)
    ... 21 more
Caused by: java.io.IOException: Too many open files
    at sun.nio.ch.IOUtil.makePipe(Native Method)
    at sun.nio.ch.EPollSelectorImpl.<init>(EPollSelectorImpl.java:65)
    at sun.nio.ch.EPollSelectorProvider.openSelector(EPollSelectorProvider.java:36)
    at io.netty.channel.nio.NioEventLoop.openSelector(NioEventLoop.java:154)
    ... 25 more
```
