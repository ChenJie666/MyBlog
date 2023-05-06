---
title: SpringBoot注解
categories:
- SpringBoot
---
@JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss",timezone = "GMT+8") 
 返回给前端时转换时区，默认时区是GMT。不添加timezone = "GMT+8"会比CST少8小时。可以注解在属性或对应的get方法上。
>实体类中的属性是Date类型时，返回给前端时如果需要规定日期格式，那么就可以使用@JsonFormat注解，pattern属性是输出格式，timeZone属性是需要显示哪个时区的时间。

<br>
@DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")  接受前端参数时转化的数据格式。
- pattern:自定义样式，y,M,d,h,m,s
- iso:套用spring当中已经定义好的一些。
- style:两位字符，简单的样式S,L,M,F
>post请求内容是json字符串，但是接收的类是实体类，那么springboot的默认转换工具jackson就会将json转换为实体类对象，如果属性名不同或类型不能进行转换，那么对象的这个属性为null。
如果实体类对象中有Date类型的属性，为了让json中的日期字符串可以解析为Date对象，引入了@DateTimeFormat注解，可以根据pattern格式解析日期字符串，转化为Date对象。

（理论上是这样，但是即是不引入这个注解还是可以解析一些固定格式的日期字符串，引入后自定义pattern不起作用？？？）
默认不引入注解可以识别的格式为
- "yyyy-MM-dd'T'HH:mm:ss.SSSZ"；
- "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"；
- "yyyy-MM-dd";
- "EEE, dd MMM yyyy HH:mm:ss zzz";
- long类型的时间戳（毫秒时间戳）

<br>
@NumberFormat(pattern="#,###.##")
private long salary;
指定传入格式，如果格式不正确报错。

@CrossOrigin(origins = "*",maxAge = 3600) 添加在controller上解决跨域问题跨域

@PropertySource(value = {"classpath:kaptcha.properties"}) 注解加载指定的配置文件
@Value()
@EnableConfigurationProperties 使使用 @ConfigurationProperties 注解的类生效。
@ConfigurationProperties(prefix = "aliyun.oss")   作用同@Value，可以将配置文件中的配置注入到注解类的属性中。即告诉框架将本类中的所有属性和配置文件中相关的配置进行绑定。如果有报错提示，可以导入配置文件处理器spring-boot-configuration-processor。
@PropertySource(value = {"classpath:/config.properties"}) 指定读取的配置文件
@PropertySource({"mysql.properties"})
>**属性控制注解**
@Value("normal")
private String normal; // 注入普通字符串
注入操作系统属性
@Value("#{systemProperties['os.name']}")
private String systemPropertiesName; // 注入操作系统属性
注入表达式结果
@Value("#{ T(java.lang.Math).random() * 100.0 }")
private double randomNumber; //注入表达式结果
注入其他Bean属性
@Value("#{person.name}")
private String name; // 注入其他Bean属性：注入person对象的属性name
注入文件资源
@Value("classpath:io/mykit/spring/config/config.properties")
private Resource resourceFile; // 注入文件资源
注入URL资源
@Value("http://www.baidu.com")
private Resource url; // 注入URL资源

@Validated  开启对注入的数据进行校验
@Email  对注入的属性进行校验，如果不是邮箱格式，则报错

因为@Bean比@Value和@PropertySource优先级高，导致@Bean中属性为null，可以通过注入Environment对象获取属性。
>    @Resource
>   private Environment environment;
>
>String location = environment.getProperty("jwt.location");

<br>
@EnableScheduling  在启动类上添加注解允许定时任务
@Scheduled(cron = "*/5 * * * * ?") Springboot框架提供的注解，定时执行被注解的方法


@RequestHeader("${jwt.header}")  获取请求头中的对应的属性值。

测试类注入到容器中：
@SpringBootTest
@RunWith(SpringRunner.class)

@SneakyThrows() 利用泛型将我们传入的Throwable强转为RuntimeException，使得程序无需显式处理任何异常。

@Profile({"test","dev"})     加了环境标识的bean，只有这个环境被激活的时候才能注册到容器中，默认是default环境。 写在配置类上，只有是指定的环境的时候，整个配置类里面的所有配置才能开始生效

@ThreadSafe  是表示这个类是线程安全的。是否真的线程安全不确定。

@NotEmpty用在集合类上面,不能为null，并且长度必须大于0
@NotBlank 用在String上面,只能作用在String上，不能为null，而且调用trim()后，长度必须大于0
@NotNull 用在基本类型上,不能为null，但可以为空字符串
>@Null  被注释的元素必须为null
@NotNull  被注释的元素不能为null
@AssertTrue  被注释的元素必须为true
@AssertFalse  被注释的元素必须为false
@Min(value)  被注释的元素必须是一个数字，其值必须大于等于指定的最小值
@Max(value)  被注释的元素必须是一个数字，其值必须小于等于指定的最大值
@DecimalMin(value)  被注释的元素必须是一个数字，其值必须大于等于指定的最小值
@DecimalMax(value)  被注释的元素必须是一个数字，其值必须小于等于指定的最大值
@Size(max,min)  被注释的元素的大小必须在指定的范围内。
@Digits(integer,fraction)  被注释的元素必须是一个数字，其值必须在可接受的范围内
@Past  被注释的元素必须是一个过去的日期
@Future  被注释的元素必须是一个将来的日期
@Pattern(value) 被注释的元素必须符合指定的正则表达式。
@Email 被注释的元素必须是电子邮件地址
@Length 被注释的字符串的大小必须在指定的范围内
@NotEmpty  被注释的字符串必须非空
@Range  被注释的元素必须在合适的范围内

@EnableTransactionManagement // 开启注解事务管理
@Transactional 注释的方法开启事务
手动回滚并抛出异常
try{
Product dept = new Product();
dept.setProductName("12");
productMapper.create(dept);
}catch(Exception e){
//捕获异常并执行回滚，且能拿到返回值false
TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
e.printStackTrace();
throws new IllegalArgumentException("xxx");
}

@EnableAuthorizationServer  注解来告诉spring框架自动配置一些关于AuthorizationEndpoint以及一些关于AuthorizationServer security的配置。同时，来配置访问的client的一些细节
@EnableResourceServer  注解来告诉spring框架自动配置一些关于resource server的配置，比如启用OAuth2AuthenticationProcessingFilter来检查进来的request有没有有效的accesstoken。

**四个方法级别的过滤注解：**
@EnableGlobalMethodSecurity(prePostEnabled=true)表示以下4个注解可用（hasRole hasAnyRole hasAuthority hasAnyAuthority）
- @PreAuthorize
例：@PreAuthorize("hasRole('admin')") 在方法执行前进行判断，如果当前用户不是admin角色，则拒绝访问，抛出异常。
- @PreFilter
例：@PreFilter(filterTarget="ids",value="filterObject%2==0") 在方法执行前对参数数组ids进行过滤，对数组中的值filterObject进行判断，不满足条件的参数剔除。
- @PostAuthorize
例：@PostAuthorize("returnObject.name == authentication.name")  在方法执行后进行判断，如果不满足条件，则拒绝访问，抛出异常。
- @PostFilter
例：@PostFilter("filterObject.name == authentication.name") 在方法执行之后对返回值数组进行过滤，将不满足条件的返回值剔除。



@EnableWebSecurity  启用安全认证，在Springboot中没有必要再次引用该注解，Springboot的自动配置机制WebSecurityEnablerConfiguration已经引入了该注解。
@EnableAuthorizationServer
@EnableResourceServer


**JPA注解**
@Entity 标注用于实体类声明语句之前，指出该Java类为实体类，将映射到指定的数据库表。
@Table(name = "xxx") 当实体类与其映射的数据库表名不同名时使用@Table标注说明
@Id 声明一个实体类的属性映射为数据库的主键列。
@GeneratedValue 标注主键的生成策略
- IDENTITY：采用数据库ID自增长的方式来自增主键字段，Oracle不支持这种方式（oracle12g后，应该支持了。）；
- AUTO：JPA自动选择合适的策略，是默认选项；
- SEQUENCE：通过序列产生主键，通过@SequenceGenerator(strategy=GenerationType.AUTO) 注解指定序列名，MySql不支持这种方式。
- TABLE 通过表产生键，框架借助由表模拟序列产生主键，使用该策略可以使应用更易于数据库移植。
@Column(name="xxx",nullable=false,length=64,unique=false,) 当实体的属性与其映射的数据库表的列不同名时使用。@Column标注也可以置于属性的getter方法之前。
@Basic(fetch="",optional="") 表示一个简单的属性到数据库表的字段的映射，对于没有任何标注的getXxx()方法，默认即为Basic。fetch表示该属性的读取策略，有EAGER和LAZY两种，分别表示主支抓取和延迟加载，默认为EAGER。optional表示该属性是否允许为null,默认为true。
@Transient 表示该属性并非一个到数据库表的字段的映射，ORM框架将忽略该属性。类似@TableField(exist = false)。
@Temporal(TemporalType.TIMESTAMP)  使用@Temporal注解来调整Date精度


**JACKSON的注解**
//在jackson解析该对象时(包括@ResponseBody返回对象)，将转换后的json的属性值改为指定的value值
@JsonProperty(value = "voice_version")   
String voiceVersion;
@JsonInclude(JsonInclude.Include.NON_NULL)  //springboot 返回的json中忽略null属性值

**Lombok注解**
@Data
@Accessors(chain = true)
@AllArgsConstructor
@NoArgsConstructor
@Getter(AccessLevel.NONE)  不生成该属性的getter/setter方法

**实体类属性的注解**
@Null  被注释的元素必须为null
@NotNull  被注释的元素不能为null
@AssertTrue  被注释的元素必须为true
@AssertFalse  被注释的元素必须为false
@Min(value)  被注释的元素必须是一个数字，其值必须大于等于指定的最小值
@Max(value)  被注释的元素必须是一个数字，其值必须小于等于指定的最大值
@DecimalMin(value)  被注释的元素必须是一个数字，其值必须大于等于指定的最小值
@DecimalMax(value)  被注释的元素必须是一个数字，其值必须小于等于指定的最大值
@Size(max,min)  被注释的元素的大小必须在指定的范围内。
@Digits(integer,fraction)  被注释的元素必须是一个数字，其值必须在可接受的范围内
@Past  被注释的元素必须是一个过去的日期
@Future  被注释的元素必须是一个将来的日期
@Pattern(value) 被注释的元素必须符合指定的正则表达式。
@Email 被注释的元素必须是电子邮件地址
@Length 被注释的字符串的大小必须在指定的范围内
@NotEmpty  被注释的字符串必须非空
@Range  被注释的元素必须在合适的范围内


**加载顺序注解**
@AutoConfigureAfter(RedisAutoConfiguration.class)  在加载配置的类之后再加载当前类

**判断配置类或方法是否生效**
`@ConditionalOnProperty(prefix = "filter",name = "loginFilter",havingValue = "true")  `//prefix是配置前缀，name是配置名，如果配置和havingValue相同则生效。
`@ConditionalOnProperty(name="redisson.address")` //如果配置redisson.address不为空则生效，为空的失效。
```	
@Retention(RetentionPolicy.RUNTIME)
@Target({ ElementType.TYPE, ElementType.METHOD })
@Documented
@Conditional(OnPropertyCondition.class)
public @interface ConditionalOnProperty {

	// 数组，获取对应property名称的值，与name不可同时使用
	String[] value() default {};

	// 配置属性名称的前缀，比如spring.http.encoding
	String prefix() default "";

	// 数组，配置属性完整名称或部分名称
	// 可与prefix组合使用，组成完整的配置属性名称，与value不可同时使用
	String[] name() default {};

	// 可与name组合使用，比较获取到的属性值与havingValue给定的值是否相同，相同才加载配置
	String havingValue() default "";

	// 缺少该配置属性时是否可以加载。如果为true，没有该配置属性时也会正常加载；反之则不会生效
	boolean matchIfMissing() default false;
}
```

<br>
**本地事务注解**
@Transactional
- isolation = Isonlation.REPEATABLE_READ  指定隔离级别，mysql默认为可重复读；
- propagation = Propagation.REQUIRED  指定传播行为，REQUIRED表示该方法被另一个事务方法调用，会共用一个事务，即会一起回滚；PROPAGATION_REQUIRES_NEW 表示不会共用一个事务；
- timeout = 2  指定事务执行超时时间，超时回滚；
- rollback  指定抛出异常回滚的异常类型

手动回滚的方法：`currentTransactionStatus().setRollbackOnly();`

注：传播行为分类如下
| 事务传播行为类型          | 说明                                                         |
| ------------------------- | ------------------------------------------------------------ |
| PROPAGATION_REQUIRED      | 如果当前没有事务，就新建一个事务，如果已经存在一个事务中，加入到这个事务中。这是最常见的选择。 |
| PROPAGATION_SUPPORTS      | 支持当前事务，如果当前没有事务，就以非事务方式执行。         |
| PROPAGATION_MANDATORY     | 使用当前的事务，如果当前没有事务，就抛出异常。               |
| PROPAGATION_REQUIRES_NEW  | 新建事务，如果当前存在事务，把当前事务挂起。                 |
| PROPAGATION_NOT_SUPPORTED | 以非事务方式执行操作，如果当前存在事务，就把当前事务挂起。   |
| PROPAGATION_NEVER         | 以非事务方式执行，如果当前存在事务，则抛出异常。             |
| PROPAGATION_NESTED        | 如果当前存在事务，则在嵌套事务内执行。如果当前没有事务，则执行与PROPAGATION_REQUIRED类似的操作。 |
