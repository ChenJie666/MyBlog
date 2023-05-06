---
title: MySQL数据迁移
categories:
- MySQL
---
#一、导出数据库为sql文件，然后通过sql文件将数据导入到新的MySQL中
###导出
mysqldump -uroot -phxr --all-databases > mysql.sql
mysqldump -uroot -phxr dev_smartcook > dev_smartcook.sql

###导入
mysql -uroot -phxr dev_smartcook < dev_smartcook.sql
