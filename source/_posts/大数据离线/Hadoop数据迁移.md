---
title: Hadoop数据迁移
categories:
- 大数据离线
---
# 一、磁盘数据均衡
## 1.1 问题
在hdfs存储数据时，通过dfs.datanode.data.dir设置了三个文件存储目录file://${hadoop.tmp.dir}/dfs/data,file:///dfs/data1,file:///home/dfs/data2，分别对应了三个硬盘。
目前有一块较小的硬盘数据满了，

## 1.2 解决
### 1.2.1 方法一
通过命令在节点内自动平衡各个硬盘间的数据。

1. 创建计划 `hdfs diskbalancer -plan {主机名}`
会将执行计划放到hdfs上的指定路径


2. 查看计划 ``

3. 执行计划执行命令 `hdfs diskbalancer -execute /system/diskbalancer/2021-十一月-11-13-45-12/bigdata1.plan.json`

4. 检查执行情况和结果 `hdfs diskbalancer -query {主机名}`
```
[root@cos-bigdata-hadoop-01 /]#  hdfs diskbalancer -query bigdata1
2021-11-11 13:54:05,958 INFO command.Command: Executing "query plan" command.
Plan File: /system/diskbalancer/2021-十一月-11-13-45-12/bigdata1.plan.json
Plan ID: 4e36e294eb8d835a6a6c807fbc399f4f771c2487
Result: PLAN_UNDER_PROGRESS
```

Result是当前执行状态：
- PLAN_UNDER_PROGRESS表示正在执行磁盘均衡操作
- PLAN_DONE表示已经完成。


### 1.2.2 方法二
首先停止hadoop所有服务，然后将该磁盘上存储hdfs数据的文件夹复制到富余的磁盘中，然后修改hdfs-site.xml中的配置dfs.datanode.data.dir，指向新的文件路径。
操作有风险。


<br>
# 二、磁盘路径删除
## 2.1 问题
hadoop的每个datanode节点有3个数据磁盘，但是有一个数据磁盘很小，该磁盘会率先写满磁盘，磁盘写满后就不能在写入日志和中间文件，导致无法进行MR，节点就会变为inactive状态，不可用。希望将这个盘符删除出hdfs存储路径，且保证数据不丢失。

## 2.2 解决
移除的动作不能直接从集群中移除，因为数据还存放在这些磁盘中。我们知道，hadoop默认是3份副本，移除一块或者两块磁盘，数据是不会丢失的。为了保险起见，我们一块一块操作，移除一块之后，会有若干副本丢失。

1. 停止hdfs集群
```
stop-dfs.sh
```
2. 在配置文件中删除该盘符
```
    <property>
        <name>dfs.datanode.data.dir</name>
        <!--<value>file://${hadoop.tmp.dir}/dfs/data,file:///dfs/data1,file:///home/dfs/data2</value>-->
        <value>file://${hadoop.tmp.dir}/dfs/data</value>
    </property>
```
3. 启动hdfs集群，会开始检查数据副本的情况。打开hdfs的UI界面，最后有一个检查报告，提示block损坏的情况，和副本的丢失情况。因为已经删除一个磁盘，可能会有很多数据只有2个副本。有的临时的jar文件，由于副本数被设置为1，所以会丢失，不过这些是Mapreduce临时生成的文件，不影响数据的完整性。
4. 运行`hadoop fs -setrep -w 3 -R /, 重新生成副本, 如果中途出现out of memory，则重新运行该命令即可
5. 查看检查报告看看有哪些目录的数据丢失，是否无关数据，删除这些无关数据：hadoop fsck <目录> -delete

## 2.3 查看状态
**1. 查看节点、hdfs、丢失的数据块 命令：**`hdfs dfsadmin -report`
```
Configured Capacity: 10809436413952 (9.83 TB)
Present Capacity: 8469607092540 (7.70 TB)
DFS Remaining: 6084234952704 (5.53 TB)
DFS Used: 2385372139836 (2.17 TB)
DFS Used%: 28.16%
Replicated Blocks:
	Under replicated blocks: 58219
	Blocks with corrupt replicas: 65
	Missing blocks: 0
	Missing blocks (with replication factor 1): 0
	Low redundancy blocks with highest priority to recover: 22
	Pending deletion blocks: 0
Erasure Coded Block Groups: 
	Low redundancy block groups: 0
	Block groups with corrupt internal blocks: 0
	Missing block groups: 0
	Low redundancy blocks with highest priority to recover: 0
	Pending deletion blocks: 0

-------------------------------------------------
Live datanodes (3):

Name: 192.168.101.179:9866 (bigdata1)
Hostname: bigdata1
Decommission Status : Normal
Configured Capacity: 2144236208128 (1.95 TB)
DFS Used: 527111639356 (490.91 GB)
Non DFS Used: 482234957508 (449.12 GB)
DFS Remaining: 1134889611264 (1.03 TB)
DFS Used%: 24.58%
DFS Remaining%: 52.93%
Configured Cache Capacity: 0 (0 B)
Cache Used: 0 (0 B)
Cache Remaining: 0 (0 B)
Cache Used%: 100.00%
Cache Remaining%: 0.00%
Xceivers: 1
Last contact: Sun Apr 24 17:00:20 CST 2022
Last Block Report: Sun Apr 24 16:23:17 CST 2022
Num of Blocks: 55384


Name: 192.168.101.180:9866 (bigdata2)
Hostname: bigdata2
Decommission Status : Normal
Configured Capacity: 4332600102912 (3.94 TB)
DFS Used: 928879513600 (865.09 GB)
Non DFS Used: 930558398464 (866.65 GB)
DFS Remaining: 2473162190848 (2.25 TB)
DFS Used%: 21.44%
DFS Remaining%: 57.08%
Configured Cache Capacity: 0 (0 B)
Cache Used: 0 (0 B)
Cache Remaining: 0 (0 B)
Cache Used%: 100.00%
Cache Remaining%: 0.00%
Xceivers: 1
Last contact: Sun Apr 24 17:00:22 CST 2022
Last Block Report: Sun Apr 24 16:23:19 CST 2022
Num of Blocks: 113416


Name: 192.168.101.181:9866 (bigdata3)
Hostname: bigdata3
Decommission Status : Normal
Configured Capacity: 4332600102912 (3.94 TB)
DFS Used: 929380986880 (865.55 GB)
Non DFS Used: 927035965440 (863.37 GB)
DFS Remaining: 2476183150592 (2.25 TB)
DFS Used%: 21.45%
DFS Remaining%: 57.15%
Configured Cache Capacity: 0 (0 B)
Cache Used: 0 (0 B)
Cache Remaining: 0 (0 B)
Cache Used%: 100.00%
Cache Remaining%: 0.00%
Xceivers: 1
Last contact: Sun Apr 24 17:00:22 CST 2022
Last Block Report: Sun Apr 24 16:23:19 CST 2022
Num of Blocks: 113416
```

**2. 查看文件系统的健康状况：**`hdfs fsck --<path> [-options]` , 用这个命令 `hdfs fsck /`
 可以检查整个文件系统的健康状况，但是要注意它不会主动恢复备份缺失的block，这个是由NameNode单独的线程异步处理的。
```
Usage: hdfs fsck <path> [-list-corruptfileblocks | [-move | -delete | -openforwrite] [-files [-blocks [-locations | -racks | -replicaDetails | -upgradedomains]]]] [-includeSnapshots] [-showprogress] [-storagepolicies] [-maintenance] [-blockId <blk_Id>]
	<path>	start checking from this path (检查这个目录中的文件是否完整)
	-move	move corrupted files to /lost+found ( 破损的文件移至/lost+found目录)
	-delete	delete corrupted files (删除破损的文件)
	-files	print out files being checked (打印正在check的文件名)
	-openforwrite	print out files opened for write (打印正在打开写操作的文件)
	-includeSnapshots	include snapshot data if the given path indicates a snapshottable directory or there are snapshottable directories under it
	-list-corruptfileblocks	print out list of missing blocks and files they belong to
	-files -blocks	print out block report (打印block报告 （需要和-files参数一起使用）)
	-files -blocks -locations	print out locations for every block (打印每个block的位置信息（需要和-files参数一起使用）)
	-files -blocks -racks	print out network topology for data-node locations (打印位置信息的网络拓扑图 （需要和-files参数一起使用）)
	-files -blocks -replicaDetails	print out each replica details 
	-files -blocks -upgradedomains	print out upgrade domains for every block
	-storagepolicies	print out storage policy summary for the blocks
	-maintenance	print out maintenance state node details
	-showprogress	show progress in output. Default is OFF (no progress)
	-blockId	print out which file this blockId belongs to, locations (nodes, racks) of this block, and other diagnostics info (under replicated, corrupted or not, etc)
```

如果hadoop不能自动恢复，则只能删除损坏的blocks： `hdfs fsck -delete`
