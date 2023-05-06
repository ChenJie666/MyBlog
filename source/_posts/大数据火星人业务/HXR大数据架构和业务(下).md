---
title: HXR大数据架构和业务(下)
categories:
- 大数据火星人业务
---


#### 4.2.2.4 ads层

##### 4.2.2.4.1 设备维度

###### 4.2.2.4.1.1 发生频率统计

- 建表
  **ads_q6_device_errorcode_count**

```sql
DROP TABLE IF EXISTS ads_q6_device_errorcode_count;
CREATE EXTERNAL TABLE ads_q6_device_errorcode_count(
`date` string COMMENT '统计日期',
`product_key` string,
`e1_count` bigint,
`e1_amount` bigint,
`e2_count` bigint,
`e2_amount` bigint,
`e3_count` bigint,
`e3_amount` bigint,
`e4_count` bigint,
`e4_amount` bigint,
`e5_count` bigint,
`e5_amount` bigint,
`e6_count` bigint,
`e6_amount` bigint,
`e7_count` bigint,
`e7_amount` bigint,
`e8_count` bigint,
`e8_amount` bigint,
`e9_count` bigint,
`e9_amount` bigint,
`e10_count` bigint,
`e10_amount` bigint,
`e11_count` bigint,
`e11_amount` bigint,
`e12_count` bigint,
`e12_amount` bigint,
`e13_count` bigint,
`e13_amount` bigint,
`e14_count` bigint,
`e14_amount` bigint
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/warehouse/device_model_log/ads/ads_q6_device_errorcode_count';

```

- 导入脚本
  **dwt2ads_device_errorcode_count.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE ads_q6_device_errorcode_count
PARTITION(dt='${do_date}')
SELECT
  '${do_date}',
  product_key,
  sum(e1_count),
  sum(e1_amount),
  sum(e2_count),
  sum(e2_amount),
  sum(e3_count),
  sum(e3_amount),
  sum(e4_count),
  sum(e4_amount),
  sum(e5_count),
  sum(e5_amount),
  sum(e6_count),
  sum(e6_amount),
  sum(e7_count),
  sum(e7_amount),
  sum(e8_count),
  sum(e8_amount),
  sum(e9_count),
  sum(e9_amount),
  sum(e10_count),
  sum(e10_amount),
  sum(e11_count),
  sum(e11_amount),
  sum(e12_count),
  sum(e12_amount),
  sum(e13_count),
  sum(e13_amount),
  sum(e14_count),
  sum(e14_amount)
FROM dwt_q6_user_errorcode_topic
WHERE dt='${do_date}'
GROUP BY product_key;
"

$hive -e "$sql"

```

`以下废弃`

- 建表
  **ads_q6_device_errorcode_count**

```sql
DROP TABLE IF EXISTS ads_q6_device_errorcode_count;
CREATE EXTERNAL TABLE ads_q6_device_errorcode_count(
`dt` string COMMENT '统计日期',
`error_code` string COMMENT '异常类型',
`error_date_first` string COMMENT '异常首次出现时间',
`error_date_last` string COMMENT '异常末次出现时间',
`day_count` bigint COMMENT '当日异常次数',
`week_count` bigint COMMENT '当周异常次数',
`month_count` bigint COMMENT '当月异常次数',
`quarter_count` bigint COMMENT '当季异常次数',
`amount` bigint COMMENT '累计异常次数',
`is_weekend` string COMMENT 'Y表示当天是周末,N表示当天不是周末',
`is_monthend` string COMMENT 'Y表示当天是月末,N表示当天不是月末',
`is_quarterend` string COMMENT 'Y表示当天是季末,N表示当天不是季末'
) 
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/warehouse/device_model_log/ads/ads_q6_device_errorcode_count';

```

- 导入脚本
  **dwt2ads_device_errorcode_count.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT INTO TABLE ads_q6_device_errorcode_count
SELECT 
  '${do_date}',
  daycount.error_code,
  daycount.error_date_first,
  daycount.error_date_last,
  daycount.day_count,
  wkcount.week_count,
  mncount.month_count,
  qtcount.quarter_count,
  daycount.amount,
  if(date_add(next_day('${do_date}','MO'),-1)='${do_date}','Y','N'),
  if(last_day('${do_date}')='${do_date}','Y','N'),
  if(last_day('${do_date}')='${do_date}' and substr('${do_date}',6,2) in (3,6,9,12),'Y','N')
FROM 
(
SELECT 
  error_code,
  error_date_first,
  error_date_last,
  error_day_count day_count,
  error_count amount
FROM dwt_q6_device_errorcode_topic
) daycount
JOIN 
(
SELECT 
  error_code,
  sum(error_count) week_count
FROM dws_q6_device_errorcode_daycount
WHERE dt>=date_add(next_day('${do_date}','MO'),-7) 
GROUP BY error_code
) wkcount ON daycount.error_code=wkcount.error_code
JOIN 
(
SELECT 
  error_code,
  sum(error_count) month_count
FROM dws_q6_device_errorcode_daycount
WHERE date_format(dt,'yyyy-MM')=date_format('${do_date}','yyyy-MM')
GROUP BY error_code
) mncount ON daycount.error_code=mncount.error_code
JOIN 
(
SELECT 
  error_code,
  sum(error_count) quarter_count
FROM dws_q6_device_errorcode_daycount
WHERE substr(dt,6,2) between ceil(substr('${do_date}',6,2)/3)*3-2 and ceil(substr('${do_date}',6,2)/3)*3 
GROUP BY error_code
) qtcount ON daycount.error_code=qtcount.error_code;
"

$hive -e "$sql"
```



##### 4.2.2.4.2 用户维度

###### 4.2.2.4.2.1 发生频率统计

- 建表



- 导入脚本



### 4.2.3 烟机使用统计

#### 4.2.3.1 dwd层

- 建表

**dwd_q6_hoodspeed_log**

```sql
DROP TABLE IF EXISTS dwd_q6_hoodspeed_log;
CREATE EXTERNAL TABLE dwd_q6_hoodspeed_log(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`gmt_create` string,
`device_name` string,
`hood_speed` string,
`event_time` string
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwd/dwd_q6_hoodspeed_log'
TBLPROPERTIES('parquet.compression'='lzo');
```

- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi    

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE ${APP}.dwd_q6_hoodspeed_log
partition(dt='${do_date}')
SELECT 
device_type,
iot_id,
request_id,
check_failed_data,
product_key,
gmt_create,
device_name,
event_value,
event_time
FROM ${APP}.dwd_q6_event_log 
WHERE dt='${do_date}' AND event_name='HoodSpeed';
"

$hive -e "$sql"

```



#### 4.2.3.2 dws层

##### 4.2.3.2.1 设备维度

###### 4.2.3.2.1.1 使用频段统计

- 建表

**dws_q6_device_hoodspeed_daycount**

```sql
DROP TABLE IF EXISTS dws_q6_device_hoodspeed_daycount;
CREATE EXTERNAL TABLE dws_q6_device_hoodspeed_daycount(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`hood_speed` string COMMENT '烟机档位',
`start_count` bigint COMMENT '当日设备烟机总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`mor_count` bigint COMMENT '当日6:00-10:00烟机启动次数统计(跨时段会多次计算)', 
`noo_count` bigint COMMENT '当日10:00-14:00烟机启动次数统计(跨时段会多次计算)',
`eve_count` bigint COMMENT '当日16:00-20:00烟机启动次数统计(跨时段会多次计算)',
`oth_count` bigint COMMENT '当日其他时间段烟机启动次数统计(跨时段会多次计算)'
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dws/dws_q6_user_hoodspeed_daycount';

```

- 导入脚本

  也可以直接从用户维度的表中集合得到结果。

```shell
#!/bin/bash

hive=/opt/module/hive-2.3.6/bin/hive
APP=device_model_log

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;

with
temp as 
(
  SELECT 
    device_type,
    iot_id,
    '' request_id,
    '' check_failed_data,
    product_key,
    device_name,
    hood_speed,
    lag(hood_speed,1,hood_speed) over(partition by iot_id order by event_time) hood_lag_speed,
    event_time,
    from_unixtime(cast(substr(event_time,1,10) as bigint),'H') start_hour
  FROM dwd_q6_hoodspeed_log
  WHERE dt = '${do_date}'
)

INSERT OVERWRITE TABLE dws_q6_user_hoodspeed_daycount
PARTITION(dt='${do_date}')
SELECT 
  concat_ws('|',collect_set(device_type)) device_type,
  concat_ws('|',collect_set(iot_id)) iot_id,
  concat_ws('|',collect_set(request_id)) request_id,
  concat_ws('|',collect_set(check_failed_data)) check_failed_data,
  concat_ws('|',collect_set(product_key)) product_key,
  concat_ws('|',collect_set(device_name)) device_name,
  concat_ws('|',collect_set(hood_speed)) hood_speed,
  count(*) start_count,
  sum(mor) mor_count,
  sum(noo) noo_count,
  sum(eve) eve_count,
  sum(oth) oth_count
FROM 
(
SELECT
  device_type,
  iot_id,
  request_id,
  check_failed_data,
  product_key,
  device_name,
  hood_speed,
  hood_lag_speed,
  event_time,
  start_hour,
  from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H') end_hour,
  if(start_hour<10 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=6,1,0) mor,
  if(start_hour<14 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=10,1,0) noo,
  if(start_hour<20 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=16,1,0) eve,
  if((start_hour<6 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=0) or (start_hour<16 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=14) or (start_hour<24 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=20),1,0) oth
FROM 
(
    SELECT
      device_type,
      iot_id,
      request_id,
      check_failed_data,
      product_key,
      device_name,
      hood_speed,
      hood_lag_speed,
      event_time,
      lead(event_time,1,event_time) over(partition by iot_id order by event_time) event_next_time,
      start_hour
    FROM temp
    WHERE hood_lag_speed>0 and hood_speed>0
) temp1
WHERE hood_speed<>0
) temp2;
"

$hive -e "$sql"

```



###### 4.2.3.2.1.2 使用时间统计

- 建表

**dws_q6_device_hoodspeed_daytime**

```sql
DROP TABLE IF EXISTS dws_q6_device_hoodspeed_daytime;
CREATE EXTERNAL TABLE dws_q6_device_hoodspeed_daytime(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`hood_speed` string COMMENT '烟机档位',
`start_count` bigint COMMENT '当日该档位启动次数统计',
`using_time` bigint COMMENT '当日该档位烟机使用时间统计'
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dws/dws_q6_device_hoodspeed_daytime';

```

- 导入语句

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use ${APP};
set hive.exec.dynamic.partition.mode=nonstrict;
with
temp as 
(
  SELECT 
    device_type,
    iot_id,
    '' request_id,
    '' check_failed_data,
    product_key,
    device_name,
    hood_speed,
    event_time,
    lead(event_time,1,event_time) over(partition by iot_id order by event_time) event_next_time,
    from_unixtime(cast(substr(event_time,1,10) as bigint),'H') start_hour
  FROM dwd_q6_hoodspeed_log
  WHERE dt = '${do_date}'
)

INSERT OVERWRITE TABLE dws_q6_hoodspeed_daytime
PARTITION(dt='${do_date}')
SELECT
  concat_ws('|',collect_set(device_type)) device_type,
  concat_ws('|',collect_set(iot_id)) iot_id,
  concat_ws('|',collect_set(request_id)) request_id,
  concat_ws('|',collect_set(check_failed_data)) check_failed_data,
  concat_ws('|',collect_set(product_key)) product_key,
  concat_ws('|',collect_set(device_name)) device_name,
  hood_speed,
  count(*),
  sum(event_next_time-event_time)/1000 using_time
FROM temp
GROUP BY hood_speed;
"

$hive -e "$sql"

```





##### 4.2.3.2.2 用户维度

###### 4.2.3.2.2.1 使用频段统计

- 建表

**dws_q6_user_hoodspeed_daycount**

```sql
DROP TABLE IF EXISTS dws_q6_user_hoodspeed_daycount;
CREATE EXTERNAL TABLE dws_q6_user_hoodspeed_daycount(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`hood_speed` string COMMENT '烟机档位',
`start_count` bigint COMMENT '当日设备烟机总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`mor_count` bigint COMMENT '当日6:00-10:00烟机启动次数统计(跨时段会多次计算)', 
`noo_count` bigint COMMENT '当日10:00-14:00烟机启动次数统计(跨时段会多次计算)',
`eve_count` bigint COMMENT '当日16:00-20:00烟机启动次数统计(跨时段会多次计算)',
`oth_count` bigint COMMENT '当日其他时间段烟机启动次数统计(跨时段会多次计算)'
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dws/dws_q6_user_hoodspeed_daycount';

```

- 导入脚本

**dwd2dws_user_hoodspeed_count.sh**

思路：获取当前档位的前一档位，过滤掉n——>n的记录，只保留0——>n和n——>0的记录，为了计算出当前档位到下一档位的运行时间，然后过滤掉0——>n的记录，只剩下n——>0的记录。最后通过比较start_hour和end_hour来确定其落入的时段范围(每次启动)。

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use ${APP};
SET hive.exec.dynamic.partition.mode=nonstrict;
with
temp as 
(
  SELECT 
    device_type,
    iot_id,
    '' request_id,
    '' check_failed_data,
    product_key,
    device_name,
    hood_speed,
    lag(hood_speed,1,hood_speed) over(partition by iot_id order by event_time) hood_lag_speed,
    event_time,
    from_unixtime(cast(substr(event_time,1,10) as bigint),'H') start_hour
  FROM dwd_q6_hoodspeed_log
  WHERE dt = '${do_date}'
)

INSERT OVERWRITE TABLE dws_q6_user_hoodspeed_daycount
PARTITION(dt='${do_date}')
SELECT 
  concat_ws('|',collect_set(device_type)) device_type,
  iot_id,
  concat_ws('|',collect_set(request_id)) request_id,
  concat_ws('|',collect_set(check_failed_data)) check_failed_data,
  concat_ws('|',collect_set(product_key)) product_key,
  concat_ws('|',collect_set(device_name)) device_name,
  concat_ws('|',collect_set(hood_speed)) hood_speed,
  count(*) start_count,
  sum(mor) mor_count,
  sum(noo) noo_count,
  sum(eve) eve_count,
  sum(oth) oth_count
FROM 
(
SELECT
  device_type,
  iot_id,
  request_id,
  check_failed_data,
  product_key,
  device_name,
  hood_speed,
  hood_lag_speed,
  event_time,
  start_hour,
  from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H') end_hour,
  if(start_hour<10 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=6,1,0) mor,
  if(start_hour<14 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=10,1,0) noo,
  if(start_hour<20 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=16,1,0) eve,
  if((start_hour<6 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=0) or (start_hour<16 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=14) or (start_hour<24 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=20),1,0) oth
FROM 
(
    SELECT
      device_type,
      iot_id,
      request_id,
      check_failed_data,
      product_key,
      device_name,
      hood_speed,
      hood_lag_speed,
      event_time,
      lead(event_time,1,event_time) over(partition by iot_id order by event_time) event_next_time,
      start_hour
    FROM  temp
    WHERE (hood_lag_speed>0 and hood_speed=0) or (hood_lag_speed=0 and hood_speed>0)
) temp1
WHERE hood_speed<>0
) temp2
GROUP BY iot_id;
"

$hive -e "$sql"

```



###### 4.2.3.2.2.2 使用时间统计

- 建表

**dws_q6_user_hoodspeed_daytime**

思路：通过窗口函数查询同一台设备下一次换挡的时间，然后将时间相减得到该档位运行时间。通过档位分组聚合得到该档位的总使用时间。

```sql
DROP TABLE IF EXISTS dws_q6_user_hoodspeed_daytime;
CREATE EXTERNAL TABLE dws_q6_user_hoodspeed_daytime(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`hood_speed` string COMMENT '烟机档位',
`start_count` bigint COMMENT '当日该档位启动次数统计',
`using_time` string COMMENT '当日该档位烟机使用时间统计'
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dws/dws_q6_user_hoodspeed_daytime';

```

- 导入脚本

**dwd2dws_user_hoodspeed_time.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use ${APP};
set hive.exec.dynamic.partition.mode=nonstrict;
with
temp as 
(
  SELECT 
    device_type,
    iot_id,
    '' request_id,
    '' check_failed_data,
    product_key,
    device_name,
    hood_speed,
    event_time,
    lead(event_time,1,event_time) over(partition by iot_id order by event_time) event_next_time,
    from_unixtime(cast(substr(event_time,1,10) as bigint),'H') start_hour
  FROM dwd_q6_hoodspeed_log
  WHERE dt = '${do_date}'
)

INSERT OVERWRITE TABLE dws_q6_user_hoodspeed_daytime
PARTITION(dt='${do_date}')
SELECT
  concat_ws('|',collect_set(device_type)) device_type,
  iot_id,
  concat_ws('|',collect_set(request_id)) request_id,
  concat_ws('|',collect_set(check_failed_data)) check_failed_data,
  concat_ws('|',collect_set(product_key)) product_key,
  concat_ws('|',collect_set(device_name)) device_name,
  hood_speed,
  count(*),
  cast(sum(event_next_time-event_time)/1000/3600 as decimal(38,3)) using_time
FROM temp
GROUP BY iot_id,hood_speed;
"

$hive -e "$sql"
```



#### 4.2.3.3 dwt层

##### 4.2.3.3.1 设备维度

- 建表

**dwt_q6_device_hoodspeed_topic**

```sql
DROP TABLE IF EXISTS dwt_q6_device_hoodspeed_topic;
CREATE EXTERNAL TABLE dwt_q6_device_hoodspeed_topic(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`start_count` bigint COMMENT '当日设备烟机总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`start_amount` bigint COMMENT '总计设备烟机总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`mor_count` bigint COMMENT '当日6:00-10:00烟机启动次数统计(跨时段会多次计算)', 
`mor_amount` bigint COMMENT '总计6:00-10:00烟机启动次数统计(跨时段会多次计算)',
`noo_count` bigint COMMENT '当日10:00-14:00烟机启动次数统计(跨时段会多次计算)',
`noo_amount` bigint COMMENT '总计10:00-14:00烟机启动次数统计(跨时段会多次计算)',
`eve_count` bigint COMMENT '当日16:00-20:00烟机启动次数统计(跨时段会多次计算)',
`eve_amount` bigint COMMENT '总计16:00-20:00烟机启动次数统计(跨时段会多次计算)',
`oth_count` bigint COMMENT '当日其他时间段烟机启动次数统计(跨时段会多次计算)',
`oth_amount` bigint COMMENT '总计其他时间段烟机启动次数统计(跨时段会多次计算)',
`speed-0_start_count` bigint COMMENT '当日0档位烟机使用次数统计',
`speed-0_start_amount` bigint COMMENT '总计0档位烟机使用次数统计',
`speed-0_using_time` string COMMENT '当日0档位烟机使用时间统计',
`speed-0_using_alltime` string COMMENT '总计0档位烟机使用时间统计',
`speed-1_start_count` bigint COMMENT '当日1档位烟机使用次数统计',
`speed-1_start_amount` bigint COMMENT '总计1档位烟机使用次数统计',
`speed-1_using_time` string COMMENT '当日1档位烟机使用时间统计',
`speed-1_using_alltime` string COMMENT '总计1档位烟机使用时间统计',
`speed-2_start_count` bigint COMMENT '当日2档位烟机使用次数统计',
`speed-2_start_amount` bigint COMMENT '总计2档位烟机使用次数统计',
`speed-2_using_time` string COMMENT '当日2档位烟机使用时间统计',
`speed-2_using_alltime` string COMMENT '总计2档位烟机使用时间统计',
`speed-3_start_count` bigint COMMENT '当日3档位烟机使用次数统计',
`speed-3_start_amount` bigint COMMENT '总计3档位烟机使用次数统计',
`speed-3_using_time` string COMMENT '当日3档位烟机使用时间统计',
`speed-3_using_alltime` string COMMENT '总计3档位烟机使用时间统计'
)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwt/dwt_q6_device_hoodspeed_topic';
```

- 导入脚本

dws2dwt_device_hoodspeed_topic.sh

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict
INSERT INTO TABLE dwt_q6_device_hoodspeed_topic


"

$hive -e "$sql"
```







##### 4.2.3.3.2 用户维度

- 建表

**dwt_q6_user_hoodspeed_topic**

一条记录包含了用户的所有与烟机相关的信息。包括四个时段的使用频段统计和烟机4个档位的使用时长统计。

```sql
DROP TABLE IF EXISTS dwt_q6_user_hoodspeed_topic;
CREATE EXTERNAL TABLE dwt_q6_user_hoodspeed_topic(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`start_count` string COMMENT '当日设备烟机总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`start_amount` string COMMENT '总计设备烟机总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`mor_count` bigint COMMENT '当日6:00-10:00烟机启动次数统计(跨时段会多次计算)', 
`mor_amount` bigint COMMENT '总计6:00-10:00烟机启动次数统计(跨时段会多次计算)',
`noo_count` bigint COMMENT '当日10:00-14:00烟机启动次数统计(跨时段会多次计算)',
`noo_amount` bigint COMMENT '总计10:00-14:00烟机启动次数统计(跨时段会多次计算)',
`eve_count` bigint COMMENT '当日16:00-20:00烟机启动次数统计(跨时段会多次计算)',
`eve_amount` bigint COMMENT '总计16:00-20:00烟机启动次数统计(跨时段会多次计算)',
`oth_count` bigint COMMENT '当日其他时间段烟机启动次数统计(跨时段会多次计算)',
`oth_amount` bigint COMMENT '总计其他时间段烟机启动次数统计(跨时段会多次计算)',
`using30s_count` bigint COMMENT '当日使用30秒内次数统计',
`using30s_amount` bigint COMMENT '总计使用30秒内次数统计',
`using3m_count` bigint COMMENT '当日使用30秒到3分钟内次数统计',
`using3m_amount` bigint COMMENT '总计使用30秒到3分钟内次数统计',
`using5m_count` bigint COMMENT '当日使用3分钟到五分钟内次数统计',
`using5m_amount` bigint COMMENT '总计使用3分钟到五分钟内次数统计',
`speed0_start_count` bigint COMMENT '当日0档位烟机使用次数统计',
`speed0_start_amount` bigint COMMENT '总计0档位烟机使用次数统计',
`speed0_using_time` string COMMENT '当日0档位烟机使用时间统计',
`speed0_using_alltime` string COMMENT '总计0档位烟机使用时间统计',
`speed1_start_count` bigint COMMENT '当日1档位烟机使用次数统计',
`speed1_start_amount` bigint COMMENT '总计1档位烟机使用次数统计',
`speed1_using_time` string COMMENT '当日1档位烟机使用时间统计',
`speed1_using_alltime` string COMMENT '总计1档位烟机使用时间统计',
`speed2_start_count` bigint COMMENT '当日2档位烟机使用次数统计',
`speed2_start_amount` bigint COMMENT '总计2档位烟机使用次数统计',
`speed2_using_time` string COMMENT '当日2档位烟机使用时间统计',
`speed2_using_alltime` string COMMENT '总计2档位烟机使用时间统计',
`speed3_start_count` bigint COMMENT '当日3档位烟机使用次数统计',
`speed3_start_amount` bigint COMMENT '总计3档位烟机使用次数统计',
`speed3_using_time`string COMMENT '当日3档位烟机使用时间统计',
`speed3_using_alltime` string COMMENT '总计3档位烟机使用时间统计'
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwt/dwt_q6_user_hoodspeed_topic';
```

- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;

with 
tmp_daycount as
(
    SELECT
      nvl(new.device_type,old.device_type) device_type,
      nvl(new.iot_id,old.iot_id) iot_id,
      nvl(new.request_id,old.request_id) request_id,
      nvl(new.check_failed_data,old.check_failed_data) check_failed_data,
      nvl(new.product_key,old.product_key) product_key,
      nvl(new.device_name,old.device_name) device_name,
      nvl(new.start_count,0) start_count,
      nvl(new.mor_count,0) mor_count,
      nvl(new.noo_count,0) noo_count,
      nvl(new.eve_count,0) eve_count,
      nvl(new.oth_count,0) oth_count,
      nvl(new.start_count,0)+nvl(old.start_amount,0) start_amount,
      nvl(new.mor_count,0)+nvl(old.mor_amount,0) mor_amount,
      nvl(new.noo_count,0)+nvl(old.noo_amount,0) noo_amount,
      nvl(new.eve_count,0)+nvl(old.eve_amount,0) eve_amount,
      nvl(new.oth_count,0)+nvl(old.oth_amount,0) oth_amount
    FROM 
    (
        SELECT
          device_type,
          iot_id,
          request_id,
          check_failed_data,
          product_key,
          device_name,
          start_count,
          start_amount,
          mor_count,
          mor_amount,
          noo_count,
          noo_amount,
          eve_count,
          eve_amount,
          oth_count,
          oth_amount
        FROM dwt_q6_user_hoodspeed_topic
        WHERE dt=date_add('${do_date}',-1)
    ) old
    FULL OUTER JOIN
    (
        SELECT 
          device_type,
          iot_id,
          '' request_id,
          '' check_failed_data,
          product_key,
          device_name,
          hood_speed,
          start_count,
          mor_count,
          noo_count,
          eve_count,
          oth_count
        FROM dws_q6_user_hoodspeed_daycount
        WHERE dt='${do_date}'
    ) new ON old.iot_id=new.iot_id
),
tmp_daytime as
(
    SELECT
      nvl(new.iot_id,old.iot_id) iot_id,
      nvl(new.speed0_start_count,old.speed0_start_count) speed0_start_count,
      nvl(new.speed0_start_count,0)+nvl(old.speed0_start_amount,0) speed0_start_amount,
      nvl(new.speed0_using_time,old.speed0_using_time) speed0_using_time,
      nvl(new.speed0_using_time,0)+nvl(old.speed0_using_alltime,0) speed0_using_alltime,
      nvl(new.speed1_start_count,old.speed1_start_count) speed1_start_count,
      nvl(new.speed1_start_count,0)+nvl(old.speed1_start_amount,0) speed1_start_amount,
      nvl(new.speed1_using_time,old.speed1_using_time) speed1_using_time,
      nvl(new.speed1_using_time,0)+nvl(old.speed1_using_alltime,0) speed1_using_alltime,
      nvl(new.speed2_start_count,old.speed2_start_count) speed2_start_count,
      nvl(new.speed2_start_count,0)+nvl(old.speed2_start_amount,0) speed2_start_amount,
      nvl(new.speed2_using_time,old.speed2_using_time) speed2_using_time,
      nvl(new.speed2_using_time,0)+nvl(old.speed2_using_alltime,0) speed2_using_alltime,
      nvl(new.speed3_start_count,old.speed3_start_count) speed3_start_count, 
      nvl(new.speed3_start_count,0)+nvl(old.speed3_start_amount,0) speed3_start_amount,
      nvl(new.speed3_using_time,old.speed3_using_time) speed3_using_time,
      nvl(new.speed3_using_time,0)+nvl(old.speed3_using_alltime,0) speed3_using_alltime
    FROM 
    (
        SELECT
         *
        FROM dwt_q6_user_hoodspeed_topic
        WHERE dt=date_add('${do_date}',-1)
    ) old
    FULL OUTER JOIN
    (
        SELECT
          speed0.iot_id,
          speed0.start_count speed0_start_count,
          speed0.using_time speed0_using_time,
          speed1.start_count speed1_start_count,
          speed1.using_time speed1_using_time,
          speed2.start_count speed2_start_count,
          speed2.using_time speed2_using_time,
          speed3.start_count speed3_start_count,
          speed3.using_time speed3_using_time
        FROM 
        (
            SELECT
              iot_id,
              start_count,
              using_time
            FROM dws_q6_user_hoodspeed_daytime
            WHERE dt='${do_date}' AND ood_speed=0
        ) speed0
        JOIN 
        (
            SELECT
              iot_id,
              start_count,
              using_time
            FROM dws_q6_user_hoodspeed_daytime
            WHERE dt='${do_date}' and hood_speed=1 
        ) speed1 ON speed0.iot_id=speed1.iot_id
        JOIN
        (
            SELECT
              iot_id,
              start_count,
              using_time
            FROM dws_q6_user_hoodspeed_daytime
            WHERE dt='${do_date}' AND hood_speed=2
        ) speed2 ON speed0.iot_id=speed2.iot_id
        JOIN
        (
            SELECT
              iot_id,
              start_count,
              using_time
            FROM dws_q6_user_hoodspeed_daytime
            WHERE dt='${do_date}' AND hood_speed=3
        ) speed3 ON speed0.iot_id=speed3.iot_id
    ) new ON old.iot_id=new.iot_id
   
)

INSERT OVERWRITE TABLE dwt_q6_user_hoodspeed_topic
PARTITION(dt='${do_date}')
SELECT
  device_type,
  tmp_daycount.iot_id,
  request_id,
  check_failed_data,
  product_key,
  device_name,
  start_count,
  mor_count,
  noo_count,
  eve_count,
  oth_count,
  start_amount,
  mor_amount,
  noo_amount,
  eve_amount,
  oth_amount,
  using30s_count,
  using30s_amount,
  using3m_count,
  using3m_amount,
  using5m_count,
  using5m_amount,
  speed0_start_count,
  speed0_start_amount,
  speed0_using_time,
  speed0_using_alltime,
  speed1_start_count,
  speed1_start_amount,
  speed1_using_time,
  speed1_using_alltime,
  speed2_start_count,
  speed2_start_amount,
  speed2_using_time,
  speed2_using_alltime,
  speed3_start_count, 
  speed3_start_amount,
  speed3_using_time,
  speed3_using_alltime
FROM tmp_daycount
JOIN tmp_daytime 
ON tmp_daycount.iot_id=tmp_daytime.iot_id;
"

$hive -e "$sql"
```



#### 4.2.3.4 ads层

##### 4.2.3.4.1 设备维度

- 建表

**ads_q6_device_hoodspeed_count**

```sql
DROP TABLE IF EXISTS ads_q6_device_hoodspeed_count;
CREATE EXTERNAL TABLE ads_q6_device_hoodspeed_count(
`date` string,
`product_key` string,
`start_count` bigint COMMENT '当日设备烟机总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`start_amount` bigint COMMENT '总计设备烟机总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`mor_count` bigint COMMENT '当日6:00-10:00烟机启动次数统计(跨时段会多次计算)', 
`mor_amount` bigint COMMENT '总计6:00-10:00烟机启动次数统计(跨时段会多次计算)',
`noo_count` bigint COMMENT '当日10:00-14:00烟机启动次数统计(跨时段会多次计算)',
`noo_amount` bigint COMMENT '总计10:00-14:00烟机启动次数统计(跨时段会多次计算)',
`eve_count` bigint COMMENT '当日16:00-20:00烟机启动次数统计(跨时段会多次计算)',
`eve_amount` bigint COMMENT '总计16:00-20:00烟机启动次数统计(跨时段会多次计算)',
`oth_count` bigint COMMENT '当日其他时间段烟机启动次数统计(跨时段会多次计算)',
`oth_amount` bigint COMMENT '总计其他时间段烟机启动次数统计(跨时段会多次计算)',
`using30s_count` bigint COMMENT '当日使用30秒内次数统计',
`using30s_amount` bigint COMMENT '总计使用30秒内次数统计',
`using3m_count` bigint COMMENT '当日使用30秒到3分钟内次数统计',
`using3m_amount` bigint COMMENT '总计使用30秒到3分钟内次数统计',
`using5m_count` bigint COMMENT '当日使用3分钟到五分钟内次数统计',
`using5m_amount` bigint COMMENT '总计使用3分钟到五分钟内次数统计',
`speed0_start_count` bigint COMMENT '当日0档位烟机使用次数统计',
`speed0_start_amount` bigint COMMENT '总计0档位烟机使用次数统计',
`speed0_using_time` string COMMENT '当日0档位烟机使用时间统计',
`speed0_using_alltime` string COMMENT '总计0档位烟机使用时间统计',
`speed1_start_count` bigint COMMENT '当日1档位烟机使用次数统计',
`speed1_start_amount` bigint COMMENT '总计1档位烟机使用次数统计',
`speed1_using_time` string COMMENT '当日1档位烟机使用时间统计',
`speed1_using_alltime` string COMMENT '总计1档位烟机使用时间统计',
`speed2_start_count` bigint COMMENT '当日2档位烟机使用次数统计',
`speed2_start_amount` bigint COMMENT '总计2档位烟机使用次数统计',
`speed2_using_time` string COMMENT '当日2档位烟机使用时间统计',
`speed2_using_alltime` string COMMENT '总计2档位烟机使用时间统计',
`speed3_start_count` bigint COMMENT '当日3档位烟机使用次数统计',
`speed3_start_amount` bigint COMMENT '总计3档位烟机使用次数统计',
`speed3_using_time` string COMMENT '当日3档位烟机使用时间统计',
`speed3_using_alltime` string COMMENT '总计3档位烟机使用时间统计'
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/warehouse/device_model_log/ads/ads_q6_device_hoodspeed_count';
```

- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE ads_q6_device_hoodspeed_count
PARTITION(dt='${do_date}')
SELECT
'${do_date}',
product_key,
sum(start_count),
sum(start_amount),
sum(mor_count),
sum(mor_amount),
sum(noo_count),
sum(noo_amount),
sum(eve_count),
sum(eve_amount),
sum(oth_count),
sum(oth_amount),
sum(using30s_count),
sum(using30s_amount),
sum(using3m_count),
sum(using3m_amount),
sum(using5m_count),
sum(using5m_amount),
sum(speed0_start_count),
sum(speed0_start_amount),
cast(sum(speed0_using_time) as decimal(38,3)),
cast(sum(speed0_using_alltime) as decimal(38,3)),
sum(speed1_start_count),
sum(speed1_start_amount),
cast(sum(speed1_using_time) as decimal(38,3)),
cast(sum(speed1_using_alltime) as decimal(38,3)),
sum(speed2_start_count),
sum(speed2_start_amount),
cast(sum(speed2_using_time) as decimal(38,3)),
cast(sum(speed2_using_alltime) as decimal(38,3)),
sum(speed3_start_count),
sum(speed3_start_amount),
cast(sum(speed3_using_time) as decimal(38,3)),
cast(sum(speed3_using_alltime) as decimal(38,3))
FROM dwt_q6_user_hoodspeed_topic
WHERE dt='${do_date}'
GROUP BY product_key
"

$hive -e "$sql"
```





##### 4.2.3.4.2 用户维度

- 建表
- 导入脚本





- 导入脚本

**dws2dwt_hoodspeed_topic.sh**

```shell
dws2dwt
```

**dwt2ads_hoodspeed_count.sh**

```shell

```



#### 4.2.3.5 导出到mysql

```shell
#!/bin/bash

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

mysql_db_name=device_model_log
hive_dir_name=device_model_log

export_data() {
/opt/module/sqoop-1.4.6/bin/sqoop export \
--connect "jdbc:mysql://bigdata3:3306/${mysql_db_name}?useUnicode=true&characterEncoding=utf-8" \
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

export_data "ads_q6_device_hoodspeed_count" "ads_q6_device_hoodspeed_count" $do_date 'date,product_key'

```


### 4.2.4 灶具使用频段统计

#### 4.2.4.1 dwd层

- 建表

**dwd_q6_rstovestatus_log**

```sql
DROP TABLE IF EXISTS dwd_q6_rstovestatus_log;
CREATE EXTERNAL TABLE dwd_q6_rstovestatus_log(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`gmt_create` string,
`device_name` string,
`r_stove_status` string,
`event_time` string
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwd/dwd_q6_rstovestatus_log'
TBLPROPERTIES('parquet.compression'='lzo');

```

**dwd_q6_lstovestatus_log**

```sql
DROP TABLE IF EXISTS dwd_q6_lstovestatus_log;
CREATE EXTERNAL TABLE dwd_q6_lstovestatus_log(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`gmt_create` string,
`device_name` string,
`l_stove_status` string,
`event_time` string
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwd/dwd_q6_lstovestatus_log'
TBLPROPERTIES('parquet.compression'='lzo');

```



- 导入脚本

**dwd2dwd_q6_stovestatus_log.sh**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi    

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE ${APP}.dwd_q6_rstovestatus_log
partition(dt='${do_date}')
SELECT 
device_type,
iot_id,
request_id,
check_failed_data,
product_key,
gmt_create,
device_name,
event_value,
event_time
FROM ${APP}.dwd_q6_event_log 
WHERE dt='${do_date}' AND event_name='RStoveStatus';

INSERT OVERWRITE TABLE ${APP}.dwd_q6_lstovestatus_log
partition(dt='${do_date}')
SELECT 
device_type,
iot_id,
request_id,
check_failed_data,
product_key,
gmt_create,
device_name,
event_value,
event_time
FROM ${APP}.dwd_q6_event_log 
WHERE dt='${do_date}' AND event_name='LStoveStatus';
"

$hive -e "$sql"

```





#### 4.2.4.2 dws层

##### 4.2.4.2.1 设备维度

###### 4.2.4.2.1.1 使用频率统计

- 建表

**dws_q6_user_rstovestatus_daycount**

```sql
DROP TABLE IF EXISTS dws_q6_user_rstovestatus_daycount;
CREATE EXTERNAL TABLE dws_q6_user_rstovestatus_daycount(
device_type string,
iot_id string,
request_id string,
check_failed_data string,
product_key string,
device_name string,
r_stove_status string,
`start_count` bigint COMMENT '累计模式启动次数',
`mor_count` bigint COMMENT '6:00-10:00累计右灶启动次数',
`noo_count` bigint COMMENT '10:00-14:00累计右灶启动次数',
`eve_count` bigint COMMENT '16:00-20:00累计右灶启动次数',
`oth_count` bigint COMMENT '其他时段累计右灶启动次数',
`r_using_time` decimal(38,3) COMMENT '右灶当日使用时间'
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION "/warehouse/device_model_log/dws/dws_q6_user_rstovestatus_daycount";

```

**dws_q6_user_lstovestatus_daycount**

```sql
DROP TABLE IF EXISTS dws_q6_user_lstovestatus_daycount;
CREATE EXTERNAL TABLE dws_q6_user_lstovestatus_daycount(
device_type string,
iot_id string,
request_id string,
check_failed_data string,
product_key string,
device_name string,
l_stove_status string,
`start_count` bigint COMMENT '累计模式启动次数',
`mor_count` bigint COMMENT '6:00-10:00累计左灶启动次数',
`noo_count` bigint COMMENT '10:00-14:00累计左灶启动次数',
`eve_count` bigint COMMENT '16:00-20:00累计左灶启动次数',
`oth_count` bigint COMMENT '其他时段累计左灶启动次数',
`l_using_time` decimal(38,3) COMMENT '左灶当日使用时间'
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION "/warehouse/device_model_log/dws/dws_q6_user_lstovestatus_daycount";

```



- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
with
tempr as
(
SELECT
  device_type,
  iot_id,
  '' request_id,
  '' check_failed_data,
  product_key,
  device_name,
  r_stove_status,
  lag(r_stove_status,1) over(partition by iot_id order by event_time) r_stove_lag_status,
  event_time,
  from_unixtime(cast(substr(event_time,1,10) as bigint),'H') start_hour
FROM dwd_q6_rstovestatus_log
WHERE dt='${do_date}'
)

INSERT OVERWRITE TABLE dws_q6_user_rstovestatus_daycount
PARTITION(dt='${do_date}')
SELECT 
  concat_ws('|',collect_set(device_type)) device_type,
  iot_id,
  concat_ws('|',collect_set(request_id)) request_id,
  concat_ws('|',collect_set(check_failed_data)) check_failed_data,
  concat_ws('|',collect_set(product_key)) product_key,
  concat_ws('|',collect_set(device_name)) device_name,
  concat_ws('|',collect_set(r_stove_status)) r_stove_status,
  count(*) start_count,
  sum(mor) mor_count,
  sum(noo) noo_count,
  sum(eve) eve_count,
  sum(oth) oth_count,
  cast(sum(event_next_time-event_time)/1000/3600 as decimal(38,3)) r_using_time
FROM
(
SELECT
  device_type,
  iot_id,
  request_id,
  check_failed_data,
  product_key,
  device_name,
  r_stove_status,
  r_stove_lag_status,
  event_time,
  event_next_time,
  start_hour,
  from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H') end_hour,
  if(start_hour<10 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=6,1,0) mor,
  if(start_hour<14 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=10,1,0) noo,
  if(start_hour<20 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=16,1,0) eve,
  if((start_hour<6 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=0) or (start_hour<16 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=14) or (start_hour<24 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=20),1,0) oth
FROM 
(
    SELECT
      device_type,
      iot_id,
      request_id,
      check_failed_data,
      product_key,
      device_name,
      r_stove_status,
      r_stove_lag_status,
      event_time,
      lead(event_time,1,event_time) over(partition by iot_id order by event_time) event_next_time,
      start_hour
    FROM  tempr
    WHERE (r_stove_lag_status>0 and r_stove_status=0) or (r_stove_lag_status=0 and r_stove_status>0)
) tempr1
WHERE r_stove_status<>0
) tempr2
GROUP BY iot_id;

with
templ as
(
SELECT
  device_type,
  iot_id,
  '' request_id,
  '' check_failed_data,
  product_key,
  device_name,
  l_stove_status,
  lag(l_stove_status,1) over(partition by iot_id order by event_time) l_stove_lag_status,
  event_time,
  from_unixtime(cast(substr(event_time,1,10) as bigint),'H') start_hour
FROM dwd_q6_lstovestatus_log
WHERE dt='${do_date}'
)

INSERT OVERWRITE TABLE dws_q6_user_lstovestatus_daycount
PARTITION(dt='${do_date}')
SELECT 
  concat_ws('|',collect_set(device_type)) device_type,
  iot_id,
  concat_ws('|',collect_set(request_id)) request_id,
  concat_ws('|',collect_set(check_failed_data)) check_failed_data,
  concat_ws('|',collect_set(product_key)) product_key,
  concat_ws('|',collect_set(device_name)) device_name,
  concat_ws('|',collect_set(l_stove_status)) l_stove_status,
  count(*) start_count,
  sum(mor) mor_count,
  sum(noo) noo_count,
  sum(eve) eve_count,
  sum(oth) oth_count,
  cast(sum(event_next_time-event_time)/1000/3600 as decimal(38,3)) l_using_time
FROM
(
SELECT
  device_type,
  iot_id,
  request_id,
  check_failed_data,
  product_key,
  device_name,
  l_stove_status,
  l_stove_lag_status,
  event_time,
  event_next_time,
  start_hour,
  from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H') end_hour,
  if(start_hour<10 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=6,1,0) mor,
  if(start_hour<14 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=10,1,0) noo,
  if(start_hour<20 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=16,1,0) eve,
  if((start_hour<6 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=0) or (start_hour<16 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=14) or (start_hour<24 and from_unixtime(cast(substr(event_next_time,1,10) as bigint),'H')>=20),1,0) oth
FROM 
(
    SELECT
      device_type,
      iot_id,
      request_id,
      check_failed_data,
      product_key,
      device_name,
      l_stove_status,
      l_stove_lag_status,
      event_time,
      lead(event_time,1,event_time) over(partition by iot_id order by event_time) event_next_time,
      start_hour
    FROM  templ
    WHERE (l_stove_lag_status>0 and l_stove_status=0) or (l_stove_lag_status=0 and l_stove_status>0)
) templ1
WHERE l_stove_status<>0
) templ2
GROUP BY iot_id;
"

$hive -e "$sql"

```



###### 4.2.4.2.1.2 使用时间统计

- 建表

```sql

```



- 导入脚本

```shell

```



##### 4.2.4.2.2 用户维度

###### 4.2.4.2.2.1 使用频率统计

```sql

```



###### 4.2.4.2.2.2 使用时间统计

```shell;

```





#### 4.2.4.3 dwt层

##### 4.2.4.3.1 设备维度

###### 4.2.4.3.1.1 使用频率统计

- 建表
- 导入脚本



###### 4.2.4.3.1.2 使用时间统计

- 建表

```sql

```

- 导入脚本

```shell

```



##### 4.2.4.3.2 用户维度

- 建表

**dwt_q6_user_stovestatus_topic**

```sql
DROP TABLE IF EXISTS dwt_q6_user_stovestatus_topic;
CREATE EXTERNAL TABLE dwt_q6_user_stovestatus_topic(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`r_start_count` string COMMENT '当日设备右灶总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`r_start_amount` string COMMENT '总计设备右灶总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`r_mor_count` bigint COMMENT '当日6:00-10:00右灶启动次数统计(跨时段会多次计算)', 
`r_mor_amount` bigint COMMENT '总计6:00-10:00右灶启动次数统计(跨时段会多次计算)',
`r_noo_count` bigint COMMENT '当日10:00-14:00右灶启动次数统计(跨时段会多次计算)',
`r_noo_amount` bigint COMMENT '总计10:00-14:00右灶启动次数统计(跨时段会多次计算)',
`r_eve_count` bigint COMMENT '当日16:00-20:00右灶启动次数统计(跨时段会多次计算)',
`r_eve_amount` bigint COMMENT '总计16:00-20:00右灶启动次数统计(跨时段会多次计算)',
`r_oth_count` bigint COMMENT '当日其他时间段右灶启动次数统计(跨时段会多次计算)',
`r_oth_amount` bigint COMMENT '总计其他时间段右灶启动次数统计(跨时段会多次计算)',
`l_start_count` string COMMENT '当日设备左灶总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`l_start_amount` string COMMENT '总计设备左灶总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`l_mor_count` bigint COMMENT '当日6:00-10:00左灶启动次数统计(跨时段会多次计算)', 
`l_mor_amount` bigint COMMENT '总计6:00-10:00左灶启动次数统计(跨时段会多次计算)',
`l_noo_count` bigint COMMENT '当日10:00-14:00左灶启动次数统计(跨时段会多次计算)',
`l_noo_amount` bigint COMMENT '总计10:00-14:00左灶启动次数统计(跨时段会多次计算)',
`l_eve_count` bigint COMMENT '当日16:00-20:00左灶启动次数统计(跨时段会多次计算)',
`l_eve_amount` bigint COMMENT '总计16:00-20:00左灶启动次数统计(跨时段会多次计算)',
`l_oth_count` bigint COMMENT '当日其他时间段左灶启动次数统计(跨时段会多次计算)',
`l_oth_amount` bigint COMMENT '总计其他时间段左灶启动次数统计(跨时段会多次计算)',
`r_using_time` decimal(38,3) COMMENT '右灶当日使用时间',
`r_using_alltime` decimal(38,3) COMMENT '右灶总使用时间',
`l_using_time` decimal(38,3) COMMENT '左灶当日使用时间',
`l_using_alltime` decimal(38,3) COMMENT '左灶总使用时间'
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwt/dwt_q6_user_stovestatus_topic';

```

- 导入脚本

**dwt_q6_user_stovestatus_topic**

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict

with
temp_rstove as
(
SELECT 
  nvl(new.device_type,old.device_type) device_type,
  nvl(new.iot_id,old.iot_id) iot_id,
  nvl(new.request_id,old.request_id) request_id,
  nvl(new.check_failed_data,old.check_failed_data) check_failed_data,
  nvl(new.product_key,old.product_key) product_key,
  nvl(new.device_name,old.device_name) device_name,
  nvl(new.start_count,0) r_start_count,
  nvl(new.start_count,0)+nvl(old.r_start_amount,0) r_start_amount,
  nvl(new.mor_count,0) r_mor_count,
  nvl(new.mor_count,0)+nvl(old.r_mor_amount,0) r_mor_amount,
  nvl(new.noo_count,0) r_noo_count,
  nvl(new.noo_count,0)+nvl(old.r_noo_amount,0) r_noo_amount,
  nvl(new.eve_count,0) r_eve_count,
  nvl(new.eve_count,0)+nvl(old.r_eve_amount,0) r_eve_amount,
  nvl(new.oth_count,0) r_oth_count,
  nvl(new.oth_count,0)+nvl(old.r_oth_amount,0) r_oth_amount,
  nvl(new.r_using_time,0) r_using_time,
  nvl(new.r_using_time,0) + nvl(old.r_using_time,0) r_using_alltime
FROM 
    (
    SELECT
      device_type,
      iot_id,
      request_id,
      check_failed_data,
      product_key,
      device_name,
      r_start_amount,
      r_mor_amount,
      r_noo_amount,
      r_eve_amount,
      r_oth_amount,
      r_using_time,
      r_using_alltime
    FROM dwt_q6_user_stovestatus_topic
    WHERE dt=date_sub('${do_date}',1)
    ) old
    FULL OUTER JOIN
    (
    SELECT
      device_type,
      iot_id,
      request_id,
      check_failed_data,
      product_key,
      device_name,
      r_stove_status,
      start_count,
      mor_count,
      noo_count,
      eve_count,
      oth_count,
      r_using_time
    FROM dws_q6_user_rstovestatus_daycount
    WHERE dt='${do_date}'
    ) new ON old.iot_id=new.iot_id
),
temp_lstove as
(
SELECT 
  nvl(new.device_type,old.device_type) device_type,
  nvl(new.iot_id,old.iot_id) iot_id,
  nvl(new.request_id,old.request_id) request_id,
  nvl(new.check_failed_data,old.check_failed_data) check_failed_data,
  nvl(new.product_key,old.product_key) product_key,
  nvl(new.device_name,old.device_name) device_name,
  nvl(new.start_count,0) l_start_count,
  nvl(new.start_count,0)+nvl(old.l_start_amount,0) l_start_amount,
  nvl(new.mor_count,0) l_mor_count,
  nvl(new.mor_count,0)+nvl(old.l_mor_amount,0) l_mor_amount,
  nvl(new.noo_count,0) l_noo_count,
  nvl(new.noo_count,0)+nvl(old.l_noo_amount,0) l_noo_amount,
  nvl(new.eve_count,0) l_eve_count,
  nvl(new.eve_count,0)+nvl(old.l_eve_amount,0) l_eve_amount,
  nvl(new.oth_count,0) l_oth_count,
  nvl(new.oth_count,0)+nvl(old.l_oth_amount,0) l_oth_amount,
  nvl(new.l_using_time,0) l_using_time,
  nvl(new.l_using_time,0) + nvl(old.l_using_time,0) l_using_alltime
FROM 
    (
    SELECT
      device_type,
      iot_id,
      request_id,
      check_failed_data,
      product_key,
      device_name,
      l_start_amount,
      l_mor_amount,
      l_noo_amount,
      l_eve_amount,
      l_oth_amount,
      l_using_time,
      l_using_alltime
    FROM dwt_q6_user_stovestatus_topic
    WHERE dt=date_sub('${do_date}',1)
    ) old
    FULL OUTER JOIN
    (
    SELECT
      device_type,
      iot_id,
      request_id,
      check_failed_data,
      product_key,
      device_name,
      l_stove_status,
      start_count,
      mor_count,
      noo_count,
      eve_count,
      oth_count,
      l_using_time
    FROM dws_q6_user_lstovestatus_daycount
    WHERE dt='${do_date}'
    ) new ON old.iot_id=new.iot_id
)

INSERT OVERWRITE TABLE dwt_q6_user_stovestatus_topic
PARTITION(dt='${do_date}')
SELECT
  concat(temp_rstove.device_type,'-',temp_lstove.device_type),
  temp_lstove.iot_id,
  concat(temp_rstove.request_id,'-',temp_lstove.request_id),
  concat(temp_rstove.check_failed_data,'-',temp_lstove.check_failed_data),
  temp_rstove.product_key,
  concat(temp_rstove.device_name,'-',temp_lstove.device_name),
  r_start_count,
  r_start_amount,
  r_mor_count,
  r_mor_amount,
  r_noo_count,
  r_noo_amount,
  r_eve_count,
  r_eve_amount,
  r_oth_count,
  r_oth_amount,
  l_start_count,
  l_start_amount,
  l_mor_count,
  l_mor_amount,
  l_noo_count,
  l_noo_amount,
  l_eve_count,
  l_eve_amount,
  l_oth_count,
  l_oth_amount,
  r_using_time,
  r_using_alltime,
  l_using_time,
  l_using_alltime
FROM temp_rstove
JOIN temp_lstove ON temp_rstove.iot_id=temp_lstove.iot_id;
"

$hive -e "$sql"

```





#### 4.2.4.4 ads层

##### 4.2.4.4.1 设备维度

- 建表

```sql
DROP TABLE IF EXISTS ads_q6_device_stovestatus_count;
CREATE EXTERNAL TABLE ads_q6_device_stovestatus_count(
`date` string,
`product_key` string,
`r_start_count` bigint COMMENT '当日设备右灶总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`r_start_amount` bigint COMMENT '总计设备右灶总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`r_mor_count` bigint COMMENT '当日6:00-10:00右灶启动次数统计(跨时段会多次计算)', 
`r_mor_amount` bigint COMMENT '总计6:00-10:00右灶启动次数统计(跨时段会多次计算)',
`r_noo_count` bigint COMMENT '当日10:00-14:00右灶启动次数统计(跨时段会多次计算)',
`r_noo_amount` bigint COMMENT '总计10:00-14:00右灶启动次数统计(跨时段会多次计算)',
`r_eve_count` bigint COMMENT '当日16:00-20:00右灶启动次数统计(跨时段会多次计算)',
`r_eve_amount` bigint COMMENT '总计16:00-20:00右灶启动次数统计(跨时段会多次计算)',
`r_oth_count` bigint COMMENT '当日其他时间段右灶启动次数统计(跨时段会多次计算)',
`r_oth_amount` bigint COMMENT '总计其他时间段右灶启动次数统计(跨时段会多次计算)',
`l_start_count` bigint COMMENT '当日设备左灶总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`l_start_amount` bigint COMMENT '总计设备左灶总启动次数统计(启动次数，不是时段启动次数的和，跨时段不会多次计算)',
`l_mor_count` bigint COMMENT '当日6:00-10:00左灶启动次数统计(跨时段会多次计算)', 
`l_mor_amount` bigint COMMENT '总计6:00-10:00左灶启动次数统计(跨时段会多次计算)',
`l_noo_count` bigint COMMENT '当日10:00-14:00左灶启动次数统计(跨时段会多次计算)',
`l_noo_amount` bigint COMMENT '总计10:00-14:00左灶启动次数统计(跨时段会多次计算)',
`l_eve_count` bigint COMMENT '当日16:00-20:00左灶启动次数统计(跨时段会多次计算)',
`l_eve_amount` bigint COMMENT '总计16:00-20:00左灶启动次数统计(跨时段会多次计算)',
`l_oth_count` bigint COMMENT '当日其他时间段左灶启动次数统计(跨时段会多次计算)',
`l_oth_amount` bigint COMMENT '总计其他时间段左灶启动次数统计(跨时段会多次计算)',
`r_using_time` decimal(38,3) COMMENT '右灶当日使用时间',
`r_using_alltime` decimal(38,3) COMMENT '右灶总使用时间',
`l_using_time` decimal(38,3) COMMENT '左灶当日使用时间',
`l_using_alltime` decimal(38,3) COMMENT '左灶总使用时间'
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/warehouse/device_model_log/ads/ads_q6_device_stovestatus_count';

```



- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE ads_q6_device_stovestatus_count
PARTITION(dt='${do_date}')
SELECT
  '${do_date}',
  product_key,
  sum(r_start_count) r_start_count,
  sum(r_start_amount) r_start_amount,
  sum(r_mor_count) r_mor_count,
  sum(r_mor_amount) r_mor_amount,
  sum(r_noo_count) r_noo_count,
  sum(r_noo_amount) r_noo_amount,
  sum(r_eve_count) r_eve_count,
  sum(r_eve_amount) r_eve_amount,
  sum(r_oth_count) r_oth_count,
  sum(r_oth_amount) r_oth_amount,
  sum(l_start_count) l_start_count,
  sum(l_start_amount) l_start_amount,
  sum(l_mor_count) l_mor_count,
  sum(l_mor_amount) l_mor_amount,
  sum(l_noo_count) l_noo_count,
  sum(l_noo_amount) l_noo_amount,
  sum(l_eve_count) l_eve_count,
  sum(l_eve_amount) l_eve_amount,
  sum(l_oth_count) l_oth_count,
  sum(l_oth_amount) l_oth_amount,
  sum(r_using_time) r_using_time,
  sum(r_using_alltime) r_using_alltime,
  sum(l_using_time) l_using_time,
  sum(l_using_alltime) l_using_alltime
FROM dwt_q6_user_stovestatus_topic
WHERE dt='${do_date}'
GROUP BY product_key;
"

$hive -e "$sql"

```



##### 4.2.4.4.2 用户维度







#### 4.2.4.5  导出到mysql

```shell
#!/bin/bash

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

mysql_db_name=device_model_log
hive_dir_name=device_model_log

export_data() {
/opt/module/sqoop-1.4.6/bin/sqoop export \
--connect "jdbc:mysql://bigdata3:3306/${mysql_db_name}?useUnicode=true&characterEncoding=utf-8" \
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

export_data "ads_q6_device_stovestatus_count" "ads_q6_device_stovestatus_count" $do_date 'date,product_key'

```



### 4.2.5 灶定时器使用统计 RStoveTimingState

#### 4.2.5.1 dwd层

- 建表

```sql
DROP TABLE IF EXISTS dwd_q6_rstovetimingstate_log;
CREATE EXTERNAL TABLE dwd_q6_rstovetimingstate_log(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`gmt_create` string,
`device_name` string,
`rstove_timing_state` string,
`event_time` string
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwd/dwd_q6_stovetimingstate_log'
TBLPROPERTIES('parquet.compression'='lzo');

```



- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
set hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE dwd_q6_rstovetimingstate_log
PARTITION(dt='${do_date}')
SELECT
  device_type,
  iot_id,
  request_id,
  check_failed_data,
  product_key,
  gmt_create,
  device_name,
  event_value,
  event_time
FROM dwd_q6_event_log
WHERE event_name='RStoveTimingState' AND dt='${do_date}'
"

$hive -e "$sql"

```





#### 4.2.5.2 dws层

##### 4.2.5.2.1 设备维度

###### 4.2.5.2.1.1 使用频率统计

##### 4.2.5.2.2 用户维度

###### 4.2.5.2.2.1 使用频率统计

- 建表

```sql
DROP TABLE IF EXISTS dws_q6_user_rstovetimingstate_daycount;
CREATE EXTERNAL TABLE dws_q6_user_rstovetimingstate_daycount(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`rstove_timing_state` string,
`state_count` string
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dws/dws_q6_user_rstovetimingstate_daycount';

```



- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
set hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE dws_q6_user_rstovetimingstate_daycount
PARTITION(dt='${do_date}')
SELECT 
  concat_ws('|',collect_set(device_type)) device_type,
  iot_id,
  '' request_id,
  '' check_failed_data,
  concat_ws('|',collect_set(product_key)) product_key,
  concat_ws('|',collect_set(device_name)) device_name,
  rstove_timing_state,
  count(*) state_count
FROM dwd_q6_rstovetimingstate_log
WHERE dt='${do_date}'
GROUP BY iot_id,rstove_timing_state;
"

$hive -e "$sql"

```



#### 4.2.5.3 dwt层

##### 4.2.5.3.1 设备维度

###### 4.2.5.3.1.1 使用频率统计

##### 4.2.5.3.2 用户维度

###### 4.2.5.3.2.1 使用频率统计

- 建表

```sql
DROP TABLE IF EXISTS dwt_q6_user_rstovetimingstate_topic;
CREATE EXTERNAL TABLE dwt_q6_user_rstovetimingstate_topic(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`rstove_timing_start_count` bigint,
`rstove_timing_start_amount` bigint
)
PARTITIONED BY (`dt` string)
LOCATION "/warehouse/device_model_log/dwt/dwt_q6_user_rstovetimingstate_topic";

```



- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
set hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE dwt_q6_user_rstovetimingstate_topic
PARTITION(dt='${do_date}')
SELECT
  nvl(new.device_type,old.device_type) device_type,
  nvl(new.iot_id,old.iot_id) iot_id,
  nvl(new.request_id,old.request_id) request_id,
  nvl(new.check_failed_data,old.check_failed_data) check_failed_data,
  nvl(new.product_key,old.product_key) product_key,
  nvl(new.device_name,old.device_name) device_name,
  nvl(new.state_count,0) rstove_timing_start_count,
  nvl(new.state_count,0)+nvl(old.rstove_timing_start_amount,0) rstove_timing_start_amount
FROM 
(
SELECT
  device_type,
  iot_id,
  request_id,
  check_failed_data,
  product_key,
  device_name,
  rstove_timing_start_amount
FROM dwt_q6_user_rstovetimingstate_topic
WHERE dt=date_sub('${do_date}',1)
) old
FULL OUTER JOIN
(
SELECT
  device_type,
  iot_id,
  request_id,
  check_failed_data,
  product_key,
  device_name,
  state_count
FROM dws_q6_user_rstovetimingstate_daycount
WHERE dt='${do_date}' AND rstove_timing_state='1'
) new ON old.iot_id=new.iot_id
"

$hive -e "$sql"

```



#### 4.2.5.4 ads层

##### 4.2.5.3.1 设备维度

###### 4.2.5.3.1.1 使用频率统计

- 建表

```sql
DROP TABLE IF EXISTS ads_q6_device_rstovetimingstate_count;
CREATE EXTERNAL TABLE ads_q6_device_rstovetimingstate_count(
  `date` string,
  `product_key` string,
  `rstove_timing_start_count` bigint,
  `rstove_timing_start_amount` bigint
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/warehouse/device_model_log/ads/ads_q6_device_rstovetimingstate_count';

```



- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
SET hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE ads_q6_device_rstovetimingstate_count
PARTITION(dt='${do_date}')
SELECT 
  '${do_date}',
  product_key,
  sum(rstove_timing_start_count),
  sum(rstove_timing_start_amount)
FROM dwt_q6_user_rstovetimingstate_topic
WHERE dt='${do_date}'
GROUP BY product_key;
"

$hive -e "$sql"

```



##### 4.2.5.3.2 用户维度

###### 4.2.5.3.2.1 使用频率统计



#### 4.2.5.5  导出到mysql

```shell
#!/bin/bash

if [ -n "$1" ];then
    do_date=$1
else 
    do_date=`date -d '-1 day' +%F`
fi

mysql_db_name=device_model_log
hive_dir_name=device_model_log

export_data() {
/opt/module/sqoop-1.4.6/bin/sqoop export \
--connect "jdbc:mysql://bigdata3:3306/${mysql_db_name}?useUnicode=true&characterEncoding=utf-8" \
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

export_data "ads_q6_device_rstovetimingstate_count" "ads_q6_device_rstovetimingstate_count" $do_date "date,product_key"

```





### 4.2.6 闹钟使用统计 TimingState

#### 4.2.6.1 dwd层

- 建表

```sql
DROP TABLE IF EXISTS dwd_q6_timingstate_log;
CREATE EXTERNAL TABLE dwd_q6_timingstate_log(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`gmt_create` string,
`device_name` string,
`timing_state` string,
`event_time` string
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dwd/dwd_q6_timingstate_log'
TBLPROPERTIES('parquet.compression'='lzo');

```



- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
set hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE dwd_q6_timingstate_log
PARTITION(dt='${do_date}')
SELECT
  device_type,
  iot_id,
  request_id,
  check_failed_data,
  product_key,
  gmt_create,
  device_name,
  event_value,
  event_time
FROM dwd_q6_event_log
WHERE event_name='TimingState' AND dt='${do_date}'
"

$hive -e "$sql"

```





#### 4.2.6.2 dws层

##### 4.2.6.2.1 设备维度

###### 4.2.6.2.1.1 使用频率统计

##### 4.2.6.2.2 用户维度

###### 4.2.6.2.2.1 使用频率统计

- 建表

```sql
DROP TABLE IF EXISTS dws_q6_user_timingstate_daycount;
CREATE EXTERNAL TABLE dws_q6_user_timingstate_daycount(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`timing_state` string,
`state_count` string
)
PARTITIONED BY (`dt` string)
STORED AS parquet
LOCATION '/warehouse/device_model_log/dws/dws_q6_user_timingstate_daycount';

```



- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
set hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE dws_q6_user_timingstate_daycount
PARTITION(dt='${do_date}')
SELECT 
  concat_ws('|',collect_set(device_type)) device_type,
  iot_id,
  '' request_id,
  '' check_failed_data,
  concat_ws('|',collect_set(product_key)) product_key,
  concat_ws('|',collect_set(device_name)) device_name,
  timing_state,
  count(*) state_count
FROM dwd_q6_timingstate_log
WHERE dt='${do_date}'
GROUP BY iot_id,timing_state;
"

$hive -e "$sql"

```



#### 4.2.6.3 dwt层

##### 4.2.6.3.1 设备维度

###### 4.2.6.3.1.1 使用频率统计

##### 4.2.6.3.2 用户维度

###### 4.2.6.3.2.1 使用频率统计

- 建表

```sql
DROP TABLE IF EXISTS dwt_q6_user_timingstate_topic;
CREATE EXTERNAL TABLE dwt_q6_user_timingstate_topic(
`device_type` string,
`iot_id` string,
`request_id` string,
`check_failed_data` string,
`product_key` string,
`device_name` string,
`timing_start_count` bigint,
`timing_start_amount` bigint
)
PARTITIONED BY (`dt` string)
LOCATION "/warehouse/device_model_log/dwt/dwt_q6_user_timingstate_topic";

```



- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
set hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE dwt_q6_user_timingstate_topic
PARTITION(dt='${do_date}')
SELECT
  nvl(new.device_type,old.device_type) device_type,
  nvl(new.iot_id,old.iot_id) iot_id,
  nvl(new.request_id,old.request_id) request_id,
  nvl(new.check_failed_data,old.check_failed_data) check_failed_data,
  nvl(new.product_key,old.product_key) product_key,
  nvl(new.device_name,old.device_name) device_name,
  nvl(new.state_count,0) timing_start_count,
  nvl(new.state_count,0)+nvl(old.timing_start_amount,0) timing_start_amount
FROM 
(
SELECT
  device_type,
  iot_id,
  request_id,
  check_failed_data,
  product_key,
  device_name,
  timing_start_amount
FROM dwt_q6_user_timingstate_topic
WHERE dt=date_sub('${do_date}',1)
) old
FULL OUTER JOIN
(
SELECT
  device_type,
  iot_id,
  request_id,
  check_failed_data,
  product_key,
  device_name,
  state_count
FROM dws_q6_user_timingstate_daycount
WHERE dt='${do_date}' AND timing_state='1'
) new ON old.iot_id=new.iot_id
"

$hive -e "$sql"

```



#### 4.2.6.4 ads层

##### 4.2.6.3.1 设备维度

###### 4.2.6.3.1.1 使用频率统计

- 建表

```sql
DROP TABLE IF EXISTS ads_q6_device_timingstate_count;
CREATE EXTERNAL TABLE ads_q6_device_timingstate_count(
  `date` string,
  `product_key` string,
  `timing_start_count` bigint,
  `timing_start_amount` bigint
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/warehouse/device_model_log/ads/ads_q6_device_timingstate_count';

```



- 导入脚本

```shell
#!/bin/bash

APP=device_model_log
hive=/opt/module/hive-2.3.6/bin/hive

if [ -n "$1" ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

sql="
use $APP;
set hive.exec.dynamic.partition.mode=nonstrict;

INSERT OVERWRITE TABLE ads_q6_device_timingstate_count
PARTITION(dt='${do_date}')
SELECT 
  '${do_date}',
  product_key,
  sum(timing_start_count),
  sum(timing_start_amount)
FROM dwt_q6_user_timingstate_topic
WHERE dt='${do_date}'
GROUP BY product_key;
"

$hive -e "$sql"

```



##### 4.2.6.3.2 用户维度

###### 4.2.6.3.2.1 使用频率统计



#### 4.2.6.5  导出到mysql





# 五、导入业务数据

## 5.1 导入用户表

```shell
#!/bin/bash

sqoop=/opt/module/sqoop-1.4.6/bin

mysql_db_name=hifun_user
APP=device_model_log

if [ -n '$1' ];then
    do_date=$1
else
    do_date=`date -d '-1 day' +%F`
fi

import_data(){
$sqoop import \
--connect jdbc:mysql://121.196.18.219:41401/${mysql_db_name} \
--username fayfox \
--password TEqwk9diD4RXeW7f \
--target-dir /origin_data/${APP}/db/user_info/${do_date} \
--delete-target-dir \
--query "$1 and \$CONDITIONS" \
--num-mappers 1 \
--fields-terminated-by '	' \
--compress \
--compression-codec lzop \
--null-string '\N' \
--null-non-string '\N'

hadoop jar /opt/module/hadoop-2.7.2/share/hadoop/common/hadoop-lzo-0.4.20.jar com.hadoop.compression.lzo.DistributedLzoIndexer /origin_data/${APP}/db/user_info/${do_date}
}

import_user_info(){
    import_data "SELECT * FROM users"
}

```

用户信息表ods_user_info

```sql
DROP TABLE IF EXISTS ods_user_info;
CREATE EXTERNAL TABLE ods_user_info(
`id` string COMMENT '用户id',
`username` string COMMENT '用户名',
`password` string COMMENT '密码',
`state` string COMMENT '用户状态',
`mobile` string COMMENT '手机号码',
`nickname` string COMMENT '昵称',
`realname` string COMMENT '真名',
`avatar` string COMMENT '头像',
`level_id` string COMMENT '会员等级',
`channel` string COMMENT '注册渠道',
`create_ip` string COMMENT '注册ip',
`create_time` string COMMENT '创建时间',
`update_time` string COMMENT '更新时间',
`delete_time` string COMMENT '删除时间'
)
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS 
  INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/warehouse/device_model_log/ods/user_detail';
```



```shell
LOAD DATA INPATH '/origin_data/${APP}/db/user_info/${do_date}' OVERWRITE INTO TABLE ${APP}.ods_user_info PARTITION(dt='${do_date}');
```
