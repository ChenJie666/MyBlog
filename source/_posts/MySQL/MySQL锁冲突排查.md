---
title: MySQL锁冲突排查
categories:
- MySQL
---

# 一、常用命令
## 1. 查询当前启动的进程
```
show processlist
```
## 2. 查看当前正在被使用的表
```
show OPEN TABLES where In_use > 0;
```
## 3. 查询innodb引擎状态
```
show engine innodb status
```


<br>
# 二、锁表信息
在5.5中，information_schema 库中增加了三个关于锁的表（innoDB引擎）：

- innodb_trx         ## 当前运行的所有事务
- innodb_locks       ## 当前出现的锁
- innodb_lock_waits  ## 锁等待的对应关系

先来看一下这三张表结构：

①表innodb_locks
```
mysql> desc information_schema.innodb_locks;

+————-+———————+——+—–+———+——-+
| Field       | Type                | Null | Key | Default | Extra |
+————-+———————+——+—–+———+——-+
| lock_id     | varchar(81)         | NO   |     |         |       |#锁ID
| lock_trx_id | varchar(18)         | NO   |     |         |       |#拥有锁的事务ID
| lock_mode   | varchar(32)         | NO   |     |         |       |#锁模式
| lock_type   | varchar(32)         | NO   |     |         |       |#锁类型
| lock_table  | varchar(1024)       | NO   |     |         |       |#被锁的表
| lock_index  | varchar(1024)       | YES  |     | NULL    |       |#被锁的索引
| lock_space  | bigint(21) unsigned | YES  |     | NULL    |       |#被锁的表空间号
| lock_page   | bigint(21) unsigned | YES  |     | NULL    |       |#被锁的页号
| lock_rec    | bigint(21) unsigned | YES  |     | NULL    |       |#被锁的记录号
| lock_data   | varchar(8192)       | YES  |     | NULL    |       |#被锁的数据
+————-+———————+——+—–+———+——-+
```


②表innodb_lock_waits
```
mysql> desc information_schema.innodb_lock_waits

+——————-+————-+——+—–+———+——-+
| Field             | Type        | Null | Key | Default | Extra |
+——————-+————-+——+—–+———+——-+
| requesting_trx_id | varchar(18) | NO   |     |         |       |#请求锁的事务ID
| requested_lock_id | varchar(81) | NO   |     |         |       |#请求锁的锁ID
| blocking_trx_id   | varchar(18) | NO   |     |         |       |#当前拥有锁的事务ID
| blocking_lock_id  | varchar(81) | NO   |     |         |       |#当前拥有锁的锁ID
+——————-+————-+——+—–+———+——-+
```

③表innodb_trx 
```
mysql> desc information_schema.innodb_trx 

+—————————-+———————+——+—–+———————+——-+
| Field                      | Type                | Null | Key | Default             | Extra |
+—————————-+———————+——+—–+———————+——-+
| trx_id                     | varchar(18)         | NO   |     |                     |       |#事务ID
| trx_state                  | varchar(13)         | NO   |     |                     |       |#事务状态：
| trx_started                | datetime            | NO   |     | 0000-00-00 00:00:00 |       |#事务开始时间；
| trx_requested_lock_id      | varchar(81)         | YES  |     | NULL                |       |#innodb_locks.lock_id
| trx_wait_started           | datetime            | YES  |     | NULL                |       |#事务开始等待的时间
| trx_weight                 | bigint(21) unsigned | NO   |     | 0                   |       |#
| trx_mysql_thread_id        | bigint(21) unsigned | NO   |     | 0                   |       |#事务线程ID
| trx_query                  | varchar(1024)       | YES  |     | NULL                |       |#具体SQL语句
| trx_operation_state        | varchar(64)         | YES  |     | NULL                |       |#事务当前操作状态
| trx_tables_in_use          | bigint(21) unsigned | NO   |     | 0                   |       |#事务中有多少个表被使用
| trx_tables_locked          | bigint(21) unsigned | NO   |     | 0                   |       |#事务拥有多少个锁
| trx_lock_structs           | bigint(21) unsigned | NO   |     | 0                   |       |#
| trx_lock_memory_bytes      | bigint(21) unsigned | NO   |     | 0                   |       |#事务锁住的内存大小（B）
| trx_rows_locked            | bigint(21) unsigned | NO   |     | 0                   |       |#事务锁住的行数
| trx_rows_modified          | bigint(21) unsigned | NO   |     | 0                   |       |#事务更改的行数
| trx_concurrency_tickets    | bigint(21) unsigned | NO   |     | 0                   |       |#事务并发票数
| trx_isolation_level        | varchar(16)         | NO   |     |                     |       |#事务隔离级别
| trx_unique_checks          | int(1)              | NO   |     | 0                   |       |#是否唯一性检查
| trx_foreign_key_checks     | int(1)              | NO   |     | 0                   |       |#是否外键检查
| trx_last_foreign_key_error | varchar(256)        | YES  |     | NULL                |       |#最后的外键错误
| trx_adaptive_hash_latched  | int(1)              | NO   |     | 0                   |       |#
| trx_adaptive_hash_timeout  | bigint(21) unsigned | NO   |     | 0                   |       |#
+—————————-+———————+——+—–+———————+——-+
```

查看所有的锁和持有锁的事务
```
SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCKS; 
```

查看等待锁的事务
```
SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCK_WAITS;
```

查看锁阻塞线程信息
3.1  使用show processlist查看
3.2  直接使用show engine innodb status查看


<br>
# 三、测试
## 3.1 准备
创建测试数据库和表
```
create database test DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
use test;
create table user(id int(11), name varchar(255), score int(11)) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci;
```
插入一条数据
```
insert into user values(1, 'zs', 88);
```
上锁
```
BEGIN;
select * from user where id = 1 lock in share mode;
```

打开另一个对话，修改这条记录
```
update user set score = 100 where id = 1;
```
此时这个操作就会一直等待持有该行读锁的事务释放锁，直到超时。

## 3.2 排查
① `show OPEN TABLES where In_use > 0`
```
mysql> show OPEN TABLES where In_use > 0;
+----------+-------+--------+-------------+
| Database | Table | In_use | Name_locked |
+----------+-------+--------+-------------+
| test     | user  |      1 |           0 |
+----------+-------+--------+-------------+
```

②`show processlist`
```
mysql> show processlist\G;
*************************** 1. row ***************************
     Id: 43972
   User: root
   Host: 192.168.32.23:6801
     db: test
Command: Sleep
   Time: 516
  State: 
   Info: NULL
*************************** 2. row ***************************
     Id: 43973
   User: root
   Host: 192.168.32.23:12821
     db: test
Command: Sleep
   Time: 1425
  State: 
   Info: NULL
*************************** 3. row ***************************
     Id: 43975
   User: root
   Host: localhost
     db: test
Command: Query
   Time: 0
  State: init
   Info: show processlist
*************************** 4. row ***************************
     Id: 43995
   User: root
   Host: localhost
     db: test
Command: Query
   Time: 25
  State: updating
   Info: update user set score = 100 where id = 1
```

可以发现id为43995的进程在执行更新操作，只是无法准确判断该进程是否阻塞。
可以配合`show OPEN TABLES where In_use > 0`来判断，如果该进程阻塞，可以通过kill 43995来杀死该进程。

③查看所有的锁和持有锁的事务
查询INNODB_LOCKS表
```
mysql> mysql> SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCKS;
+-------------------+-------------+-----------+-----------+---------------+------------+------------+-----------+----------+-----------+
| lock_id           | lock_trx_id | lock_mode | lock_type | lock_table    | lock_index | lock_space | lock_page | lock_rec | lock_data |
+-------------------+-------------+-----------+-----------+---------------+------------+------------+-----------+----------+-----------+
| 37057126:1359:3:2 | 37057126    | X         | RECORD    | `test`.`user` | PRIMARY    |       1359 |         3 |        2 | 1         |
| 37056201:1359:3:2 | 37056201    | X         | RECORD    | `test`.`user` | PRIMARY    |       1359 |         3 |        2 | 1         |
+-------------------+-------------+-----------+-----------+---------------+------------+------------+-----------+----------+-----------+
```

④查询等待锁的事务
查询INNODB_LOCK_WAITS表
```
mysql> SELECT * FROM INFORMATION_SCHEMA.INNODB_LOCK_WAITS;
+-------------------+-------------------+-----------------+-------------------+
| requesting_trx_id | requested_lock_id | blocking_trx_id | blocking_lock_id  |
+-------------------+-------------------+-----------------+-------------------+
| 37057220          | 37057220:1359:3:2 | 37056201        | 37056201:1359:3:2 |
+-------------------+-------------------+-----------------+-------------------+
```

⑤查询当前事务
查询INNODB_TRX表
```
mysql> mysql> SELECT * FROM INFORMATION_SCHEMA.INNODB_TRX;
+----------+-----------+---------------------+-----------------------+------------------+------------+---------------------+---------------------------------------------+---------------------+-------------------+-------------------+------------------+-----------------------+-----------------+-------------------+-------------------------+---------------------+-------------------+------------------------+----------------------------+---------------------------+---------------------------+------------------+----------------------------+
| trx_id   | trx_state | trx_started         | trx_requested_lock_id | trx_wait_started | trx_weight | trx_mysql_thread_id | trx_query                                   | trx_operation_state | trx_tables_in_use | trx_tables_locked | trx_lock_structs | trx_lock_memory_bytes | trx_rows_locked | trx_rows_modified | trx_concurrency_tickets | trx_isolation_level | trx_unique_checks | trx_foreign_key_checks | trx_last_foreign_key_error | trx_adaptive_hash_latched | trx_adaptive_hash_timeout | trx_is_read_only | trx_autocommit_non_locking |
+----------+-----------+---------------------+-----------------------+------------------+------------+---------------------+---------------------------------------------+---------------------+-------------------+-------------------+------------------+-----------------------+-----------------+-------------------+-------------------------+---------------------+-------------------+------------------------+----------------------------+---------------------------+---------------------------+------------------+----------------------------+
| 37056201 | RUNNING   | 2021-10-09 10:51:23 | NULL                  | NULL             |          7 |               43975 | SELECT * FROM INFORMATION_SCHEMA.INNODB_TRX | NULL                |                 0 |                 0 |                5 |                  1184 |               3 |                 2 |                       0 | REPEATABLE READ     |                 1 |                      1 | NULL                       |                         0 |                     10000 |                0 |                          0 |
+----------+-----------+---------------------+-----------------------+------------------+------------+---------------------+---------------------------------------------+---------------------+-------------------+-------------------+------------------+-----------------------+-----------------+-------------------+-------------------------+---------------------+-------------------+------------------------+----------------------------+---------------------------+---------------------------+------------------+----------------------------+
```

⑥`show engine innodb status`
```
mysql> show engine innodb status\G;
*************************** 1. row ***************************
  Type: InnoDB
  Name: 
Status: 
=====================================
2021-10-09 11:27:46 7f01eb71f700 INNODB MONITOR OUTPUT
=====================================
Per second averages calculated from the last 57 seconds
-----------------
BACKGROUND THREAD
-----------------
srv_master_thread loops: 249 srv_active, 0 srv_shutdown, 2581588 srv_idle
srv_master_thread log flush and writes: 2581820
----------
SEMAPHORES
----------
OS WAIT ARRAY INFO: reservation count 6806
OS WAIT ARRAY INFO: signal count 6802
Mutex spin waits 59, rounds 568, OS waits 15
RW-shared spins 6791, rounds 203730, OS waits 6787
RW-excl spins 0, rounds 0, OS waits 0
Spin rounds per wait: 9.63 mutex, 30.00 RW-shared, 0.00 RW-excl
------------
TRANSACTIONS
------------
Trx id counter 37057632
Purge done for trx's n:o < 37053030 undo n:o < 0 state: running but idle
History list length 769
LIST OF TRANSACTIONS FOR EACH SESSION:
---TRANSACTION 37057631, not started
MySQL thread id 44007, OS thread handle 0x7f01eb827700, query id 4948502 192.168.32.237 root cleaning up
---TRANSACTION 37057630, not started
MySQL thread id 44005, OS thread handle 0x7f01eb617700, query id 4948504 192.168.32.237 root cleaning up
---TRANSACTION 0, not started
MySQL thread id 43973, OS thread handle 0x7f01eb5d5700, query id 4943434 192.168.32.23 root cleaning up
---TRANSACTION 37056224, not started
MySQL thread id 43972, OS thread handle 0x7f01eafe7700, query id 4945238 192.168.32.23 root cleaning up
---TRANSACTION 37057629, ACTIVE 4 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 2 lock struct(s), heap size 360, 1 row lock(s)
MySQL thread id 43995, OS thread handle 0x7f01eb551700, query id 4948497 localhost root updating
update user set score = 100 where id = 1
------- TRX HAS BEEN WAITING 4 SEC FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 1359 page no 3 n bits 72 index `PRIMARY` of table `test`.`user` trx id 37057629 lock_mode X locks rec but not gap waiting
Record lock, heap no 2 PHYSICAL RECORD: n_fields 5; compact format; info bits 0
 0: len 4; hex 80000001; asc     ;;
 1: len 6; hex 000002356ec9; asc    5n ;;
 2: len 7; hex 0500000157043c; asc     W <;;
 3: len 2; hex 7a73; asc zs;;
 4: len 4; hex 8000005a; asc    Z;;

------------------
---TRANSACTION 37056201, ACTIVE 2183 sec
5 lock struct(s), heap size 1184, 3 row lock(s), undo log entries 2
MySQL thread id 43975, OS thread handle 0x7f01eb71f700, query id 4948505 localhost root init
show engine innodb status
--------
FILE I/O
--------
I/O thread 0 state: waiting for completed aio requests (insert buffer thread)
I/O thread 1 state: waiting for completed aio requests (log thread)
I/O thread 2 state: waiting for completed aio requests (read thread)
I/O thread 3 state: waiting for completed aio requests (read thread)
I/O thread 4 state: waiting for completed aio requests (read thread)
I/O thread 5 state: waiting for completed aio requests (read thread)
I/O thread 6 state: waiting for completed aio requests (write thread)
I/O thread 7 state: waiting for completed aio requests (write thread)
I/O thread 8 state: waiting for completed aio requests (write thread)
I/O thread 9 state: waiting for completed aio requests (write thread)
Pending normal aio reads: 0 [0, 0, 0, 0] , aio writes: 0 [0, 0, 0, 0] ,
 ibuf aio reads: 0, log i/o's: 0, sync i/o's: 0
Pending flushes (fsync) log: 0; buffer pool: 0
737 OS file reads, 28767 OS file writes, 27726 OS fsyncs
0.00 reads/s, 0 avg bytes/read, 0.00 writes/s, 0.00 fsyncs/s
-------------------------------------
INSERT BUFFER AND ADAPTIVE HASH INDEX
-------------------------------------
Ibuf: size 1, free list len 0, seg size 2, 0 merges
merged operations:
 insert 0, delete mark 0, delete 0
discarded operations:
 insert 0, delete mark 0, delete 0
Hash table size 276671, node heap has 2 buffer(s)
0.28 hash searches/s, 0.30 non-hash searches/s
---
LOG
---
Log sequence number 6498236107
Log flushed up to   6498236107
Pages flushed up to 6498236107
Last checkpoint at  6498236107
0 pending log writes, 0 pending chkp writes
13909 log i/o's done, 0.00 log i/o's/second
----------------------
BUFFER POOL AND MEMORY
----------------------
Total memory allocated 137363456; in additional pool allocated 0
Dictionary memory allocated 474108
Buffer pool size   8191
Free buffers       7528
Database pages     661
Old database pages 261
Modified db pages  0
Pending reads 0
Pending writes: LRU 0, flush list 0, single page 0
Pages made young 0, not young 0
0.00 youngs/s, 0.00 non-youngs/s
Pages read 645, created 16, written 8072
0.00 reads/s, 0.00 creates/s, 0.00 writes/s
Buffer pool hit rate 1000 / 1000, young-making rate 0 / 1000 not 0 / 1000
Pages read ahead 0.00/s, evicted without access 0.00/s, Random read ahead 0.00/s
LRU len: 661, unzip_LRU len: 0
I/O sum[0]:cur[0], unzip sum[0]:cur[0]
--------------
ROW OPERATIONS
--------------
0 queries inside InnoDB, 0 queries in queue
0 read views open inside InnoDB
Main thread process no. 16650, id 139646388864768, state: sleeping
Number of rows inserted 61, updated 247, deleted 0, read 37851986
0.00 inserts/s, 0.00 updates/s, 0.00 deletes/s, 19.19 reads/s
----------------------------
END OF INNODB MONITOR OUTPUT
============================
```
>该命令可以看到详细的锁等待信息和原因，推荐使用。

<br>
# 四、结论
在分析innodb中锁阻塞时，几种方法的对比情况：

（1）使用show processlist查看不靠谱；
（2）直接使用show engine innodb status查看，无法判断到问题的根因；
（3）使用mysqladmin debug查看，能看到所有产生锁的线程，但无法判断哪个才是根因；
（4）开启innodb_lock_monitor后，再使用show engine innodb status查看，能够找到锁阻塞的根因。
