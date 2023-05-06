---
title: MySQL基础命令
categories:
- MySQL
---
# mysql：

## 新建用户
方式一：直接将用户信息插入mysql.user表
mysql> insert into mysql.user(Host,User,Password) values("%","root",password("abc123"));

方式二：创建默认权限的用户
CREATE USER 'rangerdba'@'localhost' IDENTIFIED BY 'rangerdba';

方式三：创建用户并赋予用户root所有数据库的所有表的权限
mysql> grant all privileges on *.* to 'root'@'%' identified by 'abc123';

注意：需要执行flush privileges使得修改生效。

**查看用户权限**
1. 执行`select * from mysql.user where user='ranger'\G;` 获取用户的信息
2. 执行`show grants for ranger` 获取执行的授权语句


创建数据库时指定字符集和排序规则
`create database hive DEFAULT CHARSET utf8 COLLATE utf8_general_ci;`

>其中 utf8_general_ci 是针对utf8mb4编码的其中一种collatio，定义了哪个字符和哪个字符是“等价”的，在排序中确定顺序。如 utf8mb4_0900_ai_ci ，中间的0900对应的是Unicode 9.0的规范(相比6.0版新加入了222个中日韩统一表义字符、7.0版加入了俄国货币卢布的符号)、ai表示accent insensitivity、ci表示case insensitivity；
MySQL 8.0之后，默认collation不再像之前版本一样是是utf8mb4_general_ci，而是统一更新成了utf8mb4_0900_ai_ci。如果联表查询排序的多表的COLLATE不同，会导致异常发生。

远程链接数据库（指定地址和端口）
`mysql -P3308 -h 192.168.32.244 -uroot -proot`

## sql
执行顺序
![image.png](MySQL基础命令.assets715abf0ebed4447905497742d243e46.png)

![image.png](MySQL基础命令.assets