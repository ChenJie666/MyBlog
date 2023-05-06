---
title: HXR大数据架构和业务(上)
categories:
- 大数据火星人业务
---
# 一、架构

## 1.1 架构图

![1620700859180.png](HXR大数据架构和业务(上).assets\75b0b4d81e24495b81f4b149f303a647.png)



## 1.2 数据流向图

![1620702778841.png](HXR大数据架构和业务(上).assets\dcd1a08f5b524a7eb481a72f3bbf8507.png)




## 1.3 前端展示页面

![1620701050023.png](HXR大数据架构和业务(上).assets\321553d94dd54d9aa122f01e6ef20389.png)




# 二、业务

### 2.1 BI指标

1. 蒸箱模式使用频率统计(包括时间段内使用频次和总频次) stovmode
2. 集成灶故障类型发生频率统计 errorcode
3. 烟机使用频段统计 hoodspeed
4. 灶具使用统计 stovestatus
5. 右灶定时器使用统计 RStoveTimingState
6. 闹钟使用统计 TimingState



### 2.2 分层

- ODS（operation data store）：存放原始数据。保持数据原貌不变；创建分区表，防止后续的全表扫描；`时间分区`，采用`LZO压缩，需要建索引`，`指定输入输出格式`；创建外部表；
- DWD（data warehouse detail）：结构粒度与ODS层保持一致，对ODS层数据进行清洗（去除无效数据、脏数据，数据脱敏，`维度退化`，`数据转换`等）。ETL数据清洗，用hive sql、MR、Python、Kettle、SparkSQL；`时间分区`，采用`LZO压缩，不需要建索引`，采用`parquet格式`存储；创建外部表；
- DWS（data warehouse service）：在DWD基础上，按天进行轻度汇总。`时间分区`，采用`parquet格式`存储；创建外部表；
- DWT（data warehouse topic）：在DWS基础上，按主题进行汇总。采用`parquet格式`存储；创建外部表，时间分区；
- ADS（Application Data Store）：为统计报表提供数据。`明确字段分割符`，与sqoop对应；创建外部表，时间分区。

在ODS层对原始数据进行存储，需要采用压缩（一般lzo为10倍压缩），创建分区表，防止后续的全表扫描。lzop需要建索引才能进行分片，如果时parquet格式+lzo压缩，则不需要切片，因为parquet支持切片。



# 三、数据采集和存储

## 3.1 从飞燕获取数据保存到本地

**pom文件**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.2.5.RELEASE</version>
    </parent>

    <groupId>com.iotmars</groupId>
    <artifactId>hxr-logclient</artifactId>
    <version>1.0-SNAPSHOT</version>

    <dependencies>
        <dependency>
            <groupId>com.aliyun.openservices</groupId>
            <artifactId>iot-client-message</artifactId>
            <version>1.1.5</version>
        </dependency>

        <dependency>
            <groupId>commons-codec</groupId>
            <artifactId>commons-codec</artifactId>
            <version>1.11</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>2.3.2</version>
                <configuration>
                    <source>1.8</source>
                    <target>1.8</target>
                </configuration>
            </plugin>
            <plugin>
                <artifactId>maven-assembly-plugin</artifactId>
                <configuration>
                    <descriptorRefs>
                        <descriptorRef>jar-with-dependencies</descriptorRef>
                    </descriptorRefs>
                    <archive>
                        <manifest>
                            <mainClass>com.iotmars.ClientApplication</mainClass>
                        </manifest>
                    </archive>
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

</project>
```

**业务代码**

```java
package com.iotmars;

import com.aliyun.openservices.iot.api.Profile;
import com.aliyun.openservices.iot.api.message.MessageClientFactory;
import com.aliyun.openservices.iot.api.message.api.MessageClient;
import com.aliyun.openservices.iot.api.message.callback.MessageCallback;
import com.aliyun.openservices.iot.api.message.entity.MessageToken;

import java.io.*;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

/**
 * @Description:
 * @Author: CJ
 * @Data: 2020/11/9 10:06
 */
public class ClientApplication {

    private static String path = "/tmp/logs/q6";

    public static void main(String[] args) throws UnsupportedEncodingException {
        String endPoint = "https://ilop.iot-as-http2.cn-shanghai.aliyuncs.com:443";
        String appKey = "27698993";
        String appSecret = "2d13de8dfdb4284f6e1e5e1ecc21a6d9";

        Profile profile = Profile.getAppKeyProfile(endPoint, appKey, appSecret);

        MessageCallback messageCallback = new MessageCallback() {
            public Action consume(MessageToken messageToken) {
                byte[] payload = messageToken.getMessage().getPayload();
//                String data = new String(payload);
//                System.out.println("receive : " + data);

                // 获取当前时间
                ZoneId Shanghai = ZoneId.of("Asia/Shanghai");
                ZonedDateTime now = ZonedDateTime.now(Shanghai);
                DateTimeFormatter df = DateTimeFormatter.ofPattern("yyyy-MM-dd");
                String strDate = now.format(df);
                // 获取路径
//        String filename = "C:/Users/Administrator/Desktop/log" + File.separator + "q6_" + strDate + ".log";
                String filename = path + File.separator + "q6_" + strDate + ".log";
                if (args.length > 0) {
                    filename = args[0];
                }

                // 输出到文件中
                File file = new File(filename);
                if (!file.getParentFile().exists()) {
                    file.getParentFile().mkdirs();
                }


                FileOutputStream fos;

                try {
                    fos = new FileOutputStream(filename, true);
                    BufferedOutputStream bos = new BufferedOutputStream(fos);
                    bos.write(payload);
                    bos.write("
".getBytes());
                    bos.flush();
                } catch (Exception e) {
                    e.printStackTrace();
                }

                return Action.CommitSuccess;
            }
        };

        MessageClient messageClient = MessageClientFactory.messageClient(profile);
        messageClient.setMessageListener(messageCallback);
        messageClient.connect(messageCallback);

        try {
            System.in.read();
        } catch (Exception e) {
        }
    }
}
```





## 3.2 Flume

### 3.2.1 集群启动脚本

```sh
#!/bin/bash

case $1 in
"start")
	for host in bigdata1 #bigdata2
	do
#		ssh ${host} "source /etc/profile ; nohup /opt/module/flume-1.7.0/bin/flume-ng agent -n a1 -c /opt/module/flume-1.7.0/conf -f /opt/module/flume-1.7.0/job/file-kafka-hdfs.conf 1>/dev/null 2>&1 &"
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



### 3.2.2 JobFile

**log-kafka.conf**

```properties
#define
a1.sources= r1
a1.channels= c1 c2

#source
a1.sources.r1.type = TAILDIR
a1.sources.r1.positionFile = /opt/module/flume-1.7.0/taildir_position.json
a1.sources.r1.filegroups = f1
a1.sources.r1.filegroups.f1 = /tmp/logs/q6/.*log
a1.sources.r1.fileHeader = false
a1.sources.ri.maxBatchCount = 1000

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

```properties
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
a2.sinks.k1.channel = c1
a2.sinks.k1.hdfs.path = /origin_data/device_model_log/logs/q6/%Y-%m-%d
a2.sinks.k1.hdfs.filePrefix = q6-
a2.sinks.k1.hdfs.rollInterval = 3600
a2.sinks.k1.hdfs.rollSize = 134217728
a2.sinks.k1.hdfs.rollCount = 0
a2.sinks.k1.hdfs.useLocalTimeStamp = true

a2.sinks.k2.type = hdfs
a2.sinks.k2.channel = c2
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



### 3.2.3 拦截器

**pom文件**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.hxr.flume</groupId>
    <artifactId>flume_interceptor</artifactId>
    <version>1.0-SNAPSHOT</version>

    <dependencies>
        <dependency>
            <groupId>org.apache.flume</groupId>
            <artifactId>flume-ng-core</artifactId>
            <version>1.7.0</version>
            <scope>provided </scope>
        </dependency>
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>fastjson</artifactId>
            <version>1.2.68</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>2.3.2</version>
                <configuration>
                    <source>1.8</source>
                    <target>1.8</target>
                </configuration>
            </plugin>
            <plugin>
                <artifactId>maven-assembly-plugin</artifactId>
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

</project>
```

**LogETLInterceptor.java**

```java
package com.hxr.flume;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import org.apache.flume.Context;
import org.apache.flume.Event;
import org.apache.flume.interceptor.Interceptor;

import java.nio.charset.StandardCharsets;
import java.util.*;

/**
 * @Author: CJ
 * @Data: 2020/6/3 10:38
 */
public class LogETLInterceptor implements Interceptor {

    private final Map<String, JSONObject> buffer = new HashMap<>(Collections.emptyMap());

    @Override
    public void initialize() {

    }

    @Override
    public Event intercept(Event event) {

        byte[] body = event.getBody();
        String log = new String(body, StandardCharsets.UTF_8);

        // 通过比较同一设备的相邻的两条物模型，来判断用户进行的操作，采集改变的字段
        if (log.startsWith("{\"deviceType\"")) {
            JSONObject jsonObject = JSONObject.parseObject(log);
            String iotId = jsonObject.getString("iotId");

            // 比较两条记录
            JSONObject newItems = jsonObject.getJSONObject("items");

            JSONObject oldItems = buffer.get(iotId);

            buffer.put(iotId, newItems);
            if (Objects.isNull(iotId)) {
                return null;
            }

            Set<String> keySet = newItems.keySet();
            if (keySet.size() < 35) {
                if (keySet.contains("ComSWVersion")) {
                    return null; // 暂时过滤掉设备启动时的mac信息
                } else {
                    return event; // 放行音量等事件信息
                }
            } else if (keySet.size() == 36) {
                return null; // 不知道36个属性的记录是哪来的，先过滤掉
            }

            // 对非事件信息进行比较，获取改变的属性并重置event的body
            Map<String, JSONObject> changePros = new HashMap<>(Collections.emptyMap());
            keySet.forEach(key -> {
                JSONObject oldValue = oldItems.getJSONObject(key);
                String oldValueVa = oldValue.getString("value");

                JSONObject newValue = newItems.getJSONObject(key);
                Object newValueVa = newValue.getString("value");

                if (!oldValueVa.equals(newValueVa)) {
                    changePros.put(key, newValue);
                }
            });

            if (changePros.isEmpty()) {
                return null;
            }

            jsonObject.put("items", changePros);
            event.setBody(jsonObject.toJSONString().getBytes());

            return event;
        }

        return null;
    }

    @Override
    public List<Event> intercept(List<Event> events) {

        Iterator<Event> iterator = events.iterator();

        while (iterator.hasNext()) {
            Event event = iterator.next();
            Event intercept = intercept(event);
            if (intercept == null) {
                iterator.remove();
            }
        }

        return events;
    }

    @Override
    public void close() {

    }

    public static class Builder implements Interceptor.Builder {

        @Override
        public Interceptor build() {
            return new LogETLInterceptor();
        }

        @Override
        public void configure(Context context) {

        }
    }

}
```

**LogTypeInterceptor.java**

```java
package com.hxr.flume;

import com.alibaba.fastjson.JSONObject;
import org.apache.flume.Context;
import org.apache.flume.Event;
import org.apache.flume.interceptor.Interceptor;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

/**
 * @Author: CJ
 * @Data: 2020/6/3 10:38
 */
public class LogTypeInterceptor implements Interceptor {

    private String q6ProduceKey = "a17JZbZVctc";
    private String e5ProduceKey = "a1wJ5yI6O37";

    @Override
    public void initialize() {

    }

    @Override
    public Event intercept(Event event) {
        byte[] body = event.getBody();
        String log = new String(body, StandardCharsets.UTF_8);
        Map<String, String> headers = event.getHeaders();

        JSONObject jsonObject = JSONObject.parseObject(log);
        String productKey = jsonObject.getString("productKey");

        if (q6ProduceKey.equals(productKey)) {
            headers.put("topic", "Log_Q6");
        } else if (e5ProduceKey.equals(productKey)) {
            headers.put("topic", "Log_E5");
        } else {
            return null;
        }

        return event;
    }

    @Override
    public List<Event> intercept(List<Event> events) {

        for (Event event : events) {
            intercept(event);
        }

        return events;
    }

    @Override
    public void close() {

    }

    public static class Builder implements Interceptor.Builder{

        @Override
        public Interceptor build() {
            return new LogTypeInterceptor();
        }

        @Override
        public void configure(Context context) {

        }
    }

}
```





## 3.3 Flink

**pom文件**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>org.example</groupId>
    <artifactId>LogBehaviorETL</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <flink.version>1.12.0</flink.version>
        <scala.binary.version>2.11</scala.binary.version>
        <kafka.version>2.2.0</kafka.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-streaming-scala_${scala.binary.version}</artifactId>
            <version>${flink.version}</version>
<!--            <scope>provided</scope>-->
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-clients_${scala.binary.version}</artifactId>
            <version>${flink.version}</version>
<!--            <scope>provided</scope>-->
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-table-api-scala-bridge_${scala.binary.version}</artifactId>
            <version>${flink.version}</version>
<!--            <scope>provided</scope>-->
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-table-planner-blink_${scala.binary.version}</artifactId>
            <version>${flink.version}</version>
<!--            <scope>provided</scope>-->
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-cep-scala_${scala.binary.version}</artifactId>
            <version>${flink.version}</version>
        </dependency>

        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-connector-kafka_${scala.binary.version}</artifactId>
            <version>${flink.version}</version>
        </dependency>

        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>fastjson</artifactId>
            <version>1.2.68</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>net.alchim31.maven</groupId>
                <artifactId>scala-maven-plugin</artifactId>
                <version>4.4.0</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>compile</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <artifactId>maven-assembly-plugin</artifactId>
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
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.2</version>
                <configuration>
                    <source>1.8</source>
                    <target>1.8</target>
                </configuration>
            </plugin>
        </plugins>
    </build>

</project>
```

**业务代码**

```scala
package com.iotmars.mcook

import java.util
import java.util.Properties

import com.alibaba.fastjson.{JSON, JSONObject}
import com.iotmars.mcook.common.KafkaConstant
import org.apache.flink.api.common.serialization.SimpleStringSchema
import org.apache.flink.cep.{PatternSelectFunction, PatternTimeoutFunction}
import org.apache.flink.cep.scala.CEP
import org.apache.flink.cep.scala.pattern.Pattern
import org.apache.flink.streaming.api.functions.timestamps.BoundedOutOfOrdernessTimestampExtractor
import org.apache.flink.streaming.api.scala._
import org.apache.flink.streaming.api.windowing.time.Time
import org.apache.flink.streaming.connectors.kafka.{FlinkKafkaConsumer, FlinkKafkaProducer}

import scala.util.control.Breaks._
import scala.collection.JavaConversions._

/**
 * @Description:
 * @Author: CJ
 * @Data: 2021/1/13 14:04
 */
case class ModelLogQ6(iotId: String, productKey: String, gmtCreate: Long, data: String)

object LogBehaviorEtl {
  def main(args: Array[String]): Unit = {
    val env = StreamExecutionEnvironment.getExecutionEnvironment
    env.setParallelism(3)

    val readProperties = new Properties()
    readProperties.setProperty("bootstrap.servers", KafkaConstant.BOOTSTRAP_SERVERS)
    readProperties.setProperty("group.id", "consumer-group")
    readProperties.setProperty("key.deserializer", "org.apache.kafka.common.serialization.StringDeserializer")
    readProperties.setProperty("value.deserializer", "org.apache.kafka.common.serialization.StringDeserializer")
    val myConsumer = new FlinkKafkaConsumer[String](KafkaConstant.READ_KAFKA_TOPIC, new SimpleStringSchema(), readProperties)
    //    myConsumer.setStartFromEarliest()
    myConsumer.setStartFromLatest()

    // 从kafka中读取
    val inputStream = env.addSource(myConsumer)
    // 从端口中读取
    //        val inputStream = env.socketTextStream("192.168.32.242", 7777)
    // 从文本中读取
    //        val resource = getClass.getResource("/DeviceModelLog")
    //        val inputStream = env.readTextFile(resource.getPath)

    //    inputStream.print("...")

    val dataStream = inputStream
      .map(log => {
        val jsonObject = JSON.parseObject(log)
        val iotId = jsonObject.getString("iotId")
        val productKey = jsonObject.getString("productKey")
        val gmtCreate = jsonObject.getLong("gmtCreate")
        //        val data = jsonObject.getString("items")
        ModelLogQ6(iotId, productKey, gmtCreate, log)
      })
      //          .assignAscendingTimestamps(_.gmtCreate)
      .assignTimestampsAndWatermarks(new BoundedOutOfOrdernessTimestampExtractor[ModelLogQ6](Time.seconds(5)) {
        override def extractTimestamp(element: ModelLogQ6): Long = element.gmtCreate
      })

    // 如果是WifiMac，则通过mq存储到数据库中


    val pattern = Pattern
      .begin[ModelLogQ6]("start").where(_.productKey.equals("a17JZbZVctc"))
      .next("next").where(_.productKey.equals("a17JZbZVctc"))

    val outputTag = new OutputTag[String]("order-timeout")

    val selectStream = CEP
      .pattern(dataStream.keyBy(_.iotId), pattern)
      .select(outputTag, new LogTimeoutResult, new LogCompleteResult)

    // 将正确的数据存入Log_Q6中，将迟到的数据存入LogLate_Q6
    val writeProperties = new Properties()
    writeProperties.setProperty("bootstrap.servers", KafkaConstant.BOOTSTRAP_SERVERS)
    //    writeProperties.setProperty("key.serializer", "org.apache.kafka.common.serialization.StringSerializer")
    //    writeProperties.setProperty("value.serializer", "org.apache.kafka.common.serialization.StringSerializer")
    // 迟到数据
    val lateStream = selectStream.getSideOutput(outputTag)
    //    lateStream.print("warn")
    lateStream.addSink(new FlinkKafkaProducer[String](KafkaConstant.WRITE_LATE_KAFKA_TOPIC, new SimpleStringSchema(), writeProperties))
    // 正常数据
    val resultStream = selectStream.filter(_ != null)
    //    resultStream.print("info")
    resultStream.addSink(new FlinkKafkaProducer[String](KafkaConstant.WRITE_SUCCESS_KAFKA_TOPIC, new SimpleStringSchema(), writeProperties))

    env.execute("Q6 Log ETL")
  }
}

class LogTimeoutResult extends PatternTimeoutFunction[ModelLogQ6, String] {
  override def timeout(map: util.Map[String, util.List[ModelLogQ6]], l: Long): String =
    map.get("start").get(0).data
}

class LogCompleteResult extends PatternSelectFunction[ModelLogQ6, String] {
  override def select(map: util.Map[String, util.List[ModelLogQ6]]): String = {
    val start: ModelLogQ6 = map.get("start").get(0)
    val next: ModelLogQ6 = map.get("next").get(0)
    val oldData: String = start.data
    val newData: String = next.data

    // 解析新数据的事件
    try {
      val jsonObject: JSONObject = JSON.parseObject(newData)
      val newItems = jsonObject.getJSONObject("items")
      val keySet: util.Set[String] = newItems.keySet()

      // 解析旧数据的事件
      val oldItems = JSON.parseObject(oldData).getJSONObject("items")

      val changePros = new util.HashMap[String, JSONObject]()

      for (key <- keySet) {
        breakable {
          // 过滤掉目前无用且一直打印的字段
          if ("LFirewallTemp".equals(key) || "StOvRealTemp".equals(key) || "RFirewallTemp".equals(key)) {
            break()
          }

          val oldValue: JSONObject = oldItems.getJSONObject(key)
          val oldValueVa: String = oldValue.getString("value")

          val newValue: JSONObject = newItems.getJSONObject(key)
          val newValueVa: String = newValue.getString("value")

          // 剩余时间取最大值
          if ("StOvSetTimerLeft".equals(key) || "HoodOffLeftTime".equals(key)) {
            if (newValueVa.compareTo(oldValueVa) > 0) {
              changePros.put(key, newValue)
            }
          }

          // 累计运行时间取最大值
          if ("HoodRunningTime".equals(key)) {
            if (newValueVa.compareTo(oldValueVa) < 0) {
              changePros.put(key, newValue)
            }
          }

          if (!oldValueVa.equals(newValueVa)) {
            changePros.put(key, newValue)
          }
        }
      }

      if (changePros.nonEmpty) {
        jsonObject.put("items", changePros)
        jsonObject.toString()
      } else {
        null
      }
    } catch {
      case e: Exception => return null;
    }
  }
}
```

**枚举类**

```java
package com.iotmars.mcook.common;

/**
 * @Description:
 * @Author: CJ
 * @Data: 2021/1/15 11:31
 */
public interface KafkaConstant {

    String BOOTSTRAP_SERVERS = "192.168.32.242:9092,192.168.32.243:9092,192.168.32.244:9092";
    String READ_KAFKA_TOPIC = "ModelLog_Q6";
    String WRITE_SUCCESS_KAFKA_TOPIC = "Log_Q6";
    String WRITE_LATE_KAFKA_TOPIC = "LogLate_Q6";

}
```





## 3.4 Kafka

### 3.4.1 创建原始数据表

**ModelLog_E5**

```
bin/kafka-topics.sh  --zookeeper bigdata12:2181  --create --topic ModelLog_E5 --partitions 3  --replication-factor 2
```

**ModelLog_Q6**

```
bin/kafka-topics.sh  --zookeeper bigdata12:2181  --create --topic ModelLog_Q6 --partitions 3  --replication-factor 2
```

### 3.4.2 创建ETL后数据表

**Log_E5**

```
bin/kafka-topics.sh  --zookeeper bigdata12:2181  --create --topic Log_E5 --partitions 3  --replication-factor 2
```

**Log_Q6**

```
bin/kafka-topics.sh  --zookeeper bigdata12:2181  --create --topic Log_Q6 --partitions 3  --replication-factor 2
```

### 3.4.3 创建迟到数据表

**LogLate_E5**

```
bin/kafka-topics.sh  --zookeeper bigdata12:2181  --create --topic LogLate_E5 --partitions 3  --replication-factor 2
```

**LogLate_Q6**

```
bin/kafka-topics.sh  --zookeeper bigdata12:2181  --create --topic LogLate_Q6 --partitions 3  --replication-factor 2
```


<br>
# 四、数据处理

## 4.1 总表

### 4.1.1 建表

**ods_q6_model_log**

```sql
DROP TABLE IF EXISTS device_model_log.ods_q6_model_log;
CREATE EXTERNAL TABLE device_model_log.ods_q6_model_log (`line` string)
PARTITIONED BY (`dt` string)
STORED AS
  INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/warehouse/device_model_log/ods/ods_q6_model_log';
```

**dwd_q6_event_log**

```sql
DROP TABLE IF EXISTS dwd_q6_event_log;
CREATE EXTERNAL TABLE dwd_q6_event_log (
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`gmt_create` string,
`device_name` string,
`event_name` string,
`event_value` string,
`event_time` string
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwd/dwd_q6_event_log'
TBLPROPERTIES('parquet.compression'='lzo');
```



### 4.1.2 导入脚本

**hdfs2ods_model_log.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
LOAD DATA INPATH '/origin_data/${APP}/logs/q6/${do_date}' INTO TABLE ${APP}.ods_q6_model_log partition(dt='${do_date}');
"

$hive -e "$sql"
```

**ods2dwd_model_log.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE ${APP}.dwd_q6_event_log
partition(dt='${do_date}')
SELECT 
 get_json_object(line,'$.deviceType'),
 get_json_object(line,'$.iotId'),
 get_json_object(line,'$.requestId'),
 get_json_object(line,'$.checkFailedData'),
 get_json_object(line,'$.productKey'),
 get_json_object(line,'$.gmtCreate'),
 get_json_object(line,'$.deviceName'),
 event_name,
 split(event_value,'\\|')[0],
 split(event_value,'\\|')[1]
FROM ${APP}.ods_q6_model_log LATERAL VIEW flat_analizer(get_json_object(line,'$.items')) tmp_flat AS event_name,event_value
WHERE dt='${do_date}' AND get_json_object(line,'$.items')<>'';"

$hive -e "$sql"
```



## 4.2 事件表

### 4.2.1 蒸箱模式使用频率统计(包括时间段内使用频次和总频次) stovmode

#### 4.2.1.1 dwd层

- 建表

**dwd_q6_stovmode_log**

```sql
DROP TABLE IF EXISTS dwd_q6_stovmode_log;
CREATE EXTERNAL TABLE dwd_q6_stovmode_log (
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`gmt_create` string,
`device_name` string,  
`st_ov_mode` string,
`event_time` string
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwd/dwd_q6_stovmode_log'
TBLPROPERTIES('parquet.compression'='lzo');
```

- 导入脚本

**dwd2dwd_stovmode_log.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi    

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE ${APP}.dwd_q6_stovmode_log
partition(dt='${do_date}')
SELECT 
device_type,
iot_id,
request_id,
check_failed_data,
product_key,
gmt_create,
device_name,
event_value,
event_time
FROM ${APP}.dwd_q6_event_log 
WHERE dt='${do_date}' AND event_name='StOvMode';
"

$hive -e "$sql"
```



#### 4.2.1.2 dws层

##### 4.2.1.2.1 设备维度

- 建表

**dws_q6_device_stovmode_daycount**

```sql
DROP TABLE IF EXISTS dws_q6_device_stovmode_daycount;
CREATE EXTERNAL TABLE dws_q6_device_stovmode_daycount(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`st_ov_mode` string,
`mode_count` bigint COMMENT '累计模式启动次数',
`mor_count` bigint COMMENT '6:00-10:00累计模式启动次数',
`noo_count` bigint COMMENT '10:00-14:00累计模式启动次数',
`eve_count` bigint COMMENT '16:00-20:00累计模式启动次数',
`oth_count` bigint COMMENT '其他时段累计模式启动次数'
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dws/dws_q6_device_stovmode_daycount';
```

- 导入脚本

**dwd2dws_device_stovmode_count.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE ${APP}.dws_q6_device_stovmode_daycount
partition(dt='${do_date}')
SELECT 
  daycount.deviceType,
  daycount.iotId,
  daycount.requestId,
  daycount.checkFailedData,
  daycount.productKey,
  daycount.deviceName,
  daycount.st_ov_mode,
  daycount.amount,
  nvl(morcount.mor_count,0),
  nvl(noocount.noo_count,0),
  nvl(evecount.eve_count,0),
  daycount.amount-nvl(morcount.mor_count,0)-nvl(noocount.noo_count,0)-nvl(evecount.eve_count,0)
FROM
(
SELECT 
  concat_ws('|',collect_set(device_type)) deviceType, 
  concat_ws('|',collect_set(iot_id)) iotId,
  concat_ws('|',collect_set(request_id)) requestId,
  concat_ws('|',collect_set(check_failed_data)) checkFailedData,
  concat_ws('|',collect_set(product_key)) productKey,
  concat_ws('|',collect_set(device_name)) deviceName,
  st_ov_mode,
  count(*) amount
FROM ${APP}.dwd_q6_stovmode_log  
WHERE dt='${do_date}'
GROUP BY st_ov_mode
) daycount
LEFT JOIN 
(
SELECT 
  st_ov_mode,
  count(*) mor_count
FROM ${APP}.dwd_q6_stovmode_log
WHERE dt='${do_date}' and from_unixtime(cast(event_time/1000 as bigint),'H') IN (6,7,8,9)
GROUP BY st_ov_mode
) morcount ON daycount.st_ov_mode=morcount.st_ov_mode
LEFT JOIN 
(
SELECT 
  st_ov_mode,
  count(*) noo_count
FROM ${APP}.dwd_q6_stovmode_log
WHERE dt='${do_date}' and from_unixtime(cast(event_time/1000 as bigint),'H') IN (10,11,12,13)
GROUP BY st_ov_mode
) noocount ON daycount.st_ov_mode=noocount.st_ov_mode
LEFT JOIN 
(
SELECT 
  st_ov_mode,
  count(*) eve_count
FROM ${APP}.dwd_q6_stovmode_log
WHERE dt='${do_date}' and from_unixtime(cast(event_time/1000 as bigint),'H') IN (16,17,18,19)
GROUP BY st_ov_mode
) evecount ON daycount.st_ov_mode=evecount.st_ov_mode
"

$hive -e "$sql"
```



##### 4.2.1.2.2 用户维度

###### 4.2.1.2.2.1 使用频率统计

- 建表

```sql
DROP TABLE IF EXISTS dws_q6_user_stovmode_daycount;
CREATE EXTERNAL TABLE dws_q6_user_stovmode_daycount(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`st_ov_mode` string,
`mode_count` bigint COMMENT '累计模式启动次数',
`mor_count` bigint COMMENT '6:00-10:00累计模式启动次数',
`noo_count` bigint COMMENT '10:00-14:00累计模式启动次数',
`eve_count` bigint COMMENT '16:00-20:00累计模式启动次数',
`oth_count` bigint COMMENT '其他时段累计模式启动次数'
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dws/dws_q6_user_stovmode_daycount';
```

- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use ${APP};
SET hive.exec.dynamic.partition.mode=nonstrict;
with
temp as 
(
  SELECT 
    device_type,
    iot_id,
    '' request_id,
    '' check_failed_data,
    product_key,
    device_name,
    st_ov_mode,
    lag(st_ov_mode,1,st_ov_mode) over(partition by iot_id order by event_time) st_ov_lag_mode,
    event_time,
    from_unixtime(cast(substr(event_time,1,10) as bigint),'H') start_hour
  FROM dwd_q6_stovmode_log
  WHERE dt = '${do_date}'
)

INSERT OVERWRITE TABLE dws_q6_user_stovmode_daycount
PARTITION(dt='${do_date}')
SELECT 
  concat_ws('|',collect_set(device_type)) device_type,
  iot_id,
  concat_ws('|',collect_set(request_id)) request_id,
  concat_ws('|',collect_set(check_failed_data)) check_failed_data,
  concat_ws('|',collect_set(product_key)) product_key,
  concat_ws('|',collect_set(device_name)) device_name,
  concat_ws('|',collect_set(st_ov_mode)) st_ov_mode,
  count(*) start_count,
  sum(mor) mor_count,
  sum(noo) noo_count,
  sum(eve) eve_count,
  sum(oth) oth_count
FROM 
(
SELECT
  device_type,
  iot_id,
  request_id,
  check_failed_data,
  product_key,
  device_name,
  st_ov_mode,
  st_ov_lag_mode,
  event_time,
  start_hour,
  from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H') end_hour,
  if(start_hour<10 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=6,1,0) mor,
  if(start_hour<14 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=10,1,0) noo,
  if(start_hour<20 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=16,1,0) eve,
  if((start_hour<6 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=0) or (start_hour<16 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=14) or (start_hour<24 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=20),1,0) oth
FROM 
(
    SELECT
      device_type,
      iot_id,
      request_id,
      check_failed_data,
      product_key,
      device_name,
      st_ov_mode,
      st_ov_lag_mode,
      event_time,
      lead(event_time,1,event_time) over(partition by iot_id order by event_time) event_next_time,
      start_hour
    FROM  temp
    WHERE (st_ov_mode>0 and st_ov_lag_mode=0) or (st_ov_mode=0 and st_ov_lag_mode>0)
) temp1
WHERE st_ov_mode<>0
) temp2
GROUP BY iot_id;
"

$hive -e "$sql"
```



###### 4.2.1.2.2.2 使用时间统计

- 建表

```sql
DROP TABLE IF EXISTS dws_q6_user_stovmode_daytime;
CREATE EXTERNAL TABLE dws_q6_user_stovmode_daytime(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`st_ov_mode` string COMMENT '蒸烤模式',
`start_count` bigint COMMENT '当日该模式启动次数统计',
`using_time` string COMMENT '当日该模式使用时间统计'
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwd/dws_q6_user_stovmode_daytime';
```

- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
with
temp as
(
SELECT
  device_type,
  iot_id,
  '' request_id,
  '' check_failed_data,
  product_key,
  gmt_create,
  device_name,
  st_ov_mode,
  event_time,
  lead(event_time,1,event_time) over(partition by iot_id order by event_time) event_next_time
FROM dwd_q6_stovmode_log
WHERE dt='${do_date}'
)

INSERT OVERWRITE TABLE dws_q6_user_stovmode_daytime
PARTITION(dt='${do_date}')
SELECT 
  concat_ws('|',collect_set(device_type)) device_type,
  iot_id,
  concat_ws('|',collect_set(request_id)) request_id,
  concat_ws('|',collect_set(check_failed_data)) check_failed_data,
  concat_ws('|',collect_set(product_key)) product_key,
  concat_ws('|',collect_set(device_name)) device_name,
  st_ov_mode,
  count(*),
  cast(sum(event_next_time-event_time)/1000/3600 as decimal(38,3)) 
FROM temp
GROUP BY iot_id,st_ov_mode;
"

$hive -e "$sql"
```



#### 4.2.1.3 dwt层

##### 4.2.1.3.1 设备维度

- 建表

**dwt_q6_device_stovmode_topic**

```sql
DROP TABLE IF EXISTS dwt_q6_device_stovmode_topic;
CREATE EXTERNAL TABLE dwt_q6_device_stovmode_topic(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`st_ov_mode` string,
`mode_date_first` string comment '首次使用时间',
`mode_date_last` string comment '末次使用时间',
`mode_day_count` bigint comment '当日使用次数',
`mode_count` bigint comment '累积使用次数',
`mor_day_count` bigint COMMENT '当日6:00-10:00累计模式启动次数',
`mor_count` bigint COMMENT '累积6:00-10:00累计模式启动次数',
`noo_day_count` bigint COMMENT '当日10:00-14:00累计模式启动次数',
`noo_count` bigint COMMENT '累积10:00-14:00累计模式启动次数',
`eve_day_count` bigint COMMENT '当日16:00-20:00累计模式启动次数',
`eve_count` bigint COMMENT '累积16:00-20:00累计模式启动次数',
`oth_day_count` bigint COMMENT '当日其他时段累计模式启动次数',
`oth_count` bigint COMMENT '累积其他时段累计模式启动次数'
)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwt/dwt_q6_device_stovmode_topic';
```

- 导入脚本

**dws2dwt_device_stovmode_topic.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE dwt_q6_device_stovmode_topic
SELECT
nvl(new.device_type,old.device_type),
nvl(new.iot_id,old.iot_id),
nvl(new.request_id,old.request_id),
nvl(new.check_failed_data,old.check_failed_data),
nvl(new.product_key,old.product_key),
nvl(new.device_name,old.device_name),
nvl(new.st_ov_mode,old.st_ov_mode),
if(old.mode_date_first is null,'${do_date}',old.mode_date_first),
if(new.st_ov_mode is null,old.mode_date_last,'${do_date}'),
if(new.st_ov_mode is null,0,new.mode_count),
nvl(new.mode_count,0) + nvl(old.mode_day_count,0),
if(new.st_ov_mode is null,0,new.mor_count),
nvl(new.mor_count,0) + nvl(old.mor_day_count,0),
if(new.st_ov_mode is null,0,new.noo_count),
nvl(new.noo_count,0) + nvl(old.noo_day_count,0),
if(new.st_ov_mode is null,0,new.eve_count),
nvl(new.eve_count,0) + nvl(old.eve_day_count,0),
if(new.st_ov_mode is null,0,new.oth_count),
nvl(new.oth_count,0) + nvl(old.oth_day_count,0)
FROM
(
    SELECT * FROM dwt_q6_device_stovmode_topic WHERE dt=date_sub('${do_date}',1)
) old
FULL OUTER JOIN
(
    SELECT * FROM dws_q6_device_stovmode_daycount WHERE dt='${do_date}'
) new
ON old.st_ov_mode=new.st_ov_mode;
"

$hive -e "$sql"

```



##### 4.2.1.3.2 用户维度

- 建表

```sql
DROP TABLE IF EXISTS dwt_q6_user_stovmode_topic;
CREATE EXTERNAL TABLE dwt_q6_user_stovmode_topic(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`mode_count`  bigint COMMENT '当日设备烟机总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`mode_amount`  bigint COMMENT '总计设备烟机总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`mor_count` bigint COMMENT '当日6:00-10:00烟机启动次数统计(跨时段会多次计算)', 
`mor_amount` bigint COMMENT '总计6:00-10:00烟机启动次数统计(跨时段会多次计算)',
`noo_count` bigint COMMENT '当日10:00-14:00烟机启动次数统计(跨时段会多次计算)',
`noo_amount` bigint COMMENT '总计10:00-14:00烟机启动次数统计(跨时段会多次计算)',
`eve_count` bigint COMMENT '当日16:00-20:00烟机启动次数统计(跨时段会多次计算)',
`eve_amount` bigint COMMENT '总计16:00-20:00烟机启动次数统计(跨时段会多次计算)',
`oth_count` bigint COMMENT '当日其他时间段烟机启动次数统计(跨时段会多次计算)',
`oth_amount` bigint COMMENT '总计其他时间段烟机启动次数统计(跨时段会多次计算)',
`mode0_using_time`  decimal(38,3) COMMENT '当日未设定模式使用时间统计',
`mode0_using_alltime`  decimal(38,3) COMMENT '总计未设定模式使用时间统计',
`mode1_using_time`  decimal(38,3) COMMENT '当日经典蒸模式使用时间统计',
`mode1_using_alltime`  decimal(38,3) COMMENT '总计经典蒸模式使用时间统计',
`mode2_using_time`  decimal(38,3) COMMENT '当日快速蒸模式使用时间统计',
`mode2_using_alltime`  decimal(38,3) COMMENT '总计快速蒸模式使用时间统计',
`mode33_using_time`  decimal(38,3) COMMENT '当日风扇烤模式使用时间统计',
`mode33_using_alltime`   decimal(38,3) COMMENT '总计风扇烤模式使用时间统计',
`mode34_using_time`   decimal(38,3) COMMENT '当日强烧烤模式使用时间统计',
`mode34_using_alltime`   decimal(38,3) COMMENT '总计强烧烤模式使用时间统计',
`mode35_using_time`   decimal(38,3) COMMENT '当日热风烧烤模式使用时间统计',
`mode35_using_alltime`   decimal(38,3) COMMENT '总计热风烧烤模式使用时间统计',
`mode36_using_time`   decimal(38,3) COMMENT '当日上下加热模式使用时间统计',
`mode36_using_alltime`   decimal(38,3) COMMENT '总计上下加热模式使用时间统计',
`mode37_using_time`  decimal(38,3) COMMENT '当日热风烤模式使用时间统计',
`mode37_using_alltime`   decimal(38,3) COMMENT '总计热风烤模式使用时间统计',
`mode38_using_time`   decimal(38,3) COMMENT '当日立体热风模式使用时间统计',
`mode38_using_alltime`  decimal(38,3) COMMENT '总计立体热风模式使用时间统计',
`mode39_using_time`  decimal(38,3) COMMENT '当日嫩烤模式使用时间统计',
`mode39_using_alltime`  decimal(38,3) COMMENT '总计嫩烤模式使用时间统计',
`mode65_using_time` decimal(38,3) COMMENT '当日解冻模式使用时间统计',
`mode65_using_alltime`  decimal(38,3) COMMENT '总计解冻模式使用时间统计',
`mode66_using_time` decimal(38,3) COMMENT '当日发酵模式使用时间统计',
`mode66_using_alltime`  decimal(38,3) COMMENT '总计发酵模式使用时间统计',
`mode67_using_time` decimal(38,3) COMMENT '当日杀菌模式使用时间统计',
`mode67_using_alltime`  decimal(38,3) COMMENT '总计杀菌模式使用时间统计',
`mode68_using_time` decimal(38,3) COMMENT '当日保温模式使用时间统计',
`mode68_using_alltime`  decimal(38,3) COMMENT '总计保温模式使用时间统计',
`mode69_using_time` decimal(38,3) COMMENT '当日烘干模式使用时间统计',
`mode69_using_alltime`  decimal(38,3) COMMENT '总计烘干模式使用时间统计',
`mode70_using_time` decimal(38,3) COMMENT '当日除垢模式使用时间统计',
`mode70_using_alltime`  decimal(38,3) COMMENT '总计除垢模式使用时间统计',
`mode71_using_time` decimal(38,3) COMMENT '当日延时模式使用时间统计',
`mode71_using_alltime` decimal(38,3) COMMENT '总计延时模式使用时间统计',
`mode0_count` bigint COMMENT '当日未设定模式次数统计',
`mode0_amount` bigint COMMENT '总计未设定模式次数统计',
`mode1_count` bigint COMMENT '当日经典蒸模式次数统计',
`mode1_amount` bigint COMMENT '总计经典蒸模式次数统计',
`mode2_count` bigint COMMENT '当日快速蒸模式次数统计',
`mode2_amount` bigint COMMENT '总计快速蒸模式次数统计',
`mode33_count` bigint COMMENT '当日风扇烤模式次数统计',
`mode33_amount` bigint COMMENT '总计风扇烤模式次数统计',
`mode34_count` bigint COMMENT '当日强烧烤模式次数统计',
`mode34_amount` bigint COMMENT '总计强烧烤模式次数统计',
`mode35_count` bigint COMMENT '当日热风烧烤模式次数统计',
`mode35_amount` bigint COMMENT '总计热风烧烤模式次数统计',
`mode36_count` bigint COMMENT '当日上下加热模式次数统计',
`mode36_amount` bigint COMMENT '总计上下加热模式次数统计',
`mode37_count` bigint COMMENT '当日热风烤模式次数统计',
`mode37_amount` bigint COMMENT '总计热风烤模式次数统计',
`mode38_count` bigint COMMENT '当日立体热风模式次数统计',
`mode38_amount` bigint COMMENT '总计立体热风模式次数统计',
`mode39_count` bigint COMMENT '当日嫩烤模式次数统计',
`mode39_amount` bigint COMMENT '总计嫩烤模式次数统计',
`mode65_count` bigint COMMENT '当日解冻模式次数统计',
`mode65_amount` bigint COMMENT '总计解冻模式次数统计',
`mode66_count` bigint COMMENT '当日发酵模式次数统计',
`mode66_amount` bigint COMMENT '总计发酵模式次数统计',
`mode67_count` bigint COMMENT '当日杀菌模式次数统计',
`mode67_amount` bigint COMMENT '总计杀菌模式次数统计',
`mode68_count` bigint COMMENT '当日保温模式次数统计',
`mode68_amount` bigint COMMENT '总计保温模式次数统计',
`mode69_count` bigint COMMENT '当日烘干模式次数统计',
`mode69_amount` bigint COMMENT '总计烘干模式次数统计',
`mode70_count` bigint COMMENT '当日除垢模式次数统计',
`mode70_amount` bigint COMMENT '总计除垢模式次数统计',
`mode71_count` bigint COMMENT '当日延时模式次数统计',
`mode71_amount` bigint COMMENT '总计延时模式次数统计'
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwt/dwt_q6_user_stovmode_topic';

```



- 导入脚本

首先创建自定义udf函数daytime_udf('0-115.581|1-83.281|33-2.448|36-5.677|38-1.358',38)，可以传入key解析出对应的value值。

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;

with
temp_count as
(
    SELECT 
      nvl(new.device_type,old.device_type) device_type,
      nvl(new.iot_id,old.iot_id) iot_id,
      nvl(new.request_id,old.request_id) request_id,
      nvl(new.check_failed_data,old.check_failed_data) check_failed_data,
      nvl(new.product_key,old.product_key) product_key, 
      nvl(new.device_name,old.device_name) device_name,
      nvl(new.mode_count,0) mode_count,
      nvl(new.mode_count,0)+nvl(old.mode_amount,0) mode_amount,
      nvl(new.mor_count,0) mor_count,
      nvl(new.mor_count,0)+nvl(old.mor_amount,0) mor_amount,
      nvl(new.noo_count,0) noo_count,
      nvl(new.noo_count,0)+nvl(old.noo_amount,0) noo_amount,
      nvl(new.eve_count,0) eve_count,
      nvl(new.eve_count,0)+nvl(old.eve_amount,0) eve_amount,
      nvl(new.oth_count,0) oth_count,
      nvl(new.oth_count,0)+nvl(old.oth_amount,0) oth_amount
    FROM 
    (
        SELECT
          device_type,
          iot_id,
          request_id,
          check_failed_data,
          product_key,
          device_name,
          mode_amount,
          mor_amount,
          noo_amount,
          eve_amount,
          oth_amount
        FROM dwt_q6_user_stovmode_topic
        WHERE dt=date_sub('${do_date}',1)
    ) old
    FULL OUTER JOIN
    (
        SELECT 
          device_type,
          iot_id,
          request_id,
          check_failed_data,
          product_key,
          device_name,
          mode_count,
          mor_count,
          noo_count,
          eve_count,
          oth_count
        FROM dws_q6_user_stovmode_daycount
        WHERE dt='${do_date}'
    ) new ON old.iot_id=new.iot_id
),
temp_time as
(
    SELECT 
      nvl(new.iot_id,old.iot_id) iot_id,
      nvl(new.mode0_using_time,0) mode0_using_time,
      nvl(new.mode0_using_time,0)+nvl(old.mode0_using_alltime,0) mode0_using_alltime,
      nvl(new.mode1_using_time,0) mode1_using_time,
      nvl(new.mode1_using_time,0)+nvl(old.mode1_using_alltime,0) mode1_using_alltime,
      nvl(new.mode2_using_time,0) mode2_using_time,
      nvl(new.mode2_using_time,0)+nvl(old.mode2_using_alltime,0) mode2_using_alltime,
      nvl(new.mode33_using_time,0) mode33_using_time,
      nvl(new.mode33_using_time,0)+nvl(old.mode33_using_alltime,0) mode33_using_alltime,
      nvl(new.mode34_using_time,0) mode34_using_time,
      nvl(new.mode34_using_time,0)+nvl(old.mode34_using_alltime,0) mode34_using_alltime,
      nvl(new.mode35_using_time,0) mode35_using_time,
      nvl(new.mode35_using_time,0)+nvl(old.mode35_using_alltime,0) mode35_using_alltime,
      nvl(new.mode36_using_time,0) mode36_using_time,
      nvl(new.mode36_using_time,0)+nvl(old.mode36_using_alltime,0) mode36_using_alltime,
      nvl(new.mode37_using_time,0) mode37_using_time,
      nvl(new.mode37_using_time,0)+nvl(old.mode37_using_alltime,0) mode37_using_alltime,
      nvl(new.mode38_using_time,0) mode38_using_time,
      nvl(new.mode38_using_time,0)+nvl(old.mode38_using_alltime,0) mode38_using_alltime,
      nvl(new.mode39_using_time,0) mode39_using_time,
      nvl(new.mode39_using_time,0)+nvl(old.mode39_using_alltime,0) mode39_using_alltime,
      nvl(new.mode65_using_time,0) mode65_using_time,
      nvl(new.mode65_using_time,0)+nvl(old.mode65_using_alltime,0) mode65_using_alltime,
      nvl(new.mode66_using_time,0) mode66_using_time,
      nvl(new.mode66_using_time,0)+nvl(old.mode66_using_alltime,0) mode66_using_alltime,
      nvl(new.mode67_using_time,0) mode67_using_time,
      nvl(new.mode67_using_time,0)+nvl(old.mode67_using_alltime,0) mode67_using_alltime,
      nvl(new.mode68_using_time,0) mode68_using_time,
      nvl(new.mode68_using_time,0)+nvl(old.mode68_using_alltime,0) mode68_using_alltime,
      nvl(new.mode69_using_time,0) mode69_using_time,
      nvl(new.mode69_using_time,0)+nvl(old.mode69_using_alltime,0) mode69_using_alltime,
      nvl(new.mode70_using_time,0) mode70_using_time,
      nvl(new.mode70_using_time,0)+nvl(old.mode70_using_alltime,0) mode70_using_alltime,
      nvl(new.mode71_using_time,0) mode71_using_time,
      nvl(new.mode71_using_time,0)+nvl(old.mode71_using_alltime,0) mode71_using_alltime,
      nvl(new.mode0_count,0) mode0_count,
      nvl(new.mode0_count,0)+nvl(old.mode0_amount,0) mode0_amount,
      nvl(new.mode1_count,0) mode1_count,
      nvl(new.mode1_count,0)+nvl(old.mode1_amount,0) mode1_amount,
      nvl(new.mode2_count,0) mode2_count,
      nvl(new.mode2_count,0)+nvl(old.mode2_amount,0) mode2_amount,
      nvl(new.mode33_count,0) mode33_count,
      nvl(new.mode33_count,0)+nvl(old.mode33_amount,0) mode33_amount,
      nvl(new.mode34_count,0) mode34_count,
      nvl(new.mode34_count,0)+nvl(old.mode34_amount,0) mode34_amount,
      nvl(new.mode35_count,0) mode35_count,
      nvl(new.mode35_count,0)+nvl(old.mode35_amount,0) mode35_amount,
      nvl(new.mode36_count,0) mode36_count,
      nvl(new.mode36_count,0)+nvl(old.mode36_amount,0) mode36_amount,
      nvl(new.mode37_count,0) mode37_count,
      nvl(new.mode37_count,0)+nvl(old.mode37_amount,0) mode37_amount,
      nvl(new.mode38_count,0) mode38_count,
      nvl(new.mode38_count,0)+nvl(old.mode38_amount,0) mode38_amount,
      nvl(new.mode39_count,0) mode39_count,
      nvl(new.mode39_count,0)+nvl(old.mode39_amount,0) mode39_amount,
      nvl(new.mode65_count,0) mode65_count,
      nvl(new.mode65_count,0)+nvl(old.mode65_amount,0) mode65_amount,
      nvl(new.mode66_count,0) mode66_count,
      nvl(new.mode66_count,0)+nvl(old.mode66_amount,0) mode66_amount,
      nvl(new.mode67_count,0) mode67_count,
      nvl(new.mode67_count,0)+nvl(old.mode67_amount,0) mode67_amount,
      nvl(new.mode68_count,0) mode68_count,
      nvl(new.mode68_count,0)+nvl(old.mode68_amount,0) mode68_amount,
      nvl(new.mode69_count,0) mode69_count,
      nvl(new.mode69_count,0)+nvl(old.mode69_amount,0) mode69_amount,
      nvl(new.mode70_count,0) mode70_count,
      nvl(new.mode70_count,0)+nvl(old.mode70_amount,0) mode70_amount,
      nvl(new.mode71_count,0) mode71_count,
      nvl(new.mode71_count,0)+nvl(old.mode71_amount,0) mode71_amount
    FROM 
    (
        SELECT
          iot_id,
          mode0_using_alltime,
          mode1_using_alltime,
          mode2_using_alltime,
          mode33_using_alltime,
          mode34_using_alltime,
          mode35_using_alltime,
          mode36_using_alltime,
          mode37_using_alltime,
          mode38_using_alltime,
          mode39_using_alltime,
          mode65_using_alltime,
          mode66_using_alltime,
          mode67_using_alltime,
          mode68_using_alltime,
          mode69_using_alltime,
          mode70_using_alltime,
          mode71_using_alltime,
          mode0_amount,
          mode1_amount,
          mode2_amount,
          mode33_amount,
          mode34_amount,
          mode35_amount,
          mode36_amount,
          mode37_amount,
          mode38_amount,
          mode39_amount,
          mode65_amount,
          mode66_amount,
          mode67_amount,
          mode68_amount,
          mode69_amount,
          mode70_amount,
          mode71_amount
        FROM dwt_q6_user_stovmode_topic
        WHERE dt=date_sub('${do_date}',1)
    ) old
    FULL OUTER JOIN 
    (
        SELECT
          iot_id,
          daytime_udf(val,0) mode0_using_time,
          daytime_udf(val,1) mode1_using_time,
          daytime_udf(val,2) mode2_using_time,
          daytime_udf(val,33) mode33_using_time,
          daytime_udf(val,34) mode34_using_time,
          daytime_udf(val,35) mode35_using_time,
          daytime_udf(val,36) mode36_using_time,
          daytime_udf(val,37) mode37_using_time,
          daytime_udf(val,38) mode38_using_time,
          daytime_udf(val,39) mode39_using_time,
          daytime_udf(val,65) mode65_using_time,
          daytime_udf(val,66) mode66_using_time,
          daytime_udf(val,67) mode67_using_time,
          daytime_udf(val,68) mode68_using_time,
          daytime_udf(val,69) mode69_using_time,
          daytime_udf(val,70) mode70_using_time,
          daytime_udf(val,71) mode71_using_time,
          daytime_udf(valc,0) mode0_count,
          daytime_udf(valc,1) mode1_count,
          daytime_udf(valc,2) mode2_count,
          daytime_udf(valc,33) mode33_count,
          daytime_udf(valc,34) mode34_count,
          daytime_udf(valc,35) mode35_count,
          daytime_udf(valc,36) mode36_count,
          daytime_udf(valc,37) mode37_count,
          daytime_udf(valc,38) mode38_count,
          daytime_udf(valc,39) mode39_count,
          daytime_udf(valc,65) mode65_count,
          daytime_udf(valc,66) mode66_count,
          daytime_udf(valc,67) mode67_count,
          daytime_udf(valc,68) mode68_count,
          daytime_udf(valc,69) mode69_count,
          daytime_udf(valc,70) mode70_count,
          daytime_udf(valc,71) mode71_count
        FROM 
        (
            SELECT
              iot_id,
              concat_ws('|',collect_set(concat(st_ov_mode,'-',using_time))) val,
              concat_ws('|',collect_set(concat(st_ov_mode,'-',start_count))) valc
            FROM dws_q6_user_stovmode_daytime
            WHERE dt='${do_date}'
            GROUP BY iot_id
        ) tmp
    ) new ON old.iot_id=new.iot_id
)

INSERT OVERWRITE TABLE dwt_q6_user_stovmode_topic
PARTITION(dt='${do_date}')
SELECT
  device_type,
  temp_count.iot_id,
  request_id,
  check_failed_data,
  product_key,
  device_name,
  mode_count,
  mode_amount,
  mor_count, 
  mor_amount,
  noo_count,
  noo_amount,
  eve_count,
  eve_amount,
  oth_count,
  oth_amount,
  mode0_using_time,
  mode0_using_alltime,
  mode1_using_time,
  mode1_using_alltime,
  mode2_using_time,
  mode2_using_alltime,
  mode33_using_time,
  mode33_using_alltime,
  mode34_using_time,
  mode34_using_alltime,
  mode35_using_time,
  mode35_using_alltime,
  mode36_using_time,
  mode36_using_alltime,
  mode37_using_time,
  mode37_using_alltime,
  mode38_using_time,
  mode38_using_alltime,
  mode39_using_time,
  mode39_using_alltime,
  mode65_using_time,
  mode65_using_alltime,
  mode66_using_time,
  mode66_using_alltime,
  mode67_using_time,
  mode67_using_alltime,
  mode68_using_time,
  mode68_using_alltime,
  mode69_using_time,
  mode69_using_alltime,
  mode70_using_time,
  mode70_using_alltime,
  mode71_using_time,
  mode71_using_alltime,
  mode0_count,
  mode0_amount,
  mode1_count,
  mode1_amount,
  mode2_count,
  mode2_amount,
  mode33_count,
  mode33_amount,
  mode34_count,
  mode34_amount,
  mode35_count,
  mode35_amount,
  mode36_count,
  mode36_amount,
  mode37_count,
  mode37_amount,
  mode38_count,
  mode38_amount,
  mode39_count,
  mode39_amount,
  mode65_count,
  mode65_amount,
  mode66_count,
  mode66_amount,
  mode67_count,
  mode67_amount,
  mode68_count,
  mode68_amount,
  mode69_count,
  mode69_amount,
  mode70_count,
  mode70_amount,
  mode71_count,
  mode71_amount
FROM temp_count
JOIN temp_time ON temp_count.iot_id=temp_time.iot_id;
"

$hive -e "$sql"

```



#### 4.2.1.4 ads层

##### 4.2.1.4.1 设备维度

- 建表

```sql
DROP TABLE IF EXISTS ads_q6_device_stovmode_count;
CREATE EXTERNAL TABLE ads_q6_device_stovmode_count(
`date` string COMMENT '统计日期',
`product_key` string,
`mode_count` bigint COMMENT '当日设备烟机总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`mode_amount` bigint COMMENT '总计设备烟机总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`mor_count` bigint COMMENT '当日6:00-10:00蒸烤箱启动次数统计(跨时段会多次计算)', 
`mor_amount` bigint COMMENT '总计6:00-10:00蒸烤箱启动次数统计(跨时段会多次计算)',
`noo_count` bigint COMMENT '当日10:00-14:00蒸烤箱启动次数统计(跨时段会多次计算)',
`noo_amount` bigint COMMENT '总计10:00-14:00蒸烤箱启动次数统计(跨时段会多次计算)',
`eve_count` bigint COMMENT '当日16:00-20:00蒸烤箱启动次数统计(跨时段会多次计算)',
`eve_amount` bigint COMMENT '总计16:00-20:00蒸烤箱启动次数统计(跨时段会多次计算)',
`oth_count` bigint COMMENT '当日其他时间段蒸烤箱启动次数统计(跨时段会多次计算)',
`oth_amount` bigint COMMENT '总计其他时间段蒸烤箱启动次数统计(跨时段会多次计算)',
`mode0_using_time` string COMMENT '当日未设定模式使用时间统计',
`mode0_using_alltime` string COMMENT '总计未设定模式使用时间统计',
`mode1_using_time` string COMMENT '当日经典蒸模式使用时间统计',
`mode1_using_alltime` string COMMENT '总计经典蒸模式使用时间统计',
`mode2_using_time` string COMMENT '当日快速蒸模式使用时间统计',
`mode2_using_alltime` string COMMENT '总计快速蒸模式使用时间统计',
`mode33_using_time` string COMMENT '当日风扇烤模式使用时间统计',
`mode33_using_alltime` string COMMENT '总计风扇烤模式使用时间统计',
`mode34_using_time` string COMMENT '当日强烧烤模式使用时间统计',
`mode34_using_alltime` string COMMENT '总计强烧烤模式使用时间统计',
`mode35_using_time` string COMMENT '当日热风烧烤模式使用时间统计',
`mode35_using_alltime` string COMMENT '总计热风烧烤模式使用时间统计',
`mode36_using_time` string COMMENT '当日上下加热模式使用时间统计',
`mode36_using_alltime` string COMMENT '总计上下加热模式使用时间统计',
`mode37_using_time` string COMMENT '当日热风烤模式使用时间统计',
`mode37_using_alltime` string COMMENT '总计热风烤模式使用时间统计',
`mode38_using_time` string COMMENT '当日立体热风模式使用时间统计',
`mode38_using_alltime` string COMMENT '总计立体热风模式使用时间统计',
`mode39_using_time` string COMMENT '当日嫩烤模式使用时间统计',
`mode39_using_alltime` string COMMENT '总计嫩烤模式使用时间统计',
`mode65_using_time` string COMMENT '当日解冻模式使用时间统计',
`mode65_using_alltime` string COMMENT '总计解冻模式使用时间统计',
`mode66_using_time` string COMMENT '当日发酵模式使用时间统计',
`mode66_using_alltime` string COMMENT '总计发酵模式使用时间统计',
`mode67_using_time` string COMMENT '当日杀菌模式使用时间统计',
`mode67_using_alltime` string COMMENT '总计杀菌模式使用时间统计',
`mode68_using_time` string COMMENT '当日保温模式使用时间统计',
`mode68_using_alltime` string COMMENT '总计保温模式使用时间统计',
`mode69_using_time` string COMMENT '当日烘干模式使用时间统计',
`mode69_using_alltime` string COMMENT '总计烘干模式使用时间统计',
`mode70_using_time` string COMMENT '当日除垢模式使用时间统计',
`mode70_using_alltime` string COMMENT '总计除垢模式使用时间统计',
`mode71_using_time` string COMMENT '当日延时模式使用时间统计',
`mode71_using_alltime` string COMMENT '总计延时模式使用时间统计',
`mode0_count` bigint COMMENT '当日未设定模式次数统计',
`mode0_amount` bigint COMMENT '总计未设定模式次数统计',
`mode1_count` bigint COMMENT '当日经典蒸模式次数统计',
`mode1_amount` bigint COMMENT '总计经典蒸模式次数统计',
`mode2_count` bigint COMMENT '当日快速蒸模式次数统计',
`mode2_amount` bigint COMMENT '总计快速蒸模式次数统计',
`mode33_count` bigint COMMENT '当日风扇烤模式次数统计',
`mode33_amount` bigint COMMENT '总计风扇烤模式次数统计',
`mode34_count` bigint COMMENT '当日强烧烤模式次数统计',
`mode34_amount` bigint COMMENT '总计强烧烤模式次数统计',
`mode35_count` bigint COMMENT '当日热风烧烤模式次数统计',
`mode35_amount` bigint COMMENT '总计热风烧烤模式次数统计',
`mode36_count` bigint COMMENT '当日上下加热模式次数统计',
`mode36_amount` bigint COMMENT '总计上下加热模式次数统计',
`mode37_count` bigint COMMENT '当日热风烤模式次数统计',
`mode37_amount` bigint COMMENT '总计热风烤模式次数统计',
`mode38_count` bigint COMMENT '当日立体热风模式次数统计',
`mode38_amount` bigint COMMENT '总计立体热风模式次数统计',
`mode39_count` bigint COMMENT '当日嫩烤模式次数统计',
`mode39_amount` bigint COMMENT '总计嫩烤模式次数统计',
`mode65_count` bigint COMMENT '当日解冻模式次数统计',
`mode65_amount` bigint COMMENT '总计解冻模式次数统计',
`mode66_count` bigint COMMENT '当日发酵模式次数统计',
`mode66_amount` bigint COMMENT '总计发酵模式次数统计',
`mode67_count` bigint COMMENT '当日杀菌模式次数统计',
`mode67_amount` bigint COMMENT '总计杀菌模式次数统计',
`mode68_count` bigint COMMENT '当日保温模式次数统计',
`mode68_amount` bigint COMMENT '总计保温模式次数统计',
`mode69_count` bigint COMMENT '当日烘干模式次数统计',
`mode69_amount` bigint COMMENT '总计烘干模式次数统计',
`mode70_count` bigint COMMENT '当日除垢模式次数统计',
`mode70_amount` bigint COMMENT '总计除垢模式次数统计',
`mode71_count` bigint COMMENT '当日延时模式次数统计',
`mode71_amount` bigint COMMENT '总计延时模式次数统计'
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/warehouse/device_model_log/ads/ads_q6_device_stovmode_count';

```

- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE ads_q6_device_stovmode_count
PARTITION(dt='${do_date}')
SELECT 
  '${do_date}',
  product_key,
  cast(sum(mode_count) as decimal(38,3)),
  cast(sum(mode_amount) as decimal(38,3)),
  cast(sum(mor_count) as decimal(38,3)),
  cast(sum(mor_amount) as decimal(38,3)),
  cast(sum(noo_count) as decimal(38,3)),
  cast(sum(noo_amount) as decimal(38,3)),
  cast(sum(eve_count) as decimal(38,3)),
  cast(sum(eve_amount) as decimal(38,3)),
  cast(sum(oth_count) as decimal(38,3)),
  cast(sum(oth_amount) as decimal(38,3)),
  cast(sum(mode0_using_time) as decimal(38,3)),
  cast(sum(mode0_using_alltime) as decimal(38,3)),
  cast(sum(mode1_using_time) as decimal(38,3)),
  cast(sum(mode1_using_alltime) as decimal(38,3)),
  cast(sum(mode2_using_time) as decimal(38,3)),
  cast(sum(mode2_using_alltime) as decimal(38,3)),
  cast(sum(mode33_using_time) as decimal(38,3)),
  cast(sum(mode33_using_alltime) as decimal(38,3)),
  cast(sum(mode34_using_time) as decimal(38,3)),
  cast(sum(mode34_using_alltime) as decimal(38,3)),
  cast(sum(mode35_using_time) as decimal(38,3)),
  cast(sum(mode35_using_alltime) as decimal(38,3)),
  cast(sum(mode36_using_time) as decimal(38,3)),
  cast(sum(mode36_using_alltime) as decimal(38,3)),
  cast(sum(mode37_using_time) as decimal(38,3)),
  cast(sum(mode37_using_alltime) as decimal(38,3)),
  cast(sum(mode38_using_time) as decimal(38,3)),
  cast(sum(mode38_using_alltime) as decimal(38,3)),
  cast(sum(mode39_using_time) as decimal(38,3)),
  cast(sum(mode39_using_alltime) as decimal(38,3)),
  cast(sum(mode65_using_time) as decimal(38,3)),
  cast(sum(mode65_using_alltime) as decimal(38,3)),
  cast(sum(mode66_using_time) as decimal(38,3)),
  cast(sum(mode66_using_alltime) as decimal(38,3)),
  cast(sum(mode67_using_time) as decimal(38,3)),
  cast(sum(mode67_using_alltime) as decimal(38,3)),
  cast(sum(mode68_using_time) as decimal(38,3)),
  cast(sum(mode68_using_alltime) as decimal(38,3)),
  cast(sum(mode69_using_time) as decimal(38,3)),
  cast(sum(mode69_using_alltime) as decimal(38,3)),
  cast(sum(mode70_using_time) as decimal(38,3)),
  cast(sum(mode70_using_alltime) as decimal(38,3)),
  cast(sum(mode71_using_time) as decimal(38,3)),
  cast(sum(mode71_using_alltime) as decimal(38,3)),
  sum(mode0_count),
  sum(mode0_amount),
  sum(mode1_count),
  sum(mode1_amount),
  sum(mode2_count),
  sum(mode2_amount),
  sum(mode33_count),
  sum(mode33_amount),
  sum(mode34_count),
  sum(mode34_amount),
  sum(mode35_count),
  sum(mode35_amount),
  sum(mode36_count),
  sum(mode36_amount),
  sum(mode37_count),
  sum(mode37_amount),
  sum(mode38_count),
  sum(mode38_amount),
  sum(mode39_count),
  sum(mode39_amount),
  sum(mode65_count),
  sum(mode65_amount),
  sum(mode66_count),
  sum(mode66_amount),
  sum(mode67_count),
  sum(mode67_amount),
  sum(mode68_count),
  sum(mode68_amount),
  sum(mode69_count),
  sum(mode69_amount),
  sum(mode70_count),
  sum(mode70_amount),
  sum(mode71_count),
  sum(mode71_amount)
FROM dwt_q6_user_stovmode_topic
WHERE dt='${do_date}'
GROUP BY product_key;
"

$hive -e "$sql"

```



**如下已废弃**

- 建表

**ads_q6_device_stovmode_count**

```sql
DROP TABLE IF EXISTS ads_q6_device_stovmode_count;
CREATE EXTERNAL TABLE ads_q6_device_stovmode_count(
`dt` string COMMENT '统计日期',
`st_ov_mode` string COMMENT '模式类型',
`mode_date_first` string COMMENT '首次使用时间',
`mode_date_last` string COMMENT '末次使用时间',
`day_count` bigint COMMENT '当日启动次数',
`mor_day_count` bigint COMMENT '当日6:00-10:00累计模式启动次数',
`noo_day_count` bigint COMMENT '当日10:00-14:00累计模式启动次数',
`eve_day_count` bigint COMMENT '当日16:00-20:00累计模式启动次数',
`oth_day_count` bigint COMMENT '当日其他时段累计模式启动次数',
`week_count` bigint COMMENT '当周启动次数',
`mor_week_count` bigint COMMENT '当月6:00-10:00累计模式启动次数',
`noo_week_count` bigint COMMENT '当周10:00-14:00累计模式启动次数',
`eve_week_count` bigint COMMENT '当周16:00-20:00累计模式启动次数',
`oth_week_count` bigint COMMENT '当周其他时段累计模式启动次数',
`month_count` bigint COMMENT '当月启动次数',
`mor_month_count` bigint COMMENT '当月6:00-10:00累计模式启动次数',
`noo_month_count` bigint COMMENT '当月10:00-14:00累计模式启动次数',
`eve_month_count` bigint COMMENT '当月16:00-20:00累计模式启动次数',
`oth_month_count` bigint COMMENT '当月其他时段累计模式启动次数',
`quarter_count` bigint COMMENT '当季启动次数',
`mor_quarter_count` bigint COMMENT '当季6:00-10:00累计模式启动次数',
`noo_quarter_count` bigint COMMENT '当季10:00-14:00累计模式启动次数',
`eve_quarter_count` bigint COMMENT '当季16:00-20:00累计模式启动次数',
`oth_quarter_count` bigint COMMENT '当季其他时段累计模式启动次数',
`amount` bigint COMMENT '累计总启动次数',
`mor_amount` bigint COMMENT '累积6:00-10:00累计模式启动次数',
`noo_amount` bigint COMMENT '累积10:00-14:00累计模式启动次数',
`eve_amount` bigint COMMENT '累积16:00-20:00累计模式启动次数',
`oth_amount` bigint COMMENT '累积其他时段累计模式启动次数',
`is_weekend` string COMMENT 'Y表示当天是周末,N表示当天不是周末',
`is_monthend` string COMMENT 'Y表示当天是月末,N表示当天不是月末',
`is_quarterend` string COMMENT 'Y表示当天是季末,N表示当天不是季末'
) 
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/warehouse/device_model_log/ads/ads_q6_device_stovmode_count';

```

- 导入脚本

**dwt2ads_device_stovmode_count.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT INTO TABLE ads_q6_device_stovmode_count
SELECT 
  '${do_date}',
  daycount.st_ov_mode,
  daycount.mode_date_first,
  daycount.mode_date_last,
  daycount.day_count,
  daycount.mor_day_count,
  daycount.noo_day_count,
  daycount.eve_day_count,
  daycount.oth_day_count,
  wkcount.week_count,
  wkcount.mor_week_count,
  wkcount.noo_week_count,
  wkcount.eve_week_count,
  wkcount.oth_week_count,
  mncount.month_count,
  mncount.mor_month_count,
  mncount.noo_month_count,
  mncount.eve_month_count,
  mncount.oth_month_count,
  qtcount.quarter_count,
  qtcount.mor_quarter_count,
  qtcount.noo_quarter_count,
  qtcount.eve_quarter_count,
  qtcount.oth_quarter_count,
  daycount.amount,
  daycount.mor_amount,
  daycount.noo_amount,
  daycount.eve_amount,
  daycount.oth_amount,
  if(date_add(next_day('${do_date}','MO'),-1)='${do_date}','Y','N'),
  if(last_day('${do_date}')='${do_date}','Y','N'),
  if(last_day('${do_date}')='${do_date}' and substr('${do_date}',6,2) in (3,6,9,12),'Y','N')
FROM 
(
SELECT 
  st_ov_mode,
  mode_date_first,
  mode_date_last,
  mode_day_count day_count,
  mor_day_count,
  noo_day_count,
  eve_day_count,
  oth_day_count,
  mode_count amount,
  mor_count mor_amount,
  noo_count noo_amount,
  eve_count eve_amount,
  oth_count oth_amount
FROM dwt_q6_device_stovmode_topic
) daycount
JOIN 
(
SELECT 
  st_ov_mode,
  sum(mode_count) week_count,
  sum(mor_count) mor_week_count,
  sum(noo_count) noo_week_count,
  sum(eve_count) eve_week_count,
  sum(oth_count) oth_week_count
FROM dws_q6_device_stovmode_daycount
WHERE dt>=date_add(next_day('${do_date}','MO'),-7) 
GROUP BY st_ov_mode
) wkcount ON daycount.st_ov_mode=wkcount.st_ov_mode
JOIN 
(
SELECT 
  st_ov_mode,
  sum(mode_count) month_count,
  sum(mor_count) mor_month_count,
  sum(noo_count) noo_month_count,
  sum(eve_count) eve_month_count,
  sum(oth_count) oth_month_count
FROM dws_q6_device_stovmode_daycount
WHERE date_format(dt,'yyyy-MM')=date_format('${do_date}','yyyy-MM')
GROUP BY st_ov_mode
) mncount ON daycount.st_ov_mode=mncount.st_ov_mode
JOIN
(
SELECT 
  st_ov_mode,
  sum(mode_count) quarter_count,
  sum(mor_count) mor_quarter_count,
  sum(noo_count) noo_quarter_count,
  sum(eve_count) eve_quarter_count,
  sum(oth_count) oth_quarter_count
FROM dws_q6_device_stovmode_daycount
WHERE substr(dt,6,2) between ceil(substr('${do_date}',6,2)/3)*3-2 and ceil(substr('${do_date}',6,2)/3)*3 
GROUP BY st_ov_mode
) qtcount ON daycount.st_ov_mode=qtcount.st_ov_mode
"

$hive -e "$sql"

```

##### 4.2.1.4.2 用户维度

- 建表



- 导入脚本



#### 4.2.1.5 导出到mysql

```shell
#!/bin/bash

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

mysql_db_name=device_model_log
hive_dir_name=device_model_log

export_data() {
/opt/module/sqoop-1.4.6/bin/sqoop export \
--connect "jdbc:mysql://bigdata3:3306/${mysql_db_name}?useUnicode=true&characterEncoding=utf-8" \
--username root \
--password hxr \
--table $1 \
--num-mappers 1 \
--hive-partition-key dt \
--hive-partition-value $3 \
--export-dir /warehouse/${hive_dir_name}/ads/$2/dt=$3 \
--input-fields-terminated-by "	" \
--update-mode allowinsert \
--update-key $4 \
--input-null-string '\N' \
--input-null-non-string '\N'
}

export_data "ads_q6_device_stovmode_count" "ads_q6_device_stovmode_count" $do_date "date,product_key"


```







### 4.2.2 集成灶故障类型发生频率统计 errorcode

#### 4.2.2.1 dwd层

- 建表

**dwd_q6_errorcode_log**

```sql
DROP TABLE IF EXISTS dwd_q6_errorcode_log;
CREATE EXTERNAL TABLE dwd_q6_errorcode_log (
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`gmt_create` string,
`device_name` string,
`error_code` string,
`event_time` string
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwd/dwd_q6_errorcode_log'
TBLPROPERTIES('parquet.compression'='lzo');

```

- 导入脚本

**dwd2dwd_errorcode_log.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi
    
sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE ${APP}.dwd_q6_errorcode_log
partition(dt='${do_date}')
SELECT 
device_type,
iot_id,
request_id,
check_failed_data,
product_key,
gmt_create,
device_name,
event_code,
event_time
FROM ${APP}.dwd_q6_event_log LATERAL VIEW errorcode_analizer(event_value) tmp_errorcode AS event_code 
WHERE dt='${do_date}' AND event_name='ErrorCode';
"

$hive -e "$sql"

```



#### 4.2.2.2 dws层

##### 4.2.2.2.1 设备维度

###### 4.2.2.2.1.1 发生频率统计

- 建表

**dws_q6_device_errorcode_daycount**

```sql
DROP TABLE IF EXISTS dws_q6_device_errorcode_daycount;
create external table dws_q6_device_errorcode_daycount(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`error_code` string,
`error_count` string
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dws/dws_q6_device_errorcode_daycount';

```

- 导入脚本

**dwd2dws_device_errorcode_count.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE ${APP}.dws_q6_device_errorcode_daycount
partition(dt='${do_date}')
SELECT 
concat_ws('|',collect_set(device_type)) deviceType, 
concat_ws('|',collect_set(iot_id)) iotId,
concat_ws('|',collect_set(request_id)) requestId,
concat_ws('|',collect_set(check_failed_data)) checkFailedData,
concat_ws('|',collect_set(product_key)) productKey,
concat_ws('|',collect_set(device_name)) deviceName,
error_code,
count(*)
FROM ${APP}.dwd_q6_errorcode_log 
WHERE dt='${do_date}'
GROUP BY error_code;
"

$hive -e "$sql"

```



##### 4.2.2.2.2 用户维度

###### 4.2.2.2.1.1 发生频率统计

- 建表

**dws_q6_user_errorcode_daycount**

```sql
DROP TABLE IF EXISTS dws_q6_user_errorcode_daycount;
create external table dws_q6_user_errorcode_daycount(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`error_code` string,
`error_count` string
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dws/dws_q6_user_errorcode_daycount';

```

- 导入脚本
  **dwd2dws_user_errorcode_count.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE dws_q6_user_errorcode_daycount
PARTITION(dt='${do_date}')
SELECT 
concat_ws('|',collect_set(device_type)) deviceType, 
iot_id,
'' requestId,
'' checkFailedData,
concat_ws('|',collect_set(product_key)) productKey,
concat_ws('|',collect_set(device_name)) deviceName,
error_code,
count(*)
FROM ${APP}.dwd_q6_errorcode_log 
WHERE dt='${do_date}'
GROUP BY iot_id,error_code;
"

$hive -e "$sql"

```

#### 4.2.2.3 dwt层

##### 4.2.2.3.1 设备维度

###### 4.2.2.3.1.1 发生频率统计

- 建表

**dwt_q6_device_errorcode_topic**

```sql
DROP TABLE IF EXISTS dwt_q6_device_errorcode_topic;
CREATE EXTERNAL TABLE dwt_q6_device_errorcode_topic(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`error_code` string,
`error_date_first` string COMMENT '首次发生时间',
`error_date_last` string COMMENT '末次发生时间',
`error_day_count` bigint COMMENT '当日发生次数',
`error_count` bigint COMMENT '累积发生次数'
)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwt/dwt_q6_device_errorcode_topic';

```

- 导入脚本

**dws2dwt_device_errorcode_topic.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi
    
sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE dwt_q6_device_errorcode_topic
SELECT 
nvl(new.device_type,old.device_type),
nvl(new.iot_id,old.iot_id),
nvl(new.request_id,old.request_id),
nvl(new.check_failed_data,old.check_failed_data),
nvl(new.product_key,old.product_key),
nvl(new.device_name,old.device_name),
nvl(new.error_code,old.error_code),
if(old.error_date_first is null,'${do_date}',old.error_date_first),
if(new.error_code is null,old.error_date_first,'${do_date}'),
if(new.error_code is null,0,new.error_count),
nvl(new.error_count,0) + nvl(old.error_day_count,0)
FROM 
(
    SELECT * FROM dwt_q6_device_errorcode_topic
) old
full outer join
(
    SELECT * FROM dws_q6_device_errorcode_daycount WHERE dt='${do_date}'
) new
ON old.error_code=new.error_code
"

$hive -e "$sql"

```





##### 4.2.2.3.2 用户维度

###### 4.2.2.3.2.1 发生频率统计

- 建表
  **dwt_q6_user_errorcode_topic**

```sql
DROP TABLE IF EXISTS dwt_q6_user_errorcode_topic;
CREATE EXTERNAL TABLE dwt_q6_user_errorcode_topic(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`e1_count` bigint,
`e1_amount` bigint,
`e2_count` bigint,
`e2_amount` bigint,
`e3_count` bigint,
`e3_amount` bigint,
`e4_count` bigint,
`e4_amount` bigint,
`e5_count` bigint,
`e5_amount` bigint,
`e6_count` bigint,
`e6_amount` bigint,
`e7_count` bigint,
`e7_amount` bigint,
`e8_count` bigint,
`e8_amount` bigint,
`e9_count` bigint,
`e9_amount` bigint,
`e10_count` bigint,
`e10_amount` bigint,
`e11_count` bigint,
`e11_amount` bigint,
`e12_count` bigint,
`e12_amount` bigint,
`e13_count` bigint,
`e13_amount` bigint,
`e14_count` bigint,
`e14_amount` bigint
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwt/dwt_q6_user_errorcode_topic';

```

- 导入脚本
  **dws2dwt_user_errorcode_topic.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi
    
sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;

with
temp as
(
SELECT
  device_type,
  iot_id,
  request_id,
  check_failed_data,
  product_key,
  device_name,
  daytime_udf(val,1) e1,
  daytime_udf(val,2) e2,
  daytime_udf(val,4) e3,
  daytime_udf(val,8) e4,
  daytime_udf(val,16) e5,
  daytime_udf(val,32) e6,
  daytime_udf(val,64) e7,
  daytime_udf(val,128) e8,
  daytime_udf(val,256) e9,
  daytime_udf(val,512) e10,
  daytime_udf(val,1024) e11,
  daytime_udf(val,2048) e12,
  daytime_udf(val,4096) e13,
  daytime_udf(val,8192) e14
FROM 
  (
    SELECT 
      concat_ws('|',collect_set(device_type)) device_type,
      iot_id,
      '' request_id,
      '' check_failed_data,
      concat_ws('|',collect_set(product_key)) product_key,
      concat_ws('|',collect_set(device_name)) device_name, 
      concat_ws('|',collect_set(concat(error_code,'-',error_count))) val
    FROM dws_q6_user_errorcode_daycount
    WHERE dt='${do_date}'
    GROUP BY iot_id
  ) tmp

)

INSERT OVERWRITE TABLE dwt_q6_user_errorcode_topic
PARTITION(dt='${do_date}')
SELECT
  nvl(new.device_type,old.device_type) device_type,
  nvl(new.iot_id,old.iot_id) iot_id,
  nvl(new.request_id,old.request_id) request_id,
  nvl(new.check_failed_data,old.check_failed_data) check_failed_data,
  nvl(new.product_key,old.product_key) product_key,
  nvl(new.device_name,old.device_name) device_name,
  nvl(new.e1,0) e1_count,
  nvl(new.e1,0)+nvl(old.e1_amount,0) e1_amount,
  nvl(new.e2,0) e2_count,
  nvl(new.e2,0)+nvl(old.e2_amount,0) e2_amount,
  nvl(new.e3,0) e3_count,
  nvl(new.e3,0)+nvl(old.e3_amount,0) e3_amount,
  nvl(new.e4,0) e4_count,
  nvl(new.e4,0)+nvl(old.e4_amount,0) e4_amount,
  nvl(new.e5,0) e5_count,
  nvl(new.e5,0)+nvl(old.e5_amount,0) e5_amount,
  nvl(new.e6,0) e6_count,
  nvl(new.e6,0)+nvl(old.e6_amount,0) e6_amount,
  nvl(new.e7,0) e7_count,
  nvl(new.e7,0)+nvl(old.e7_amount,0) e7_amount,
  nvl(new.e8,0) e8_count,
  nvl(new.e8,0)+nvl(old.e8_amount,0) e8_amount,
  nvl(new.e9,0) e9_count,
  nvl(new.e9,0)+nvl(old.e9_amount,0) e9_amount,
  nvl(new.e10,0) e10_count,
  nvl(new.e10,0)+nvl(old.e10_amount,0) e10_amount,
  nvl(new.e11,0) e11_count,
  nvl(new.e11,0)+nvl(old.e11_amount,0) e11_amount,
  nvl(new.e12,0) e12_count,
  nvl(new.e12,0)+nvl(old.e12_amount,0) e12_amount,
  nvl(new.e13,0) e13_count,
  nvl(new.e13,0)+nvl(old.e13_amount,0) e13_amount,
  nvl(new.e14,0) e14_count,
  nvl(new.e14,0)+nvl(old.e14_amount,0) e14_amount
FROM 
(
  SELECT
    *
  FROM dwt_q6_user_errorcode_topic
  WHERE dt=date_sub('${do_date}',1)
) old
FULL OUTER JOIN
(
  SELECT
    *
  FROM temp
) new ON old.iot_id=new.iot_id;
"

$hive -e "$sql"
```
