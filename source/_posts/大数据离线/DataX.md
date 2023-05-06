---
title: DataX
categories:
- 大数据离线
---
# 第1章 DataX简介
## 1.1 DataX概述
	DataX 是阿里巴巴开源的一个异构数据源离线同步工具，致力于实现包括关系型数据库(MySQL、Oracle等)、HDFS、Hive、ODPS、HBase、FTP等各种异构数据源之间稳定高效的数据同步功能。
源码地址：https://github.com/alibaba/DataX
## 1.2 DataX支持的数据源
DataX目前已经有了比较全面的插件体系，主流的RDBMS数据库、NOSQL、大数据计算系统都已经接入，目前支持数据如下图。
| **类型**               | **数据源**        | **Reader(读)** | **Writer(写)** |
| ---------------------- | ----------------- | -------------- | -------------- |
| **RDBMS 关系型数据库** | **MySQL**         | **√**          | **√**          |
|                        | **Oracle**        | **√**          | **√**          |
|                        | **OceanBase**     | **√**          | **√**          |
|                        | **SQLServer**     | **√**          | **√**          |
|                        | **PostgreSQL**    | **√**          | **√**          |
|                        | **DRDS**          | **√**          | **√**          |
|                        | **通用RDBMS**     | **√**          | **√**          |
| **阿里云数仓数据存储** | **ODPS**          | **√**          | **√**          |
|                        | **ADS**           |                | **√**          |
|                        | **OSS**           | **√**          | **√**          |
|                        | **OCS**           | **√**          | **√**          |
| **NoSQL数据存储**      | **OTS**           | **√**          | **√**          |
|                        | **Hbase0.94**     | **√**          | **√**          |
|                        | **Hbase1.1**      | **√**          | **√**          |
|                        | **Phoenix4.x**    | **√**          | **√**          |
|                        | **Phoenix5.x**    | **√**          | **√**          |
|                        | **MongoDB**       | **√**          | **√**          |
|                        | **Hive**          | **√**          | **√**          |
|                        | **Cassandra**     | **√**          | **√**          |
| **无结构化数据存储**   | **TxtFile**       | **√**          | **√**          |
|                        | **FTP**           | **√**          | **√**          |
|                        | **HDFS**          | **√**          | **√**          |
|                        | **Elasticsearch** |                | **√**          |
| **时间序列数据库**     | **OpenTSDB**      | **√**          |                |
|                        | **TSDB**          | **√**          | **√**          |

<br>
# 第2章 DataX架构原理
## 2.1 DataX设计理念
为了解决异构数据源同步问题，DataX将复杂的网状的同步链路变成了星型数据链路，DataX作为中间传输载体负责连接各种数据源。当需要接入一个新的数据源的时候，只需要将此数据源对接到DataX，便能跟已有的数据源做到无缝数据同步。

![image.png](DataX.assets53a7289a1f440c6b6a26bbf8757e478.png)


## 2.2 DataX框架设计
DataX本身作为离线数据同步框架，采用Framework + plugin架构构建。将数据源读取和写入抽象成为Reader/Writer插件，纳入到整个同步框架中。

![image.png](DataX.assets\58f69340773d4c039e072a7578caf91f.png)


- Reader：数据采集模块，负责采集数据源的数据，将数据发送给Framework。
- Writer：数据写入模块，负责不断向Framework取数据，并将数据写入到目的端。
- Framework：用于连接reader和writer，作为两者的数据传输通道，并处理缓冲，流控，并发，数据转换等核心技术问题。


## 2.3 DataX运行流程
下面用一个DataX作业生命周期的时序图说明DataX的运行流程、核心概念以及每个概念之间的关系。

![image.png](DataX.assets2db7eea31e54893afd25ed298f01efb.png)


- Job：单个数据同步的作业，称为一个Job，一个Job启动一个进程。
Task根据不同数据源的切分策略：一个Job会切分为多个Task，Task是Datax作业的最小单元，每个Task负责一部分数据的同步工作。
- TaskGroup：Schedule调度模块会对Task进行分组，每个Task组称为个TaskGroup。每个TaskGroup负责以一定的并发度运行其所分得的Task，单个TaskGroup的并发度为5。
Reader→Channel-→Writer：每个Task启动后，都会固定启动Reader→Channel→Writer的线程来完成同步工作。


## 2.4 DataX调度决策思路
举例来说，用户提交了一个DataX作业，并且配置了总的并发度为20，目的是对一个有100张分表的mysql数据源进行同步。DataX的调度决策思路是：
1）DataX Job根据分库分表切分策略，将同步工作分成100个Task。
2）根据配置的总的并发度20，以及每个Task Group的并发度5，DataX计算共需要分配4个TaskGroup。
3）4个TaskGroup平分100个Task，每一个TaskGroup负责运行25个Task。

## 2.5 DataX与Sqoop对比
| **功能** | **DataX**                    | **Sqoop**                    |
| -------- | ---------------------------- | ---------------------------- |
| 运行模式 | 单进程多线程                 | MR                           |
| 分布式   | 不支持，可以通过调度系统规避 | 支持                         |
| 流控     | 有流控功能                   | 需要定制                     |
| 统计信息 | 已有一些统计，上报需定制     | 没有，分布式的数据收集不方便 |
| 数据校验 | 在core部分有校验功能         | 没有，分布式的数据收集不方便 |
| 监控     | 需要定制                     | 需要定制                     |

<br>
# 第3章 DataX部署
1）下载DataX安装包并上传到hadoop102的/opt/software
下载地址：http://datax-opensource.oss-cn-hangzhou.aliyuncs.com/datax.tar.gz
2）解压datax.tar.gz到/opt/module
```
tar -zxvf datax.tar.gz -C /opt/module/
```
3）自检，执行如下命令
```
python /opt/module/datax/bin/datax.py /opt/module/datax/job/job.json
```
出现如下内容，则表明安装成功
```
……
2021-10-12 21:51:12.335 [job-0] INFO  JobContainer - 
任务启动时刻                    : 2021-10-12 21:51:02
任务结束时刻                    : 2021-10-12 21:51:12
任务总计耗时                    :                 10s
任务平均流量                    :          253.91KB/s
记录写入速度                    :          10000rec/s
读出记录总数                    :              100000
读写失败总数                    :                   0
```

<br>
# 第4章 DataX使用
## 4.1 DataX使用概述
### 4.1.1 DataX任务提交命令
DataX的使用十分简单，用户只需根据自己同步数据的数据源和目的地选择相应的Reader和Writer，并将Reader和Writer的信息配置在一个json文件中，然后执行如下命令提交数据同步任务即可。
```
python bin/datax.py path/to/your/job.json
```
### 4.2.2 DataX配置文件格式
可以使用如下命名查看DataX配置文件模板。
```
python bin/datax.py -r mysqlreader -w hdfswriter
```
配置文件模板如下，json最外层是一个job，job包含setting和content两部分，其中setting用于对整个job进行配置，content用户配置数据源和目的地。

![image.png](DataX.assets\70f8373195ea404581d9378944b2d8a9.png)

Reader和Writer的具体参数可参考官方文档，地址如下：
https://github.com/alibaba/DataX/blob/master/README.md 
![image.png](DataX.assets85298d9a7684fdf9a1e9e5bdf7fa49c.png)

## 4.2 同步MySQL数据到HDFS案例
**案例要求：**同步gmall数据库中base_province表数据到HDFS的/base_province目录
**需求分析：**要实现该功能，需选用MySQLReader和HDFSWriter，MySQLReader具有两种模式分别是TableMode和QuerySQLMode，前者使用table，column，where等属性声明需要同步的数据；后者使用一条SQL查询语句声明需要同步的数据。
下面分别使用两种模式进行演示。

### 4.2.1 MySQLReader之TableMode
**1）编写配置文件**
（1）创建配置文件base_province.json
```
vim /opt/module/datax/job/base_province.json
```
（2）配置文件内容如下
```
{
    "job": {
        "content": [
            {
                "reader": {
                    "name": "mysqlreader",
                    "parameter": {
                        "column": [
                            "id",
                            "name",
                            "region_id",
                            "area_code",
                            "iso_code",
                            "iso_3166_2"
                        ],
                        "where": "id>=3",
                        "connection": [
                            {
                                "jdbcUrl": [
                                    "jdbc:mysql://hadoop102:3306/gmall"
                                ],
                                "table": [
                                    "base_province"
                                ]
                            }
                        ],
                        "password": "000000",
                        "splitPk": "",
                        "username": "root"
                    }
                },
                "writer": {
                    "name": "hdfswriter",
                    "parameter": {
                        "column": [
                            {
                                "name": "id",
                                "type": "bigint"
                            },
                            {
                                "name": "name",
                                "type": "string"
                            },
                            {
                                "name": "region_id",
                                "type": "string"
                            },
                            {
                                "name": "area_code",
                                "type": "string"
                            },
                            {
                                "name": "iso_code",
                                "type": "string"
                            },
                            {
                                "name": "iso_3166_2",
                                "type": "string"
                            }
                        ],
                        "compress": "gzip",
                        "defaultFS": "hdfs://hadoop102:8020",
                        "fieldDelimiter": "	",
                        "fileName": "base_province",
                        "fileType": "text",
                        "path": "/base_province",
                        "writeMode": "append"
                    }
                }
            }
        ],
        "setting": {
            "speed": {
                "channel": 1
            }
        }
    }
}
```

**2）配置文件说明**
（1）Reader参数说明
```
{
	"name": "mysqlreader", Reader名称，固定写法
	"parameter": {
		"username": "root", 数据库用户名
		"password": "000000", 数据库密码
		"connection": [{
			"jdbcUrl": ["jdbc: mysql: //bigdata1:3306/compass"], 数据库JDBC URL
			"table": ["base_province"] 需要同步的表名
		}],
		"column": ["id", "name", "region_id", "area_code", "isocode", "iso_31662"], 需要同步的列，*代表所有列

		"where": "id>=3", where过滤条件
		"splitPk": "" 分片字段，如果指定该字段，则Datax会启动多个Task同步数据；若未指定（不提供splitPk或者splitPk值为空），则只会有有单个Task。该参数只在TableMode下有效，意味着在QuerySQLMode下，只会有单个Task。
	}
}
```
（2）Writer参数说明
```
{
    "name": "hdfswriterWriter", Writer名称，固定写法
    "parameter": {
        "column": [ 列信息，包括列名和类型。类型为Hive表字段类型，目前不支持decimal、binany、arrays、maps、structs等类型。若MySQL数据源中包含decimal类型字段，此处可将该字段类型设置为string，hive表中仍设置为decimal类型
            {
                "name": "id",
                "type": "bigint"
            },
            {
                "name": "name",
                "type": "string"
            },
            {
                ......
            }
        ],
        "defaultFS": "hdfs://bigdata1:8020", HDFS文件系统namenode节点地址
        "path": "/base_province", HDFS文件系统目标路径
        "fileName": "base_province", HDFS文件名前缀
        "fileType": "text", HDFS文件类型，目前支持“text或“orc”
        "compress": "gzip", HDFS压缩类型，text文件支持gzip、bzip2；ore文件支持有NONE、SNAPPY
        "fieldDelimiter": "	", HDFS文件字段分隔符
        "writeMode": "append" 数据写入模式，append：追加：nonConflict:若写入目录有同名（前相同）文件，报错
    }
}
```
**注意事项：**
HFDS Writer并未提供nullFormat参数：也就是用户并不能自定义null值写到HFDS文件中的存储格式。默认情况下，HFDS Writer会将null值存储为空字符串（''），而Hive默认的null值存储格式为\N。所以后期将DataX同步的文件导入Hive表就会出现问题。

解决该问题的方案有两个：
- 一是修改DataX HDFS Writer的源码，增加自定义null值存储格式的逻辑；修改类HdfsHelper的transportOneRecord方法
```
    public static MutablePair<List<Object>, Boolean> transportOneRecord(
            Record record, List<Configuration> columnsConfiguration,
            TaskPluginCollector taskPluginCollector) {
              ......
                    // warn: it's all ok if nullFormat is null
//                    recordList.add(null);

                    // hdfswriter模块中的枚举类Constant中已经定义了null值，直接使用即可；当然灵活点可以不写死null，改用通过参数传入；
                    recordList.add(Constant.DEFAULT_NULL_FORMAT);
              ......
    }
```
- 二是在Hive中建表时指定null值存储格式为空字符串（''），例如：
```
DROP TABLE IF EXISTS base_province;
CREATE EXTERNAL TABLE base_province
(
    `id`         STRING COMMENT '编号',
    `name`       STRING COMMENT '省份名称',
    `region_id`  STRING COMMENT '地区ID',
    `area_code`  STRING COMMENT '地区编码',
    `iso_code`   STRING COMMENT '旧版ISO-3166-2编码，供可视化使用',
    `iso_3166_2` STRING COMMENT '新版IOS-3166-2编码，供可视化使用'
) COMMENT '省份表'
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
    NULL DEFINED AS ''
    LOCATION '/base_province/';
```

（3）Setting参数说明
```
{
    "setting": {
        "speed": {  传输速度配置
            "channel": 1  并发数，最终并发数并不一定是这个数，与查询模式，总/单record限速，总/单byte限速有关
        }
    },
    "errorLimit": { 容错速度配置
        "record": 1, 错误条数上限，超出则任务失败
        "percentage": 0.02 错误比例上限，超出则任务失败
    }
}
```

**3）提交任务**
（1）在HDFS创建/base_province目录
使用DataX向HDFS同步数据时，需确保目标路径已存在
```
hadoop fs -mkdir /base_province
```
（2）进入DataX根目录
```
cd /opt/module/datax 
```
（3）执行如下命令
```
python bin/datax.py job/base_province.json 
```
**4）查看结果**
（1）DataX打印日志
```
2021-10-13 11:13:14.930 [job-0] INFO  JobContainer - 
任务启动时刻                    : 2021-10-13 11:13:03
任务结束时刻                    : 2021-10-13 11:13:14
任务总计耗时                    :                 11s
任务平均流量                    :               66B/s
记录写入速度                    :              3rec/s
读出记录总数                    :                  32
读写失败总数                    :                   0
```
（2）查看HDFS文件
```
hadoop fs -cat /base_province/* | zcat
```

### 4.2.2 MySQLReader之QuerySQLMode
**1）编写配置文件**
（1）修改配置文件base_province.json
```
vim /opt/module/datax/job/base_province.json
```
（2）配置文件内容如下
```
{
    "job": {
        "content": [
            {
                "reader": {
                    "name": "mysqlreader",
                    "parameter": {
                        "connection": [
                            {
                                "jdbcUrl": [
                                    "jdbc:mysql://hadoop102:3306/gmall"
                                ],
                                "querySql": [
                                    "select id,name,region_id,area_code,iso_code,iso_3166_2 from base_province where id>=3"
                                ]
                            }
                        ],
                        "password": "000000",
                        "username": "root"
                    }
                },
                "writer": {
                    "name": "hdfswriter",
                    "parameter": {
                        "column": [
                            {
                                "name": "id",
                                "type": "bigint"
                            },
                            {
                                "name": "name",
                                "type": "string"
                            },
                            {
                                "name": "region_id",
                                "type": "string"
                            },
                            {
                                "name": "area_code",
                                "type": "string"
                            },
                            {
                                "name": "iso_code",
                                "type": "string"
                            },
                            {
                                "name": "iso_3166_2",
                                "type": "string"
                            }
                        ],
                        "compress": "gzip",
                        "defaultFS": "hdfs://hadoop102:8020",
                        "fieldDelimiter": "	",
                        "fileName": "base_province",
                        "fileType": "text",
                        "path": "/base_province",
                        "writeMode": "append"
                    }
                }
            }
        ],
        "setting": {
            "speed": {
                "channel": 1
            }
        }
    }
}
```

2）配置文件说明
（1）Reader参数说明
```
{
	"name": "mysqlreader", Reader名称，固定写法
	"parameter": {
		"username": "root", 数据库用户名
		"password": "000000", 数据库密码
		"connection": [{
			"jdbcUrl": ["jdbc: mysql: //bigdata1:3306/compass"], 数据库JDBC URL
			"querySql": ["select id, name, region_id, area_code, isocode, iso_31662 from base_province where id>=3"] 查询语句
		}]
	}
}
```
3）提交任务
（1）清空历史数据
```
hadoop fs -rm -r -f /base_province/*
```
（2）进入DataX根目录
```
cd /opt/module/datax 
```
（3）执行如下命令
```
python bin/datax.py job/base_province.json
```
4）查看结果
（1）DataX打印日志
```
2021-10-13 11:13:14.930 [job-0] INFO  JobContainer - 
任务启动时刻                    : 2021-10-13 11:13:03
任务结束时刻                    : 2021-10-13 11:13:14
任务总计耗时                    :                 11s
任务平均流量                    :               66B/s
记录写入速度                    :              3rec/s
读出记录总数                    :                  32
读写失败总数                    :                   0
```
（2）查看HDFS文件
```
hadoop fs -cat /base_province/* | zcat
```

### 4.2.3 DataX传参
通常情况下，离线数据同步任务需要每日定时重复执行，故HDFS上的目标路径通常会包含一层日期，以对每日同步的数据加以区分，也就是说每日同步数据的目标路径不是固定不变的，因此DataX配置文件中HDFS Writer的path参数的值应该是动态的。为实现这一效果，就需要使用DataX传参的功能。
DataX传参的用法如下，在JSON配置文件中使用${param}引用参数，在提交任务时使用-p"-Dparam=value"传入参数值，具体示例如下。
1）编写配置文件
（1）修改配置文件base_province.json
```
vim /opt/module/datax/job/base_province.json
```
（2）配置文件内容如下
```
{
    "job": {
        "content": [
            {
                "reader": {
                    "name": "mysqlreader",
                    "parameter": {
                        "connection": [
                            {
                                "jdbcUrl": [
                                    "jdbc:mysql://hadoop102:3306/gmall"
                                ],
                                "querySql": [
                                    "select id,name,region_id,area_code,iso_code,iso_3166_2 from base_province where id>=3"
                                ]
                            }
                        ],
                        "password": "000000",
                        "username": "root"
                    }
                },
                "writer": {
                    "name": "hdfswriter",
                    "parameter": {
                        "column": [
                            {
                                "name": "id",
                                "type": "bigint"
                            },
                            {
                                "name": "name",
                                "type": "string"
                            },
                            {
                                "name": "region_id",
                                "type": "string"
                            },
                            {
                                "name": "area_code",
                                "type": "string"
                            },
                            {
                                "name": "iso_code",
                                "type": "string"
                            },
                            {
                                "name": "iso_3166_2",
                                "type": "string"
                            }
                        ],
                        "compress": "gzip",
                        "defaultFS": "hdfs://hadoop102:8020",
                        "fieldDelimiter": "	",
                        "fileName": "base_province",
                        "fileType": "text",
                        "path": "/base_province/${dt}",
                        "writeMode": "append"
                    }
                }
            }
        ],
        "setting": {
            "speed": {
                "channel": 1
            }
        }
    }
}
```
2）提交任务
（1）创建目标路径
```
hadoop fs -mkdir /base_province/2020-06-14
```
（2）进入DataX根目录
```
cd /opt/module/datax 
```
（3）执行如下命令
```
python bin/datax.py -p"-Ddt=2020-06-14" job/base_province.json
```
3）查看结果
```
hadoop fs -ls /base_province

Found 2 items
drwxr-xr-x   - atguigu supergroup          0 2021-10-15 21:41 /base_province/2020-06-14
```

## 4.3 同步HDFS数据到MySQL案例
案例要求：同步HDFS上的/base_province目录下的数据到MySQL gmall 数据库下的test_province表。
需求分析：要实现该功能，需选用HDFSReader和MySQLWriter。
1）编写配置文件
（1）创建配置文件test_province.json
```
vim /opt/module/datax/job/base_province.json
```
（2）配置文件内容如下
```
{
    "job": {
        "content": [
            {
                "reader": {
                    "name": "hdfsreader",
                    "parameter": {
                        "defaultFS": "hdfs://hadoop102:8020",
                        "path": "/base_province",
                        "column": [
                            "*"
                        ],
                        "fileType": "text",
                        "compress": "gzip",
                        "encoding": "UTF-8",
                        "nullFormat": "\N",
                        "fieldDelimiter": "	",
                    }
                },
                "writer": {
                    "name": "mysqlwriter",
                    "parameter": {
                        "username": "root",
                        "password": "000000",
                        "connection": [
                            {
                                "table": [
                                    "test_province"
                                ],
                                "jdbcUrl": "jdbc:mysql://hadoop102:3306/gmall?useUnicode=true&characterEncoding=utf-8"
                            }
                        ],
                        "column": [
                            "id",
                            "name",
                            "region_id",
                            "area_code",
                            "iso_code",
                            "iso_3166_2"
                        ],
                        "writeMode": "replace"
                    }
                }
            }
        ],
        "setting": {
            "speed": {
                "channel": 1
            }
        }
    }
}
```
2）配置文件说明
（1）Reader参数说明
```
{
    "name": "hdfsreader", Reader名称，固定写法
    "parameter": {
        "defaultFs": "hdfs://hadoop102:8020", HDFS文件系统namenode地址
        "path": "/base_province", 文件所在路径
        "column": [ 需要同步的列，可使用索引选择所需列，例如{"index":0,"type": "long"}，也可以用["*"]标识所有列
            "*"
        ],
        "fileType": "text", 文件类型，目前支持textfile（text）、orcfile（orc）、rcfile（rc）、sequencefile（seq）和csv文件（csv）
        "compress": "gzip", 压缩类型，目前支持gzip、bz2、zip、lzo、lzo_deflate、snappy等
        "encoding": "UTF-8", 文件编码
        "nullFormat": "\N", null值存储格式
        "fieldDelimiter": "t" 字段分隔符
    }
}
```

（2）Writer参数说明
```
{
    "name": "mysqlwriter", Writer名称，固定写法
    "parameter": {
        "username": "root", 数据库用户名
        "password": "000000", 数据库密码
        "connection": [
            {
                "table": [
                    "test_province" 目标表
                ],
                "jdbcUrl": "jdbc:mysql://bigdata1:3306/gmall?useUnicode=true&characterEncoding=utf-8"
            }
        ],
        "column": [
            "rid",
            "name",
            "regionid",
            "area_code",
            "iso_code",
            "jso_31662"
        ],
        "writeMode": "replace" 写入方式：控制写入数据到目标表采用insertinto（insert）或者replace into（replace）或者ONDUPLICATEKEYUPDATE（update）语句

    }
}
```

3）提交任务
（1）在MySQL中创建gmall.test_province表
```
DROP TABLE IF EXISTS `test_province`;
CREATE TABLE `test_province`  (
  `id` bigint(20) NOT NULL,
  `name` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `region_id` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `area_code` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `iso_code` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  `iso_3166_2` varchar(20) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE = InnoDB CHARACTER SET = utf8 COLLATE = utf8_general_ci ROW_FORMAT = Dynamic;
```
（2）进入DataX根目录
```
cd /opt/module/datax 
```
（3）执行如下命令
```
python bin/datax.py job/test_province.json 
```
4）查看结果
（1）DataX打印日志
```
2021-10-13 15:21:35.006 [job-0] INFO  JobContainer - 
任务启动时刻                    : 2021-10-13 15:21:23
任务结束时刻                    : 2021-10-13 15:21:35
任务总计耗时                    :                 11s
任务平均流量                    :               70B/s
记录写入速度                    :              3rec/s
读出记录总数                    :                  34
读写失败总数                    :                   0
```
（2）查看MySQL目标表数据

<br>
#第5章 DataX优化
## 5.1 速度控制
DataX3.0提供了包括通道(并发)、记录流、字节流三种流控模式，可以随意控制你的作业速度，让你的作业在数据库可以承受的范围内达到最佳的同步速度。
关键优化参数如下：
| **参数**                                | **说明**                                            |
| --------------------------------------- | --------------------------------------------------- |
| **job.setting.speed.channel**           | 并发数                                              |
| **job.setting.speed.record**            | 总record限速                                        |
| **job.setting.speed.byte**              | 总byte限速                                          |
| **core.transport.channel.speed.record** | 单个channel的record限速，默认值为10000（10000条/s） |
| **core.transport.channel.speed.byte**   | 单个channel的byte限速，默认值1024*1024（1M/s）      |

注意事项：
1.若配置了总record限速，则必须配置单个channel的record限速
2.若配置了总byte限速，则必须配置单个channe的byte限速
3.若配置了总record限速和总byte限速，channel并发数参数就会失效。因为配置了总record限速和总byte限速之后，实际channel并发数是通过计算得到的,计算公式为:`min(总byte限速/单个channel的byte限速，总record限速/单个channel的record限速)`

**配置示例：**
```
{
    "core": {
        "transport": {
            "channel": {
                "speed": {
                    "byte": 1048576 //单个channel byte限速1M/s
                }
            }
        }
    },
    "job": {
        "setting": {
            "speed": {
                "byte" : 5242880 //总byte限速5M/s
            }
        },
        ...
    }
}
```

>需要注意的是：
>1. Datax只有在**指定splitPk且splitPk不为空**的情况下才会切分多个Task执行并行任务，否则只会启动一个Task任务。
>2. 一致性约束，SqlServer在数据存储划分中属于RDBMS系统，对外可以提供强一致性数据查询接口。例如当一次同步任务启动运行过程中，当该库存在其他数据写入方写入数据时，SqlServerReader完全不会获取到写入更新数据，这是由于数据库本身的快照特性决定的。关于数据库快照特性，请参看[MVCC Wikipedia](https://en.wikipedia.org/wiki/Multiversion_concurrency_control)
上述是在SqlServerReader单线程模型下数据同步一致性的特性，由于SqlServerReader可以根据用户配置信息使用了并发数据抽取，因此不能严格保证数据一致性：当SqlServerReader根据splitPk进行数据切分后，会先后启动多个并发任务完成数据同步。由于多个并发任务相互之间不属于同一个读事务，同时多个并发任务存在时间间隔。因此这份数据并不是`完整的`、`一致的`数据快照信息。
针对多线程的一致性快照需求，在技术上目前无法实现，只能从工程角度解决，工程化的方式存在取舍，我们提供几个解决思路给用户，用户可以自行选择：
①使用单线程同步，即不再进行数据切片。缺点是速度比较慢，但是能够很好保证一致性。
②关闭其他数据写入方，保证当前数据为静态数据，例如，锁表、关闭备库同步等等。缺点是可能影响在线业务。



## 5.2 内存调整
当提升DataX Job内Channel并发数时，内存的占用会显著增加，因为DataX作为数据交换通道，在内存中会缓存较多的数据。例如Channel中会有一个Buffer，作为临时的数据交换的缓冲区，而在部分Reader和Writer的中，也会存在一些Buffer，为了防止OOM等错误，需调大JVM的堆内存。
建议将内存设置为4G或者8G，这个也可以根据实际情况来调整。
调整JVM xms xmx参数的两种方式：
- 一种是直接更改datax.py脚本；
- 另一种是在启动的时候，加上对应的参数，如下：
```
python datax/bin/datax.py --jvm="-Xms8G -Xmx8G" /path/to/your/job.json
```
