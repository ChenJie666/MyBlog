---
title: Compass-FineDB
categories:
- 大数据火星人业务
---
# 一、需求
## 1.1 目标
开发罗盘1.0，实现企业数据的统计和可视化。

## 1.2 数据表
总部提供数据库表如下
| 表名 | 说明 |
| --- | --- |
| U8_SO_ORDER | 订单 |
| FR_DIM_PRODUCT | 产品 |
| LIKU_STOCK | 库存 |
| U8_SO_SEND | 发货 |
| U8_PRODUCT_SAMPLE | 上样 |

增量表：订单(ddate)、发货(months)、上样(ddate)
全量表：产品、库存

## 1.3 后端所需数据库
| 表名 | 说明 |
| --- | --- |
| ba_device_category | 设备品类表 |
| ba_device_series | 设备系列表 |
| ba_device_type | 设备类型表 |
| ca_sales | 销量表 |
| ca_sales_total | 总销量表 |
| ca_stock | 发样库存表 |

<br>
# 二、建表
## 2.1 原始数据表
```
CREATE DATABASE IF NOT EXISTS fineDB_ori
LOCATION '/origin_data/compass/fineDB';

CREATE EXTERNAL TABLE IF NOT EXISTS fineDB_ori.U8_SO_ORDER(
  cuscode string,
  CDCNAME string,
  CCUSDEFINE8 string,
  CCUSNAME string,
  channel string,
  type string,
  CINVCNAME_REAL string,
  ddate string,
  num int,
  Source string,
  BIG_TYPE string,
  BASIC string,
  CCODE string,
  amount string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/origin_data/compass/fineDB/U8_SO_ORDER';

--------------------------

CREATE EXTERNAL TABLE IF NOT EXISTS fineDB_ori.U8_SO_SEND (
  CDCNAME string,
  CCUSDEFINE8 string,
  CCUSNAME string,
  CINVCODE string,
  CINVCNAME_REAL string,
  months string,
  IQUANTITY int,
  channel string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/origin_data/compass/fineDB/U8_SO_SEND';

-----------------------------

CREATE EXTERNAL TABLE IF NOT EXISTS fineDB_ori.U8_PRODUCT_SAMPLE (
  CDCCODE string,
  CDCNAME string,
  CCUSDEFINE8 string,
  CCUSNAME string,
  CCUSCODE string,
  CINVCODE string,
  CINVCNAME string,
  CINVCNAME_REAL string,
  MIN_DATE string,
  DDATE string,
  IQUANTITY string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/origin_data/compass/fineDB/U8_PRODUCT_SAMPLE';

-----------------------------

CREATE EXTERNAL TABLE IF NOT EXISTS fineDB_ori.LIKU_STOCK (
  CINVCODE string,
  NOW_STOCK bigint,
  USE_STOCK bigint,
  LOCK_STOCK bigint,
  CINVCNAME_REAL string
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/origin_data/compass/fineDB/LIKU_STOCK';

----------------------------

CREATE EXTERNAL TABLE IF NOT EXISTS fineDB_ori.FR_DIM_PRODUCT (
  CINVCNAME_REAL string,
  CHANNEL1 string,
  CHANNEL2 string,
  SERIES string,
  CATEGORY2 string,
  BASIC string,
  CREATOR string,
  CREATE_TIME string, -- sqlserver的datetime是什么类型
  SEQ string,
  PRICE decimal(18,2),
  STATE string,
  CATEGORY1 string,
  START_TIME string,
  YKPH_SALE int
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/origin_data/compass/fineDB/FR_DIM_PRODUCT';
```

## 2.2 ods表
```
CREATE DATABASE IF NOT EXISTS fineDB_ods
LOCATION '/warehouse/compass/fineDB/ods';

CREATE EXTERNAL TABLE IF NOT EXISTS fineDB_ods.U8_SO_ORDER(
  cuscode string,
  CDCNAME string,
  CCUSDEFINE8 string,
  CCUSNAME string,
  channel string,
  type string,
  CINVCNAME_REAL string,
  ddate string,
  num int,
  Source string,
  BIG_TYPE string,
  BASIC string,
  CCODE string,
  amount string
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS parquet
LOCATION '/warehouse/compass/fineDB/ods/U8_SO_ORDER'
TBLPROPERTIES ("parquet.compression"="lzo");

------------------------------

CREATE EXTERNAL TABLE IF NOT EXISTS fineDB_ods.U8_SO_SEND (
  CDCNAME string,
  CCUSDEFINE8 string,
  CCUSNAME string,
  CINVCODE string,
  CINVCNAME_REAL string,
  months string,
  IQUANTITY int,
  channel string
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS parquet
LOCATION '/warehouse/compass/fineDB/ods/U8_SO_SEND'
TBLPROPERTIES ("parquet.compression"="lzo");

------------------------------

CREATE EXTERNAL TABLE IF NOT EXISTS fineDB_ods.U8_PRODUCT_SAMPLE (
  CDCCODE string,
  CDCNAME string,
  CCUSDEFINE8 string,
  CCUSNAME string,
  CCUSCODE string,
  CINVCODE string,
  CINVCNAME string,
  CINVCNAME_REAL string,
  MIN_DATE string,
  DDATE string,
  IQUANTITY string
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS parquet
LOCATION '/warehouse/compass/fineDB/ods/U8_PRODUCT_SAMPLE'
TBLPROPERTIES ("parquet.compression"="lzo");

------------------------------

CREATE EXTERNAL TABLE IF NOT EXISTS fineDB_ods.LIKU_STOCK (
  CINVCODE string,
  NOW_STOCK bigint,
  USE_STOCK bigint,
  LOCK_STOCK bigint,
  CINVCNAME_REAL string
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS parquet
LOCATION '/warehouse/compass/fineDB/ods/LIKU_STOCK'
TBLPROPERTIES ("parquet.compression"="lzo");

------------------------------

CREATE EXTERNAL TABLE IF NOT EXISTS fineDB_ods.FR_DIM_PRODUCT (
  CINVCNAME_REAL string,
  CHANNEL1 string,
  CHANNEL2 string,
  SERIES string,
  CATEGORY2 string,
  BASIC string,
  CREATOR string,
  CREATE_TIME string, -- sqlserver的datetime是什么类型
  SEQ string,
  PRICE decimal(18),
  STATE string,
  CATEGORY1 string,
  START_TIME string,
  YKPH_SALE int
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS parquet
LOCATION '/warehouse/compass/fineDB/ods/FR_DIM_PRODUCT'
TBLPROPERTIES ("parquet.compression"="lzo");
```

## 2.3 ads表
```

```

<br>
# 三、流程
## 3.1 Datax导入hdfs
```
{
  "job": {
    "setting": {
      "speed": {
        "channel": 3,
        "byte": 1048576
      },
      "errorLimit": {
        "record": 0,
        "percentage": 0.02
      }
    },
    "content": [
      {
        "reader": {
          "name": "sqlserverreader",
          "parameter": {
            "username": "KAtgZpcVTxVOWl2MZAaTNQ==",
            "password": "NcjVYxj0O8b9nAHiz4irLQ==",
            "column": [
              "[CINVCNAME_REAL]",
              "[CHANNEL1]",
              "[CHANNEL2]",
              "[SERIES]",
              "[CATEGORY2]",
              "[BASIC]",
              "[CREATOR]",
              "[CREATE_TIME]",
              "[SEQ]",
              "[PRICE]",
              "[STATE]",
              "[CATEGORY1]",
              "[START_TIME]",
              "[YKPH_SALE]"
            ],
            "splitPk": "",
            "connection": [
              {
                "table": [
                  "dbo.FR_DIM_PRODUCT"
                ],
                "jdbcUrl": [
                  "jdbc:sqlserver://192.168.101.62:1433;DatabaseName=DW"
                ]
              }
            ]
          }
        },
        "writer": {
          "name": "hdfswriter",
          "parameter": {
            "defaultFS": "hdfs://192.168.101.179:9820",
            "fileType": "text",
            "path": "/origin_data/compass/fineDB/FR_DIM_PRODUCT",
            "fileName": "FR_DIM_PRODUCT",
            "writeMode": "nonConflict",
            "fieldDelimiter": "	",
            "column": [
              {
                "name": "cinvcname_real",
                "type": "string"
              },
              {
                "name": "channel1",
                "type": "string"
              },
              {
                "name": "channel2",
                "type": "string"
              },
              {
                "name": "series",
                "type": "string"
              },
              {
                "name": "category2",
                "type": "string"
              },
              {
                "name": "basic",
                "type": "string"
              },
              {
                "name": "creator",
                "type": "string"
              },
              {
                "name": "create_time",
                "type": "string"
              },
              {
                "name": "seq",
                "type": "string"
              },
              {
                "name": "price",
                "type": "string"
              },
              {
                "name": "state",
                "type": "string"
              },
              {
                "name": "category1",
                "type": "string"
              },
              {
                "name": "start_time",
                "type": "string"
              },
              {
                "name": "ykph_sale",
                "type": "int"
              }
            ]
          }
        }
      }
    ]
  }
}
```

## 3.2 hdfs导入ods
```
#!/bin/bash

APP=compass
DB=fineDB
DBori=fineDB_ori
hive=/opt/module/hive-3.1.2/bin/hive

if [ -n '$1' ];then
    do_date=`date -d '-1 day' +%F`
else
    do_date=$1
fi

load_data(){
sql="
set hive.exec.dynamic.partition.mode=nonstrict;
use $DB;
INSERT OVERWRITE TABLE $DB.$1 PARTITION(dt='$do_date')
SELECT 
*
FROM $DBori.$1;
"

$hive -e "$sql"

if [ $? -eq 0 ];then
    hadoop fs -rm "/origin_data/compass/fineDB/$1/*"
fi
}

case $1 in
"all")
  load_data FR_DIM_PRODUCT;
  load_data LIKU_STOCK;
  load_data U8_PRODUCT_SAMPLE;
  load_data U8_SO_ORDER;
  load_data U8_SO_SEND;
;;
"FR_DIM_PRODUCT")
load_data FR_DIM_PRODUCT
;;
"LIKU_STOCK")
load_data LIKU_STOCK
;;
"U8_PRODUCT_SAMPLE")
load_data U8_PRODUCT_SAMPLE
;;
"U8_SO_ORDER")
load_data U8_SO_ORDER
;;
"U8_SO_SEND")
load_data U8_SO_SEND
;;
esac
```

## 3.3 ods导入ads
### 3.3.1 表 ba_device_catagory 
```
#!/bin/bash

DB=fineDB_ads
DBori=fineDB_ods
hive=/opt/module/hive-3.1.2/bin/hive

if [ -n "$1" ];then
  do_date=$1
else
  do_date=`date -d '-1 day' +%F`
fi

sql="
use $DB;
set hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE $DB.ba_device_catagory PARTITION(dt='${do_date}')
SELECT case
           when category1 = '燃热' then 'rr'
           when category1 = '嵌电' then 'qd'
           when category1 = '洗碗机' then 'xwj'
           when category1 = '集成灶' then 'jcz'
           when category1 = '水槽' then 'sc'
           else category1
           end   as code,
       category1 as name,
       null,
       null
FROM (
         SELECT distinct category1
         FROM $DBori.fr_dim_product
         WHERE dt = '${do_date}'
     ) tmp_cate;
"

hive -e "$sql"
```

### 3.3.2 表 ba_device_series 
```
#!/bin/bash

DB=fineDB_ads
DBori=fineDB_ods
hive=/opt/module/hive-3.1.2/bin/hive

if [ -n "$1" ];then
  do_date=$1
else
  do_date=`date -d '-1 day' +%F`
fi

sql="
use $DB;
set hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE $DB.ba_device_series PARTITION(dt='${do_date}')
SELECT
       series as code,
       category1 as name,
       null,
       null,
       case
           when category1 = '燃热' then 'rr'
           when category1 = '嵌电' then 'qd'
           when category1 = '洗碗机' then 'xwj'
           when category1 = '集成灶' then 'jcz'
           when category1 = '水槽' then 'sc'
           else category1
           end   as device_category_code
FROM (
         SELECT distinct series, category1
         FROM $DBori.fr_dim_product
         WHERE dt = '${do_date}'
     ) tmp_ser;
"

hive -e "$sql"
```

### 3.3.3 表 ba_device_series 

### 3.3.4 表 ca_sales

### 3.3.5 表 ca_sales_total

### 3.3.6 表 ca_stock

<br>
# 四、调度
## 4.1 Datax调度
每天凌晨3点进行调度。


## 4.2 Azkaban调度
### 4.2.1 任务脚本管理
将任务脚本上传到GitLab仓库中，进行统一管理。

### 4.2.2 测试
通过DataGrip远程连接hive，可以进行SQL语句的测试。
任务脚本编辑完成后，可以将脚本和Azkaban任务流程脚本一同上传到Azkaban UI中进行测试。

### 4.2.3 定时调度
所有SQL和脚本测试完成后，将脚本上传到GitLab仓库中，然后通过Azkaban任务流程脚本将GitLab上的脚本定时clone到本地运行。

```
config:
  user.to.proxy: hxr
  failure.emails: 792965772@qq.com

nodes:
  - name: cloneScript
    type: command
    config:
      command: git clone http://gitlab.iotmars.com/backend/compass/jobscript.git
      retries: 3
      retry.backoff: 5000
      
  - name: hdfs2ods.sh
    type: command
    config:
      command: sh jobscript/hdfs2ods.sh all
      retries: 3
      retry.backoff: 5000
    dependsOn:
      - cloneScript
```
