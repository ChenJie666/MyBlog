---
title: Flume-1-7-0
categories:
- 大数据离线
---
# 一、任务文件
## 1.1 说明
flume：
source可以接收netcat、exec、spooldir、taildir、avro等来源的数据。
taildir支持监控多目录（filegroups参数以空格分隔）并实现断点续传，taildir的断点信息存储在taildir_position.json 文件中。fileHeader可以用于采集多个文件并进行区分，设为true，则可以指定header中的key的值，value默认为文件的绝对路径。

file channel：将写到channel的event保存到磁盘的dataDirs文件中，会在内存中维护一个队列，队列中存储了写到文件中的还未被sink消费的event的物理地址。防止内存中的队列信息丢失，会间隔checkpointInterval时间保存到本地的checkpointDir中，还有一个backupCheckpointDir作为checkpointDir的备份。

sink可以将数据发往hdfs、hbase、logger、avro等目的地

flume中存在事务：transactionCapacity

![image.png](Flume-1-7-0.assets\d2c9138c58ea41c49cd97e279372ed29.png)


## 1.2 任务文件配置
主要参数说明：

| 属性名称 |	默认值 |	含义 |
|---|---|---|
|capacity|	100	|存储在channel中的最大event数量，即 queue 的大小
|transactionCapacity|	100	|source 将 event put 到 channel，或者 sink 从 channel take event 的每次最大事物数。putList和takeList的大小。transactionCapacity 必须不大于 capacity|
|keep-alive|	3|	添加或移除 event 的超时时间|
|byteCapacityBufferPercentage|	20	|所有 event 的 header 字节数占 byteCapacity 的百分比|
|byteCapacity	|JVM的80%|	channel 中允许所有 event 字节数之和的最大值（只计算 event 的 body 字节数，不包含 header）。defaultByteCapacity等于JVM可用最大内存的80％（-Xmx的80%）。如果定义了byteCapacity，则 实际byteCapacity = 定义的byteCapacity * (1- Event header百分比) / byteCapacitySlotSize 。byteCapacitySlotSize 默认等于100|
|flumeBatchSize|	100|	KafkaSink 一次事务发送的 event 数|


**Source配置**
| 参数 | 说明 |
| --- | --- |
|  |  |

**Channel配置**
| 参数 | 说明 |
| --- | --- |
|  |  |

**HDFS Sink配置**
| 参数 | 说明 |
| --- | --- |
| a2.sinks.k1.hdfs.filePrefix | 上传文件的前缀  |
| a2.sinks.k1.hdfs.round | 是否按照时间滚动文件夹 |
| a2.sinks.k1.hdfs.roundValue | 多少时间单位创建一个新的文件夹  |
| a2.sinks.k1.hdfs.roundUnit | 重新定义时间单位  |
| a2.sinks.k1.hdfs.useLocalTimeStamp | 是否使用本地时间戳  |
| a2.sinks.k1.hdfs.fileType | 设置文件类型，可支持压缩  |
| a2.sinks.k1.hdfs.rollInterval | 多久生成一个新的文件 |
| a2.sinks.k1.hdfs.rollSize | 设置每个文件的滚动大小 |
| a2.sinks.k1.hdfs.rollCount | 文件的滚动与Event数量无关 |
| a2.sinks.k1.hdfs.batchSize | 积攒多少个Event才flush到HDFS一次 |

hdfs.useLocalTimeStamp配置详解：
hdfs.useLocalTimeStamp为true时，相当于将event的header的timestamp属性设置为当前时间的时间戳（13位）。如果将false设置为false，则我们需要自己设置header中的timestamp属性，这样flume就会根据timestamp中的时间进行分区保存。详见下文TimestampInterceptor。

### 1.2.1 Kafka作为Channel，直接存储到HDFS
**file-kafka-hdfs：**
```
# agent
a1.sources = r1
a1.channels = c1
a1.sinks = k1

# source
a1.sources.r1.channels = c1
a1.sources.r1.type = TAILDIR
a1.sources.r1.positionFile = /opt/module/flume-1.7.0/taildir_position.json
a1.sources.r1.filegroups = f1
a1.sources.r1.filegroups.f1 = /tmp/logs/q6/.*log
a1.sources.r1.fileHeader = false
a1.sources.r1.maxBatchCount = 1000

# interceptor
a1.sources.r1.interceptors = i1 i2
a1.sources.r1.interceptors.i1.type = com.hxr.flume.LogETLInterceptor$Builder
a1.sources.r1.interceptors.i2.type = com.hxr.flume.LogTypeInterceptor$Builder

# multiplexing selector
a1.sources.r1.selector.type = multiplexing
a1.sources.r1.selector.header = topic
a1.sources.r1.selector.mapping.Log_Q6 = c1

# channel
a1.channels.c1.type = org.apache.flume.channel.kafka.KafkaChannel
a1.channels.c1.kafka.bootstrap.servers = bigdata1:9092,bigdata2:9092,bigdata3:9092
a1.channels.c1.kafka.topic = log_q6
a1.channels.c1.parseAsFlumeEvent = false


# sink
a1.sinks.k1.type = hdfs
a1.sinks.k1.hdfs.path = /origin_data/device/logs/q6/%Y-%m-%d/
a1.sinks.k1.hdfs.filePrefix = q6-
#a1.sinks.k1.hdfs.round = true
#a1.sinks.k1.hdfs.roundValue = 10
#a1.sinks.k1.hdfs.roundUnit = minute
#a1.sinks.k1.hdfs.rollInterval = 3600
#a1.sinks.k1.hdfs.rollSize = 134217728
#a1.sinks.k1.hdfs.rollCount = 0
a1.sinks.k1.hdfs.useLocalTimeStamp = true

a1.sinks.k1.hdfs.rollInterval = 3600
a1.sinks.k1.hdfs.rollSize = 134217728
a1.sinks.k1.hdfs.rollCount = 0

# codec LZOP
a1.sinks.k1.hdfs.codeC = lzop
a1.sinks.k1.hdfs.fileType = CompressedStream

# 拼装
a1.sinks.k1.channel = c1
```


### 1.2.2 存储到Kafka，再从Kafka输出到HDFS（分为两个任务，推荐）
**log-kafka.conf**
```
#define
a1.sources= r1
a1.channels= c1 c2

#source
a1.sources.r1.type = TAILDIR
a1.sources.r1.positionFile = /opt/module/flume-1.7.0/taildir_position.json
a1.sources.r1.filegroups = f1
a1.sources.r1.filegroups.f1 = /tmp/logs/q6/.*log
a1.sources.r1.fileHeader = false
a1.sources.r1.maxBatchCount = 1000

#interceptors
#a1.sources.r1.interceptors = i1 i2
#a1.sources.r1.interceptors.i1.type = com.hxr.flume.LogETLInterceptor$Builder
a1.sources.r1.interceptors = i2
a1.sources.r1.interceptors.i2.type = com.hxr.flume.LogTypeInterceptor$Builder

#selector
a1.sources.r1.selector.type = multiplexing
a1.sources.r1.selector.header = topic
a1.sources.r1.selector.mapping.Log_Q6 = c1
a1.sources.r1.selector.mapping.Log_E5 = c2

#channel
a1.channels.c1.type = org.apache.flume.channel.kafka.KafkaChannel
a1.channels.c1.kafka.bootstrap.servers = BigData1:9092,BigData2:9092,BigData3:9092
a1.channels.c1.kafka.topic = ModelLog_Q6
a1.channels.c1.parseAsFlumeEvent = false

a1.channels.c2.type = org.apache.flume.channel.kafka.KafkaChannel
a1.channels.c2.kafka.bootstrap.servers = BigData1:9092,BigData2:9092,BigData3:9092
a1.channels.c2.kafka.topic = ModelLog_E5
a1.channels.c2.parseAsFlumeEvent = false

#combine
a1.sources.r1.channels = c1 c2
```

**kafka-hdfs.conf**
```
#define
a2.sources= r1 r2
a2.channels= c1 c2
a2.sinks = k1 k2

#source
a2.sources.r1.type = org.apache.flume.source.kafka.KafkaSource
a2.sources.r1.batchSize = 5000
a2.sources.r1.batchDurationMillis = 2000
a2.sources.r1.kafka.bootstrap.servers = BigData1:9092,BigData2:9092,BigData3:9092
a2.sources.r1.kafka.topics = Log_Q6
a2.sources.r1.kafka.consumer.group.id = custom.q6

a2.sources.r2.type = org.apache.flume.source.kafka.KafkaSource
a2.sources.r2.batchSize = 5000
a2.sources.r2.batchDurationMillis = 2000
a2.sources.r2.kafka.bootstrap.servers = BigData1:9092,BigData2:9092,BigData3:9092
a2.sources.r2.kafka.topics = Log_E5
a2.sources.r2.kafka.consumer.group.id = custom.e5

#channels
a2.channels.c1.type = memory
a2.channels.c1.capacity = 10000
a2.channels.c1.transactionCapacity = 10000
a2.channels.c1.byteCapacityBufferPercentage = 20
a2.channels.c1.byteCapacity = 800000

a2.channels.c2.type = memory
a2.channels.c2.capacity = 10000
a2.channels.c2.transactionCapacity = 10000
a2.channels.c2.byteCapacityBufferPercentage = 20
a2.channels.c2.byteCapacity = 800000

#sink
a2.sinks.k1.type = hdfs
a2.sinks.k1.hdfs.path = /origin_data/device_model_log/logs/q6/%Y-%m-%d
a2.sinks.k1.hdfs.filePrefix = q6-
a2.sinks.k1.hdfs.rollInterval = 3600
a2.sinks.k1.hdfs.rollSize = 134217728
a2.sinks.k1.hdfs.rollCount = 0
a2.sinks.k1.hdfs.useLocalTimeStamp = true

a2.sinks.k2.type = hdfs
a2.sinks.k2.hdfs.path = /origin_data/device_model_log/logs/e5/%Y-%m-%d
a2.sinks.k2.hdfs.filePrefix = e5-
a2.sinks.k2.hdfs.rollInterval = 3600
a2.sinks.k2.hdfs.rollSize = 134217728
a2.sinks.k2.hdfs.rollCount = 0
a2.sinks.k2.hdfs.useLocalTimeStamp = true

#compress
a2.sinks.k1.hdfs.codeC = lzop
a2.sinks.k1.hdfs.fileType = CompressedStream

a2.sinks.k2.hdfs.codeC = lzop
a2.sinks.k2.hdfs.fileType = CompressedStream

#combine
a2.sources.r1.channels = c1
a2.sources.r2.channels = c2
a2.sinks.k1.channel = c1
a2.sinks.k2.channel = c2
```

### 1.2.3 除了memory channel，还可以使用file channel
**使用file channel**
```
# agent 
a1.sources = r1
a1.channels = c1
a1.sinks = k1

# sources
a1.sources.r1.type = org.apache.flume.source.kafka.KafkaSource
a1.sources.r1.batchSize = 5000
a1.sources.r1.batchDurationMillis = 2000
a1.sources.r1.kafka.bootstrap.servers = bigdata1:9092,bigdata2:9092,bigdata3:9092
a1.sources.r1.kafka.topics = compass-edb-sales-test
a1.sources.r1.kafka.consumer.group.id = edb_consumer

# channels
#a1.channels.c1.type = memory
#a1.channels.c1.capacity = 10000
#a1.channels.c1.transactionCapacity = 10000
#a1.channels.c1.byteCapacityBufferPercentage = 20
#a1.channels.c1.byteCapacity = 800000
a1.channels.c1.type = file 
a1.channels.c1.checkpointDir = /opt/module/flume-1.7.0/checkpoint/edb_file_channel
a1.channels.c1.dataDirs = /opt/module/flume-1.7.0/data/edb_file_channel

# sinks
a1.sinks.k1.type = hdfs
a1.sinks.k1.hdfs.path = /origin_data/compass/edb_test/%Y-%m-%d
a1.sinks.k1.hdfs.filePrefix = edb
a1.sinks.k1.hdfs.batchSize = 100
a1.sinks.k1.hdfs.rollInterval = 3600
a1.sinks.k1.hdfs.rollSize = 134217728
a1.sinks.k1.hdfs.rollCount = 0
a1.sinks.k1.hdfs.useLocalTimeStamp =true


# compress
a1.sinks.k1.hdfs.codeC = lzop
a1.sinks.k1.hdfs.fileType = CompressedStream

# combine
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
```

## 1.3 任务启动和脚本
**启动任务命令：**`/opt/module/flume-1.7.0/bin/flume-ng agent -n a1 -c /opt/module/flume-1.7.0/conf -f /opt/module/flume-1.7.0/job/log-kafka.conf  -Dflume.root.logger=DEBUG,FILE-Dflume.log.file=flume.log`

**启动/关闭脚本**
```
#!/bin/bash

case $1 in
"start")
    for host in bigdata1 #bigdata2
    do
#       ssh ${host} "source /etc/profile ; nohup /opt/module/flume-1.7.0/bin/flume-ng agent -n a1 -c /opt/module/flume-1.7.0/conf -f /opt/module/flume-1.7.0/job/file-kafka-hdfs.conf 1>/dev/null 2>&1 &"
        #ssh ${host} "source /etc/profile ; nohup /opt/module/flume-1.7.0/bin/flume-ng agent -n a1 -c /opt/module/flume-1.7.0/conf -f /opt/module/flume-1.7.0/job/log-kafka.conf 1>/dev/null 2>&1 &"
        ssh bigdata1 "source /etc/profile ; nohup /opt/module/flume-1.7.0/bin/flume-ng agent -n a1 -c /opt/module/flume-1.7.0/conf -f /opt/module/flume-1.7.0/job/log-kafka.conf 1>/dev/null 2>&1 &"
        #ssh ${host} "source /etc/profile ; nohup /opt/module/flume-1.7.0/bin/flume-ng agent -n a2 -c /opt/module/flume-1.7.0/conf -f /opt/module/flume-1.7.0/job/kafka-hdfs.conf 1>/dev/null 2>&1 &"
        ssh bigdata2 "source /etc/profile ; nohup /opt/module/flume-1.7.0/bin/flume-ng agent -n a2 -c /opt/module/flume-1.7.0/conf -f /opt/module/flume-1.7.0/job/kafka-hdfs.conf 1>/dev/null 2>&1 &"
        if [ $? -eq 0 ]
        then
            echo ----- ${host} flume启动成功 -----
        fi
    done
;;
"stop")
    for host in bigdata1 #bigdata2
    do
        ssh ${host} "source /etc/profile ; ps -ef | awk -F \" \" '/log-kafka.conf/ && !/awk/{print \$2}' | xargs kill "
        ssh ${host} "source /etc/profile ; ps -ef | awk -F \" \" '/kafka-hdfs.conf/ && !/awk/{print \$2}' | xargs kill "
        if [ $? -eq 0 ]
        then
            echo ----- ${host} flume关闭成功 -----
        fi
    done
;;
esac
```

<br>
# 二、Flume组件

![image.png](Flume-1-7-0.assets819b1a830f2471ab59e420b127b109f.png)

## 2.1 ChannelSelector
ChannelSelector的作用就是选出Event将要被发往哪个Channel。其共有两种类型，分别是Replicating（复制）和Multiplexing（多路复用）。
ReplicatingSelector会将同一个Event发往所有的Channel，Multiplexing会根据相应的原则，将不同的Event发往不同的Channel。

## 2.2 SinkProcessor
SinkProcessor共有三种类型，分别是DefaultSinkProcessor、LoadBalancingSinkProcessor和FailoverSinkProcessor。
DefaultSinkProcessor对应的是单个的Sink，LoadBalancingSinkProcessor和FailoverSinkProcessor对应的是Sink Group，LoadBalancingSinkProcessor可以实现负载均衡的功能，FailoverSinkProcessor可以错误恢复的功能。

## 2.3 自定义拦截器
自定义拦截器主要分两种：ETL 拦截器、日志类型区分拦截器。
- ETL 拦截器主要用于过滤时间戳不合法和 Json 数据不完整的日志。
- 日志类型区分拦截器主要用于，将启动日志和事件日志区分开来，方便发往 Kafka 的不同Topic。

### 2.3.1 拦截器规划
#### 从Log到Kafka
![image.png](Flume-1-7-0.assets8f2481d535847d18d37d56e66d8e309.png)

日志过滤器：对日志格式进行校验。

#### 从Kafka到HDFS
![image.png](Flume-1-7-0.assets\7eb7d3dfe7f248c8b1e4964fd5620245.png)

**时间过滤器：**
由于Flume默认会用Linux系统时间，作为输出到HDFS路径的时间。如果数据是23:59分产生的。Flume消费Kafka里面的数据时，有可能已经是第二天了，那么这部门数据会被发往第二天的HDFS路径。我们希望的是根据日志里面的实际时间，发往HDFS的路径，所以下面拦截器作用是获取日志中的实际时间。
解决的思路：拦截json日志，通过fastjson框架解析json，获取实际时间ts。将获取的ts时间写入拦截器header头，header的key必须是timestamp(毫秒级)，因为**Flume框架会根据这个key的值识别为时间，写入到HDFS**。


### 2.3.2 代码实现
**依赖**
```
<dependencies>
        <dependency>
            <groupId>org.apache.flume</groupId>
            <artifactId>flume-ng-core</artifactId>
            <version>1.7.0</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>fastjson</artifactId>
            <version>1.2.62</version>
        </dependency>

        <dependency>
            <groupId>com.microsoft.sqlserver</groupId>
            <artifactId>mssql-jdbc</artifactId>
            <version>7.0.0.jre8</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>2.3.2</version>
                <configuration>
                    <source>1.8</source>
                    <target>1.8</target>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-assembly-plugin</artifactId>
                <version>3.1.1</version>
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

**ETLInterceptor**
```
public class ETLInterceptor implements Interceptor {

    @Override
    public void initialize() {

    }

    @Override
    public Event intercept(Event event) {

        byte[] body = event.getBody();
        String log = new String(body, StandardCharsets.UTF_8);

        if (JSONUtils.isJSONValidate(log)) {
            return event;
        } else {
            return null;
        }
    }

    @Override
    public List<Event> intercept(List<Event> list) {

        Iterator<Event> iterator = list.iterator();

        while (iterator.hasNext()){
            Event next = iterator.next();
            if(intercept(next)==null){
                iterator.remove();
            }
        }

        return list;
    }

    public static class Builder implements Interceptor.Builder{

        @Override
        public Interceptor build() {
            return new ETLInterceptor();
        }
        @Override
        public void configure(Context context) {

        }

    }

    @Override
    public void close() {

    }
}
```

**TimeStampInterceptor**
```
public class TimeStampInterceptor implements Interceptor {

    private ArrayList<Event> events = new ArrayList<>();

    @Override
    public void initialize() {

    }

    @Override
    public Event intercept(Event event) {

        Map<String, String> headers = event.getHeaders();
        String log = new String(event.getBody(), StandardCharsets.UTF_8);

        JSONObject jsonObject = JSONObject.parseObject(log);

        String ts = jsonObject.getString("ts");
        headers.put("timestamp", ts);

        return event;
    }

    @Override
    public List<Event> intercept(List<Event> list) {
        events.clear();
        for (Event event : list) {
            events.add(intercept(event));
        }

        return events;
    }

    @Override
    public void close() {

    }

    public static class Builder implements Interceptor.Builder {
        @Override
        public Interceptor build() {
            return new TimeStampInterceptor();
        }

        @Override
        public void configure(Context context) {
        }
    }
}
```

```
# agent
a1.sources = r1
a1.channels = c1
a1.sinks = k1

# sources
a1.sources.r1.type = org.apache.flume.source.kafka.KafkaSource
a1.sources.r1.batchSize = 5000
a1.sources.r1.batchDurationMillis = 2000
a1.sources.r1.kafka.bootstrap.servers = bigdata1:9092,bigdata2:9092,bigdata3:9092
a1.sources.r1.kafka.topics = compass-edb-returnSales-prod
a1.sources.r1.kafka.consumer.group.id = edb_returnSales_consumer

# interceptor
a1.sources.r1.interceptors = i1 i2
a1.sources.r1.interceptors.i1.type = com.iotmars.flume.ETLInterceptor$Builder
a1.sources.r1.interceptors.i2.type = com.iotmars.flume.TimeStampInterceptor$Builder

# channels
#a1.channels.c1.type = memory
#a1.channels.c1.capacity = 10000
#a1.channels.c1.transactionCapacity = 10000
#a1.channels.c1.byteCapacityBufferPercentage = 20
#a1.channels.c1.byteCapacity = 800000
a1.channels.c1.type = file
a1.channels.c1.checkpointDir = /opt/module/flume-1.7.0/checkpoint/edb_returnSales_channel
a1.channels.c1.dataDirs = /opt/module/flume-1.7.0/data/edb_returnSales_channel

# sinks
a1.sinks.k1.type = hdfs
a1.sinks.k1.hdfs.path = /origin_data/compass/edb_salesReturn/%Y-%m-%d
a1.sinks.k1.hdfs.filePrefix = edb_returnSales
a1.sinks.k1.hdfs.batchSize = 100
a1.sinks.k1.hdfs.rollInterval = 3600
a1.sinks.k1.hdfs.rollSize = 134217728
a1.sinks.k1.hdfs.rollCount = 0
a1.sinks.k1.hdfs.useLocalTimeStamp = false


# compress
a1.sinks.k1.hdfs.codeC = lzop
a1.sinks.k1.hdfs.fileType = CompressedStream

# combine
a1.sources.r1.channels = c1
a1.sinks.k1.channel = c1
```

### 2.3.3 配置拦截器
打包后将 带有依赖的jar包 放到flume的lib目录下。

在任务文件中配置拦截器
```
a1.sources.r1.interceptors =  i1
a1.sources.r1.interceptors.i1.type = com.atguigu.flume.interceptor.ETLInterceptor$Builder
```



<br>
# 三、监控
| 字段（图表名称）	| 字段含义 |
|---|---|
|EventPutAttemptCount |	source尝试写入channel的事件总数量 |
|EventPutSuccessCount |	成功写入channel且提交的事件总数量 |
|EventTakeAttemptCount |	sink尝试从channel拉取事件的总数量。 |
|EventTakeSuccessCount |	sink成功读取的事件的总数量 |
|StartTime |	channel启动的时间（毫秒） |
|StopTime |	channel停止的时间（毫秒） |
|ChannelSize |	目前channel中事件的总数量 |
|ChannelFillPercentage |	channel占用百分比 |
|ChannelCapacity |	channel的容量 |


<br>
# 四、调优
优化要从三个组件的角度去分别优化。

## 1、source

sources是flume日志采集的起点，监控日志文件系统目录。其中最常用的是 Spooling Directory Source ， Exec Source 和 Avro Source 。

关键参数讲解：

（1）batchSize：这个参数当你采用的是 Exec Source 时，含义是一次读入channel的数据的行数，当你采用Spooling Directory Source含义是 Granularity（粒度） at which to batch transfer to the channel ，据我分析应该是events（flume最小处理数据单元）的数量。

这个参数一般会设置比较大，一般的数值跟每秒要处理的数值相当。

（2）inputCharset 这个很重要，就是文本文件的编码，默认是flume按照utf-8处理，如果文本数据是gbk，则要增加此参数,

（3）interceptors flume自带的拦截器，可以根据正则表达式去过滤数据，但是据我实际经验总结，这个配置很影响入库性能，因此这部分工作我基本都在sink代码里面做。

## 2、channel

channel 是flume的中间数据缓存管道，有点类似kafka的机制，因此个组件的性能很重要。

我在项目中主要采用的是menmory channel,原因是数据量大，要求极大的数据吞吐量和速度，但是有一点不好的是

如果一旦flume进程down掉，是没有“续点传输”的机制的，filechannel 和它正好相反。

关键参数讲解：

(1) capacity : 存储在channel中的events的最大数量

(2) transactionCapacity ： 每次数据由channel到sink传输的最大events的数量

(3) byteCapacity ：该channel的内存大小，单位是 byte 。


其中transactionCapacity关键中最容易忽略的，因为每个sink的终端不一样，批处理的数量要严格限制。还有一点，events的数量值和channel大小不是一回事，一个event包括单位数据的内容+头数据+数据传输状态。可以说 （events的数量值*单位数据所占字节数）* 0.9 = 所占空间内存数值（就是想说明transactionCapacity 的大小和byteCapacity 不能简答的数值比较）。

## 3、sink
sink组件的核心工作是把channel中数据进行输出到特定的终端，比如hdfs,Hbase,database，avro等等。

因此这块的核心优化工作在优化各个终端（hdfs,hbase,database，avro）的数据插入性能。在这里面我只优化过hbase的数据插入性能(具体的做法就是打开flume hbasesink源码，修改然后打包)，当然这块的工作不在flume本身，这也不是flume所能控制的。
