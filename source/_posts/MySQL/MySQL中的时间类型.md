---
title: MySQL中的时间类型
categories:
- MySQL
---
| 类型      | 大小 | 范围                                    | 格式                | 用途                     |
| --------- | ---- | --------------------------------------- | ------------------- | ------------------------ |
| DATE      | 3    | 1000-01-01/9999-12-31                   | YYYY-MM-DD          | 日期值                   |
| TIME      | 3    | '-838:59:59'/'838:59:59'                | HH:MM:SS            | 时间值或持续时间         |
| YEAR      | 1    | 1901/2155                               | YYYY                | 年份值                   |
| DATETIME  | 8    | 1000-01-01 00:00:00/9999-12-31 23:59:59 | YYYY-MM-DD HH:MM:SS | 混合日期和时间值         |
| TIMESTAMP | 4    | 1970-01-01 00:00:00/2038                | YYYYMMDD HHMMSS     | 混合日期和时间值，时间戳 |

<br>
**TIMESTAMP和DATETIME的相同点：**
- 两者都可用来表示yyyy-MM-dd HH:mm:ss[.fraction]类型的日期。
- 服务端会根据本地时区和MySQL时区自动转换时区，所以两者存储的都是创建连接时MySQL所在的时区时间。

**TIMESTAMP和DATETIME的不同点：**
- 两者的存储方式不一样：datetime占用8字节，timestamp占用4字节，timestamp底层被存储为int类型。
- 可以存储的时间范围不同：datetime类型取值范围(1000-01-01 00:00:00 到 9999-12-31 23:59:59)；timestamp类型取值范围(1970-01-01 08:00:01 到2038-01-19 11:14:07)


**我们在项目中一般使用DATETIME，不论数据库设置的时区是多少，我们在链接url中定义了serverTimezone=UTC是中国时区，DATETIME在存储时会存储为UTC时间。我们只需要在返回时再转回UTC即可，使用@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8")注解即可。**


**用下面这个例子通俗点说为什么我们当前时间和MySQL中存储的时间可能不同：**
如使用`url: jdbc:mysql://chenjie.asia:3306/test?useUnicode=true&characterEncoding=utf-8&useSSL=true&serverTimezone=UTC&allowMultiQueries=true`时，存储到MySQL中的日期会相对于北京时间少8小时。
如果使用`url: jdbc:mysql://chenjie.asia:3306/test?useUnicode=true&characterEncoding=utf-8&useSSL=true&serverTimezone=Asia/Shanghai&allowMultiQueries=true`时，存储到MySQL中的日期和北京时间相同（注：serverTimezone写为GMT+8等格式都是错误的，可以去/usr/share/zoneinfo目录下找时区名称，如Asia/Shanghai）。

我们创建Date对象存储到MySQL中时，date是这样的`Fri Jul 16 14:37:43 CST 2021`，可以看到其中有时区信息，而我们url中的serverTimezone是设置了MySQL本次连接中使用的时区，如果是UTC则需要减8小时，如果是Asia/Shanghai，则无需时区转换。
