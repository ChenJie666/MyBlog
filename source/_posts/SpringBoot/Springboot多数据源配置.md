---
title: Springboot多数据源配置
categories:
- SpringBoot
---
参考：[SpringBoot 的多数据源配置 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/340528068)

### 1. 引入数据源依赖
SpringBoot 的多数据源开发十分简单，如果多个数据源的数据库相同，比如都是 MySQL，那么依赖是不需要任何改动的，只需要进行多数据源配置即可。

如果你新增的数据库数据源和目前的数据库不同，记得引入新数据库的驱动依赖，比如 MySQL 和 PGSQL。
****
```
<dependency>
 <groupId>mysql</groupId>
 <artifactId>mysql-connector-java</artifactId>
 <scope>runtime</scope>
</dependency>

<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <version>42.2.7</version>
</dependency>
```

### 2. 连接配置
```
########################## 主数据源 ##################################
spring.datasource.primary.jdbc-url=jdbc:mysql://127.0.0.1:3306/demo1?characterEncoding=utf-8&serverTimezone=GMT%2B8
spring.datasource.primary.driver-class-name=com.mysql.jdbc.Driver
spring.datasource.primary.username=root
spring.datasource.primary.password=

########################## 第二个数据源 ###############################
spring.datasource.datasource2.jdbc-url=jdbc:mysql://127.0.0.1:3306/demo2?characterEncoding=utf-8&serverTimezone=GMT%2B8
spring.datasource.datasource2.driver-class-name=com.mysql.jdbc.Driver
spring.datasource.datasource2.username=root
spring.datasource.datasource2.password=

# mybatis
mybatis.mapper-locations=classpath:mapper/*.xml
mybatis.type-aliases-package=com.wdbyte.domain
```
注意，配置中的数据源连接 url 末尾使用的是 jdbc-url.

因为使用了 Mybatis 框架，所以 Mybatis 框架的配置信息也是少不了的，指定扫描目录 mapper 下的mapper xml 配置文件。

### 3. 创建mapper接口
下面我已经按照上面的两个库中的两个表，Book 和 User 表分别编写相应的 Mybatis 配置。

创建 BookMapper.xml 和 UserMapper.xml 放到配置文件配置的路径 mapper 目录下。创建 UserMapper 和 BookMapper 接口操作类放在不同的目录。这里注意 Mapper 接口要按数据源分开放在不同的目录中。后续好使用不同的数据源配置扫描不同的目录，这样就可以实现不同的 Mapper 使用不同的数据源配置。

![image.png](Springboot多数据源配置.assets\1d310cf26c8240d3ac161a2cc13fe5f5.png)
Service 层没有变化，这里 BookMapper 和 UserMapper 都有一个 selectAll() 方法用于查询测试。



### 3. 多数据源配置
**上面你应该看到了，到目前为止和 Mybatis 单数据源写法唯一的区别就是 Mapper 接口使用不同的目录分开了，那么这个不同点一定会在数据源配置中体现。**

#### 3.1 主数据源
开始配置两个数据源信息，先配置主数据源，配置扫描的 MapperScan 目录为 com.wdbyte.mapper.primary

```
@Configuration
@MapperScan(basePackages = {"com.wdbyte.mapper.primary"}, sqlSessionFactoryRef = "sqlSessionFactory")
public class PrimaryDataSourceConfig {

    @Bean(name = "dataSource")
    @ConfigurationProperties(prefix = "spring.datasource.primary")
    @Primary
    public DataSource dataSource() {
        return DataSourceBuilder.create().build();
    }

    @Bean(name = "sqlSessionFactory")
    @Primary
    public SqlSessionFactory sqlSessionFactory(@Qualifier("dataSource") DataSource dataSource) throws Exception {
        SqlSessionFactoryBean bean = new SqlSessionFactoryBean();
        bean.setDataSource(dataSource);
        bean.setMapperLocations(new PathMatchingResourcePatternResolver().getResources("classpath:mapper/*.xml"));
        return bean.getObject();
    }

    @Bean(name = "transactionManager")
    @Primary
    public DataSourceTransactionManager transactionManager(@Qualifier("dataSource") DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }

    @Bean(name = "sqlSessionTemplate")
    @Primary
    public SqlSessionTemplate sqlSessionTemplate(@Qualifier("sqlSessionFactory") SqlSessionFactory sqlSessionFactory) {
        return new SqlSessionTemplate(sqlSessionFactory);
    }
}
```
和单数据源不同的是这里把
- dataSource
- sqlSessionFactory
- transactionManager
- sqlSessionTemplate

都单独进行了配置，简单的 bean 创建，下面是用到的一些注解说明。
- @ConfigurationProperties(prefix = "spring.datasource.primary")：使用配置文件中配置的spring.datasource.primary 开头的数据源。
- @Primary ：声明这是一个主数据源（默认数据源），多数据源配置时必不可少。
- @Qualifier：显式选择传入的 Bean。

此处绑定了com.wdbyte.mapper.primary下的mapper接口、mapper的xml配置文件和yml配置文件中的数据源配置spring.datasource.primary，所以com.wdbyte.mapper.primary下的接口请求都会访问配置中spring.datasource.primary数据源。

#### 3.2 第二个数据源
第二个数据源和主数据源唯一不同的只是 MapperScan 扫描路径和创建的 Bean 名称，同时没有 @Primary 主数据源的注解。
```
@Configuration
@MapperScan(basePackages = {"com.wdbyte.mapper.datasource2"}, sqlSessionFactoryRef = "sqlSessionFactory2")
public class SecondDataSourceConfig {

    @Bean(name = "dataSource2")
    @ConfigurationProperties(prefix = "spring.datasource.datasource2")
    public DataSource dataSource() {
        return DataSourceBuilder.create().build();
    }

    @Bean(name = "sqlSessionFactory2")
    public SqlSessionFactory sqlSessionFactory(@Qualifier("dataSource2") DataSource dataSource) throws Exception {
        SqlSessionFactoryBean bean = new SqlSessionFactoryBean();
        bean.setDataSource(dataSource);
        bean.setMapperLocations(new PathMatchingResourcePatternResolver().getResources("classpath:mapper/*.xml"));
        return bean.getObject();
    }

    @Bean(name = "transactionManager2")
    public DataSourceTransactionManager transactionManager(@Qualifier("dataSource2") DataSource dataSource) {
        return new DataSourceTransactionManager(dataSource);
    }

    @Bean(name = "sqlSessionTemplate2")
    public SqlSessionTemplate sqlSessionTemplate(@Qualifier("sqlSessionFactory2") SqlSessionFactory sqlSessionFactory) {
        return new SqlSessionTemplate(sqlSessionFactory);
    }
}
```
注意：因为已经在两个数据源中分别配置了扫描的 Mapper 路径，如果你之前在 SpringBoot 启动类中也使用了 Mapper 扫描注解，需要删掉。


### 4. 访问测试
编写两个简单的查询 Controller 然后进行访问测试。
```
// BookController
@RestController
public class BookController {

    @Autowired
    private BookService bookService;

    @GetMapping(value = "/books")
    public Response selectAll() throws Exception {
        List<Book> books = bookService.selectAll();
        return ResponseUtill.success(books);
    }
}

// UserController
@RestController
public class UserController {

    @Autowired
    private UserService userService;

    @ResponseBody
    @GetMapping(value = "/users")
    public Response selectAll() {
        List<User> userList = userService.selectAll();
        return ResponseUtill.success(userList);
    }
}
```
访问测试，我这里直接 CURL 请求。
```
# ~ curl localhost:8080/books 
{
  "code": "0000",
  "message": "success",
  "data": [
    {
      "id": 1,
      "author": "金庸",
      "name": "笑傲江湖",
      "price": 13,
      "createtime": "2020-12-19T07:26:51.000+00:00",
      "description": "武侠小说"
    },
    {
      "id": 2,
      "author": "罗贯中",
      "name": "三国演义",
      "price": 14,
      "createtime": "2020-12-19T07:28:36.000+00:00",
      "description": "历史小说"
    }
  ]
}

# ~ curl localhost:8080/users 
{
  "code": "0000",
  "message": "success",
  "data": [
    {
      "id": 1,
      "name": "金庸",
      "birthday": "1924-03-09T16:00:00.000+00:00"
    },
    {
      "id": 2,
      "name": "罗贯中",
      "birthday": "1330-01-09T16:00:00.000+00:00"
    }
  ]
}
```
至此，多数据源配置完成，测试成功。


### 5. 连接池
其实在多数据源改造中，我们一般情况下都不会使用默认的 JDBC 连接方式，往往都需要引入连接池进行连接优化，不然你可能会经常遇到数据源连接被断开等报错日志。其实数据源切换连接池数据源也是十分简单的，直接引入连接池依赖，然后把创建 dataSource 的部分换成连接池数据源创建即可。

下面以阿里的 Druid 为例，先引入连接池数据源依赖。
```
<dependency>
   <groupId>com.alibaba</groupId>
   <artifactId>druid</artifactId>
</dependency>
```
添加 Druid 的一些配置。
```
spring.datasource.datasource2.initialSize=3 # 根据自己情况设置
spring.datasource.datasource2.minIdle=3
spring.datasource.datasource2.maxActive=20
```
改写 dataSource Bean 的创建代码部分。
```
@Value("${spring.datasource.datasource2.jdbc-url}")
private String url;
@Value("${spring.datasource.datasource2.driver-class-name}")
private String driverClassName;
@Value("${spring.datasource.datasource2.username}")
private String username;
@Value("${spring.datasource.datasource2.password}")
private String password;
@Value("${spring.datasource.datasource2.initialSize}")
private int initialSize;
@Value("${spring.datasource.datasource2.minIdle}")
private int minIdle;
@Value("${spring.datasource.datasource2.maxActive}")
private int maxActive;

@Bean(name = "dataSource2")
public DataSource dataSource() {
    DruidDataSource dataSource = new DruidDataSource();
    dataSource.setUrl(url);
    dataSource.setDriverClassName(driverClassName);
    dataSource.setUsername(username);
    dataSource.setPassword(password);
    dataSource.setInitialSize(initialSize);
    dataSource.setMinIdle(minIdle);
    dataSource.setMaxActive(maxActive);
    return dataSource;
}
```
这里只是简单的提一下使用连接池的重要性，Druid 的详细用法还请参考官方文档。
