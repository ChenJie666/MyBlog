---
title: Flink内存管理
categories:
- 大数据实时
---
目前，大数据计算引擎主要用 Java 或是基于 JVM 的编程语言实现的，例如 Apache Hadoop、Apache Spark、Apache Drill、Apache Flink等。Java语言的好处在于程序员不需要太关注底层内存资源的管理，但同样会面临一个问题，就是如何在内存中存储大量的数据（包括缓存和高效处理）。Flink使用自主的内存管理，来避免这个问题。

## JVM内存管理的不足：

1）Java 对象存储密度低。Java的对象在内存中存储包含3个主要部分：对象头、实例数据、对齐填充部分。例如，一个只包含 boolean 属性的对象占16byte：对象头占8byte，boolean 属性占1byte，为了对齐达到8的倍数额外占7byte。而实际上只需要一个bit（1/8字节）就够了。

2）Full GC 会极大地影响性能。尤其是为了处理更大数据而开了很大内存空间的JVM来说，GC 会达到秒级甚至分钟级。

3）OOM 问题影响稳定性。OutOfMemoryError是分布式计算框架经常会遇到的问题，当JVM中所有对象大小超过分配给JVM的内存大小时，就会发生OutOfMemoryError错误，导致JVM崩溃，分布式框架的健壮性和性能都会受到影响。

4）缓存未命中问题。CPU进行计算的时候，是从CPU缓存中获取数据。现代体系的CPU会有多级缓存，而加载的时候是以Cache Line为单位加载。如果能够将对象连续存储，这样就会大大降低CacheMiss。使得CPU集中处理业务，而不是空转。（Java对象在堆上存储的时候并不是连续的，所以从内存中读取Java对象时，缓存的邻近的内存区域的数据往往不是CPU下一步计算所需要的，这就是缓存未命中。此时CPU需要空转等待从内存中重新读取数据。）

Flink 并不是将大量对象存在堆内存上，而是将对象都序列化到一个预分配的内存块上，这个内存块叫做 MemorySegment，它代表了一段固定长度的内存（默认大小为 32KB），也是 Flink中最小的内存分配单元，并且提供了非常高效的读写方法，很多运算可以直接操作二进制数据，不需要反序列化即可执行。每条记录都会以序列化的形式存储在一个或多个MemorySegment中。

## 内存模型

![image.png](Flink内存管理.assets\d53ee9def8174a8fa22231434e9abdb6.png)

### 1、 JobManager内存模型

![image.png](Flink内存管理.assets\53be7359fe014eb8a0b942a12c29cc6e.png)


在1.10中，Flink 统一了 TM 端的内存管理和配置，相应的在1.11中，Flink 进一步对JM 端的内存配置进行了修改，使它的选项和配置方式与TM 端的配置方式保持一致。

>1.10版本# The heap sizefor the JobManager JVM jobmanager.heap.size:1024m 
1.11版本及以后# The totalprocess memory size for the JobManager.## Note thisaccounts for all memory usage within the JobManager process, including JVMmetaspace and other overhead. jobmanager.memory.process.size:1600m


<br>
### 2、 TaskManager内存模型

Flink 1.10 对TaskManager的内存模型和Flink应用程序的配置选项进行了重大更改，让用户能够更加严格地控制其内存开销。

![image.png](Flink内存管理.assets13b44d7ecb94009b8d268bf11cd8672.png)

**TaskExecutorFlinkMemory.java**

![image.png](Flink内存管理.assets\d90a330ec8a0452296716b8244a002c1.png)

**JVM Heap(JVM堆上内存)**
- Framework HeapMemory：Flink框架本身使用的内存，即TaskManager本身所占用的堆上内存，不计入Slot的资源中。
配置参数：`taskmanager.memory.framework.heap.size=128MB`,默认128MB
- Task Heap Memory：Task执行用户代码时所使用的堆上内存。
配置参数：`taskmanager.memory.task.heap.size`

**Off-Heap Mempry(JVM堆外内存)**
- DirectMemory(JVM直接内存)
   - FrameworkOff-Heap Memory：Flink框架本身所使用的内存，即TaskManager本身所占用的对外内存，不计入Slot资源。
配置参数：`taskmanager.memory.framework.off-heap.size=128MB`,默认128MB
   - Task Off-HeapMemory：Task执行用户代码所使用的对外内存。
配置参数：`taskmanager.memory.task.off-heap.size=0`,默认0
   - Network Memory：网络数据交换所使用的堆外内存大小，如网络数据交换缓冲区
配置参数：`taskmanager.memory.network.fraction:0.1`
`taskmanager.memory.network.min:64mb`
`taskmanager.memory.network.max:1gb`
- Managed Memory：Flink管理的堆外内存，用于排序、哈希表、缓存中间结果及 RocksDB StateBackend 的本地内存。
配置参数：`taskmanager.memory.managed.fraction=0.4`
`taskmanager.memory.managed.size`

**JVM specific memory：JVM本身使用的内存**
- JVM metaspace：JVM元空间
- JVM over-head执行开销：JVM执行时自身所需要的内容，包括线程堆栈、IO、编译缓存等所使用的内存。
配置参数：`taskmanager.memory.jvm-overhead.min=192mb`
`taskmanager.memory.jvm-overhead.max=1gb`
`taskmanager.memory.jvm-overhead.fraction=0.1`

<br>
**总体内存(Total Process Memory)**
- 总进程内存：Flink Java应用程序（包括用户代码）和JVM运行整个进程所消耗的总内存。
总进程内存 = Flink使用内存 + JVM元空间 + JVM执行开销
配置项：`taskmanager.memory.process.size:1728m`

- Flink总内存：仅Flink Java应用程序消耗的内存，包括用户代码，但不包括JVM为其运行而分配的内存
Flink使用内存：框架堆内外 + task堆内外 + network + manage
配置项：`taskmanager.memory.flink.size:1280m`

说明：配置项详细信息查看 [链接](
https://ci.apache.org/projects/flink/flink-docs-release-1.12/deployment/config.html#memory-configuration)


<br>
