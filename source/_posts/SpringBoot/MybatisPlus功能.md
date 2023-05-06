---
title: MybatisPlus功能
categories:
- SpringBoot
---
***依赖***
<dependency>
            <groupId>com.baomidou</groupId>
            <artifactId>mybatis-plus-boot-starter</artifactId>
            <version>3.2.0</version>
</dependency>

***配置控制台打印完整带参数SQL语句***
``` 
#mybatis-plus配置控制台打印完整带参数SQL语句
mybatis-plus.configuration.log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
```
注：如果同时配置了logback.xml配置文件，需要将注解删除，避免冲突。

###主键生成策略：
- 自动增长：如果数据量过大，需要进行分表，不方便；
- UUID：每次生成随机值，但是主键过长，且不能排序；
- redis(常用)：通过redis进行原子操作，如五个节点的redis集群，每次增长步长为5；
- MybatisPlus自带策略（雪花算法）：Twitter开源的分布式ID生成算法，结果是一个long型的ID。核心思想是：使用41bit作为毫秒数，10bit作为机器的ID（5个bit是数据中心，5个bit是机器的ID），12bit作为毫秒内的流水号（意味着每个节点在每毫秒可以产生4096个ID），最后还有一个符号位，永远是0；

在主键上添加@TableId(type = IdType.XXX)
- type = IdType.AUTO    自动增长(mysql中表主键也要配置自增)
- type = IdType.ID_WORKER      mp自带策略，生成19位的值(数字类型)
- type = IdType.ID_WORKER_STR     mp自带策略，生成19位的值(字符串类型)
- type = IdType.INPUT    需要我们自己设置id值，不自动生成
- type = IdType.NONE    需要我们自己设置id值，不自动生成
- type = IdType.UUID    自动生成UUID值作为主键


###自动填充功能
***配置类***
```java
@Component
public class MyMetaObjectHandler implements MetaObjectHandler {

    //使用mp实现添加操作时执行以下方法
    @Override
    public void insertFill(MetaObject metaObject) {
        this.setFieldValByName("createTime", new Date(), metaObject); //createTime对应属性名
        this.setFieldValByName("updateTime", new Date(), metaObject);
    }

    //使用mp实现更新操作时执行以下方法
    @Override
    public void updateFill(MetaObject metaObject) {
        this.setFieldValByName("updateTime", new Date(), metaObject);
    }
}
```

***注解***
- @TableField(value = "update_time",fill = FieldFill.INSERT_UPDATE)
    private Date updateTime;
需要在@TableField注解中设置自动填充生效的数据库操作。填充策略包括DEFAULT、INSERT、UPDATE、INSERT_UPDATE四种。
- 如果需要使用雪花算法生成主键，在主键上添加注解
主键添加注解@TableId(type = IdType.ID_WORKER_STR)指定生成主键策略，主键类型为String
- 实体类version字段上添加注解@Version用于乐观锁


###乐观锁功能
***读问题***
- 隔离级别：Read Uncommitted（读取未提交内容），所有事务可以看到其他未提交的事务的执行结果。
- 脏读：事务一读取到的是事务二已修改但未提交的数据，在事务二回滚后事务一读取到的数据成为无效数据；
- 隔离级别：Read Committed（读取未提交内容），所有事物只能看见其他已提交事务的执行结果。
- 不可重复读：事务一读取了一个数据，事务2在事务一期间修改了该数据并提交，事务一再次读取这个数据时发现两次数据不一样；
- 隔离级别：Repeatable Read（可重复读），MySQL默认的隔离级别。一个事务中，所有被读过的行都会加上行锁，直到该事务提交或回滚才释放锁。保证事务中多次读同一行的值相同。
- 幻读：事务一读取某个范围数据时，事务二在该范围内插入了新数据，事务一再次读取该范围记录时，发现记录数改变，产生幻读。
- 隔离级别：Serializable（可串行化），每个读的数据行上加共享锁，可能造成大量的超时现象和锁竞争。

***写问题***
- 丢失更新:事务一和事务二读取到数据后进行修改，最后提交的事务覆盖了之前提交的事务，造成丢失更新。

***写问题解决方案***
- 悲观锁：串行操作
- 乐观锁：通过版本号进行控制，进入事务后首先获取版本号，提交事务前再次读取版本号进行比较，如果版本号一致，则进行提交，且将版本号加一；如果版本号不一致，则放弃操作。

***mp解决步骤***
- 数据库和实体类中添加version字段
- 实体类version字段添加注解`@Version`,配置自动填充值为1
- 配置类
```java
@EnableTransactionManagement  //开启事务支持,需要依赖jdbc
@Configuration
@MapperScan("com.cj.springcloud.dao")
public class MybatisPlusConfig {

    /**
     * 乐观锁插件
     */
    @Bean
    public OptimisticLockerInterceptor optimisticLockerInterceptor(){
        return new OptimisticLockerInterceptor();
    }

}
```
- 请求时version不能为null，如果version与数据库中的version一致，则修改成功且version值加一；如果version与数据库中的version不一致，抛异常，修改失败。(在事务开始时获取version值v1，写入时添加version判断条件update ... where ... and version=v1，如果version不同则修改失败)
![mp实际执行的语句](MybatisPlus功能.assets\1d27ae3e13ae459596859921bb07caa8.png)

![version不一致导致修改失败](MybatisPlus功能.assets\388f287e27354334916d305a0a4e93b3.png)


###分页插件
```java
@EnableTransactionManagement  //开启事务支持,需要依赖jdbc
@Configuration
@MapperScan("com.cj.springcloud.dao")
public class MybatisPlusConfig {

    /**
     * 分页插件
     */
    @Bean
    public PaginationInterceptor paginationInterceptor(){
        return new PaginationInterceptor();
    }

}
```

***代码***
```java
    @Override
    public CommonResult findAll(Integer page, Integer pageSize) {
        QueryWrapper<BookkeepPO> wrapper = new QueryWrapper<>();
        wrapper.orderByDesc("account_date");
        IPage<BookkeepPO> iPage = bookkeepDao.selectPage(new Page(page, pageSize), wrapper);
        List<BookkeepPO> bookkeeps = iPage.getRecords();
        return new CommonResult<List<BookkeepPO>>(200, "查询成功", bookkeeps);
    }


//page.getCurrent();  当前页
//page.getRecords();  每页数据list集合
//page.getSize();  每页显示记录数
//page.getTotal();  总记录数
//page.getPages();  总页数
//page.hasNext();  是否有下一页
//page.hasPrevious();  是否有上一页
```
![查询语句](MybatisPlus功能.assets\16a0d8e97596475492e64475d07171cd.png)

###逻辑删除
- 数据库添加字段deleted，实体类添加属性deleted
- 实体类deleted上添加注解    
    @TableLogic
    @TableField(fill = FieldFill.INSERT)
    private Integer deleted;
- 配置文件
mybatis-plus.global-config.db-config.logic-delete-value=1
mybatis-plus.global-config.db-config.logic-not-delete-value=0
- 配置类
```java
@EnableTransactionManagement  //开启事务支持,需要依赖jdbc
@Configuration
@MapperScan("com.cj.springcloud.dao")
public class MybatisPlusConfig {

    @Override
    public void insertFill(MetaObject metaObject) {
        this.setFieldValByName("deleted", 0, metaObject);
    }

}
```
- 完成配置后调用MP的删除方法，会进行逻辑删除自动将deleted置为1；通过MP的查找方法，会自动忽略deleted为1的记录。
![删除实际执行更新操作，因为结果是幂等的，不考虑加锁](MybatisPlus功能.assets\24631f38f1ed4cfd89019c92847c4dda.png)
![查询时只查未被逻辑删除的记录](MybatisPlus功能.assets