---
title: MySQL优化
categories:
- MySQL
---
# 1. 性能下降原因
- 查询语句效率低
- 索引失效（会导致行锁变表锁，很严重！！！）
- 关联查询太多
- 服务器调优及各个参数设置（缓冲、线程数等）
- 锁的效率（可能间隙锁导致并发下降，主键需要自增） 
- 数据量过大，使用缓存，进行读写分离，分库分表等

# 2. 性能分析
## 2.1 优化器(MySQL Query Optimizer)
专门负责优化SELECT语句的优化器模型。通过计算分析系统中收集到的统计信息，为客户端请求的Query提供它认为最优的执行计划（不一定是DBA认为最优的计划，这部分最耗时间）

## 2.2 MySQL常见瓶颈
- 1.CPU饱和的时候一般发生在数据装入内存或从磁盘上读取数据的时候；
- 2.IO：磁盘I/O瓶颈发生在装入数据远大于内存容量的时候；
- 3.服务器硬件性能瓶颈：top、free、iostat和vmstat查看系统性能。

<br>
## 2.3 效率分析
### 2.3.1 开启慢查询日志，设置阈值，比如超过5秒钟的就是慢SQL，并将它抓取出来；
```
**设置开启**
SHOW VARIABLES LIKE '%slow_query_log%';
set global show_query_log=1;
set slow_query_log_file=/var/lib/mysql/slow-query.log;
**设置慢查询时间**
SHOW VARIABLES LIKE 'long_query_time%';
set long_query_time = 3; 
会将慢查询的信息存储到指定文件中。
SHOW VARIABLES LIKE '';
查询记录的慢SQL的数量
SHOW GLOBAL STATUS LIKE '%slow_queries%';
查询是否将未使用索引的SQL进行记录
SHOW VARIABLES LIKE '%log_queries_not_using_indexes%';
```
**在生产环境中，可以使用MySQL提供的日志分析工具mysqldumpslow进行分析。**![image.png](MySQL优化.assets