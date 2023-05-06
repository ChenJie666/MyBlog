---
title: Hive面试题
categories:
- 大数据建模
---
# 第 1 题 连续问题
## 1 问题描述
如下数据为蚂蚁森林中用户领取的减少碳排放量
```
id dt lowcarbon
1001 2021-12-12 123
1002 2021-12-12 45
1001 2021-12-13 43
1001 2021-12-13 45
1001 2021-12-13 23
1002 2021-12-14 45
1001 2021-12-14 230
1002 2021-12-15 45
1001 2021-12-15 23
… …
```
找出连续 3 天及以上减少碳排放量在 100 以上的用户

## 2 解决
1. 首先计算每个用户每日的碳排放量，过滤掉小于100的数据
2. 开窗函数计算每条记录的排名，然后日期减去排名
3. 然后根据用户和计算后日期分组，如果日期统计数量>=3，那么该日期就是连续开始日期的前一天。

```
select id, date_add(flag, 1) as start_date, count(*) as cnt
from (
         select id, date_sub(dt, rank) as flag
         from (
                  select id,
                         dt,
                         rank()
                                 over (partition by id order by dt) as rank
                  from (
                           select id, dt, sum(lowcarbon) as carbon
                           from default.question1
                           group by id, dt
                       ) t1
                  where carbon >= 100
              ) t2
     ) t3
group by id, flag
having cnt >= 3;
```

<br>
# 第 2 题 分组问题
## 1 问题描述
如下为电商公司用户访问时间数据
```
id ts(秒)
1001 17523641234
1001 17523641256
1002 17523641278
1001 17523641334
1002 17523641434
1001 17523641534
1001 17523641544
1002 17523641634
1001 17523641638
1001 17523641654
```
某个用户连续的访问记录如果时间间隔小于 60 秒，则分为同一个组，结果为：
```
id ts(秒) group
1001 17523641234 1
1001 17523641256 1
1001 17523641334 2
1001 17523641534 3
1001 17523641544 3
1001 17523641638 4
1001 17523641654 4
1002 17523641278 1
1002 17523641434 2
1002 17523641634 3
```

## 2 解决
1. 首先计算出用户上次登陆时间与本次登陆时间的时间间隔gap
```
id, ts, gap
1001,17523641234,17523641234
1001,17523641256,22
1001,17523641334,78
1001,17523641534,200
1001,17523641544,10
1001,17523641638,94
1001,17523641654,16
1002,17523641278,17523641278
1002,17523641434,156
1002,17523641634,200
```
可以发现，每次时间间隔gap大于60时，就进入下一组

2. 进行分组
这里需要使用比较巧妙的方法，判断时间间隔是否小于60，用0和1表示结果，将判断结果相加得到分组号。

hql如下
```
select id,
       ts,
       sum(if(gap >= 60, 1, 0)) over (partition by id order by ts rows between unbounded preceding and current row )
from (
         select id,
                ts,
                ts - lag(ts, 1, 0)
                         over (partition by id order by ts) as gap
         from default.question2) t1;
```


<br>
# 第 3 题 间隔连续问题
## 1 问题描述
某游戏公司记录的用户每日登录数据
```
id dt
1001 2021-12-12
1002 2021-12-12
1001 2021-12-13
1001 2021-12-14
1001 2021-12-16
1002 2021-12-16
1001 2021-12-19
1002 2021-12-17
1001 2021-12-20
```
计算每个用户最大的连续登录天数，可以间隔一天。解释：如果一个用户在 1,3,5,6 登录游戏，则视为连续 6 天登录。

## 2 解决
1. 计算每个用户每次登陆的日期间隔
2. 使用问题2的分组方式分组
3. 合并分组获取连续登录的首日和末日，相减加一得到连续登录天数。

```
select id,
       min(dt) as first_day,
       max(dt) as last_day,
       datediff(max(dt), min(dt)) + 1
from (
         select id,
                dt,
                gap,
                sum(if(gap >= 3, 1, 0))
                    over (partition by id order by dt rows between unbounded preceding and current row) as groupid
         from (
                  select id,
                         dt,
                         datediff(dt, lag(dt, 1, date_sub(dt, 1))
                                          over (partition by id order by dt)) as gap
                  from default.question3
              ) t1
     ) t2
group by id, groupid;
```

<br>
# 第 4 题 打折日期交叉问题
## 1 问题描述
如下为平台商品促销数据：字段为品牌，打折开始日期，打折结束日期
```
brand stt edt
oppo 2021-06-05 2021-06-09
oppo 2021-06-11 2021-06-21
vivo 2021-06-05 2021-06-15
vivo 2021-06-09 2021-06-21
redmi 2021-06-05 2021-06-21
redmi 2021-06-09 2021-06-15
redmi 2021-06-17 2021-06-26
huawei 2021-06-05 2021-06-26
huawei 2021-06-09 2021-06-15
huawei 2021-06-17 2021-06-21
```
计算每个品牌总的打折销售天数，注意其中的交叉日期，比如 vivo 品牌，第一次活动时间为 2021-06-05 到 2021-06-15，第二次活动时间为 2021-06-09 到 2021-06-21 其中 9 号到 15 号为重复天数，只统计一次，即 vivo 总打折天数为 2021-06-05 到 2021-06-21 共计 17 天。

## 2 解决
1. 需要解决日期的重叠问题，将每个品牌的日期改为不重叠。思路就是，按照首日排序，排序后的记录的首日日期改为前序记录最大末日日期的后一天。
2. 然后计算每段日期的天数，筛掉负数后相加即可。

```
select brand,
       sum(if(datediff(edt, new_stt) > 0, datediff(edt, new_stt) + 1, 0)) as date_sum
from (
         select brand,
                stt,
                edt,
                if(datediff(max_edt, stt) > 0, date_add(max_edt, 1), stt) as new_stt
         from (
                  select brand,
                         stt,
                         edt,
                         max(edt)
                             over (partition by brand order by stt rows between unbounded preceding and 1 preceding) as max_edt
                  from default.question4
              ) t1
     ) t2
group by brand;
```


<br>
# 第 5 题 同时在线问题
## 1 问题描述
如下为某直播平台主播开播及关播时间，根据该数据计算出平台最高峰同时在线的主播人数。
```
id stt edt
1001 2021-06-14 12:12:12 2021-06-14 18:12:12
1003 2021-06-14 13:12:12 2021-06-14 16:12:12
1004 2021-06-14 13:15:12 2021-06-14 20:12:12
1002 2021-06-14 15:12:12 2021-06-14 16:12:12
1005 2021-06-14 15:18:12 2021-06-14 20:12:12
1001 2021-06-14 20:12:12 2021-06-14 23:12:12
1006 2021-06-14 21:12:12 2021-06-14 23:15:12
1007 2021-06-14 22:12:12 2021-06-14 23:10:12
… …
```

## 2 解决
1. 采用流式计算的思想，按每个时间点进行相加。思路就是，将一条记录拆分为上线和下线记录。然后按时间进行累加，上线加一，下线减一。
2. 得到每个时间点的在线人数，筛选出最大值即可。

```
select max(online_num) as max_online_num
from (
         select id, ts, sum(p) over (order by ts rows between unbounded preceding and current row ) as online_num
         from (
                  select id, stt as ts, 1 as p
                  from default.question5
                  union all
                  select id, edt as ts, -1 as p
                  from default.question5
              ) t1
     ) t2;
```

<br>
# 第6题 
## 1 问题描述
需要获取上次库存值非零的日期，即获取last_date这一列。
|date|invt|$