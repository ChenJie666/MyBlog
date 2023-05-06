---
title: Spark实时项目
categories:
- 大数据实时
---
离线处理：有界的批处理
实时处理：无界的流处理

![1565573300066](F:/Typora/图片/1565573300066.png)

	从kafka到hdfs中的flume的作业：可以直接从kafka中读取数据导入到hdfs中，不用自己写消费者然后将消费的数据上传到hdfs中。

	从mysql导入到hdfs中一般使用sqoop，但是sqoop底层基于MR，速度较慢；因此可以用spark/flink自己写代码进行导入导出。

	web app微服务：将数据库中的数据查询出来，写一个web app，可以通过web请求来调用数据库中的数据。请求为http://url , 查询结果以json数组返回。

![1565573307329](F:/Typora/图片/1565573307329.png)

	sparkStreaming用于清洗、转换、计算、聚合，转化之后的数据量比较大，一般存储到redis、es和hbase中。

	phoenix为hbase提供sql语言可查询的功能；会写springmvc；

	canal可以从mysql中实时读取数据（模拟mysql的从机发送dump请求）

实时：1.模拟日志2.1搭建日志采集集群2.2利用canal采集mysql中的数据发送到kafka中3.消费kafka中的数据4.把数据保存到对应的存储容器5.查询存储容器中的数据发布成web接口。



maven的三种关系：
①依赖关系：依赖于模块的jar
②继承关系：继承pom.xml
③聚合关系：有相同的生命周期，module中填写的就是有聚合关系的模块；如果该模块进行打包，其他也会打包![1565604998324](F:/Typora/图片/1565604998324-1566143759939.png)



**Spring**
　　Spring就像是整个项目中装配bean的大工厂，在配置文件中可以指定使用特定的参数去调用实体类的构造方法来实例化对象。也可以称之为项目中的粘合剂。
　　Spring的核心思想是IoC（控制反转），即不再需要程序员去显式地`new`一个对象，而是让Spring框架帮你来完成这一切。
**SpringMVC**
　　SpringMVC在项目中拦截用户请求，它的核心Servlet即DispatcherServlet承担中介或是前台这样的职责，将用户请求通过HandlerMapping去匹配Controller，Controller就是具体对应请求所执行的操作。SpringMVC相当于SSH框架中struts。
**mybatis**
　　mybatis是对jdbc的封装，它让数据库底层操作变的透明。mybatis的操作都是围绕一个sqlSessionFactory实例展开的。mybatis通过配置文件关联到各实体类的Mapper文件，Mapper文件中配置了每个类对数据库所需进行的sql语句映射。在每次与数据库交互时，通过sqlSessionFactory拿到一个sqlSession，再执行sql命令。

**springBoot**

	①将spring和springMVC整合到一起，将参数配置完成，约定大于配置大于代码；
	②springBoot内部集合Tomcat；springBoot整合配置第三方软件，**spring web starter包**整合了（tomcat、mysql、redis,elasticsearch,dubbo,kafka）等第三方工具；
	③只需要配置application.properties文件或application.yml文件。



jar  war  pom工程



400   （错误请求）服务器不理解请求的语法。
403   （禁止）服务器拒绝请求。
500   （服务器内部错误）  服务器遇到错误，无法完成请求。
503   （服务不可用）服务器目前无法使用
200   （成功）  服务器已成功处理了请求





lombok能通过注解的方式,在编译时自动为属性生成构造器、getter/setter、equals、hashcode、toString方法

80端口是服务器的缺省端口，省略则为80端口。springboot中可以在配置文件中修改。



system.out和system.err区别是打印的颜色不同，黑和红



linux不允许非root用户使用1024一下的端口。
sudo setcap cap_net_bind_service=+eip /bigdata/nginx/sbin/nginx  可以使nginx绕过端口的限制



项目中的注释
①@ResponseBody
②@Controller		@Controller+@ResponseBody简写为@RestController
③@SpringBootApplication	@Configuration（标识这个类可以使用Spring IoC容器作为bean定义的来源）+@EnableAutoConfiguration（能够自动配置spring的上下文，试图猜测和配置你想要的bean类）+@ComponentScan（会自动扫描指定包下的全部标有@Component的类，并注册成bean）也可以指定扫描的类
④@postMapping("log") 和 @RequestMapping(name="/log",method=RequestMethod.POST) 效果相同，即接收post请求；如果url文件名为log，则调用方法并返回方法的返回值。
⑤@ResponseBody	不将方法的返回值当作url，而是当作一个字符串。一般和@postMapping("log")一起使用。
⑥@Slf4j	（Simple Logging Facade for Java）SLF4J，即简单日志门面，只服务于各种各样的日志系统。如果采用lombok的@Slf4j注释，可以直接写log，会自动生成Slf4j对象--log。log.info("...")会根据resourses中的配置信息进行打印输出（可以在任意多个地方输出，如文件中或控制台中）。
⑦@RequestParam 用于将指定的请求参数赋值给方法中的形参。即将请求头或请求体中的k对应的v赋值给方法中的形参。
⑧@Autowired 注释,它可以对类成员变量、方法及构造函数进行标注,完成自动装配的工作

log4j
logback
logging：springboot内置的log工具，如果想要使用log4j中的配置进行打印，需要将logging禁用（pom文件中exclusion属性中加入logging）
日志级别：trace、debug、info、warn、error、fatal、



lombok注释：
①@Data	//生成Getter 和 ToString
②@AllArgsConstructor  //生成构造方法



```java
通过url向服务器发送请求：
public class LogUploader {
    public static void sendLogStream(String log){
        try{
            //不同的日志类型对应不同的URL

            URL url  =new URL("http://logserver:8080/log");

            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            //设置请求方式为post
            conn.setRequestMethod("POST");

            //时间头用来供server进行时钟校对的
            conn.setRequestProperty("clientTime",System.currentTimeMillis() + "");
            //允许上传数据
            conn.setDoOutput(true);
            //设置请求的头信息,设置内容类型为JSON
            conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");

            System.out.println("upload" + log);

            //输出流
            OutputStream out = conn.getOutputStream();
            out.write(("logString="+log).getBytes());
            out.flush();
            out.close();
            int code = conn.getResponseCode();//返回的状态码
            System.out.println(code);
        }
        catch (Exception e){
            e.printStackTrace();
        }
    }
}

/*向kafka发送数据，用到springboot框架，springboot整合kafka，直接通过kafkaTemplate类发送，信息在application.properties中配置*/
@Slf4j
@RestController
public class LoggerController {

    @Autowired
    KafkaTemplate<String,String> kafkaTemplate;

//    @ResponseBody
    @PostMapping("log")
    public String dolog(@RequestParam("logString") String json){
        //1.补充时间戳
        JSONObject jsonObject = JSON.parseObject(json);
        jsonObject.put("ts", System.currentTimeMillis());
        //2.写日志（用于离线采集）
        log.info(jsonObject.toJSONString());

        //3.发往kafka
        if("startup".equals(jsonObject.get("type"))) {
            kafkaTemplate.send(GmallConstants.KAFKA_TOPIC_STARTUP, jsonObject.toJSONString());
        }else{
            kafkaTemplate.send(GmallConstants.KAFKA_TOPIC_EVENT, jsonObject.toJSONString());
        }

        return "success";
    }
}

//增加log4j.properties
log4j.appender.atguigu.MyConsole=org.apache.log4j.ConsoleAppender
log4j.appender.atguigu.MyConsole.target=System.err
log4j.appender.atguigu.MyConsole.layout=org.apache.log4j.PatternLayout    
log4j.appender.atguigu.MyConsole.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss} %10p (%c:%M) - %m%n 

log4j.appender.atguigu.File=org.apache.log4j.DailyRollingFileAppender
log4j.appender.atguigu.File.file=d:/applog/gmall2019/log/app.log
log4j.appender.atguigu.File.DatePattern='.'yyyy-MM-dd
log4j.appender.atguigu.File.layout=org.apache.log4j.PatternLayout
log4j.appender.atguigu.File.layout.ConversionPattern=%m%n

log4j.logger.com.atguigu.xxxxxx.XXXXcontroller=info,atguigu.File,atguigu.MyConsole
```

```scala
//读取.properties中的值
object PropertiesUtil { 	
  def main(args: Array[String]): Unit = {
    val properties: Properties = PropertiesUtil.load("config.properties")
    println(properties.get("kafka.broker.list"))
  }

  def load(propertieName:String): Properties ={
    val properties = new Properties()
    val reader = new InputStreamReader(Thread.currentThread().getContextClassLoader.getResourceAsStream(propertieName), "UTF-8")
    properties.load(reader)
    properties
  }
}
//获取kafka的DStream
object MykafkaUtil {

  private val properties: Properties = PropertiesUtil.load("config.properties")

  private val kafka_list: String = properties.getProperty("kafka.broker.list")

  private val kafkaParam = Map(
    ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG -> kafka_list,
    ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG -> classOf[org.apache.kafka.common.serialization.StringDeserializer],
    ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG -> classOf[org.apache.kafka.common.serialization.StringDeserializer],
    ConsumerConfig.GROUP_ID_CONFIG -> "Spark_kafka",
    ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG -> (true:java.lang.Boolean), //scala中的true默认为AnyVal类型的，而下面需要填入object类型的，所以要指定java类型的true
    ConsumerConfig.AUTO_OFFSET_RESET_CONFIG -> "latest"
  )

  def getKafkaStream(topic: String, ssc: StreamingContext): InputDStream[ConsumerRecord[String, String]] = {

    val inputDS: InputDStream[ConsumerRecord[String, String]] = KafkaUtils.createDirectStream[String, String](ssc, LocationStrategies.PreferConsistent, ConsumerStrategies.Subscribe[String, String](Array(topic), kafkaParam))
    inputDS

  }
}
//求日活，对mid进行去重，然后写入到hbase中（phoenix）
object DauApp {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("kafka").setMaster("local[*]")
    val ssc = new StreamingContext(conf,Seconds(5))

    val inputDS: InputDStream[ConsumerRecord[String, String]] = MykafkaUtil.getKafkaStream(GmallConstants.KAFKA_TOPIC_STARTUP,ssc)

    val valueDS: DStream[String] = inputDS.map(cr => cr.value())
//    value.print()
    //转换为样例类
    val objDS: DStream[StartupLog] = valueDS.map {
      json =>
        val startupLog = JSON.parseObject(json, classOf[StartupLog])
        val str: String = new SimpleDateFormat("yyyy-MM-dd HH").format(startupLog.ts)
        val split: Array[String] = str.split(" ")
        startupLog.logDate = split(0)
        startupLog.logHour = split(1)
        startupLog
    }

    objDS.cache() //防止本次处理未完成，下次数据到达，导致的线程安全问题

    //对批次中的数据进行过滤
    val groupDS: DStream[(String, Iterable[StartupLog])] = objDS.map {
      obj => (obj.mid, obj)
    }.groupByKey()

    val takeDS: DStream[StartupLog] = groupDS.flatMap {
      case (mid, iter) => iter.take(1)
    }


    //对批次间的数据进行过滤
    val filterDS: DStream[StartupLog] = takeDS.transform {
      rdd =>
        println("批次间过滤前数量为" + rdd.count())
        val jedis = new Jedis("hadoop102", 6379)
        val date: String = new SimpleDateFormat("yyyy-MM-dd").format(new Date())
        val set: util.Set[String] = jedis.smembers(date)

        val broadcast: Broadcast[util.Set[String]] = ssc.sparkContext.broadcast(set)
        val filterRDD: RDD[StartupLog] = rdd.filter {
          obj => !broadcast.value.contains(obj.mid)
        }
        println("批次间过滤后数量为" + filterRDD.count())
        filterRDD
    }

    //更新redis上的数据
    filterDS.foreachRDD{
      rdd => rdd.foreachPartition{
        iter =>
          val list: List[StartupLog] = iter.toList
          val jedis = new Jedis("hadoop102", 6379)
          list.foreach{obj =>
            jedis.sadd(obj.logDate,obj.mid)
          }
      }
    }

    filterDS.print()

    import org.apache.phoenix.spark._

    filterDS.foreachRDD{
      rdd => rdd.saveToPhoenix(
        "gmall0311_dau",
        Seq("MID", "UID", "APPID", "AREA", "OS", "CH", "TYPE", "VS", "LOGDATE", "LOGHOUR", "TS"),
        new Configuration,
        Some("hadoop102,hadoop103,hadoop104:2181")
      )
    }


    ssc.start()
    println("启动流程")
    ssc.awaitTermination()
  }
}
```



enable.auto.commit : kafka的offset自动提交，可能会导致数据？？？；可以自己维护一个offset的存储。

log4j.properties中的类名替换为rootLogger，表示所有的类都打印。



hbase、mysql、es和redis集群用于存储数据。



ls /brokers/ids 如果zk不正常关闭导致无法启动kafka，删除zk客户端中的ids



cache  多线程安全  



es	①数据量相对小一点，1T一下②支持单表复杂查询，不建议进行join③全文检索④kibana  bi工具
hbase   ①数据量大，1T以上用（hdfs支持）②原生的hbase不利于分析，查询手段单一（get和scan），所以整合phoenix框架，phoenix好处 1.支持sql，复杂查询（过滤、聚合、join）2.二级索引 ？？。



phoenix的索引相当于一列rowkey

全局索引   查询语句中的select设计的字段 必须包含在索引中   或者在 索引的include中

全局索引和本地索引：全局索引管理所有表的索引信息，当索引需要更新时，可能会有网络传输 ；
本地索引存储在表中，当表进行更新时，索引更新不需要网络传输。
所以全局索引适合多读少些（面向事务），本地索引适合少读多写（面向分析）；

```sql
select * from "TABLE_03111"
upsert into "TABLE_03111" values('2','lisi','19')
//创建主键索引
create index my_index1 on TABLE_03111("id")
//创建全局索引
create index my_index2 on TABLE_03111("info"."name")
//删除索引
drop index my_index2 on "TABLE_03111"
//创建全局索引
create index my_index3 on "TABLE_03111"("info"."name") include("info"."age")
//查看执行是是否用到索引
explain select * from "TABLE_03111" where "id"='2'
explain select "age" FROM  "TABLE_03111" where "name"='zhangsan'
//创建本地索引
create local index my_index4 on "TABLE_03111"("info"."name") 
explain select * from "TABLE_03111" where "name"='zhangsan'
```



controller  控制 发布web接口或页面
service 业务 处理业务逻辑
dao 数据 查询后台数据

mapper（即dao层）  mybatis查询数据库 映射成java对象 

guava是google工具包；org.apache.common.lang3是apache的工具包（里面有好用的DateUtils类处理时间）DateUtils.addDays(date, -1)



查看mysql是否开启binlog。mysql配置文件中/etc/my.conf中log-bin=mysql-bin , mysql的数据目录在/var/lib/mysql中的mysql-bin文件就是binlog文件。每次mysql服务的开启都会产生一个binlog文件。

模版在 /usr/share/mysql



binlog_format：

	statement  语句级	记录执行的语句，但可能会造成数据不一致。
	row 行级	记录变化后的数据，但是会造成数据的冗余。canal用row，因为只关心改变的数据。
	mixed 混合	一些内定的特殊情况使用row，其他情况使用statement。主从复制用mixed。



老师提供的脚本文件生成数据指令：
CALL init_data(‘2019-08-14’，100 , 2 , true)  参数为日期、订单数、用户数、是否覆盖
CALL insert_user("2019-08-18",5,TRUE)	插入用户

 

(视频day03_4 )canal基本结构:![canal](F:/Typora/图片/canal.PNG)

	canal分为客户端和服务端，服务端有一个总的配置文件和多个instance配置文件；每个instance配置文件对应一个mysql集群，所以一个canal可以监控多个mysql集群。每个instance将读取的数据放置在相互独立的队列中，客户端可以随时进行消费。
	canal的客户端是一个jar包，可以在java端调用API启动，client会主动从canal中拉取数据。





练习：增加一个额外的字段，是否是首次消费

14:35



DStream如果是（k，v）结构，可以使用groupByKey。



kibana

<http://hadoop102:9200/_cat/health?v> 查看集群的健康状况，“？v”可以规范输出格式



## 灵活查询：ES数据的读取

```
GET		
POST	相当于insert update		和幂等性有关
PUT		相当于create
DELETE	
Head

GET _cat/nodes?v
GET _cat/indices?v	查所有的索引

mysql			elasticsearch
datebase		index			相当于一个db对应一个table			
table			type			index（type='_doc'）
row				document		
column			field		

es中把定义index中描述每个字段的信息（字段名，字段类型。。） 称为mapping

没有先建索引，而是直接插入数据，则会自动进行类型推断。整数推断为long，浮点数推断为float，字符串推断为TEXT类型，同时自动生成该字段的子字段keyword，类型为keyword，主字段和子字段都可以存储数据。
PUT customer0311/doc/1
{
    "name":"zhangsan",
    "age":22
}

在ES 上建索引
PUT gmall_coupon_alert
{
   "mappings": {
     "_doc":{
       "properties":{
         "mid":{
           "type":"keyword"
         },
         "uids":{
           "type":"keyword"	//HashSet存入后，会转化为字符串形式
         },
         "itemIds":{
           "type":"keyword"
         },
         "events":{
           "type":"keyword"
         },
        "ts":{
           "type":"date"
         } 
       }
     }
   }
}
查看创建的表的表结构
get gmall_coupon_alert/_mapping

#字符串类型  text\ keyword
text：会进行分词，每个分词建索引消耗大量空间
keyword：不会进行分词，只建一个索引

对表进行检索，会对字段分词，只要zhang或san匹配上，就命中
GET customer0311/_search
{
    "query":{
        "match":{
            "customer_name":"zhang san"
        }
    }
}
也是全文检索，加上keyword后不分词，必须”zhang san“完全匹配上才命中
GET customer0311/_search
{
    "query":{
        "match":{
            "customer_name.keyword":"zhang san"
        }
    }
}

检查分词器：
GET _analyze
{
  "analyzer":"ik_smart",
  "text":"我是中国人"
}


查询条件中既有匹配又有过滤时用bool；
term表示按照字段进行搜索；
"operator":"and"表示字段之间时并且关系，即都要匹配上；
aggs用于将属性进行聚合，AGG_TYPE表示聚合的方法，如sum、avg、max、terms等等，terms就是groupby，以field进行聚合，分为size组；
from是行码，从零开始计算，size是从指定行开始显示的数据数；假设用户给的页码为n，(n-1)*size即是该页的起始行号。

//es的过滤、查找，分组聚合，分页输出
GET gmall0311_sale_detail/_search
{
  "query":{
    "bool":{
      "filter":{
        "term": {
          "dt":"2019-08-20"
        }
      },
      "must":{
        "match":{
          "sku_name": {
            "query":"小米wifi",
            "operator":"and"
          }
        }
      }
    }
  }
  , 
  "aggs": {
    "groupbygender": {
      "terms": {
        "field": "user_gender",
        "size": 2
      }
    }
    ,
    "groupbyage": {
      "terms": {
        "field":"user_age",
        "size":100
      }
    }
  }
  ,
  "from": 3,	##这是第二页的第一行
  "size": 3
}
```

	ES和spark不像phoenix和spark有一个整合包，需要我们自己编写逻辑写入到ES中。导入jest依赖，jest-->elasticsearch  类似  jedis-->redis。

	indexName、type、id、source；即表名、type（_doc）、id（主键）、数据



fastjson解析不了样例类：
val orderJson: String = JSON.toJSONString(orderOpt.get)会报错
用json4s包中的方法，导入json4s包和隐式转换：
import org.json4s.jackson.Serialization
implicit val formats = org.json4s.DefaultFormats
val orderSer: String = Serialization.write(orderOpt.get) 获得json字符串



**import** collection.JavaConversions._	将java的集合隐式转换为scala的集合









kibana的dashboard表可以进行share-embodycode-saved object，确认copy iFrame code（可以在html代码中的一个内嵌的区域引用第三方app）

```
<html>
<iframe src=......><iframe>
</html>
用网页打开该html格式的文件即可
```





# 项目流程：

sparkstreaming 可以用于清洗、转换、计算、聚合。

数据源：

### 需求一   日活（dau）：

本框架中没有使用flume，从日志服务器直接将数据发给kafka；分为type：startup和type：event两种类型发给不同的topic。

```
工具类准备：
创建从配置文件中读取数据的工具类，用于kafka和redis的配置参数获取。
创建从kafka读取数据的工具类，用于spark读取kafka中的数据。
创建获取redis连接池的工具类，用于获取redis客户端jedis对象。

样例类准备：
创建样例类用于将kafka中读取到的数据进行封装。
```

**objDS.cache() //防止本次处理未完成，下次数据到达，导致的线程安全问题**

```scala
日活（dau）——需求实现：
1.通过工具类从kafka中读取数据
2.对相同的mid进行去重   
要点：通过redis进行去重。如果存为string类型（日期和mid拼成key），不会造成数据倾斜，如果存为set类型（日期作为key，mid为value），可能造成数据倾斜，但是管理方便（设置过期等）。
去重过程：通过transform算子（每个流都会执行一次）获取redis中的当天用户的set集合，广播给各个executor，再利用filter算子过滤set集合中存在的mid，返回过滤后的rdd；然后再对该批次内的数据进行去重（以mid进行分组获取每组第一个数据的mid）。
3.将该批次的新增的数据写入到redis中。
4.也需要将该批次的数据写入hbase+phoenix中。(实时不用hive进行数据处理，用到高效的HBase或ES框架进行处理)
要点：HBase通过Phoenix框架进行交互
import org.apache.phoenix.spark._
distictDstream.foreachRDD{rdd=>
  rdd.saveToPhoenix("GMALL2019_DAU",Seq("MID", "UID", "APPID", "AREA", "OS", "CH", "TYPE", "VS", "LOGDATE", "LOGHOUR", "TS") ,new Configuration,Some("hadoop1,hadoop2,hadoop3:2181"))
}

5.需要自己写一个微服务框架springboot(1.5)，供可视化组进行数据拉取并实时展示。
用到Spring Web Starter（springboot框架）、lombok（自动生成get/set、toString、构造器等方法）、JDBC API、用到MyBatis Framework（在配置文件中写sql，查询结果自动放到集合中）
分层：
controller	 控制 发布web接口或页面
service 	业务 处理业务逻辑
dao			数据 查询后台数据

mapper		mybatis查询数据库 映射成java的对象

返回的是json格式，可以先放入map集合中，然后通过FastJson的toJsonString方法转为json字符串。
```

![1568454136288](F:/Typora/图片/1568454136288.png)



### 需求二   交易额（gmv）：

canal：用于监控mysql中的表的变化，将变化的数据放到临时表中。进行实时统计。

```scala
工具类准备：
1.canal处理类：包括构造方法，canal数据的解析方法，解析后数据发送给kafka的方法
要点：canal得到的数据是entry对象，相当于一条sql；反序列化后得到RowChange -> 多个RowDataList组成 -> 多个RowData组成 -> ColumnList -> Column -> Column_Name,Column_Value
2.kafka发送工具类：将数据发送给kafka，在canal处理类中调用。
3.client客户端：
CanalConnector canalConnector = CanalConnectors.newSingleConnector(new InetSocketAddress("hadoop102",11111), "example", "", "");
canalConnector.connect();
canalConnector.subscribe("sparkgmall.*");
while(true){
   Message message = canalConnector.get(100);
   List<CanalEntry.Entry> entries = message.getEntries();
}
获取canal中的数据，然后解析entries后，发送给kafka。
```



```
交易额（gmv）--需求实现：
1.通过canal获取业务系统mysql中的数据，通过工具类进行解析并发送给kafka。
2.sparkstreaming消费kafka并保持到Hbase中。
要点：在封装为样例类时需要进行脱敏。然后通过rdd.saveToPhoenix 保存到HBase中。
3.利用springboot框架编写微服务框架，根据请求信息返回对应格式的数据。

```

![1568524911898](F:/Typora/图片/1568524911898.png)

### 需求三   预警

筛选条件分析

Ø 同一设备

Ø 5分钟内

Ø 三次不同账号登录

Ø 领取优惠券

Ø 没有浏览商品

Ø 同一设备每分钟只记录一次预警

```scala
工具类准备：
Es连接工具类：创建客户端连接池方法，从连接池中获取jest客户端方法和批量插入es的方法。
  private var ES_HOST = "http://hadoop102"
  private var ES_HTTP_PORT = 9200
  private var factory: JestClientFactory = null
  //获取一个客户端对象
  private def getClient = {
    if (factory == null) {
      build()
    }
    factory.getObject
  }
   //创建jest的连接池
  private def build() = {
    factory = new JestClientFactory
    factory.setHttpClientConfig(new HttpClientConfig.Builder(ES_HOST + ":" + ES_HTTP_PORT).multiThreaded(true)
      .maxTotalConnection(20)
      .connTimeout(10000).readTimeout(10000).build())
  }
   //向ES中批量插入数据,参数为表名，主键和数据
  def indexBulk(indexName: String, dataList: List[(String, Any)]): Unit = {
    //如果dataList是空的话就不用进行插入了
    if(dataList.size > 0) {
      val client: JestClient = getClient
      val bulkbuilder = new Bulk.Builder()
      for ((id, source) <- dataList) {
        val index: Index = new Index.Builder(source).index(indexName).`type`("_doc").id(id).build()
        bulkbuilder.addAction(index)
      }

      val bulk: Bulk = bulkbuilder.build()
      val items: util.List[BulkResult#BulkResultItem] = client.execute(bulk).getItems //TODO 获取插入的条数

      println("插入了" + items.size() + "条报警信息")
      close(client)
    }
  }

```

	**可能会出先mutil-thread异常，因为window窗口的数据有重叠，如果前面的线程没有处理完该批次数据，下一批数据就到了，就会出现批数据被多个线程引用，所以在批数据进行开窗前，先对其进行cache缓存。**

```
预警 --需求实现：
1.将从kafka读取的event日志转换为样例类，然后进行开窗，窗口大小为300s，步长为5s（批次时间为5s）。
2.然后根据mid进行聚合。
1）在每个group中，对时间进行遍历，如果事件id为coupon，则将uid加入到set集合中；
2）同时需要判断用户是否点击了商品，设置flag=false，如果点击，则设为true，跳出循环；
3）返回最终的结果为tuple2类型，第一个元素是是否报警，第二个元素是预警样例类。
3.需要报警的信息过滤出来，然后批量插入到es已经创建的表中。注意需要拼接mid+分钟形成主键，相同主键后面的会覆盖前面的，实现去重，同一设备每分钟只记录一次预警。
4.通过springboot框架创建微服务框架，根据请求信息返回相应格式的json字符串。也可以直接通过Kibana进行展示。

```

![1568524902467](F:/Typora/图片/1568524902467.png)



### 需求四  灵活分析

需求：通过日期关键字，查询出对应的数据。并计算出男女比例、年龄比例、购买数据明细。

思路：最终结果需要将多张表进行join，ES中不能进行join，所以需要在存入ES前完成join。

①T+1方式：通过sqoop将表导入hive中进行join，第二天展示结果。

![1568531267771](F:/Typora/图片/1568531267771.png)

②T+0方式：通过canal将数据导入到kafka中，用sparkstreaming对表进行join，实时展示结果。

![1568531261534](F:/Typora/图片/1568531261534.png)

```
灵活分析 --T+0 需求实现：
1.从kafka中读取数据，分别读取order_info，order_detail和user_info表。

2.在spark中完成对表order_info和order_detail的join。
要点：
由于延迟等因素，表中的批数据不是同步到达的，所以需要对数据进行缓存然后join。（双流join）
先完成order_info.fullOutJoin(order_detail)得到joinedStream，然后再对joinedStream进行遍历。
1）如果order_info，order_detail都匹配上，那么加入到resultList中。并将orderId作为key、order_info作为value，缓存到redis的set集合中（因为可能后续还有相同orderId的order_detail需要进行匹配，同时可以进行去重）
2）如果只有order_info，那么将orderId作为key、order_info作为vlaue缓存到redis的set集合中。并读取redis中的相同orderId的order_detail数据，得到set集合，进行遍历，组合成tuple放入到resultList中。
3）如果只有order_detail，那么将order_detail缓存到redis中。并读取redis中的相同orderId的order_info的数据，得到set集合，进行遍历，组合成tuple放入到resultList中。
4）最后将resultList返回，得到本批次匹配后的数据，并将需要的数据缓存到redis中。

3.将上面的tuple数据转化为样例类，然后和user_info进行关联。
要点：
1）因为用户信息是需要随时查全表的进行关联的，所以将每批次的user_info全放入到redis中（也可以直接在mysql中查询，数据量太大，可以放到HBase中）。
2）因为是一对一的关系，所以可以使用string和hash方式保存到redis。string不能统一管理（如不能取出所有的value值），在集群中hash会造成数据倾斜。我们采用string方式，userid作为key，user_info作为value。
3）遍历resultList，从redis中取出向同userid的user_info，然后组合成tuple。放入到saleList中。
4）最后将saleList存入到ES中创建的表中。

4.通过springboot框架创建微服务框架，根据请求信息返回相应格式的json字符串。也可以直接通过Kibana进行展示。（ES需要配置ik分词器插件）
要点：
ES的请求语句可以写为算子的形式

```





对ES中的表格进行检索：

```scala
public Map getSaleDetail(String date,int startpage,int size,String key) {
//        String sql = "GET gmall0311_sale_detail/_search
" +
//                "{
" +
//                "  \"query\":{
" +
//                "    \"bool\":{
" +
//                "      \"filter\":{
" +
//                "        \"term\": {
" +
//                "          \"dt\":\"2019-08-20\"
" +
//                "        }
" +
//                "      },
" +
//                "      \"must\":{
" +
//                "        \"match\":{
" +
//                "          \"sku_name\": {
" +
//                "            \"query\":\"小米wifi\",
" +
//                "            \"operator\":\"and\"
" +
//                "          }
" +
//                "        }
" +
//                "      }
" +
//                "    }
" +
//                "  }
" +
//                "  , 
" +
//                "  \"aggs\": {
" +
//                "    \"groupbygender\": {
" +
//                "      \"terms\": {
" +
//                "        \"field\": \"user_gender\",
" +
//                "        \"size\": 2
" +
//                "      }
" +
//                "    }
" +
//                "  }
" +
//                "  ,
" +
//                "  \"from\": 3,
" +
//                "  \"size\": 3
" +
//                "}";

        //查询语句
        SearchSourceBuilder searchSourceBuilder = new SearchSourceBuilder();
        BoolQueryBuilder boolQueryBuilder = new BoolQueryBuilder();
        boolQueryBuilder.filter(new TermQueryBuilder("dt",date));
        boolQueryBuilder.must(new MatchQueryBuilder("sku_name",key).operator(MatchQueryBuilder.Operator.AND));
        searchSourceBuilder.query(boolQueryBuilder);
        //聚合
        TermsBuilder groupby_gender = AggregationBuilders.terms("groupby_gender").field("user_gender").size(2);
        TermsBuilder groupby_age = AggregationBuilders.terms("groupby_age").field("user_age").size(100);
        searchSourceBuilder.aggregation(groupby_gender);
        searchSourceBuilder.aggregation(groupby_age);
        //分页
        searchSourceBuilder.from((startpage-1)*size);
        searchSourceBuilder.size(size);

        System.out.println(searchSourceBuilder.toString());
        Search search = new Search.Builder(searchSourceBuilder.toString()).addIndex(/*GmallConstants.ES_PRODUCT_DETAIL*/"gmall_product_detail").addType("_doc").build();

        HashMap map = new HashMap();
        HashMap<String, Long> genderMap = new HashMap<>();
        HashMap<Object, Object> ageMap = new HashMap<>();
        try {
            SearchResult searchResult = jestClient.execute(search);
            Long total = searchResult.getTotal();

            List<SearchResult.Hit<Map, Void>> hits = searchResult.getHits(Map.class);
            ArrayList<Map> hitList = new ArrayList<>();
            for (SearchResult.Hit<Map, Void> hit : hits) {
                hitList.add(hit.source);
            }
            //获取gender的聚合后的kv值
            List<TermsAggregation.Entry> groupbygender = searchResult.getAggregations().getTermsAggregation("groupby_gender").getBuckets();
            for (TermsAggregation.Entry entry : groupbygender) {
                genderMap.put(entry.getKey(),entry.getCount());
            }
            //获取age的集合后的kv值
            List<TermsAggregation.Entry> groupbyage = searchResult.getAggregations().getTermsAggregation("groupby_age").getBuckets();
            for (TermsAggregation.Entry entry : groupbyage) {
                ageMap.put(entry.getKey(),entry.getCount());
            }

            map.put("total",total);
            map.put("source",hitList);
            map.put("groupby_gender",genderMap);
            map.put("groupby_age",ageMap);
        } catch (IOException e) {
            e.printStackTrace();
        }finally {
            try {
                jestClient.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        return map;
    }

```
