---
title: Hive基础
categories:
- 大数据离线
---
# 一、Hive基本概念
Hive 是基于 Hadoop 的一个数据仓库工具，可以将结构化的数据文件映射为一张表，并提供类 SQL 查询功能。

本质是：`将 HQL 转化成 MapReduce 程序`

![流程图](Hive基础.assets 8d884ad8e2e44588000befb5f46d6db.png)

**架构原理**
![架构图](Hive基础.assets\3aaeb6ee6a424af9a3f43c7a33458879.png)

- 用户接口(Client)：CLI（hive shell）、JDBC/ODBC(java 访问 hive)、WebUI（浏览器访问 hive）
- 元数据(Metastore)：包括表名、表所属的数据库（默认是 default）、表的拥有者、列/分区字段、表的类型（是否是外部表）、表的数据所在目录等；默认存储在自带的 derby 数据库中，推荐使用 MySQL 存储 Metastore
- Hadoop：使用 HDFS 进行存储，使用 MapReduce 进行计算。
- 驱动器(Driver)：
（1）解析器（SQL Parser）：将 SQL 字符串转换成抽象语法树 AST，这一步一般都用第三方工具库完成，比如 antlr；对 AST 进行语法分析，比如表是否存在、字段是否存在、SQL 语义是否有误。
（2）编译器（Physical Plan）：将 AST 编译生成逻辑执行计划。
（3）优化器（Query Optimizer）：对逻辑执行计划进行优化。
（4）执行器（Execution）：把逻辑执行计划转换成可以运行的物理计划。对于 Hive 来说，就是 MR/Spark。

![运行机制](Hive基础.assets\d231ff52516a4fad8e2695770da06493.png)

Hive 通过给用户提供的一系列交互接口，接收到用户的指令(SQL)，使用自己的 Driver，
结合元数据(MetaStore)，将这些指令翻译成 MapReduce，提交到 Hadoop 中执行，最后，将
执行返回的结果输出到用户交互接口。

<br>
# 二、Hive基本操作
## 2.1 启动hive
启动配置的MySQL，不然会报错
启动metastore和hiveserver2
`nohup ./hive --service metastore &`
`nohup ./hive --service hiveserver2 &`

可以通过`/bin/hive`访问hive客户端，也可以通过beeline远程访问
`bin/beeline`
`beeline> !connect jdbc:hive2://bigdata1:10000`
或直接远程登陆
```
[hxr@bigdata1 bi_hr]$ beeline -u jdbc:hive2://bigdata1:10000 -n hxr -p hxr  --showHeader=false --outputformat=utf-8
```
或直接远程执行命令
```
beeline -u jdbc:hive2://bigdata1:10000 -n hxr -p hxr  --showHeader=false --outputformat=utf-8 -e 'show databases;'
```

<br>
**hive常用的交互命令**
- -e 不进入 hive 的交互窗口执行 sql 语句
`bin/hive -e "select id from student;"`
- -f 执行脚本中 sql 语句
`bin/hive -f /opt/module/datas/hivef.sql`

<br>
**hive基本数据类型**
| Hive数据类型 | Java数据类型 | 长度 | 例子 |
|-----|-----|-----|-----|
| TINYINT | byte | 1byte有符号整数 | 20 |
| SMALLINT | short | 2byte有符号整数 | 20 |
| INT | int | 4byte有符号整数 | 20 | 
| BIGINT | long | 8byte有符号整数 | 20 |
| BOOLEAN | boolean | 布尔类型 | TRUE,FALSE |
| FLOAT | float | 单精度浮点数 | 3.14159 |
| DOUBLE | double | 双精度浮点数 | 3.14159 |
| STRING | string | 字符 | "hello hive" |
| TIMESTAMP |  | 时间类型 |  |
| BINARY |  | 字节数组 |  |
>NOTE：对于 Hive 的 String 类型相当于数据库的 varchar 类型，该类型是一个可变的字符串，不过它不能声明其中最多能存储多少个字符，理论上它可以存储 2GB 的字符数。

<br>
**集合数据类型**
| 数据类型 | 描述 | 语法示例 |
|-----|-----|-----|
| STRUCT |  | struct() |
| MAP |  | map() |
| ARRAY |  | struct() |
Hive 有三种复杂数据类型 ARRAY、MAP 和 STRUCT。ARRAY 和 MAP 与 Java 中的Array 和 Map 类似，而 STRUCT 与 C 语言中的 Struct 类似，它封装了一个命名字段集合，复杂数据类型允许任意层次的嵌套。

[官方官网函数的使用](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+UDF#LanguageManualUDF-Misc.Functions)


**案例实操1**
1） 假设某表有如下一行，我们用 JSON 格式来表示其数据结构。在 Hive 下访问的格式为
```
{
 "name": "songsong",
 "friends": ["bingbing" , "lili"] , //列表 Array, 
 "children": { //键值 Map,
 "xiao song": 18 ,
 "xiaoxiao song": 19
 }
 "address": { //结构 Struct,
 "street": "hui long guan" ,
 "city": "beijing" 
 } }
```

2）基于上述数据结构，我们在 Hive 里创建对应的表，并导入数据。
创建本地测试文件 test.txt
```
songsong,bingbing_lili,xiao song:18_xiaoxiao song:19,hui long 
guan_beijing
yangyang,caicai_susu,xiao yang:18_xiaoxiao yang:19,chao 
yang_beijing
```
注意：MAP，STRUCT 和 ARRAY 里的元素间关系都可以用同一个字符表示，这里用“_”。 

3）Hive 上创建测试表 test
```
create table test(
name string,
friends array<string>,
children map<string, int>,
address struct<street:string, city:string>
)
row format delimited 
fields terminated by ','
collection items terminated by '_'
map keys terminated by ':'
lines terminated by '
';
```
>字段解释：
>row format delimited fields terminated by ',' -- 列分隔符
>collection items terminated by '_' --MAP STRUCT 和 ARRAY 的>>分隔符(数据分割符号)
>map keys terminated by ':' -- MAP 中的 key 与 value 的分隔符
>lines terminated by '
'; -- 行分隔符
>row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'; -- 已经封装完成的序列化和反序列化数据格式;如JsonSerDe，可以按json格式进行切割并将对应key的value值匹配到对应的字段上。


4）导入文本数据到测试表
hive (default)> load data local inpath 
"/opt/module/datas/test.txt" into table test; 5）访问三种集合列里的数据，以下分别是 ARRAY，MAP，STRUCT 的访问方式
```
hive (default)> select friends[1],children['xiao 
song'],address.city from test
where name="songsong";
OK
_c0 _c1 city
lili 18 beijing
Time taken: 0.076 seconds, Fetched: 1 row(s)
```

**案例实操2:将多个字段转化为一个ARRAY<STRUCT<>>字段**
建表
```
DROP TABLE IF EXISTS dim_sku_full;
CREATE EXTERNAL TABLE dim_sku_full
(
    `id`                   STRING COMMENT 'sku_id',
    ......
    `sku_attr_values`      ARRAY<STRUCT<attr_id :STRING,value_id :STRING,attr_name :STRING,value_name:STRING>> COMMENT '平台属性',
    `sku_sale_attr_values` ARRAY<STRUCT<sale_attr_id :STRING,sale_attr_value_id :STRING,sale_attr_name :STRING,sale_attr_value_name:STRING>> COMMENT '销售属性'
) COMMENT '商品维度表'
    PARTITIONED BY (`dt` STRING)
    STORED AS ORC
    LOCATION '/warehouse/gmall/dim/dim_sku_full/'
    TBLPROPERTIES ('orc.compress' = 'snappy');
```
插入数据
```
INSERT OVERWRITE TABLE dim_sku_full
SELECT id,
       ......
       attr as
       (
           select
               sku_id,
               collect_set(named_struct('attr_id',attr_id,'value_id',value_id,'attr_name',attr_name,'value_name',value_name)) attrs
           from ods_sku_attr_value_full
           where dt='2020-06-14'
           group by sku_id
       ),
       sale_attr as
       (
           select
               sku_id,
               collect_set(named_struct('sale_attr_id',sale_attr_id,'sale_attr_value_id',sale_attr_value_id,'sale_attr_name',sale_attr_name,'sale_attr_value_name',sale_attr_value_name)) 
sale_attrs
           from ods_sku_sale_attr_value_full
           where dt='2020-06-14'
           group by sku_id
       )
FROM ......
```

**案例实操3:将多个字段转化为一个Map字段**
```
select id,
       str_to_map(concat_ws(",",collect_set(concat_ws(':', key, value) )) , ',', ':' )
from tmp  
group by id;
```


<br>
**类型转化**
Hive 的原子数据类型是可以进行隐式转换的，类似于 Java 的类型转换，例如某表达式使用 INT 类型，TINYINT 会自动转换为 INT 类型，但是 Hive 不会进行反向转化，例如，某表达式使用 TINYINT 类型，INT 不会自动转换为 TINYINT 类型，它会返回错误，除非使用 CAST 操作。

隐式类型转换规则如下
- 任何整数类型都可以隐式地转换为一个范围更广的类型，如 TINYINT 可以转换 成 INT，INT 可以转换成 BIGINT。
- 所有整数类型、FLOAT 和 STRING 类型都可以隐式地转换成 DOUBLE。
- TINYINT、SMALLINT、INT 都可以转换为 FLOAT。 
- BOOLEAN 类型不可以转换为任何其它的类型。

可以使用 CAST 操作显示进行数据类型转换
`CAST('1' AS INT)`
如果转换失败，返回null。

<br>
## 2.2 DDL
### 2.2.1 数据库操作
**查看数据库**
`show databases;`
`show databases like 'db_hive*';`
**查看数据库详情**
desc database db_hive;
desc database extended db_hive;
**创建数据库**
```
CREATE DATABASE [IF NOT EXISTS] database_name
[COMMENT database_comment]
[LOCATION hdfs_path]
[WITH DBPROPERTIES (property_name=property_value, ...)];
```
**使用数据库**
`use [database_name];`

**修改数据库**
`alter database db_hive set dbproperties('createtime'='20170830');`
**删除空数据库**
`drop database [IF NOT EXISTS] db_hive;`
**数据库不为空，强制删除数据库**
`drop database db_hive cascade;`

**查看建表语句**
show create table fineDB.u8_so_order;

### 2.2.2 表操作
**查看表**  
`show tables;`
**创建表**
```sql
CREATE [EXTERNAL] TABLE [IF NOT EXISTS] table_name 
[(col_name data_type [COMMENT col_comment], ...)] 
[COMMENT table_comment] 
[PARTITIONED BY (col_name data_type          `创建分区表`
[COMMENT col_comment], ...)] 
[CLUSTERED BY (col_name, col_name, ...)     `创建分桶表`
[SORTED BY (col_name [ASC|DESC], ...)] INTO num_buckets BUCKETS]    `对桶中的一个或多个列另外排序`
[ROW FORMAT row_format] 
[STORED AS file_format] 
[LOCATION hdfs_path]      `指定表在HDFS上的存储位置`
[TBLPROPERTIES (property_name=property_value, ...)]
[AS select_statement]
`LIKE允许用户复制现有的表结构，但是不复制数据`
```
**删除表**  
`drop table student;`

**查看表的结构**  
`desc student;`
**查看表的详细信息**
`desc formatted student;`  或  `describe extended student;`
**查看分区表有多少分区**
`show partitions dept_partition;`

**修改内部表为外部表**  
`alter table xxx set tblproperties('external'='true') `
**修改外部表为内部表**  
`alter table xxx set tblproperties('external'='false')`

**增加单个分区**  
`alter table ods_q6_log add partition(dt='2020-06-15');`
**增加多个分区**  
`alter table ods_q6_log add partition(dt='2020-06-15')   partition(dt='2020-06-16');`
**删除单个分区**  
`alter table ods_q6_log drop if exists partition(dt='2020-06-15');`
**删除多个分区**  
`alter table ods_q6_log drop if exists partition(dt='2020-06-15'), partition(dt='2020-06-16');`

**重命名表**   
`alter table xxxx rename to yyyy`

**修改列(修改列类型可能不生效)**  
`alter table xxx change column [col_old_name] [col_new_name] [column_type] comment [col_comment]`
**增加列/替换**
`alter table xxx add/replace columns ([col_name] [data_type] comment [col_comment], ......)`
注：ADD 是代表新增一字段，字段位置在所有列后面(partition 列前)，REPLACE 则是表示替换表中所有字段。

**交换列名（只是交换了元数据的名字，数据对应关系不变）**
alter table student change name name string after nickname;

**增加分区**
hive (default)> alter table dept_partition add partition(month='201705') partition(month='201704');
只会对未创建的分区生效，已创建的分区新插入数据时，该新增列的值还是显示null值。
此时需要删除并重新创建该分区后才能看到刚才新插入的数据的新增列的值，或直接修复表 `msck repair  table user_monthly_detail_i_m`。

**二级分区表**
```
# 创建二级分区表
create table dept_partition2(
deptno int, dname string, loc string
)
partitioned by (month string, day string)
row format delimited fields terminated by '	';
# 导入数据
load data local inpath '/opt/module/datas/dept.txt' into table default.dept_partition2 partition(month='201709', day='13');
```

<br>
## 2.3 DCL

<br>
## 2.4 DML
### 2.4.1 数据导入
- **向表中装载数据（Load）**
```
# 创建student表, 并声明文件分隔符’	’（hive默认的分隔符 ）
hive> create table student(id int, name string) ROW FORMAT DELIMITED FIELDS TERMINATED BY '	';
hive> load data local inpath '/opt/module/datas/student.txt' into table student partition(dt='xxxx');
```
>- local:表示从本地加载数据到 hive 表；否则从 HDFS 加载数据到 hive 表 
>- inpath:表示加载数据的路径
>- overwrite:表示覆盖表中已有数据，否则表示追加
>- partition:表示上传到指定分区


- **Import 数据到指定 Hive 表中**
注意：先用 export 导出后，再将数据导入。
`import table student2 partition(month='201709') 
from '/user/hive/warehouse/export/student';`

### 2.4.2 数据导出
**①Insert 导出**
导出到本地
`insert overwrite local directory 
'/opt/module/datas/export/student1'
 ROW FORMAT DELIMITED FIELDS TERMINATED BY '	' 
select * from student;`
导出到hdfs
`insert overwrite directory 
'/user/atguigu/student2'
 ROW FORMAT DELIMITED FIELDS TERMINATED BY '	' 
 select * from student;`

**②Hadoop 命令导出到本地**
`dfs -get /user/hive/warehouse/student/month=201709/000000_0
/opt/module/datas/export/student3.txt;`

**③Hive Shell 命令导出**
`bin/hive -e 'select * from default.student;' > /opt/module/datas/export/student4.txt;`

**④Export 导出到 HDFS 上**
`export table default.student to
'/user/hive/warehouse/export/student';`

**⑤Sqoop 导出**
`sqoop export xxx`

<br>
### 2.4.3 一般操作
插入数据  
`insert into student values(1000,"ss");`

清除表中数据（Truncate）
`truncate table student;`

查询语句中创建表并加载数据（As Select）
`create table if not exists xxxx
as select id, name from yyyy;`
查询表记录并插入原表   
`insert into table xxxxx partition(dt='xxxx') select * from xxx;`
查询表记录并覆盖回原表，实现表的更新  
`insert overwrite table xxxxx partition(dt='xxxx') select * from xxx;`


<br>
## 2.5 DQL
**查询语句**
```
SELECT [ALL | DISTINCT] select_expr, select_expr, ...
  FROM table_reference
  [WHERE where_condition]
  [GROUP BY col_list]
  [ORDER BY col_list]
  [CLUSTER BY col_list
    | [DISTRIBUTE BY col_list] [SORT BY col_list]
  ]
 [LIMIT number]
```

**算术运算符**
`select sal+1 from emp;`
注：包括`+`、`-`、`*`、`/`、`%`、`&`、`|`、`^`、`~`等运算符

**常用函数**
`select count(*)/max(sal)/min(sal)/sum(sal)/avg(sal)/round(xxx,n)  from emp;`

**比较运算符**
`select * from emp where sal RLIKE '[2]';`
注：包括`=`、`<=>` (如果都为null，返回true；如果任一为null，返回null)、`<>/!=` (任一为null返回null)、`<`、`<=`、`>`、`>=`、`between and` (包括两边边界)、`is null`、`is not null`、`in`、`like`(同mysql)、`rlike/regexp`(正则匹配)

**正则匹配**
- REGEXP
语法: A REGEXP B 
操作类型: strings 
描述: 功能与RLIKE相同
例：`select count(*) from olap_b_dw_hotelorder_f where create_date_wid not regexp '\d{8}'`
- REGEXP_EXTRACT
语法: regexp_extract(string subject, string pattern, int index) 
返回值: string 
说明：将字符串subject按照pattern正则表达式的规则拆分，返回index指定的字符
例：`select regexp_extract('IloveYou','I(.*?)(You)',1) from test1 limit1;`
- REGEXP_REPLACE
语法: regexp_replace(string A, string B, string C) 
返回值: string 
说明：将字符串A中的符合[Java](http://lib.csdn.net/base/javaee "Java EE知识库")正则表达式B的部分替换为C。注意，在有些情况下要使用转义字符,类似[Oracle](http://lib.csdn.net/base/oracle "Oracle知识库")中的regexp_replace函数。
例：`select regexp_replace("IloveYou","You","") from test1 limit1;`

<br>
**分组**
- Group By 语句
```sql
select cata, tm, name, sum(pro_num),`grouping`(cata), `grouping`(tm),`grouping`(name)
from default.cube_test
group by cata, tm, name
order by cata, tm, name;
-- 得到
pc,hp,envy,2,0,0,0
pc,mac,M1,6,0,0,0
phone,iphone,8,8,0,0,0
phone,redmi,k30,5,0,0,0
phone,redmi,z1,3,0,0,0
```
- Group By Rollup：生成的结果集显示了所选列中值的某一层次结构的聚合，例Group by  ROLLUP(A, B, C)的话，首先会对(A、B、C)进行GROUP BY，然后对(A、B)进行GROUP BY，然后对(A)进行GROUP BY，最后对全表进行GROUP BY操作。
```sql
select cata, tm, name, sum(pro_num), sum(pro_num),`grouping`(cata), `grouping`(tm),`grouping`(name)
from default.cube_test
group by rollup (cata, tm, name)
order by cata, tm, name;
-- 得到
,,,24,24,1,1,1
pc,,,8,8,0,1,1
pc,hp,,2,2,0,0,1
pc,hp,envy,2,2,0,0,0
pc,mac,,6,6,0,0,1
pc,mac,M1,6,6,0,0,0
phone,,,16,16,0,1,1
phone,iphone,,8,8,0,0,1
phone,iphone,8,8,8,0,0,0
phone,redmi,,8,8,0,0,1
phone,redmi,k30,5,5,0,0,0
phone,redmi,z1,3,3,0,0,0
```
- Group By Cube：对选择的维度的所有组合进行group by，例cube(a,b,c):(a,b,c),(a,b),(a,c),(b,c),(a),(b),(c),(全表)
```sql
select cata, tm,name, sum(pro_num), sum(pro_num),`grouping`(cata), `grouping`(tm),`grouping`(name)
from default.cube_test
group by cube (cata, tm, name)
order by cata, tm, name;
-- 得到
,,,24,24,1,1,1
,,8,8,8,1,1,0
,,M1,6,6,1,1,0
,,envy,2,2,1,1,0
,,k30,5,5,1,1,0
,,z1,3,3,1,1,0
,hp,,2,2,1,0,1
,hp,envy,2,2,1,0,0
,iphone,,8,8,1,0,1
,iphone,8,8,8,1,0,0
,mac,,6,6,1,0,1
,mac,M1,6,6,1,0,0
,redmi,,8,8,1,0,1
,redmi,k30,5,5,1,0,0
,redmi,z1,3,3,1,0,0
pc,,,8,8,0,1,1
pc,,M1,6,6,0,1,0
pc,,envy,2,2,0,1,0
pc,hp,,2,2,0,0,1
pc,hp,envy,2,2,0,0,0
pc,mac,,6,6,0,0,1
pc,mac,M1,6,6,0,0,0
phone,,,16,16,0,1,1
phone,,8,8,8,0,1,0
phone,,k30,5,5,0,1,0
phone,,z1,3,3,0,1,0
phone,iphone,,8,8,0,0,1
phone,iphone,8,8,8,0,0,0
phone,redmi,,8,8,0,0,1
phone,redmi,k30,5,5,0,0,0
phone,redmi,z1,3,3,0,0,0
```
- Having 语句 (聚合后进行筛选)
`select deptno, avg(sal) avg_sal from emp group by deptno having avg_sal > 2000;`

**grouping sets**
查询如下
```
SELECT a, b, sum(m)
FROM t
GROUP BY a,b 
UNION ALL  
SELECT a, null, sum(m)
FROM t
GROUP BY a 
UNION ALL  
SELECT null, b, sum(m)
FROM t
GROUP BY b
```
可以使用grouping sets进行简化
```
SELECT null, b, sum(m), GROUPING__ID
FROM t
GROUP BY a, b
    GROUPING SETS ( a, b, (a, b) )
```
>GROUPING__ID表示以哪些字段作为聚合条件：如GROUPING__ID值为2，那么二进制表示为10，表示使用了a进行聚合；同理，GROUPING__ID值为3，那么二进制表示为11，表示使用了a,b进行聚合。

hive中grouping sets 数量较多时如何处理? 
可以使用如下设置来
set hive.new.job.grouping.set.cardinality = 30;
这条设置的意义在于告知解释器，group by之前，每条数据复制量在30份以内。

`Grouping Sets与Group by然后UNION ALL的区别就是，Grouping Sets会读取一次记录并根据指定的多个维度组合进行聚合，这样可以减少多次读取的IO消耗，但是会增加内存和CPU消耗。如果内存资源够用的情况下推荐使用Grouping Sets，速度更快。`

[官网对于Grouping Sets的介绍](https://cwiki.apache.org/confluence/display/Hive/Enhanced+Aggregation%2C+Cube%2C+Grouping+and+Rollup#EnhancedAggregation,Cube,GroupingandRollup-GROUPINGSETSclause)


**Join 语句**
- 内连接
`select e.empno, e.ename, d.deptno from emp e join
dept d on e.deptno = d.deptno;`
- 左外连接
`select e.empno, e.ename, d.deptno from emp e left 
join dept d on e.deptno = d.deptno;`
- 右外连接
`select e.empno, e.ename, d.deptno from emp e right 
join dept d on e.deptno = d.deptno;`
- 满外连接
`select e.empno, e.ename, d.deptno from emp e full 
join dept d on e.deptno = d.deptno;`

**排序**
- Order by：只能启动一个reduce进行排序，排序结果全局有序。如果数据量过大，需要加上limit限制个数。
`select ename, deptno, sal from emp order by deptno, 
sal desc;`
- 按照别名排序
`select ename, sal*2 twosal from emp order by 
twosal;`
- 每个 MapReduce 内部排序（Sort By）
Sort By：可以启动多个reduce执行排序，通过设置设置mapred.reduce.tasks来规定reducer个数；如果个数大于一个，只会保证每个reducer的输出有序，并不保证全局有序。
```
# 设置 reduce 个数
set mapreduce.job.reduces=3;
# 根据部门编号降序查看员工信息(每个reduce中的部门编号是降序的，汇总后的结果是部分有序的)
select * from emp sort by empno desc
# 将查询结果导入到文件中，不同于上个命令结果是杂乱无章的，导出后有三个文件，保存了每个reduce的排序结果
insert overwrite local directory '/opt/module/datas/sortby-result' select * from emp sort by deptno desc;
```
- 分区排序（Distribute By）
Distribute By：distribute by是控制在map端如何拆分数据给reduce端的；需要配合sort by使用，即对记录进行分区，在每个分区中进行排序。
`注意，Hive 要求 DISTRIBUTE BY 语句要写在 SORT BY 语句之前。`
```
# 设置 reduce 个数
set mapreduce.job.reduces=3;
# 先按照部门编号分区，再按照员工编号降序排序
insert overwrite local directory '/opt/module/datas/distribute-result' select * from emp distribute by deptno sort by empno desc;
```
- Cluster By
当 distribute by 和 sorts by 字段相同时，可以使用 cluster by 代替，但是排序只能是升序排序，不能指定排序规则为 ASC 或者 DESC。
即`select * from emp cluster by deptno;`
等价于`select * from emp distribute by deptno sort by 
deptno;`
注意：分区时，可能多个key会进入一个分区中，如可能 20 号和 30 号部门分到一个分区里面去。

**分桶及抽样查询**
- 分桶表数据存储
`分区针对的是数据的存储路径；分桶针对的是数据文件。`
```
# 设置属性
set hive.enforce.bucketing=true;
# 创建分桶表
create table stu_buck(id int, name string)
clustered by(id) into 4 buckets
row format delimited fields terminated by '	';
# 查看表结构
desc formatted stu_buck;
# 导入数据
insert into table stu_buck select id, name from stu;
```
- 分桶抽样查询
对于非常大的数据集，有时用户需要使用的是一个具有代表性的查询结果而不是全部结果。Hive 可以通过对表进行抽样来满足这个需求。
`select * from stu_buck tablesample(bucket 1 out 
of 2 on id)`
解释：table 总 bucket 数为 4，tablesample(bucket 1 out of 2)，表示总共抽取（4/2=）2 个bucket 的数据，抽取第 1(x)个和第 3(x+y)个 bucket 的数据。
根据结果可知：Hive的分桶采用对分桶字段的值进行哈希，然后除以桶的个数求余的方式决定该条记录存放在哪个桶当中。


<br>
# 三、函数
查看系统自带的函数，支持模糊查询和正则查询
`show functions;`
`show functions like '*row_number*';`  	
显示自带的函数的用法
`desc function upper;`
详细显示自带的函数的用法
`desc function extended upper;`

[官网函数的说明和使用](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+UDF#LanguageManualUDF-Misc.Functions)

## 3.1 常用函数
#### 数据类型转换
`select '1'+2, cast('1' as int) + 2;`

#### format_number
规定数字的小数位数并输出string类型
`format_number(x,n)`

#### NVL
`NVL( string1, string2)`  
如果string1不为null，则结果为null；如果string1为null，则结果为string2，如果string1为null且string2为null，则返回null。

#### COALESCE
NVL的强化版，可以出入任意个参数。如果第一个参数为null则判断第二个，依次类推，如果全是null则返回null；

#### IF
if(boolean testCondition, T valueTrue, F valueFalseOrNull)    如果表达式结果为true则值为T ，如果表达式结果为false则值为F。


#### JSON类
①get_json_object：解析json字符串的一个字段
```
select get_json_object(line,'$.tid')
from ods_edb.ods_edb_order
limit 5;
```
②json_tuple：解析json字符串中的多个字段
```
select json_tuple(line,'tid','out_tid','tid_item')
from ods_edb.ods_edb_order
limit 5;
```
③Json数组解析
```
SELECT explode(split(regexp_replace(regexp_replace('[{"website":"www.baidu.com","name":"百度"},{"website":"google.com","name":"谷歌"}]', '\]',''),'\}\,\{','\}\;\{'),'\;'));
```

#### 时间类
①日期格式化：date_format、date_add、next_day、last_day等函数只能识别"yyyy-MM-dd"，所以其他日期格式需要转化为"yyyy-MM-dd"格式。
- `regexp_replace('2019/06/29',/,-);`		用-替换/
- `date_format('2019-06-29','yyyy-MM-dd');`
`date_format(regexp_replace( '2019/06/29', '/' , '-' ) , 'yyyy-MM' )`  
- 参数类型可以是string/date/timestamp
`unix_timestamp(visitdate,'yyyy/MM/dd')`
`from_unixtime(unix_timestamp(visitdate,'yyyy/MM/dd') , 'yyyy-MM-dd')` 只要年月可以把dd删去

②日期
- current_date：获取当前日期
`select current_date`
- current_timestamp：获取当前系统时间(包括毫秒数)
`select current_timestamp; `
- to_date：日期时间转日期
`select to_date('2017-09-15 11:12:00') from dual;`
- date_add：时间跟天数相加
`select date_add('2019-06-29', -5);`
- date_sub：时间跟天数相减
`select date_sub('2019-06-29',5);`
- datediff：两个时间相减
`select datediff('2019-06-29','2019-06-24');`
`select datediff('2019-06-24 12:12:12','2019-06-29');`
- next_day：取当前天的下一个周一
`select next_day('2019-02-12','MO');`
说明：星期一到星期日的英文（Monday，Tuesday、Wednesday、Thursday、Friday、Saturday、Sunday）
- last_day：当月最后一天日期
`select last_day('2019-02-10');`
mysql中的事件格式是 +%Y-%m-%d  或  +%F
- 获取日期中的年/月/日/时/分/秒/周/季度
`with dtime as (select from_unixtime(unix_timestamp(),'yyyy-MM-dd HH:mm:ss') as dt)
select year(dt), month(dt), day(dt), hour(dt), minute(dt), second(dt), weekofyear(dt) ,floor(substr(dt,6,2)/3.1)+1 from dtime;`
- 获取周所在的年：需要注意周跨年的情况，7天中有4天及以上在哪一年，那么该周就属于哪一年。计算逻辑为: 当天的下周一，再往前推4天所在的年就是该周所在的年
year(date_add(next_day(date_id,'MO'),-4))
- 获取周几：hive中dayofweek函数得到的周几与我们理解的周几是错位的，调整如下
if((dayofweek(date_id) - 1) = 0, 7, dayofweek(date_id) - 1)

③时间戳
- 日期转时间戳：从1970-01-01 00:00:00 UTC到指定时间的秒数
`select unix_timestamp();` --获得当前时区的UNIX时间戳
`select unix_timestamp('2017-09-15 14:23:00'); `
`select unix_timestamp('2017-09-15 14:23:00','yyyy-MM-dd HH:mm:ss');`
`select unix_timestamp('20170915 14:23:00','yyyyMMdd HH:mm:ss');`

- 时间戳转日期
`select from_unixtime(1505456567); `
`select from_unixtime(1505456567,'yyyyMMdd'); `
`select from_unixtime(1505456567,'yyyy-MM-dd HH:mm:ss'); `
`select from_unixtime(unix_timestamp(),'yyyy-MM-dd HH:mm:ss');`  --获取系统当前时间

④trunc函数
- 截取日期
`select trunc('2020-06-10','MM');` -- 2020-06-01 返回当月第一天.
`select trunc('2020-06-10','YY');` -- 2020-01-01 返回当年第一天
`select trunc('2020-06-10','Q');`  -- 2020-04-01

- 截取数字
`select trunc(123.458);` --123
`select trunc(123.458,0);` --123
`select trunc(123.458,1);` --123.4
`select trunc(123.458,-1);` --120
`select trunc(123.458,-4);` --0
`select trunc(123.458,4);` --123.458
`select trunc(123);` --123
`select trunc(123,1);` --123
`select trunc(123,-1);` --120

⑤月份函数
- 查询当前月份
`select month(current_date);`
- 查询当月第几天
`select dayofmonth(current_date);`
- 当月第1天
`date_sub(current_date,dayofmonth(current_date)-1);`
- 下个月第1天 
`add_months(date_sub(current_date,dayofmonth(current_date)-1),1);`

⑥获取UUID
`regexp_replace(reflect("java.util.UUID", "randomUUID"), "-", "")`

<br>
#### CASE WHEN
`select  dept_id, sum(case sex when '男' then 1 else 0 end) male_count, sum(case sex when '女' then 1 else 0 end) female_count from emp_sex group by dept_id;`

<br>
#### 行转列

![数据](Hive基础.assets\16a6dc5abfcc4f77becf07db9f91a875.png)
将如上数据转化为如下结构
![结果](Hive基础.assets\45e85de5cc1c4d379168e83cf4acf851.png)
```sql
select
    t1.base,
    concat_ws('|', collect_set(t1.name)) name
from
    (select
        name,
        concat(constellation, ",", blood_type) base
    from
        person_info) t1
group by
    t1.base;
```
>**concat_ws与concat区别**
concat("a",":","c")：将所有直接拼接起来得到a:c，如果有一个元素为null，则结果为null；
concat_ws()：第一个元素为分隔符，将元素通过分隔符拼接起来，如果有一个元素为null，则自动忽略；
**collect_set与collect_list区别**
collect_set去重，collect_list不去重；
**STR_TO_MAP函数**
MAP STR_TO_MAP(VARCHAR text,VARCHAR listDelimiter,VARCHAR keyValueDelimiter) 将字符串text通过listDelimiter分割为多个元素，再通过keyValueDelimiter将元素分割为key和value。
```
-- 以'='分割kv对中的key和value，以'-'分隔每个kv对
str_to_map(
                        concat_ws(
                                '-', collect_list(
                                concat(
                                        case
                                            when year_month_day is not null
                                                then 'year_month_day'
                                            when year_week is not null
                                                then 'year_week'
                                            when year_month is not null
                                                then 'year_month'
                                            when year is not null then 'year'
                                            end, '='
                                    , nvl(sale_num, ''), ',', nvl(sale_amount, ''), ',', nvl(send_num, ''), ','
                                    , nvl(stock_out, ''), ',', nvl(stock_unserved, '')
                                    )
                                )
                            ), '-', '='
                    )
```

<br>
#### 列转行
LATERAL VIEW udtf(expression) tableAlias AS columnAlias。
EXPLODE(col)：将hive一列中复杂的array或者map结构拆分成多行，默认分隔符为逗号。
将如下数据

![数据](Hive基础.assets\44273fc549104f0fa6fea93391cec2fc.png)
转化为如下结构

![结果](Hive基础.assets4cf93a13a374d3daf80375d64e96dc5.png)

```sql
select
    movie,
    category_name
from 
    movie_info lateral view explode(category) table_tmp as category_name;
```  



<br>
#### 开窗函数
在其他查询执行完之后才会执行窗口函数，在查询结果表上添加一列用于记录处理结果。对查询得到的表作相应的over(..)处理：partition by对表进行分区；order by将分区中的数据进行排序；然后按行处理，rows between.. and..生成所指定的行的临时表（缺省为整表），将该临时表的数据通过聚合函数进行处理，得到当前所在行的处理结果，将结果填入到当前行的新增列中。
常见的开窗函数：
- 聚合开窗函数：count、sum、min、max、avg、first_value、last_value、lag、lead、cume_dist、cume_dist
- 排序开窗函数：rank、dense_rank、ntile、row_number、percent_rank

其中
- LAG(col,n, [default_val])：往前第 n 行数据，如果没写default_val默认为null；
- LEAD(col,n, [default_val])：往后第 n 行数据，如果没写default_val默认为null；
- RANK() 排序相同时会重复，总数不会变（如有两个第一名，则下一名是第三名）；
- DENSE_RANK() 排序相同时会重复，总数会减少（如有两个第一名，则下一名是第二名）；
- ROW_NUMBER() 会根据顺序计算（第一行是1，第二行是2）；
- NTILE(n)：先根据某一属性排序，然后通过ntile（n）给其分n组，再添加一列，值是每组编号（从1开始）。  注意：n必须为int类型。如想取20%，可以NTILE(5)分成五组，取第一组。
- percent_rank：计算给定行的百分比排名。可以用来计算超过了百分之多少的人

①函数相关说明
- OVER()：指定分析函数工作的数据窗口大小，这个数据窗口大小可能会随着行的变而变化。
- CURRENT ROW：当前行
- n PRECEDING：往前n行数据
- n FOLLOWING：往后n行数据
- UNBOUNDED：起点，UNBOUNDED PRECEDING 表示从前面的起点， UNBOUNDED FOLLOWING表示到后面的终点。


注意：
1. 窗口函数只在order by和limit之前执行
2. 如果窗口函数排序，那么就默认有一个rows between 最前行到当前行。
`sum(cost) over(partition by name order by orderdate)`
和下句表达的意思是一样的
`sum(cost) over(partition by name order by orderdate rows between UNBOUNDED PRECEDING and current row )`  
即由起点到当前行的聚合。
3. 如果窗口函数没有排序，那么默认从最前行到最后行.
`sum(cost) over()`
和下句表达的意思是一样的
`sum(cost) over(rows between unbounded preceding and current row)`
4. partition by .. order by ..和group by ..order by .. 区别：partition by和order by的执行顺序是连着的，分区后进入不同的reduce以关键字为key进行排序，输出时同一分区在一起且各个分区内的数据有序。而group by和order by的执行顺序不是连着的，order by是对分组后的表进行的整表排序，进入一个reduce中，所以order by一般和limit连用。
5. min(dt) over (order by dt rows between unbounded preceding and 1 preceding) 中，首先会对全局dt进行排序，而非首行到前一行排序；最后选择首行到前一行作为窗口进行处理。
6. 如下hql，如果ts中有两个值相同，那么运行语句中有无between unbounded preceding and current row得到的结果是不同的。推测没有时的逻辑是筛选出小于等于ts的记录作为窗口进行sum；而有between时，是排序后从第一行到当前行的记录作为窗口进行sum。
```
select id, ts, sum(p) over (order by ts rows between unbounded preceding and current row ) as online_num
         from t1
```
![image.png](Hive基础.assets\8d4f83d948e4426abaaf602613213419.png)


>例：希望给前20%记录进行标记
>①使用rank类开窗函数
>②使用分桶函数ntile
>③使用分位函数percentile和percentile_approx

<br>
**这里举例解释cume_dist开窗函数**
```
select studentId,math,departmentId,classId,
-- 统计小于等于当前分数的人数占总人数的比例
cume_dist() over(order by math) as cume_dist1,
-- 统计大于等于当前分数的人数占总人数的比例
cume_dist() over(order by math desc) as cume_dist2,
-- 统计分区内小于等于当前分数的人数占总人数的比例
cume_dist() over(partition by classId order by math) as cume_dist3
from student_scores where departmentId='department1';

-- 结果
studentid   math    departmentid    classid cume_dist1              cume_dist2          cume_dist3
111         69      department1     class1  0.1111111111111111      1.0                 0.2
113         74      department1     class1  0.4444444444444444      0.7777777777777778  0.4
112         80      department1     class1  0.6666666666666666      0.4444444444444444  0.6
115         93      department1     class1  0.8888888888888888      0.2222222222222222  0.8
114         94      department1     class1  1.0                     0.1111111111111111  1.0
124         70      department1     class2  0.2222222222222222      0.8888888888888888  0.25
121         74      department1     class2  0.4444444444444444      0.7777777777777778  0.5
123         78      department1     class2  0.5555555555555556      0.5555555555555556  0.75
122         86      department1     class2  0.7777777777777778      0.3333333333333333  1.0

结果解释:
    第三行:
        cume_dist1=小于等于80的人数为6/总人数9=0.6666666666666666
        cume_dist2=大于等于80的人数为4/总人数9=0.4444444444444444
        cume_dist3=分区内小于等于80的人数为3/分区内总人数5=0.6
```

**举例percent_rank开窗函数**
```
select studentid,departmentid,classid,math,
row_number() over(partition by departmentid,classid order by math) as row_number,
percent_rank() over(partition by departmentid,classid order by math) as percent_rank
from student_scores;

结果
studentid   departmentid    classid math    row_number  percent_rank
111         department1     class1  69      1           0.0
113         department1     class1  74      2           0.25
112         department1     class1  80      3           0.5
115         department1     class1  93      4           0.75
114         department1     class1  94      5           1.0
124         department1     class2  70      1           0.0
121         department1     class2  74      2           0.3333333333333333
123         department1     class2  78      3           0.6666666666666666
122         department1     class2  86      4           1.0
216         department2     class1  74      1           0.0
215         department2     class1  82      2           0.2
212         department2     class1  83      3           0.4
211         department2     class1  93      4           0.6
213         department2     class1  94      5           0.8
214         department2     class1  94      6           0.8
223         department2     class2  74      1           0.0
222         department2     class2  78      2           0.25
224         department2     class2  80      3           0.5
225         department2     class2  85      4           0.75
221         department2     class2  99      5           1.0

结果解释:
    studentid=115,percent_rank=(4-1)/(5-1)=0.75
    studentid=123,percent_rank=(3-1)/(4-1)=0.6666666666666666
```


<br>
#### 通过开窗函数进性去重
Hive3.0 默认group by不能超过64个，可以使用开窗函数进性去重
```
SELECT get_json_object(line, '$.order_totalfee'),
       get_json_object(item, '$.tid'),
       get_json_object(item, '$.send_num')
FROM (
         SELECT row_number() over (partition by get_json_object(line, '$.tid')) row_num,
                line
         FROM hxr_edb.ods_edb_order
         where ds = '$edb_ds'
           and get_json_object(line, '$.tid_item') is not null
     ) tmp
         lateral view hxr_edb.explode_json_array(get_json_object(tmp.line, '$.tid_item')) table_tmp as item
where row_num = 1;
```

<br>
#### get_json_object函数
用于获取json字符串中的属性的值，参数是字段名和外部json名.json属性名。
```
insert overwrite table dwd_start_log
PARTITION (dt='2019-02-10')
select
    get_json_object(line,'$.mid') mid_id,
    get_json_object(line,'$.uid') user_id,
    get_json_object(line,'$.vc') version_code
from ods_start_log
where dt='2019-02-10';
```


<br>
## 3.2 自定义函数
Hive 自带了一些函数，比如：max/min 等，但是数量有限，自己可以通过自定义 UDF来方便的扩展。
- UDF（User-Defined-Function）：一进一出
- UDAF（User-Defined Aggregation Function）：聚集函数，多进一出，类似于：count/max/min
- UDTF（User-Defined Table-Generating Functions）：一进多出，如 lateral view explore()

**依赖**
```
    <dependencies>
        <dependency>
            <groupId>org.apache.hive</groupId>
            <artifactId>hive-exec</artifactId>
            <version>3.1.2</version>
            <scope>provided</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <target>1.8</target>
                    <source>1.8</source>
                </configuration>
            </plugin>
        </plugins>
    </build>
```
<br>
### 3.2.1 UDF函数
如需要解析如下字符串
`0-115.581|1-83.281|33-2.448|36-5.677|38-1.358`
获取key对应的value。
```java
public class TimeCountUDF extends UDF {
    public String evaluate(String str, String key) {
        String[] kvs = str.split("\|");
        for (String kv : kvs) {
            String[] split = kv.split("-");
            String k = split[0];
            if (key.equals(k)) {
                return split[1];
            }
        }
        return "0";
    }
}
```
>步骤：
>1. 继承UDF类
>2. 实现evaluate方法

<br>
### 3.2.2 UDTF函数
```java
public class ExplodeJSONArray extends GenericUDTF {

    @Override
    public StructObjectInspector initialize(ObjectInspector[] argOIs) throws UDFArgumentException {
        // 1.检查参数合法性
        if (argOIs.length != 1) {
            throw new UDFArgumentException("只需要一个参数");
        }

        // 2. 第一个参数必须为string
        // 判断参数是否为基础数据类型
        if (argOIs[0].getCategory() != ObjectInspector.Category.PRIMITIVE) {
            throw new UDFArgumentException("只接受基础类型参数");
        }

        // 将参数对象检查器强制转为基础类型对象检查其
        PrimitiveObjectInspector argument = (PrimitiveObjectInspector) argOIs[0];

        // 判断参数是否为String类型
        if (argument.getPrimitiveCategory() != PrimitiveObjectInspector.PrimitiveCategory.STRING) {
            throw new UDFArgumentException("只接受string类型参数");
        }

        // 定义返回值名称和类型
        ArrayList<String> fieldNames = new ArrayList<String>();
        ArrayList<ObjectInspector> fieldOIs = new ArrayList<ObjectInspector>();

        fieldNames.add("items");
        fieldOIs.add(PrimitiveObjectInspectorFactory.javaStringObjectInspector);

        return ObjectInspectorFactory.getStandardStructObjectInspector(fieldNames, fieldOIs);
    }

    @Override
    public void process(Object[] objects) throws HiveException {
        Object arg = objects[0];
        String jsonArrayStr = PrimitiveObjectInspectorUtils.getString(arg, PrimitiveObjectInspectorFactory.javaStringObjectInspector);

        try {
            JSONArray jsonArray = new JSONArray(jsonArrayStr);

            for (int i = 0; i < jsonArray.length(); i++) {
                String json = jsonArray.getString(i);
                String[] result = {json};
                forward(result);
            }
        } catch (Exception e) {
            Logger.getLogger("ExplodeJSONArray").warning("FastJson解析失败: " + jsonArrayStr);
        }
    }

    @Override
    public void close() throws HiveException {

    }

}
```
>步骤：
>1. 继承GenericUDTF类
>2. initialize方法控制输入参数的类型
>3. process方法对输入进行处理并返回输出的字段

<br>
### 3.2.3 导入hive
**打包后将jar包放置到hdfs上**
```
hadoop fs -mkdir /user/hive/jars
hadoop fs -put /opt/module/packages/hivefunction-1.0-SNAPSHOT-jar-with-dependencies.jar /user/hive/jars/
```
**创建永久函数**
```
create function device_udf as 'com.cj.hive.TimeCountUDF ' using jar 'hdfs://bigdata1:9000/user/hive/jars/hivefunction-1.0-SNAPSHOT-jar-with-dependencies.jar';
create function addr_udtf as 'com.cj.hive.ModelJsonUDTF ' using jar 'hdfs://bigdata1:9000/user/hive/jars/hivefunction-1.0-SNAPSHOT-jar-with-dependencies.jar';
show functions like "*udtf*";  # 模糊匹配搜索函数
```
**删除函数**
`drop [temporary] function [if exists] [dbname.]function_name;`



<br>
# 四、hive调优
1. 非mapreduce查询 
hive.fetch.task.conversion默认是more，全局查找、字段查找、limit查找等都不走mapreduce。
2. 本地模式
Hive可以通过本地模式在单台机器上处理所有的任务。对于小数据集，执行时间可以明显被缩短。
用户可以通过设置hive.exec.mode.local.auto的值为true来使hive自动启动本地模式。
3. 小表join大表
如果是join on ，会将左表先加入内存，然后通过on条件，筛选右表的符合条件项，建立一张临时表，避免了如果使用where，会先产生笛卡尔积表，再进行筛选的危险。
map join优化：
如果是map join ，那么就要大表join小表（25MB）。因为MR底层会调用本地任务将join后面的表缓存到内存中，所以将小表放在后面可以减轻缓存和计算压力。如果是join，优化器会自动交换位置；如果是left join不会交换位置，需要注意大表join小表。
①设置自动选择Mapjoin
set hive.auto.convert.join = true; 默认为true
②大表小表的阈值设置（默认25M一下认为是小表）
set hive.mapjoin.smalltable.filesize=25000000;  
reduce join 优化：
如果关闭了map join功能（默认是打开的）
set hive.auto.convert.join = false;
或者没有小表(25MB以下)，那么会进行reduce join。一般来说都是小表join大表，小表join大表，如果是内连接，hive会自动优化，将小表放在左边join大表，效率高。
但是如果是外连接，就需要将小表放在join左边，将大表放在join右边。

数据量小的表放在join的左边，这样可以有效减少内存溢出错误发生的几率。
set hive.auto.convert.join = true; 默认为true
set hive.mapjoin.smalltable.filesize=25000000;大表小表的阈值设置（默认25M一下认为是小表）
MapJoin把小表全部加载到内存在map端进行join，将join后的结果直接输出，避免reducer处理。
4. 大表join大表
Join前先过滤表中的脏数据，如果某一个key对应的数据过多，可以进行加盐使其随机分不到不同reduce中。
例1：滤空
hive (default)> insert overwrite table jointable select n.* from (select * from nullidtable where id is not null ) n  left join ori o on n.id = o.id;
例2：随机分布空null值
insert overwrite table jointable
select n.* from nullidtable n full join ori o on 
case when n.id is null then concat('hive', rand()) else n.id end = o.id;
5. 预聚合功能
group by会先通过key值分区，然后再通过key值再进行分组。如果某个分区有过多的数据，会进入一个reduce，则会造成某一个reduce数据量过大，即数据倾斜。可以开启预聚合功能：会先进行一个MR任务，该阶段随机进行分组，然后数据均匀的进入reduce处理，该步先将相同的key进行聚合，然后将得到的结果作为输入给到下一个MR任务，该任务将根据key进行分区，进入reduce输出最终的group by结果。
由于先进行了预分区，所以两次MR任务都不会出现严重的数据倾斜。
set hive.map.aggr = true		开启Map端聚合参数设置，默认为true
set hive.groupby.mapaggr.checkinterval = 100000	在Map端进行聚合操作的条目数目
set hive.groupby.skewindata = true	有数据倾斜的时候进行负载均衡，默认为false
6. 避免使用distinct
distinct去重和group by 去重是一回事。但是count（distinct ..）是全聚合操作，最终会进入一个reduce中，造成效率低下。可以先用group by 过滤，然后在过滤表的基础上再进行count.
select count(distinct id) from bigtable; 只进行一个MR任务，但是进入一个reduce中处理。
替换为
select count(id) from (select id from bigtable group by id) a; 两个MR任务处理，每个MR任务中多个reduce进行处理。
`虽然会多用一个Job来完成，但在数据量大的情况下，这个绝对是值得的`
7. 避免笛卡尔积
where是单个表用的，如果多个表用where，会先产生笛卡尔积表再进行筛选，效率低且消耗内存。多表用join on 连接，会先进行on的筛选，不会产生笛卡尔积表。
尽量避免笛卡尔积，join的时候不加on条件，或者无效的on条件，Hive只能使用1个reducer来完成笛卡尔积。因为没有on条件，所有的数据都会进入一个reduce中，reduce压力过大，所以禁止笛卡尔积表生成。有on条件，相同的字段进入一个reduce，多reduce并行处理。
8.行列过滤：
列过滤：少用select * ，要什么就选什么
行过滤：在进行join之前将表进行过滤
select  o.id  from  bigtable  b  join  ori  o  on o.id = b.id  where  o.id <= 10;
替换为
select  b.id  from  bigtable  b  join  (select id from ori where id <= 10 ) o  on  b.id = o.id;
9. 动态分区调整
关系型数据库中，对分区表Insert数据时候，数据库自动会根据分区字段的值，将数据插入到相应的分区中，Hive中也提供了类似的机制，即动态分区(Dynamic Partition)，只不过，使用Hive的动态分区，需要进行相应的配置。
1．开启动态分区参数设置
（1）开启动态分区功能（默认true，开启）
hive.exec.dynamic.partition=true
（2）设置为非严格模式（动态分区的模式，默认strict，表示必须指定至少一个分区为静态分区，nonstrict模式表示允许所有的分区字段都可以使用动态分区。）
hive.exec.dynamic.partition.mode=nonstrict
（3）在所有执行MR的节点上，最大一共可以创建多少个动态分区。默认1000
hive.exec.max.dynamic.partitions=1000
	（4）在每个执行MR的节点上，最大可以创建多少个动态分区。该参数需要根据实际的数据来设定。比如：源数据中包含了一年的数据，即day字段有365个值，那么该参数就需要设置成大于365，如果使用默认值100，则会报错。
hive.exec.max.dynamic.partitions.pernode=100
（5）整个MR Job中，最大可以创建多少个HDFS文件。默认100000
hive.exec.max.created.files=100000
（6）当有空分区生成时，是否抛出异常。一般不需要设置。默认false
hive.error.on.empty.partition=false
2．案例实操
需求：将dept表中的数据按照地区（loc字段），插入到目标表dept_partition的相应分区中。
（1）创建目标分区表
hive (default)> create table dept_partition(id int, name string) partitioned
by (location int) row format delimited fields terminated by '	';
（2）设置动态分区
set hive.exec.dynamic.partition.mode = nonstrict;
hive (default)> insert into table dept_partition partition(location) select deptno, dname, loc from dept;
（3）查看目标分区表的分区情况
hive (default)> show partitions dept_partition;
思考：目标分区表是如何匹配到分区字段的？ 三个字段数据按顺序匹配。
10. 合理设置Map及Reduce数
概述：
map数量由切片数量决定，而reduce数量是人为设置的。如果将reduce数量设为-1（set mapreduce.job.reduces=-1），那么hive会将需要处理的数据大小除以256mb，预估需要的reduce数量。
在设置map数量时（切片数量），需要注意①map不能过多，也不能过少。过多会导致启动任务的时间大于执行时间，过少导致执行效率过低。②大多情况下，127mb左右的数据大小切片较合适，但是也要根据数据的特点进行切片：如果数据块中的数据计算复杂或每行的字段很少但是行数过多，那么应该减小切片的大小。
增加map的方法为：
根据computeSliteSize(Math.max(minSize,Math.min(maxSize,blocksize)))=blocksize=128M公式，调整maxSize最大值。让maxSize最大值低于blocksize就可以增加map的个数。
通过下述公式调整切片maxsize和minsize大小：
set mapreduce.input.fileinputformat.split.maxsize=100;  将切片大小设为100mb
11. 小文件进行合并：
在map执行前合并小文件：
CombineHiveInputFormat具有对小文件进行合并的功能（系统默认的格式）。HiveInputFormat没有对小文件合并功能。
set hive.input.format= org.apache.hadoop.hive.ql.io.CombineHiveInputFormat;
在Map-Reduce的任务结束时合并小文件的设置：
在map-only任务结束时合并小文件，默认true
SET hive.merge.mapfiles = true;
在map-reduce任务结束时合并小文件，默认false
SET hive.merge.mapredfiles = true;
合并文件的大小，默认256M
SET hive.merge.size.per.task = 268435456;
当输出文件的平均大小小于该值时，启动一个独立的map-reduce任务进行文件merge
SET hive.merge.smallfiles.avgsize = 16777216;
12. 合理设置Reduce数
reduce数量如果设为-1，那么hive会根据需要处理的数据大小除以256mb来预估需要的reduce数量。
①调整reduce个数方法一
（1）每个Reduce处理的数据量默认是256MB
hive.exec.reducers.bytes.per.reducer=256000000
（2）每个任务最大的reduce数，默认为1009
hive.exec.reducers.max=1009
（3）计算reducer数的公式
N=min(参数2，总输入数据量/参数1)
2．调整reduce个数方法二
在hadoop的mapred-default.xml文件中修改
设置每个job的Reduce个数
set mapreduce.job.reduces = 15;
3．reduce个数并不是越多越好
1）过多的启动和初始化reduce也会消耗时间和资源；
2）另外，有多少个reduce，就会有多少个输出文件，如果生成了很多个小文件，那么如果这些小文件作为下一个任务的输入，则也会出现小文件过多的问题；
在设置reduce个数的时候也需要考虑这两个原则：
1.处理大数据量利用合适的reduce数；2.使单个reduce任务处理数据量大小要合适；
13.并行执行
多个map和reduce阶段可以并行执行。
set hive.exec.parallel=true;              //打开任务并行执行
set hive.exec.parallel.thread.number=16;  //同一个sql允许最大并行度，默认为8。
14.严格模式
在hive-site.xml中，通过设置属性hive.mapred.mode值为默认是非严格模式nonstrict 。开启严格模式需要修改hive.mapred.mode值为strict，开启严格模式可以禁止3种类型的查询。	
set  hive.mapred.mode = strict
①对于分区表，除非where语句中含有分区字段过滤条件来限制范围，否则不允许执行。即不允许查找所有的分区。
②对于使用了order by语句的查询，要求必须使用limit语句。这样每个map只需写出limit个数据，在一个reduce中排序，避免了对全部数据在一个reduce中进行排序。
③限制笛卡尔积的查询。多表查询必须用join on语句。关系型数据库在执行JOIN查询的时候不使用ON语句而是使用where语句，关系数据库的执行优化器就可以高效地将WHERE语句转化成ON语句。但是hive中不会这样转化。
15.JVM重用
hive的底层是MR实现的，所以jvm重用同样适用于hive。正常情况下，每个任务都会开启一个jvm在container中执行任务，任务执行完后关闭。对应小任务过多的情况，开启jvm的时间占比过大。开启jvm重用，jvm使用完不会关闭，而是给下一个任务使用，这样就没有开启jvm的时间浪费。缺点是会造成资源的闲置浪费。
16.推测执行(具体见hadoop调优)
如果并行任务中有任务因为bug、数据倾斜、阻塞等原因造成进度过慢，推测执行会开启另一个线程来执行相同的任务，并最终选择先执行完的任务的数据。
Hadoop的mapred-site.xml文件中进行配置，默认是true
mapreduce.map.speculative -> true
hive本身也提供了配置项来控制reduce-side的推测执行：默认是true
hive.mapred.reduce.tasks.speculative.execution -> true

11. 分区分桶
12. 每对JOIN连接对象启动一个MapReduce任务，当对3个或者更多表进行join连接时，如果每个on子句都使用相同的连接键的话，那么只会产生一个MapReduce job。
13. Order By：全局排序，只有一个Reducer

配置参数	参数说明
mapreduce.map.memory.mb	一个MapTask可使用的资源上限（单位:MB），默认为1024。如果MapTask实际使用的资源量超过该值，则会被强制杀死。
mapreduce.reduce.memory.mb	一个ReduceTask可使用的资源上限（单位:MB），默认为1024。如果ReduceTask实际使用的资源量超过该值，则会被强制杀死。
mapreduce.map.cpu.vcores	每个MapTask可使用的最多cpu core数目，默认值: 1
mapreduce.reduce.cpu.vcores	每个ReduceTask可使用的最多cpu core数目，默认值: 1
mapreduce.reduce.shuffle.parallelcopies	每个Reduce去Map中取数据的并行数。默认值是5
mapreduce.reduce.shuffle.merge.percent	Buffer中的数据达到多少比例开始写入磁盘。默认值0.66
mapreduce.reduce.shuffle.input.buffer.percent	Buffer大小占Reduce可用内存的比例。默认值0.7
mapreduce.reduce.input.buffer.percent	指定多少比例的内存用来存放Buffer中的数据，默认值是0.0
（2）应该在YARN启动之前就配置在服务器的配置文件中才能生效（yarn-default.xml）
表6-2
配置参数	参数说明
yarn.scheduler.minimum-allocation-mb	  	给应用程序Container分配的最小内存，默认值：1024
yarn.scheduler.maximum-allocation-mb	  	给应用程序Container分配的最大内存，默认值：8192
yarn.scheduler.minimum-allocation-vcores		每个Container申请的最小CPU核数，默认值：1
yarn.scheduler.maximum-allocation-vcores		每个Container申请的最大CPU核数，默认值：32
yarn.nodemanager.resource.memory-mb   	给Containers分配的最大物理内存，默认值：8192
（3）Shuffle性能优化的关键参数，应在YARN启动之前就配置好（mapred-default.xml）
表6-3
配置参数	参数说明
mapreduce.task.io.sort.mb   	Shuffle的环形缓冲区大小，默认100m
mapreduce.map.sort.spill.percent   	环形缓冲区溢出的阈值，默认80%
2．容错相关参数(MapReduce性能优化)
表6-4
配置参数	参数说明
mapreduce.map.maxattempts	每个Map Task最大重试次数，一旦重试参数超过该值，则认为Map Task运行失败，默认值：4。
mapreduce.reduce.maxattempts	每个Reduce Task最大重试次数，一旦重试参数超过该值，则认为Map Task运行失败，默认值：4。
mapreduce.task.timeout	Task超时时间，经常需要设置的一个参数，该参数表达的意思为：如果一个Task在一定时间内没有任何进入，即不会读取新的数据，也没有输出数据，则认为该Task处于Block状态，可能是卡住了，也许永远会卡住，为了防止因为用户程序永远Block住不退出，则强制设置了一个该超时时间（单位毫秒），默认是600000。如果你的程序对每条输入数据的处理时间过长（比如会访问数据库，通过网络拉取数据等），建议将该参数调大，该参数过小常出现的错误提示是“AttemptID:attempt_14267829456721_123456_m_000224_0 Timed out after 300 secsContainer killed by the ApplicationMaster.”。



###hive配置参数
1.配置配置文件
2.启动Hive时，可以在命令行添加-hiveconf param=value来设定参数
hive -hiveconf mapred.reduce.tasks=10;
3.hive (default)> set mapred.reduce.tasks=100;

不进入hive交互窗口执行hql语句
hive -e "select id from student;"
执行脚本中sql语句
hive -f /opt/module/datas/hivef.sql
hive -f /opt/module/datas/hivef.sql  > /opt/module/datas/hive_result.txt
在hive交互窗口中查看hdfs文件系统
dfs -ls /;
在hive交互窗口中查看本地文件系统
! ls /opt/module/datas;
4．查看在hive中输入的所有历史命令
cat ~/.hivehistory

### hive2.3配置
hive-env.sh
```sh
# Set HADOOP_HOME to point to a specific hadoop install directoryHADOOP_HOME=${HADOOP_HOME}
export HADOOP_HOME=$HADOOP_HOME
# Hive Configuration Directory can be controlled by:
export HIVE_CONF_DIR=$HIVE_HOME/conf

# Folder containing extra libraries required for hive compilation/execution can be controlled by:
# export HIVE_AUX_JARS_PATH=

export TEZ_HOME=/opt/module/tez-0.9.1
export TEZ_JARS=""
for jar in `ls $TEZ_HOME | grep jar`;do
        export TEZ_JARS=$TEZ_JARS:$TEZ_HOME/$jar
done

for jar in `ls $TEZ_HOME/lib`;do
        export TEZ_JARS=$TEZ_JARS:$TEZ_HOME/lib/$jar
done

export HIVE_AUX_JARS_PATH=$HADOOP_HOME/share/hadoop/common/hadoop-lzo-0.4.20.jar$TEZ_JARS
```
hive-site.xml
```xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
	<property>
	    <name>javax.jdo.option.ConnectionURL</name>
	    <value>jdbc:mysql://bigdata3:3306/metastore?createDatabaseIfNotExist=true</value>
	    <description>JDBC connect string for a JDBC metastore</description>
	</property>

	<property>
	    <name>javax.jdo.option.ConnectionDriverName</name>
	    <value>com.mysql.jdbc.Driver</value>
	    <description>Driver class name for a JDBC metastore</description>
	</property>

	<property>
	    <name>javax.jdo.option.ConnectionUserName</name>
	    <value>root</value>
	    <description>username to use against metastore database</description>
	</property>

	<property>
	    <name>javax.jdo.option.ConnectionPassword</name>
	    <value>hxr</value>
	    <description>password to use against metastore database</description>
	</property>
    
    <property>
         <name>hive.metastore.warehouse.dir</name>
         <value>/user/hive/warehouse</value>
         <description>location of default database for the warehouse</description>
    </property>
    
    <property>
        <name>hive.cli.print.header</name>
        <value>true</value>
    </property>

    <property>
        <name>hive.cli.print.current.db</name>
        <value>true</value>
    </property>
    
    <property>
        <name>hive.metastore.schema.verification</name>
        <value>false</value>
    </property>
    
    <property>
        <name>datanucleus.schema.autoCreateAll</name>
        <value>true</value> 
    </property>

    <property>
	<name>hive.metastore.uris</name>
	<value>thrift://bigdata1:9083</value>
    </property>

    <property>
	<name>hive.execution.engine</name>
	<value>tez</value>
    </property>

</configuration>
```
hive-log4j2.properties
```
#将原日志路径/tmp/hxr/hive.log改到hive-2.3.6文件下
property.hive.log.dir = /opt/module/hive-2.3.6/logs 
```
需要将jdbc包放到hive的库中
cp mysql-connector-java-5.1.27-bin.jar
 /opt/module/hive/lib/


<br>
**hive注释中文乱码解决**
   - 修改mysql注释相关表字段的编码格式为UTF-8
   ```
   -- 修改字段注释字符集
   alter table COLUMNS_V2 modify column comment varchar(256) character set utf8;
   -- 修改表注释字符集
   alter table TABLE_PARAMS modify column PARAM_VALUE varchar(4000) character set utf8;
   -- 修改分区参数，支持分区键用中文表示
   alter table PARTITION_PARAMS modify column PARAM_VALUE varchar(4000) character set utf8;
   alter table PARTITION_KEYS modify column PKEY_COMMENT varchar(4000) character set utf8;
   -- 修改索引名注释，支持中文表示
   alter table INDEX_PARAMS modify column PARAM_VALUE varchar(4000) character set utf8;
   -- 修改视图，支持视图中文
   ALTER TABLE TBLS modify COLUMN VIEW_EXPANDED_TEXT mediumtext CHARACTER SET utf8;
   ALTER TABLE TBLS modify COLUMN VIEW_ORIGINAL_TEXT mediumtext CHARACTER SET utf8;
   ```
   - 修改hive的jdbc连接配置如下
   ```
   <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://192.168.101.174:3306/metastore?useSSL=false&amp;useUnicode=true&amp;characterEncoding=UTF-8</value>
   </property>
   ```
完成后新建的表的中文注释就不会乱码了。如果是字段的值乱码，则需要检查该文件是否是UTF-8编码。


<br>
# 五、压缩和存储
## 5.1 Hadoop压缩配置
### 5.1.1 MR支持的压缩编码
| 压缩格式 | 算法    | 文件扩展名 | 是否可切分 |
| -------- | ------- | ---------- | ---------- |
| DEFLATE  | DEFLATE | .deflate   | 否         |
| Gzip     | DEFLATE | .gz        | 否         |
| bzip2    | bzip2   | .bz2       | 是         |
| LZO      | LZO     | .lzo       | 是         |
| Snappy   | Snappy  | .snappy    | 否         |

为了支持多种压缩/解压缩算法，Hadoop引入了编码/解码器，如下表所示：


| 压缩格式 | 对应的编码/解码器                          |
| -------- | ------------------------------------------ |
| DEFLATE  | org.apache.hadoop.io.compress.DefaultCodec |
| gzip     | org.apache.hadoop.io.compress.GzipCodec    |
| bzip2    | org.apache.hadoop.io.compress.BZip2Codec   |
| LZO      | com.hadoop.compression.lzo.LzopCodec       |
| Snappy   | org.apache.hadoop.io.compress.SnappyCodec  |

压缩性能的比较：


| 压缩算法 | 原始文件大小 | 压缩文件大小 | 压缩速度 | 解压速度 |
| -------- | ------------ | ------------ | -------- | -------- |
| gzip     | 8.3GB        | 1.8GB        | 17.5MB/s | 58MB/s   |
| bzip2    | 8.3GB        | 1.1GB        | 2.4MB/s  | 9.5MB/s  |
| LZO      | 8.3GB        | 2.9GB        | 49.3MB/s | 74.6MB/s |

[<u>http://google.github.io/snappy/</u>](http://google.github.io/snappy/)
On a single core of a Core i7 processor in 64-bit mode, Snappy compressesat about 250 MB/sec or more and decompresses at about 500 MB/sec or more.

## 5.1.2 压缩参数配置 
要在Hadoop中启用压缩，可以配置如下参数（mapred-site.xml文件中）：


| 参数                                              | 默认值                                                       | 阶段        | 建议                                         |
| ------------------------------------------------- | ------------------------------------------------------------ | ----------- | -------------------------------------------- |
| io.compression.codecs   （在core-site.xml中配置） | org.apache.hadoop.io.compress.DefaultCodec, org.apache.hadoop.io.compress.GzipCodec, org.apache.hadoop.io.compress.BZip2Codec,org.apache.hadoop.io.compress.Lz4Codec | 输入压缩    | Hadoop使用文件扩展名判断是否支持某种编解码器 |
| mapreduce.map.output.compress                     | false                                                        | mapper输出  | 这个参数设为true启用压缩                     |
| mapreduce.map.output.compress.codec               | org.apache.hadoop.io.compress.DefaultCodec                   | mapper输出  | 使用LZO、LZ4或snappy编解码器在此阶段压缩数据 |
| mapreduce.output.fileoutputformat.compress        | false                                                        | reducer输出 | 这个参数设为true启用压缩                     |
| mapreduce.output.fileoutputformat.compress.codec  | org.apache.hadoop.io.compress. DefaultCodec                  | reducer输出 | 使用标准工具或者编解码器，如gzip和bzip2      |
| mapreduce.output.fileoutputformat.compress.type   | RECORD                                                       | reducer输出 | SequenceFile输出使用的压缩类型：NONE和BLOCK  |

<br>
## 5.2 开启Map输出阶段压缩（MR引擎）
开启map输出阶段压缩可以减少job中map和Reduce task间数据传输量。具体配置如下：
**1）案例实操：**
（1）开启hive中间传输数据压缩功能
```
hive (default)>set hive.exec.compress.intermediate=true;
```
（2）开启mapreduce中map输出压缩功能
```
hive (default)>set mapreduce.map.output.compress=true;
```
（3）设置mapreduce中map输出数据的压缩方式
```
hive (default)>set mapreduce.map.output.compress.codec=
 org.apache.hadoop.io.compress.SnappyCodec;
```
（4）执行查询语句
```
hive (default)> select count(ename) name from emp;
```

<br>
## 5.3 开启Reduce输出阶段压缩
当Hive将输出写入到表中时，输出内容同样可以进行压缩。属性hive.exec.compress.output控制着这个功能。用户可能需要保持默认设置文件中的默认值false，这样默认的输出就是非压缩的纯文本文件了。用户可以通过在查询语句或执行脚本中设置这个值为true，来开启输出结果压缩功能。

**1）案例实操：**
（1）开启hive最终输出数据压缩功能
```
hive (default)>set hive.exec.compress.output=true;
```
（2）开启mapreduce最终输出数据压缩
```
hive (default)>set mapreduce.output.fileoutputformat.compress=true;
```
（3）设置mapreduce最终数据输出压缩方式
```
hive (default)> set mapreduce.output.fileoutputformat.compress.codec = org.apache.hadoop.io.compress.SnappyCodec;
```
（4）设置mapreduce最终数据输出压缩为块压缩
```
hive (default)> set mapreduce.output.fileoutputformat.compress.type=BLOCK;
```
（5）测试一下输出结果是否是压缩文件
```
hive (default)> insert overwrite local directory '/opt/module/data/distribute-result' select * from emp distribute by deptno sort by empno desc;
```

<br>
## 5.4 文件存储格式
Hive支持的存储数据的格式主要有：TEXTFILE 、SEQUENCEFILE、ORC、PARQUET。

### 5.4.1 列式存储和行式存储
![image.png](Hive基础.assets\4d7a3432d7f0477d897bb8ac5aaa229e.png)

如图所示左边为逻辑表，右边第一个为行式存储，第二个为列式存储。
**1）行存储的特点**
查询满足条件的一整行数据的时候，列存储则需要去每个聚集的字段找到对应的每个列的值，行存储只需要找到其中一个值，其余的值都在相邻地方，所以此时行存储查询的速度更快。
**2）列存储的特点**
因为每个字段的数据聚集存储，在查询只需要少数几个字段的时候，能大大减少读取的数据量；每个字段的数据类型一定是相同的，列式存储可以针对性的设计更好的设计压缩算法。
TEXTFILE和SEQUENCEFILE的存储格式都是基于行存储的；
ORC和PARQUET是基于列式存储的。

<br>
### 5.4.2 TextFile格式
默认格式，数据不做压缩，磁盘开销大，数据解析开销大。可结合Gzip、Bzip2使用，但使用Gzip这种方式，hive不会对数据进行切分，从而无法对数据进行并行操作。

<br>
### 5.4.3 Orc格式
Orc (Optimized Row Columnar)是Hive 0.11版里引入的新的存储格式。
如下图所示可以看到每个Orc文件由1个或多个stripe组成，每个stripe一般为HDFS的块大小，每一个stripe包含多条记录，这些记录按照列进行独立存储，对应到Parquet中的row group的概念。每个Stripe里有三部分组成，分别是Index Data，Row Data，Stripe Footer：

![image.png](Hive基础.assets8c09f2f239243b99254bead7687bbe9.png)


**1）Index Data：**一个轻量级的index，默认是每隔1W行做一个索引。这里做的索引应该只是记录某行的各字段在Row Data中的offset。
**2）Row Data：**存的是具体的数据，先取部分行，然后对这些行按列进行存储。对每个列进行了编码，分成多个Stream来存储。
**3）Stripe Footer：**存的是各个Stream的类型，长度等信息。
每个文件有一个File Footer，这里面存的是每个Stripe的行数，每个Column的数据类型信息等；每个文件的尾部是一个PostScript，这里面记录了整个文件的压缩类型以及FileFooter的长度信息等。在读取文件时，会seek到文件尾部读PostScript，从里面解析到File Footer长度，再读FileFooter，从里面解析到各个Stripe信息，再读各个Stripe，即从后往前读。


**可以简单理解为下图**
![](Hive基础.assets276c702ebee4443a8006a9b7f729bd5.png)

左边的图就表示了传统的行式数据库存储方式，按行存储，如果没有存储索引的话，如果需要查询一个字段，就需要把整行的数据都查出来然后做筛选，这么做式比较消耗IO资源的，于是在Hive种最开始也是用了索引的方式来解决这个问题。

但是由于索引的高成本，在「目前的Hive3.X 中，已经废除了索引」，当然也早就引入了列式存储。

列式存储的存储方式，其实和名字一样，它是按照一列一列存储的，如上图中的右图，这样的话如果查询一个字段的数据，就等于是索引查询，效率高。但是如果需要查全表，它因为需要分别取所有的列最后汇总，反而更占用资源。于是ORC行列式存储出现了。

1. 在需要全表扫描时，可以按照行组读取
2. 如果需要取列数据，在行组的基础上，读取指定的列，而不需要所有行组内所有行的数据和一行内所有字段的数据。

![image.png](Hive基础.assets7c72276b856499abb99fa71728ae324.png)

所以其实发现，ORC提供了3级索引，文件级、条带级、行组级，所以在查询的时候，利用这些索引可以规避大部分不满足查询条件的文件和数据块。

**「特别注意：ORC格式的表还支持事务ACID，但是支持事务的表必须为分桶表，所以适用于更新大批量的数据，不建议用事务频繁的更新小批量的数据」**
```
#开启并发支持,支持插入、删除和更新的事务
set hive. support concurrency=truei
#支持ACID事务的表必须为分桶表
set hive. enforce bucketing=truei
#开启事物需要开启动态分区非严格模式
set hive.exec,dynamicpartition.mode-nonstrict
#设置事务所管理类型为 org. apache.hive.q1. lockage. DbTxnManager
#原有的org. apache. hadoop.hive.q1.1 eckmar. DummyTxnManager不支持事务
set hive. txn. manager=org. apache. hadoop. hive. q1. lockmgr DbTxnManageri
#开启在相同的一个 meatore实例运行初始化和清理的线程
set hive. compactor initiator on=true:
#设置每个 metastore实例运行的线程数 hadoop
set hive. compactor. worker threads=l
#(2)创建表
create table student_txn
(id int,
name string
)
#必须支持分桶
clustered by (id) into 2 buckets
#在表属性中添加支持事务
stored as orc
TBLPROPERTIES('transactional'='true‘);
#(3)插入数据
#插入id为1001,名字为student 1001
insert into table student_txn values('1001','student 1001');
#(4)更新数据
#更新数据
update student_txn set name= 'student 1zh' where id='1001';
# (5)查看表的数据,最终会发现id为1001被改为 sutdent_1zh
```

1.2关于ORC的Hive配置
表配置属性（建表时配置，例如tblproperties ('orc.compress'='snappy');：
- orc.compress:表示ORC文件的压缩类型，「可选的类型有NONE、ZLB和SNAPPY，默认值是ZLIB（Snappy不支持切片）」---这个配置是最关键的。
- orc. compress.Slze:表示压缩块( chunk)的大小,默认值是262144(256KB)。
- orc. stripe.size:写 stripe,可以使用的内存缓冲池大小,默认值是67108864(64MB）
- orc. row. index. stride:行组级别索引的数据量大小,默认是10000,必须要设置成大于等于10000的数
- orc. create index:是否创建行组级别索引,默认是true
- orc. bloom filter. columns:需要创建布隆过滤的组。
- orc. bloom filter fpp:使用布隆过滤器的假正( False Positive)概率,默认值是0. 扩展:在Hive中使用 bloom过滤器,可以用较少的文件空间快速判定数据是否存表中,但是也存在将不属于这个表的数据判定为属于这个这表的情况,这个称之为假正概率,开发者可以调整该概率,但概率越低,布隆过滤器所需要。



<br>
### 5.4.4 Parquet格式
既然ORC都那么高效了，那为什么还要再来一个Parquet，那是因为orc支持的压缩格式可选的类型为NONE、ZLB和SNAPPY，都不支持数据切片，而parquet支持多种格式的切片。**「Parquet是为了使Hadoop生态系统中的任何项目都可以使用压缩的，高效的列式数据表示形式」**。
>❝ Parquet 是语言无关的，而且不与任何一种数据处理框架绑定在一起，适配多种语言和组件，能够与 Parquet 配合的组件有：
查询引擎: Hive, Impala, Pig, Presto, Drill, Tajo, HAWQ, IBM Big SQL
计算框架: MapReduce, Spark, Cascading, Crunch, Scalding, Kite
数据模型: Avro, Thrift, Protocol Buffers, POJOs
❞

Parquet文件是以二进制方式存储的，所以是不可以直接读取的，文件中包括该文件的数据和元数据，因此Parquet格式文件是自解析的。
**（1）行组(Row Group)：**每一个行组包含一定的行数，在一个HDFS文件中至少存储一个行组，类似于orc的stripe的概念。
**（2）列块(Column Chunk)：**在一个行组中每一列保存在一个列块中，行组中的所有列连续的存储在这个行组文件中。一个列块中的值都是相同类型的，不同的列块可能使用不同的算法进行压缩。
**（3）页(Page)：**每一个列块划分为多个页，一个页是最小的编码的单位，在同一个列块的不同页可能使用不同的编码方式。
通常情况下，在存储Parquet数据的时候会按照Block大小设置行组的大小，由于一般情况下每一个Mapper任务处理数据的最小单位是一个Block，这样可以把每一个行组由一个Mapper任务处理，增大任务执行并行度。Parquet文件的格式。

![image.png](Hive基础.assets\21a4868ca8d7403ca13174fa574407ab.png)

简易版如下：
![image.png](Hive基础.assets\39043c4992e748c6b861fc9c79739c35.png)

Parquet文件是以二进制方式存储的，所以不可以直接读取，和ORC一样，文件的元数据和数据一起存储，所以Parquet格式文件是自解析的。

上图展示了一个Parquet文件的内容，一个文件中可以存储多个行组，文件的首位都是该文件的Magic Code，用于校验它是否是一个Parquet文件，Footer length记录了文件元数据的大小，通过该值和文件长度可以计算出元数据的偏移量，文件的元数据中包括每一个行组的元数据信息和该文件存储数据的Schema信息。除了文件中每一个行组的元数据，每一页的开始都会存储该页的元数据，在Parquet中，有三种类型的页：数据页、字典页和索引页。数据页用于存储当前行组中该列的值，字典页存储该列值的编码字典，每一个列块中最多包含一个字典页，索引页用来存储当前行组下该列的索引，目前Parquet中还不支持索引页。

- 行组(Row Group)：每一个行组包含一定的行数，在一个HDFS文件中至少存储一个行组，类似于orc的stripe的概念。
- 列块(Column Chunk)：在一个行组中每一列保存在一个列块中，行组中的所有列连续的存储在这个行组文件中。一个列块中的值都是相同类型的，不同的列块可能使用不同的算法进行压缩。
- 页(Page)：每一个列块划分为多个页，一个页是最小的编码的单位，在同一个列块的不同页可能使用不同的编码方式。

**Parquet的表配置属性**
parquet. block size:默认值为134217728byte,即128MB,表示 Row Group在内存中的块大小。该值设置得大,可以提升 Parquet文件的读取效率,但是相应在写的时候需要耗费更多的内存
parquet. page:size:默认值为1048576byt,即1MB,表示每个页(page)的大小。这个特指压缩后的页大小,在读取时会先将页的数据进行解压。页是 Parquet操作数据的最小单位,每次读取时必须读完一整页的数据才能访问数据。这个值如果设置得过小,会导致压缩时出现性能问题
parquet. compression:默认值为 UNCOMPRESSED，表示页的压缩方式。「可以使用的压缩方式有 UNCOMPRESSED、 SNAPPY、GZP和LZO」。
Parquet enable. dictionary:默认为tue,表示是否启用字典编码。
parquet. dictionary page.size:默认值为1048576byte,即1MB。在使用字典编码时,会在 Parquet的每行每列中创建一个字典页。使用字典编码,如果存储的数据页中重复的数据较多,能够起到一个很好的压缩效果,也能减少每个页在内存的占用。

**如果需要查全表**
1. 在需要全表扫描时，可以按照行组读取
2. 如果需要取列数据，在行组的基础上，读取指定的列，而不需要所有行组内所有行的数据和一行内所有字段的数据。




<br>
### 5.4.5 主流文件存储格式对比实验
从存储文件的压缩比和查询速度两个角度对比。
存储文件的压缩比测试：

**1）测试数据**
使用10w条如下格式测试数据进行测试
```
2017-08-10 13:00:00	http://www.taobao.com/17/?tracker_u=1624169&type=1	B58W48U4WKZCJ5D1T3Z9ZY88RU7QA7B1	http://hao.360.cn/	1.196.34.243	NULL	-1
2017-08-10 13:00:00	http://www.taobao.com/item/962967_14?ref=1_1_52_search.ctg_1	T82C9WBFB1N8EW14YF2E2GY8AC9K5M5P	http://www.yihaodian.com/ctg/s2/c24566-%E5%B1%B1%E6%A5%82%E5%88%B6%E5%93%81?ref=pms_15_78_258	222.78.246.228	134939954	156
2017-08-10 13:00:00	http://www.taobao.com/1/?tracker_u=1013304189&uid=2687512&type=3	W17C89RU8DZ6NMN7JD2ZCBDMX1CQVZ1W	http://www.yihaodian.com/1/?tracker_u=1013304189&uid=2687512&type=3	118.205.0.18	NULL	-20
2017-08-10 13:00:00	http://m.taobao.com/getCategoryByRootCategoryId_1_5146	f55598cafba346eb217ff3fbd0de2930	http://m.yihaodian.com/getCategoryByRootCategoryId_1_5135	10.4.6.53	NULL	-1000
2017-08-10 13:00:00	http://m.taobao.com/getCategoryByRootCategoryId_1_24728	f55598cafba346eb217ff3fbd0de2930	http://m.yihaodian.com/getCategoryByRootCategoryId_1_5146	10.4.4.109	NULL	-1000
```

**2）TextFile**
（1）创建表，存储数据格式为TEXTFILE
```
create table log_text (
track_time string,
url string,
session_id string,
referer string,
ip string,
end_user_id string,
city_id string
)
row format delimited fields terminated by '	'
stored as textfile;
```
（2）向表中加载数据
```
hive (default)> load data local inpath '/opt/module/hive/datas/log.data' into table log_text ;
```
（3）查看表中数据大小
```
hive (default)> dfs -du -h /user/hive/warehouse/log_text;
18.13 M  /user/hive/warehouse/log_text/log.data
```

**3）ORC**
（1）创建表，存储数据格式为ORC
```
create table log_orc(
track_time string,
url string,
session_id string,
referer string,
ip string,
end_user_id string,
city_id string
)
row format delimited fields terminated by '	'
stored as orc
tblproperties("orc.compress"="NONE"); -- 设置orc存储不使用压缩
```
（2）向表中加载数据
```
hive (default)> insert into table log_orc select * from log_text;
```
（3）查看表中数据大小
```
hive (default)> dfs -du -h /user/hive/warehouse/log_orc/ ;

7.7 M  /user/hive/warehouse/log_orc/000000_0
```
**4）Parquet**
（1）创建表，存储数据格式为parquet
```
create table log_parquet(
track_time string,
url string,
session_id string,
referer string,
ip string,
end_user_id string,
city_id string
)
row format delimited fields terminated by '	'
stored as parquet;
```
**（2）向表中加载数据**
```
hive (default)> insert into table log_parquet select * from log_text;
```
**（3）查看表中数据大小**
```
hive (default)> dfs -du -h /user/hive/warehouse/log_parquet/;
13.1 M  /user/hive/warehouse/log_parquet/000000_0
```

**存储文件的对比总结：**
`ORC >  Parquet >  textFile`

**存储文件的查询速度测试：**
（1）TextFile
```
hive (default)> insert overwrite local directory '/opt/module/data/log_text' select substring(url,1,4) from log_text;
```
（2）ORC
```
hive (default)> insert overwrite local directory '/opt/module/data/log_orc' select substring(url,1,4) from log_orc;
```
（3）Parquet
```
hive (default)> insert overwrite local directory '/opt/module/data/log_parquet' select substring(url,1,4) from log_parquet;
```
`存储文件的查询速度总结：查询速度相近。`

![image.png](Hive基础.assets\d469b2514b5b4498ac558754eec91188.png)

![image.png](Hive基础.assets\738e757a77e74e1b8a419287c1d97e0a.png)

同时，从《Hive性能调优实战》作者的案例中，2张分别采用ORC和Parquet存储格式的表，导入同样的数据，进行sql查询，**「发现使用ORC读取的行远小于Parquet」**，所以使用ORC作为存储，可以借助元数据过滤掉更多不需要的数据，查询时需要的集群资源比Parquet更少。（查看更详细的性能分析，请移步[https://blog.csdn.net/yu616568/article/details/51188479](https://link.zhihu.com/?target=https%3A//blog.csdn.net/yu616568/article/details/51188479)）


<br>
**大小为100G的textfile格式文件性能测试结果**
| 存储格式	| ORC	| Sequencefile	| Parquet	| RCfile	| Avro |
| --- | --- | --- | --- | --- | --- |
| 数据压缩后大小	| 1.8G	| 67.0G	| 11G	| 63.8G	| 66.7G | 
| 存储耗费时间	| 535.7s	| 625.8s	| 537.3s	| 543.48	| 544.3 | 
| SQL查询响应速度	| 19.63s	| 184.07s	| 24.22s	| 88.5s	| 281.65s | 

<br>
## 5.5 存储和压缩结合
### 5.5.1 测试存储和压缩
[官网](https://cwiki.apache.org/confluence/display/Hive/LanguageManual+ORC)

**ORC存储方式的压缩：**

| Key                      | Default     | Notes                                                        |
| ------------------------ | ----------- | ------------------------------------------------------------ |
| orc.compress             | ZLIB       | high level compression (one of NONE, ZLIB, SNAPPY)           |
| orc.compress.size        | 262,144     | number of bytes in each compression chunk                    |
| orc.stripe.size          | 268,435,456 | number of bytes in each stripe                               |
| orc.row.index.stride     | 10,000      | number of rows between index entries (must be >= 1000)       |
| orc.create.index         | true        | whether to create row indexes                                |
| orc.bloom.filter.columns | ""          | comma separated list of column names for which bloom filter should be created |
| orc.bloom.filter.fpp     | 0.05        | false positive probability for bloom filter (must >0.0 and <1.0) |
注意：所有关于ORCFile的参数都是在HQL语句的TBLPROPERTIES字段里面出现.

**1）创建一个ZLIB压缩的ORC存储方式**
（1）建表语句
```
create table log_orc_zlib(
track_time string,
url string,
session_id string,
referer string,
ip string,
end_user_id string,
city_id string
)
row format delimited fields terminated by '	'
stored as orc
tblproperties("orc.compress"="ZLIB");
```
（2）插入数据
```
insert into log_orc_zlib select * from log_text;
```
（3）查看插入后数据
```
hive (default)> dfs -du -h /user/hive/warehouse/log_orc_zlib/ ;

2.78 M  /user/hive/warehouse/log_orc_none/000000_0
```

**2）创建一个SNAPPY压缩的ORC存储方式**
（1）建表语句
```
create table log_orc_snappy(
track_time string,
url string,
session_id string,
referer string,
ip string,
end_user_id string,
city_id string
)
row format delimited fields terminated by '	'
stored as orc
tblproperties("orc.compress"="SNAPPY");
```
（2）插入数据
```
insert into log_orc_snappy select * from log_text;
```
（3）查看插入后数据
```
hive (default)> dfs -du -h /user/hive/warehouse/log_orc_snappy/;
3.75 M  /user/hive/warehouse/log_orc_snappy/000000_0
```
ZLIB比Snappy压缩的还小。原因是ZLIB采用的是deflate压缩算法。比snappy压缩的压缩率高。

**3）创建一个SNAPPY压缩的parquet存储方式**
（1）建表语句
```
create table log_parquet_snappy(
track_time string,
url string,
session_id string,
referer string,
ip string,
end_user_id string,
city_id string
)
row format delimited fields terminated by '	'
stored as parquet
tblproperties("parquet.compression"="SNAPPY");
```
（2）插入数据
```
insert into log_parquet_snappy select * from log_text;
```
（3）查看插入后数据
```
hive (default)> dfs -du -h /user/hive/warehouse/log_parquet_snappy/;
6.39 MB  /user/hive/warehouse/ log_parquet_snappy /000000_0
```
**4）存储方式和压缩总结**
在实际的项目开发当中，hive表的数据存储格式一般选择：orc或parquet。压缩方式一般选择snappy，lzo。

**3）创建一个LZO压缩的parquet存储方式**
```
DROP TABLE IF EXISTS dim_coupon_info;
CREATE EXTERNAL TABLE dim_coupon_info(
    `id` STRING COMMENT '购物券编号',
    `coupon_name` STRING COMMENT '购物券名称',
    `coupon_type` STRING COMMENT '购物券类型 1 现金券 2 折扣券 3 满减券 4 满件打折券',
    `condition_amount` DECIMAL(16,2) COMMENT '满额数',
    `condition_num` BIGINT COMMENT '满件数',
    `activity_id` STRING COMMENT '活动编号',
    `benefit_amount` DECIMAL(16,2) COMMENT '减金额',
    `benefit_discount` DECIMAL(16,2) COMMENT '折扣',
    `create_time` STRING COMMENT '创建时间',
    `range_type` STRING COMMENT '范围类型 1、商品 2、品类 3、品牌',
    `limit_num` BIGINT COMMENT '最多领取次数',
    `taken_count` BIGINT COMMENT '已领取次数',
    `start_time` STRING COMMENT '可以领取的开始日期',
    `end_time` STRING COMMENT '可以领取的结束日期',
    `operate_time` STRING COMMENT '修改时间',
    `expire_time` STRING COMMENT '过期时间'
) COMMENT '优惠券维度表'
PARTITIONED BY (`dt` STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '	'
STORED AS PARQUET
LOCATION '/warehouse/gmall/dim/dim_coupon_info/'
TBLPROPERTIES ("parquet.compression"="lzo");
```

<br>
## 5.6 总结
根据ORC和parquet的要求，一般就有了
1、ORC格式存储，Snappy压缩
```
create table stu_orc(id int,name string)
stored as orc 
tblproperties ('orc.compress'='snappy');
```
2、Parquet格式存储，Lzo压缩
```
create table stu_par(id int,name string)
stored as parquet 
tblproperties ('parquet.compression'='lzo');
```
3、Parquet格式存储，Snappy压缩
```
create table stu_par(id int,name string)
stored as parquet 
tblproperties ('parquet.compression'='snappy');
```
因为Hive 的SQL会转化为MR任务，如果该文件是用ORC存储，Snappy压缩的，因为Snappy不支持文件分割操作，所以压缩文件「只会被一个任务所读取」，如果该压缩文件很大，那么处理该文件的Map需要花费的时间会远多于读取普通文件的Map时间，这就是常说的「Map读取文件的数据倾斜」。

那么为了避免这种情况的发生，就需要在数据压缩的时候采用bzip2和Zip等支持文件分割的压缩算法。但恰恰ORC不支持刚说到的这些压缩方式，所以这也就成为了大家在可能遇到大文件的情况下不选择ORC的原因，避免数据倾斜。

在Hive on Spark的方式中，也是一样的，Spark作为分布式架构，通常会尝试从多个不同机器上一起读入数据。要实现这种情况，每个工作节点都必须能够找到一条新记录的开端，也就需要该文件可以进行分割，但是有些不可以分割的压缩格式的文件，必须要单个节点来读入所有数据，这就很容易产生性能瓶颈。(下一篇文章详细写Spark读取文件的源码分析)

**「所以在实际生产中，使用Parquet存储，lzo压缩的方式更为常见，这种情况下可以避免由于读取不可分割大文件引发的数据倾斜。 但是，如果数据量并不大（预测不会有超大文件，若干G以上）的情况下，使用ORC存储，snappy压缩的效率还是非常高的。」**


<br>
使用lzo压缩并有索引时，需要注意：
>hive在join时，会误把lzo索引当成小文件进行合并，并插入一条。
select * from ods_log不执行MR操作，直接采用的是ods_log建表语句中指定的DeprecatedLzoTextInputFormat，能够识别lzo.index为索引文件。
select count(*) from ods_log执行MR操作，会先经过hive.input.format，其默认值为CombineHiveInputFormat，其会先将索引文件当成小文件合并，将其当做普通文件处理。
- 解决：在对ods表进行降维等操作时，直接关闭hive自动合并小文件即可 `set hive.input.format=org.apache.hadoop.hive.ql.io.HiveInputFormat`

<br>
# 六、参考
https://cwiki.apache.org/confluence/display/Hive/HivePlugins
[Hive数仓建表该选用ORC还是Parquet，压缩选LZO还是Snappy？ - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/257917645)
