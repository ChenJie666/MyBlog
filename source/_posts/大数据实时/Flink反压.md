---
title: Flink反压
categories:
- 大数据实时
---
参考：[Flink优化03---反压处理_Johnson8702的博客-CSDN博客_flink反压](https://blog.csdn.net/Johnson8702/article/details/123841740)


# 一、概述
## 1.1 反压的理解
简单来说，数据在 flink 拓扑中多个节点自上而下流动，下游处理数据较慢，导致上游数据发送阻塞，最终导致数据源的获取也被阻塞。也就是说，下游处理数据的速度跟不上数据流入的速度，会导致数据流入阻塞，并反馈到上游，使上游数据的发送也产生阻塞。

通常情况下，大促销、秒杀活动导致流量激增，会导致反压的产生。

## 1.2 反压的危害
反压的出现，会影响到 checkpoint 时长和 state 大小，进而可能导致资源耗尽甚至系统奔溃。

1）影响 checkpoint 时长
根据checkpoint机制可知，只有所有管道的 barrier 对齐之后，才能正常 checkpoint。如果某个管道出现反压，则 barrier 会延迟到来，尽管其他的 barrier 已经到来，哪怕只剩一个 barrier 迟到，也会导致 checkpoint 无法正常触发，直到所有的 barrier 都到了之后，才正常触发 checkpoint。所以，反压的出现，会导致 checkpoint 总体时间（End to End Duration）变长。

2） 影响 state 大小
barrier 对齐之前，其他较快的管道的数据会源源不断发送过来，虽然不会被处理，但是会被缓存起来，直到较慢的管道的 barrier 也到达，所有没有被处理但是缓存起来的数据，会一起放到 state 中，导致 checkpoint 变大。

上面两个问题的出现，对实际生产环境来说是十分危险的，checkpoint 是保证数据一致性和准确性的关键，一旦 checkpoint 时间变长，有可能导致 checkpoint 超时失败，而 state 变大同样可能会拖慢 checkpoint 甚至导致 OOM （使用 Heap-based StateBackend）或者物理内存使用超出容器资源（使用 RocksDBStateBackend）的稳定性问题。

因此，在实际生产环境中，要尽量避免出现反压的情况。

<br>
# 二、反压节点的定位
解决反压问题，首先要定位反压节点，为了方便排查，需要禁用任务链 operator chain，否则，多个算子会被集中到一个节点图中，不利于定位产生反压的算子。

## 2.1 利用 Flink Web UI 定位
Flink 1.13 以后的版本，Flink Web UI 的监控中，通过颜色加数值，更清晰明了地表明每个算子的繁忙程度和反压程度，正常情况下为 蓝色 -> 紫色 -> 黑色 -> 淡红 -> 红 繁忙和反压程度逐渐加深。同时，为每个算子提供了 SubTask 级别的 BackPressure 监控，更便于观察该节点是否处于反压状态。默认情况下，0.1 表示 OK，0.1~0.5 表示 LOW，超过 0.5 表示 HIGH。Flink 1.13 版本之后，在此基础上，加入颜色作为背景，更便于观察反压和繁忙的程度。其中， OK 是绿色，LOW 是黄色，HIGH 是红色。具体，如下图所示
![image.png](Flink反压.assets\2123e530b3ee4a62aae566aa73918ee0.png)

**如果出现反压，通常有两种可能：**
1）**该节点的发送速率跟不上产生速率**。这种状况一般是输入一条数据，发送多条数据的场景下出现，比如 flatmap 算子。这种情况下，该节点就是反压产生的根源节点；
2）**下游节点接收速率低于当前节点的发送速率**，通过反压机制，拉低了当前节点的发送速率，这种情况下，需要继续往下游节点排查，直到找到第一个反压状态为 OK 的节点，一般这个节点就是产生反压的节点。

通常，结合每个节点的反压程度和繁忙程度，综合考虑，判断产生反压的根源节点；一般情况下，繁忙程度接近 100%，并导致上游节点反压程度接近 100%的节点，就是反压产生的根源节点。

## 2.2 利用 Metrics 定位（了解）
利用 Flink Web UI 中的 Metrics，也可以帮助我们定位反压根源。最为有用的是一下几个 Metrics：

| Metrics |	描述 |
| --- | --- |
| outPoolUsage	| 发送端 Buffer 的使用率 |
| inPoolUsage	| 接收端 Buffer 的使用率 |
| floatingBuffersUsage（1.9以上）	| 接收端 Floating Buffer 的使用率 |
| exclusiveBuffersUsage（1.9以上）	| 接收端 Exclusive Buffer 的使用率 |

其中 `inPoolUsage = floatingBuffersUsage + ExclusiveBuffersUsage`

**1）根据指标分析反压**

如果一个 Subtask 的发送端 Buffer 占用率很高，说明它被下游反压限速了；如果一个 Subtask 的接收端 Buffer 占用很高，表明它将反压传导到上游。具体情况可以参考下表：

| | outPoolUsage 低	| outPoolUsage 高 |
| --- | --- | --- |
| inPoolUsage 低	| 正常	| 1. 被下游反压，处理临时状态（还没传导到上游）<br>2. 可能是反压的根源，一条输入多条输出的场景，比如 flatmap |
| inPoolUsage 高	| 1. 如果上游所有 outPoolUsage 都是低，有可能还没传导到上游，最终会导致反压<br>2. 如果上游的 outPoolUsage 高，则是反压的根源	| 被下游反压 |

**2）进一步分析数据传输**

Flink 1.9 及以上版本，还可以根据 floatingBuffersUsage/exclusiveBuffersUsage 以及上游 Task 的 outPoolUsage 来进行进一步的分析一个 Subtask  及其上游 Subtask 的数据传输。

在流量较大时，Channel 的 Exclusive Buffer 可能会被写满，此时 Flink 会向 Buffer Pool 申请剩余的 Floating Buffer。这些 Floating Buffer 属于备用 Buffer。

| | exclusiveBuffersUsage 低	| exclusiveBuffersUsage 高 |
| --- | --- | --- |
| floatingBuffersUsage 低<br>所有上游 outPoolUsage 低 | 正常 | |	
| floatingBuffersUsage 低<br>上游某个 outPoolUsage 高 | 潜在的网络瓶颈 | |	
| floatingBuffersUsage 高<br>所有上游 outPoolUsage 低 | 最终对部分 inputChannel 反压（正在传递）	| 最终对大多数或所有 inputChannel 反压（正在传递） |
|floatingBuffersUsage 高<br>上游某个 outPoolUsage 高 | 只对部分 inputChannel 反压 |	对大多数或所有 inputChannel 反压 |

**总结：**
1. floatingBuffersUsage 高，则表明反压正在传导至上游;
2. 同时 exclusiveBuffersUsage 低，则表明可能有倾斜;
比如，floatingBuffersUsage 高、exclusiveBuffersUsage 低 为有数据倾斜，因为少数 channel 占用了大部分的 Floating Buffer。

<br>
# 三、反压的原因及处理
## 3.1 数据倾斜
通过 Web UI 各个 SubTask 的 Records Sent 和 Records Received 来确认，另外，还可以通过 Checkpoint detail 里不同的 SubTask 的 State Size 来判断是否数据倾斜。

![image.png](Flink反压.assetsb4ad49abe0248cfac1616de209bbe7f.png)

 例如上图，节点 2 的数据量明显高于其他节点的数据量，数据发生了很严重的倾斜问题。


## 3.2 使用火焰图分析
如果不是数据倾斜，可能就是用户代码的执行效率问题，可能是频繁被阻塞 或者 性能问题，需要找到瓶颈算子的哪部分计算消耗巨大。

最有用的办法就是对 TaskManager 进行 CPU profile，从中可以分析到 Task Thread 是否跑满一个 CPU 核；如果是的话就要分析 CPU 主要消耗在哪些函数上；如果不是，就要看 Task Thread 阻塞在哪里，可能是yoghurt函数本身有些同步的调用，可能是 checkpoint 或者 GC 等系统活动导致的暂时系统暂停。

### 3.2.1 开启火焰图功能
Flink 1.13 及其之后的版本，直接在 WebUI 提供了 JVM 的 CPU火焰图，从而大大简化了性能瓶颈的分析难度。该配置默认是不开启的，需要修改参数：
```
rest.flamegraph.enabled: true # 默认 false
```
或者在启动指令中指定
```
-Drest.flamegraph.enabled=true \
sudo -u hdfs $FLINK_HOME/bin/flink run-application -t yarn-application \
-Djobmanager.memory.process.size=1024m \
-Dtaskmanager.memory.process.size=1024m \
-Dtaskmanager.numberOfTaskSlots=1 \
-Dparallelism.default=12 \
-Drest.flamegraph.enabled=true \
-Dyarn.application.name="TestDemo" \
/tmp/****-jar-with-dependencies.jar
```

### 3.2.2 WebUI查看火焰图
![image.png](Flink反压.assets4c4d3eddc114db086671899a4a03069.png)

 火焰图是通过对堆栈跟踪进行多次采样来构建的。每个方法调用都由一个条形表示，其中条形的长度与其在样本中出现的次数成正比。

- On-CPU：处于 [RUNNABLE，NEW] 状态的线程
- Off-CPU：处于 [TIMED_WAITING，WAITING，BLOCKED] 的线程，用于查看在样本中发现的阻塞调用

### 3.2.3 分析火焰图
颜色没有具体含义，具体查看：

- 纵向是调用链，从下往上，顶部就是正在执行的函数
- 横向是样本出现次数，可以理解为执行时长

**看顶层的哪个函数占据的宽度最大。只要有“平顶”（plateaus），就表示该函数可能存在性能问题。**

如果是 Flink 1.13 以前的版本，需要自己手动生成火焰图。

注意，火焰图在不需要性能分析的情况下，尽量不要打开，数据采集生成火焰图，也会消耗一定的性能。

## 3.3 分析 GC 情况
TaskManager 的内存以及 GC 问题也可能导致反压，包括 TaskManager JVM 各区内存不合理导致的频繁 Full GC 甚至失联。通常建议使用默认的 G1 垃圾回收器。

可以通过打印 GC 日志（-XX：+PrintGCDetails），使用 GC 分析器（GCViewer工具）来验证是否处于这种情况。

- 在 Flink 提交脚本中，设置 JVM 参数，打印 GC 日志
   ```
   -Denv.java.opts="-XX:+PrintGCDetails -XX:+PrintGCDateStamps" \
   ```
   ```
   sudo -u hdfs $FLINK_HOME/bin/flink run-application -t yarn-application \
   -Djobmanager.memory.process.size=1024m \
   -Dtaskmanager.memory.process.size=1024m \
   -Dtaskmanager.numberOfTaskSlots=1 \
   -Dparallelism.default=12 \
   -Drest.flamegraph.enabled=true \
   -Denv.java.opts="-XX:+PrintGCDetails -XX:+PrintGCDateStamps" \
   -Dyarn.application.name="TestDemo" \
   /tmp/****-jar-with-dependencies.jar
   ```

- 下载 GC 日志
打开 Flink WebUI，选择 JobManager 或者 TaskManager，点击 Stdout，即可看到 GC 日志，点击下载按钮，即可以将 GC 日志下载下来。

- 分析 GC 日志
通过 GC 日志，分析出单个 Flink TaskManager 堆总大小、年轻代、老年代分配的内存空间，Full GC 后老年代剩余大小等。


在Windows下，直接双击打开 [gcviewer_1.3.4.jar](https://github.com/chewiebug/GCViewer)，打开 GUI 界面，选择 上面下载的 gc log。

扩展：最重要的指标是 Full GC 后，老年代剩余大小 这个指标，按照《Java 性能优化权威指南》中 Java 堆大小计算法则，设 Full GC 后老年代剩余大小空间为 M，那么堆的大小建议为 3~4 倍 M，新生代为 1~1.5 倍 M，老年代为 2~3 倍 M。

## 3.4 外部组件影响
如果发现 Source 端数据读取性能比较低，或者 Sink 端写入性能较差，需要检查第三方组件是否是瓶颈产生的主要原因，还有就是做维表 join 时的性能问题。

比如，Kafka 集群是否需要扩容，并行度是否太低；Sink 的数据库是否性能需要提高；等等。

如果第三方组件存在性能问题，比如 Postgresql，写入太慢，可以考虑：

1）先赞批，再写入（满足实时性要求的情况下）
2）异步 io + 热缓存来优化读写性能

## 3.5 算子性能问题
下游整个整个算子 sub-task 的处理性能差，输入是 1w qps，当前算子的 sub-task 算下来平均只能处理 1k qps，因此就有反压的情况。比如算子需要访问外部接口，访问外部接口耗时长。

<br>
# 四、解决问题
**任务运行前：**解决上述介绍到的数据倾斜、算子性能 问题。

**任务运行中：**
1. 限制数据源的消费数据速度。比如在事件时间窗口的应用中，可以自己设置在数据源处加一些限流措施，让每个数据源都能够够匀速消费数据，避免出现有的 Source 快，有的 Source 慢，导致窗口 input pool 打满，watermark 对不齐导致任务卡住。
2. 关闭 Checkpoint。关闭 Checkpoint 可以将 barrier 对齐这一步省略掉，促使任务能够快速回溯数据。我们可以在数据回溯完成之后，再将 Checkpoint 打开。
