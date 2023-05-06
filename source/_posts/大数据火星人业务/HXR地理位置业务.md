---
title: HXR地理位置业务
categories:
- 大数据火星人业务
---
#　一、导入数据
```
#!/bin/bash

sqoop=/opt/module/sqoop-1.4.6/bin/sqoop

mysql_db_name=application_cloud
APP=device_net_info

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

import_data(){
$sqoop import \
--connect "jdbc:mysql://192.168.32.225:3306/${mysql_db_name}?useUnicode=true&characterEncoding=utf-8" \
--username root \
--password hxr \
--target-dir /origin_data/${APP}/db/$3/$2 \
--delete-target-dir \
--query "$1 and \$CONDITIONS" \
--num-mappers 1 \
--fields-terminated-by '	' \
--compress \
--compression-codec lzop \
--null-string '\N' \
--null-non-string '\N'

hadoop jar /opt/module/hadoop-2.7.2/share/hadoop/common/hadoop-lzo-0.4.20.jar com.hadoop.compression.lzo.DistributedLzoIndexer /origin_data/${APP}/db/$3/$2
}

import_data "SELECT * FROM net_info WHERE 1=1" $do_date "net_info"
import_data "SELECT * FROM ip_address_city WHERE 1=1" $do_date "ip_address_city"
```


# 二、分层
## 2.1 ods
### 2.1.1 建库表
CREATE DATABASE device_net_info;
```
DROP TABLE IF EXISTS device_net_info.ods_net_info;
CREATE EXTERNAL TABLE device_net_info.ods_net_info(
`id` string,
`create_time` string,
`device_type` string,
`iot_id` string,
`ip` string,
`mac` string,
`product_key` string,
`update_time` string
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS
  INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/warehouse/device_net_info/ods/ods_net_info';
```

```
DROP TABLE IF EXISTS device_net_info.ods_ip_address_city;
CREATE EXTERNAL TABLE device_net_info.ods_ip_address_city(
`id` string,
`city_code` string,
`city_name` string,
`create_time` string,
`ip` string,
`province_name` string
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS
  INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/warehouse/device_net_info/ods/ods_ip_address_city';
```
### 2.1.2 导入脚本
```
#!/bin/bash

APP=device_net_info

hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else 
    do_date=`date -d '-1 day' +%F`
fi

load_data(){
    sql="LOAD DATA INPATH '/origin_data/${APP}/db/$2/$1' OVERWRITE INTO TABLE ${APP}.ods_net_info partition(dt='${do_date}');"
    $hive -e "$sql"
}

load_data $do_date "net_info"
load_data $do_date "ip_address_city"
```

## 2.2 dwd
### 2.2.1 建表
```
DROP TABLE IF EXISTS device_net_info.dwd_device_city;
CREATE EXTERNAL TABLE device_net_info.dwd_device_city(
`mac` string COMMENT 'mac',
`ip` string COMMENT 'ip地址',
`city_code` string COMMENT '城市编号',
`city_name` string COMMENT '城市名',
`province_name` string COMMENT '省份名',
`iot_id` string COMMENT 'iotid',
`product_key` string COMMENT '设备product_key',
`device_type` string COMMENT '设备类型'
) COMMENT '设备城市表'
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_net_info/dwd/dwd_device_city'
TBLPROPERTIES ("parquet.compression"="lzo");
```

### 2.2.2 导入脚本
```
#!/bin/bash

APP=device_net_info
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE ${APP}.dwd_device_city partition(dt='${do_date}') 
SELECT 
  ni.mac,
  ni.ip,
  iac.city_code,
  iac.city_name,
  iac.province_name,
  ni.iot_id,
  ni.product_key,
  ni.device_type
FROM 
(
SELECT 
  mac,ip,iot_id,product_key,device_type
FROM ods_net_info 
WHERE dt='${do_date}'
) ni 
LEFT JOIN 
(
SELECT 
  ip,city_code,city_name,province_name
FROM ods_ip_address_city iac 
WHERE dt='${do_date}'
) iac
ON ni.ip = iac.ip;"

$hive -e "$sql"
```

## 2.3 dws

## 2.4 dwt

## 2.5 ads
### 2.5.1 建表语句
```
DROP TABLE IF EXISTS device_net_info.ads_device_city;
CREATE EXTERNAL TABLE device_net_info.ads_device_city (
  `city_name` string COMMENT '城市名',
  `province_name` string COMMENT '省份名',
  `device_num` string COMMENT '设备数量'
) COMMENT '城市设备数量表'
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_net_info/ads/device_net_info'
TBLPROPERTIES("parquet.compression"="lzo");
```
### 2.5.2 导入脚本
```
#!/bin/bash

APP=device_net_info
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE ${APP}.ads_device_city PARTITION(dt='$do_date')
SELECT 
  city_name,
  count(*) device_num,
  province_name
FROM dwd_device_city
WHERE dt='$do_date'
GROUP BY province_name,city_name;
"

$hive -e "$sql"
```

# 三、导出到mysql
```
#!/bin/bash

mysql_db_name=device_net_info
hive_dir_name=device_net_info

if [ -n "$1" ];then
  do_date=$1
else
  do_date=`date -d '-1 day' +%F`
fi

export_data(){
/opt/module/sqoop-1.4.6/bin/sqoop export \
--connect "jdbc:mysql://47.114.151.10:3306/${mysql_db_name}?useUnicode=true&characterEncoding=utf-8" \
--username root \
--password hxr \
--table $1 \
--num-mappers 1 \
--hive-partition-key dt \
--hive-partition-value $3 \
--export-dir /warehouse/${hive_dir_name}/ads/$2/dt=$3 \
--input-fields-terminated-by "	" \
--update-mode allowinsert \
--update-key $4 \
--input-null-string '\N' \
--input-null-non-string '\N'
}

export_data "ads_device_city" "ads_device_city" $do_date "date,city_name"
```


# 四、异常记录
## 4.1 问题一
问题：连接Mysql时出现java.math.BigInteger cannot be cast to java.lang.Long
解决：jar包版本过低，更换为5.1.45
