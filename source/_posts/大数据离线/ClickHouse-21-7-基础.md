---
title: ClickHouse-21-7-基础
categories:
- 大数据离线
---
#一、简介
ClickHouse 是俄罗斯的 Yandex 于 2016 年开源的列式存储数据库（DBMS），使用 C++语言编写，主要用于在线分析处理查询（OLAP），能够使用 SQL 查询实时生成分析数据报告。

Clickhouse MergeTree 是类hbase LSM实现，写优化于读。

![大数据架构图](ClickHouse-21-7-基础.assets\81bd8a195de24c2b8d963ec7a2e85c13.png)


高吞吐写入能力：
1. 定期合并
2. 顺序写（是随机写的6000倍）

适合存储处理完成之后的宽表，也要注意不适合高qps的场景，不适合多表关联查询。

#二、安装
## 2.1 单机安装
### 2.1.1 安装前准备
#### 2.1.1.1 CentOS取消打开文件数限制
打开/etc/security/limits.conf和/etc/security/limits.d/20-nproc.conf 文件，在末尾添加如下配置。因为Clickhouse擅长高并发处理数据，所以需要打开系统对其的限制(ES同理)。
```
* soft nofile 65536
* hard nofile 65536
* soft nproc 131072
* hard nproc 131072
```
>*：表示所有用户/用户组，也可以指定用户和用户组，如hxr@hxr
>能打开的最大文件数和最大进程数。
>soft/hard/-：软限制和硬限制，软限制就是当前生效的，硬限制就是最大的限制。软限制小于硬限制。-表示软硬一起配置。
>nofile/noproc：no表示数量，nofile表示软件数，noproc表示进程数。

重新打开会话即可生效
可以通过如下命令查看系统配置
`ulimit -n/-a`
>关注以下两项：
>- open files                      (-n) 65536
>- max user processes              (-u) 131072


#### 2.1.1.2 取消SELINUX
打开/etc/selinux/config文件，配置
```
SELINUX=disabled
```
上述配置只有重启生效，所以还需要设置临时生效
`setenforce 0`
查看是否生效
`getenforce`

#### 2.1.1.3 关闭防火墙
`systemctl disable firewalld`

#### 2.1.1.4 安装依赖
yum install -y libtool
yum install -y \*unixODBC\*
yum install -y libicu

### 2.1.2 安装
|版本|功能|
|---|---|
| 20.5 | 新增支持final多线程 |
| 20.6 | 新增支持explain语法查看执行过程 |
| 20.8 | 新增支持同步MySQL数据，不需要Canal或Maxwell |

#### 2.1.2.1 安装地址
[官方安装教程](https://clickhouse.tech/docs/en/getting-started/install)
[国内下载包地址](https://packagecloud.io/altinity/clickhouse)

**一共四个包：**
clickhouse-server-21.7.3.14-2.noarch.rpm
clickhouse-client-21.7.3.14-2.noarch.rpm
clickhouse-common-static-21.7.3.14-2.x86_64.rpm
clickhouse-common-static-dbg-21.7.3.14-2.x86_64.rpm

#### 2.1.2.2 安装
`rpm -ivh *.rpm`

**安装后默认的文件位置：**
- 启动命令：/usr/bin
- 配置文件：/etc/clickhouse-server /etc/clickhouse-client
- lib和数据文件：/var/lib/clickhouse
- 日志文件：/var/log/clickhouse-server

#### 2.1.2.3 修改配置文件
修改/etc/clickhouse-server/config.xml文件
```
<listen_host>::</listen_host>
```
>将listen_host标签的注释打开，允许除本机外的客户端访问。
>该配置文件中还指定了数据文件路径：
>**<path>/var/lib/clickhouse/</path>**
>和日志文件路径：
>**<log>/var/log/clickhouse-server/clickhouse-server.log</log>**

#### 2.1.2.4 启动
**启动clickhouse-server服务**
`systemctl start clickhouse-server`
或
`sudo clickhouse restart`
这个启动命令可以打印启动状态，也可以指定一些参数，如下
`sudo -u clickhouse clickhouse-server start --config-file /etc/clickhouse-server/config.xml --pid-file=/etc/clickhouse-server/clickhouse.pid`
>--database/-d  默认当前操作的数据库（默认default）
>--format/-f  使用指定的默认格式输出结果
>--time/-t  非交互模式下会打印查询执行的时间到窗口
>--stacktrace  如果出现异常，会打印堆栈跟踪信息
>--config-file  指定配置文件
>--pid-file  指定pid存储位置

设置开机自启
`systemctl enable clickhouse-server`
检查是否关闭开机自启
`systemctl is=enabled clickhouse-server`

### 2.1.3 进入客户端
clickhouse-client -m -h bigdata1 -u default --password bigdata123
>-m/--multiline 表示支持多行输入命令
>-h/--host 表示远程连接的主机地址（默认localhost）
>-p/--port 连接的端口（默认9000）
>-u/--user 用户名（默认default）
>--password 密码（用户名密码在配置文件中设置）
>--query/-q/<<<  后面跟查询语句，直接返回查询结果。类似hive -e 
>--send_logs_level=trace 在客户端输出日志并指定日志级别；否则只能去日志文件中查看。
>--multiline/-m  允许多行语句查询
> --format CSVWithNames 规定输出格式

<br>
## 2.2 安装集群
将每个节点都安装单机模式。
然后通过配置文件将多个节点组合成一个集群。

### 2.2.1 修改配置文件
①修改/etc/clickhouse-server/config.xml配置文件
修改为允许任意节点连接
<include_from>/etc/clickhouse-server/metrika.xml</include_from>
<listen_host>::</listen_host>
②在etc目录下新建metrika.xml文件
```
<?xml version="1.0"?>
<yandex>
    <clickhouse_remote_servers>
        <cluster-01>
            <shard>
                <weight>1</weight>
                <internal_replication>false</internal_replication>
                <replica>
                    <host>bigdata1</host>
                    <port>9000</port>
                    <user>default</user>
                    <password></password>
                </replica>
                <replica>
                    <host>bigdata2</host>
                    <port>9000</port>
                    <user>default</user>
                    <password></password>
                </replica>
            </shard>
            <shard>
                <weight>1</weight>
                <internal_replication>false</internal_replication>
                <replica>
                    <host>bigdata2</host>
                    <port>9000</port>
                    <user>default</user>
                    <password></password>
                </replica>
                <replica>
                    <host>bigdata3</host>
                    <port>9000</port>
                    <user>default</user>
                    <password></password>
                </replica>
            </shard>
            <shard>
                <weight>1</weight>
                <internal_replication>false</internal_replication>
                <replica>
                    <host>bigdata3</host>
                    <port>9000</port>
                    <user>default</user>
                    <password></password>
                </replica>
                <replica>
                    <host>bigdata1</host>
                    <port>9000</port>
                    <user>default</user>
                    <password></password>
                </replica>
            </shard>
        </cluster-01>
    </clickhouse_remote_servers>
    
    <zookeeper-servers>
        <node index="1">
            <host>bigdata1</host>
            <port>2181</port>
        </node>
        <node index="2">
            <host>bigdata2</host>
            <port>2181</port>
        </node>
        <node index="3">
            <host>bigdata3</host>
            <port>2181</port>
        </node>
    </zookeeper-servers>
    
     <macros>
      <cluster>cluster-01</cluster>
      <!-- <shard>01</shard> -->
      <!-- <replica>bigdata1</replica> -->
    </macros>
    
    <clickhouse_compression>
        <case>
            <min_part_size>10000000000</min_part_size>
            <min_part_size_ratio>0.01</min_part_size_ratio>
            <method>lz4</method>
        </case>
    </clickhouse_compression>
    
</yandex>
```

**四种复制模式：**
- 非复制表，internal_replication=false。写入单机表时，不同服务器查询结果不同；插入到分布式表中的数据被插入到两个本地表中，如果在插入期间没有问题，则两个本地表上的数据保持同步。我们称之为“穷人的复制”，因为复制在网络出现问题的情况下容易发生分歧，没有一个简单的方法来确定哪一个是正确的复制。
- 非复制表，internal_replication=true。数据只被插入到一个本地表中，但没有任何机制可以将它转移到另一个表中。因此，在不同主机上的本地表看到了不同的数据，查询分布式表时会出现非预期的数据。显然，这是配置ClickHouse集群的一种不正确的方法。
- 复制表，**internal_replication=true**。插入到分布式表中的数据仅插入到其中一个本地表中，但通过复制机制传输到另一个主机上的表中。因此两个本地表上的数据保持同步。这是**官方推荐配置**。
- 复制表，internal_replication=false。数据被插入到两个本地表中，但同时复制表的机制保证重复数据会被删除。数据会从插入的第一个节点复制到其它的节点。其它节点拿到数据后如果发现数据重复，数据会被丢弃。这种情况下，虽然复制保持同步，没有错误发生。但由于不断的重复复制流，会导致写入性能明显的下降。所以这种配置实际应该是避免的。

### 2.2.2 重启每个节点
重启之后查看分片状态
**select * from system.clusters**


<br>
# 三、数据类型
## 3.1 整型
固定长度的整型，包括有符号整型或无符号整型。

**整型范围（-2n-1~2n-1-1）：**
- Int8 - [-128 : 127]
- Int16 - [-32768 : 32767]
- Int32 - [-2147483648 : 2147483647]
- Int64 - [-9223372036854775808 : 9223372036854775807]

**无符号整型范围（0~2n-1）：**
- UInt8 - [0 : 255]
- UInt16 - [0 : 65535]
- UInt32 - [0 : 4294967295]
- UInt64 - [0 : 18446744073709551615]

**使用场景： 个数、数量、也可以存储 id。**

## 3.2 浮点型
- Float32 - float
- Float64 – double
建议尽可能以整数形式存储数据。例如，将固定精度的数字转换为整数值，如时间用毫秒为单位表示，因为浮点型进行计算时可能引起四舍五入的误差。

**使用场景：一般数据值比较小，不涉及大量的统计计算，精度要求不高的时候。比如保存商品的重量。**

## 3.3 布尔型
没有单独的类型来存储布尔值。可以使用 UInt8 类型，取值限制为 0 或 1。

## 3.4 Decimal 型
有符号的浮点数，可在加、减和乘法运算过程中保持精度。对于除法，最低有效数字会被丢弃（不舍入）。
有三种声明(s 标识小数位)：
- Decimal32(s)，相当于 Decimal(9,s)，有效位数为 9，小数位数为s；
- Decimal64(s)，相当于 Decimal(18,s)，有效位数为 18，小数位数为s；
- Decimal128(s)，相当于 Decimal(38,s)，有效位数为 38，小数位数为s。

**使用场景： 一般金额字段、汇率、利率等字段为了保证小数点精度，都使用 Decimal进行存储。**

## 3.5 字符串
- String：字符串可以任意长度的。它可以包含任意的字节集，包含空字节。

- FixedString(N)：固定长度 N 的字符串，N 必须是严格的正自然数。当服务端读取长度小于 N 的字符串时候，通过在字符串末尾添加空字节来达到 N 字节长度。 当服务端读取长度大于 N 的字符串时候，将返回错误消息。与 String 相比，极少会使用 FixedString，因为使用起来不是很方便。

**使用场景：名称、文字描述、字符型编码。 固定长度的可以保存一些定长的内容，比如一些编码，性别等但是考虑到一定的变化风险，带来收益不够明显，所以定长字符串使用意义有限。**


## 3.6 枚举类型
包括 Enum8 和 Enum16 类型。Enum 保存 'string'= integer 的对应关系。
- Enum8 用 'String'= Int8 对描述。
- Enum16 用 'String'= Int16 对描述。

创建一个带有一个枚举 Enum8('hello' = 1, 'world' = 2) 类型的列
```
CREATE TABLE t_enum
(
 x Enum8('hello' = 1, 'world' = 2)
)
ENGINE = TinyLog;
```
这个 x 列只能存储类型定义中列出的值：'hello'或'world'，如果尝试保存任何其他值，ClickHouse 抛出异常。
```
bigdata1 :) INSERT INTO t_enum VALUES ('hello'), ('world'), ('hello');
```
如果需要看到对应行的数值，则必须将 Enum 值转换为整数类型
```
bigdata1 :) SELECT CAST(x, 'Int8') FROM t_enum;
```

**使用场景：对一些状态、类型的字段算是一种空间优化，也算是一种数据约束。但是实际使用中往往因为一些数据内容的变化增加一定的维护成本，甚至是数据丢失问题。所以谨慎使用。**

## 3.7 时间类型
目前 ClickHouse 有三种时间类型
- Date 接受年-月-日的字符串比如 ‘2019-12-16’
- Datetime 接受年-月-日 时:分:秒的字符串比如 ‘2019-12-16 20:50:10’ 
- Datetime64 接受年-月-日 时:分:秒.亚秒的字符串比如‘2019-12-16 20:50:10.66’

日期类型，用两个字节存储，表示从 1970-01-01 (无符号) 到当前的日期值。

[还有很多数据结构，可以参考官方文档](https://clickhouse.yandex/docs/zh/data_types/)

## 3.8 数组
Array(T)：由 T 类型元素组成的数组。
T 可以是任意类型，包含数组类型。 但不推荐使用多维数组，ClickHouse 对多维数组的支持有限。例如，不能在 MergeTree 表中存储多维数组。
（1）创建数组方式 1，使用 array 函数，**array(T)**
```
SELECT array(1, 2) AS x, toTypeName(x) ;
```
（2）创建数组方式 2：使用方括号，**[x, y]**
```
SELECT [1, 2] AS x, toTypeName(x);
```

## 3.9 Nullable
使用Nullable会对性能产生影响，在设计数据库时不要使用Nullable。

<br>
# 四、表引擎
表引擎是 ClickHouse 的一大特色。可以说， 表引擎决定了如何存储表的数据。包括：
- 数据的存储方式和位置，写到哪里以及从哪里读取数据。 
- 支持哪些查询以及如何支持。
- 并发数据访问。
- 索引的使用（如果存在）。
- 是否可以执行多线程请求。
- 数据复制参数。

表引擎的使用方式就是必须显式在创建表时定义该表使用的引擎，以及引擎使用的相关参数。

特别注意：引擎的名称大小写敏感。

[引擎的官网介绍](https://clickhouse.tech/docs/en/engines/table-engines/)

表引擎中有外部集成引擎和内部引擎：外部集成引擎是ClickHouse 提供了集成引擎来与外部系统集成，可以通过代理给外部系统来查询和操作其他类型数据库中的数据(如MySQL，HDFS，Kafka，RabbitMQ等)。如下例子，使用表引擎MySQL创建表来关联外部MySQL表，作为一个代理对MySQL表进行查询。
```
CREATE TABLE IF NOT EXISTS default.course(
   cid Int64,
   user_id Int64,
   msg String
) ENGINE=MySQL('192.168.32.244:3306','sphere_test','course_1','root','hxr')
   SETTINGS
     connection_pool_size=16,
     connection_max_tries=3,
     connection_auto_close=true;
```
>NOTE：可以通过命令`show create xxxxx;`查看表的建表语句。

以下介绍内部引擎。

## 4.1 TinyLog（存磁盘，不支持索引）
**建表：**
```
CREATE TABLE t (a UInt16,b String) ENGINE=TinyLog;
```
**插入数据：**
```
INSERT INTO t (a,b) values(1,'zs');
```
以列文件的形式将数据保存在磁盘中，不支持索引，没有并发控制。一般保存少量数据的小表。
在/var/lib/clickhouse/data/目录下的可以看到数据文件，每列单独存成一个bin文件，还有一个json文件记录信息。

## 4.2 Memory（存内存，不支持索引）
简单查询下可以每秒处理10G数据，但是重启服务器会导致数据丢失。
用于测试或者需要快速处理但是数据量不大的情况。

## 4.3 ★ MergeTree（存磁盘，有索引）
每条数据都存为一个文件，这样可以高效的写入数据。后台会对这些数据按规则进行合并。
①数据按主键排序
②可以使用分区（如果指定了主键）
③支持数据副本
④支持数据采样
```
create table t_order_mt(
 id UInt32,
 sku_id String,
 total_amount Decimal(16,2),
 create_time Datetime
) engine =MergeTree
 partition by toYYYYMMDD(create_time)
 primary key (id)
 order by (id,sku_id);
```
可以手动触发合并：optimize table mt_table（不好用）

### 4.3.1 partition by 分区（可选）
**同hive中的分区，降低扫描范围，优化查询速度。**

MergeTree 是以列文件+索引文件+表定义文件组成的，但是如果设定了分区那么这些文件就会保存到不同的分区目录中。分区后，面对涉及跨分区的查询统计，ClickHouse 会**以分区为单位并行处理**。

**数据写入与分区合并：**任何一个批次的数据写入都会产生一个临时分区，不会纳入任何一个已有的分区。写入后的某个时刻（大概 10-15 分钟后），ClickHouse 会自动执行合并操作（等不及也可以手动通过 optimize 执行，但是optimize操作不会清理过期数据），把临时分区的数据，合并到已有分区中。
`optimize table xxxx final;`

**例：在创建表t_order_mt后，插入数据**
```
insert into t_order_mt values
(101,'sku_001',1000.00,'2020-06-01 12:00:00') ,
(102,'sku_002',2000.00,'2020-06-01 11:00:00'),
(102,'sku_004',2500.00,'2020-06-01 12:00:00'),
(102,'sku_002',2000.00,'2020-06-01 13:00:00'),
(102,'sku_002',12000.00,'2020-06-01 13:00:00'),
(102,'sku_002',600.00,'2020-06-02 12:00:00');
```
查询得到结果如下
```
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 102 │ sku_002 │       600.00 │ 2020-06-02 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 101 │ sku_001 │      1000.00 │ 2020-06-01 12:00:00 │
│ 102 │ sku_002 │      2000.00 │ 2020-06-01 11:00:00 │
│ 102 │ sku_002 │      2000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_002 │     12000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_004 │      2500.00 │ 2020-06-01 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
```
发现已经有两个分区被创建。
再次执行上面的插入操作
```
insert into t_order_mt values
(101,'sku_001',1000.00,'2020-06-01 12:00:00') ,
(102,'sku_002',2000.00,'2020-06-01 11:00:00'),
(102,'sku_004',2500.00,'2020-06-01 12:00:00'),
(102,'sku_002',2000.00,'2020-06-01 13:00:00'),
(102,'sku_002',12000.00,'2020-06-01 13:00:00'),
(102,'sku_002',600.00,'2020-06-02 12:00:00');
```
查询发现
```
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 102 │ sku_002 │       600.00 │ 2020-06-02 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 102 │ sku_002 │       600.00 │ 2020-06-02 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 101 │ sku_001 │      1000.00 │ 2020-06-01 12:00:00 │
│ 102 │ sku_002 │      2000.00 │ 2020-06-01 11:00:00 │
│ 102 │ sku_002 │      2000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_002 │     12000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_004 │      2500.00 │ 2020-06-01 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 101 │ sku_001 │      1000.00 │ 2020-06-01 12:00:00 │
│ 102 │ sku_002 │      2000.00 │ 2020-06-01 11:00:00 │
│ 102 │ sku_002 │      2000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_002 │     12000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_004 │      2500.00 │ 2020-06-01 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
```
发现新插入的数据还是分成了两个分区，但是这两个是临时分区，并没有直接添加到原有的分区中。
手动执行分区合并操作`optimize table t_order_mt final;`或只合并某一分区`optimize table t_order_mt partition '20200601' final;`
```
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 102 │ sku_002 │       600.00 │ 2020-06-02 12:00:00 │
│ 102 │ sku_002 │       600.00 │ 2020-06-02 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 101 │ sku_001 │      1000.00 │ 2020-06-01 12:00:00 │
│ 101 │ sku_001 │      1000.00 │ 2020-06-01 12:00:00 │
│ 102 │ sku_002 │      2000.00 │ 2020-06-01 11:00:00 │
│ 102 │ sku_002 │      2000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_002 │     12000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_002 │      2000.00 │ 2020-06-01 11:00:00 │
│ 102 │ sku_002 │      2000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_002 │     12000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_004 │      2500.00 │ 2020-06-01 12:00:00 │
│ 102 │ sku_004 │      2500.00 │ 2020-06-01 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
```
临时分区合并到了现有的分区中。

当我们查看其本地数据存储目录/var/lib/clickhouse/data/default/t_order_mt后发现，分区文件是单独保存为文件夹的。
```
drwxr-x---. 2 clickhouse clickhouse 243 8月  12 14:06 20200601_1_3_1
drwxr-x---. 2 clickhouse clickhouse 243 8月  12 14:06 20200602_2_4_1
drwxr-x---. 2 clickhouse clickhouse   6 8月  12 13:38 detached
-rw-r-----. 1 clickhouse clickhouse   1 8月  12 13:38 format_version.txt
```
>分区文件夹命名规则为PartitionId_MinBlockNum_MaxBlockNum_Level：
>- PartitionId：取分区键的值；如果是String或Float等类型，通过128位的Hash算法取其Hash值作为分区ID；如果不是分区表，则默认为all。
>- MinBlockNum：最小分区块编号，自增类型，从1开始向上递增。每产生一个新的目录分区，就向上递增一个数字。
>- MaxBlockNum：最大分区块编号，新创建的分区MinBlockNum等于MaxBlockNum的编号。
>- Level：合并的等级，被合并的次数。合并次数越多，层级值越大。

进入20200601_1_3_1目录下可以看到分区的一些信息
```
-rw-r-----. 1 clickhouse clickhouse 260 8月  12 14:06 checksums.txt
-rw-r-----. 1 clickhouse clickhouse 118 8月  12 14:06 columns.txt
-rw-r-----. 1 clickhouse clickhouse   2 8月  12 14:06 count.txt
-rw-r-----. 1 clickhouse clickhouse 217 8月  12 14:06 data.bin
-rw-r-----. 1 clickhouse clickhouse 144 8月  12 14:06 data.mrk3
-rw-r-----. 1 clickhouse clickhouse  10 8月  12 14:06 default_compression_codec.txt
-rw-r-----. 1 clickhouse clickhouse   8 8月  12 14:06 minmax_create_time.idx
-rw-r-----. 1 clickhouse clickhouse   4 8月  12 14:06 partition.dat
-rw-r-----. 1 clickhouse clickhouse   8 8月  12 14:06 primary.idx
```
>- bin文件：数据文件
>- mrk文件：标记文件，标记文件在idx索引文件和bin数据文件之间起到了桥梁作用。以mrk2结尾的文件，表示该表启用了自适应索引间隔。
>- primary.idx文件：主键索引文件，用于加快查询效率。
>- minmax_create_time.idx：分区键的最大最小值。
>- checksums.txt：校验文件，用于校验各个文件的正确性。存放各个文件的size以及hash值。

![image.png](ClickHouse-21-7-基础.assets+73d43d5349ff913ebc456811746e.png)


### 4.3.2 primary key主键（可选）
ClickHouse 中的主键，和其他数据库不太一样，它只提供了数据的一级索引，但是却不是唯一约束。这就意味着是可以存在相同 primary key 的数据的。主键的设定主要依据是查询语句中的 where 条件。

根据条件通过对主键进行某种形式的二分查找，能够定位到对应的 index granularity,避免了全表扫描。

**稀疏索引：**类似Kafka的索引，索引文件中记录了索引行的值和物理偏移量。

**index granularity：** 索引粒度，指在稀疏索引中两个相邻索引对应数据的间隔。ClickHouse 中的 MergeTree 默认是 8192。官方不建议修改这个值，除非该列存在大量重复值，比如在一个分区中几万行才有一个不同数据。

![image.png](ClickHouse-21-7-基础.assets\6430310d8a3843498d6e60e3734fef40.png)


### 4.3.3 order by（必选）
order by 设定了分区内的数据按照哪些字段顺序进行有序保存。
order by 是 MergeTree 中唯一一个必填项，甚至比 primary key 还重要，因为当用户不设置主键的情况，很多处理会依照 order by 的字段进行处理（比如后面会讲的去重和汇总）。

**要求：主键必须是 order by 字段的前缀字段。**比如 order by 字段是 (id,sku_id) 那么主键必须是 id 或者(id,sku_id)


### 4.3.4 二级索引
目前在 ClickHouse 的官网上二级索引的功能在 v20.1.2.4 之前是被标注为实验性的（开启需要设置 **set allow_experimental_data_skipping_indices=1;**），在这个版本之后默认是开启的。

二级索引可以理解为一级索引的索引，作用是快速定位一级索引的位置，加快检索的速度。

**创建测试表**
```
create table t_order_mt2(
 id UInt32,
 sku_id String,
 total_amount Decimal(16,2),
 create_time DateTime,
INDEX mt2_sec_idx total_amount TYPE minmax GRANULARITY 5
) engine =MergeTree
 partition by toYYYYMMDD(create_time)
 primary key (id)
 order by (id, sku_id);
```
>其中 GRANULARITY N 是设定二级索引对于一级索引粒度的粒度，即将N个一级索引合并为一个索引。

插入数据
```
insert into t_order_mt2 values
(101,'sku_001',1000.00,'2020-06-01 12:00:00') ,
(102,'sku_002',2000.00,'2020-06-01 11:00:00'),
(102,'sku_004',2500.00,'2020-06-01 12:00:00'),
(102,'sku_002',2000.00,'2020-06-01 13:00:00'),
(102,'sku_002',12000.00,'2020-06-01 13:00:00'),
(102,'sku_002',600.00,'2020-06-02 12:00:00');
```

查询并打印日志
```shell
clickhouse-client --send_logs_level=trace <<< 'select > * from t_order_mt2 where total_amount > toDecimal32(900., 2)';
```
>可以看到日志中打印 
>**(SelectExecutor): Index mt2_sec_idx has dropped 1/2 granules.**
>表示使用了二级索引。

进入/var/lib/clickhouse/data/default/t_order_mt/20200601_1_3_1本地数据目录，可以看到多了跳数索引文件skp_idx_mt2_sec_idx.idx 和 skp_idx_mt2_sec_idx.mrk3 。
```
-rw-r-----. 1 clickhouse clickhouse 344 8月  12 18:03 checksums.txt
-rw-r-----. 1 clickhouse clickhouse 118 8月  12 18:03 columns.txt
-rw-r-----. 1 clickhouse clickhouse   1 8月  12 18:03 count.txt
-rw-r-----. 1 clickhouse clickhouse 189 8月  12 18:03 data.bin
-rw-r-----. 1 clickhouse clickhouse 144 8月  12 18:03 data.mrk3
-rw-r-----. 1 clickhouse clickhouse  10 8月  12 18:03 default_compression_codec.txt
-rw-r-----. 1 clickhouse clickhouse   8 8月  12 18:03 minmax_create_time.idx
-rw-r-----. 1 clickhouse clickhouse   4 8月  12 18:03 partition.dat
-rw-r-----. 1 clickhouse clickhouse   8 8月  12 18:03 primary.idx
-rw-r-----. 1 clickhouse clickhouse  41 8月  12 18:03 skp_idx_mt2_sec_idx.idx
-rw-r-----. 1 clickhouse clickhouse  24 8月  12 18:03 skp_idx_mt2_sec_idx.mrk3
```

### 4.3.5 数据TTL
TTL 即 Time To Live，MergeTree 提供了可以管理数据表或者列的生命周期的功能，需要依托Date或DateTime类型的字段。

若一张MergeTree表被设置为TTL，则在写入数据时会以数据分区为单位，在每个分区目录内生成一个ttl.txt文件。
ClickHouse 在数据片段合并时会删除掉过期的数据。当ClickHouse发现数据过期时, 它将会执行一个计划外的合并。

要控制这类合并的频率, 可以设置 merge_with_ttl_timeout。如果该值被设置的太低, 它将引发大量计划外的合并，这可能会消耗大量资源。
如果在合并的过程中执行 SELECT 查询, 则可能会得到过期的数据。为了避免这种情况，可以在 SELECT 之前使用 OPTIMIZE 查询。

#### 4.3.5.1 列级别TTL
创建测试表
```
create table t_order_mt3(
 id UInt32,
 sku_id String,
 total_amount Decimal(16,2) TTL create_time+interval 10 SECOND,
 create_time DateTime
) engine =MergeTree
partition by toYYYYMMDD(create_time)
 primary key (id)
 order by (id, sku_id);
```
插入数据
```
insert into t_order_mt3 values
(106,'sku_001',1000.00,'2021-08-12 18:24:30'),
(107,'sku_002',2000.00,'2021-06-12 18:24:30'),
(110,'sku_003',600.00,'2021-06-11 12:00:00');
```
手动合并`optimize table t_order_mt3 final;`
查看效果，到期后指定字段的数据归零(在执行合并时过期的数据才会真正失效)。


#### 4.3.5.2 表级别TTL
下面的这条语句是数据会在 create_time 之后 10 秒丢失
```
alter table t_order_mt3 MODIFY TTL create_time + INTERVAL 10 SECOND;
```
涉及判断的字段必须是 **Date 或者 Datetime 类型**，推荐使用分区的日期字段。

**能够使用的时间周期包括**
- SECOND
- MINUTE
- HOUR
- DAY
- WEEK
- MONTH
- QUARTER
- YEAR

## 4.4 ReplacingMergeTree
在MergeTree的基础上，添加了“处理重复数据”的功能，会删除相同排序项的重复记录，因为Clickhouse的主键没有唯一约束，所以可通过ReplacingMergeTree来保证**分区内的排序项唯一**。

**去重时机：**只会在数据合并时去重，且不保证全部去重。可以指定版本列，选择版本列最大的保留；没指定版本列，默认保留最新的数据。
**去重范围：**表经过分区，去重只会在分区内部进行去重，不能跨分区去重。所以ReplacingMergeTree 适用于在后台清除重复的数据以节省空间，但是它不保证没有重复的数据出现。

**总结**
- 使用order by字段作为唯一键
- 去重只在分区内，不能跨分区去重
- 数据插入时会先对插入的数据进行去重；分区数据在合并分区时进行去重。
- 未指定版本字段，重复数据默认保留新的记录；如果指定版本字段，则保留版本字段的最大值。

**案例演示**
```
create table t_order_rmt(
 id UInt32,
 sku_id String,
 total_amount Decimal(16,2) ,
 create_time Datetime 
) engine =ReplacingMergeTree(create_time)
 partition by toYYYYMMDD(create_time)
 primary key (id)
 order by (id, sku_id);
```
插入数据
```
insert into t_order_rmt values
(101,'sku_001',1000.00,'2020-06-01 12:00:00') ,
(102,'sku_002',2000.00,'2020-06-01 11:00:00'),
(102,'sku_004',2500.00,'2020-06-01 12:00:00'),
(102,'sku_002',2000.00,'2020-06-01 13:00:00'),
(102,'sku_002',12000.00,'2020-06-01 13:00:00'),
(102,'sku_002',600.00,'2020-06-02 12:00:00');
```
新版本的clickhouse在插入时，会对插入的数据先进行去重。
查询得到
```
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 102 │ sku_002 │       600.00 │ 2020-06-02 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 101 │ sku_001 │      1000.00 │ 2020-06-01 12:00:00 │
│ 102 │ sku_002 │     12000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_004 │      2500.00 │ 2020-06-01 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
```
再次插入数据
```
insert into t_order_rmt values
(101,'sku_001',1000.00,'2020-06-01 12:00:00') ,
(102,'sku_002',2000.00,'2020-06-01 11:00:00'),
(102,'sku_004',2500.00,'2020-06-01 12:00:00'),
(102,'sku_002',2000.00,'2020-06-01 13:00:00'),
(102,'sku_002',12000.00,'2020-06-01 13:00:00'),
(102,'sku_002',600.00,'2020-06-02 12:00:00');
```
查询
```
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 102 │ sku_002 │       600.00 │ 2020-06-02 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 102 │ sku_002 │       600.00 │ 2020-06-02 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 101 │ sku_001 │      1000.00 │ 2020-06-01 12:00:00 │
│ 102 │ sku_002 │     12000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_004 │      2500.00 │ 2020-06-01 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 101 │ sku_001 │      1000.00 │ 2020-06-01 12:00:00 │
│ 102 │ sku_002 │     12000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_004 │      2500.00 │ 2020-06-01 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
```
手动合并
`OPTIMIZE TABLE t_order_rmt FINAL;`
再执行一次查询
```
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 102 │ sku_002 │       600.00 │ 2020-06-02 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 101 │ sku_001 │      1000.00 │ 2020-06-01 12:00:00 │
│ 102 │ sku_002 │     12000.00 │ 2020-06-01 13:00:00 │
│ 102 │ sku_004 │      2500.00 │ 2020-06-01 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
```

## 4.5 SummingMergeTree
对于不查询明细，只关心以维度进行汇总聚合结果的场景。如果只使用普通的MergeTree的话，无论是存储空间的开销，还是查询时临时聚合的开销都比较大。
ClickHouse 为了这种场景，提供了一种能够“预聚合”的引擎SummingMergeTree。


**总结**
- 使用order by字段作为同类项进行聚合；
- 聚合只在分区内，不能跨分区聚合；
- 数据插入时会先对插入的数据进行聚合；分区数据在合并分区时进行聚合。
- 其他的列按插入数据保留第一行
- 未指定聚合字段，则以所有数字列(order by 列除外)作为汇总数据列；如果指定聚合字段(可以指定多列)，则聚合指定列。
- 在查询时，还是需要通过sum函数来得到想要的聚合值，以免有部分数据未聚合导致数据偏差。

在大数据场景下一般会使用ReplacingMergeTree，因为SummingMergeTree不能保证幂等性，实时写入时数据源宕机会导致数据重复。

**案例演示**
```
create table t_order_smt(
 id UInt32,
 sku_id String,
 total_amount Decimal(16,2) ,
 create_time Datetime 
) engine =SummingMergeTree(total_amount)
 partition by toYYYYMMDD(create_time)
 primary key (id)
 order by (id,sku_id );
```
插入数据
```
insert into t_order_smt values
(101,'sku_001',1000.00,'2020-06-01 12:00:00'),
(102,'sku_002',2000.00,'2020-06-01 11:00:00'),
(102,'sku_004',2500.00,'2020-06-01 12:00:00'),
(102,'sku_002',2000.00,'2020-06-01 13:00:00'),
(102,'sku_002',12000.00,'2020-06-01 13:00:00'),
(102,'sku_002',600.00,'2020-06-02 12:00:00');
```
新版本在插入时会对插入到数据先进行一次预聚合。
执行第一次查询得到
```
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 101 │ sku_001 │      1000.00 │ 2020-06-01 12:00:00 │
│ 102 │ sku_002 │     16000.00 │ 2020-06-01 11:00:00 │
│ 102 │ sku_004 │      2500.00 │ 2020-06-01 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 102 │ sku_002 │       600.00 │ 2020-06-02 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
```
再次插入数据
```
insert into t_order_smt values
(101,'sku_001',1000.00,'2020-06-01 12:00:00'),
(102,'sku_002',2000.00,'2020-06-01 11:00:00'),
(102,'sku_004',2500.00,'2020-06-01 12:00:00'),
(102,'sku_002',2000.00,'2020-06-01 13:00:00'),
(102,'sku_002',12000.00,'2020-06-01 13:00:00'),
(102,'sku_002',600.00,'2020-06-02 12:00:00');
```
查询得到
```
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 102 │ sku_002 │       600.00 │ 2020-06-02 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 101 │ sku_001 │      1000.00 │ 2020-06-01 12:00:00 │
│ 102 │ sku_002 │     16000.00 │ 2020-06-01 11:00:00 │
│ 102 │ sku_004 │      2500.00 │ 2020-06-01 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 102 │ sku_002 │       600.00 │ 2020-06-02 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 101 │ sku_001 │      1000.00 │ 2020-06-01 12:00:00 │
│ 102 │ sku_002 │     16000.00 │ 2020-06-01 11:00:00 │
│ 102 │ sku_004 │      2500.00 │ 2020-06-01 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
```
手动合并
`optimize table t_order_smt FINAL;`
查询得到
```
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 101 │ sku_001 │      2000.00 │ 2020-06-01 12:00:00 │
│ 102 │ sku_002 │     32000.00 │ 2020-06-01 11:00:00 │
│ 102 │ sku_004 │      5000.00 │ 2020-06-01 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
┌──id─┬─sku_id──┬─total_amount─┬─────────create_time─┐
│ 102 │ sku_002 │      1200.00 │ 2020-06-02 12:00:00 │
└─────┴─────────┴──────────────┴─────────────────────┘
```


## 4.6 Distributed
分布式引擎，本身不存储数据，但是可以在多个服务器上进行分布式查询。读是自动并行的，读取时远程服务器表的索引（如果有的话）会被使用。
```
CREATE TABLE dis_table(id UInt16,name String) 
ENGINE=Distributed('cluster-01','default','t',id);
```

详见第七章分片集群。

# 五、SQL语句
基本上来说传统关系型数据库（以 MySQL 为例）的 SQL 语句，ClickHouse 基本都支持，下面介绍与标准SQL不一致的地方。
## 5.1 Insert
表到表的插入
`insert into [table_name1] select * form [table_name2];

## 5.2 Update和Delete
Clickhouse提供了Delete 和 Update的能力，这类操作被称为Mutation查询，他可以看作是Alter的一种。

虽然可以实现修改和删除，但是和一般的 OLTP 数据库不一样，**Mutation 语句是一种很“重”的操作，而且不支持事务**。
“重”的原因主要是每次修改或者删除都会导致放弃目标数据的原有分区，重建新分区。所以尽量做批量的变更，不要进行频繁小数据的操作。

**删除操作**
```
alter table t_order_smt delete where sku_id = 'sku_001';
```
**修改操作**
```
alter table t_order_smt update total_amount = toDecimal32(2000.00, 2) where id = 102;
```

由于操作比较“重”，所以 Mutation 语句分两步执行，同步执行的部分其实只是进行新增数据新增分区和并把旧分区打上逻辑上的失效标记（类似HBase）。直到触发分区合并的时候，才会删除旧数据释放磁盘空间，一般不会开放这样的功能给用户，由管理员完成。

**底层原理：**将原分区文件读取后修改指定的记录，然后写到新的分区文件中，等待下次分区合并时删除旧数据。

删除更新操作前的数据文件
```
drwxr-x---. 2 clickhouse clickhouse 243 8月  12 14:06 20200601_1_3_1
drwxr-x---. 2 clickhouse clickhouse 243 8月  12 14:06 20200602_2_4_1
drwxr-x---. 2 clickhouse clickhouse   6 8月  12 13:38 detached
-rw-r-----. 1 clickhouse clickhouse   1 8月  12 13:38 format_version.txt
```
删除更新操作后的数据文件
```
drwxr-x---. 2 clickhouse clickhouse 243 8月  12 14:06 20200601_1_3_1
drwxr-x---. 2 clickhouse clickhouse 203 8月  13 11:49 20200601_1_3_1_5
drwxr-x---. 2 clickhouse clickhouse 203 8月  13 11:49 20200601_1_3_1_6
drwxr-x---. 2 clickhouse clickhouse 243 8月  12 14:06 20200602_2_4_1
drwxr-x---. 2 clickhouse clickhouse 243 8月  13 11:49 20200602_2_4_1_5
drwxr-x---. 2 clickhouse clickhouse 203 8月  13 11:49 20200602_2_4_1_6
drwxr-x---. 2 clickhouse clickhouse   6 8月  12 13:38 detached
-rw-r-----. 1 clickhouse clickhouse   1 8月  12 13:38 format_version.txt
-rw-r-----. 1 clickhouse clickhouse  95 8月  13 11:49 mutation_5.txt
-rw-r-----. 1 clickhouse clickhouse 113 8月  13 11:49 mutation_6.txt
```
>可以发现多了几个分区文件，删除操作时产生了20200601_1_3_1_5和20200602_2_4_1_5文件；更新操作时产生了20200601_1_3_1_6和20200602_2_4_1_6文件；20200601_1_3_1和20200602_1_3_1作为旧版本的数据文件，会在分区合并时删除。

<br>
**NOTE：有一种讨巧的修改和删除方式，再添加一个_sign和_version字段。实现如下：**
```
create table a(
b xxx,
c xxx,
_sign UInt8,
_version UInt32
) ENGINE=MergeTree
order by (b);
```
>修改操作：只需要添加一行新数据并将version加一，查询时只需要过滤出version最大的数据即可。
>删除操作：只需要添加新数据，将version加一并将_sign设置为删除标识。查询时过滤出version最大的数据并判断是否已经删除。
>合并过期数据：时间久了，需要考虑如何把过期数据删除。

## 5.3 查询操作
- 支持子查询
- 支持CTE（Common Table Expression 公共表表达式with子句）
- 支持各种 JOIN，但是 JOIN 操作无法使用缓存，所以即使是两次相同的 JOIN 语句，ClickHouse 也会视为两条新 SQL。
- 窗口函数(官方正在测试中... set allow_experimental_window_functions = 1)
- 不支持自定义函数
- GROUP BY 操作增加了 with rollup\with cube\with total 用来计算小计和总计（类似hive中的grouping sets）。相对于自己写优化了代码和执行效率。


**案例演示**
向t_order_mt表中插入数据
```
alter table t_order_mt delete where 1=1;
insert into t_order_mt values
(101,'sku_001',1000.00,'2020-06-01 12:00:00'),
(101,'sku_002',2000.00,'2020-06-01 12:00:00'),
(103,'sku_004',2500.00,'2020-06-01 12:00:00'),
(104,'sku_002',2000.00,'2020-06-01 12:00:00'),
(105,'sku_003',600.00,'2020-06-02 12:00:00'),
(106,'sku_001',1000.00,'2020-06-04 12:00:00'),
(107,'sku_002',2000.00,'2020-06-04 12:00:00'),
(108,'sku_004',2500.00,'2020-06-04 12:00:00'),
(109,'sku_002',2000.00,'2020-06-04 12:00:00'),
(110,'sku_003',600.00,'2020-06-01 12:00:00');
```
①进行rollup操作：从右至左去掉维度进行小计
```
select id, sku_id, sum(total_amount) from t_order_mt group by id, sku_id with rollup;
```
得到结果如下，从上到下分别打印了原始数据、以id进行聚合的数据、以id和sku_id进行聚合的数据。
```
┌──id─┬─sku_id──┬─sum(total_amount)─┐
│ 110 │ sku_003 │            600.00 │
│ 109 │ sku_002 │           2000.00 │
│ 107 │ sku_002 │           2000.00 │
│ 106 │ sku_001 │           1000.00 │
│ 104 │ sku_002 │           2000.00 │
│ 101 │ sku_002 │           2000.00 │
│ 103 │ sku_004 │           2500.00 │
│ 108 │ sku_004 │           2500.00 │
│ 105 │ sku_003 │            600.00 │
│ 101 │ sku_001 │           1000.00 │
└─────┴─────────┴───────────────────┘
┌──id─┬─sku_id─┬─sum(total_amount)─┐
│ 110 │        │            600.00 │
│ 106 │        │           1000.00 │
│ 105 │        │            600.00 │
│ 109 │        │           2000.00 │
│ 107 │        │           2000.00 │
│ 104 │        │           2000.00 │
│ 103 │        │           2500.00 │
│ 108 │        │           2500.00 │
│ 101 │        │           3000.00 │
└─────┴────────┴───────────────────┘
┌─id─┬─sku_id─┬─sum(total_amount)─┐
│  0 │        │          16200.00 │
└────┴────────┴───────────────────┘
```

②进行cube操作：从右至左去掉维度进行小计，再从左至右去掉维度进行小计
```
select id, sku_id, sum(total_amount) from t_order_mt group by id, sku_id with cube;
```
得到结果如下，从上到下分别打印了原始数据、以id进行聚合的数据、以sku_id进行聚合的数据、以id和sku_id进行聚合的数据。
```
┌──id─┬─sku_id──┬─sum(total_amount)─┐
│ 110 │ sku_003 │            600.00 │
│ 109 │ sku_002 │           2000.00 │
│ 107 │ sku_002 │           2000.00 │
│ 106 │ sku_001 │           1000.00 │
│ 104 │ sku_002 │           2000.00 │
│ 101 │ sku_002 │           2000.00 │
│ 103 │ sku_004 │           2500.00 │
│ 108 │ sku_004 │           2500.00 │
│ 105 │ sku_003 │            600.00 │
│ 101 │ sku_001 │           1000.00 │
└─────┴─────────┴───────────────────┘
┌──id─┬─sku_id─┬─sum(total_amount)─┐
│ 110 │        │            600.00 │
│ 106 │        │           1000.00 │
│ 105 │        │            600.00 │
│ 109 │        │           2000.00 │
│ 107 │        │           2000.00 │
│ 104 │        │           2000.00 │
│ 103 │        │           2500.00 │
│ 108 │        │           2500.00 │
│ 101 │        │           3000.00 │
└─────┴────────┴───────────────────┘
┌─id─┬─sku_id──┬─sum(total_amount)─┐
│  0 │ sku_003 │           1200.00 │
│  0 │ sku_004 │           5000.00 │
│  0 │ sku_001 │           2000.00 │
│  0 │ sku_002 │           8000.00 │
└────┴─────────┴───────────────────┘
┌─id─┬─sku_id─┬─sum(total_amount)─┐
│  0 │        │          16200.00 │
└────┴────────┴───────────────────┘
```

③进行totals操作：只计算合计
```
select id, sku_id, sum(total_amount) from t_order_mt group by id, sku_id with totals;
```
得到结果如下
```
┌──id─┬─sku_id──┬─sum(total_amount)─┐
│ 110 │ sku_003 │            600.00 │
│ 109 │ sku_002 │           2000.00 │
│ 107 │ sku_002 │           2000.00 │
│ 106 │ sku_001 │           1000.00 │
│ 104 │ sku_002 │           2000.00 │
│ 101 │ sku_002 │           2000.00 │
│ 103 │ sku_004 │           2500.00 │
│ 108 │ sku_004 │           2500.00 │
│ 105 │ sku_003 │            600.00 │
│ 101 │ sku_001 │           1000.00 │
└─────┴─────────┴───────────────────┘
Totals:
┌─id─┬─sku_id─┬─sum(total_amount)─┐
│  0 │        │          16200.00 │
└────┴────────┴───────────────────┘
```

[内置函数官网说明](https://clickhouse.tech/docs/en/sql-reference/functions/comparison-functions/)


## 5.4 ALTER操作
ALTER只支持MergeTree系列，语法与MySQL基本一致。

新增字段
```
alter table [tableName] add column [colname] [type] after [col1];
```
修改字段类型
```
alter table [tableName] modify column [colname] [type];
```
删除字段
```
alter table [tableName] drop column [colname];
```

## 5.5 DESCRIBE
查看表结构
```
DESCRIBE table;  
```
查看建表语句
```
SHOW CREATE tablename;
```

## 5.6 导出数据
```
clickhouse-client -m -h bigdata1 -u default --password bigdata123 -q 'select * from t_order_mt' --format CSVWithNames > /tmp/t_order_mt;
```
[其他输出格式参考官网](https://clickhouse.tech/docs/en/interfaces/formats/)



## 5.3 CHECK
检查表是否损坏,0表示数据已损坏，1表示数据完整。只支持Log，TinyLog和StripeLog引擎。
`CHECK table;`

<br>
# 六、副本
副本的目的主要是保障数据的高可用性，即使一台 ClickHouse 节点宕机，那么也可以从其他服务器获得相同的数据。
[参考官网](https://clickhouse.tech/docs/en/engines/table-engines/mergetree-family/replication/)

## 6.1 副本写入流程
![image.png](ClickHouse-21-7-基础.assets\48f4d8f012284598b9300ff0fb442819.png)

## 6.2 配置步骤
1. 启动zookeeper集群

2. 在每个节点的/etc/clickhouse-server/config.d目录下另外创建一个名为 metrika.xml 的配置文件，修改用户和用户组为clickhouse，内容如下：
```
<?xml version="1.0"?>
<yandex>
  <zookeeper-servers>
        <node>
            <host>bigdata1</host>
            <port>2181</port>
        </node>
        <node>
            <host>bigdata2</host>
            <port>2181</port>
        </node>
        <node>
            <host>bigdata3</host>
            <port>2181</port>
        </node>
  </zookeeper-servers>
</yandex>
```
>也可以直接修改每个节点的 /etc/clickhouse-server/config.xml 文件，指定zookeeper。

3. 在每个节点的/etc/clickhouse-server/config.xml文件中增加
```
<zookeeper incl="zookeeper-servers" optional="true" />
<include_from>/etc/clickhouse-server/config.d/metrika.xml</include_from>
```

4. 重启所有节点的clickhouse-server服务。

5. 测试：注意副本只能同步数据，不能同步表结构，所以我们需要在每台机器上自己手动建表。

**案例演示**
在三个节点上创建表，节点路径要相同，节点名称进行区分，这里使用rep_1, rep_2和 rep_3。
```
create table t_order_rep2 (
 id UInt32,
 sku_id String,
 total_amount Decimal(16,2),
 create_time Datetime
) engine =ReplicatedMergeTree('/clickhouse/table/01/t_order_rep','rep_1')
 partition by toYYYYMMDD(create_time)
 primary key (id)
 order by (id,sku_id);
```
```
create table t_order_rep2 (
 id UInt32,
 sku_id String,
 total_amount Decimal(16,2),
 create_time Datetime
) engine =ReplicatedMergeTree('/clickhouse/table/01/t_order_rep','rep_2')
 partition by toYYYYMMDD(create_time)
 primary key (id)
 order by (id,sku_id);
```
```
create table t_order_rep2 (
 id UInt32,
 sku_id String,
 total_amount Decimal(16,2),
 create_time Datetime
) engine =ReplicatedMergeTree('/clickhouse/table/01/t_order_rep','rep_3')
 partition by toYYYYMMDD(create_time)
 primary key (id)
 order by (id,sku_id);
```
>**参数解释**
>ReplicatedMergeTree是支持副本的合并树。
>第一个参数是分片的 zk_path 一般按照：/clickhouse/table/{shard}/{table_name} 的格式写，如果只有一个分片就写 01 即可。
>第二个参数是副本名称，相同的分片副本名称不能相同。
>
>可以进入zookeeper客户端中查看该路径下的节点。
>```
>[zk: localhost:2181(CONNECTED) 1] ls  /clickhouse/table/01/t_order_rep  
>[alter_partition_version, metadata, temp, log, leader_election, columns, blocks, nonincrement_block_numbers, replicas, quorum, pinned_part_uuids, block_numbers, mutations, part_moves_shard]
>[zk: localhost:2181(CONNECTED) 2] ls  /clickhouse/table/01/t_order_rep/replicas
>[rep_1, rep_2, rep_3]
>[zk: localhost:2181(CONNECTED) 3] ls /clickhouse/table/01/t_order_rep/replicas/rep_102 
>[is_lost, metadata, is_active, mutation_pointer, columns, max_processed_insert_time, flags, log_pointer, min_unprocessed_insert_time, host, parts, queue, metadata_version]
>[zk: localhost:2181(CONNECTED) 4] ls /clickhouse/table/01/t_order_rep/leader_election
>[leader_election-0000000002, leader_election-0000000001, leader_election-0000000000]
>[zk: localhost:2181(CONNECTED) 5] get /clickhouse/table/01/t_order_rep/leader_election/leader_election-0000000001
>rep_1 (multiple leaders Ok)
>cZxid = 0x100000099
>ctime = Fri Aug 13 16:52:08 CST 2021
>mZxid = 0x100000099
>mtime = Fri Aug 13 16:52:08 CST 2021
>pZxid = 0x100000099
>cversion = 0
>dataVersion = 0
>aclVersion = 0
>ephemeralOwner = 0x27ac19206330004
>dataLength = 27
>numChildren = 0
>```

在一条节点上执行插入命令
```
insert into t_order_rep2 values
(101,'sku_001',1000.00,'2020-06-01 12:00:00'),
(102,'sku_002',2000.00,'2020-06-01 12:00:00'),
(103,'sku_004',2500.00,'2020-06-01 12:00:00'),
(104,'sku_002',2000.00,'2020-06-01 12:00:00'),
(105,'sku_003',600.00,'2020-06-02 12:00:00');
```
查询所有节点的表数据，发现全都已经完成数据同步，这些节点间互为副本。


<br>
# 七、分片集群
副本虽然能够提高数据的可用性，降低丢失风险，但是每台服务器实际上必须容纳全量数据，对数据的横向扩容没有解决。
要解决数据水平切分的问题，需要引入分片的概念。通过分片把一份完整的数据进行切分，不同的分片分布到不同的节点上，再通过 Distributed 表引擎把数据拼接起来一同使用。
Distributed 表引擎本身不存储数据，有点类似于 MyCat 之于 MySql，成为一种中间件，通过分布式逻辑表来写入、分发、路由来操作多台节点不同分片的分布式数据。

`注意：ClickHouse 的集群是表级别的，实际企业中，大部分做了高可用，但是没有用分片，避免降低查询性能以及操作集群的复杂性。`

## 7.1 集群写入流程（3 分片 2 副本共 6 个节点）
![image.png](ClickHouse-21-7-基础.assets\9dea9931dd4147dea9d7a8ae06b5c323.png)

集群通过distribute引擎向表中写入数据，因为每个分片存在副本，可以通过internal_replication参数来选择同步策略：
- internal_replication=false，则不进行内部同步，distribute引擎需要向每个分片的每个副本都进行同步；
- internal_replication=true（适合生产中使用），进行内部同步，先写入到一个副本中，再由这个副本向另一个副本进行同步。这样可以减少副本之间数据不一致的情况。

<br>
## 7.2 集群读取流程（3 分片 2 副本共 6 个节点）
![image.png](ClickHouse-21-7-基础.assets\7309c847778f457c8342867e5f2fe22e.png)

<br>
## 7.3  3 分片 2 副本共 6 个节点集群配置（供参考）
配置的位置还是在之前的/etc/clickhouse-server/config.d/metrika.xml，内容如下
注：也可以不创建外部文件，直接在 config.xml 的<remote_servers>中指定
```
<?xml version="1.0" encoding="utf-8"?>
<yandex> 
  <remote_servers> 
    <gmall_cluster> 
      <!-- 集群名称-->  
      <shard> 
        <!--集群的第一个分片-->  
        <internal_replication>true</internal_replication>  
        <!--该分片的第一个副本-->  
        <replica> 
          <host>bigdata1</host>  
          <port>9000</port> 
        </replica>  
        <!--该分片的第二个副本-->  
        <replica> 
          <host>bigdata2</host>  
          <port>9000</port> 
        </replica> 
      </shard>  
      <shard> 
        <!--集群的第二个分片-->  
        <internal_replication>true</internal_replication>  
        <replica> 
          <!--该分片的第一个副本-->  
          <host>bigdata3</host>  
          <port>9000</port> 
        </replica>  
        <replica> 
          <!--该分片的第二个副本-->  
          <host>bigdata4</host>  
          <port>9000</port> 
        </replica> 
      </shard>  
      <shard> 
        <!--集群的第三个分片-->  
        <internal_replication>true</internal_replication>  
        <replica> 
          <!--该分片的第一个副本-->  
          <host>bigdata5</host>  
          <port>9000</port> 
        </replica>  
        <replica> 
          <!--该分片的第二个副本-->  
          <host>bigdata6</host>  
          <port>9000</port> 
        </replica> 
      </shard> 
    </gmall_cluster> 
  </remote_servers> 
</yandex>
```

<br>
## 7.4 配置三节点版本集群及副本
### 7.4.1 集群及副本规划（2 个分片，只有第一个分片有副本）
![image.png](ClickHouse-21-7-基础.assets\d68ddacb237445839616899e9833c508.png)



| bigdata1                                                     | bigdata2                                                     | bigdata3                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| <macros><br/><shard>01</shard><br/><replica>rep_1_1</replica><br/></macros> | <macros><br/><shard>01</shard> <br/><replica>rep_1_2</replica><br/></macros> | <macros><br/><shard>02</shard><br/><replica>rep_2_1</replica><br/></macros> |

### 7.4.2 配置步骤
1）在 bigdata1的/etc/clickhouse-server/config.d 目录下创建 metrika-shard.xml 文件
`注：也可以不创建外部文件，直接在 config.xml 的<remote_servers>中指定`
```
<?xml version="1.0"?>
<yandex>
  <zookeeper-servers>
    <node index="1">
      <host>bigdata1</host>
      <port>2181</port>
    </node>
    <node index="2">
      <host>bigdata2</host>
      <port>2181</port>
    </node>
    <node index="3">
      <host>bigdata3</host>
      <port>2181</port>
    </node>
  </zookeeper-servers>
  <remote_servers>
    <gmall_cluster>
      <!-- 集群名称-->
      <shard>
        <!--集群的第一个分片-->
        <internal_replication>true</internal_replication>
        <!--该分片的第一个副本-->
        <replica>
          <host>bigdata1</host>
          <port>9000</port>
          <!--目标节点上clickhouse的登陆用户密码，需要有响应的权限，否则导致查询不到目标机的数据--> 
          <user>default</user>
          <password>bigdata123</password>
        </replica>
        <!--该分片的第二个副本-->
        <replica>
          <host>bigdata2</host>
          <port>9000</port>
          <user>default</user>
          <password>bigdata123</password>
        </replica>
      </shard>
      <shard>
        <!--集群的第二个分片-->
        <internal_replication>true</internal_replication>
        <replica>
          <!--该分片的第一个副本-->
          <host>bigdata3</host>
          <port>9000</port>
          <user>default</user>
          <password>bigdata123</password>
        </replica>
      </shard>
    </gmall_cluster>
  </remote_servers>

  <macros>
    <!--不同机器放的分片数不一样-->
    <shard>01</shard>
    <!--不同机器放的副本数不一样--> 
    <replica>rep_01_1</replica>
  </macros>
</yandex>
```

2）将 bigdata1的 metrika-shard.xml 同步到 bigdata2 和 bigdata3

3）修改 103 和 104 中 metrika-shard.xml 宏的配置
```
  <macros> 
    <!--不同机器放的分片数不一样-->
    <shard>01</shard>  
    <!--不同机器放的副本数不一样--> 
    <replica>rep_1_2</replica>  
  </macros> 
```
```
  <macros> 
    <!--不同机器放的分片数不一样-->
    <shard>01</shard>  
    <!--不同机器放的副本数不一样--> 
    <replica>rep_2_1</replica>  
  </macros> 
```

4）在 bigdata1上修改/etc/clickhouse-server/config.xml
```
<include_from>/etc/clickhouse-server/config.d/metrika-shard.xml</include_from>
```

5）同步/etc/clickhouse-server/config.xml 到 bigdata2 和 bigdata3

6）重启三台服务器上的 ClickHouse 服务
` ps -ef |grep click` 查看是否成功运行。

进入客户端，使用命令`show clusters`或`select * from system.clusters;`查询集群，可以看到我们创建的集群gmall_cluster，以及配置文件中默认配置并启动的6个集群。
```
┌─cluster──────────────────────────────────────┐
│ gmall_cluster                                │
│ test_cluster_two_shards                      │
│ test_cluster_two_shards_internal_replication │
│ test_cluster_two_shards_localhost            │
│ test_shard_localhost                         │
│ test_shard_localhost_secure                  │
│ test_unavailable_shard                       │
└──────────────────────────────────────────────┘
```

7）在 bigdata1 上执行建表语句
```
create table st_order_mt on cluster gmall_cluster (
 id UInt32,
 sku_id String,
 total_amount Decimal(16,2),
 create_time Datetime
) engine 
=ReplicatedMergeTree('/clickhouse/tables/{shard}/st_order_mt','{replica}')
 partition by toYYYYMMDD(create_time)
 primary key (id)
 order by (id,sku_id);
```
执行结果为
```
┌─host─────┬─port─┬─status─┬─error─┬─num_hosts_remaining─┬─num_hosts_active─┐
│ bigdata2 │ 9000 │      0 │       │                   2 │                0 │
│ bigdata3 │ 9000 │      0 │       │                   1 │                0 │
│ bigdata1 │ 9000 │      0 │       │                   0 │                0 │
└──────────┴──────┴────────┴───────┴─────────────────────┴──────────────────┘
```

- 会自动同步到 bigdata2 和 bigdata3 上 
- 集群名字要和配置文件中的一致
- 分片和副本名称会自动从配置文件的宏定义中获取

8）在 bigdata1 上创建 Distribute 分布式表
```
create table st_order_mt_all2 on cluster gmall_cluster
(
 id UInt32,
 sku_id String,
 total_amount Decimal(16,2),
 create_time Datetime
)engine = Distributed(gmall_cluster,default, st_order_mt,hiveHash(sku_id));
```
>参数含义：
>Distributed（集群名称，库名，本地表名，分片键）
>分片键必须是整型数字，所以用 hiveHash 函数转换，也可以 rand()

9）在 bigdata1上插入测试数据
```
insert into st_order_mt_all2 values
(201,'sku_001',1000.00,'2020-06-01 12:00:00') ,
(202,'sku_002',2000.00,'2020-06-01 12:00:00'),
(203,'sku_004',2500.00,'2020-06-01 12:00:00'),
(204,'sku_002',2000.00,'2020-06-01 12:00:00'),
(205,'sku_003',600.00,'2020-06-02 12:00:00');
```

10）通过查询分布式表和本地表观察输出结果
（1）分布式表
```
SELECT * FROM st_order_mt_all2; 
```
（2）本地表
```
select * from st_order_mt;
```
（3）观察数据的分布

## 7.5 配置三节点、三分片、三副本的集群
```
<?xml version="1.0"?>
<yandex>
  <zookeeper-servers>
    <node index="1">
      <host>bigdata1</host>
      <port>2181</port>
    </node>
    <node index="2">
      <host>bigdata2</host>
      <port>2181</port>
    </node>
    <node index="3">
      <host>bigdata3</host>
      <port>2181</port>
    </node>
  </zookeeper-servers>
  <remote_servers>
    <gmall_cluster>
      <!-- 集群名称-->
      <shard>
        <!--集群的第一个分片-->
        <internal_replication>true</internal_replication>
        <!--该分片的第一个副本-->
        <replica>
          <host>bigdata1</host>
          <port>9000</port>
          <!--目标节点上clickhouse的登陆用户密码，需要有响应的权限，否则导致查询不到目标机的数据--> 
          <user>default</user>
          <password>bigdata123</password>
        </replica>
        <!--该分片的第二个副本-->
        <replica>
          <host>bigdata2</host>
          <port>9000</port>
          <user>default</user>
          <password>bigdata123</password>
        </replica>
      </shard>
      <shard>
        <!--集群的第二个分片-->
        <internal_replication>true</internal_replication>
        <replica>
          <!--该分片的第一个副本-->
          <host>bigdata2</host>
          <port>9000</port>
          <user>default</user>
          <password>bigdata123</password>
          <!--该分片的第二个副本-->
          <host>bigdata3</host>
          <port>9000</port>
          <user>default</user>
          <password>bigdata123</password>
        </replica>
      </shard>
      <shard>
        <!--集群的第三个分片-->
        <internal_replication>true</internal_replication>
        <replica>
          <!--该分片的第一个副本-->
          <host>bigdata3</host>
          <port>9000</port>
          <user>default</user>
          <password>bigdata123</password>
          <!--该分片的第二个副本-->
          <host>bigdata1</host>
          <port>9000</port>
          <user>default</user>
          <password>bigdata123</password>
        </replica>
      </shard>
    </gmall_cluster>
  </remote_servers>
</yandex>
```

思路：不能在配置文件中配置macros，因为一台节点上有两个副本，配置两个macros会导致clickhouse不知道读哪个，所以需要为每个副本建一张mergetree表，在建表时写死分片号和副本号，然后通过Distributed引擎将这些表管理起来。


<br>
# 八、从HDFS中读取/导入数据
## 8.1 HDFS中读取数据
**把HDFS作为一个外部存储，需要从HDFS拉取数据，相较于ClickHouse本地存储速度较慢。**
CREATE TABLE hdfs_student_csv(id Int8,name String) 
ENGINE=HDFS('hdfs://bigdata1:9000/student.csv','CSV')
使用HDFS引擎从HDFS中读取CSV文件并映射成表。

## 8.2 HDFS中导入数据
**将HDFS读取到的数据导入到本地表中：**
CREATE TABLE student_local(id Int8,name String) ENGINE=TinyLog;
INSERT INTO student_local SELECT * FORM hdfs_student_csv;

<br>
# 九、优化
## 9.1 max_table_to_drop
在config.xml中配置，应用于需要删除表或分区的情况。默认50GB，如果删除的分区或者表数据量大于这个参数会删除失败。建议改为0,0表示不限制删除大小。

## 9.2 max_memory_usage
在user.xml中配置，表示单词Query占用内存的最大值，超过后查询失败。

## 9.3 删除多个节点上的同一张表
删除集群上的所有指定名字的表
DROP TABLE t ON CLUSTER clickhouse_cluster;

## 9.4 自动数据备份
MergeTree系列的表支持副本。在表引擎名称上加上Replicated前缀。如ReplicatedMergeTree。
以3个分片2个备份，六台服务器为例：
bigdata1  shard=01  replica=01
bigdata2  shard=01  replica=02
bigdata3  shard=02  replica=01
bigdata4  shard=02  replica=02
bigdata5  shard=03  replica=01
bigdata6  shard=03  replica=02

创建表：
```sql
CREATE TABLE rep_table_name(......) ENGINE=ReplicatedMergeTree('/clickhouse/tables/{shard}/rep_table_name','{replica}')
PARTITION BY expr
ORDER BY expr
SAMPLE BY expr
```
