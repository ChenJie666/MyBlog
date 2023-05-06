---
title: MySQL锁机制和MVCC版本控制
categories:
- MySQL
---
#一、MySQL锁机制
## 1.1 锁分类
按**锁的粒度** 划分：
- **表锁：**表锁是粒度最大的锁，开销小，加锁快，不会出现死锁，但是由于粒度太大，因此造成锁的冲突几率大，并发性能低。
- **页锁：**页锁的粒度是介于行锁和表锁之间的一种锁，页锁是在BDB中支持的一种锁机制，很少提及和使用。
- **行锁：**行锁是粒度最小的锁机制，行锁的加锁开销性能大，加锁慢，并且会出现死锁，但是行锁的锁冲突的几率低，并发性能高。
- **间隙锁：**间隙锁主要用于范围查询的时候，锁住查询的范围，并且间隙锁也是解决幻读的方案。

按**使用的方式** 划分：
- **共享锁(S)：**当一个事务对Mysql中的一条数据行加上了S锁，当前事务不能修改该行数据只能执行读操作，其他事务只能对该行数据加S锁不能加X锁。
- **排它锁(X)：**若是一个事务对一行数据加了X锁，该事务能够对该行数据执行读和写操作，其它事务不能对该行数据加任何的锁，既不能读也不能写。

按**思想** 划分：
- **乐观锁：**乐观锁（ Optimistic Locking ） 相对悲观锁而言，乐观锁假设认为数据一般情况下不会造成冲突，所以在数据进行提交更新的时候，才会正式对数据的冲突与否进行检测。乐观锁需要程序员自己去实现的锁机制」，最常见的乐观锁实现就锁机制是「使用版本号实现」；
- **悲观锁：**一个事务执行的操作读某行数据应用了锁，那只有当这个事务把锁释放，其他事务才能够执行与该锁冲突的操作。悲观锁的实现是基于Mysql自身的锁机制实现。



## 1.2 MySQL引擎的锁机制
MySQL引擎介绍以下两种，MyISAM和InnoDB。
### 1.2.1 MyISAM引擎
#### 1.2.1.1 概念
MySQL的**MyISAM储存引擎**就支持表锁，MyISAM的表锁模式有两种：
- 表共享读锁(S)：当一个事务对一张MyISAM表加上了共享读锁(S锁)，当前事务不能修改该表的数据，只能执行读操作，其他事务只能对该表加S锁不能加X锁。
- 表独占写锁：当一个事务对一张MyISAM表加上了排他写锁(X锁)，只能自己进行读写，其他事务不能对该表添加任何锁，既不能读也不能写。

**行锁是InnoDB默认的支持的锁机制，MyISAM不支持行锁，这个也是InnoDB和MyISAM的区别之一。**

####1.2.1.2 测试表级锁
Mysql中可以通过以下sql来显示的在事务中显式的进行加锁和解锁操作：
```sql
-- 显式的添加表级读锁
LOCK TABLE 表名 READ
-- 显示的添加表级写锁
LOCK TABLE 表名 WRITE
-- 显式的解锁（当一个事务commit的时候也会自动解锁）
unlock tables;
```
#### 建表
创建一个测试表student，这里要指定存储引擎为MyISAM，并插入两条测试数据：
```sql
CREATE TABLE IF NOT EXISTS student( \
    id INT PRIMARY KEY auto_increment, \
    name VARCHAR(40), \
    score INT \
)ENGINE MyISAM;

INSERT INTO student(name, score) VALUES('zs', 60);
INSERT INTO student(name, score) VALUES('ls', 80);
```
查看一下，表结果如下图所示：
```
mysql> select * from student;
+----+------+-------+
| id | name | score |
+----+------+-------+
|  1 | zs   |    60 |
|  2 | ls   |    80 |
+----+------+-------+
```
#### MyISAM表级写锁
**1. 第一个窗口执行下面的sql，在session1中给表添加写锁：**
```sql
LOCK TABLE student WRITE;
```
**2.  与此同时再开启一个session2窗口，然后在可以在session2中进行查询或者插入、更新该表数据，可以发现都会处于等待状态，也就是session1锁住了整个表，导致session2只能等待：**
```
mysql> select * from student;
   
```
**3. 在session1中进行查询、插入、更新数据，都可以执行成功：**
```
mysql> select * from student;
+----+------+-------+
| id | name | score |
+----+------+-------+
|  1 | zs   |    60 |
|  2 | ls   |    80 |
+----+------+-------+
2 rows in set (0.00 sec)

mysql> update student set score=100 where id = 1;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0
```
**4. 解锁student表**
```
mysql> unlock tables;
Query OK, 0 rows affected (0.00 sec)
```
session2中的查询语句返回结果
```
mysql> select * from student;
+----+------+-------+
| id | name | score |
+----+------+-------+
|  1 | zs   |   100 |
|  2 | ls   |    80 |
+----+------+-------+
2 rows in set (3 min 27.09 sec)
```

**总结：**从上面的测试结果显示，当一个线程获取到表级写锁后，只能由该线程对表进行读写操作，别的线程必须等待该线程释放锁以后才能操作。

#### MyISAM表级读锁
**1. 第一步还是在session1给表加读锁。**
```
mysql> LOCK TABLE student READ;
Query OK, 0 rows affected (0.00 sec)
```
**2. 然后在session1中尝试进行插入、更新数据，发现都会报错，只能查询数据。**
```
mysql> insert into student value(4,"ww",99);
ERROR 1099 (HY000): Table 'student' was locked with a READ lock and can't be updated
```
**3. 最后在session2中尝试进行插入、更新数据，程序都会进入等待状态，只能查询数据，直到session1解锁表session2才能插入、更新数据。**
```
mysql> select * from student;
+----+------+-------+
| id | name | score |
+----+------+-------+
|  1 | zs   |   100 |
|  2 | ls   |    80 |
+----+------+-------+
2 rows in set (0.00 sec)

mysql> insert into student value(4,"ww",99);

```

**总结：**从上面的测试结果显示，当一个线程获取到表级读锁后，该线程只能读取数据不能修改数据，其它线程也只能加读锁，不能加写锁。

#### 1.2.1.3 MyISAM表级锁竞争情况
MyISAM存储引擎中，可以通过查询变量来查看并发场景锁的争夺情况`show status like 'table%'`：
```sql
mysql> show status like 'table%';
+----------------------------+-------+
| Variable_name              | Value |
+----------------------------+-------+
| Table_locks_immediate      | 81    |
| Table_locks_waited         | 1     |
| Table_open_cache_hits      | 9     |
| Table_open_cache_misses    | 1     |
| Table_open_cache_overflows | 0     |
+----------------------------+-------+
5 rows in set (0.00 sec)
```

主要是查看table_locks_waited和table_locks_immediate的值的大小分析锁的竞争情况。
- **Table_locks_immediate：**表示能够立即获得表级锁的锁请求次数；
- **Table_locks_waited：**表示不能立即获取表级锁而需要等待的锁请求次数分析，**值越大竞争就越严重**。

#### 1.2.1.4 并发插入
在我们平时执行select语句的时候就会隐式的加读锁，执行增、删、改的操作时就会隐式的执行加写锁。

MyISAM存储引擎中，虽然读写操作是串行化的，但是它也支持并发插入，这个需要设置内部变量concurrent_insert的值。

它的值有三个值0、1、2。可以通过以下的sql查看concurrent_insert的默认值为「AUTO(或者1)」。
```
mysql> show variables like '%concurrent_insert';
+-------------------+-------+
| Variable_name     | Value |
+-------------------+-------+
| concurrent_insert | AUTO  |
+-------------------+-------+
1 row in set (0.00 sec)
```
- NEVER (0)表示不支持并发插入；
- AUTO(1）表示在MyISAM表中没有被删除的行，运行另一个线程从表尾插入数据；
- ALWAYS (2)表示不管是否有删除的行，都允许在表尾插入数据。

### 1.2.1.5 锁调度
MyISAM存储引擎中，假如同时一个读请求，一个写请求过来的话，它会优先处理写请求，因为MyISAM存储引擎中认为写请求比读请求重要。

这样就会导致，假如大量的读写请求过来，就会导致读请求长时间的等待，或者"线程饿死"，因此MyISAM不适合运用于大量读写操作的场景，这样会导致长时间读取不到用户数据，用户体验感极差。

当然可以通过设置low-priority-updates参数，设置请求链接的优先级，使得Mysql优先处理读请求。

<br>
### 1.2.2 InnoDB引擎
#### 1.2.2.1 概念
InnoDB和MyISAM不同的是，InnoDB支持**表锁**、**间隙锁**、**Next-key Lock锁**和**行锁**，默认支持的是行锁。

**需要注意的是：**InnoDB中的行级锁是对**索引**加的锁，在不通过索引查询数据的时候，InnoDB就会使用表锁。若是Mysql觉得执行索引查询还不如全表扫描速度快，那么Mysql就会使用全表扫描来查询，这是即使sql语句中使用了索引，最后还是执行为全表扫描，加的是表锁。

#### 1.2.2.2 测试行级锁
若想显式的给表加行级读锁和写锁，可以执行下面的sql语句：
```sql
-- 给查询sql显示添加读锁
select ... lock in share mode;
-- 给查询sql显示添加写锁
select ... for update；
```
#### 建表
创建一个测试表，并插入两条数据：
```sql
-- 先把原来的MyISAM表给删除了
DROP TABLE IF EXISTS student;
CREATE TABLE IF NOT EXISTS student( \
    id INT PRIMARY KEY auto_increment, \
    name VARCHAR(40), \
    score INT \
)ENGINE INNODB;
-- 插入测试数据
INSERT INTO student(name, score) VALUES('zs', 60);
INSERT INTO student(name, score) VALUES('ls', 80);
```
#### InnoDB表级写锁（对非索引列加行级写锁）
1. 创建的表中可以看出对表中的字段只有id添加了主键索引，接着就是在session1窗口执行begin开启事务，并执行下面的sql语句：
```sql
begin;
-- 使用非索引字段查询，并显式的添加写锁
select * from student where name='zs' for update;
+----+------+-------+
| id | name | score |
+----+------+-------+
|  1 | zs   |    60 |
+----+------+-------+
1 row in set (0.00 sec)
```
2. 然后在session2中执行update语句和insert语句，上面更新上锁的是id=1的数据行，现在update的是id=1的数据，insert的是新的一行数据，会发现程序也都会进入等待状态并超时：
```sql
mysql> update student set score = 100 where id = 1;
ERROR 1205 (HY000): Lock wait timeout exceeded; try restarting transaction
mysql> insert into student value(3,"ww",99);

```
**总结：**可见若是使用**非索引查询**，直接就是使用的**表级锁**，锁住了整个表。
#### InnoDB行级写锁（对索引列加行级写锁）
1. 若是session1使用的是id来查询
```
begin;
mysql> select * from student where id = 1 for update;
+----+------+-------+
| id | name | score |
+----+------+-------+
|  1 | zs   |    60 |
+----+------+-------+
1 row in set (0.00 sec)
```
2. 然后在session2中执行update语句和insert语句，上面更新上锁的是id=1的数据行，现在update的是id=1的数据，insert的是新的一行数据，会发现update等待并超时，insert成功：
```
mysql> insert into student value(3,"ww",99);
Query OK, 1 row affected (0.00 sec)
mysql> update student set score = 100 where id = 1;

```
**总结：**若是使用**索引查询**，就是使用的**行级锁**，锁住了指定的行。但是是否执行索引还得看Mysql的执行计划，对于一些小表的操作，可能就直接使用全表扫描。


1.执行非索引条件查询执行的是表锁。
2.执行索引查询是否是加行锁，还得看Mysql的执行计划，可以通过explain关键字来查看。
3.用普通键索引的查询，遇到索引值相同的，也会对其他的操作数据行的产生影响。

#### InnoDB普通索引锁住相同行
1. 添加普通索引
```
mysql> alter table student add index idx_name(name);
Query OK, 0 rows affected (6.94 sec)
```
2. 修改name为相同值
```
mysql> update student set name = "zs" where id = 2;
Query OK, 1 row affected (0.01 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> select * from student;
+----+------+-------+
| id | name | score |
+----+------+-------+
|  1 | zs   |    60 |
|  2 | zs   |    80 |
|  3 | ww   |    99 |
+----+------+-------+
3 rows in set (0.00 sec)
```
3. 然后在session1中锁住name="zs"的行
```
begin;
select * from student where name = "zs" for update;
```
4. 在session2中修改id=1的记录
```
mysql> update student set score = 0 where id = 1;

```
**总结：**用普通键索引的查询，遇到索引值相同的，也会对其他的操作数据行的产生影响。

#### 结论：
- 1.执行非索引条件查询执行的是表锁。
- 2.执行索引查询是否是加行锁，还得看Mysql的执行计划，可以通过explain关键字来查看。
- 3.用普通键索引的查询，遇到索引值相同的，也会对其他的操作数据行的产生影响。

#### 1.2.2.3 InnoDB间隙锁和Next-Key锁
当我们使用范围条件查询而不是等值条件查询的时候，InnoDB就会给符合条件的范围索引加锁，在条件范围内并不存的记录就叫做"间隙（GAP）"

InnoDB中引入了间隙锁，解决了事务等级-不可重复读下会产生的幻读问题，只能通过提高隔离级别到串行化来解决幻读现象。

**这里抛出几种情况来测试间隙锁：**
- 非唯一索引是否会加上间隙锁呢？
- 主键索引（唯一索引）是否会加上间隙锁呢？
- 范围查询是否会加上间隙锁？
- 使用不存在的检索条件是否会加上间隙锁？


**例如我们执行下面的sql语句，就会对id大于100的记录加锁，在id>100的记录中肯定是有不存在的间隙：**
```sql
Select * from student where id> 100 for update;
```

Next-Key锁是行锁加上记录前的间隙锁的结合。如果一个会话在索引中的记录R上有一个共享或独占的锁，则另一个会话不能按照索引顺序在R之前的间隙中插入新的索引记录。

#### 建表
```sql
mysql> alter table student add num int not null default 0;
mysql> update student set num = 1 where id = 1;
mysql> update student set num = 1 where id = 2;
mysql> update student set num = 3 where id = 3;
mysql> insert into student values(4,'tq',100,5);

mysql> select * from student;
+----+------+-------+-----+
| id | name | score | num |
+----+------+-------+-----+
|  1 | zs   |    60 |   1 |
|  2 | zs   |    80 |   1 |
|  3 | ww   |    99 |   3 |
|  4 | tq   |   100 |   5 |
+----+------+-------+-----+
4 rows in set (0.00 sec)
```
#### 为非唯一索引单行加锁
1.接着在session1的窗口开启事务，并执行下面操作：
```
mysql> begin;
Query OK, 0 rows affected (0.00 sec)

mysql> select * from student where num=3 for update;
+----+------+-------+-----+
| id | name | score | num |
+----+------+-------+-----+
|  3 | ww   |    99 |   3 |
+----+------+-------+-----+
1 row in set (0.00 sec)
```
2. 同时打开窗口session2，并执行新增语句：
```sql
insert into student values(5,'ceshi',5000,2);  -- 程序出现等待
insert into student values(5,'ceshi',5000,4);  -- 程序出现等待
insert into student values(5,'ceshi',5000,1);  -- 程序出现等待
insert into student values(5,'ceshi',5000,5);  -- 程序出现等待
insert into student values(5,'ceshi',5000,6);  -- 新增成功
insert into student values(6,'ceshi',5000,0);  -- 新增成功
```
**总结：**从上面的测试结果显示在区间 [1,3] U [3,5] 之间加了锁，是不能够新增数据行，这就是新增num=1/2/4/5失败的原因，但是在这个区间以外的数据行是没有加锁的，可以新增数据行。

根据索引的有序性，而普通索引是可以出现重复值，那么当我们第一个sesson查询的时候只出现一条数据num=3，为了解决第二次查询的时候出现幻读，也就是出现两条或者更多num=3这样查询条件的数据。

#### 为唯一索引单行加锁
因为主键索引具有唯一性，不允许出现重复，那么当进行等值查询的时候id=3，只能有且只有一条数据，是不可能再出现id=3的第二条数据。

因此它只要锁定这条数据（锁定索引），在下次查询当前读的时候不会被删除、或者更新id=3的数据行，也就保证了数据的一致性，所以主键索引由于他的唯一性的原因，是不需要加间隙锁的。

#### 为非唯一索引范围加锁
```
mysql> select * from student;
+----+------+-------+-----+
| id | name | score | num |
+----+------+-------+-----+
|  1 | zs   |    60 |   1 |
|  2 | zs   |    80 |   1 |
|  3 | ww   |    99 |   3 |
|  4 | tq   |   100 |   5 |
+----+------+-------+-----+
4 rows in set (0.01 sec)
```
在session1中执行下面的sql语句:
```sql
begin;
select * from student where num>=3 for update;
```
在session2中新增数据：
```
insert into student values(6,'ceshi',5000,2);  -- 程序出现等待
insert into student values(7,'ceshi',5000,4);  -- 程序出现等待
insert into student values(8,'ceshi',5000,1);  -- 新增数据成功
```
**原理：**单查询num>=3的时候，在现有的student表中满足条件的数据行,那么在设计者的角度出发，我为了解决幻读的现象：在num>=3的条件下是必须加上间隙锁的。
而在小于num=3中，下一条数据行就是num=1了，为了防止在（1，3]的范围中加入了num=3的数据行，所以也给这个间隙加上了锁，这就是添加num=2数据行出现等待的原因。

#### 使用不存在的检索条件是否会加上间隙锁？
假如是查询num>=8的数据行呢？因为student表并不存在中num=8的数据行，num最大num=6，所以为了解决幻读（6，8]与num>=8也会加上锁。

<br>
#### 1.2.2.4 表锁
意向锁：当一个事务带着表锁去访问一个被加了行锁的资源，那么这个行锁就会升级为意向锁将表锁住。
自增锁：事务插入自增类型的列时，获取自增锁。如果一个事务正在往表中插入自增记录，其他事务都必须等待。

<br>
#### 1.2.2.5 死锁
死锁在InnoDB中才会出现死锁，MyISAM是不会出现死锁，因为MyISAM支持的是表锁，一次性获取了所有的锁，其它的线程只能排队等候。

而InnoDB默认支持行锁，获取锁是分步的，并不是一次性获取所有的锁，因此在锁竞争的时候就会出现死锁的情况。

虽然InnoDB会出现死锁，但是并不影响InnoDB成为最受欢迎的存储引擎，MyISAM可以理解为串行化操作，读写有序，因此支持的并发性能低下。

####死锁案例
举一个例子，现在数据库表employee中六条数据，如下所示：
```
+----+------+-------+-----+
| id | name | score | num |
+----+------+-------+-----+
|  1 | zs   |    60 |   1 |
|  2 | zs   |    80 |   1 |
|  3 | ww   |    99 |   3 |
|  4 | tq   |   100 |   5 |
+----+------+-------+-----+
```

其中name=ldc的有两条数据，并且name字段为普通索引，分别是id=2和id=3的数据行，现在假设有两个事务分别执行下面的两条sql语句：
```sql
-- session1执行
update student set num = 1 where name ='zs';
-- session2执行
select * from student where id = 1 or id = 2;
```
其中session1事务执行的sql获取的数据行是两条数据，假设先为id=1的数据行加排它读锁；然后cpu的时间分配给了session2事务，执行查询为id=2的数据行加排它读锁。
此时cpu又将时间分配给了session1事务，为id=2数据添加排他读锁时发现已经被添加了排它读锁，它就处于等待的状态。
当cpu把时间有分配给了session2事务，为id=1数据添加排他读锁时发现已经被添加了排它读锁，这样就行了死锁，两个事务彼此之间相互等待。

#### 死锁的解决方案
首先要解决死锁问题，在程序的设计上，当发现程序有高并发的访问某一个表时，尽量对该表的执行操作串行化，或者锁升级，一次性获取所有的锁资源。

然后也可以设置参数innodb_lock_wait_timeout，超时时间，并且将参数innodb_deadlock_detect 打开，当发现死锁的时候，自动回滚其中的某一个事务。

<br>
## 1.3 事务类型
在默认 的自动事务提交 设置下 select 同Update,Insert,Delete一样都会启动一个事务，这种就是隐式事务。

**问题：如更新库存语句如下**
```
update stock set leave_stock=leave_stock-sale_stock  where id = 1 and leave_stock >= sale_stock;
```
那么是否存在一下问题：
如果隔离级别是可重复读，执行update库存操作时开启隐式事务，AB事务同时开启，A事务修改库存从6改到5,，但是B事务不可见还是在6基础上减库存，导致少卖的情况发送。

### 1.3.1 显示事务
显示事务是一种由你自己指定的事务.这种事务允许你自己决定哪批工作必须成功完成, 
否则所有部分都不完成.为了给自己的事务定界,可以使用关键字BEGIN TRANSACTION和 
ROLLBACK TRANSACTION或COMMIT TRANSACTION. 
BEGIN TRANSACTION—这个关键词用来通知SQL Server一个事务就要开始了. 
BEGIN TRANSACTION后面发生的每一条S Q L语句都是同一个事务中的一部分. 
ROLLBACK TRANSACTION—这个关键词用来通知SQL Server自BEGIN TRANSACTION 
后的所有工作都应取消,对数据库中任何数据的改变都被还原,任何已经创建或删除的对 
象被清除或恢复. 
COMMIT TRANSACTION—这个关键词用来通知SQL Server自BEGIN TRANSACTION 
后的全部工作都要完成并成为数据库的一个永久性部分.在同一个事务中,你不能同时 
使用ROLLBACK TRANSACTION和COMMIT TRANSACTION. 
你必须意识到,即使你的脚本中有错误,而你又让SQL Server提交事务,该事务也将执 
行.如果你打算依赖于现实事务保证数据完整性,必须在脚本中建立错误检查机制.

### 1.3.2 隐式事务
隐式事务是SQL Server为你而做的事务.隐式事务又称自动提交事务.如果运行一条 
I N S E RT语句,SQL Server将把它包装到事务中,如果此I N S E RT语句失败,SQL Server将回滚 
或取消这个事务.每条S Q L语句均被视为一个自身的事务.

<br> 
## 1.4 总结 
- MyISAM的表锁分为两种模式：「共享读锁」和「排它写锁」。获取的读锁的线程对该数据行只能读，不能修改，其它线程也只能对该数据行加读锁。
获取到写锁的线程对该数据行既能读也能写，对其他线程对该数据行的读写具有排它性。
MyISAM中默认写优先于去操作，因此MyISAM一般不适合运用于大量读写操作的程序中。

- InnoDB的行锁虽然会出现死锁的可能，但是InnoDB的支持的并发性能比MyISAM好，行锁的粒度最小，一定的方法和措施可以解决死锁的发生，极大的发挥InnoDB的性能。
InnoDB中引入了间隙锁的概念来决解出现幻读的问题，也引入事务的特性，通过事务的四种隔离级别，来降低锁冲突，提高并发性能。

**需要注意的是：**事务添加了排它锁，不代表其他事务不能无锁读取该数据（无锁可以读取添加排它锁的数据）。
```
- 无锁
>select ... from ...;

- 共享锁
>select ... from ... lock in share mode;

- 排它锁
>update ...
>delete ...
>insert ...
>select ... from ... for update
```

**查看锁信息：**
show status like 'innodb_row_lock%';

| 名称                            | 解释                                          |
| ----------------------------- | ---------------------------------------- |
| Innodb_row_lock_current_waits | 当前正在等待锁定的数量                   |
| Innodb_row_lock_time          | 从系统启动到现在锁定总时间长度           |
| Innodb_row_lock_time_avg      | 每次等待所花平均时间                     |
| Innodb_row_lock_time_max      | 从系统启动到现在等待最长的一次所花的时间 |
| Innodb_row_lock_waits         | 系统启动后到现在总共等待的次数           |

 <br>
#二、MVCC快照
## 2.1 概念
MVCC，全称Multi-Version Concurrency Control，即多版本并发控制。MVCC是一种并发控制的方法。
MVCC在MySQL InnoDB中的实现主要是为了提高数据库并发性能，用更好的方式去处理读-写冲突，做到即使有读写冲突时，也能做到不加锁，非阻塞并发读。

## 2.2 流程
1. 当修改或删除记录时，会插入一条新记录并指向前一个版本的记录，并标记该记录的操作类型和事务id。
2. 当开启事务并查询表时，会为该事务保存一个快照read-view，保存了当前还未提交的事务id的列表和最大的事务id。
3. 如果是可重复度，那么该事务再次读取数据时会根据保存的read-view，去undo日志查找对其可见的版本列并返回。
4. 如果查找到的最新记录的事务id在read-view的事务id列表中，那么根据指针查找上一版本的记录，直到找到对其可见的记录。

![read-view流程图](MySQL锁机制和MVCC版本控制.assets\3c9a91a6f8404da59018fd7158b4c269.png)

例：同时开启两个事务，同时不加锁查询同一条记录，在一个事务中修改记录并提交，记录修改成功，但是在另一个事务中读取该记录发现还是修改前的值，直到提交事务后查询该记录，才能读到修改后的记录；因为该事务中读取记录后会保存快照，事务中再次读取都会读取该快照，直到提交事务。

![image.png](MySQL锁机制和MVCC版本控制.assetse4996f96e743d9a735c971b440180d.png)

<br>
# 三、隔离级别
## 3.1 读问题
- 隔离级别：Read Uncommitted（读取未提交内容），所有事务可以看到其他未提交的事务的执行结果。
- 脏读：事务一读取到的是事务二已修改但未提交的数据，在事务二回滚后事务一读取到的数据成为无效数据；
- 隔离级别：Read Committed（读取已提交内容），所有事物只能看见其他已提交事务的执行结果。
- 不可重复读：事务一读取了一个数据，事务2在事务一期间修改了该数据并提交，事务一再次读取这个数据时发现两次数据不一样；
- 隔离级别：Repeatable Read（可重复读），MySQL默认的隔离级别。一个事务中，所有被读过的行都会加上行锁，直到该事务提交或回滚才释放锁。保证事务中多次读同一行的值相同。（添加行锁、间隙锁或表锁）
- 幻读：事务一读取某个范围数据时，事务二在该范围内插入了新数据，事务一再次读取该范围记录时，发现记录数改变，产生幻读。
- 隔离级别：Serializable（可串行化），每个读的数据行上加共享锁，可能造成大量的超时现象和锁竞争。（添加表锁）

### 3.1.1 隔离级别的实现
通过锁实现了读未提交和串行化；通过锁配合MVCC实现了读已提交和可重复读。
#### 3.1.1.1 锁机制
读未提交：读数据时不加锁；
读已提交：读数据加共享锁，但是读完就释放锁而不是等到事务结束；
可重复读：读数据时添加共享行锁，事务结束释放锁；
可串行化：读数据时添加共享表锁，事务结束释放锁。

#### 3.1.1.2 MVCC机制（MySQL主要使用快照保证隔离级别）
MVCC机制生成一个数据快照，并用这个快照来提供一定级别的一致性的读取，也成为了多版本数据控制。MVCC实现的是普通读取不加锁，并且读写分离，保证了读写并发。
- 实际就是CAS版本控制和读写分离
- 主要作用读已提交和可重复读

## 3.2 写问题
脏写(丢失更新)：事务一和事务二读取到数据后进行修改，最后提交的事务覆盖了之前提交的事务，造成丢失更新。

**写问题解决方案**
- 悲观锁：串行操作。读取数据时添加排他写锁(for update)，其他事务读取时阻塞，等到该事务提交时才允许其他事务进行读写。如果不加for upfate会因为没有加锁和MVCC快照，可以同时读取数据导致数据覆盖丢失更新。
- 乐观锁：通过版本号进行控制，进入事务后首先获取版本号，提交事务前再次读取版本号进行比较，如果版本号一致，则进行提交，且将版本号加一；如果版本号不一致，则放弃操作。
update user set name = 'www' where id = 1 and version = 1;
