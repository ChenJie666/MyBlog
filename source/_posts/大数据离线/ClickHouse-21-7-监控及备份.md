---
title: ClickHouse-21-7-监控及备份
categories:
- 大数据离线
---
# 一、ClickHouse 监控概述
ClickHouse 运行时会将一些个自身的运行状态记录到众多系统表中( system.*)。所以我们对于 CH 自身的一些运行指标的监控数据，也主要来自这些系统表。

但是直接查询这些系统表会有一些不足之处：
- 这种方式太过底层，不够直观，我们还需要在此之上实现可视化展示； 
- 系统表只记录了 CH 自己的运行指标，有些时候我们需要外部系统的指标进行关联分析，例如 ZooKeeper、服务器 CPU、IO 等等。

现在 Prometheus + Grafana 的组合比较流行，安装简单易上手，可以集成很多框架，包括服务器的负载, 其中 Prometheus 负责收集各类系统的运行指标; Grafana 负责可视化的部分。

ClickHouse 从 v20.1.2.4 开始，内置了对接 Prometheus 的功能，配置的方式也很简单,可以将其作为 Prometheus 的 Endpoint 服务，从而自动的将 metrics、events 和asynchronous_metrics 三张系统的表的数据发送给 Prometheus。 

<br>
# 二、Prometheus&Grafana 的安装
Prometheus下载地址：https://prometheus.io/download/
Grafana 下载地址：https://grafana.com/grafana/download
## 2.1 安装 Prometheus
Prometheus 基于 Golang 编写，编译后的软件包，不依赖于任何的第三方依赖。只需要
下载对应平台的二进制包，解压并且添加基本的配置即可正常启动 Prometheus Server。

### 2.1.1 上传安装包
上传 prometheus-2.26.0.linux-amd64.tar.gz 到虚拟机的/opt/software 目录

### 2.1.2 解压安装包
（1）解压到/opt/module 目录下
```
tar -zxvf prometheus-2.26.0.linux-amd64.tar.gz -C /opt/module
```
修改目录名
```
 mv prometheus-2.26.0.linux-amd64 prometheus-2.26.0
```

### 2.1.3 修改配置文件 prometheus.yml
在 scrape_configs 配置项下添加配置：
```
scrape_configs:
 - job_name: 'prometheus'
   static_configs:
     - targets: ['bigdata1:9090']
 #添加 ClickHouse 监控配置
 - job_name: clickhouse-1
   static_configs:
     - targets: ['bigdata1:9363']
```

配置说明：
1、global 配置块：控制 Prometheus 服务器的全局配置
- scrape_interval：配置拉取数据的时间间隔，默认为 1 分钟。
- evaluation_interval：规则验证（生成 alert）的时间间隔，默认为 1 分钟。

2、rule_files 配置块：规则配置文件
3、scrape_configs 配置块：配置采集目标相关， prometheus 监视的目标。Prometheus 自身的运行信息可以通过 HTTP 访问，所以 Prometheus 可以监控自己的运行数据。
- job_name：监控作业的名称
- static_configs：表示静态目标配置，就是固定从某个 target 拉取数据
- targets ： 指 定 监 控 的 目 标 ， 其 实 就 是 从 哪 儿 拉 取 数 据 。 Prometheus 会 从 http://bigdata1:9090/metrics 上拉取数据。

**Prometheus 是可以在运行时自动加载配置的。启动时需要添加： --web.enable-lifecycle**

### 2.1.4 启动 Prometheus Server
```
nohup ./prometheus --web.enable-lifecycle --config.file=prometheus.yml > ./prometheus.log 2>&1 &
```
>prometheus启动命令添加参数 --web.enable-lifecycle然后热重启: `curl -XPOST http://localhost:9090/-/reload`

访问UI页面：http://bigdata1:9090

![image.png](ClickHouse-21-7-监控及备份.assets\2028fcf066b14582bab2e22029878473.png)

prometheus 是 up 状态，表示安装启动成功。

<br>
## 2.2 Grafana 安装
### 2.2.1 上传并解压
（1）将 grafana-7.5.2.linux-amd64.tar.gz 上传至/opt/software/目录下，解压：
```
tar -zxvf grafana-7.5.2.linux-amd64.tar.gz -C /opt/module/
```
（2）更改名字：
```
mv grafana-7.5.2.linux-amd64 grafana-7.5.2
```

###2.2.2 启动 Grafana
```
nohup ./bin/grafana-server web > ./grafana.log 2>&1 &
```
访问UI页面：http://hadoop1:3000 
默认用户名和密码：admin


<br>
# 三、ClickHouse 配置
## 3.1 修改配置文件
编辑/etc/clickhouse-server/config.xml，打开如下配置：
```
<prometheus>
  <endpoint>/metrics</endpoint>
  <port>9363</port>
  <metrics>true</metrics>
  <events>true</events>
  <asynchronous_metrics>true</asynchronous_metrics>
  <status_info>true</status_info>
</prometheus>
```
如果有多个 CH 节点，分发配置。

## 3.2 重启 ClickHouse
```
sudo clickhouse restart
```
Float64 – double
建议尽可能以整数形式存储数据。例如，将固定精度的数字转换为整数值，如时间用毫秒为单位表示，因为浮点型进行计算时可能引起四舍五入的误差。
使用场景：一般数据值比较小，不涉及大量的统计计算，精度要求不高的时候。比如保存商品的重量。

<br>
## 3.3 访问 Web 查看
浏览器打开: http://hadoop1:9363/metrics
看到信息说明 ClickHouse 开启 Metrics 服务成功。

<br>
# 四、Grafana 集成 Prometheus
## 4.1 添加数据源 Prometheus
（1）点击配置，点击 Data Sources：
![image.png](ClickHouse-21-7-监控及备份.assets1b84343b38e4ba0855c1bc29c39815b.png)

<br>
## 4.2 添加监控
如果ClickHouse被Promethues监控正常，那么Metrics browser中就会出现ClickHouse相关的监控指标。
![image.png](ClickHouse-21-7-监控及备份.assetse59316adcd94a9cad7f7f01068faaf4.png)
可以选择并手动添加监控指标。

手动一个个添加 Dashboard 比较繁琐，Grafana 社区鼓励用户分享 Dashboard，通过 https://grafana.com/dashboards 网站，可以找到大量可直接使用的 Dashboard 模板。
Grafana 中所有的 Dashboard 通过 JSON 进行共享，下载并且导入这些 JSON 文件，就可以直接使用这些已经定义好的 Dashboard。
（1）点击左侧 ”+”号，选择 import
（2）点击Upload JSON file，上传下载的JSON文件

<br>
# 五、备份及恢复
官网：https://clickhouse.tech/docs/en/operations/backup/
即使ClickHouse支持副本保证数据的安全性，但是不能预防任务操作失误或bug的情况。
ClickHouse有内置的保护措施可以预防一些错误的发生。如默认开启的不能删除MergeTree引擎超过50G数据的表。
ClickHouse支持数据备份及恢复。
## 5.1 手动实现备份及恢复
ClickHouse 允许使用 ALTER TABLE ... FREEZE PARTITION ... 查询以创建表分区的本地副本。
这是利用硬链接(hardlink)到 /var/lib/clickhouse/shadow/ 文件夹中实现的，所以它通常不会因为旧数据而占用额外的磁盘空间。 创建的文件副本不由 ClickHouse 服务器处理，所以不需要任何额外的外部系统就有一个简单的备份。防止硬件问题，最好将它们远程复制到另一个位置，然后删除本地副本。

### 5.1.1 创建备份路径
创建用于存放备份数据的目录 shadow
```
sudo mkdir -p /var/lib/clickhouse/shadow/
```
>shadow是freeze命令默认的存放路径，可以作为中转站，将数据再转移到备份仓库。

实际就是创建了一个硬链接到 /var/lib/clickhouse/store/ 目录下的表数据的分区文件夹。如下就是备份出来的分区文件夹。
```
drwxr-x---. 2 clickhouse clickhouse 203 8月  19 15:34 20200601_8_8_0
drwxr-x---. 2 clickhouse clickhouse 203 8月  19 15:34 20200602_9_9_0
drwxr-x---. 2 clickhouse clickhouse 203 8月  19 15:34 20200604_10_10_0
```

### 5.1.2 执行备份命令
```
alter table t_order_mt freeze;
```

### 5.1.3 将备份数据保存到其他路径
```
#创建备份存储路径
sudo mkdir -p /var/lib/clickhouse/backup/ 

#拷贝数据到备份路径
sudo cp -r /var/lib/clickhouse/shadow/ /var/lib/clickhouse/backup/t_order_mt

#为下次备份准备，删除 shadow 下的数据
sudo rm -rf /var/lib/clickhouse/shadow/*
```

### 5.1.4 恢复数据
（1）模拟删除备份过的表
```
drop table t_order_mt
```
（2）重新创建表
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
（3）将备份复制到 detached 目录
```
cp -rl /var/lib/clickhouse/backup/t_order_mt/1/store/ddb/ddb2f9c5-2e1d-43be-9db2-f9c52e1df3be/* /var/lib/clickhouse/data/default/t_order_mt/detached/
```
ClickHouse 使用文件系统硬链接来实现即时备份，而不会导致 ClickHouse 服务停机（或锁定）。这些硬链接可以进一步用于有效的备份存储。在支持硬链接的文件系统（例如本地文件系统或 NFS）上，将 cp 与-l 标志一起使用（或将 rsync 与–hard-links 和–numeric-ids 标志一起使用）以避免复制数据。
`注意：仅拷贝分区目录，注意目录所属的用户要是 clickhouse`

修改用户为clickhouse
```
chown -R clickhouse:clickhouse /var/lib/clickhouse/data/default/t_order_mt/detached
```

（4）执行 attach，恢复分区
```
alter table t_order_mt attach partition 20200601;
```
（5）查看数据
```
select count() from t_order_mt
```
可以看到已经恢复了20200601分区，其他分区恢复同理。

<br>
## 5.2 使用 clickhouse-backup
上面的过程，我们可以使用 Clickhouse 的备份工具 clickhouse-backup 帮我们自动化实现。
工具地址：https://github.com/AlexAkulov/clickhouse-backup/

### 5.2.1 上传并安装
将 clickhouse-backup-1.0.0-1.x86_64.rpm 上传至/opt/software/目录下，安装：
```
sudo rpm -ivh clickhouse-backup-1.0.0-1.x86_64.rpm
```

### 5.2.2 配置文件config.yml
```
general:  # 通用配置
  remote_storage: s3 # 指定远程备份为Amazon S3
  max_file_size: 1099511627776  
  disable_progress_bar: false 
  backups_to_keep_local: 0  # 本地备份保存时间，0表示一直保存
  backups_to_keep_remote: 0 # 远程备份保存时间，0表示一直保存
  log_level: info
  allow_empty_backups: false # false表示空表不备份
clickhouse:  # clickhouse配置
  username: default 
  password: "bigdata123"
  host: bigdata2
  port: 9000
  disk_mapping: {}
  skip_tables: # 不备份的表
  - system.* # 不备份系统表
  timeout: 5m
  freeze_by_part: false # 是否按分区备份
  secure: false
  skip_verify: false
  sync_replicated_tables: true
  skip_sync_replica_timeouts: true
  log_sql_queries: false

# 下面的都是一些远程存储备份配置
s3:
  ......
```
支持的远程仓库有 azblob、s3、gcs、cos、api、ftp、sftp；
如果想备份到hdfs，只能自己手动上传了。

### 5.2.3 创建备份
（1）查看可用命令
```
clickhouse-backup help
```
命令参数如下
```
   tables          Print list of tables
   create          Create new backup
   create_remote   Create and upload
   upload          Upload backup to remote storage
   list            Print list of backups
   download        Download backup from remote storage
   restore         Create schema and restore data from backup
   restore_remote  Download and restore
   delete          Delete specific backup
   default-config  Print default config
   server          Run API server
   help, h         Shows a list of commands or help for one command
```
（2）显示可以备份的表
```
[root@cos-bigdata-hadoop-02 clickhouse-backup]# clickhouse-backup tables;
default.st_order_mt       333B  default  
default.st_order_mt_all2  0B    default  
default.t_order_rep2      642B  default 
```
（3）创建备份
```
sudo clickhouse-backup create
```
--name：指定文件夹名
--table：指定需要备份的表名

>如果不指定名称，备份文件夹会以当前时间为文件名，存储到/var/lib/clickhouse/backup文件夹中。这个备份比我们自己手动备份的内容更全，包括了表的数据和元数据还有备份详细信息metadata.json，所以如果表删除了，也能自动恢复。
>```
>[root@cos-bigdata-hadoop-02 2021-08-19T09-08-12]# ll
>总用量 4
>drwxr-x---. 3 clickhouse clickhouse  21 8月  19 17:08 metadata
>-rw-r-----. 1 clickhouse clickhouse 606 8月  19 17:08 metadata.json
>drwxr-x---. 3 clickhouse clickhouse  21 8月  19 17:08 shadow
>```

（4）查看现有的本地备份
```
sudo clickhouse-backup list
```

备份存储在中/var/lib/clickhouse/backup/BACKUPNAME。备份名称默认为时间戳，但是可以选择使用–name 标志指定备份名称。备份包含两个目录：一个“metadata”目录，其中包含重新创建架构所需的 DDL SQL 语句；以及一个“shadow”目录，其中包含作为 ALTER TABLE ... FREEZE 操作结果的数据。

### 5.2.4 从备份恢复数据
（1）模拟删除备份过的表
```
drop table t_order_mt;
```
>ClickHouse21.7 版本删除数据时，不会删除store下的数据，所以使用ClickHouse-backup-1.0版本进行恢复时，会报错路径已存在，可能存在版本兼容性问题。

（2）从备份还原
```
sudo clickhouse-backup restore 2021-07-25T23-14-50
```
--schema 参数：只还原表结构。
--data 参数：只还原数据。
--table 参数：备份（或还原）特定表。也可以使用一个正则表达式，例如，针对特定的数据库：--table=dbname.*。 

### 5.2.5 其他说明
（1）API 文档：https : //github.com/AlexAkulov/clickhouse-backup#api

（2）注意事项：切勿更改文件夹/var/lib/clickhouse/backup 的权限，可能会导致数据损
坏。

（3）远程备份
- 较新版本才支持，需要设置 config 里的 s3 相关配置
- 上传到远程存储：sudo clickhouse-backup upload xxxx
- 从远程存储下载：sudo clickhouse-backup download xxxx
- 保存周期： backups_to_keep_local，本地保存周期，单位天
backups_to_keep_remote，远程存储保存周期，单位天 
0 均表示不删除。
