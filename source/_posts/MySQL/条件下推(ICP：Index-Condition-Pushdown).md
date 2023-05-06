---
title: 条件下推(ICP：Index-Condition-Pushdown)
categories:
- MySQL
---
       “索引条件下推”，称为 Index Condition Pushdown (ICP)，这是MySQL提供的用某一个索引对一个特定的表从表中获取元组”，注意我们这里特意强调了“一个”，这是因为这样的索引优化不是用于多表连接而是用于单表扫描，确切地说，是单表利用索引进行扫描以获取数据的一种方式。 
        当没有icp时，存储引擎会运用索引定位到符合索引条件的行，将这些行发送给MySQL server去计算where 条件是否正确。当有icp时，如果where 条件的一部分可以通过索引来计算（意思就是索引中包含的信息可以计算这一部分where条件），那么MySQL Server就会将这部分索引条件下推到（index condition push）存储引擎（下推的意思可以看MySQL逻辑架构图）去计算，这样的话就可以返回尽量少的行给MySQL Server，也尽量少的让MySQL Server访问存储引擎层。简单来说就是索引中存储了计算where条件的信息，索引下推过滤后直接将符合条件的数据给到存储引擎计算，减少了IO。

关闭ICP：set optimizer_switch='index_condition_pushdown=off';
开启ICP：set optimizer_switch='index_condition_pushdown=on';

#关闭ICP后执行过程：
EXPLAIN SELECT * FROM t4 WHERE 1=t4.a4 AND t4.name like 'char%'; 
![image.png](条件下推(ICP：Index-Condition-Pushdown).assets