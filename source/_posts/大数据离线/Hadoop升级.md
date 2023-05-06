---
title: Hadoop升级
categories:
- 大数据离线
---
# 五、部分框架升级
## 5.1 Hadoop 3.1.3
### 5.1.1 安装
安装方式同旧版本

### 5.1.2 配置文件
core-site.xml
```
<configuration>
    <!-- 指定NameNode地址 -->
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://bigdata1:9820</value>
    </property>
    <!-- 指定hadoop数据的存储目录 -->
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/opt/module/hadoop-3.1.3/data</value>
    </property>
    
    <!-- 配置HDFS网页登陆使用的静态用户为hxr -->
    <property>
        <name>hadoop.http.staticuser.user</name>
        <value>hxr</value>
    </property>
    <!-- 配置hxr允许通过代理访问主机节点 -->
    <property>
        <name>hadoop.proxyuser.hxr.hosts</name>
        <value>*</value>
    </property>
    <!-- 配置hxr允许通过代理用户所属组 -->
    <property>
        <name>hadoop.proxyuser.hxr.groups</name>
        <value>*</value>
    </property>

    <property>
        <name>io.compression.codecs</name>
        <value>
        org.apache.hadoop.io.compress.GzipCodec,
        org.apache.hadoop.io.compress.DefaultCodec,
        org.apache.hadoop.io.compress.BZip2Codec,
        org.apache.hadoop.io.compress.SnappyCodec,
        com.hadoop.compression.lzo.LzoCodec,
        com.hadoop.compression.lzo.LzopCodec
        </value>
    </property>
    <property>
        <name>io.compression.codec.lzo.class</name>
        <value>com.hadoop.compression.lzo.LzoCodec</value>
    </property>

</configuration>
```
>集群支持lzo压缩，还需要将lzo包**hadoop-lzo-0.4.20.jar**放到路径**/opt/module/hadoop-2.7.2/share/hadoop/common**下，分发到其他节点后重启hadoop集群。

hdfs-site.xml
```
<configuration>
    <!-- nn web端访问地址 -->
    <property>
        <name>dfs.namenode.http-address</name>
        <value>bigdata1:9870</value>
    </property>
    <!-- 2nn web端访问地址 -->
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>bigdata3:9868</value>
    </property>
    <!-- 挂载目录配置 -->
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file://${hadoop.tmp.dir}/dfs/data,file:///dfs/data1,file:///home/dfs/data2</value>
    </property>

    <!-- 测试环境指定HDFS副本数量 -->
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
</configuration>
```
>如果是新添加的硬盘，为了防止原有的数据丢失，需要将原来的数据也进行挂载，默认路径是`file://${hadoop.tmp.dir}/dfs/data`。
>启动时，所有挂载的路径下，不能存在一个以上的current文件夹，否则会导致错误
>```
>org.apache.hadoop.hdfs.server.common.InconsistentFSStateException: Directory /home/dfs/data2 is in an inconsistent state: Root /home/dfs/data2: DatanodeUuid=a6602160-4a1b-445a-946c-e525affe6b42, does not match 13905291-f3df-41f3-a4ed-c7c2b5a5c63d from other StorageDirectory.
>```

yarn-site.xml
```
<configuration>
    <!-- 指定MR走shuffle -->
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <!-- 指定ResourceManager的地址-->
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>bigdata2</value>
    </property>
    <!-- 环境变量的继承 -->
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
    </property>
    
    <!-- yarn容器允许分配的最大最小内存 -->
    <property>
        <name>yarn.scheduler.minimum-allocation-mb</name>
        <value>512</value>
    </property>
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>4096</value>
    </property>

    <!-- 虚拟核数和物理核数乘数 -->
    <property>
        <name>yarn.nodemanager.resource.pcores-vcores-multiplier</name>
        <value>1</value>
    </property>

    <!-- 该节点上YARN可使用的物理内存总量 -->
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>30720</value>
    </property>

    
    <!-- resourcemanager可以分配给容器的核数 -->
    <property>
        <name>yarn.nodemanager.resource.cpu-vcores</name>
        <value>16</value>
    </property>
    
    <!-- 关闭yarn对物理内存和虚拟内存的限制检查 -->
    <property>
        <name>yarn.nodemanager.pmem-check-enabled</name>
        <value>false</value>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
    </property>
    
    <!-- 开启日志聚集功能 -->
    <property>
        <name>yarn.log-aggregation-enable</name>
        <value>true</value>
    </property>
    <!-- 设置日志聚集服务器地址 -->
    <property>  
        <name>yarn.log.server.url</name>  
        <value>http://bigdata3:19888/jobhistory/logs</value>
    </property>
    <!-- 设置日志保留时间为7天 -->
    <property>
        <name>yarn.log-aggregation.retain-seconds</name>
        <value>604800</value>
    </property>
</configuration>
```

mapred-site.xml
```
<configuration>
    <!-- 指定MapReduce程序运行在Yarn上 -->
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>

    <!-- 历史服务器端地址 -->
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>bigdata1:10020</value>
    </property>

    <!-- 历史服务器web端地址 -->
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>bigdata1:19888</value>
    </property>
</configuration>
```

workers
```
bigdata1
bigdata2
bigdata3
```

在/etc/profile.d/env.sh中添加pid存储位置变量：
```
# hdfs pid location
export HADOOP_PID_DIR=${HADOOP_HOME}/pids/hdfs
# jobhistoryserver pid location
export HADOOP_MAPRED_PID_DIR=${HADOOP_HOME}/pids/mapred
# yarn pid location
export YARN_PID_DIR=${HADOOP_HOME}/pids/yarn
```
在log4j.properties中配置hadoop日志输出位置
```
hadoop.log.dir=/opt/module/hadoop-3.1.3/logs
```

### 5.1.3 端口
| 组件 | 端口 |
| namenode-web | 9870/9871 |
| namenode通讯端口 | 9820 |
| resourcemanager-web | 8088 |
| resourcemanager通讯端口 | 8031 |
| nodemanager-http端口 | 8042 |


### 5.1.4 高可用
#### 5.1.4.1 namenode高可用
[Apache Hadoop 3.3.5 – HDFS High Availability Using the Quorum Journal Manager](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html)

>HA通过配置Active/Standby两个NameNode实现在集群中对NameNode的热备份来解决上述问题。
>1. 在一个典型的HA集群中，使用两台单独的机器配置为NameNodes。在任何时间点，确保NameNodes中只有一个处于Active状态，其他的处在Standby状态。其中Active对外提供服务，负责集群中的所有客户端操作，Standby仅仅充当备机，仅同步Active NameNode的状态，以便能够在它失败时快速进行切换。
>2. 为了能够实时同步Active和Standby两个NameNode的元数据信息（editlog），需提供一个SharedStorage（共享存储系统），可以是NFS或QJM，Active将数据写入共享存储系统，而Standby监听该系统，一旦发现有日志变更，则读取这些数据并加载到自己内存中，以保证自己内存状态与Active保持一致，则在当failover(失效转移)发生时standby便可快速切为active。
>3. 为了实现快速切换，Standby节点获取集群中blocks的最新位置是非常必要的。为了实现这一目标，DataNodes上需要同时配置这两个Namenode的地址，并同时给他们发送文件块信息以及心跳检测。
>4. 为了实现热备，增加FailoverController（故障转移控制器）和Zookeeper，FailoverController与Zookeeper通信，通过Zookeeper选举机制，FailoverController通过RPC让NameNode转换为Active或Standby。
>
>【备注】standby代替SNN的功能（edits-----fsimage）
>启动了hadoop2.0的HA机制之后，secondarynamenode，checkpointnode，buckcupnode这些都不需要了。

>Hadoop 高可用性有两种实现方式：QJM 和 NFS。QJM 通过多个 JournalNode 保证了系统的可靠性，消耗的资源很少，不需要额外的机器来启动 JournalNode 进程，只需从 Hadoop 集群中选择几个节点启动 JournalNode 即可。NFS 则是通过共享存储来实现数据共享，但是 NFS 存在单点故障问题，不如 QJM 可靠。这里使用QJM 方式实现HA。

hdfs-site.xml添加如下配置
```
    <!-- NameNode高可用 -->
    <property>
        <name>dfs.nameservices</name>
        <value>hdfscluster</value>
    </property>
    <property>
        <name>dfs.ha.namenodes.hdfscluster</name>
        <value>nn1,nn2,nn3</value>
    </property>
    
    <property>
        <name>dfs.namenode.rpc-address.hdfscluster.nn1</name>
        <value>cos-bigdata-test-flink-01:8020</value>
    </property>
    <property>
        <name>dfs.namenode.rpc-address.hdfscluster.nn2</name>
        <value>cos-bigdata-test-flink-02:8020</value>
    </property>
    <property>
        <name>dfs.namenode.rpc-address.hdfscluster.nn3</name>
        <value>cos-bigdata-test-flink-03:8020</value>
    </property>
    
    <property>
        <name>dfs.namenode.http-address.hdfscluster.nn1</name>
        <value>cos-bigdata-test-flink-01:9870</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.hdfscluster.nn2</name>
        <value>cos-bigdata-test-flink-02:9870</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.hdfscluster.nn3</name>
        <value>cos-bigdata-test-flink-03:9870</value>
    </property>
    
    <property>
        <name>dfs.namenode.shared.edits.dir</name>
        <value>qjournal://cos-bigdata-test-flink-01:8485;cos-bigdata-test-flink-02:8485;cos-bigdata-test-flink-03:8485/hdfscluster</value>
    </property>
    
    <property>
        <name>dfs.client.failover.proxy.provider.hdfscluster</name>
        <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
    </property>
    
    <property>
        <name>dfs.ha.fencing.methods</name>
        <value>shell(/bin/true)</value>
    </property>
    
<!--
    <property>
        <name>dfs.ha.fencing.methods</name>
        <value>sshfence</value>
    </property>
    <property>
        <name>dfs.ha.fencing.ssh.private-key-files</name>
        <value>/root/.ssh/id_rsa</value>
    </property>
    -->
    
    <property>
        <name>dfs.journalnode.edits.dir</name>
        <value>/opt/module/hadoop/journal</value>
    </property>
    
    <property>
        <name>dfs.ha.automatic-failover.enabled</name>
        <value>true</value>
    </property> 
```
在core-site.xml中配置zk
```
    <property>
        <name>ha.zookeeper.quorum</name>
        <value>cos-bigdata-test-flink-01:2181,cos-bigdata-test-flink-02:2181,cos-bigdata-test-flink-03:2181</value>
    </property>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://hdfscluster</value>
    </property>
```
在hadoop-env.sh中配置用户
```
export HDFS_JOURNALNODE_USER=root
export HDFS_ZKFC_USER=root
```

启动每个节点上的journalnode服务 `hdfs --daemon start journalnode`
运行命令清空zookeeper中namenode的注册信息 `hdfs zkfc -formatZK`
将所有journalnode启动后，在其中一台namenode下执行命令 `hdfs namenode -initializeSharedEdits`
然后启动服务`start-dfs.sh`
此时配置的另外两台的namenode会报错启动失败，执行命令 `hdfs namenode -bootstrapStandby`
然后重启集群 `stop-dfs.sh`  `start-dfs.sh`
最后检查各个namenode的状态 `bin/hdfs haadmin -getServiceState nn1/nn2/nn2`

相比namenode单节点，多了两个进程
| 进程                    | 描述                                     |
| ----------------------- | ---------------------------------------- |
| JournalNode             | 用于存储namenode的数据                   |
| DFSZKFailoverController | 用于在发生namenode宕机是进行自动故障转移 |

#### 5.1.4.2 resourcemanger高可用
yarn-site.xml中添加配置
```
    <!-- Yarn高可用 -->
    <property>
        <name>yarn.resourcemanager.ha.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>yarn.resourcemanager.cluster-id</name>
        <value>yarncluster</value>
    </property>
    <property>
        <name>yarn.resourcemanager.ha.rm-ids</name>
        <value>rm1,rm2,rm3</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname.rm1</name>
        <value>cos-bigdata-test-flink-01</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname.rm2</name>
        <value>cos-bigdata-test-flink-02</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname.rm3</name>
        <value>cos-bigdata-test-flink-03</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address.rm1</name>
        <value>cos-bigdata-test-flink-01:8088</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address.rm2</name>
        <value>cos-bigdata-test-flink-02:8088</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address.rm3</name>
        <value>cos-bigdata-test-flink-03:8088</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address.rm1</name>
        <value>cos-bigdata-test-flink-01:8032</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address.rm2</name>
        <value>cos-bigdata-test-flink-02:8032</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address.rm3</name>
        <value>cos-bigdata-test-flink-03:8032</value>
    </property>
    <!-- 指定 AM 向 rm1 申请资源的地址 -->
    <property>
        <name>yarn.resourcemanager.scheduler.address.rm1</name> 
        <value>cos-bigdata-test-flink-01:8030</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address.rm2</name> 
        <value>cos-bigdata-test-flink-02:8030</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address.rm3</name> 
        <value>cos-bigdata-test-flink-03:8030</value>
    </property>
    <!-- 指定供 NM 连接的地址 --> 
    <property>
        <name>yarn.resourcemanager.resource-tracker.address.rm1</name>
        <value>cos-bigdata-test-flink-01:8031</value>
    </property>
    <property>
        <name>yarn.resourcemanager.resource-tracker.address.rm2</name>
        <value>cos-bigdata-test-flink-02:8031</value>
    </property>
    <property>
        <name>yarn.resourcemanager.resource-tracker.address.rm3</name>
        <value>cos-bigdata-test-flink-03:8031</value>
    </property>
    <!-- 启用自动恢复 --> 
    <property>
        <name>yarn.resourcemanager.recovery.enabled</name>
        <value>true</value>
    </property>
<!-- 指定 resourcemanager 的状态信息存储在 zookeeper 集群 --> 
    <property>
        <name>yarn.resourcemanager.store.class</name> 
        <value>org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore</value>
    </property>
<!-- 环境变量的继承 -->
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
    </property>
<!--     <property>
        <name>yarn.client.failover-proxy-provider</name>
        <value>org.apache.hadoop.yarn.client.ConfiguredRMFailoverProxyProvider</value>
    </property> -->
    <property>
        <name>hadoop.zk.address</name>
        <value>cos-bigdata-test-flink-01:2181,cos-bigdata-test-flink-02:2181,cos-bigdata-test-flink-03:2181</value>
    </property>
```
启动yarn `start-yarn.sh`，访问任何一个resourcemanager都会重定向到activate的那个resourcemanager上。
查看resourcemanager状态 `yarn rmadmin -getServiceState rm1/rm2`


<br>
**启动Flink-on-yarn任务**
因为namenode和resourcemanager都是集群，Flink-on-yarn任务无法指定其中一个节点的地址。此时可以将hadoop的配置文件引入，在flink-conf.yml中添加配置；如果配置了flink-ha，则high-availability.storageDir也需要修改为namenode集群地址。
```
fs.hdfs.hadoopconf: $HADOOP_HOME/etc/hadoop

yarn.application-attempts: 2
high-availability: zookeeper
high-availability.storageDir: hdfs:///flink/yarn/ha
high-availability.zookeeper.quorum: bigdata1:2181,bigdata2:2181,bigdata3:2181
high-availability.zookeeper.path.root: /flink-yarn
```
可以将hadoop集群的地址和端口省略，例如
`./flink run -s hdfs:///flink/checkpoint/msas/msas_device_exceptions/0bbbf051f47e795067032e7aa612aecd/chk-9884/_metadata --allowNonRestoredState -m yarn-cluster -ynm ADS_DEVICE_MSAS_EXCEPTIONS_test -p 2 -ys 2 -yjm 1024 -ytm 2048m -d -c com.iotmars.compass.MsasDeviceExceptionsApp -yqu default -yD metrics.reporter.promgateway.class=org.apache.flink.metrics.prometheus.PrometheusPushGatewayReporter -yD metrics.reporter.promgateway.host=192.168.101.174 -yD metrics.reporter.promgateway.port=9091 -yD metrics.reporter.promgateway.jobName=flink-metrics- -yD metrics.reporter.promgateway.randomJobNameSuffix=true -yD metrics.reporter.promgateway.deleteOnShutdown=false -yD metrics.reporter.promgateway.groupingKey="instance=ADS_DEVICE_MSAS_EXCEPTIONS_test" /opt/jar/test/ADS_DEVICE_MSAS_EXCEPTIONS-1.0-SNAPSHOT.jar`

>启动时namenode和resourcemanager会进行故障转移，知道找到活跃的节点。在访问日志时，historyserver也会进行故障转移，找到可用的namenode节点。

<br>

## 5.2 Hive 3.1.2
1. 解压
2. 在lib中放入mysql驱动 mysql-connector-java-5.1.45.jar
3. conf中创建hive-site.xml配置文件
```
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <!-- 数据库配置 -->
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://192.168.101.174:3306/metastore?useSSL=false</value>
    </property>

    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.jdbc.Driver</value>
    </property>

    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>root</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>Password@123</value>
    </property>

    <!-- 内部表元数据存储路径 -->
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/user/hive/warehouse</value>
    </property>

    <!-- Hive元数据存储版本的验证 -->
    <property>
        <name>hive.metastore.schema.verification</name>
        <value>false</value>
    </property>

    <property>
        <name>hive.server2.thrift.port</name>
        <value>10000</value>
    </property>

    <property>
        <name>hive.server2.thrift.bind.host</name>
        <value>bigdata1</value>
    </property>

    <!-- 元数据授权存储 -->
    <property>
        <name>hive.metastore.event.db.notification.api.auth</name>
        <value>false</value>
    </property>
    <!-- 显示查询头信息和当前数据库 -->    
    <property>
        <name>hive.cli.print.header</name>
        <value>true</value>
    </property>

    <property>
        <name>hive.cli.print.current.db</name>
        <value>true</value>
    </property>
</configuration>
```
>这里没有配置hive.metastore.uris参数，所以metastore实际没有使用到，启动hiveserver2时不需要启动metastore，即hiveserver2直连数据库而不是通过metastore进行连接。实际使用中，直连mysql的任务过多会导致获取原数据失败，所以推荐使用metastore进行连接。

4. 修改/opt/module/hive3.1.2/conf/hive-log4j.properties.template文件名称为hive-log4j.properties，修改 log 存放位置hive.log.dir=/opt/module/hive3.1.2/logs
5. 创建数据库metastore，执行命令`schematool -initSchema -dbType mysql -verbose`，在数据库中创建表。

6. 修改/etc/profile.d/my_env.sh，添加环境变量
```
#HIVE_HOME
export HIVE_HOME=/opt/module/hive
export PATH=$PATH:$HIVE_HOME/bin
```
7. 运行bin/hive进入本地客户端。
  如果需要通过beeline进行远程连接，需要启动metastore服务和hiveserver2服务。
```
nohup ./hive --service metastore &
nohup ./hive --service hiveserver2 &
```
登陆用户在hadoop配置文件core-site.xml中配置
```
    <!-- 配置HDFS网页登陆使用的静态用户为hxr -->
    <property>
        <name>hadoop.http.staticuser.user</name>
        <value>hxr</value>
    </property>
    <!-- 配置hxr允许通过代理访问主机节点 -->
    <property>
        <name>hadoop.proxyuser.hxr.hosts</name>
        <value>*</value>
    </property>
```

<br>
## 5.2 Tez 0.10.1
因为tez-0.9.x版本过低，不能和hive3.1.2搭配使用，所以使用tez-0.10.1版本。

下载[Tez安装包](apache.org)](https://dlcdn.apache.org/tez/0.10.1/)
和[Tez-UI.war包](https://repository.apache.org/content/repositories/releases/org/apache/tez/tez-ui/0.10.1/)

### 5.2.1 Tez安装
1. 解压安装包到指定目录
```
tar –zxvf apache-tez-0.10.1-bin.tar.gz -C /opt/module/
```
重命名解压后的文件为tez-0.10.1。


2. 需要在hive的配置文件hive-env.sh中引入tez的所有jar包：
```
export TEZ_HOME=/opt/module/tez-0.10.1
export TEZ_JARS=""
for jar in `ls $TEZ_HOME | grep jar`;do
        export TEZ_JARS=$TEZ_JARS:$TEZ_HOME/$jar
done

for jar in `ls $TEZ_HOME/lib`;do
        export TEZ_JARS=$TEZ_JARS:$TEZ_HOME/lib/$jar
done

export ATLAS_HOME=/opt/module/atlas-2.1.0
export ATLAS_JARS=""
for jar in `ls $ATLAS_HOME/hook/hive | grep jar`;do
        export ATLAS_JARS=$ATLAS_JARS:$ATLAS_HOME/hook/hive/$jar
done

for jar in `ls $ATLAS_HOME/hook/hive/atlas-hive-plugin-impl`;do
        export ATLAS_JARS=$ATLAS_JARS:$ATLAS_HOME/hook/hive/atlas-hive-plugin-impl/$jar
done

export HIVE_AUX_JARS_PATH=$HADOOP_HOME/share/hadoop/common/hadoop-lzo-0.4.20.jar$TEZ_JARS$ATLAS_JARS
```
>这里因为使用了Altas的钩子，需要添加相关的包。所以将JARS包加入到hive的读取路径中

3. 在Hive的/opt/module/hive/conf下面创建一个tez-site.xml文件，添加如下内容
```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xs1" href="configuration.xsl"?>
<configuration>
    <property>
        <name>tez.lib.uris</name>
        <value>${fs.defaultFS}/tez/apache-tez-0.10.1-bin.tar.gz</value>
    </property>
    <property>
        <name>tez.use.cluster.hadoop-libs</name>
        <value>true</value>
    </property>
    <property>
        <name>tez.history.logging.service.class</name>
        <value>org.apache.tez.dag.history.logging.ats.ATSHistoryLoggingService</value>
    </property>

    <property>
        <name>tez.am.resource.memory.mb</name>
        <value>1024</value>
    </property>
    <property>
        <name>hive.tez.cpu.vcores</name>
        <value>1</value>
    </property>
    <property>
        <name>hive.tez.container.size</name>
        <value>10240</value>
    </property>
    <property>
        <name>tez.runtime.io.sort.mb</name>
        <value>2048</value>
    </property>
    <property>
        <name>tez.runtime.unordered.output.buffer.size-mb</name>
        <value>1024</value>
    </property>
    <property>
        <name>tez.am.container.reuse.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>tez.am.speculation.enabled</name>
        <value>false</value>
    </property>
    <property>
        <name>hive.tez.auto.reducer.parallelism</name>
        <value>true</value>
    </property>
</configuration>
```

4. 将/opt/module/tez-0.10.1上传到HDFS的/tez路径，使所有的hdfs节点都可以使用tez。
   ```
    hadoop fs -mkdir /tez
    hadoop fs -put /opt/software/apache-tez-0.10.1-bin.tar.gz /tez
    hadoop fs -ls /tez
   ```
   放置的路径需要与tez-site.xml中配置的路径对应


### 5.2.2 Tez-UI配置
[官方配置](https://tez.apache.org/tez-ui.html)

1. 安装Tomcat，将webapps文件挂载到宿主机
```
docker run --name tomcat --privileged=true --restart=always -p 8080:8080 -v /root/docker/tomcat/conf:/usr/local/tomcat/conf -v /root/docker/tomcat/logs:/usr/local/tomcat/logs -v /root/docker/tomcat/webapps:/usr/local/tomcat/webapps -d tomcat:8.5.78-jre8-temurin-focal
```
2. 在宿主机webapps文件夹下创建tez-ui文件夹，将下载的tez-ui-0.10.1.war解压到tez-ui目录下
```
unzip tez-ui-0.10.1.war
```
并编辑配置文件config/configs.js
```
ENV = {
  hosts: {
    /*
     * Timeline Server Address:
     * By default TEZ UI looks for timeline server at http://localhost:8188, uncomment and change
     * the following value for pointing to a different address.
     */
    timeline: "http://192.168.101.185:8188",

    /*
     * Resource Manager Address:
     * By default RM REST APIs are expected to be at http://localhost:8088, uncomment and change
     * the following value to point to a different address.
     */
    rm: "http://192.168.101.185:8088",

    /*
     * Resource Manager Web Proxy Address:
     * Optional - By default, value configured as RM host will be taken as proxy address
     * Use this configuration when RM web proxy is configured at a different address than RM.
     */
    //rmProxy: "http://localhost:8088",
  },

  /*
   * Time Zone in which dates are displayed in the UI:
   * If not set, local time zone will be used.
   * Refer http://momentjs.com/timezone/docs/ for valid entries.
   */
  //timeZone: "UTC",

  /*
   * yarnProtocol:
   * If specified, this protocol would be used to construct node manager log links.
   * Possible values: http, https
   * Default value: If not specified, protocol of hosts.rm will be used
   */
  //yarnProtocol: "<value>",
};
```

3. 配置timelineserver
  说明：timeline作为具体任务执行过程中的节点,相关数据存储的位置,tez任务的applicationMaster,具体执行任务的container,hiveserver,在执行的过程中都会将tez任务的相关信息通过http接口上报到timeline,timeline对这些数据做持久化,保存起来,再通过http接口将数据暴露给tez-ui供用户查看;

在hadoop配置文件yarn-site.xml中配置 [timeline相关参数](https://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServer.html)

```
    <!-- 配置tez-ui所需的timeline服务 -->
    <property>
      <name>yarn.timeline-service.enabled</name>
      <value>true</value>
      <description>Indicate to clients whether Timeline service is enabled or not.
      If enabled, the TimelineClient library used by end-users will post entities
      and events to the Timeline server.</description>
    </property>
    <property>
      <name>yarn.timeline-service.hostname</name>
      <value>bigdata2</value>
      <description>The hostname of the Timeline service web application.</description>
    </property>
    <property>
      <name>yarn.timeline-service.http-cross-origin.enabled</name>
      <value>true</value>
      <description>Enables cross-origin support (CORS) for web services where
      cross-origin web response headers are needed. For example, javascript making
      a web services request to the timeline server.</description>
    </property>
    <property>
      <name>yarn.resourcemanager.system-metrics-publisher.enabled</name>
      <value>true</value>
      <description>Publish YARN information to Timeline Server</description>
    </property>
    <property>
      <name>yarn.timeline-service.generic-application-history.enabled</name>
      <value>true</value>
      <description>Indicate to clients whether to query generic application data 
      from timeline history-service or not. If not enabled then application data 
      is queried only from Resource Manager. Defaults to false.</description>
    </property>
    <property>
      <name>yarn.timeline-service.address</name>
      <value>bigdata2:10200</value>
      <description>Address for the Timeline server to start the RPC server. 
      Defaults to ${yarn.timeline-service.hostname}:10200.</description>
    </property>
    <property>
      <name>yarn.timeline-service.webapp.address</name>
      <value>bigdata2:8188</value>
      <description>The http address of the Timeline service web application. 
      Defaults to ${yarn.timeline-service.hostname}:8188.</description>
    </property>
    <property>
      <name>yarn.timeline-service.webapp.https.address</name>
      <value>bigdata2:8190</value>
      <description>The https address of the Timeline service web application. 
      Defaults to ${yarn.timeline-service.hostname}:8190.</description>
    </property>
    <property>
      <name>yarn.timeline-service.handler-thread-count</name>
      <value>10</value>
      <description>Handler thread count to serve the client RPC requests. Defaults to 10.</description>
    </property>
```
rm也需要开启cors
```
    <property>
      <name>yarn.resourcemanager.webapp.cross-origin.enabled</name>
      <value>true</value>
      <description>Flag to enable cross-origin (CORS) support in the RM. This flag requires the
      CORS filter initializer to be added to the filter initializers list in core-site.xml.</description>
    </property>
```

如果需要timeline服务启用kerberos认证，配置如下，如无特殊需求可以不配置kerberos。Timeline服务开启kerberos认证，则tomcat也需要[配置kerberos认证](https://tomcat.apache.org/tomcat-8.5-doc/windows-auth-howto.html)，否则报401错误导致读取不到数据。
```
    <property>
      <name>yarn.timeline-service.http-authentication.type</name>
      <value>kerberos</value>
      <description>Defines authentication used for the timeline server HTTP endpoint. 
      Supported values are: simple / kerberos /</description>
    </property>
    <property>
      <name>yarn.timeline-service.principal</name>
      <value>rm/_HOST@IOTMARS.COM</value>
      <description>The Kerberos principal for the timeline server.</description>
    </property>
    <property>
      <name>yarn.timeline-service.keytab</name>
      <value>/etc/security/keytab/rm.service.keytab</value>
      <description>The Kerberos keytab for the timeline server. 
      Defaults on Unix to to /etc/krb5.keytab.</description>
    </property>
    <property>
      <name>yarn.timeline-service.http-authentication.kerberos.principal</name>
      <value>HTTP/_HOST@IOTMARS.COM</value>
      <description></description>
    </property>
    <property>
      <name>yarn.timeline-service.http-authentication.kerberos.keytab</name>
      <value>/etc/security/keytab/spnego.service.keytab</value>
      <description></description>
    </property>
    <property>
      <name>yarn.timeline-service.http-authentication.simple.anonymous.allowed</name>
      <value>true</value>
      <description>Indicates if anonymous requests are allowed by the timeline server when using ‘simple’ authentication.
      Defaults to true.</description>
    </property>
```


4. 配置tez-site.xml
```
    <property>
        <name>tez.tez-ui.history-url.base</name>
        <value>http://192.168.101.174:8080/tez-ui</value>
    </property>
    <property>
      <description>Enable Tez to use the Timeline Server for History Logging</description>
      <name>tez.history.logging.service.class</name>
      <value>org.apache.tez.dag.history.logging.ats.ATSHistoryLoggingService</value>
    </property>
```

5. 同步配置文件到每个hadoop节点，然后重启yarn服务
```
sudo -i -u yarn stop-yarn.sh
sudo -i -u yarn start-yarn.sh
```
重启hiveserver2服务，否则hiveserver2连接的任务不会记录到tez-ui中。

6. 启动/关闭timeline服务
```
yarn --daemon start/stop timelineserver
```


>**注意：**
>**1. 如果同时使用了Hive On Spark引擎，可能会报错如下**
>
>```
>Exception in thread "main" java.lang.NoClassDefFoundError: >com/sun/jersey/core/util/FeaturesAndProperties. It appears that the timeline client failed to initiate because an incompatible dependency in classpath. If timeline service is optional to this client, try to work around by setting yarn.timeline-service.enabled to false in client configuration.
>```
>原因是Hadoop使用的jersey包的版本低于Spark，Spark中没有yarn所需要的包，导致Spark提交任务到Yarn失败。只需要将hadoop下的三个包/share/hadoop/hdfs/lib/jersey-core-1.19.jar、/share/hadoop/yarn/lib/jersey-client-1.19.jar、/share/hadoop/yarn/lib/jersey-guice-1.19.jar 复制到spark的jars目录下即可。
>
>**2. 也可能报错如下**
>```
>com.google.protobuf.ServiceException: java.io.IOException: DestHost:destPort bigdata3:43799 , LocalHost:localPort bigdata1/192.168.101.179:0. Failed on local exception: java.io.IOException: Connection reset by peer
>Caused by: java.io.IOException: DestHost:destPort bigdata3:43799 , LocalHost:localPort bigdata1/192.168.101.179:0. Failed on local exception: java.io.IOException: Connection reset by peer
>Caused by: java.io.IOException: Connection reset by peer
>2022-04-19T16:43:25,448  INFO [f8b8e0df-ccd6-4f08-ab69-225144b91dc6 main] client.TezClient: Failed to retrieve AM Status via proxy
>com.google.protobuf.ServiceException: java.io.EOFException: End of File Exception between local host is: "bigdata1/192.168.101.179"; destination host is: "bigdata2":38361; : java.io.EOFException; For more details see:  http://wiki.apache.org/hadoop/EOFException
>Caused by: java.io.EOFException: End of File Exception between local host is: "bigdata1/192.168.101.179"; destination host is: "bigdata2":38361; : java.io.EOFException; For more details see:  http://wiki.apache.org/hadoop/EOFException
>Caused by: java.io.EOFException]
>```
>这些异常不准确，真正异常原因需要查看历史服务器，发现如下异常
>```
>java.lang.NoClassDefFoundError: com/fasterxml/jackson/core/exc/InputCoercionException
>```
>原因是缺失了jackson-core-asl-1.9.13.jar和jackson-core-asl-1.9.13.jar包。因为hive-env.sh文件中加载了Tez-0.10.1目录下的所有jar包，所以只需要将jackson-core-asl-1.9.13.jar和jackson-core-asl-1.9.13.jar放到Tez-0.10.1目录下即可。

<br>

## 5.3 Spark 3.0.0
这里我们使用spark替代tez作为计算引擎，即Hive on Spark。Hive将HQL任务提交为Spark任务交给Spark执行，提交的配置参数可以写在spark-defaults.conf或HQL(set语句)中。

**步骤**
1. Hive-3.1.2中的Spark版本是2.x.x，所以需要下载hive源码（https://mirrors.tuna.tsinghua.edu.cn/apache/hive/），将Spark依赖版本修改为3.0.0再进行打包。
2. Hive所在节点部署Spark，设置SPARK_HOME全局变量。因为将Hive任务转成Spark任务需要本地Spark的依赖。
  解压Spark压缩包到本地目录下，需要注意Spark版本与Hive中Spark依赖版本一致。


- 携带hadoop依赖的spark安装包：spark-3.0.0-bin-hadoop3.2.tgz
- 纯净的spark安装包：spark-3.0.0-bin-without-hadoop.tgz


解压spark-3.0.0-bin-hadoop3.2.tgz到hive所在节点，添加SPARK_HOME环境变量
```
# SPARK_HOME
export SPARK_HOME=/opt/module/spark
export PATH=$PATH:$SPARK_HOME/bin
```
source使其生效
```
source /etc/profile.d/my_env.sh
```

在hive的conf目录下创建spark-defaults.conf文件
```
spark.master                               yarn
spark.eventLog.enabled                   true
spark.eventLog.dir                        hdfs://bigdata1:9820/spark/history
spark.executor.memory                    1g
spark.driver.memory					   1g
```
在HDFS创建如下路径，用于存储历史日志
```
hadoop fs -mkdir /spark/history
```

3. 将Spark纯净版上传到HDFS上，Hive任务最终由Spark来执行，Spark任务资源分配由Yarn来调度，该任务有可能被分配到集群的任何一个节点。所以需要将Spark的依赖上传到HDFS集群路径，这样集群中任何一个节点都能获取到。又因为Spark3非纯净版的hive版本是2.3.7，直接使用会有版本冲突。**解压Spark纯净版压缩包，将lib目录下的jar包上穿到hdfs中。**
```
hadoop fs -put spark-3.0.0-bin-without-hadoop/jars/* /spark-jars
```


4. hive的conf下创建hive-site.xml文件
```
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <!-- 数据库配置 -->
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://192.168.101.174:3306/metastore?useSSL=false</value>
    </property>

    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.jdbc.Driver</value>
    </property>

    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>root</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>Password@123</value>
    </property>

    <!-- 内部表元数据存储路径 -->
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>/user/hive/warehouse</value>
    </property>

    <!-- Hive元数据存储版本的验证 -->
    <property>
        <name>hive.metastore.schema.verification</name>
        <value>false</value>
    </property>

    <property>
        <name>hive.server2.thrift.port</name>
        <value>10000</value>
    </property>

    <property>
        <name>hive.server2.thrift.bind.host</name>
        <value>bigdata1</value>
    </property>

    <!-- 元数据授权存储 -->
    <property>
        <name>hive.metastore.event.db.notification.api.auth</name>
        <value>false</value>
    </property>
    <!-- 显示查询头信息和当前数据库 -->    
    <property>
        <name>hive.cli.print.header</name>
        <value>true</value>
    </property>

    <property>
        <name>hive.cli.print.current.db</name>
        <value>true</value>
    </property>

    <!-- Spark依赖位置（注意：端口号必须和namenode的端口号一致） -->
    <property>
        <name>spark.yarn.jars</name>
        <value>hdfs://bigdata1:9820/spark/jars-3.0.0/*</value>
    </property>
    <!-- Hive执行引擎 -->
    <property>
        <name>hive.execution.engine</name>
        <value>spark</value>
    </property>
    <!-- Hive和Spark连接超时时间 -->
    <property>
        <name>hive.spark.client.connect.timeout</name>
        <value>10000ms</value>
    </property>
</configuration>
```

第一次提交任务会很慢，因为需要启动spark-session，spark-session会一直存在，直到hive客户端关闭。后台进程为**YarnCoarseGrainedExecutorBackend**。

**如果需要通过beeline访问，则需要启动hiveserver2，并指定相关参数**
`hiveserver2 --hiveconf hive.execution.engine=spark spark.master=yarn`
或直接在后台运行
`nohup hiveserver2 --hiveconf hive.execution.engine=spark spark.master=yarn 1>/opt/module/hive-3.1.2/logs/hive-on-spark.log 2>/opt/module/hive-3.1.2/logs/hive-on-spark.err &`

我们在配置文件中不是通过metastore连接数据库，而是直连数据库，所以不需要启动metastore进行(对比hive2.3.6的配置文件，它使用的是metastore连接数据库，所以需要启动metastore)。

进入beeline客户端
`beeline -u jdbc:hive2://192.168.101.179:10000 -n hxr`
每个beeline对应一个SparkContext，而在Spark thriftserver中，多个beeline共享一个SparkContext。


5. hive注释中文乱码解决
   - 修改mysql注释相关表字段的编码格式为UTF-8
   ```
   alter table COLUMNS_V2 modify column comment varchar(256) character set utf8;
   alter table TABLE_PARAMS modify column PARAM_VALUE varchar(4000) character set utf8;
   alter table PARTITION_PARAMS modify column PARAM_VALUE varchar(4000) character set utf8;
   alter table PARTITION_KEYS modify column PKEY_COMMENT varchar(4000) character set utf8;
   alter table INDEX_PARAMS modify column PARAM_VALUE varchar(4000) character set utf8;
   ```
   - 修改hive的jdbc连接配置如下
   ```
   <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://192.168.101.174:3306/metastore?useSSL=false&amp;useUnicode=true&amp;characterEncoding=UTF-8</value>
   </property>
   ```
   完成后新建的表的中文注释就不会乱码了。

<br>
**优化Spark(可选)**
配置Spark shuffle服务
Spark Shuffle服务的配置因Cluster Manager（standalone、Mesos、Yarn）的不同而不同。此处以Yarn作为Cluster Manager。
（1）拷贝`$SPARK_HOME/yarn/spark-3.0.0-yarn-shuffle.jar`到
`$HADOOP_HOME/share/hadoop/yarn/lib`
（2）分发`$HADOOP_HOME/share/hadoop/yarn/lib/yarn/spark-3.0.0-yarn-shuffle.jar`
（3）修改`$HADOOP_HOME/etc/hadoop/yarn-site.xml`文件
```
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle,spark_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.spark_shuffle.class</name>
        <value>org.apache.spark.network.yarn.YarnShuffleService</value>
    </property>
```
>NOTE:在启用spark.dynamicAllocation.enabled配置后，需要启动spark.shuffle.service.enabled服务。Spark shuffle服务的作用是管理Executor中的各Task的输出文件，主要是shuffle过程map端的输出文件。由于启用资源动态分配后，Spark会在一个应用未结束前，将已经完成任务，处于空闲状态的Executor关闭。Executor关闭后，其输出的文件，也就无法供其他Executor使用了。需要启用Spark shuffle服务，来管理各Executor输出的文件，这样就能关闭空闲的Executor，而不影响后续的计算任务了。

（4）分发`$HADOOP_HOME/etc/hadoop/yarn-site.xml`文件
（5）重启Yarn

## 5.4 azkaban-3.84.4
解压包 azkaban-db-3.84.4.tar.gz、azkaban-web-server-3.84.4.tar.gz、azkaban-web-server-3.84.4.tar.gz 。

**数据库创建**
创建azkaban数据库，执行azkaban-db-3.84.4.tar.gz中的create-all-sql-3.84.4.sql脚本来创建表。

**web配置**
修改配置文件conf/azkaban.properties
```
...
default.timezone.id=Asia/Shanghai
...
database.type=mysql
mysql.port=3306
mysql.host=192.168.101.174
mysql.database=azkaban
mysql.user=root
mysql.password=Password@123
mysql.numconnections=100
...
azkaban.executorselector.filters=StaticRemainingFlowSize,CpuStatus
```
>**说明：**
>StaticRemainingFlowSize：正在排队的任务数；
>CpuStatus：CPU占用情况
>MinimumFreeMemory：内存占用情况。测试环境，必须将MinimumFreeMemory删除掉，否则它会认为集群资源不够，不执行。

**邮箱配置**
修改azkaban.properties文件
```
# mail settings
mail.sender=18851703029@163.com
mail.host=smtp.163.com
mail.user=18851703029@163.com
mail.password=NUJPIDRSXQWMFVDX
```

修改配置文件conf/azkaban-users.xml
```
<azkaban-users>
  <user groups="azkaban" password="azkaban" roles="admin" username="azkaban"/>
  <user password="metrics" roles="metrics" username="metrics"/>
  <!-- 添加新用户admin -->
  <user password="admin" roles="metrics,admin" username="admin"/>

  <role name="admin" permissions="ADMIN"/>
  <role name="metrics" permissions="METRICS"/>
</azkaban-users>
```

<br>
**exec配置**
修改配置文件conf/azkaban.properties
```
#...
default.timezone.id=Asia/Shanghai
#...
azkaban.webserver.url=http://bigdata1:8081
# 直接指定executor启动的端口，防止随机分配端口
executor.port=12321
#...
database.type=mysql
mysql.port=3306
mysql.host=192.168.101.174
mysql.database=azkaban
mysql.user=root
mysql.password=Password@123
mysql.numconnections=100

# 在最后添加
executor.metric.reports=true
executor.metric.milisecinterval.default=60000
```
将executor分发到需要部署的节点。

**executor需要进行激活才能使用**
```
curl -G "bigdata1:12321/executor?action=activate" && echo
curl -G "bigdata2:12321/executor?action=activate" && echo
curl -G "bigdata3:12321/executor?action=activate" && echo
```
<!--
curl -G "bigdata3:$(<./executor.port)/executor?action=activate" && echo
-->

**启动/关闭命令**
bin/start-web.sh
bin/shutdown-web.sh

bin/start-exec.sh
bin/shutdown-exec.sh

>**注意：**azkaban在重启executor之后可能会出现找不到executor的异常，可以通过请求azkaban的web接口来刷新 `WEBSERVER_URL:8081/executor?ajax=reloadExecutors`，注意请求头需要携带有admin权限用户的Cookie，Cookie格式为***azkaban.warn.message=; azkaban.failure.message=; azkaban.success.message=; JSESSIONID={JSESSIONID}; azkaban.browser.session.id={azkaban.browser.session.id}***。

详见[官网](https://azkaban.github.io/azkaban/docs/latest/)。

<br>

## 5.5 DataX & DataX-Web
[DataX官网](ttps://github.com/alibaba/DataX)
[DataX-Web网址](https://github.com/WeiYe-Jing/datax-web/blob/master/doc/datax-web/datax-web-deploy.md)
### 5.5.1 Data
解压压缩包datax.tar.gz，既可直接使用(需要安装python)。

**实例**
从mysql到mysql
```
{
    "job": {
        "setting": {
            "speed": {
                 "channel": 3
            },
            "errorLimit": {
                "record": 0,
                "percentage": 0.02
            }
        },
        "content": [
            {
                "reader": {
                    "name": "mysqlreader",
                    "parameter": {
                        "username": "root",
                        "password": "hxr",
                        "column": [
                            "cid",
                            "user_id",
                            "msg"
                        ],
                        "splitPk": "cid",
                        "connection": [
                            {
                                "table": [
                                    "course_1",
                                    "course_2"
                                ],
                                "jdbcUrl": [
     "jdbc:mysql://192.168.32.244:3306/sphere_test"
                                ]
                            }
                        ]
                    }
                },
                "writer": {
                    "name": "hdfswriter",
                    "parameter": {
                        "defaultFS": "hdfs://192.168.101.179:9820",
                        "fileType": "text",
                        "path": "/user/hive/warehouse/course",
                        "fileName": "course",
                        "column": [
                            {
                                "name": "id",
                                "type": "string"
                            },
                            {
                                "name": "userid",
                                "type": "string"
                            },
                            {
                                "name": "msg",
                                "type": "string"
                            }
                        ],
                        "writeMode": "append",
                        "fieldDelimiter": "	"
                    }
                }
            }
        ]
    }
}
```
>具体fileType需要根据建表时表的存储格式进行指定，同时指定存储的压缩格式compress。

执行命令 `python datax.py [任务文件]`

打印结果如下表示执行成功：
```
2021-07-24 17:46:42.802 [job-0] INFO  StandAloneJobContainerCommunicator - Total 3 records, 21 bytes | Speed 2B/s, 0 records/s | Error 0 records, 0 bytes |  All Task WaitWriterTime 0.000s |  All Task WaitReaderTime 0.000s | Percentage 100.00%
2021-07-24 17:46:42.803 [job-0] INFO  JobContainer - 
任务启动时刻                    : 2021-07-24 17:46:31
任务结束时刻                    : 2021-07-24 17:46:42
任务总计耗时                    :                 11s
任务平均流量                    :                2B/s
记录写入速度                    :              0rec/s
读出记录总数                    :                   3
读写失败总数                    :                   0
```


### 5.5.2 DataX-Web
安装过程见 [官网](https://github.com/WeiYe-Jing/datax-web/blob/master/doc/datax-web/datax-web-deploy.md)


将datax-executor部署在datax所在的服务器上，datax-admin可以部署在其他服务器上。


在配置文件datax-executor/conf/application.yml中添加datax.py的路径，并指定admin所在节点
```
......
datax:
  job:
    admin:
      ### datax admin address list, such as "http://address" or "http://address01,http://address02"
      #addresses: http://127.0.0.1:8080
      addresses: http://192.168.32.244:${datax.admin.port}
  ......
pypath: /root/datax/bin/datax.py
```

### 5.5.3 Data支持Kerberos和Lzop压缩
#### 5.5.3.1 说明
我们修改Datax源码，为了解决一下两件事
1. 启用Datax的Kerberos进行写入时，会报错
   ```
   2021-11-17 15:58:26,109 INFO org.apache.hadoop.hdfs.server.datanode.DataNode: Failed to read expected SASL data transfer protection handshake from client at /192.168.101.177:41208. Perhaps the client is running an older version of Hadoop which does not support SASL data transfer protection
   org.apache.hadoop.hdfs.protocol.datatransfer.sasl.InvalidMagicNumberException: Received 1c5086 instead of deadbeef from client.
   ```
   报错是因为配置问题，在服务器端配置了dfs.data.transfer.protection为authentication，而客户端没有配置，可以在脚本里配置hadoopConfig参数，添加
   `"dfs.data.transfer.protection": "authentication"`；
   也可以在Datax源码中进行相应配置。

2. 使得Datax支持Lzop压缩
   同样需要修改Datax源码，引入Lzop压缩

3. Datax导入hdfs，null值默认使用空串来表示，而不是hive中的表示null值的默认值'\N\来表示。

>**注意：**
>1. 如下修改之后的lzop格式，在导入数据时会出现脏数据，目前还未解决；
>2. 对于null值不统一问题，可以在hive建表时指定空串为null值即可； 
>```
>ROW FORMAT DELIMITED FIELDS TERMINATED BY '	' NULL DEFINED AS ''
>```

#### 5.5.3.2 实现
1. 拉取源码
```
$ git clone https://github.com/alibaba/DataX.git
```

2. 添加配置：
  在HdfsHelper类中的如下位置添加配置`hadoopConf.set("dfs.data.transfer.protection", "authentication");`；
```
        //是否有Kerberos认证
        this.haveKerberos = taskConfig.getBool(Key.HAVE_KERBEROS, false);
        if(haveKerberos){
            this.kerberosKeytabFilePath = taskConfig.getString(Key.KERBEROS_KEYTAB_FILE_PATH);
            this.kerberosPrincipal = taskConfig.getString(Key.KERBEROS_PRINCIPAL);
            hadoopConf.set(HADOOP_SECURITY_AUTHENTICATION_KEY, "kerberos");

            // CJ:添加配置如下
            hadoopConf.set("dfs.data.transfer.protection", "authentication");
        }
```
或在hdfs-site.xml配置文件中添加配置
```
    <property>
      <name>dfs.data.transfer.protection</name>
      <value>authentication</value>
    </property>
```

3. 增加Lzop支持
  引入依赖
```
        <dependency>
            <groupId>org.anarres.lzo</groupId>
            <artifactId>lzo-hadoop</artifactId>
            <version>1.0.5</version>
            <exclusions>
                <exclusion>
                    <groupId>org.apache.hadoop</groupId>
                    <artifactId>hadoop-core</artifactId>
                </exclusion>
            </exclusions>
        </dependency>
```
修改HdfsHelper类中的如下位置
```
    public Class<? extends CompressionCodec> getCompressCodec(String compress) {
        Class<? extends CompressionCodec> codecClass = null;
        if (null == compress) {
            codecClass = null;
        } else if ("GZIP".equalsIgnoreCase(compress)) {
            codecClass = org.apache.hadoop.io.compress.GzipCodec.class;
        } else if ("BZIP2".equalsIgnoreCase(compress)) {
            codecClass = org.apache.hadoop.io.compress.BZip2Codec.class;
        } else if ("SNAPPY".equalsIgnoreCase(compress)) {
            //todo 等需求明确后支持 需要用户安装SnappyCodec
            codecClass = org.apache.hadoop.io.compress.SnappyCodec.class;
            // org.apache.hadoop.hive.ql.io.orc.ZlibCodec.class  not public
            //codecClass = org.apache.hadoop.hive.ql.io.orc.ZlibCodec.class;
        } else if ("LZOP".equalsIgnoreCase(compress)) {
            codecClass = org.apache.hadoop.io.compress.LzopCodec.class;
        } else {
            throw DataXException.asDataXException(HdfsWriterErrorCode.ILLEGAL_VALUE,
                    String.format("目前不支持您配置的 compress 模式 : [%s]", compress));
        }
        return codecClass;
    }
```
```
            //compress check
            this.compress = this.writerSliceConfig.getString(Key.COMPRESS, null);
            if (fileType.equalsIgnoreCase("TEXT")) {
                Set<String> textSupportedCompress = Sets.newHashSet("GZIP", "BZIP2", "LZOP");
                //用户可能配置的是compress:"",空字符串,需要将compress设置为null
                if (StringUtils.isBlank(compress)) {
                    this.writerSliceConfig.set(Key.COMPRESS, null);
                } else {
                    compress = compress.toUpperCase().trim();
                    if (!textSupportedCompress.contains(compress)) {
                        throw DataXException.asDataXException(HdfsWriterErrorCode.ILLEGAL_VALUE,
                                String.format("目前TEXT FILE仅支持GZIP、BZIP2、LZOP 三种压缩, 不支持您配置的 compress 模式 : [%s]",
                                        compress));
                    }
                }
            }
```
修改HdfsWriter类中的如下位置
```
                //设置临时文件全路径和最终文件全路径
                if ("GZIP".equalsIgnoreCase(this.compress)) {
                    this.tmpFiles.add(fullFileName + ".gz");
                    this.endFiles.add(endFullFileName + ".gz");
                } else if ("BZIP2".equalsIgnoreCase(compress)) {
                    this.tmpFiles.add(fullFileName + ".bz2");
                    this.endFiles.add(endFullFileName + ".bz2");
                    // CJ: 新增如下
                } else if ("LZOP".equalsIgnoreCase(compress)) {
                    this.tmpFiles.add(fullFileName + ".lzo");
                    this.endFiles.add(endFullFileName + ".lzo");
                } else {
                    this.tmpFiles.add(fullFileName);
                    this.endFiles.add(endFullFileName);
                }
```
修改HdfsHelper类，当使用LZOP格式的压缩时，存储在hdfs上的null值为"\N"
```
    // CJ: 添加类属性
    public static String nullFormat = null;
```
```
    public void textFileStartWrite(RecordReceiver lineReceiver, Configuration config, String fileName,
                                   TaskPluginCollector taskPluginCollector) {
        char fieldDelimiter = config.getChar(Key.FIELD_DELIMITER);
        List<Configuration> columns = config.getListConfiguration(Key.COLUMN);
        String compress = config.getString(Key.COMPRESS, null);

        // CJ: 为了不影响其他压缩格式，这里设置如果是text格式且LZOP压缩，且添加Null值转换参数，默认是\N。
        if("LZOP".equalsIgnoreCase(compress)) {
            nullFormat = config.getString(Key.NULL_FORMAT, Constant.DEFAULT_NULL_FORMAT);
        }
        ......
```
```
    // 修改
    public static MutablePair<List<Object>, Boolean> transportOneRecord(
            Record record, List<Configuration> columnsConfiguration,
            TaskPluginCollector taskPluginCollector) {
              ......
                    // warn: it's all ok if nullFormat is null
//                    recordList.add(null);

                    // CJ: null值保存为"\N"
                    recordList.add(nullFormat);
              ......
    }
```

4. 打包即可
```
$ mvn -U clean package assembly:assembly -Dmaven.test.skip=true
```



<br>
## 5.6 HBase 2.0.5
首先要保证zookeeper和hadoop正常运行

1. [下载安装包](https://archive.apache.org/dist/hbase/2.0.5/)
2. 解压压缩包
3. 修改配置文件 
  **修改conf/hbase-env.sh**
```
export HBASE_MANAGES_ZK=false
```
**修改conf/hbase-site.xml**
```
        <property>
                <name>hbase.rootdir</name>
                <value>hdfs://bigdata1:9820/HBase</value>
        </property>

        <property>
                <name>hbase.cluster.distributed</name>
                <value>true</value>
        </property>

        <property>
                <name>hbase.zookeeper.quorum</name>
                <value>bigdata1,bigdata2,bigdata3</value>
        </property>
```
修改regionservers
```
bigdata1
bigdata2
bigdata3
```
4. 分发HBase文件到其他节点
5. 启动服务
   - 单节点启动
   ```
   [root@bigdata1 hbase]$ bin/hbase-daemon.sh start master
   [root@bigdata1 hbase]$ bin/hbase-daemon.sh start regionserver
   ```
   - 集群启动
   ```
   [root@bigdata1 hbase]$ bin/start-hbase.sh
   ```

   >如果集群之间的节点时间不同步，会导致regionserver无法启动，抛出ClockOutOfSyncException异常。可通过配置hbase.master.maxclockskew=180000修改容忍的时间差异。

6. 停止服务
   ```
   [root@bigdata1 hbase]$ bin/stop-hbase.sh
   ```
7. 查看UI
  http://bigdata1:16010

<br>
## 5.7 Solr 7.7.3
Solr版本需要与Atlas匹配

1. [下载安装包](http://archive.apache.org/dist/lucene/solr/7.7.3/)
2. 解压安装包
3. 修改配置文件
  **修改bin/solr.in.sh**
```
ZK_HOST="bigdata1:2181,bigdata2:2181,bigdata3:2181"
SOLR_HOST="bigdata1"
# Sets the port Solr binds to, default is 8983
SOLR_PORT=8983
```
4. 分发Solr到其他节点
  分发完成后，分别对bigdata2、bigdata3主机/opt/module/solr-7.7.3/bin下的solr.in.sh文件，修改为SOLR_HOST=对应主机名。

5. 系统配置
  solr推荐系统允许的最大进程数和最大打开文件数分别为65000和65000，而系统默认值低于推荐值。
  修改/etc/security/limits.conf
```
* soft nofile 65000
* hard nofile 65000
* soft nproc 65000
```

6. 集群启动
  在三台节点上分别启动Solr，这个就是Cloud模式
```
bin/solr start
```
7. Web界面
  访问8983端口，可指定三台节点中的任意一台IP
  [http://bigdata1:8983/solr/](http://bigdata1:8983/solr/)

UI界面出现Cloud菜单栏时，Solr的Cloud模式才算部署成功。

<br>
## 5.8 Atlas 2.1.0
图形引擎Graph Engine：在内部，Atlas通过使用图模型管理元数据对象。以实现元数据对象之间的巨大灵活性和丰富的关系。图引擎是负责在类型系统的类型和实体之间进行转换的组件，以及基础图形模型。除了管理图对象之外，图引擎还为元数据对象创建适当的索引，以便有效地搜索它们。

Atlas是通过HBase存储数据，通过Solr进性元数据搜索，所以需要整合HBase和Solr框架。

### 5.8.1 编译源码
1. [下载源码](https://www.apache.org/dyn/closer.cgi/atlas/2.1.0/apache-atlas-2.1.0-sources.tar.gz)
2. 打包
```
export MAVEN_OPTS="-Xms2g -Xmx2g"
mvn clean install -DskipTests
mvn clean package -Pdist -DskipTests
```
3. 编译完成后在distro/target/目录下可以找到安装包
>jdk版本需要在jdk1.8.0_202及以上，如果失败的查看依赖下载是否完整，多次重试或者更换镜像源。

### 5.8.2 安装
1. 将打包完成的安装包放到需要安装的节点上
2. 解压安装包

### 5.8.3 集成HBase
1. 修改配置文件atlas-application.properties
```
#修改atlas存储数据主机
atlas.graph.storage.hostname=bigdata1:2181,bigdata2:2181,bigdata3:2181
```
2. 软路由HBase集群的配置文件到 ${ATLAS_HOME}/conf/hbase 目录下
```
ln -s /opt/module/hbase/conf/ /opt/module/atlas/conf/hbase/
```
3. 在conf/atlas-env.sh中添加HBASE_CONF_DIR，指定hbase配置文件的位置
```
export HBASE_CONF_DIR=/opt/module/atlas-2.1.0/conf/hbase/conf
```

### 5.8.4 集成Solr
1. 修改配置文件conf/atlas-application.properties，修改如下
```
atlas.graph.index.search.solr.zookeeper-url=bigdata1:2181,bigdata2:2181,bigdata3:2181
```
2. 将conf/solr文件夹复制到外部的solr目录中
```
cp -r /opt/module/atlas-2.1.0/conf/solr /opt/module/solr-7.7.3/
```
然后将复制过来的文件夹名字从solr改为atlas_conf。
最后将该atlas_conf文件分发到所有solr节点。
3. 重启solr，并创建collection
```
[root@cos-bigdata-hadoop-01 solr-7.7.3]# sudo -i -u hxr bash -c "cd /opt/module/solr-7.7.3;bin/solr create -c vertex_index -d /opt/module/solr-7.7.3/atlas_conf -shards 3 -replicationFactor 2"

[root@cos-bigdata-hadoop-01 solr-7.7.3]# sudo -i -u hxr bash -c "cd /opt/module/solr-7.7.3;bin/solr create -c edge_index -d /opt/module/solr-7.7.3/atlas_conf -shards 3 -replicationFactor 2"

[root@cos-bigdata-hadoop-01 solr-7.7.3]# sudo -i -u hxr bash -c "cd /opt/module/solr-7.7.3;bin/solr create -c fulltext_index -d /opt/module/solr-7.7.3/atlas_conf -shards 3 -replicationFactor 2"
```
-shards 3：表示该集合分片数为3
-replicationFactor 2：表示每个分片数都有2个备份
vertex_index、edge_index、fulltext_index：表示集合名称，分别表示点搜索，线搜索和文本搜索。

>注意：如果需要删除vertex_index、edge_index、fulltext_index等collection可以执行如下命令。
>```
>[root@cos-bigdata-hadoop-01 solr-7.7.3]# bin/solr delete -c ${collection_name}
>```

4. 登陆web页面，显示如下图表示创建成功

![image.png](https://upload-images.jianshu.io/upload_images/21580557-d02b86d3eb6a54cd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 5.8.5 集成Kafka
1. 修改配置文件conf/atlas-application.properties，修改如下
```
atlas.notification.embedded=false
atlas.kafka.data=/opt/module/kafka-2.11/logs
atlas.kafka.zookeeper.connect=bigdata1:2181,bigdata2:2181,bigdata3:2181
atlas.kafka.bootstrap.servers=bigdata1:9092,bigdata2:9092,bigdata3:9092
atlas.kafka.zookeeper.session.timeout.ms=4000
atlas.kafka.zookeeper.connection.timeout.ms=2000

atlas.kafka.enable.auto.commit=true
```

2. 启动Kafka并创建topic
```
[root@cos-bigdata-hadoop-02 kafka-2.11]# bin/kafka-topics.sh --zookeeper bigdata1:2181 --create --topic ATLAS_HOOK --partitions 3 --replication-factor 2

[root@cos-bigdata-hadoop-02 kafka-2.11]# bin/kafka-topics.sh --zookeeper bigdata1:2181 --create --topic ATLAS_ENTITIES --partitions 3 --replication-factor 2
```

ATLAS_HOOK: 来自各个组件的Hook 的元数据通知事件通过写入到名为 ATLAS_HOOK 的 Kafka topic 发送到 Atlas；

ATLAS_ENTITIES：从Atlas 到其他集成组件（如Ranger）的事件写入到名为 ATLAS_ENTITIES 的 Kafka topic；

### 5.8.6 Atlas其他配置
1. 修改配置文件conf/atlas-application.properties
```
#########  Server Properties  #########
atlas.rest.address=http://bigdata1:21000
# If enabled and set to true, this will run setup steps when the server starts
atlas.server.run.setup.on.start=false

#########  Entity Audit Configs  #########
atlas.audit.hbase.zookeeper.quorum=bigdata1:2181,bigdata2:2181,bigdata3:2181
```

2. 修改conf/atlas-log4j.xml
```
    <!-- Uncomment the following for perf logs -->
    <!-- 去掉如下代码的注释 -->
    <appender name="perf_appender" class="org.apache.log4j.DailyRollingFileAppender">
        <param name="file" value="${atlas.log.dir}/atlas_perf.log" />
        <param name="datePattern" value="'.'yyyy-MM-dd" />
        <param name="append" value="true" />
        <layout class="org.apache.log4j.PatternLayout">
            <param name="ConversionPattern" value="%d|%t|%m%n" />
        </layout>
    </appender>

    <logger name="org.apache.atlas.perf" additivity="false">
        <level value="debug" />
        <appender-ref ref="perf_appender" />
    </logger>
```
打开后会记录性能指标(如查询等操作)。

### 5.8.7 Kerberos相关配置
若Hadoop集群开启了Kerberos认证，Atlas与Hadoop集群交互之前需要先进性Kerberos认证。

1. 为Atlas创建Kerberos主题，并生成keytab文件
```
kadmin -padmin/admin -wadmin -q "addprinc -randkey atlas/bigdata1"
kadmin -padmin/admin -wadmin -q "xst -k /etc/security/keytab/atlas.service.keytab atlas/bigdata1"
```
2. 修改conf/atlas-application.properties配置文件
  新增如下参数
```
atlas.authentication.method=kerberos
atlas.authentication.principal=atlas/bigdata1@IOTMARS.COM
atlas.authentication.keytab=/etc/security/keytab/atlas.service.keytab
```

### 5.8.8 集成Hive
Hive有hook借口，可以通过编写实现类将hive改动的元数据信息发送到kafka中，然后再倒入到Atlas中更新hive的元数据。
Atlas中已经有hive-hook包实现了这个逻辑功能，只需要将包放到hive的lib目录中。

1. 解压hive-hook包
2. 配置hive-hook的实现类
  首先将解压后文件夹中的hook和hook-bin文件夹放到已经安装的Atlas文件夹根目录下
```
mv /opt/module/apache-atlas-hive-hook-2.1.0/* /opt/module/atlas-2.1.0/
```
然后配置hive的配置文件conf/hive-env.sh，将hive-hook的jar包引入hive中
```
# 将atlas-hive-hook的jar包引入到hive中
export HIVE_AUX_JARS_PATH=/opt/module/atlas-2.1.0/hook/hive
```
最后修改Hive配置文件，使用Atlas实现类。在hive/conf/hive-site.xml文件中增加
```
<property>
    <name>hive.exec.post.hooks</name>
    <value>org.apache.atlas.hive.hook.HiveHook</value>
</property>
```

3. 修改配置文件conf/atlas-application.properties，新增如下
```
######### Hive Hook Configs #######
atlas.hook.hive.synchronous=false  # hook操作是异步，不会阻塞程序运行
atlas.hook.hive.numRetries=3 # 重试次数
atlas.hook.hive.queueSize=10000 # 存放等待执行的任务的队列的长度
atlas.cluster.name=primary # 集群名称，可以随便起名
```

4. 将atlas的配置文件atlas-application.properties复制到hive的配置文件夹中
```
cp /opt/module/atlas-2.1.0/conf/atlas-application.properties /opt/module/hive-3.1.2/conf/
```

## 5.8.9 启动Atlas
启动之前要保证如下框架正常运行
- hdfs/yarn
- zookeeper
- kafka
- hbase
- solr

启动Atlas
```
[root@cos-bigdata-hadoop-01 module]# sudo -i -u hxr bash -c "cd /opt/module/atlas-2.1.0/;bin/atlas_start.py"
```
关闭Atlas
```
[root@cos-bigdata-hadoop-01 module]# sudo -i -u hxr bash -c "cd /opt/module/atlas-2.1.0/;bin/atlas_stop.py"
```

查看UI
http://bigdata1:21000


## 5.8.10 将Hive元数据导入Atlas
将hive添加到系统变量中
```
export HIVE_HOME=/opt/module/hive-3.1.2
export PATH=${PATH}:${HIVE_HOME}/bin
```

将Hive元数据导入到Atlas中
```
[hxr@hadoop102 atlas-2.1.0]$ hook-bin/import-hive.sh
```
输入账号密码为 admin/admin

执行import-hive.sh，相当于初始化作用，Altas获取Hive的库/表结构（注意！此时并没有获获表与表/字段之间的血缘关系，只是获取了表的结构，即 create table语句，此时可以在web ui上面只会看到单个表的名字，location等等信息）

要想正真获取血缘关系，必须配置hive.exec.post.hooks，然后需要把任务重新调度一下，即执行 insert overwrite a select * from b。此时配置的hook 会监听感知到hive表中有更新操作，然后通过Kafka将更新的数据发给Atlas，Atlas会对数据修改，这样在Web Ui 就会看到 a表与b表的血缘关系。

### 5.8.11 Atlas常用配置（可选）
**① 配置内存**
如果计划存储数万个元数据对象，建议调整参数值获得最佳的JVM GC性能。以下是常见的服务器端选项
1）修改配置文件/opt/module/atlas/conf/atlas-env.sh
```
#设置Atlas内存
export ATLAS_SERVER_OPTS="-server -XX:SoftRefLRUPolicyMSPerMB=0 -XX:+CMSClassUnloadingEnabled -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+PrintTenuringDistribution -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=dumps/atlas_server.hprof -Xloggc:logs/gc-worker.log -verbose:gc -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=1m -XX:+PrintGCDetails -XX:+PrintHeapAtGC -XX:+PrintGCTimeStamps"

#建议JDK1.7使用以下配置
export ATLAS_SERVER_HEAP="-Xms15360m -Xmx15360m -XX:MaxNewSize=3072m -XX:PermSize=100M -XX:MaxPermSize=512m"

#建议JDK1.8使用以下配置
export ATLAS_SERVER_HEAP="-Xms15360m -Xmx15360m -XX:MaxNewSize=5120m -XX:MetaspaceSize=100M -XX:MaxMetaspaceSize=512m"

#如果是Mac OS用户需要配置
export ATLAS_SERVER_OPTS="-Djava.awt.headless=true -Djava.security.krb5.realm= -Djava.security.krb5.kdc="
```
参数说明： -XX:SoftRefLRUPolicyMSPerMB 此参数对管理具有许多并发用户的查询繁重工作负载的GC性能特别有用。

<br>
**② 配置用户名密码**
 	Atlas支持以下身份验证方法：File、Kerberos协议、LDAP协议
通过修改配置文件atlas-application.properties文件开启或关闭三种验证方法
```
atlas.authentication.method.kerberos=true|false
atlas.authentication.method.ldap=true|false
atlas.authentication.method.file=true|false
```
如果两个或多个身份证验证方法设置为true，如果较早的方法失败，则身份验证将回退到后一种方法。例如，如果Kerberos身份验证设置为true并且ldap身份验证也设置为true，那么，如果对于没有kerberos principal和keytab的请求，LDAP身份验证将作为后备方案。
本文主要讲解采用文件方式修改用户名和密码设置。其他方式可以参见官网配置即可。
1）打开/opt/module/atlas/conf/users-credentials.properties文件
```
[atguigu@hadoop102 conf]$ vim users-credentials.properties

#username=group::sha256-password
admin=ADMIN::8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918
rangertagsync=RANGER_TAG_SYNC::e3f67240f5117d1753c940dae9eea772d36ed5fe9bd9c94a300e40413f1afb9d
```
admin是用户名称；8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918是采用sha256加密的密码，默认密码为admin。

2）例如：修改用户名称为atguigu，密码为atguigu
	（1）获取sha256加密的atguigu密码
```
[atguigu@hadoop102 conf]$ echo -n "atguigu"|sha256sum
2628be627712c3555d65e0e5f9101dbdd403626e6646b72fdf728a20c5261dc2
```
（2）修改用户名和密码
```
[atguigu@hadoop102 conf]$ vim users-credentials.properties

#username=group::sha256-password
atguigu=ADMIN::2628be627712c3555d65e0e5f9101dbdd403626e6646b72fdf728a20c5261dc2
rangertagsync=RANGER_TAG_SYNC::e3f67240f5117d1753c940dae9eea772d36ed5fe9bd9c94a300e40413f1afb9d
```

**③整合LDAP实现登陆**
[官网配置](http://atlas.apache.org/#/Authentication)

修改配置文件${ATLAS_HOME}conf/atlas-application.properties，添加如下配置
```
#### ldap.type= LDAP or AD
atlas.authentication.method.file=true
atlas.authentication.method.file.filename=sys:atlas.home/conf/users-credentials.properties
# 在服务器上查询用户是否存在，不存在则报错
atlas.authentication.method.ldap.ugi-groups=false

######## LDAP properties #########
atlas.authentication.method.ldap.url=ldap://192.168.101.174:389
atlas.authentication.method.ldap.userDNpattern=uid={0},ou=atlas,dc=ldap,dc=chenjie,dc=asia
atlas.authentication.method.ldap.groupSearchBase=ou=atlas,dc=ldap,dc=chenjie,dc=asia
atlas.authentication.method.ldap.groupSearchFilter=member=uid={0},ou=atlas,dc=ldap,dc=chenjie,dc=asia
atlas.authentication.method.ldap.groupRoleAttribute=uid
atlas.authentication.method.ldap.base.dn=ou=atlas,dc=ldap,dc=chenjie,dc=asia
atlas.authentication.method.ldap.bind.dn=cn=admin,dc=ldap,dc=chenjie,dc=asia
atlas.authentication.method.ldap.bind.password=bigdata123
atlas.authentication.method.ldap.referral=ignore
atlas.authentication.method.ldap.user.searchfilter=uid={0}
atlas.authentication.method.ldap.default.role=ROLE_USER
```

### 5.8.12 Web使用
访问地址为http://bigdata1:21000

**①查询数据**
- 可以通过Search By Type查询hive相关的一些信息，如hive_db(查询Hive数据库元)、hive_process(查询Hive进程，包括建表语句)、hive_table(查询Hive表)、hive_column(查询Hive列)。

- 也可以直接在Search By Text直接搜索，比如要查询name为ddate的列，那么在Search By Query 填写 where name="ddate"， 其他选项筛选条件写法一样。

**②查看血缘关系**
需要先跑一遍完成的流程，Atlas才能绘制出正确且完整的血缘关系图。

Search By Type中选择hive_column_lineage进行血缘关系搜索。
也可以直接查询表或字段，选择Lineage进性查看血缘关系。
