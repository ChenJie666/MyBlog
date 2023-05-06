---
title: join、in、exits效率问题
categories:
- MySQL
---
in 是把外表和内表作hash链接

exists是对外表作loop循环，每次loop循环再对内表进行查询。

一直以来总认为exists比in的效率高，这种说法是不准确的。如果查询的两个表大小相当的话，那么用in和exists的效率差别不大。

如果两个表中一个较小的表A，一个大表B，两个表都有字段cc

则有以下几种情况：
```
select * from A where cc in (select cc from B)
 效率低，用到了A 表上cc 列的索引；
```

```
select * from A where exists(select cc from B where cc=A.cc)
效率高，用到了B 表上cc 列的索引。
```


相反的
```
select * from B where cc in (select cc from A)
效率高，用到了B 表上cc 列的索引；
```

```
select * from B where exists(select cc from A where cc=B.cc)
效率低，用到了A 表上cc 列的索引。
```


对于not in和not exists

如果查询语句使用了not in，那么内外表都进行全表扫描，没有用到索引；

而not exists的子查询依然能用到表上的索引，所以无论哪个表大，用not exists都比in效率更高。
