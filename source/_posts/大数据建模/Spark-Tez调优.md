---
title: Spark-Tez调优
categories:
- 大数据建模
---
# 一、Spark
## 1.1 原理说明

![原理图](Spark-Tez调优.assets2c85806a6494f5db82bcf806925b58a.png)

详细原理见上图。
我们使用spark-submit提交一个Spark作业之后，这个作业就会启动一个对应的Driver进程。根据你使用的部署模式（deploy-mode）不同，Driver进程可能在本地启动，也可能在集群中某个工作节点上启动。Driver进程本身会根据我们设置的参数，占有一定数量的内存和CPU core。而Driver进程要做的第一件事情，就是向集群管理器（可以是Spark Standalone集群，也可以是其他的资源管理集群，美团•大众点评使用的是YARN作为资源管理集群）申请运行Spark作业需要使用的资源，这里的资源指的就是Executor进程。YARN集群管理器会根据我们为Spark作业设置的资源参数，在各个工作节点上，启动一定数量的Executor进程，每个Executor进程都占有一定数量的内存和CPU core。

Spark是根据shuffle类算子来进行stage的划分。如果我们的代码中执行了某个shuffle类算子（比如reduceByKey、join等），那么就会在该算子处，划分出一个stage界限来。可以大致理解为，shuffle算子执行之前的代码会被划分为一个stage，shuffle算子执行以及之后的代码会被划分为下一个stage。因此一个stage刚开始执行的时候，它的每个task可能都会从上一个stage的task所在的节点，去通过网络传输拉取需要自己处理的所有key，然后对拉取到的所有相同的key使用我们自己编写的算子函数执行聚合操作（比如reduceByKey()算子接收的函数）。这个过程就是shuffle。

task的执行速度是跟每个Executor进程的CPU core数量有直接关系的。一个CPU core同一时间只能执行一个线程。而每个Executor进程上分配到的多个task，都是以每个task一条线程的方式，多线程并发运行的。如果CPU core数量比较充足，而且分配到的task数量比较合理，那么通常来说，可以比较快速和高效地执行完这些task线程。

以上就是Spark作业的基本运行原理的说明，大家可以结合上图来理解。理解作业基本原理，是我们进行资源参数调优的基本前提。

## 1.2 调优参数
[官网配置](https://spark.apache.org/docs/latest/configuration.html)

| 参数 | 说明 | 默认值 | 推荐值 |
| --- | --- | --- | --- |
| num-executors/spark.executor.instances | 该参数用于设置Spark作业总共要用多少个Executor进程来执行。Driver在向YARN集群管理器申请资源时，YARN集群管理器会尽可能按照你的设置来在集群的各个工作节点上，启动相应数量的Executor进程。这个参数非常之重要，如果不设置的话，默认只会给你启动少量的Executor进程，此时你的Spark作业的运行速度是非常慢的 |  | 每个Spark作业的运行一般设置50~100个左右的Executor进程比较合适，设置太少或太多的Executor进程都不好。设置的太少，无法充分利用集群资源；设置的太多的话，大部分队列可能无法给予充分的资源。 |
| executor-cores/spark.executor.cores | 设置每个Executor进程的CPU core数量。这个参数决定了每个Executor进程并行执行task线程的能力。因为每个CPU core同一时间只能执行一个task线程，因此每个Executor进程的CPU core数量越多，越能够快速地执行完分配给自己的所有task线程。 | Yarn模式下默认为1 | 2~4个,num-executors * executor-cores不要超过队列总CPU core的1/3~1/2 |
| executor-memory/spark.executor.memory | 该参数用于设置每个Executor进程的内存。Executor内存的大小，很多时候直接决定了Spark作业的性能，而且跟常见的JVM OOM异常，也有直接的关联；不能大于container的内存值yarn.scheduler.maximum-allocation-mb |  | 4G~8G,num-executors * executor-memory不要超过队列总内存的1/3~1/2 |
| spark.executor.memoryOverhead | executor堆外内存 |默认值是max(384M, 0.07 × spark.executor.memory) | 1.5G |
| driver-memory/spark.driver.memory | 用于驱动程序进程的内存量，即初始化SparkContext内存。如果需要使用collect算子将RDD的数据全部拉取到Driver上进行处理，那么必须确保Driver的内存足够大，否则会出现OOM内存溢出的问题。 | 1G | 2G |
| spark.driver.memoryOverhead | driver堆外内存 | driverMemory * 0.10 |  |
| spark.driver.cores | 在集群模式下管理资源时，用于driver程序的CPU内核数量。 | 1 | 生产环境中调大 |
| spark.default.parallelism | 该参数用于设置每个stage的默认task数量。这个参数极为重要，如果不设置可能会直接影响你的Spark作业性能 | HDFS block对应一个task，即block数量 | 500~1000，num-executors * executor-cores的2~3倍 |
| spark.storage.memoryFraction | 该参数用于设置RDD持久化数据在Executor内存中能占的比例，默认是0.6。也就是说，默认Executor 60%的内存，可以用来保存持久化的RDD数据。根据你选择的不同的持久化策略，如果内存不够时，可能数据就不会持久化，或者数据会写入磁盘。 | 默认是0.6 | 如果Spark作业中，有较多的RDD持久化操作，该参数的值可以适当提高一些，保证持久化的数据能够容纳在内存中。避免内存不够缓存所有的数据，导致数据只能写入磁盘中，降低了性能。但是如果Spark作业中的shuffle类操作比较多，而持久化操作比较少，那么这个参数的值适当降低一些比较合适。此外，如果发现作业由于频繁的gc导致运行缓慢（通过spark web ui可以观察到作业的gc耗时），意味着task执行用户代码的内存不够用，那么同样建议调低这个参数的值。 |
| spark.shuffle.memoryFraction | 该参数用于设置shuffle过程中一个task拉取到上个stage的task的输出后，进行聚合操作时能够使用的Executor内存的比例，默认是0.2。也就是说，Executor默认只有20%的内存用来进行该操作。shuffle操作在进行聚合时，如果发现使用的内存超出了这个20%的限制，那么多余的数据就会溢写到磁盘文件中去，此时就会极大地降低性能。 | 默认是0.2 | 如果Spark作业中的RDD持久化操作较少，shuffle操作较多时，建议降低持久化操作的内存占比，提高shuffle操作的内存占比比例，避免shuffle过程中数据过多时内存不够用，必须溢写到磁盘上，降低了性能。此外，如果发现作业由于频繁的gc导致运行缓慢，意味着task执行用户代码的内存不够用，那么同样建议调低这个参数的值。 |
| spark.sql.adaptive.enabled | 开启 spark 的自适应执行后，该参数控制shuffle 阶段的平均输入数据大小，防止产生过多的task | false | true |
| spark.sql.adaptive.shuffle.targetPostShuffleInputSize | 动态调整 reduce 个数的 partition 大小依据。如设置 64MB，则 reduce 阶段每个 task 最少处理 64MB 的数据。 | 64MB |128000000 |
| spark.sql.shuffle.partitions | shuffle并发度 | 200 | 800 |
| spark.yarn.executor.memoryOverhead | executor执行的时候，用的内存可能会超过executor-memoy，所以会为executor额外预留一部分内存 | max(MEMORY_OVERHEAD_FACTOR*executorMemory, MEMORY_OVERHEAD_MIN),   默认MEMORY_OVERHEAD_FACTOR为0.1, MEMORY_OVERHEAD_MIN为384MB | |
| spark.dynamicAllocation.enabled | 开启动态资源配置 | false | true |
| spark.dynamicAllocation.minExecutors | 动态分配最小executor个数，在启动时就申请好的 | 0 | 视资源而定 |
| spark.dynamicAllocation.maxExecutors | 开启动态资源配置 | infinity | 视资源而定 |
| spark.dynamicAllocation.initialExecutors | 动态分配初始executor个数默认值| spark.dynamicAllocation.minExecutors |  |
| spark.dynamicAllocation.executorIdleTimeout | 当某个executor空闲超过这个设定值，就会被kill | 60s |  |
| spark.dynamicAllocation.cachedExecutorIdleTimeout | 当某个缓存数据的executor空闲时间超过这个设定值，就会被kill | infinity |  |
| spark.dynamicAllocation.schedulerBacklogTimeout | 任务队列非空，资源不够，申请executor的时间间隔 | 1s |  |
| spark.dynamicAllocation.sustainedSchedulerBacklogTimeout | 同schedulerBacklogTimeout，是申请了新executor之后继续申请的间隔 | 默认同schedulerBacklogTimeout |  |
| spark.executor.memory | executor堆内存 | 1G | 9G |
| spark.executor.cores | executor拥有的core数 | 1 | 3 |
| spark.locality.wait.process | 进程内等待时间 | 3 | 3 |
| spark.locality.wait.node | 节点内等待时间 | 3 | 8 |
| spark.locality.wait.rack | 机架内等待时间 | 3 | 5 |
| spark.hadoop.mapreduce.input.fileinputformat.split.minsize | 控制输入文件块的大小，影响并行度 | 3 | 5 |
| spark.hadoop.mapreduce.input.fileinputformat.split.maxsize | 控制输入文件块的大小，影响并行度| 3 | 5 |
| spark.rpc.askTimeout | rpc超时时间 | 10 | 1000 |
| spark.sql.autoBroadcastJoinThreshold | 小表需要broadcast的大小阈值 | 10485760 | 33554432 |
| spark.sql.hive.convertCTAS | 创建表是否使用默认格式 | false | true |
| spark.sql.sources.default | 默认数据源格式 | parquet | orc |
| spark.sql.files.openCostIlnBytes | 小文件合并阈值 | 4194304 | 6291456 |
| spark.sql.orc.filterPushdown | orc格式表是否谓词下推 | false | true |
| spark.shuffle.sort.bypassMergeThreshold | shuffle read task阈值，小于该值则shuffle write过程不进行排序 | 200 | 600 |
| spark.shuffle.io.retryWait | 每次重试拉取数据的等待间隔 | 5 | 30 |
| spark.shuffle.io.maxRetries | 拉取数据重试次数 | 3 | 10 |
| spark.shuffle.service.enabled | NodeManager中一个长期运行的辅助服务，用于提升Shuffle计算性能 | false | true |
| spark.speculation | 开启推测执行 | false | true |
| spark.speculation.quantile | 任务延迟的比例，比如当70%的task都完成，那么取他们运行时间的中位数跟还未执行完的任务作对比。如果超过1.2倍，则开启推测执行。 |  | 0.7 |
| spark.speculation.multiplier | 拉取数据重试次数 |  | 1.2 |
| spark.shuffle.io.maxRetries | 拉取数据重试次数 | 3 | 10 |
| spark.shuffle.io.maxRetries | 拉取数据重试次数 | 3 | 10 |
| spark.shuffle.io.maxRetries | 拉取数据重试次数 | 3 | 10 |
| hive.merge.sparkfiles | 输出时是否合并小文件 | false | true |
| spark.speculation | 是否开启推测执行 | false |  |
| spark.app.name | 设置spark任务名 | Hive on Spark | |
>如果需要指定spark使用的队列，可以通过`set mapreduce.job.queuename=default`进行设置。

**Spark内存使用说明：**
1. 通过`spark.executor.memory`指定的executor值不能大于`yarn.scheduler.maximum-allocation-mb`的值，因为executor跑在container中，如果超过container内存会报错内存越界。具体的设置还是得根据不同部门的资源队列来定，可以看看自己团队的资源队列的最大内存限制是多少，num-executors乘以executor-memory，是不能超过队列的最大内存量的1/3。
2. `spark.yarn.executor.memoryOverhead`：executor执行的时候，用的内存可能会超过executor-memoy，所以会为executor额外预留一部分内存，`spark.yarn.executor.memoryOverhead`代表了这部分内存，所以指定的`spark.executor.memory+spark.yarn.executor.memoryOverhead`不能大于`yarn.scheduler.maximum-allocation-mb`。
3. 所以当我们设置spark.executor.memory为6G时，算上预留内存一共使用内存为6G*1.1。而实际使用了7168 MB，是因为**规整化因子**，即最终使用的内存为容器最小内存`yarn.scheduler.minimum-allocation-mb`的最小整数倍。


**输入输出文件说明：**
1. 开启org.apache.hadoop.hive.ql.io.CombineHiveInputFormat而不配置分片大小的参数，所有输入会合并为一个文件，也就是说，不管你数据多大，只有一个Map。可以通过最新的参数
- set mapreduce.input.fileinputformat.split.maxsize=256000000;
- set mapreduce.input.fileinputformat.split.minsize=100000000;
来设置最终合并后文件的大小范围。


**Spark读Hive、HDFS时的Task数量:**
spark读取hdfs数据时，最终会生成HadoopRDD，所以HadoopRDD的分区数量就是task数量。
以sparkContext.textFile为例，来分析下HadoopRDD的分区数。
```
// 有两个重载方法。一个要求指定minPartitions，另一个不做要求。
def textFile(path: String): JavaRDD[String] = sc.textFile(path)

// minPartitions是指希望返回的最小分区数。也就说返回的RDD分区数大于或者等于minPartitions。
def textFile(path: String, minPartitions: Int): JavaRDD[String] =
    sc.textFile(path, minPartitions)
```
一路跟进，最终会调用到org.apache.hadoop.mapred.FileInputFormat的getSplits方法，返回的split数就是rdd分区数。

以下是getSplits方法的实现逻辑。
```
    // numSplits是期望的分片数量
    public InputSplit[] getSplits(JobConf job, int numSplits) throws IOException {
        Stopwatch sw = new Stopwatch().start();
        // 列出要读取的所有文件
        FileStatus[] files = listStatus(job);
        // 设置输入文件的个数
        job.setLong(NUM_INPUT_FILES, files.length);
        // 记录所有文件的总大小。字节
        long totalSize = 0; // compute total size

        // 遍历所有文件
        for (FileStatus file : files) {// check we have valid files
            if (file.isDirectory()) {
                throw new IOException("Not a file: " + file.getPath());
            }
            // 计算所有文件总大小
            totalSize += file.getLen();
        }
        // 算出一个分片的期望大小。如果指定的分片为0，则使用总大小除以1；否则用总大小除以期望的分片个数
        long goalSize = totalSize / (numSplits == 0 ? 1 : numSplits);
        // 最小的片大小。minSplitSize=1，SPLIT_MINSIZE默认也为1，取两者中的最大值；
        long minSize = Math.max(job.getLong(org.apache.hadoop.mapreduce.lib.input.FileInputFormat.SPLIT_MINSIZE, 1), minSplitSize);
        // 创建最终的分片列表
        ArrayList<FileSplit> splits = new ArrayList<FileSplit>(numSplits);
        NetworkTopology clusterMap = new NetworkTopology();
        // 遍历所有文件 for (FileStatus file: files) {
        Path path = file.getPath();
        // 获取这个文件大小
        long length = file.getLen();
        if (length != 0) {
            FileSystem fs = path.getFileSystem(job);
            // 获取分片位置信息
            BlockLocation[] blkLocations;
            if (file instanceof LocatedFileStatus) {
                blkLocations = ((LocatedFileStatus) file).getBlockLocations();
            } else {
                blkLocations = fs.getFileBlockLocations(file, 0, length);
            }
            // 如果文件是可切分格式的
            if (isSplitable(fs, path)) {
                // 获取文件大小
                long blockSize = file.getBlockSize();
                // 计算得出最终的分片大小。
                // 在goalSize和blockSize中取较小的值作为结果，然后去和minSize比大小，取较大的值
                long splitSize = computeSplitSize(goalSize, minSize, blockSize);
                // 剩余的字节
                long bytesRemaining = length;
                // SPLIT_SLOP =1.1。如果剩余的字节数除以分片大小大于1.1，则继续生成分片
                // 循环生成分片
                while (((double) bytesRemaining) / splitSize > SPLIT_SLOP) {
                    // 获取分片位置
                    String[][] splitHosts = getSplitHostsAndCachedHosts(blkLocations, length - bytesRemaining, splitSize, clusterMap);
                    // 生成新的分片
                    splits.add(makeSplit(path, length - bytesRemaining, splitSize, splitHosts[0], splitHosts[1]));
                    // 更新剩余字节数
                    bytesRemaining -= splitSize;
                }
                // 如果还有剩下的字节，生成独立的分片
                if (bytesRemaining != 0) {
                    String[][] splitHosts = getSplitHostsAndCachedHosts(blkLocations, length - bytesRemaining, bytesRemaining, clusterMap);
                    splits.add(makeSplit(path, length - bytesRemaining, bytesRemaining, splitHosts[0], splitHosts[1]));
                }
            } else {
                // 如果文件不可切分，则直接生成分片。
                String[][] splitHosts = getSplitHostsAndCachedHosts(blkLocations, 0, length, clusterMap);
                splits.add(makeSplit(path, 0, length, splitHosts[0], splitHosts[1]));
            }
        } else {
            // 如果文件为空，直接生成空的split
            // Create empty hosts array for zero length files
            splits.add(makeSplit(path, 0, length, new String[0]));
        }
    }
    sw.stop();
    if(LOG.isDebugEnabled()) {
        LOG.debug("Total # of splits generated by getSplits: " + splits.size() + ", TimeTaken: " + sw.elapsedMillis());
    }
    // 返回生成的split列表 
     return splits.toArray(new FileSplit[splits.size()]);
}
```
**结论：**
关键点：是否指定了minPartitions、读取的文件是否可切分
- 是否可切分：如果文件没有压缩或者使用的是BZip2压缩，则文件可切分；如果是其它压缩方式，如gzip，文件就不可切分。
-  如果指定了minPartitions，且读取的文件可切分，则返回的分区数会大于等于minPartitions。会根据文件的总大小和minPartitions计算出来每个分区的期望文件大小，来生成分区。
- 如果指定了minPartitions，且读取的文件不可切分，返回的分区数就是文件的个数
- 如果没有指定minPartitions，返回的分区数就是文件的个数。

hive也是同理。
参考[https://blog.csdn.net/ifenggege/article/details/104581273](https://blog.csdn.net/ifenggege/article/details/104581273)


<br>
## 1.3 Hive-on-spark调优案例
### 1.3.1 案例一
**数据量：10g**
![image.png](Spark-Tez调优.assets\6c0bb69381e64a37bc7913e81328c0fa.png)

可以看出：
- 随着每个executor占用的CPU core数增加，q04查询的时间显著下降，q03也下降，但幅度没那么大。

本次调优只设置了spark.executor.memory和spark.executor.cores两个参数，没有涉及到spark.executor.instances参数，而默认的spark.executor.instances为2，也就是每个作业只用到2个executor，因此还没将性能发挥到最佳。

接下来采用100g的数据量，并且增加spark.executor.instances参数的设置。

**数据量：100g**
![image.png](Spark-Tez调优.assetsabaa483f2a5453a84531128bd4cb86f.png)

可以看出：
- 调优前后查询时间有了很大的飞跃；
- 增加spark.executor.instances设置项指定每个作业占用的executor个数后性能又有很大提升（通过监控我们发现此时CPU利用率平均有好几十，甚至可以高到百分之九十几）；

至此，我们终于将整个集群性能充分发挥出来，达到目的。

最后一列配置项是根据美团技术团队博客的建议设置的，可以看出性能相比我们之前自己的设置还是有一定提升的，至少该博客里建议的设置是比较通用的，因此之后我们都采取最后一列的设置来跑TPCx-BB测试。

最后来张大图展示调优前和调优后跑100g数据的对比：
![image.png](Spark-Tez调优.assets\5ea9981d9c00467ca63bd55d0bdfe5e4.png)

可以看出：

绝大多数查询调优前后查询时间有了极大的飞跃；

但是像q01/q04/q14…这几个查询，可能因为查询涉及到的表比较小，调优前时间就很短，因此调优后也看不出很多差别，如果想看到大的差别，可能需要提高数据量，比如1T，3T；

q10和q18调优前后时间都较长，而且调优后性能没有提升，需要再深入探索下是什么原因。

最后，用调优后的集群，分别跑10g、30g、100g的数据，结果如下：
![image.png](Spark-Tez调优.assets\4dfd60fa1b024adc87024c193ab12c98.png)

可以看出：
- 随着数据量增大，很多查询时间并没有明显增加，可能是因为集群性能太强，而且数据量还不够大，可以增大数据量继续观察
- 对于q10、q18和q30，随着数据量增大，时间明显增大，需再深入分析


### 1.3.2 案例二：GroupBy导致的数据倾斜优化
#### 数据倾斜问题
通常是指参与计算的数据分布不均，即某个key或者某些key的数据量远超其他key，导致在shuffle阶段，大量相同key的数据被发往一个Reduce，进而导致该Reduce所需的时间远超其他Reduce，成为整个任务的瓶颈。
Hive中的数据倾斜常出现在分组聚合和join操作的场景中，下面分别介绍在上述两种场景下的优化思路。

**示例SQL语句如下**
```
select
    province_id,
    count(*)
from dwd_trade_order_detail_inc
where dt='2020-06-16'
group by province_id;
```
**优化前的执行计划**
![image.png](Spark-Tez调优.assets\32617fd55b04430c821ac738e4eaf758.png)

<br>
#### 优化思路
由分组聚合导致的数据倾斜问题主要有以下两种优化思路：
**1）启用map-side聚合**
- 1. 启用map-side聚合 `set hive.map.aggr=true;`
- 2. hash map占用map端内存的最大比例 `set hive.map.aggr.hash.percentmemory=0.5;`

启用map-side聚合后的执行计划如下图所示
![image.png](Spark-Tez调优.assets\73261bed766b48538f2573d11c746ee7.png)

**2）启用skew groupby优化**
其原理是启动两个MR任务，第一个MR按照随机数分区，将数据分散发送到Reduce，完成部分聚合，第二个MR按照分组字段分区，完成最终聚合。
相关参数如下：
- 启用分组聚合数据倾斜优化
`set hive.groupby.skewindata=true;`

启用skew groupby优化后的执行计划如下图所示
![image.png](Spark-Tez调优.assets\41e29e53a65f4cde9a80c813525ba68f.png)

### 1.3.3 案例三：JOIN导致的数据倾斜优化
**示例SQL如下**
```
select
    *
from
(
    select
        *
    from dwd_trade_order_detail_inc
    where dt='2020-06-16'
)fact
join
(
    select
        *
    from dim_province_full
    where dt='2020-06-16'
)dim
on fact.province_id=dim.id;
```
**优化前的执行计划**
![image.png](Spark-Tez调优.assets5727bfca68e4938a8406b93e960ae0b.png)

#### 优化思路
由join导致的数据倾斜问题主要有以下两种优化思路：
**1）使用map join优化**
相关参数如下：
- 启用map join自动转换
`set hive.auto.convert.join=true;`
- common join转map join小表阈值
`set hive.auto.convert.join.noconditionaltask.size`

使用map join优化后执行计划如下图
![image.png](Spark-Tez调优.assetsc80b1dce354297ba115d056918a504.png)

**2）启用skew join优化**
其原理如下图
![image.png](Spark-Tez调优.assetsfaf784b2c3f4028ba2d5d2fa006edfe.png)

相关参数如下：
- 启用skew join优化
`set hive.optimize.skewjoin=true;`
- 触发skew join的阈值，若某个key的行数超过该参数值，则触发
`set hive.skewjoin.key=100000;`
需要注意的是，**skew join只支持Inner Join**。

启动skew join优化后的执行计划如下图所示：
![image.png](Spark-Tez调优.assets441d3fcd24e4456ad16395e1d5847ba.png)


<br>
## 1.4 常用配置
### 1.4.1 任务并行度优化
**优化说明**
对于一个分布式的计算任务而言，设置一个合适的并行度十分重要。在Hive中，无论其计算引擎是什么，所有的计算任务都可分为Map阶段和Reduce阶段。所以并行度的调整，也可从上述两个方面进行调整。

#### 1.4.1.1 Map阶段并行度
Map端的并行度，也就是Map的个数。是由输入文件的切片数决定的。一般情况下，Map端的并行度无需手动调整。Map端的并行度相关参数如下：
- 可将多个小文件切片，合并为一个切片，进而由一个map任务处理
`set hive.input.format=org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;`

- 一个切片的最大值
`set mapreduce.input.fileinputformat.split.maxsize=256000000;`

#### 1.4.1.2 Reduce阶段并行度

Reduce端的并行度，相对来说，更需要关注。默认情况下，Hive会根据Reduce端输入数据的大小，估算一个Reduce并行度。但是在某些情况下，其估计值不一定是最合适的，故需要人为调整其并行度。

Reduce并行度相关参数如下：
- 指定Reduce端并行度，默认值为-1，表示用户未指定
`set mapreduce.job.reduces;`
- Reduce端并行度最大值
`set hive.exec.reducers.max;`
- 单个Reduce Task计算的数据量，用于估算Reduce并行度
`set hive.exec.reducers.bytes.per.reducer;`

Reduce端并行度的确定逻辑为，若指定参数mapreduce.job.reduces的值为一个非负整数，则Reduce并行度为指定值。否则，Hive会自行估算Reduce并行度，估算逻辑如下：
假设Reduce端输入的数据量大小为totalInputBytes
参数hive.exec.reducers.bytes.per.reducer的值为bytesPerReducer
参数hive.exec.reducers.max的值为maxReducers
则Reduce端的并行度为：
![image.png](Spark-Tez调优.assets\d30fa7f09dca412994ba22aa62a3bb82.png)

其中，Reduce端输入的数据量大小，是从Reduce上游的Operator的Statistics（统计信息）中获取的。为保证Hive能获得准确的统计信息，需配置如下参数：
- 执行DML语句时，收集表级别的统计信息
`set hive.stats.autogather=true;`
- 执行DML语句时，收集字段级别的统计信息
`set hive.stats.column.autogather=true;`
- 计算Reduce并行度时，从上游Operator统计信息获得输入数据量
`set hive.spark.use.op.stats=true;`
- 计算Reduce并行度时，使用列级别的统计信息估算输入数据量
`set hive.stats.fetch.column.stats=true;`

### 1.4.2 小文件合并优化
#### 1.4.2.1 优化说明
小文件合并优化，分为两个方面，分别是Map端输入的小文件合并，和Reduce端输出的小文件合并。
#### 1.4.2.2 Map端输入文件合并
合并Map端输入的小文件，是指将多个小文件划分到一个切片中，进而由一个Map Task去处理。目的是防止为单个小文件启动一个Map Task，浪费计算资源。
相关参数为：
- 可将多个小文件切片，合并为一个切片，进而由一个map任务处理
`set hive.input.format=org.apache.hadoop.hive.ql.io.CombineHiveInputFormat; `

#### 1.4.2.3 Reduce输出文件合并
合并Reduce端输出的小文件，是指将多个小文件合并成大文件。目的是减少HDFS小文件数量。
相关参数为：
- 开启合并Hive on Spark任务输出的小文件
`set hive.merge.sparkfiles=true;`


#### 1.4.2.4 从HDFS读取数据的任务切分
Spark从HDFS中读取数据，会先合并小文件，然后进行导入，默认按Block大小切分为多个HadoopRDD，每个RDD对应一个task。如果希望能切分更多task，可以通过如下设置配置每个分块大小，单位为Byte。
```
set mapreduce.input.fileinputformat.split.maxsize=10000000;
```

## 1.4.3 Spark执行资源配置
hive on spark参数配置（静态分配instance）
```sql
set spark.app.name='${filename}';
set mapreduce.job.queuename=job;

set hive.execution.engine=spark;
set spark.executor.instances=4;
set spark.executor.cores=3;
set spark.executor.memory=6G;
set spark.driver.memory=819m;
set spark.driver.memoryOverhead=205m;
set spark.default.parallelism=30;
set spark.sql.shuffle.partitions=30;
set mapreduce.input.fileinputformat.split.maxsize=10000000;
set spark.serializer=org.apache.spark.serializer.KryoSerializer;
set hive.merge.sparkfiles=true;
```

hive on spark参数配置（动态分配instance）
```sql
-- 启动动态分配
set spark.dynamicAllocation.enabled=true;
-- 启用Spark shuffle服务
set spark.shuffle.service.enabled=true;
-- Executor个数初始值
set spark.dynamicAllocation.initialExecutors=1;
-- Executor个数最小值
set spark.dynamicAllocation.minExecutors=1;
-- Executor个数最大值
set spark.dynamicAllocation.maxExecutors=12;
-- Executor空闲时长，若某Executor空闲时间超过此值，则会被关闭
set spark.dynamicAllocation.executorIdleTimeout=60s;
-- 积压任务等待时长，若有Task等待时间超过此值，则申请启动新的Executor
set spark.dynamicAllocation.schedulerBacklogTimeout=1s;
set spark.shuffle.useOldFetchProtocol=true;
```
>说明：Spark shuffle服务的作用是管理Executor中的各Task的输出文件，主要是shuffle过程map端的输出文件。由于启用资源动态分配后，Spark会在一个应用未结束前，将已经完成任务，处于空闲状态的Executor关闭。Executor关闭后，其输出的文件，也就无法供其他Executor使用了。需要启用Spark shuffle服务，来管理各Executor输出的文件，这样就能关闭空闲的Executor，而不影响后续的计算任务了。

<br>
### 1.4.4 hive on spark的超时时间配置
```
    <!-- Spark driver连接Hive client的超时时间,默认单位毫秒 -->
    <property>
        <name>hive.spark.client.connect.timeout</name>
        <value>600000ms</value>
    </property>
    <!-- Hive client和远程Spark client握手的超时时间,默认单位毫秒 -->
    <property>
        <name>hive.spark.client.server.connect.timeout</name>
        <value>600000ms</value>
    </property>
    <!-- Hive client请求Spark driver的超时时间,默认单位秒 -->
    <property>
        <name>hive.spark.client.future.timeout</name>
        <value>600s</value>
    </property>
    <!-- Job监控获取Spark作业状态的超时时间,默认单位秒 -->
    <property>
        <name>hive.spark.client.future.timeout</name>
        <value>600s</value>
    </property>
```

### 1.4.5 其他优化
参考资料：
1.[https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/admin_hos_tuning.html#hos_tuning](https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/admin_hos_tuning.html#hos_tuning)
2.https://cwiki.apache.org/confluence/display/Hive/Hive+on+Spark%3A+Getting+Started](https://cwiki.apache.org/confluence/display/Hive/Hive+on+Spark%3A+Getting+Started)


<br>
# 二、Tez调优
详细配置可查看官网的[Tez配置](https://tez.apache.org/releases/0.8.4/tez-api-javadocs/configs/TezConfiguration.html)和[TezRuntime配置](https://tez.apache.org/releases/0.10.1/tez-api-javadocs/configs/TezConfiguration.html)

- **tez.runtime.io.sort.mb**是当需要对输出进行排序的内存。
- **tez.runtime.unordered.output.buffer.size-mb**是输出不需要排序的内存。
- **hive.auto.convert.join.noconditionaltask.size**是一个非常重要的参数，用于设置执行Map join时的内存大小。
- **tez.am.resource.memory.mb**设置为与**yarn.scheduler.minimum-allocate-mb** YARN最小容器大小相同。 
- **hive.tez.container.size**设置为与**yarn.scheduler.minimum-allocation-mb**大小相同或小倍数(1或2倍)，但不能超过**yarn.scheduler.maximum-allocation-mb**。
- **tez.runtime.io.sort.mb**为**hive.tez.container.size**的40%，不应该超过2gb。
- **hive.auto.convert.join.noconditionaltask.size**为**hive.tez.container.size**的1/3
- **tez.runtime.unordered.output.buffer.size-mb**为**hive.tez.container.size**的10%

**1. AM、Container大小设置**
- tez.am.resource.memory.mb　　#设置 tez AM容器内存
　　默认值：1024　　
　　配置文件：tez-site.xml
　　建议：等于yarn.scheduler.minimum-allocation-mb值。
　　
>**Note：**遇到过tez执行数据量特别大的任务时，一直卡在Scheduled阶段的情况。需要调整am的大小
set tez.am.resource.memory.mb=5120;
set tez.am.launch.cmd-opts=-Xms5120m -Xmx5120m;

- hive.tez.container.size　　#设置 tez container内存
　　默认值：-1
　　默认情况下，Tez将生成一个mapper大小的容器。这可以用来覆盖默认值。
　　配置文件：hive-site.xml
　　建议：等于或几倍于yarn.scheduler.minimum-allocation-mb值，但是不能大于yarn.scheduler.maximum-allocation-mb。

<br>
**2. AM、Container JVM参数设置**
- tez.am.launch.cmd-opts　　#设置 AM jvm，启动TEZ任务进程期间提供的命令行选项。
　　默认值：-XX:+PrintGCDetails -verbose:gc -XX:+PrintGCTimeStamps -XX:+UseNUMA -XX:+UseParallelGC(用于GC)，默认的大小：80%*tez.am.resource.memory.mb
　　配置文件：tez-site.xml
　　建议：不要在这些启动选项中设置任何xmx或xms，以便tez可以自动确定它们。
　　
- tez.task.launch.cmd-opts
   默认值：启动的JVM参数 ，默认-XX:+PrintGCDetails -verbose:gc -XX:+PrintGCTimeStamps -XX:+UseNUMA -XX:+UseParallelGC

- tez.container.max.java.heap.fraction
   说明：基于yarn提供的内存，分配给java进程的百分比，默认是0.8，具体大小取决于mapreduce.reduce.memory.mb和mapreduce.map.memory.mb。一般不用变即可


- hive.tez.java.ops　　#设置 container jvm
　　默认值：Hortonworks建议“–server –Djava.net.preferIPv4Stack=true–XX:NewRatio=8 –XX:+UseNUMA –XX:UseG1G”，默认大小：80%*hive.tez.container.size
　　配置文件：hive-site.xml
　　建议：Hortonworks建议“–server –Djava.net.preferIPv4Stack=true–XX:NewRatio=8 –XX:+UseNUMA –XX:UseG1G”

- tez.container.max.java.heap.fraction　　#设置task/AM占用jvm内存大小的比例。
　　默认值：0.8
　　配置文件：tez-site.xml
　　说明：task\AM占用JVM Xmx的比例，这个值按具体需要调整，当内存不足时，一般都要调小。

<br>
**3. Hive内存Map Join参数设置**
- tez.runtime.io.sort.mb　　#设置输出排序内存大小
　　默认值：100
　　配置文件：tez-site.xml
　　建议：40%*hive.tez.container.size，一般不超过2G


- hive.auto.convert.join  #是否自动转换为mapjoin
　　默认值：true
　　建议使用默认值。
　　配置文件：hive-site.xml

- hive.auto.convert.join.noconditionaltask　　#是否将多个mapjoin合并为一个
　　默认值：true
　　建议使用默认值。
　　配置文件：hive-site.xml

- hive.auto.convert.join.noconditionaltask.size  
　　默认值：10000000　　(10M)
　　说明：这个参数使用的前提是hive.auto.convert.join.noconditionaltask值为true，多个mapjoin转换为1个时，所有小表的文件大小总和小于这个值，这个值只是限制输入的表文件的大小，并不代表实际mapjoin时hashtable的大小。 建议值：1/3* hive.tez.container.size
　　配置文件：hive-site.xml

- tez.runtime.unordered.output.buffer.size-mb　　#如果不直接写入磁盘，使用的缓冲区大小. Size of the buffer to use if not writing directly to disk.
　　默认值：100M
 　建议：10%* hive.tez.container.size
　　配置文件：tez-site.xml

- tez.am.container.reuse.enabled　　#容器重用
　　默认值：true
　　配置文件：tez-ste.xml

<br>
**4. Hive使用CPU设置**
- hive.tez.cpu.vcores
　　默认值：-1
 　  说明：每个容器分配的CPU个数
　　配置文件：hive-site.xml

- tez.am.resource.cpu.vcores
   说明：am分配的cpu个数，默认1

<br>
**5.Mapper/Reducer设置**

①Mapper数设置
在Tez分配任务时，不会像mr那样为每个split生成一个map任务，而是会将多个split进行grouping，让map任务更高效地的完成。首先Tez会根据计算得到的 estimated number of tasks = 5，将splits聚合为5个Split Group，生成5个mapper执行任务。
Tez会检查lengthPerGroup是否在 tez.grouping.min-size （默认为50MB）以及 tez.grouping.max-size（默认为1GB） 定义范围内。如果超过了max-size，则指定lengthPerGroup为max-size，如果小于min-size，则指定lengthPerGroup为min-size。

- tez.grouping.min-size
   默认值：5010241024 (50M)
   参数说明：Lower bound on the size (in bytes) of a grouped split, to avoid generating too many small splits.

- tez.grouping.max-size
   默认值：102410241024
   参数说明：Upper bound on thesize (in bytes) of a grouped split, to avoid generating excessively largesplits.

- tez.grouping.split-count
   默认值：无
   参数说明：group的分割组数，并不是精确指定切分数量。当设置的值大于原始的895时，tez会直接使用895。


②Reducer数设置
- hive.tez.auto.reducer.parallelism
默认值：false
参数说明：Tez会估计数据量大小，设置并行度。在运行时会根据需要调整估计值。Turn on Tez' autoreducer parallelism feature. When enabled, Hive will still estimate data sizesand set parallelism estimates. Tez will sample source vertices' output sizesand adjust the estimates at runtime as necessary.
建议设置为true.

- hive.tex.min.partition.factor
默认值：0.25
参数说明：When auto reducerparallelism is enabled this factor will be used to put a lower limit to thenumber of reducers that Tez specifies.

- hive.tez.max.partition.factor
默认值：2.0
参数说明：When auto reducerparallelism is enabled this factor will be used to over-partition data inshuffle edges.

- hive.exec.reducers.bytes.per.reducer
默认值：256,000,000 (256M)
参数说明：每个reduce的数据处理量。Sizeper reducer. The default in Hive 0.14.0 and earlier is 1 GB, that is, if theinput size is 10 GB then 10 reducers will be used. In Hive 0.14.0 and later thedefault is 256 MB, that is, if the input size is 1 GB then 4 reducers willbe used.

- mapred.reduce.tasks
默认值：-1
参数说明：同mapreduce引擎配置，指定reduce的个数。

- hive.exec.reducers.max
默认值：1009
参数说明：最大reduce个数

   以下公式确认Reducer个数：
   `Max(1, Min(hive.exec.reducers.max [1009], ReducerStage estimate/hive.exec.reducers.bytes.per.reducer)) x hive.tez.max.partition.factor`

③Shuffle参数设置
- tez.shuffle-vertex-manager.min-src-fraction
默认值：0.25
参数说明：thefraction of source tasks which should complete before tasks for the currentvertex are scheduled.

- tez.shuffle-vertex-manager.max-src-fraction
默认值：0.75
参数说明：oncethis fraction of source tasks have completed, all tasks on the current vertexcan be scheduled. Number of tasks ready for scheduling on the current vertexscales linearly between min-fraction and max-fraction.

>**例子：**
>hive.exec.reducers.bytes.per.reducer=1073741824; // 1GB
>tez.shuffle-vertex-manager.min-src-fraction=0.25；
>tez.shuffle-vertex-manager.max-src-fraction=0.75；
>
>**说明：**This indicates thatthe decision will be made between 25% of mappers finishing and 75% of mappersfinishing, provided there's at least 1Gb of data being output (i.e if 25% ofmappers don't send 1Gb of data, we will wait till at least 1Gb is sent out).


<br>
**5. 其他设置**
- tez.job.name
   说明：设置tez任务名

- tez.am.speculation.enabled
   说明：是否开启推测执行，默认是false，在出现最后一个任务很慢的情况下，建议把这个参数设置为true

- tez.task.log.level
   说明：日志级别，默认info

- tez.queue.name
   说明：在yarn中的默认执行队列


- tez.am.task.max.failed.attempts
   说明：任务中attempts失败的最大重试次数，默认跟yarn一样是4次 ，在不稳定集群可以设置大一点


- tez.am.max.app.attempts
   说明：am自己失败的最大重试次数，默认是2次。这里并不是说am自己挂了，只是因为一些系统原因导致失联了

- set mapreduce.input.fileinputformat.input.dir.recursive=true
   说明：因为Tez使用Insert ... UNION ALL 语句，会将每个UNION ALL结果单独存文件夹。需要设置mr引擎递归查询，对spark引擎同样生效。


<br>
**6. 实例**
在Hive 中执行一个query时，我们可以发现Hive 的执行引擎在使用 Tez 与 MR时，两者生成mapper数量差异较大。主要原因在于 Tez 中对 inputSplit 做了 grouping 操作，将多个 inputSplit 组合成更少的 groups，然后为每个 group 生成一个 mapper 任务，而不是为每个inputSplit 生成一个mapper 任务。下面我们通过日志分析一下这中间的整个过程。

调整inputFormt为CombineInputFormat合并小文件可以有效减少作业中Mapper的数量。


1）MapReduce模式
在 mr 模式下，生成的container数为116个：

对应日志条目为：
Input size for job job_1566964005095_0003 = 31733311148. Number of splits = 116

在MR中，使用的是Hadoop中的FileInputFormat，所以若是一个文件大于一个block的大小，则会切分为多个InputSplit；若是一个文件小于一个block大小，则为一个InputSplit。

在这个例子中，总文件个数为14个，每个均为2.1GB，一共29.4GB大小。生成的InputSplit数为116个，也就是说，每个block（这个场景下InputSplit 大小为一个block大小）的大小大约为256MB。

2）Tez模式

而在Tez模式下，生成的map任务为32个：

生成split groups的相关日志如下：
```
mapred.FileInputFormat|: Total input files to process : 14
io.HiveInputFormat|: number of splits 476
tez.HiveSplitGenerator|: Number of input splits: 476. 3 available slots, 1.7 waves. Input format is: org.apache.hadoop.hive.ql.io.HiveInputFormat

tez.SplitGrouper|: # Src groups for split generation: 2
tez.SplitGrouper|: Estimated number of tasks: 5 for bucket 1
grouper.TezSplitGrouper|: Grouping splits in Tez
|grouper.TezSplitGrouper|: Desired splits: 5 too small. Desired splitLength: 6346662229 Max splitLength: 1073741824 New desired splits: 30 Total length: 31733311148 Original splits: 476
|grouper.TezSplitGrouper|: Desired numSplits: 30 lengthPerGroup: 1057777038 numLocations: 1 numSplitsPerLocation: 476 numSplitsInGroup: 15 totalLength: 31733311148 numOriginalSplits: 476 . Grouping by length: true count: false nodeLocalOnly: false
|grouper.TezSplitGrouper|: Doing rack local after iteration: 32 splitsProcessed: 466 numFullGroupsInRound: 0 totalGroups: 31 lengthPerGroup: 793332736 numSplitsInGroup: 11
|grouper.TezSplitGrouper|: Number of splits desired: 30 created: 32 splitsProcessed: 476
|tez.SplitGrouper|: Original split count is 476 grouped split count is 32, for bucket: 1
|tez.HiveSplitGenerator|: Number of split groups: 32
```

<br>
**Avaiable Slots**

首先可以看到，需要处理的文件数为14，初始splits数目为476（即意味着在这个场景下，一个block的大小约为64MB）。对应日志条目如下：

|mapred.FileInputFormat|: Total input files to process : 14

|io.HiveInputFormat|: number of splits 476

获取到splits的个数为476个后，Driver开始计算可用的slots（container）数，这里计算得到3个slots，并打印了默认的waves值为1.7。
在此场景中，集群一共资源为 8 vcore，12G 内存，capacity-scheduler中指定的user limit factor 为0.5，也就是说：当前用户能使用的资源最多为 6G 内存。在Tez Driver中，申请的container 资源的单位为： Default Resources=<memory:1536, vCores:1>

所以理论上可以申请到的container 数目为4（6G/1536MB = 4）个，而由于 Application Master 占用了一个container，所以最终available slots为3个。

在计算出了可用的slots为3个后，Tez 使用split-waves 乘数（由tez.grouping.split-waves指定，默认为1.7）指定“预估”的Map 任务数目为：3 × 1.7 = 5 个tasks。对应日志条目如下：

|tez.HiveSplitGenerator|: Number of input splits: 476. 3 available slots, 1.7 waves. Input format is: org.apache.hadoop.hive.ql.io.HiveInputFormat

|tez.SplitGrouper|: Estimated number of tasks: 5 for bucket 1

<br>
**Grouping Input Splits**

在Tez分配任务时，不会像mr那样为每个split生成一个map任务，而是会将多个split进行grouping，让map任务更高效地的完成。首先Tez会根据计算得到的 estimated number of tasks = 5，将splits聚合为5个Split Group，生成5个mapper执行任务。

**但是这里还需要考虑另一个值**：lengthPerGroup。Tez会检查lengthPerGroup是否在 tez.grouping.min-size （默认为50MB）以及 tez.grouping.max-size（默认为1GB） 定义范围内。如果超过了max-size，则指定lengthPerGroup为max-size，如果小于min-size，则指定lengthPerGroup为min-size。

在这个场景下，数据总大小为 31733311148 bytes（29.5GB左右，也是原数据大小），预估为5个Group， 则每个Group的 splitLength为6346662229 bytes（5.9GB 左右），超过了 Max splitLength = 1073741824 bytes（ 1GB），所以重新按 splitLength = 1GB 来算，计算出所需的numSplits 数为 30 个，每个Split Group的大小为1GB。

在计算出了每个Split Group的大小为1GB后，由于原Split总数目为476，所以需要将这476个inputSplit进行grouping，使得每个Group的大小大约为1GB左右。按此方法计算，预期的splits数目应为30个（但是仅是通过总数据大小/lengthPerGroup得出，尚未考虑inputSplits如何合并的问题，不一定为最终生成的map tasks数目）。且最终可计算得出每个group中可以包含15个原split，也就是numSplitsInGroup = 15。相关日志条目如下：

|grouper.TezSplitGrouper|: Grouping splits in Tez

|grouper.TezSplitGrouper|: Desired splits: 5 too small. Desired splitLength: 6346662229 Max splitLength: 1073741824 New desired splits: 30 Total length: 31733311148 Original splits: 476

|grouper.TezSplitGrouper|: Desired numSplits: 30 lengthPerGroup: 1057777038 numLocations: 1 numSplitsPerLocation: 476 numSplitsInGroup: 15 totalLength: 31733311148 numOriginalSplits: 476 . Grouping by length: true count: false nodeLocalOnly: false

原splits总数目为 476，在对splits进行grouping时，每个group中将会包含15个inputSplits，所以最终可以计算出的group数目为 476/15 = 32 个，也就是最终生成的mapper数量。

|tez.SplitGrouper|: Original split count is 476 grouped split count is 32, for bucket: 1

|tez.HiveSplitGenerator|: Number of split groups: 32

所以在Tez中，inputSplit 数目虽然是476个，但是最终仅生成了32个map任务用于处理所有的 475个inputSplits，减少了过多mapper任务会带来的额外开销。

<br>
**Split Waves**
这里为什么要定义一个split waves值呢？使用此值之后会让Driver申请更多的container，比如此场景中本来仅有3个slots可用，但是会根据这个乘数再多申请2个container资源。但是这样做的原因是什么呢？
1. 首先它可以让分配资源更灵活：比如集群之后添加了计算节点、其他任务完成后释放了资源等。所以即使刚开始会有部分map任务在等待资源，它们在后续也会很快被分配到资源执行任务
2. 将数据分配给更多的map任务可以提高并行度，减少每个map任务中处理的数据量，并缓解由于少部分map任务执行较慢，而导致的整体任务变慢的情况
