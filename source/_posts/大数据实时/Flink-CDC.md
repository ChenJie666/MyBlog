---
title: Flink-CDC
categories:
- 大数据实时
---
# 一、Flink CDC简介
## 1.1 什么是CDC
CDC是Change Data Capture(变更数据获取)的简称。核心思想是，监测并捕获数据库的变动（包括数据或数据表的插入、更新以及删除等），将这些变更按发生的顺序完整记录下来，写入到消息中间件中以供其他服务进行订阅及消费。

## 1.2 CDC的种类
CDC主要分为基于查询和基于Binlog两种方式，我们主要了解一下这两种之间的区别：
|	| 基于查询的CDC	| 基于Binlog的CDC |
| --- | --- | --- |
| 开源产品	| Sqoop、Kafka JDBC Source	| Canal、Maxwell、Debezium |
| 执行模式	| Batch	| Streaming |
| 是否可以捕获所有数据变化	| 否	| 是 |
| 延迟性	| 高延迟	| 低延迟 |
| 是否增加数据库压力	| 是	| 否 |

## 1.3 Flink-CDC
Flink社区开发了 flink-cdc-connectors 组件，这是一个可以直接从 MySQL、PostgreSQL 等数据库直接读取全量数据和增量变更数据的 source 组件，基于Debezium框架实现binlog监控。目前也已开源，开源地址：https://github.com/ververica/flink-cdc-connectors。

**支持的数据库**
| Database | Version | Flink Version |
| --- | --- | --- |
| MySQL | Database: 5.7, 8.0.x  JDBC <br>  Driver: 8.0.16 | 1.11+ |
| PostgreSQL | Database: 9.6, 10, 11, 12 <br> JDBC Driver: 42.2.12 | 1.11+ |
| MongoDB | Database: 3.6, 4.x, 5.0 <br> MongoDB Driver: 4.3.1 |  |
| Oracle | Database: 11, 12, 19 <br> Oracle Driver: 19.3.0.0 |  |
| Sqlserver | Database: 2017, 2019 <br> JDBC Driver: 7.2.2.jre8 |  |

**Supported Flink Versions**
The version mapping between Flink CDC Connectors and Flink.
| Flink CDC Connector Version | Flink Version |
| --- | --- |
| 1.0.0 | 1.11.* |
| 1.1.0 | 1.11.* |
| 1.2.0 | 1.12.* |
| 1.3.0 | 1.12.* |
| 1.4.0 | 1.13.* |
| 2.0.* | 1.13.* |
| 2.1.* | 1.13.* |


<br>
# 二、  FlinkCDC案例实操
## 2.1 DataStream方式的应用
### 2.1.1 导入依赖
```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>org.example</groupId>
    <artifactId>flink-cdc</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <flink-version>1.12.0</flink-version>
        <hadoop-version>3.1.3</hadoop-version>
        <flink-cdc-version>1.2.0</flink-cdc-version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-java</artifactId>
            <version>${flink-version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-streaming-java_2.12</artifactId>
            <version>${flink-version}</version>
            <exclusions>
                <exclusion>
                    <artifactId>slf4j-api</artifactId>
                    <groupId>org.slf4j</groupId>
                </exclusion>
            </exclusions>
        </dependency>
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-clients_2.12</artifactId>
            <version>${flink-version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-client</artifactId>
            <version>${hadoop-version}</version>
            <exclusions>
                <exclusion>
                    <groupId>log4j</groupId>
                    <artifactId>log4j</artifactId>
                </exclusion>
                <exclusion>
                    <groupId>org.slf4j</groupId>
                    <artifactId>slf4j-api</artifactId>
                </exclusion>
            </exclusions>
        </dependency>

        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>5.1.48</version>
        </dependency>

        <dependency>
            <groupId>com.alibaba.ververica</groupId>
            <artifactId>flink-connector-mysql-cdc</artifactId>
            <version>${flink-cdc-version}</version>
        </dependency>

        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>fastjson</artifactId>
            <version>1.2.76</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-assembly-plugin</artifactId>
                <version>3.3.0</version>
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

### 2.1.2 编写代码
```
import com.alibaba.ververica.cdc.connectors.mysql.MySQLSource;
import com.alibaba.ververica.cdc.connectors.mysql.table.StartupOptions;
import com.alibaba.ververica.cdc.debezium.DebeziumSourceFunction;
import com.alibaba.ververica.cdc.debezium.StringDebeziumDeserializationSchema;
import org.apache.flink.api.common.restartstrategy.RestartStrategies;
import org.apache.flink.runtime.state.filesystem.FsStateBackend;
import org.apache.flink.streaming.api.CheckpointingMode;
import org.apache.flink.streaming.api.datastream.DataStreamSource;
import org.apache.flink.streaming.api.environment.CheckpointConfig;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.security.SecurityUtil;
import org.apache.hadoop.security.UserGroupInformation;

public class FlinkCDC {

    public static void main(String[] args) throws Exception {
        // 0. 完成kerberos认证配置

        System.setProperty("java.security.krb5.conf", "/etc/krb5.conf");
//        System.setProperty("java.security.krb5.conf", "C:/Users/CJ/Desktop/krb5.conf");
//        System.setProperty("hadoop.home.dir", "D:/hadoop-3.0.0");

        Configuration configuration = new Configuration();
        configuration.set("hadoop.security.authentication", "kerberos");
//        configuration.set("dfs.data.transfer.protection", "authentication");
//        configuration.set("dfs.namenode.kerberos.principal", "nn/_HOST@IOTMARS.COM");

        UserGroupInformation.setConfiguration(configuration);
        UserGroupInformation.loginUserFromKeytab("flink/cos-bigdata-test-hadoop-03", "/etc/security/keytab/flink.service.keytab");
//        UserGroupInformation.loginUserFromKeytab("flink/cos-bigdata-test-hadoop-03", "C:/Users/CJ/Desktop/flink.service.keytab");

        SecurityUtil.setConfiguration(configuration);

        // 1. 创建执行环境
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(1);

        // 2. Flink-CDC将读取binlog的位置信息以状态的方式保存在CK，如果想要做到断点续传，需要从Checkpoint或者Savepoint启动程序
        // 2.1 开启checkpoint，间隔时间为5s
        env.enableCheckpointing(10000L);
        // 2.2 设置checkpoint的超时时间为10s，允许同时存在checkpoint任务的个数为2，最小间隔时间为3s(配置了这个值，就不会同时存在两个checkpoint)
        env.getCheckpointConfig().setCheckpointTimeout(20000L);
        env.getCheckpointConfig().setMaxConcurrentCheckpoints(2);
        env.getCheckpointConfig().setMinPauseBetweenCheckpoints(3000L);
        // 2.2 指定ck的一致性语义
        env.getCheckpointConfig().setCheckpointingMode(CheckpointingMode.EXACTLY_ONCE);
        // 2.3 设置任务关闭后的时候保留最后一次ck数据
        env.getCheckpointConfig().enableExternalizedCheckpoints(CheckpointConfig.ExternalizedCheckpointCleanup.RETAIN_ON_CANCELLATION);
        // 2.4 指定从ck自动重启策略
        env.setRestartStrategy(RestartStrategies.fixedDelayRestart(3,2000L));
        // 2.5 设置状态后端
        env.setStateBackend(new FsStateBackend("hdfs://192.168.101.184:9820/flink/checkpoint"));
        // 2.6 设置访问HDFS的用户名
//        System.setProperty("HADOOP_USER_NAME", "chenjie");

        // 3. 创建Flink-MySQL-CDC的Source
        DebeziumSourceFunction<String> mysqlSource = MySQLSource
                .<String>builder()
                .hostname("192.168.32.244")
                .port(3306)
                .username("root")
                .password("hxr")
                .databaseList("flink-cdc-test")
                .tableList("flink-cdc-test.brand")
                .deserializer(new StringDebeziumDeserializationSchema())
                .startupOptions(StartupOptions.initial())
                .build();

        // 4. 使用CDC Source从MySQL读取数据
        DataStreamSource<String> mysqlDS = env.addSource(mysqlSource);

        // 5. 打印数据
        mysqlDS.print();

        // 6. 执行任务
        env.execute("FlinkCDC");

    }

}
```
>**startupOptions中指定读取模式：**
>initial：启动任务时会对监控的数据库表原始数据做一个快照(CDC2.0之前会对库表加锁直到快照完成)，完成后从最新的binlog文件位置开始监控；
>earliest：读取完整的binlog文件，需要注意在建库表前开启binlog；
>lastest：从最新的binlog文件位置开始监控；
>specificOffset：指定binlog的offset位置开始读取；
>timestamp：从指定时间戳开始的binlog记录开始读取


### 2.1.3 案例测试
1）开启binlog
修改mysql的配置文件/etc/my.cnf
```
server-id = 1
log-bin=mysql-bin
binlog_format=row
binlog-do-db=[database_name]
```
>对于Docker部署的mysql同样适用，建议创建容器时将binlog文件所在目录/var/lib/mysql挂载到宿主机上，避免丢失。
2）创建库表
3）项目打包并上传至Linux
4）启动Flink任务
这里使用Per-Job-Cluster模式
```
bin/flink run -m yarn-cluster -p 1 -yjm 1024 -ytm 1024m -d -c com.cj.cdc.FlinkCDC -yqu default /opt/jar/flink-cdc-1.0-SNAPSHOT-jar-with-dependencies.jar
```
5）在MySQL的表中增删改数据，在Flink UI中查看taskmanager的stdout
8）给当前Flink程序创建savepoint
```
bin/flink savepoint 6b914bb899ee301383a14aec06214ab1 hdfs://192.168.101.184:9820/flink/savepoint
```
9）关闭程序后从Savepoint重启程序
```
bin/flink run -m yarn-cluster -s hdfs://192.168.101.184:9820/flink/flinkCDC/savepoint-136e8b327b393a0173eef6e09e1bde66 -p 1 -ys 2 -yjm 1024 -ytm 1024m -d -c com.cj.cdc.FlinkCDC -yqu default /opt/jar/flink-cdc-1.0-SNAPSHOT-jar-with-dependencies.jar
```

从Checkpoint重启程序
```
bin/flink run -m yarn-cluster -s hdfs://192.168.101.184:9820/flink/flinkCDC/136e8b327b393a0173eef6e09e1bde66/chk-5050/_metadata -p 1 -ys 2 -yjm 1024 -ytm 1024m -d -c com.cj.cdc.FlinkCDC -yqu default /opt/jar/flink-cdc-1.0-SNAPSHOT-jar-with-dependencies.jar
```
>-s ：指定savepoint或checkpoint所在路径

### 2.1.4 序列化器
在上述代码中直接使用StringDebeziumDeserializationSchema进行序列化，但是打印的结果不是很清晰，所以我们可以自定义序列化器，打印我们需要的结果。
```
import com.alibaba.fastjson.JSONObject;
import com.alibaba.ververica.cdc.debezium.DebeziumDeserializationSchema;
import io.debezium.data.Envelope;
import org.apache.flink.api.common.typeinfo.BasicTypeInfo;
import org.apache.flink.api.common.typeinfo.TypeInformation;
import org.apache.flink.util.Collector;
import org.apache.kafka.connect.data.Field;
import org.apache.kafka.connect.data.Struct;
import org.apache.kafka.connect.source.SourceRecord;

import java.util.Objects;

public class CustomDebeziumDeserializationSchema implements DebeziumDeserializationSchema<String> {
    /**
     * 返回格式自定义如下
     * {
     *     "database":"",
     *     "tablename":"",
     *     "operation":"",
     *     "before":"",
     *     "after":"",
     *     "ts":""
     * }
     * @param sourceRecord
     * @param collector
     * @throws Exception
     */
    @Override
    public void deserialize(SourceRecord sourceRecord, Collector<String> collector) throws Exception {
        JSONObject result = new JSONObject();

        // 1. 获取库表名
        String topic = sourceRecord.topic();
        String[] split = topic.split("\.");
        String database = split[1];
        String tablename = split[2];

        result.put("database", database);
        result.put("tablename", tablename);

        // 2. 获取操作类型
        Envelope.Operation operation = Envelope.operationFor(sourceRecord);
        result.put("operation", operation.code());

        // 3. 获取变化前后的数据
        Struct value = (Struct) sourceRecord.value();
        Struct before = value.getStruct("before");
        Struct after = value.getStruct("after");

        if(!Objects.isNull(before)) {
            JSONObject beforeEntries = new JSONObject();
            for (Field field : before.schema().fields()) {
                beforeEntries.put(field.name(), before.get(field));
            }
            result.put("before", beforeEntries);
        }
        if(!Objects.isNull(after)) {
            JSONObject afterEntries = new JSONObject();
            for (Field field : after.schema().fields()) {
                afterEntries.put(field.name(), after.get(field));
            }
            result.put("after", afterEntries);
        }

        // 4. 获取时间戳
        Long ts = value.getInt64("ts_ms");
        result.put("ts", ts);

        collector.collect(result.toString());
    }

    @Override
    public TypeInformation<String> getProducedType() {
        return BasicTypeInfo.STRING_TYPE_INFO;
    }
}
```

<br>
## 2.2 Flink SQL方式的应用
### 2.2.1 导入依赖
```
        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-table-planner-blink_2.12</artifactId>
            <version>${flink-version}</version>
            <exclusions>
                <exclusion>
                    <artifactId>slf4j-api</artifactId>
                    <groupId>org.slf4j</groupId>
                </exclusion>
            </exclusions>
        </dependency>

        <dependency>
            <groupId>org.apache.flink</groupId>
            <artifactId>flink-clients_2.12</artifactId>
            <version>${flink-version}</version>
            <exclusions>
                <exclusion>
                    <artifactId>slf4j-api</artifactId>
                    <groupId>org.slf4j</groupId>
                </exclusion>
            </exclusions>
        </dependency>

        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-client</artifactId>
            <version>${hadoop-version}</version>
        </dependency>

        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>5.1.48</version>
        </dependency>

        <dependency>
            <groupId>com.alibaba.ververica</groupId>
            <artifactId>flink-connector-mysql-cdc</artifactId>
            <version>${flink-cdc-version}</version>
        </dependency>
```

### 2.2.2 编写代码
```
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.Table;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;
import org.apache.flink.types.Row;

public class FlinkSQL_CDC {
    public static void main(String[] args) throws Exception {
        // 1. 创建执行环境
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(1);
        StreamTableEnvironment tableEnv = StreamTableEnvironment.create(env);

        // 2. DDL方式建表 (不同于CDC数据流方式，SQL方式不能一次性监控多库表，每次只能监控一张表)
        tableEnv.executeSql("create table cdc_binlog (" +
                "id int not null," +
                "brand string" +
                ") with (" +
                "'connector' = 'mysql-cdc'," +
                "'hostname' = '192.168.32.244'," +
                "'port' = '3306'," +
                "'username' = 'root'," +
                "'password' = 'hxr'," +
                "'database-name' = 'flink-cdc-test'," +
                "'table-name' = 'brand'" +
                ")");

        // 3. 查询数据
        Table table = tableEnv.sqlQuery("select * from cdc_binlog");

        // 4. 将动态表装换位流
        DataStream<Tuple2<Boolean, Row>> tuple2DataStream = tableEnv.toRetractStream(table, Row.class);
        tuple2DataStream.print();

        // 5. 启动任务
        env.execute("FlinkCDCWithSQL");
    }
}
```
