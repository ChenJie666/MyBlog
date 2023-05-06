---
title: HXR-BI-HR
categories:
- 大数据火星人业务
---
# 一、简介
需要帮hr部门统计数据，产出BI报表
表包括
- eEmployee 人员主表  ods_employee
- oDepartment 部门表  ods_department
- oJob 岗位表  ods_job
- eCD_EmpGrade 职等表  ods_ecdempgrade
- ecd_joblevel 职序表  ods_ecdjoblevel
- eCD_Gender 性别表  ods_ecdgender
- eDetails 人员详情表  ods_edetails

# 二、Sqoop导入
从sql server数据库导入
```
#!/bin/bash

# do_date=`date -d '-1 day' +%F`
do_mn=`date -d '-1 month' +'%Y-%m'`
APP=bi_hr

sqoop_import(){
/opt/module/sqoop-1.4.6/bin/sqoop import \
--driver com.microsoft.sqlserver.jdbc.SQLServerDriver \
--connect "jdbc:sqlserver://192.168.33.201:1433; \
username=sa;password=123456;database=hr" \
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

sqoop_import "SELECT * FROM eEmployee WHERE 1=1" "$do_mn" "eEmployee"
sqoop_import "SELECT * FROM oDepartment WHERE 1=1" "$do_mn" "oDepartment"
sqoop_import "SELECT * FROM oJob WHERE 1=1" "$do_mn" "oJob"
sqoop_import "SELECT * FROM eCD_EmpGrade WHERE 1=1" "$do_mn" "eCD_EmpGrade"
sqoop_import "SELECT * FROM ecd_joblevel WHERE 1=1" "$do_mn" "ecd_joblevel"
sqoop_import "SELECT * FROM eCD_Gender WHERE 1=1" "$do_mn" "eCD_Gender"
sqoop_import "SELECT * FROM eDetails WHERE 1=1" "$do_mn" "eDetails"
```


# 三、分层
## 3.1 ods
### 创建表
**eEmployee**
```
DROP TABLE IF EXISTS bi_hr.ods_employee;
CREATE EXTERNAL TABLE bi_hr.ods_employee(
  EID int,
  Badge int,
  Name string,
  EName string,
  CompID int,
  DepID int,
  JobID int,
  ReportTo int,
  wfreportto int,
  EmpStatus int,
  JobStatus int,
  EmpType int,
  EmpGrade int,
  EmpCustom1 int,
  EmpCustom2 int,
  EmpCustom3 int,
  EmpCustom4 int,
  EmpCustom5 int,
  WorkCity int,
  JoinType int,
  JoinDate string,
  WorkBeginDate string,
  JobBeginDate string,
  PracBeginDate string,
  PracTerm int,
  PracEndDate string,
  ProbBeginDate string,
  ProbTerm int,
  ProbEndDate string,
  ConCount int,
  contract int,
  ConType int,
  ConProperty int,
  ConNo string,
  ConBeginDate string,
  ConTerm int,
  ConEndDate string,
  LeaveDate string,
  LeaveType int,
  LeaveReason int,
  Wyear_Adjust decimal(9,2),
  Cyear_Adjust decimal(9,2),
  Country int,
  CertType int,
  CertNo string,
  Gender int,
  BirthDay string,
  email string,
  Mobile string,
  office_phone string,
  EZID int,
  Remark string,
  empcompany int,
  isprac int,
  isprob int,
  isleave int,
  htfujian string,
  Leaveproperty int,
  isSchool int,
  school string,
  joborder int,
  joblevel int,
  isStay int
) COMMENT '人员主表'
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS 
  INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/warehouse/bi_hr/ods/ods_employee';
```
**ODEPARTMENT**
```
DROP TABLE IF EXISTS bi_hr.ods_department;
CREATE EXTERNAL TABLE bi_hr.ods_department(
  DepID int,
  DepCode string,
  Title string,
  DepAbbr string,
  CompID int,
  AdminID int,
  DepGrade int,
  DepType int,
  DepProperty int,
  DepCost int,
  Director int,
  Director2 int,
  DepEmp int,
  DepNum int,
  EffectDate string,
  ISOU tinyint,
  xOrder string,
  isDisabled tinyint,
  DisabledDate string,
  DepCustom1 int,
  DepCustom2 int,
  DepCustom3 int,
  DepCustom4 int,
  DepCustom5 int,
  Remark string,
  EZID int
) COMMENT '部门表'
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS 
  INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/warehouse/bi_hr/ods/ods_department';
```
**ojob**
```
DROP TABLE IF EXISTS bi_hr.ods_job;
CREATE EXTERNAL TABLE bi_hr.ods_job(
  JobID int,
  JobCode string,
  Title string,
  JobAbbr string,
  DepID int,
  AdminID int,
  JobGrade int,
  JobType int,
  JobProperty int,
  Jobnum int,
  isCore tinyint,
  EffectDate string,
  xorder string,
  isDisabled tinyint,
  DisabledDate string,
  Remark string,
  jobcustom1 decimal(18,2),
  jobcustom2 decimal(18,2),
  jobcustom3 decimal(18,2),
  jobcustom4 int,
  jobcustom5 int,
  EZID int,
  xType int
) COMMENT '岗位表'
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS 
  INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/warehouse/bi_hr/ods/ods_job';
```
**ecd_empgrade**
```
DROP TABLE IF EXISTS bi_hr.ods_ecdempgrade;
CREATE EXTERNAL TABLE bi_hr.ods_ecdempgrade(
  ID int,
  Code string,
  Title string,
  xorder int,
  isDisabled tinyint,
  isDefault tinyint,
  Remark string,
  PartyValue decimal(18,2)
) COMMENT '职等表'
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS 
  INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/warehouse/bi_hr/ods/ods_ecdempgrade';
```
**ecd_joblevel**
```
DROP TABLE IF EXISTS bi_hr.ods_ecdjoblevel;
CREATE EXTERNAL TABLE bi_hr.ods_ecdjoblevel(
  id int,
  title string,
  isDisabled tinyint,
  isDefault tinyint,
  Remark string
) COMMENT '职序表'
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS 
  INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/warehouse/bi_hr/ods/ods_ecdjoblevel';
```
**eCD_Gender**
```
DROP TABLE IF EXISTS bi_hr.ods_ecdgender;
CREATE EXTERNAL TABLE bi_hr.ods_ecdgender(
  ID int,
  Code string,
  Title string,
  xorder int,
  isDisabled tinyint,
  isDefault tinyint,
  Remark string
) COMMENT '性别表'
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS 
  INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/warehouse/bi_hr/ods/ods_ecdgender';
```
**eDetails**
```
DROP TABLE IF EXISTS bi_hr.ods_edetails;
CREATE EXTERNAL TABLE bi_hr.ods_edetails(
  EID int,
  BirthPlace string,
  nation int,
  party int,
  partydate string,
  HighLevel int,
  HighDegree int,
  HighTitle int,
  Major string,
  Marriage int,
  Health int,
  Resident int,
  residentAddress string,
  Address string,
  TEL string,
  Postcode string,
  QQ string,
  eMail_pers string,
  Wechart string,
  Weibo string,
  BloodType string,
  Constellation string,
  sfzfujian string,
  place int,
  letteraddress string,
  lastcomaddress string,
  Mobile string,
  email string
) COMMENT '人员详情表'
PARTITIONED BY (`dt` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS 
  INPUTFORMAT 'com.hadoop.mapred.DeprecatedLzoTextInputFormat'
  OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION '/warehouse/bi_hr/ods/ods_edetails';
```

### 导入脚本
```
#!/bin/bash

APP=bi_hr
hive=/opt/module/hive-2.3.6/bin/hive

# do_date=`date -d '-1 day' +%F`
do_mn=`date -d '-1 month' +'%Y-%m'`

load_data(){
  sql="LOAD DATA INPATH '/origin_data/${APP}/db/$2/$1' OVERWRITE INTO TABLE ${APP}.$3 partition(dt='${do_mn}');"
  $hive -e "$sql"
}

load_data $do_mn "eEmployee" "ods_employee"
load_data $do_mn "oDepartment" "ods_department"
load_data $do_mn "oJob" "ods_job"
load_data $do_mn "eCD_EmpGrade" "ods_ecdempgrade"
load_data $do_mn "ecd_joblevel" "ods_ecdjoblevel"
load_data $do_mn "eCD_Gender" "ods_ecdgender"
load_data $do_mn "eDetails" "ods_edetails"
```

## 3.2 dwd
将员工表的所有外键表进行关联，到dwd层

## 3.3 dws
如果有统计指标的，统计后到dws层

## 3.4 dwt

## 3.5 ads
因为缺失部分表，所以先不做dwd层表，直接从ods到ads;

### 3.5.3 新进人员明细表
建表
```
DROP TABLE IF EXISTS bi_hr.ads_entry_employee_detail;
CREATE EXTERNAL TABLE bi_hr.ads_entry_employee_detail (
  `rownub` int COMMENT '序号',
  `month` string COMMENT '统计月份',
  `badge` int COMMENT '工号',
  `name` string COMMENT '姓名',
  `dep` string COMMENT '部门',
  `job` string COMMENT '岗位',
  `joindate` string COMMENT '入职日期',
  `joblevel` string COMMENT '职级',
  `empgrade` int COMMENT '职等',
  `probterm` int COMMENT '试用期限(月)'
) COMMENT '新进人员明细'
PARTITIONED BY (`mn` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
LOCATION '/warehouse/bi_hr/ads/ads_entry_employee_detail';
```
导入脚本
```
#!/bin/bash

hive=/opt/module/hive-2.3.6/bin/hive
APP=bi_hr

if [ -n "$1" ];then
  do_mn=$1
else
  do_mn=`date -d '-1 month' +"%Y-%m"`
fi

sql="
use $APP;
set hive.exec.dynamic.partition.mode=nonstrict;
INSERT OVERWRITE TABLE ads_entry_employee_detail PARTITION(mn='${do_mn}')
SELECT 
    ROW_NUMBER() OVER(),
    '${do_mn}',
    Badge,
    Name,
    dep,
    job,
    joindate,
    joblevel,
    empgrade,
    ProbTerm
FROM
(
    SELECT 
        emp.Badge,
        emp.Name,
        dep.Title dep,
        job.Title job,
        jl.title joblevel,
        dg.title empgrade,
        substring(emp.JoinDate,1,10) joindate,
        emptype,
        substring(emp.ProbBeginDate,1,10) probbegindate,
        substring(emp.ProbEndDate,1,10) probenddate,
        substring(emp.ConBeginDate,1,10) conbegindate,
        substring(emp.ConEndDate,1,10) conenddate,
        substring(emp.LeaveDate,1,10) leavedate,
        emp.LeaveType,
        emp.LeaveReason,
        ProbTerm
    FROM ods_employee emp
    LEFT JOIN ods_department dep
    ON dep.DepID=emp.DepID
    LEFT JOIN ods_job job
    ON job.JobID=emp.JobID
    LEFT JOIN ods_ecdempgrade dg
    ON dg.id=emp.empgrade
    LEFT JOIN ods_ecdjoblevel jl
    ON jl.id=emp.joblevel
) tmp
WHERE substr(tmp.joindate,1,7)='${do_mn}';
"

$hive -e "$sql"

```

导出到mysql
```
#!/bin/bash

if [ -n "$1" ];then
  do_mn=$1
else
  do_mn=`date -d '-1 month' +"%Y-%m"`
fi

mysql_db_name="bi_hr"
hive_dir_name="bi_hr"

export_data(){
/opt/module/sqoop-1.4.6/bin/sqoop export \
--connect "jdbc:mysql://192.168.32.225:3306/${mysql_db_name}?useUnicode=true&characterEncoding=utf-8" \
--username root \
--password hxr \
--table $1 \
--num-mappers 1 \
--hive-partition-key dt \
--hive-partition-value $3 \
--export-dir /warehouse/${hive_dir_name}/ads/$2/mn=$3 \
--input-fields-terminated-by "	" \
--update-mode allowinsert \
--update-key $4 \
--input-null-string '\N' \
--input-null-non-string '\N'
}

export_data "entry_employee_detail" "ads_entry_employee_detail" "$do_mn" "date,badge"
```

### 3.5.4 离职人员明细表
建表
```

```
导入脚本
```

```
