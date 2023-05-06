---
title: Kafka
categories:
- 大数据离线
---
# 一、Kafka命令
## 1.1 启动命令
启动和关闭节点上的kafka服务，-daemon表示在后台启动
```
bin/kafka-server-start.sh -daemon config/server.properties
```
```
bin/kafka-server-stop.sh
```
>指定zookeeper，因为需要先在zk上创建节点，kafka controller监控目录下有新文件，会创建新的topic，进行分区和副本均衡，选举leader然后将信息发送到zk中，同时每个broker都会缓存在metadatacache文件中，即zk和每台服务器上都有topic元数据。

<br>
## 1.2 常用命令
- 查看所有的topic
  ```
  bin/kafka-topics.sh  --zookeeper bigdata1:2181  --list   
  ```

- 创建一个名为first，分区数为3，副本数为2的topic
  ```
  bin/kafka-topics.sh  --zookeeper bigdata1:2181  --create --topic first  --partitions 3  --replication-factor 2 
  ```

- 查看名为first的topic的具体参数
  ```
  bin/kafka-topics.sh  --zookeeper bigdata1:2181  --describe  --topic first 
  ```
  分别表示topic名、分区号、该分区leader所在的brokerid、副本号、副本所在brokerid、可以同步的副本所在的brokerid
  ![image.png](Kafka.assets