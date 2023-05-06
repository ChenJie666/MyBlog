---
title: Hive进阶
categories:
- 大数据离线
---
# 一、Explain查看执行计划
## 1.1 准备
```
// 创建大表
create table bigtable
(
    id        bigint,
    t         bigint,
    uid       string,
    keyword   string,
    url_rank  int,
    click_num int,
    click_url string
) row format delimited
    fields terminated by '	';
// 创建小表
create table smalltable
(
    id        bigint,
    t         bigint,
    uid       string,
    keyword   string,
    url_rank  int,
    click_num int,
    click_url string
) row format delimited
    fields terminated by '	';
// 创建 JOIN 后表
create table jointable
(
    id        bigint,
    t         bigint,
    uid       string,
    keyword   string,
    url_rank  int,
    click_num int,
    click_url string
) row format delimited
    fields terminated by '	';
```
将数据导入到表中，smalltable有10w条，bigtable有100w条。

## 1.2 基本语法
`EXPLAIN [EXTENDED | DEPENDENCY | AUTHORIZATION] query-sql`

**结果分为**
- 第一阶段：展示抽象语法树
首先指定表，从例子可以看出指定emp表，然后是否把查询结构插入到另一个表，由这个例子仅仅是查询，所以insert这部分为空。最后是查询的字段，由于我们写的是“*”所以展示为 TOK_ALLCOLREF全部字段；
- 第二阶段：展示各个阶段的依赖关系
由于我们这个查询语句过于简单，所以并没有启动MapReduce，只有一个阶段，没有显示出依赖关系；
- 第三阶段：对Stage-0这个阶段进行详细解读

名词解释
- TableScan：查看表
- alias：所需要的表
- Statistics：这张表的基本信息
- expressions：表中需要输出的字段及类型
outputColumnNames：输出的的字段编号

## 1.3 案例实操
1）查看下面语句的执行计划
```
hive (default)> explain select * from smalltable;
```

![image.png](Hive进阶.assetsbaa8c5fcc4f4156a0fe7cb58e231968.png)


```
hive (default)> explain select click_url, count(*) ct from bigtable group by click_url;
```
![image.png](Hive进阶.assets