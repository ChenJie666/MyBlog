---
title: Hadoop命令
categories:
- 大数据离线
---
## 进程命令
#### 对hadoop集群的操作
start-dfs.sh  stop-dfs.sh   打开和关闭dfs
start-yarn.sh  stop-yarn.sh   打开和关闭yarn

#### hadoop单进程操作
**旧版本命令**
hadoop-daemon.sh  start/stop  namenode/datanode/secondarynamenode  
yarn-daemon.sh  start/stop  resourcemanager/nodemanager  
mr-jobhistory-daemon.sh start/stop historyserver 
>**注：**修改hadoop-daemon.sh和yarn-daemon.sh的启动文件，可以修改pid和log的存储位置。

<br>
**新版本命令**
hdfs --daemon start/stop namenode/datanode/secondarynamenode
yarn --daemon start/stop nodemanger/resourcemanager
mapred --daemon start/stop historyserver

<br>
## 基础命令
hadoop  fs  -help  rm   输出rm指令的详细信息
hadoop  fs  -usage  rm   输出rm的标准格式
hadoop fs -find / -name tmp  查找tmp文件

hadoop  fs  -setrep  10  /input.txt  设置HDFS中文件的replication(副本)数量（setrep指令记录在NameNode中，实际副本数还是看最大节点数。）
hadoop fs -checksum /a/b/c/xsync   每次写入读出都会自动进行一次校验判断文件的完整性；checksum是手动判断文件的完整型命令，如果和crc文件比对不同，则抛出错误。

| 选项名称 | 使用格式 | 含义 |
| --- | --- | --- |
| -ls | -ls <路径> | 查看指定路径的当前目录结构 |
| -lsr | -lsr <路径> | 递归查看指定路径的目录结构 |
| -du | -du <路径> | 统计目录下个文件大小 |
| -dus | -dus <路径> | 汇总统计目录下文件(夹)大小 |
| -count | -count [-q] <路径> | 统计文件(夹)数量 |
| -mv | -mv <源路径> <目的路径> | 移动 |
| -cp | -cp <源路径> <目的路径> | 复制 |
| -rm | -rm [-skipTrash] <路径> | 删除文件/空白文件夹 |
| -rmr | -rmr [-skipTrash] <路径> | 递归删除 |
| -put | -put <多个linux上的文件> <hdfs路径> | 上传文件 |
| -copyFromLocal | -copyFromLocal <多个linux上的文件> <hdfs路径> | 从本地复制 |
| -moveFromLocal | -moveFromLocal <多个linux上的文件> <hdfs路径> | 从本地移动 |
| -getmerge | -getmerge <源路径> <linux路径> | 合并到本地 |
| -cat | -cat <hdfs路径> | 查看文件内容 |
| -text | -text <hdfs路径> | 查看文件内容 |
| -copyToLocal | -copyToLocal [-ignoreCrc] [-crc] [hdfs源路径] [linux目的路径] | 复制到本地 |
| -moveToLocal | -moveToLocal [-crc] <hdfs源路径> <linux目的路径> | 移动到本地 |
| -mkdir | -mkdir <hdfs路径> | 创建空白文件夹 |
| -setrep | -setrep [-R] [-w] <副本数> <路径> | 修改副本数量 |
| -touchz | -touchz <文件路径> | 创建空白文件 |
| -stat | -stat [format] <路径> | 显示文件统计信息 |
| -tail | -tail [-f] <文件> | 查看文件尾部信息 |
| -chmod | -chmod [-R] <权限模式> [路径] | 修改权限 |
| -chown | -chown [-R] [属主](#)] 路径 | 修改属主 |
| -chgrp | -chgrp [-R] 属组名称 路径 | 修改属组 |
| -help | -help [命令选项] | 帮助 |

<br>
## 管理命令
hadoop dfsadmin -report  查看各个datenode节点的状态
hadoop dfsadmin -safemode get   命令是用来查看当前hadoop安全模式的开关状态
hadoop dfsadmin -safemode enter  命令是打开安全模式
hadoop dfsadmin -safemode leave 命令是离开安全模式

hdfs dfsadmin -fetchImage /data 获取fsimage信息并存储到目标地址

hadoop checknative -a 查看hadoop支持的压缩格式


<br>
## 节点间数据均衡
开启数据均衡命令：
start-balancer.sh -threshold 10
>对于参数10，代表的是集群中各个节点的磁盘空间利用率相差不超过10%，可根据实际情况进行调整。

停止数据均衡命令：
stop-balancer.sh
>注意：于HDFS需要启动单独的Rebalance Server来执行Rebalance操作，[所以尽量不要在NameNode上执行start-balancer.sh，而是找一台比较空闲的机器。

## 磁盘间数据均衡
（1）生成均衡计划（我们只有一块磁盘，不会生成计划）
hdfs diskbalancer -plan hadoop103
（2）执行均衡计划
hdfs diskbalancer -execute hadoop103.plan.json
（3）查看当前均衡任务的执行情况
hdfs diskbalancer -query hadoop103
（4）取消均衡任务
hdfs diskbalancer -cancel hadoop103.plan.json

<br>
## Hadoop中的umask
**计算规则**
Hadoop中umask的值使用的是十进制，与Linux中的umask值使用的是八进制是不同的。
但是计算规则是相同的，且默认文件夹权限为777，文件权限为666，umask为022，因此用户创建文件夹后权限为755，创建文件权限为644。
`可以先通过八进制将需要的umask的值计算出来后，再转为十进制进行设置。`

如希望让文件的属性为644，那么在linux中应该设置umask为022，而设置dfs.mask的值时，将其转为十进制就是0018。

**修改umask**
在配置文件中修改
```
    <property>
        <name>fs.permissions.umask-mode</name>
        <value>002</value>
    </property>
```

<br>
## Hadoop中占用空间过大
通过命令`hadoop fs -du -h /`查看根目录下磁盘占用过大的文件。
第一列标示该目录下总文件大小
第二列标示该目录下所有文件在集群上的总存储大小和你的副本数相关，我的副本数是3 ，所以第二列的是第一列的三倍 （第二列内容=文件大小*副本数）。
```
[root@cos-bigdata-hadoop-01 hadoop]# hadoop fs -du -h /
668.5 G  2.0 T    /HBase
7.4 G    26.3 G   /origin_data
36.5 G   109.4 G  /spark
27.9 K   83.6 K   /system
68.0 M   203.9 M  /tez
657.4 G  1.9 T    /tmp
115.5 G  346.4 G  /user
209.5 G  630.7 G  /warehouse
```
最后发现 /tmp文件和/HBase/oldWALs文件占用过大，删除即可。删除时需要注意使用命令`hdfs dfs -rm -r -skipTrash`，因为hdfs有回收站机制，如果不添加-skipTrash，不会释放磁盘空间，而是在`fs.trash.interval`配置的时候后才会完全删除并释放磁盘空间。也可以使用`hadoop fs -expunge`命令，在后台启动程序慢慢删除过期的文件。
>**NOTE:**
>1. /tmp目录: 主要用作mapreduce操作期间的临时存储.Mapreduce工件,中间数据等将保存在此目录下.mapreduce作业执行完成后,这些文件将自动清除.如果删除此临时文件,则会影响当前运行的mapreduce作业。临时文件由pig创建.临时文件删除最后发生.如果脚本执行失败或被杀死,Pig不会处理临时文件删除.然后你必须处理这种情况.您最好在脚本本身处理此临时文件清理活动。
>2. /HBase/oldWALs目录: 当/hbase/WALs中的HLog文件被持久化到存储文件中，且这些Hlog日志文件不再被需要时，就会被转移到{hbase.rootdir}/oldWALs目录下，该目录由HMaster上的定时任务负责定期清理。


<br>
## 数据迁移
**集群间迁移**
`hadoop distcp hdfs://bigdata1:8020/data hdfs://bigdata2:8020/`
**集群迁移到本地**
`hadoop distcp file:///logs hdfs://172.16.218.29:8020/data/hadoop`
**本地迁移集群**
`hadoop distcp hdfs://172.16.218.29:8020/data/hadoop file:///logs`
