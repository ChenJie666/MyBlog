---
title: 使用Maxwell监控MySQL的binlog文件
categories:
- 中间件
---
# 一、原理
## 1.1 Maxwell介绍
Maxwell是一个能实时读取MySQL二进制日志binlog，并生成 JSON 格式的消息，作为生产者发送给 Kafka，Kinesis、RabbitMQ、Redis、Google Cloud Pub/Sub、文件或其它平台的应用程序。它的常见应用场景有ETL、维护缓存、收集表级别的dml指标、增量到搜索引擎、数据分区迁移、切库binlog回滚方案等。

- 支持 SELECT * FROM table 的方式进行全量数据初始化；
- 支持在主库发生failover后，自动恢复binlog位置(GTID)；
- 可以对数据进行分区，解决数据倾斜问题，发送到kafka的数据支持database、table、column等级别的数据分区；
- 工作方式是伪装为Slave，接收binlog events，然后根据schemas信息拼装，可以接受ddl、xid、row等各种event。

## 1.2 对比Canal
- Maxwell没有canal那种server+client模式，只有一个server把数据发送到消息队列或redis。如果需要多个实例，通过指定不同配置文件启动多个进程。
- Maxwell有一个亮点功能，就是canal只能抓取最新数据，对已存在的历史数据没有办法处理。而Maxwell有一个bootstrap功能，可以直接引导出完整的历史数据用于初始化，非常好用。
- Maxwell不能直接支持HA，但是它支持断点还原，即错误解决后重启继续上次点儿读取数据。
- Maxwell只支持json格式，而Canal如果用Server+client模式的话，可以自定义格式。
- Maxwell比Canal更加轻量级。

## 1.3 流程图
可以通过Maxwell实现MySQL与Elasticsearch的数据同步。
![image.png](使用Maxwell监控MySQL的binlog文件.assets\554f96acc8e54cd58d61ff32eedadfc3.png)


<br>
# 二、实现
####① **vi my.cnf**    修改mysql的配置文件
```
[mysqld]
server_id=1
log-bin=master
binlog_format=row

gtid-mode=on
enforce-gtid-consistency=1 # 设置为主从强一致性
log-slave-updates=1 # 记录日志
```
####② **设置权限**
```
mysql> CREATE USER 'maxwell'@'%' IDENTIFIED BY 'XXXXXX';
mysql> GRANT ALL ON maxwell.* TO 'maxwell'@'%';
mysql> GRANT SELECT, REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO 'maxwell'@'%';
```
####③ **启动Maxwell并与RabbitMQ关联**
**方式一：通过在docker命令中指定属性的值关联RabbitMQ**
```
docker run -it --rm zendesk/maxwell bin/maxwell --user='maxwell' --password='hxr' --host='mysql.hostname'   --producer=rabbitmq --rabbitmq_host='rabbitmq.hostname'
```
备注：测试时，可以通过在控制台打印的方式查看配置是否正确。
```
docker run -it --rm zendesk/maxwell bin/maxwell --user='maxwell' --password='hxr' --host='mysql.hostname' --producer=stdout
```
**方式二：通过配置文件启动,配置文件名称为config.properties**
```
docker  run  -it  -d  -p  6111:6111 -v  /root/maxwell/config.properties:/app/config.properties -n  maxwell zendesk/maxwell  bin/maxwell
```
**config.properties配置文件如下**
```
# tl;dr config 生产环境配置为info级别
log_level=DEBUG
producer=rabbitmq
# mysql login info, mysql用户必须拥有读取binlog权限和新建库表的权限
host=192.168.32.225
user=maxwell
password=hxr
output_nulls=true
# options to pass into the jdbc connection, given as opt=val&opt2=val2
#jdbc_options=opt1=100&opt2=hello
jdbc_options=autoReconnet=true
#需要同步的数据库，表，及不包含的字段
#filter=exclude: *.*, include: foo.*, include: bar.baz
filter=exclude: *.*, include: dev_smartcook.menu.publish_status=2
#replica_server_id 和 client_id 唯一标示，用于集群部署
replica_server_id=64
client_id=maxwell_dev
metrics_type=http
metrics_slf4j_interval=60
http_port=8111
http_diagnostic=true # default false
#rabbitmq
rabbitmq_host=116.62.148.11
rabbitmq_port=5672
rabbitmq_user=guest
rabbitmq_pass=guest
rabbitmq_virtual_host=/vhost_mmr
rabbitmq_exchange=maxwell
rabbitmq_exchange_type=topic
rabbitmq_exchange_durable=false
rabbitmq_exchange_autodelete=false
rabbitmq_routing_key_template=dev_smartcook.menu
rabbitmq_message_persistent=false
rabbitmq_declare_exchange=true

# 仅匹配foodb数据库的tbl表和所有table_数字的表
--filter='exclude: foodb.*, include: foodb.tbl, include: foodb./table_\d+/'
# 排除所有库所有表，仅匹配db1数据库
--filter = 'exclude: *.*, include: db1.*'
# 排除含db.tbl.col列值为reject的所有更新
--filter = 'exclude: db.tbl.col = reject'
# 排除任何包含col_a列的更新
--filter = 'exclude: *.*.col_a = *'
# blacklist 黑名单，完全排除bad_db数据库，若要恢复，必须删除maxwell库
--filter = 'blacklist: bad_db.*'
```

<br>
#### 也可以通过Kafka来接收Maxwell的消息：
```
docker run -p 8080:8080 -it --rm zendesk/maxwell bin/maxwell --user='maxwell'  --password='123456' --host='10.100.97.246' --producer=kafka  --kafka.bootstrap.servers='10.100.97.246:9092' --kafka_topic=maxwell --log_level=debug  --metrics_type=http --metrics_jvm=true --http_port=8080
```
配置了通过http方式发布指标，启用收集JVM信息，端口为8080，之后可以通过 http://10.100.97.246:8080/metrics 便可获取所有的指标，http 方式有四种后缀，分别对应四种不同的格式：

>**endpoint 说明：**
> /metrics 所有指标以JSON格式返回
> /prometheus 所有指标以Prometheus格式返回（Prometheus是一套开源的监控&报警&时间序列数据库的组合）
> /healthcheck 返回Maxwell过去15分钟是否健康
> /ping 简单的测试，返回 pong

<br>
# 三、参考
[maxwell官网地址 http://maxwells-daemon.io/](http://maxwells-daemon.io/)
[Github官方地址  https://github.com/zendesk/maxwell](https://github.com/zendesk/maxwell)

<!--
<br>
# docker部署的mysql

分为5步：安装MySQL，配置binlog，创建maxwell用户，安装运行maxwell，测试maxwell工作是否正常。

##安装MySQL

使用如下命令，即可拉取MySQL 5.7的镜像，并指定密码123456，且运行：

>docker run --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=123456 -d    mysql:5.7

##配置binlog

编辑一个my.cnf文件，开启binlog，指定的server-id不能为0，必须是唯一的
```
>[mysqld]
server_id=1
log-bin=master
binlog_format=row

gtid-mode=on
enforce-gtid-consistency=1 # 设置为主从强一致性
log-slave-updates=1 # 记录日志
```

使用docker cp my.cnf mysql:/etc/复制到容器内，然后运行docker restart mysql。

##使用如下命令检查binlog配置：

show variables like 'log_bin';

![image.png](https://upload-images.jianshu.io/upload_images/21580557-db3554adc099d037.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

show variables like 'binlog_format';

![image.png](https://upload-images.jianshu.io/upload_images/21580557-4a0637421d691369.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

##创建maxwell角色

执行如下命令，不能省掉任何一步。

>CREATE USER 'maxwell'@'%' IDENTIFIED BY '123456';
>GRANT ALL ON maxwell.* TO 'maxwell'@'%';
>GRANT SELECT, REPLICATION CLIENT, REPLICATION SLAVE on *.* to 'maxwell'@'%';
>flush privileges;

##安装运行maxwell

使用如下命令拉取maxwell镜像并且安装（ip地址替换成自己MySQL的地址）：

>docker run -ti --rm zendesk/maxwell bin/maxwell --user='maxwell' --password='123456' --host='10.250.115.210' --producer=stdout

##测试maxwell

选择一个非maxwell的数据库，比如test。创建如下表：

>create table `user`(
  id int(11) not null auto_increment primary key,
  age int(11)
);

执行如下sql，并且观察maxwell在控制台是否有输出：

>insert into user values (null, 11);
update user set age = 12 where id=1;
delete from user where id = 1;

控制台能观察到3行json，分别对应增、改、删。
-->
