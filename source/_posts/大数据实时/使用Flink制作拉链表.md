---
title: 使用Flink制作拉链表
categories:
- 大数据实时
---
一、## 使用Table API 的尝试(失败)
### 方案1：
说明：使用Flink Connector中的JDBC来读取MySQL中的数据，通过日志数据与拉链表中数据进行join，然后更新到表中；
问题：最后Insert 到原表中时，发现mysql可以进行正常更新，但是并没有更新到Flink的动态表中，导致输出结果错误；
原因：Table API中的动态表不同于状态后端，不能在程序末尾更新程序开头定义的动态表；
并且sql不能自主管理状态后端中数据的过期时间，担心内存溢出导致程序崩溃。

### 方案2：
说明：使用Flink-CDC中的mysql-cdc来监控MySQL的binlog文件，实时获取变化数据；这样就可以解决方案1中Flink中动态表不更新的问题；
问题：在插入数据并产出到MySQL时的数据时正确的，但是因为MySQL中的数据发生了变化，Flink监控到后重新触发了计算，并改写了MySQL中的记录导致结果出错；
原因：Flink-CDC是一张动态表而不是状态后端，其发生变化会触发计算导致失败。


```
package com.iotmars.compass;

import com.alibaba.fastjson.JSONObject;
import org.apache.flink.api.common.eventtime.SerializableTimestampAssigner;
import org.apache.flink.api.common.eventtime.WatermarkStrategy;
import org.apache.flink.api.common.restartstrategy.RestartStrategies;
import org.apache.flink.api.common.time.Time;
import org.apache.flink.contrib.streaming.state.EmbeddedRocksDBStateBackend;
import org.apache.flink.streaming.api.CheckpointingMode;
import org.apache.flink.streaming.api.datastream.SingleOutputStreamOperator;
import org.apache.flink.streaming.api.environment.CheckpointConfig;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.Table;
import org.apache.flink.table.api.TableConfig;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;

import java.time.Duration;

/**
 * 1.读取所有的end_date为9999-12-31的记录为动态表，join设备状态动态表(水位线延迟30s，60s自动推进水位线).
 * 2.将原状态数据和新状态数据更新到ads_device_feiyan_error_status中.
 *
 * @author CJ
 * @date: 2023/2/14 10:20
 */
public class DeviceErrorStatusAppTest {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        env.setParallelism(1);

        // 设置checkpoint
        env.enableCheckpointing(60 * 1000, CheckpointingMode.EXACTLY_ONCE);
        env.getCheckpointConfig().setCheckpointTimeout(90 * 1000);
        env.getCheckpointConfig().setMaxConcurrentCheckpoints(1);
        env.getCheckpointConfig().setMinPauseBetweenCheckpoints(3000L);
        env.getCheckpointConfig().enableExternalizedCheckpoints(
                CheckpointConfig.ExternalizedCheckpointCleanup.RETAIN_ON_CANCELLATION
        );
        env.setRestartStrategy(RestartStrategies.failureRateRestart(
                3, Time.days(1L), Time.minutes(1L)
        ));

        // 设置StateBackend
        env.setStateBackend(new EmbeddedRocksDBStateBackend());

        System.setProperty("HADOOP_USER_NAME", "root");
        env.getCheckpointConfig().setCheckpointStorage("hdfs://192.168.101.193:8020/flink/checkpoint/device_feiyan_error_status");

        StreamTableEnvironment tableEnv = StreamTableEnvironment.create(env);
        TableConfig config = tableEnv.getConfig();

        config.getConfiguration().setString("parallelism.default", "3");
//        config.getConfiguration().setString("table.exec.state.ttl", String.valueOf(24 * 60 * 60 * 1000)); // 如果state状态24小时不变，则回收。需要根据后面的逻辑调整。
        config.getConfiguration().setString("table.exec.source.idle-timeout", String.valueOf(30 * 1000)); // 源在超时时间3000ms内未收到任何元素时，它将被标记为暂时空闲。这允许下游任务推进其水印.


        tableEnv.executeSql("CREATE TABLE cdc_device_feiyan_error_status_zip (
" +
                "                product_key STRING,
" +
                "                iot_id STRING,
" +
                "                device_name STRING,
" +
                "                error_code STRING,
" +
                "                start_date STRING,
" +
                "                end_date STRING,
" +
                "                PRIMARY KEY (product_key,iot_id,device_name,end_date) NOT ENFORCED
" +
                "        ) WITH (
" +
                "            'connector' = 'mysql-cdc',
" +
                "            'hostname' = 'iotmars-rds-wlan.mysql.rds.aliyuncs.com',
" +
                "            'port' = '3306',
" +
                "            'username' = 'compass',
" +
                "            'password' = 'compass@123',
" +
                "            'database-name' = 'compass_test',
" +
                "            'table-name' = 'device_feiyan_error_status_zip'" +
                "        )");

        SingleOutputStreamOperator<LogOv> dataStream = env.socketTextStream("192.168.32.242", 7779)
                .map(log -> {
                    LogOv logJson = JSONObject.parseObject(log, LogOv.class);
                    System.out.println(logJson);
                    return logJson;
                });
        SingleOutputStreamOperator<LogOv> logStream = dataStream.assignTimestampsAndWatermarks(WatermarkStrategy.<LogOv>forBoundedOutOfOrderness(Duration.ofSeconds(30L))
                .withTimestampAssigner(new SerializableTimestampAssigner<LogOv>() {
                    @Override
                    public long extractTimestamp(LogOv element, long recordTimestamp) {
                        return element.getGmtCreate();
                    }
                }));

        Table table = tableEnv.fromDataStream(logStream);
        tableEnv.createTemporaryView("dwd_device_feiyan_log_event", table);

        // 解析设备异常，然后输出到数据库中
        tableEnv.executeSql("CREATE VIEW tmp AS (SELECT 
" +
                "    new_status.productKey as new_product_key,
" +
                "    new_status.iotId as new_iot_id,
" +
                "    new_status.deviceName as new_device_name,
" +
                "    new_status.eventValue as new_error_code,
" +
                "    new_status.start_date as new_start_date,
" +
                "    new_status.end_date as new_end_date,
" +
                "    old_status.product_key as old_product_key,
" +
                "    old_status.iot_id as old_iot_id,
" +
                "    old_status.device_name as old_device_name,
" +
                "    old_status.error_code as old_error_code,
" +
                "    old_status.start_date as old_start_date,
" +
                "    old_status.end_date as old_end_date
" +
                "FROM (
" +
                "    SELECT *, FROM_UNIXTIME(gmtCreate/1000, 'yyyy-MM-dd') as start_date, '9999-12-31' as end_date 
" +
                "    FROM dwd_device_feiyan_log_event 
" +
                "    WHERE eventName = 'ErrorCode'
" +
                "    ) new_status 
" +
                "    LEFT JOIN
" +
                "    (
" +
                "    SELECT * 
" +
                "    FROM cdc_device_feiyan_error_status_zip 
" +
                "    WHERE end_date='9999-12-31'
" +
                "    ) old_status
" +
                "    ON new_status.productKey = old_status.product_key " +
//                "       and new_status.eventValue <> old_status.error_code" +
                ")");

        tableEnv.toChangelogStream(tableEnv.sqlQuery("select * from tmp")).print("tmp   ");

        // sink
        tableEnv.executeSql("CREATE TABLE sink_device_feiyan_error_status_zip (
" +
                "                product_key STRING,
" +
                "                iot_id STRING,
" +
                "                device_name STRING,
" +
                "                error_code STRING,
" +
                "                start_date STRING,
" +
                "                end_date STRING,
" +
                "                PRIMARY KEY (product_key,iot_id,device_name,end_date) NOT ENFORCED
" +
                "        ) WITH (
" +
                "                'connector' = 'jdbc',
" +
                "                'url' = 'jdbc:mysql://iotmars-rds-wlan.mysql.rds.aliyuncs.com:3306/compass_test',
" +
                "                'table-name' = 'device_feiyan_error_status_zip',
" +
                "                'username' = 'compass',
" +
                "                'password' = 'compass@123'
" +
                "        )");

        tableEnv.executeSql("INSERT INTO sink_device_feiyan_error_status_zip" +
                " SELECT 
" +
                "    IF(new_product_key IS NOT NULL,new_product_key,old_product_key),
" +
                "    IF(new_iot_id IS NOT NULL,new_iot_id,old_iot_id),
" +
                "    IF(new_device_name IS NOT NULL,new_device_name,old_device_name),
" +
                "    IF(new_error_code IS NOT NULL,new_error_code,old_error_code),
" +
                "    IF(new_start_date IS NOT NULL,new_start_date,old_start_date) as start_date,
" +
                "    IF(new_end_date IS NOT NULL,new_end_date,old_end_date) as end_date
" +
                "FROM tmp
" +
                "UNION ALL
" +
                "SELECT 
" +
                "    old_product_key,
" +
                "    old_iot_id,
" +
                "    old_device_name,
" +
                "    old_error_code,
" +
                "    old_start_date as start_date,
" +
//                "    FROM_UNIXTIME(1676648068495/1000, 'yyyy-MM-dd') as end_date
" +
                "    new_start_date as end_date
" +
                "FROM tmp
" +
                "WHERE new_device_name is not null 
" +
                "    and old_device_name is not null");

    }
}
```
创建MySQL表并插入数据
|product_key|iot_id|device_name|error_code|start_date|end_date|
|--|--|--|--|--|--|
|a	|a	|a	|ErrorCode:1	|2023-02-01	|2023-02-16|
|a	|a	|a	|ErrorCode:2	|2023-02-16	|9999-12-31|

准备三条日志数据
```
{"deviceType":"a","iotId":"a","requestId":"a","checkFailedData":"{}","productKey":"a","gmtCreate":1676648668495,"deviceName":"a","eventName":"ErrorCode","eventValue":"ErrorCode:4","eventOriValue":"ErrorCode:3"}
{"deviceType":"a","iotId":"a","requestId":"a","checkFailedData":"{}","productKey":"a","gmtCreate":1676649668495,"deviceName":"a","eventName":"ErrorCode","eventValue":"ErrorCode:5","eventOriValue":"ErrorCode:4"}
{"deviceType":"a","iotId":"a","requestId":"a","checkFailedData":"{}","productKey":"a","gmtCreate":1676874269000,"deviceName":"a","eventName":"ErrorCode","eventValue":"ErrorCode:6","eventOriValue":"ErrorCode:5"}
```
当插入第一条日志时，MySQL中的结果最开始是正确的
|product_key|iot_id|device_name|error_code|start_date|end_date|
|--|--|--|--|--|--|
|a	|a	|a	|ErrorCode:1	|2023-02-01	|2023-02-16|
|a	|a	|a	|ErrorCode:2	|2023-02-16	|2023-02-17|
|a	|a	|a	|ErrorCode:4	|2023-02-17	|9999-12-31|
但是MySQL中的变化会被Flink监控到，触发计算改写了结果导致结果出错
|product_key|iot_id|device_name|error_code|start_date|end_date|
|--|--|--|--|--|--|
|a	|a	|a	|ErrorCode:1	|2023-02-01	|2023-02-16|
|a	|a	|a	|ErrorCode:4	|2023-02-17	|2023-02-17|
|a	|a	|a	|ErrorCode:4	|2023-02-17	|9999-12-31|


<br>
<br>
## 二、使用Stream API
