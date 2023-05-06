---
title: 分库分表ShardingSphere
categories:
- MySQL
---
Sharding-JDBC会根据配置规则将数据路由到指定的数据源上，包括广播，水平/垂直分库分表，读写分离。

![image.png](分库分表ShardingSphere.assets\9519fe990177470b9d1bed94038b2fe8.png)


# 一、ShardingSphere实现分库分表
Apache ShardingSphere 是分布式数据库中间件解决方案，旨在充分合理地在分布式的场景下利用关系型数据库的计算和存储能力。

[官方文档链接](http://shardingsphere.apache.org/document/current/cn/quick-start/)

## 1.1 分库分表
### 1.1.1 概念
分库分表有两种方式：垂直切分和水平切分
- 垂直切分：分为垂直分表和垂直分库
1）垂直分表：把表垂直切分为两张表，每张表保存一部分字段。
2）垂直分库：把单一数据库按照业务进行划分，做到专库专表。
- 水平切分：分为水平分表和水平分库
1）水平分表：把表垂水平分为两张表，每张表保存一部分记录。
2）水平分库：把单一数据库分成两个数据库，每个数据库中表结构相同，按照规则分库存储。

### 1.1.2 分库分表应用和问题
#### 1.1.2.1 应用
1. 数据库设计阶段就应该考虑垂直分库和垂直分表；
2. 随着数据量增加，首先考虑缓存处理、读写分离、使用索引等优化，最后考虑分库分表。

#### 1.1.2.2 问题
1. 有跨节点连接查询问题，查询多个服务器中的多个数据库中多个表，有效率问题（分页和排序效率很低）
2. 多数据源管理问题


## 1.2 Sharding-JDBC
### 1.2.1 概念
在java的JDBC层提供服务，使用客户端直连数据库，以jar包形式提供服务。可以理解为增强版的JDBC驱动，简化对分库分表后的数据相关操作。
- 数据分片：
- 读写分离：

![image](分库分表ShardingSphere.assets\49e3982205464bce895d1c4782da889a.png)

###1.2.2 数据分片
### 1.2.2.1 实现
**依赖**
```xml
<dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
        </dependency>
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
        </dependency>

        <dependency>
            <groupId>com.baomidou</groupId>
            <artifactId>mybatis-plus-boot-starter</artifactId>
            <version>${mybatis-plus.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.shardingsphere</groupId>
            <artifactId>sharding-jdbc-spring-boot-starter</artifactId>
            <version>${shardingsphere.version}</version>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
        </dependency>
    </dependencies>
```
配置流程：
1. 添加数据源
2. 添加数据库表
3. 添加主键生成策略
4. 指定分表策略(即数据进入那个表中)
5. 可以开启sql输出日志

##### 1.2.2.1.1 水平分库分表
**水平分表配置**
```yaml
spring:
  main:
    allow-bean-definition-overriding: true
  shardingsphere:
    datasource:
      # 配置数据源名称
      names: ds0
      # 配置第一个数据源
      ds0:
        type: com.zaxxer.hikari.HikariDataSource
        driver-class-name: com.mysql.cj.jdbc.Driver
        jdbc-url: jdbc:mysql://192.168.32.244:3306/sphere_test?characterEncoding=utf8&useUnicode=true&useSSL=false&serverTimezone=UTC&allowMultiQueries=true
        username: root
        password: hxr
      # 配置第二个数据源

    # 配置 表 规则
    sharding:
      tables:
        # 实体类的名称
        course:
          # 数据库ds0的表ds0.course_1和表ds0.course_2
          actual-data-nodes: ds0.course_$->{1..2}
          # 指定主键名称和主键生成策略（雪花算法）
          key-generator:
            column: cid
            type: SNOWFLAKE
          # 指定分片策略  约定cid值偶数添加到course_1表，奇数添加到course_2表
          table-strategy:
            inline:
              sharding-column: cid
              algorithm-expression: course_$->{cid%2+1}
    # 打开sql输出日志
    props:
      sql:
        show: true
```
**水平分表分库配置**
```yaml
spring:
  main:
    allow-bean-definition-overriding: true
  shardingsphere:
    datasource:
      # 配置数据源名称
      names: ds0,ds1
      # 配置第一个数据源
      ds0:
        type: com.zaxxer.hikari.HikariDataSource
        driver-class-name: com.mysql.cj.jdbc.Driver
        jdbc-url: jdbc:mysql://192.168.32.244:3306/sphere_test?characterEncoding=utf8&useUnicode=true&useSSL=false&serverTimezone=UTC&allowMultiQueries=true
        username: root
        password: hxr
      # 配置第二个数据源
      ds1:
        type: com.zaxxer.hikari.HikariDataSource
        driver-class-name: com.mysql.cj.jdbc.Driver
        jdbc-url: jdbc:mysql://192.168.32.225:3306/sphere_test2?characterEncoding=utf8&useUnicode=true&useSSL=false&serverTimezone=UTC&allowMultiQueries=true
        username: root
        password: hxr
    #配置 表 规则
    sharding:
      tables:
        # 实体类的名称
        course:
          # 数据库ds0和ds1的表course_1和表course_2
          actual-data-nodes: ds$->{0..1}.course_$->{1..2}
          # 指定主键名称和主键生成策略（雪花算法）
          key-generator:
            column: cid
            type: SNOWFLAKE
          # 指定表的分片策略  约定cid值偶数添加到course_1表，奇数添加到course_2表
          table-strategy:
            inline:
              sharding-column: cid
              algorithm-expression: course_$->{cid % 2 + 1}
          # 指定数据库的分片策略
          database-strategy:
            inline:
              sharding-column: user_id
              algorithm-expression: ds$->{user_id % 2}
    # 打开sql输出日志
    props:
      sql:
        show: true
```
**代码**
```java
    @Resource
    private CourseMapper courseMapper;

    // 会根据分片策略在对应表中进行插入
    @Test
    public void addCourse(){
        for (int i = 0; i < 10; i++) {
            Course course = new Course(null, "zhangsan", (long) i, "Normal");
            courseMapper.insert(course);
        }
    }

    // 会根据分片策略去对应表中进行查询
    @Test
    public void findCourse(){
        QueryWrapper<Course> wrapper = new QueryWrapper<Course>();
        wrapper.eq("cid", 578276905568960513L);
        Course course = courseMapper.selectOne(wrapper);
        System.out.println(course);
    }
```

##### 1.2.2.1.2 垂直分库分表
代码略


##### 1.2.2.1.3 广播表（字典表）
代码略

### 1.2.3 读写分离
Sharding-Sphere通过sql语句语义分析，实现读写分离过程。
将增删改路由到主服务器，将查路由到从服务器。

代码略

## 1.2 Sharding-Proxy
透明化的数据库代理端，提供封装了数据库二进制协议的服务端版本，相当于一个代理数据库管理了多个业务数据库。

![image](分库分表ShardingSphere.assets\13ed80abec2e4c6ca141535916e499dd.png)

Sharding-Proxy独立应用，使用安装服务，进行分库分表或者读写分离配置，启动。

### 1.2.1 部署
1. 在[官网](https://shardingsphere.apache.org/document/current/cn/downloads/)下载Sharding-Proxy 5.0.0-alpha，解压到linux目录下。
2. 将mysql的驱动包mysql-connector-java-5.1.27-bin.jar放到lib目录下。

### 1.2.2 配置分库分表
1. 配置server.yaml文件
```yml
authentication:
  users:
    root:
      password: root
    sharding:
      password: sharding 
      authorizedSchemas: sharding_db

props:
  max-connections-size-per-query: 1
  acceptor-size: 16  # The default value is available processors count * 2.
  executor-size: 16  # Infinite by default.
  proxy-frontend-flush-threshold: 128  # The default value is 128.
    # LOCAL: Proxy will run with LOCAL transaction.
    # XA: Proxy will run with XA transaction.
    # BASE: Proxy will run with B.A.S.E transaction.
  proxy-transaction-type: LOCAL
  proxy-opentracing-enabled: false
  proxy-hint-enabled: false
  query-with-cipher-column: true
  sql-show: false
  check-table-metadata-enabled: false
```
2. 配置config-sharding.yaml文件
```yaml
schemaName: sharding_db

dataSourceCommon:
  username: root
  password:
  connectionTimeoutMilliseconds: 30000
  idleTimeoutMilliseconds: 60000
  maxLifetimeMilliseconds: 1800000
  maxPoolSize: 50
  minPoolSize: 1
  maintenanceIntervalMilliseconds: 30000

dataSources:
  ds_0:
#    url: jdbc:mysql://127.0.0.1:3306/demo_ds_0?serverTimezone=UTC&useSSL=false
    url: jdbc:mysql://192.168.32.244:3306/sphere_test?serverTimezone=UTC&useSSL=false
    username: root
    password: hxr
  ds_1:
    url: jdbc:mysql://192.168.32.225:3306/sphere_test2?serverTimezone=UTC&useSSL=false
    username: root
    password: hxr
    
rules:
- !SHARDING
  tables:
    course:
      actualDataNodes: ds_${0..1}.course_${1..2}
      tableStrategy:
        standard:
          shardingColumn: cid
          shardingAlgorithmName: course_inline
      keyGenerateStrategy:
        column: cid
        keyGeneratorName: snowflake
#    t_order_item:
#      actualDataNodes: ds_${0..1}.t_order_item_${0..1}
#      tableStrategy:
#        standard:
#          shardingColumn: order_id
#          shardingAlgorithmName: t_order_item_inline
#      keyGenerateStrategy:
#        column: order_item_id
#        keyGeneratorName: snowflake
  bindingTables:
    - course
  defaultDatabaseStrategy:
    standard:
      shardingColumn: user_id
      shardingAlgorithmName: database_inline
  defaultTableStrategy:
    none:
  
  shardingAlgorithms:
    database_inline:
      type: INLINE
      props:
        algorithm-expression: ds_${user_id % 2}
    course_inline:
      type: INLINE
      props:
        algorithm-expression: course_${cid % 2 + 1}
#    t_order_item_inline:
#      type: INLINE
#      props:
#        algorithm-expression: t_order_item_${order_id % 2}
  
  keyGenerators:
    snowflake:
      type: SNOWFLAKE
      props:
        worker-id: 123
```
3. 启动脚本start.sh 3307，然后进行远程连接(使用工具连不上，最好使用mysql原生客户端) 
mysql -P3308 -h 192.168.32.244 -uroot -proot
在代理数据库中创建的表都会在被管理的数据库中创建，增删改查请求都会被路由到对应的数据库中进行操作。
如：insert into sharding_db.course(user_id,msg) value(1,'zs'); 会插入到配置规则指定的数据库表中。

### 1.2.3 配置分库分表
略，参考官方文档
