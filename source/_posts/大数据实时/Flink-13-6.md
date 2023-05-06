---
title: Flink-13-6
categories:
- 大数据实时
---
**Flink 区别与传统数据处理框架的特性如下**
⚫ 高吞吐和低延迟。每秒处理数百万个事件，毫秒级延迟。
⚫ 结果的准确性。Flink 提供了事件时间（event-time）和处理时间（processing-time）
语义。对于乱序事件流，事件时间语义仍然能提供一致且准确的结果。
⚫ 精确一次（exactly-once）的状态一致性保证。
⚫ 可以连接到最常用的存储系统，如 Apache Kafka、Apache Cassandra、Elasticsearch、
JDBC、Kinesis 和（分布式）文件系统，如 HDFS 和 S3。
⚫ 高可用。本身高可用的设置，加上与 K8s，YARN 和 Mesos 的紧密集成，再加上从故
障中快速恢复和动态扩展任务的能力，Flink 能做到以极少的停机时间 7×24 全天候
运行。
⚫ 能够更新应用程序代码并将作业（jobs）迁移到不同的 Flink 集群，而不会丢失应用
程序的状态。


**分层 API**
Flink 还是一个非常易于开发的框架，因为它拥有易于使用的分层 API
![image.png](Flink-13-6.assets\146a00ec24cd493d98a13ed1e93bf66b.png)
最底层级的抽象仅仅提供了有状态流，它将处理函数（Process Function）嵌入到了DataStream API 中。底层处理函数（Process Function）与 DataStream API 相集成，可以对某
些操作进行抽象，它允许用户可以使用自定义状态处理来自一个或多个数据流的事件，且状态具有一致性和容错保证。除此之外，用户可以注册事件时间并处理时间回调，从而使程序可以
处理复杂的计算。
实际上，大多数应用并不需要上述的底层抽象，而是直接针对核心 API（Core APIs） 进行编程，比如 DataStream API（用于处理有界或无界流数据）以及 DataSet API（用于处理有界
数据集）。这些 API 为数据处理提供了通用的构建模块，比如由用户定义的多种形式的转换（transformations）、连接（joins）、聚合（aggregations）、窗口（windows）操作等。DataSet API
