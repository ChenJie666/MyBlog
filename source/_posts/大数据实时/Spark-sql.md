---
title: Spark-sql
categories:
- 大数据实时
---
```
Spark SQL是Spark用来处理结构化数据的一个模块，它提供了2个编程抽象：DataFrame和DataSet，并且作为分布式SQL查询引擎的作用。
```

SparkSQL可以和hive直接交互；hive底层基于MR，SparkSQL底层是RDD。



SparkSQL的三种弹性分布式数据集：RDD  Dataframe(弱类型，包含了结构信息)  Dataset(强类型，包含了结构信息和类型信息)。type DataFrame = Dataset[Row]，DataFrame是Dataset的特例，当类型为Row时即是DataFrame。

DataFrame有三种创建方式：通过Spark的数据源进行创建；从一个存在的RDD进行转换；还可以从Hive Table进行查询返回。
DataSet创建方式：var ds2 = List/Seq(emp(10,"wangwu")).toDS



sparkcontext读取json后，用JSON工具解析，每行JSON数据都会转换为Map中的kv对形式:

```scala 
    import scala.util.parsing.json.JSON
    val rdd: RDD[String] = sc.textFile("input/user.json")
    val jsonRDD: RDD[Option[Any]] = rdd.map {
      line => JSON.parseFull(line)
    }
输出：
Some(Map(name -> wangwu, age -> 22))
Some(Map(name -> zhangsan, age -> 22))
Some(Map(name -> lisi, age -> 22))
```

sparksession读取json后将其转变为Dataframe中的结构化数据。





	spark.newSession 创建一个新的会话，读取不到其他session中创建的非GlobalTempView表。如果需要读取global域的表，需要写全路径名，即global_temp.表名。

web中有四个作用域：application、session、request、page      如果指定域没找到，自动查找下面的作用域
session中有两个作用域：global、session        默认为session；如果查找global域（应用范围有效），需要指定



```shell
spark.sparkContext	//获取sc上下文
val df = spark.read.json/textFile（）	//读取文件
df.show	//展示数据

创建临时表进行查询：
df.createTempView/createOrReplaceTempView("表名")	//创建临时表
df.sql("查询语句")	//用sql语句查询临时表

df.printSchema	//打印当前DateFrame的结构信息

DSL风格语法（直接对df进行查询）：
df.select("字段名").show	//查询所选的字段
df.select($"name",$"age"+1).show()	//对查询结果计算后输出

df.filter($"age">20).show	//对查询结果进行过滤
df.groupBy("age").count().show()	//按指定字段分组，并统计每组的个数
```



dsl(domain-specific language)



	自定义聚合函数可以在sparkSQL中计算平均值。sparkSQL中有缓冲区（cache）存在，将所需的值放入缓冲区，最后进行计算。

	Dataframe，弱类型的UDAF函数，继承UserDefinedAggregateFunction。弱类型没有类型，只有顺序，根据顺序找属性。
	Dataset，强类型的UDAF函数，继承Aggregator。



rdd—(toDF(字段名称))—df—(as[泛型])—ds
ds—(toDF)—df—(rdd)—rdd
rdd(样例类对象)—(toDS)—ds
ds—(rdd)—rdd

```scala
object SparkSQL011 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("sql").setMaster("local[*]")
    val spark = SparkSession.builder().config(conf).getOrCreate()

    val sc: SparkContext = spark.sparkContext

    val rdd: RDD[(Int, String, Int)] = sc.makeRDD(List((1,"zhangsan",18),(2,"lisi",28)))

    //RDD转换为DF,DS时，需要增加隐式转换，需要引入spark环境对象的隐式转换规则
    import spark.implicits._
    //添加内部样例类,会报错。Why？？？
//    case class user(id:Int,name:String,age:Int)

    // TODO rdd转df
    val df: DataFrame = rdd.toDF("id","name","age")
    df.show()

    // TODO rdd转ds
    val objRDD: RDD[user] = rdd.map {
      case (id, name, age) => user(id, name, age)
    }
    objRDD.foreach(println)
    val ds: Dataset[user] = objRDD.toDS()
    ds.show()
    
    // TODO df转ds
    val ds2 = df.as[user] //类中的属性名和df中的属性名相同则匹配
    ds2.show()

    // TODO df转rdd
    val rdd2: RDD[Row] = df.rdd
    rdd2.foreach(println)
    rdd2.foreach{
      row =>
        println(row.get(0))
        println(row.getString(1))
        println(row.getInt(2))
    }

    // TODO ds转df
    val df2: DataFrame = ds.toDF()
    df2.show()

    // TODO ds转rdd
    val rdd1: RDD[user] = ds.rdd
    rdd1.foreach(println)
    
    sc.stop()
  }
}
case class user(id:Int,name:String,age:Int)
```



三种UDF函数：

```scala
object UDF {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("UDF").setMaster("local[*]")
    val spark: SparkSession = SparkSession.builder().config(conf).getOrCreate()

    import spark.implicits._

    val df: DataFrame = spark.read.json("input/user.json")

    df.createOrReplaceTempView("user")

    // TODO 方式一：注册UDF函数
    spark.udf.register("addName", (name: String) => "Name:" + name)
    spark.sql("select addName(name) from user").show()

    // TODO 方式二：新建弱类型的UDF类，在spark上下文对象中注册
    val myAgeAvg = new MyAgeAvg()
    spark.udf.register("myAgeAvg", myAgeAvg)

    spark.sql("select myAgeAvg(age) from user").show()

    // TODO 方式三：新建强类型的UDF类，将聚合函数转换为查询的列
    val myAgeAvgClass = new MyAgeAvgClass
    val myAgeAvgColumn: TypedColumn[User, Double] = myAgeAvgClass.toColumn.name("myAgeAvgClass")

    val ds: Dataset[User] = df.as[User] //ds的类和传入参数的类必须是同一个
    ds.select(myAgeAvgColumn).show()

    spark.stop()
  }
}

  // TODO 方式二的弱类型UDF类
class MyAgeAvg extends UserDefinedAggregateFunction {
  //函数的输入值类型
  override def inputSchema: StructType = {
    new StructType().add("age", LongType)
  }
  //缓冲区数据的结构类型
  override def bufferSchema: StructType = {
    new StructType().add("sum", LongType).add("count", LongType)
  }
  //函数的返回值类型
  override def dataType: DataType = DoubleType
  //函数的稳定性（即传入相同值，结果是否相同，是否为随机算法）
  override def deterministic: Boolean = true
    
  override def initialize(buffer: MutableAggregationBuffer): Unit = {
    buffer(0) = 0L
    buffer(1) = 0L
  }

  override def update(buffer: MutableAggregationBuffer, input: Row): Unit = {
    buffer(0) = buffer.getLong(0) + input.getLong(0)
    buffer(1) = buffer.getLong(1) + 1L
  }

  override def merge(buffer1: MutableAggregationBuffer, buffer2: Row): Unit = {
    buffer1(0) = buffer1.getLong(0) + buffer2.getLong(0)
    buffer1(1) = buffer1.getLong(1) + buffer2.getLong(1)
  }

  override def evaluate(buffer: Row): Any = ｛
    buffer.getLong(0).toDouble / buffer.getLong(1)
  ｝
}



  // TODO 方式三的强类型UDF类
case class User(name: String, age: Long)
case class Buffer(var sum: Long, var count: Long)

class MyAgeAvgClass extends Aggregator[User, Buffer, Double] {

  override def zero: Buffer = Buffer(0L, 0L)

  override def reduce(b: Buffer, age: User): Buffer = {
    b.sum = b.sum + age.age
    b.count = b.count + 1L
    b
  }

  override def merge(b1: Buffer, b2: Buffer): Buffer = {
    b1.sum = b1.sum + b2.sum
    b1.count = b1.count + b2.count
    b1
  }

  override def finish(reduction: Buffer): Double = {
    reduction.sum.toDouble / reduction.count
  }

  override def bufferEncoder: Encoder[Buffer] = Encoders.product

  override def outputEncoder: Encoder[Double] = Encoders.scalaDouble
}
```



9:13  静态导入一般用于导入类的静态方法和属性

列式存储用于统计分析，支持嵌套存储（可以存储集合），同时相同类型的数据保存在一起，便于压缩。



通用加载/保存方法

```scala
//不指定format格式，默认为parquet 
spark.read.format("json").load("路径") 或spark.read.json("路径")
//保存模式有append、overwrite、ignore三种，默认为error，即已存在相同文件则报错
df.write.format(“json”).mode("append").save("路径")	

spark.sql("show tables").show  //展示sparksession中的所有的表信息

直接运行在SQL文件上 
val sqlDF = spark.sql("SELECT * FROM parquet.`hdfs://hadoop102:9000/namesAndAges.parquet`")
```



读取/写入mysql中的数据

```scala
//TODO 读取数据
方式一：
val jdbcDF = spark.read
.format("jdbc")
.option("url", "jdbc:mysql://localhost:3306/rdd")
.option("dbtable", "rdd")
.option("user", "root")
.option("password", "abc123")
.load()
方式二：需要java.utils中的properties类的对象（一般用方式一）
val connectionProperties = new Properties()
connectionProperties.put("user", "root")
connectionProperties.put("password", "000000")
val jdbcDF2 = spark.read
.jdbc("jdbc:mysql://hadoop102:3306/rdd", "rddtable", connectionProperties)

//TODO 写入数据
方式一：
df.write
.format("jdbc")
.option("url", "jdbc:mysql://hadoop102:3306/rdd")
.option("dbtable", "rdd")
.option("user", "root")
.option("password", "abc123")
.mode("append")		//同样也有append、overwrite和ignore三种模式
.save()
方式二：同样需要properties对象，不方便
jdbcDF2.write
.jdbc("jdbc:mysql://hadoop102:3306/rdd", "db", connectionProperties)
```



	一般spark编译时已经添加了hive支持，在进入spark-shell是会自动生成hive的元数据库文件metastore_db。可以将hive-site.xml复制到spark的配置文件中（如果是idea则放置到classpath中），那么再次进入spark-shell，就会用外置的hive的元数据库。



bin/spark-sql可以很方便的通过spark查询外部hive的数据，也可以通过spark.sql和idea查询。

idea访问外部hive的元数据： 注意添加**enableHiveSupport()**

```scala
object Hive {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("hive").setMaster("local[*]")
    val spark: SparkSession = SparkSession.builder.config(conf).enableHiveSupport().getOrCreate()//添加enableHiveSupport
    import spark.implicits._

    spark.sql("show tables").show()

    spark.stop()
  }
}
```





idea中的classpath是target目录，所以在resources文件夹中放入配置文件等需要在target目录下存在才能生效。









为什么是doubletype，与double区别是什么？
Aggregator的编码器？
为什么样例类写在类中转换ds时会报错？
