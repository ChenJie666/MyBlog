---
title: Spark
categories:
- 大数据实时
---
六种实现wordCount方式

```scala
    //method0
	val rdd1: RDD[(String, Iterable[(String, Int)])] = rdd.groupBy {
      case (s, num) => s
    }
    val rdd2: RDD[(String, Int)] = rdd1.mapValues(datas => datas.map(_._2).sum)
    rdd2.collect.foreach(println)

	//method1
    rdd.groupByKey.map{
      case (s,datas) => (s,datas.sum)
    }.collect.foreach(println)

    //method2
    rdd.reduceByKey((x:Int,y:Int)=>x+y).collect.foreach(println)

    //method3
    rdd.aggregateByKey(0)((x:Int,y:Int)=>x+y,(x:Int,y:Int)=>x+y).collect.foreach(println)

    //method4
    rdd.foldByKey(0)((x:Int,y:Int)=>x+y).collect.foreach(println)

    //method5
    rdd.combineByKey((num:Int)=>num,(x:Int,y:Int)=>x+y,(x:Int,y:Int)=>x+y).collect.foreach(println)

    //method6
    rdd.flatMap{
      case (s:String,num:Int) =>
        val list = new ListBuffer[String]()
        for(elem <- 1 to num){
          list.append(s)
        }
      list
    }.groupBy((s:String)=>s).map{
      case (s,datas) => (s,datas.size)
    }.collect.foreach(println)

object Method7 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("wc").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[(String, Int)] = sc.parallelize(List(("a", 2), ("b", 3), ("c", 4), ("b", 5), ("a", 6)), 2)
    val rdd1: RDD[(String, Int)] = rdd.flatMap {
      case (s, num) =>
        val list = new ListBuffer[(String, Int)]()
        for (elem <- 1 to num) {
          list.append((s, 0))
        }
        list
    }
    val stringToLong: collection.Map[String, Long] = rdd1.countByKey()
    println(stringToLong)
  }
}
object Method8 {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("wc").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[(String, Int)] = sc.parallelize(List(("a", 2), ("b", 3), ("c", 4), ("b", 5), ("a", 6)), 2)
    val rdd1: RDD[String] = rdd.map {
      case (s, num) => (s + " ") * num
    }.flatMap {
      _.split(" ")
    }
    val stringToLong: collection.Map[String, Long] = rdd1.countByValue()
    println(stringToLong)
  }
}
```

foreachPartition		countByValue



RPC远程过程调用

RMI框架  => EJB => Spring



## Hadoop历史：

hadoop于2008年发布0.X版本，2011发布1.X版本，2013年10月发布了2.X版本（Yarn版本）。

1）1.X版本缺陷：①单节点问题，没有HA模式②硬件有上限③MR因为要落盘，不支持迭代操作④MR框架和资源管理耦合在一起，无法分离。

![11](F:/Typora/图片/11.PNG)

2）2.X版本改进：①实现HA②使用Yarn作为资源管理框架，MR只做任务调度与执行。将Yarn和MR解耦，实现计算框架的可插拔。通过中间层Container实现资源与计算的解耦。

![22](F:/Typora/图片/22.PNG)

Spark历史：

2013年6月发布，采用函数式编程方式，优化了MR框架，适合迭代式计算。Spark的框架和第一代的Hadoop框架相似，不考虑框架的可插拔，因为spark性能足够高，不需要替换。

![33](F:/Typora/图片/33.PNG)

现实中我们将hadoop的MR计算引擎替换为Spark来实现高效的计算：

![44](F:/Typora/图片/44.PNG)

内置模块：

![55](F:/Typora/图片/55.PNG)



早期通过JNDI，将应用程序与资源服务进行解耦合：

![77](F:/Typora/图片/77.PNG)

Driver：初始化上下文（sparkcontext），任务的切分和调度

Driver和Executor负责计算，RM和NM负责资源的调度。通过AppMaster进行通讯并完成两者的解耦。

![66](F:/Typora/图片/66.PNG)

	**spark执行任务的基本流程**①客户端将任务提交给Driver，Drivre向资源管理者注册应用程序，然后资源管理者启动Executor，Executor反向注册在Driver上；Driver初始化sparkContext上下文，将任务划分，并调度给各个Executor执行任务。将结果返回给Driver，关闭上下文，结束流程。

	yarn模式的spark执行任务基本流程：①客户端将App提交给RM，RM选择NM启动ApplicationMaster，在AM（用于解耦）中启动Driver，然后AM根据任务启动Executor，Driver创建sc并切分和调度任务给Executor，任务结束后AM从RM上注销。



	进入shell窗口，就会开启一个虚拟机，在输入指令前会处于阻塞状态，后台存在一个spark submit进程，可以在4040端口网页查看Driver的详情。退出shell窗口，则程序结束，虚拟机销毁。



	Spark的一个分布式数据集的分析框架，将计算单元缩小为更适合分布式计算和并行计算的模型，称之为RDD。



转换流是装饰者设计模式，RDD的原理和IO流基本类似：

 ![88](F:/Typora/图片/88.PNG)

![99](F:/Typora/图片/99.PNG)



	

## spark-core

RDD：弹性分布式数据集

	弹性：计算逻辑，血缘关系，分区

	分布式：分布式计算，数据的来源，数据目的地

	数据集：数据的类型&计算逻辑的封装（数据模型）

RDD：不可变、可分区、里面的元素可并行计算的集合

	不可变：计算逻辑不可变

	可分区：提高数据处理能力

	并行计算：多任务同时执行

算子：可以理解为方法和函数。



RDD中的方法：

```scala
protected def getPartitions: Array[Partition]	//返回多个分区
def compute(split: Partition, context: TaskContext): Iterator[T]	//计算每个分区的函数
protected def getDependencies: Seq[Dependency[_]] = deps	//获取依赖关系
val partitioner: Option[Partitioner] = None	//分区器，默认为none，因为只有k-v类型的RDD有分区器，会在pairRDD中重写partitionre方法，返回为some，通过key进行分区。
protected def getPreferredLocations(split: Partition): Seq[String] = Nil //每个分区的优先位置，优先将计算任务分配到和计算数据一个节点上。
```



读取文件的方式基于hadoop读取文件的方式，读取文件的数据是一行一行的字符串，源码如下：

```scala
def textFile(
      path: String,
      minPartitions: Int = defaultMinPartitions): RDD[String] = withScope {
    assertNotStopped()
    hadoopFile(path, classOf[TextInputFormat], classOf[LongWritable], classOf[Text],
      minPartitions).map(pair => pair._2.toString).setName(path)
  }
```

用makeRDD从内存中获取数组创建RDD时，可以传入的切片数量参数：

```scala
override def defaultParallelism(): Int =
  scheduler.conf.getInt("spark.default.parallelism", totalCores)//如果参数已经设置，则返回参数值，如果参数未设置，则返回totalCores。totalCores根据local或集群的拥有的核心数而定。

def getInt(key: String, defaultValue: Int): Int = {
  getOption(key).map(_.toInt).getOrElse(defaultValue)
}
```



数组的具体的切片规则：

```scala
def positions(length: Long, numSlices: Int): Iterator[(Int, Int)] = {
  (0 until numSlices).iterator.map { i =>
    val start = ((i * length) / numSlices).toInt
    val end = (((i + 1) * length) / numSlices).toInt
	(start, end)
  }
}
```

文件的切片规则：9:20,

```scala
def textFile(
      path: String,
      minPartitions: Int = defaultMinPartitions): RDD[String] = withScope {
    assertNotStopped()
    hadoopFile(path, classOf[TextInputFormat], classOf[LongWritable], classOf[Text],
      minPartitions).map(pair => pair._2.toString).setName(path)
  }

def defaultMinPartitions: Int = math.min(defaultParallelism, 2)//defaultParalelism值与数组的切片默认值相同，与配置参数或totalcores有关，min方法取最小值，一般返回2。

	/*实际读取时底层会调用hadoop的FileInputFormat类的getSplits方法进行切片。先统计所有文件的大小，然后除以切片数，获得目标切片的大小，因为可能除不尽，所以多余的部分再划一个切片。因此指定的参数是最小切片数，实际可能要大。
	读取行时，行末有cr和lf两个字符，写入时行末只有lf字符。对文档中的1,2,3切片，分区行号为（0-2,3-5,6），将1、2行放到分片一，3、4、5行放到分片二，6行放到分片三，最终得到1，2一个分片，3一个分片，还有一个空分片。需要注意切片有1.1的系数，如果最后一个切片很小，则不切。视频见spark-77*/
```



从内存创建RDD：sc.makeRDD/parallelize

从磁盘创建RDD：sc.textFile()

从RDD转换RDD：所有算子的逻辑计算操作都是发送给Executor执行的

new JdbcRDD（）直接创建RDD

newAPIHadoopRDD



	mapPartitions可能会出现OOM，因为map处理时可以将已经用完的数据GC，而mapPartitions所有数据以iterator进行传输，是一个整体，不能对部分进行GC。在OOM前一定会请求Full GC。

![111](F:/Typora/图片/111.PNG)



	mapPartitions只能返回可迭代的数组，所以不能实现取各分区最大值、平均值等功能；而glom可以实现。





sample方法（）

抽取不放回：false，fraction：抽取的概率

抽取放回：true，fraction：抽取的次数

随机数种子   new Random(1000)	1000就是随机数种子，随机数算法读取上一个数的值进行计算，如果随机数种子相等，那么之后计算出来的数也都相等。

打分：随机数种子会根据随机数算法给数字打分，然后小于概率的数取出，大于概率的数忽略。





shuffle：将数据打乱重组的过程。打乱重组的过程一定会写磁盘。shuffleWrite和shuffleRead进行磁盘写和读。



rddToPairRDDFunctions

K-V类型的算子的源码都不在RDD中，通过隐式转换在PariRDDFunctions源码中查找。RDD中的partitioner



//极限情况下向hashmap中放入11个数据会变成红黑树。



groupBy的区别是，groupBy可以自定义分区，而groupByKey只能通过key来分区。

reduceByKey和foldByKey的区别是foldByKey可以带入一个外来值。



**八种实现wordCount的方法：**

groupby

groupByKey和map

reduceByKey

aggregateByKey

foldByKey

combineByKey

countByKey

countByValue



会进行shuffle的算子：groupBy、repartition、groupByKey、reduceByKey、aggregateByKey、combineByKey、



	reduceByKey和aggregateByKey在shuffle前会进行combine预聚合减少数据量，而groupByKey没有预聚合。reduceByKey在分区内和分区间的计算逻辑完全相同。

	aggregateByKey使用了函数柯里化，第一个参数列表中是分区内计算的初始值，第二个参数列表中：第一个参数表示分区内计算规则，第二个参数表示分区间计算规则。

	foldByKey就是aggregateByKey简化版，当aggregateByKey中分区内和分区间的计算规则一样时使用。

	combineByKey需要传递三个参数	1.将第一个key出现的v转换结构的计算规则	2.第二个参数表示分区内计算规则	3.第三个参数表示分区间计算规则

## 算子和分区器

```scala
//value型
object MapPartitions {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[Int] = sc.makeRDD(List(1, 2, 3, 4, 5), 2)

    val rdd2: RDD[Int] = rdd.mapPartitions {
      datas => datas.map(_.*(2))
    }

    //    val rdd2: RDD[Int] = rdd.mapPartitions {
    //      datas => Iterator(datas.sum)
    //    }

    rdd2.foreach(println)

    sc.stop()
  }
}

object MapPartitionsWithIndex {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[Int] = sc.makeRDD(List(1, 2, 3, 4, 5), 2)
    val rdd2: RDD[(Int, Int)] = rdd.mapPartitionsWithIndex {
      case (index, datas) =>
        println("**************")
        datas.map((index, _))
    }

    rdd2.collect().foreach(println)
    sc.stop()
  }
}

object Glom {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    //    val rdd: RDD[(String, Int)] = sc.makeRDD(List(("a",1),("b",2),("c",4),("a",5)),2)
    //    val arrayRDD: RDD[Array[(String, Int)]] = rdd.glom()
    //    arrayRDD.collect.foreach{
    ////      println("****************")
    //      _.foreach{
    //        println("****************")
    //        println}
    //    }

    val rdd: RDD[Int] = sc.makeRDD(List(1, 2, 4, 5), 2)
    val arrayRDD: RDD[Array[Int]] = rdd.glom()
    arrayRDD.collect.foreach {
      println("****************")
      datas =>
        //            println("****************")
        datas.foreach {
          //        println("****************")
          println
        }
    }
    sc.stop()

  }
}

object GroupBy {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[(String, Int)] = sc.makeRDD(List(("a", 1), ("b", 2), ("c", 4), ("a", 5)), 2)

    val rdd2: RDD[(String, Iterable[(String, Int)])] = rdd.groupBy {
      case (c, i) => c
    }
    rdd2.foreach(println)
    sc.stop()
  }
}

object Filter {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[(String, Int)] = sc.makeRDD(List(("a", 1), ("b", 2), ("c", 4), ("a", 5)), 2)
    val rdd1: RDD[(String, Int)] = rdd.filter {
      case (c, i) => "c".equals(c)
    }
    rdd1.foreach(println)
    sc.stop()
  }
}

object Sample {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[Int] = sc.makeRDD(1.to(10), 2)

    val rdd2: RDD[Int] = rdd.sample(false, 0.5) //随机数种子会根据随机数算法给数字打分，然后小于概率的数取出，大于概率的数忽略。
    rdd2.collect().foreach(println)


    val rdd3: RDD[Int] = rdd.sample(true, 2, 20) //同一个数据可能被抽取的次数，可以用于解决HBase的热点问题
    rdd3.collect.foreach(println)
    sc.stop()
  }
}

object Distinct {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[Int] = sc.makeRDD(List(1, 2, 2, 4, 4), 5)

    rdd.distinct(10).collect.foreach(println)
    sc.stop()
  }
}

object Coalesce {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[Int] = sc.makeRDD(List(1, 2, 4, 3, 8, 10, 5, 7, 3, 5, 7, 9), 3)
    val rdd2: RDD[Int] = rdd.filter(_ % 2 == 1)
    val rdd3: RDD[Int] = rdd2.coalesce(2, true) //shuffle默认为false，单纯合并两个分区；shuffle设为true，重新洗牌
    rdd3.glom().collect().foreach { datas =>
      println("*****************")
      datas.foreach(println)
    }
    sc.stop()
  }
}

object Repartition {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[Int] = sc.makeRDD(List(1, 2, 4, 3, 8, 10, 5, 7, 3, 5, 7, 9), 3)
    val rdd1: RDD[Int] = rdd.filter(_ % 2 == 1)
    val rdd2: RDD[Int] = rdd1.repartition(2) //底层调用coalesce方法
    rdd2.glom().collect.foreach { datas =>
      println("***************")
      datas.foreach(println)
    }
    sc.stop()
  }
}

object SortBy {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[(String, Int)] = sc.makeRDD(List(("b", 1), ("a", 2), ("c", 4), ("a", 5)), 2)
    val rdd1: RDD[(String, Int)] = rdd.sortBy {
      case (s, i) => s
    }
    rdd1.collect.foreach(println)
    sc.stop()
  }
}

//pipe(脚本路径)  将每个分区的数据用脚本处理

//双value交互型
object UnionAndSubtractAndIntersection {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[Int] = sc.makeRDD(List(1, 2, 3, 4))
    val rdd1: RDD[Int] = sc.makeRDD(List(3, 4, 5, 6))

    val rdd2: RDD[Int] = rdd.union(rdd1) //全集，相当于union all
    rdd2.collect.foreach(println)

    val rdd3: RDD[Int] = rdd.subtract(rdd1) //差集
    rdd3.collect.foreach(println)

    val rdd4: RDD[Int] = rdd.intersection(rdd1) //交集
    rdd4.collect.foreach(println)

    val rdd5: RDD[(Int, Int)] = rdd.cartesian(rdd1) //求笛卡尔积
    rdd5.collect.foreach(println)

    val rdd6: RDD[(Int, Int)] = rdd.zip(rdd1) //拉链，但是数据个数或分区数不一致会抛异常
    rdd6.collect.foreach(println)

    sc.stop()
  }
}

//key-value类型
object PartitionBy {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[(String, Int)] = sc.makeRDD(List(("b", 1), ("a", 2), ("c", 4), ("a", 5)), 2)

    //Spark中默认的分区器为HashPartitioner
    val rdd1: RDD[(String, Int)] = rdd.partitionBy(new org.apache.spark.HashPartitioner(2))
    //RDD类中没有partitionBy，通过RDD伴生对象中的隐式转换类转换成rddToPairRDDFunctions对象，转换前提是k-v对
    val rdd2: RDD[(Int, (String, Int))] = rdd1.mapPartitionsWithIndex {
      case (index, datas) => datas.map(t => (index, (t._1, t._2)))
    }
    rdd2.collect.foreach(println)

    //可以自定义类继承Partitioner，实现numPartition和getPartition方法
    val rdd3: RDD[(String, Int)] = rdd.partitionBy(new MyPartitioner(2))
    val rdd4: RDD[(Int, (String, Int))] = rdd3.mapPartitionsWithIndex {
      case (index, datas) => datas.map(t => (index, (t._1, t._2)))
    }
    rdd4.collect.foreach(println)
    sc.stop()
  }
}

//自定义分区器
class MyPartitioner(num: Int) extends Partitioner {
  override def numPartitions: Int = num

  override def getPartition(key: Any): Int = 1
}

object GroupByKey { //与groupBy的区别是，groupBy可以自定义分区，而groupByKey只能通过key来分区
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[(String, Int)] = sc.makeRDD(List(("b", 1), ("a", 2), ("c", 4), ("a", 5)), 2)
    val rdd1: RDD[(String, Iterable[Int])] = rdd.groupByKey()
    val rdd2: RDD[(String, Int)] = rdd1.map {
      case (s, datas) => (s, datas.sum)
    }
    rdd2.collect.foreach(println)
    sc.stop()
  }
}

object ReduceByKey {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[(String, Int)] = sc.makeRDD(List(("b", 1), ("a", 2), ("c", 4), ("a", 5)), 2)
    val rdd1: RDD[(String, Int)] = rdd.reduceByKey(_ + _) //相较groupBy操作，会在区内进行combine预聚合,更加需求选择合适的
    rdd1.collect.foreach(println)
    sc.stop()
  }
}

object AggregateByKey { //分区内和分区间的计算逻辑不同，用该算子
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[(String, Int)] = sc.makeRDD(List(("b", 1), ("a", 2), ("c", 4), ("a", 5)), 2)
    val rdd1: RDD[(String, Int)] = rdd.aggregateByKey(0)(Math.max(_, _), _ + _) //第一个参数是初始值，第二个参数是分区内和分区间的计算逻辑
    rdd1.collect.foreach(println)

    sc.stop()
  }
}

object FoldByKey { //如果aggregateByKey的分区内和分区间的计算逻辑相同，可以用foldByKey
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[(String, Int)] = sc.makeRDD(List(("b", 1), ("a", 2), ("c", 4), ("a", 5)), 2)
    val rdd1: RDD[(String, Int)] = rdd.foldByKey(0)(_ + _)
    rdd1.collect.foreach(println)
  }
}

object CombineByKey {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("mp").setMaster("local[*]")
    val sc = new SparkContext(conf)
    //求相同key的平均值
    val rdd: RDD[(String, Int)] = sc.makeRDD(List(("b", 1), ("a", 2), ("c", 4), ("a", 5)), 2)
    val rdd1: RDD[(String, (Int, Int))] = rdd.combineByKey[(Int,Int)]((num:Int) => (num, 1), (t:(Int,Int), num1:Int) => (t._1 + num1, t._2 + 1), (t1:(Int,Int), t2:(Int,Int)) => (t1._1 + t2._1, t1._2 + t2._2))
    rdd1.collect.foreach{
      case (s,t) => println((s,t._1*1.0/t._2))
    }
  }
}
```

join算子效率不高。



aggregate（）算子中的零值在分区内可以使用，在分区间计算也会使用。



saveAsObjectFile是序列化到磁盘上

saveAsSequenceFile需要k-v对数据才能保存到磁盘上



countByValue（）将数据作为值，进行计数



rdd.collect()会将executor执行后返回的结果放入到数组中；rdd.foreach会将计算逻辑发送给executor，由executor执行。



序列化形成字节码才能网络传输。

算子外的代码在Driver端执行，算子内的代码在Executor中执行。所以执行任务时需要注意传输的信息是否可序列化，如果不能序列化则会抛异常。

14:51  网络传输

spark在执行作业之前，会先进行闭包（closure）检测，同时检查闭包的变量是否可以序列化用于网络传输。



**源码:视频69**

toDebugString：查看rdd的血缘关系

```
(2) MapPartitionsRDD[2] at mapPartitionsWithIndex at AggregateByKey.scala:20 []
 |  ShuffledRDD[1] at aggregateByKey at AggregateByKey.scala:14 []
 +-(2) ParallelCollectionRDD[0] at parallelize at AggregateByKey.scala:11 []
```

	继承了NarrowDependency的就是窄依赖，如MapPartitionsRDD最终会继承RDD(oneParent.context, List(new OneToOneDependency(oneParent))),所以窄依赖的rdd调用getDependencies方法，会调用父类的方法，返回其上一个RDD的对象。OneToOneDependency类是NarrowDependency的子类，所以称为窄依赖。
	通过makeRDD等方法创建的rdd是ParallelCollectionRDD类型的，rdd.getDependencies会返回Nil空集合。
	所有的会进行shuffle的算子最终会返回ShuffleRDD类对象，拥有自己的getDependencies方法，返回一个集合，集合中只有一个ShuffleDependency对象。



	shuffleRDD就是宽依赖

![222](F:/Typora/图片/222.PNG)



persist/cache作用：①提高容错率②提升效率

	缓存会保存到血缘关系中，如果有血缘关系，直接调用缓存；但是不会切断前面的血缘关系，因为缓存可能丢失，丢失后重新根据血缘进行查找。血缘关系保存在RDD中。



## 源码解析

**源码:视频62**

**App->job:**Application任务会根据行动算子产生对应的job，如行动算子collect（），会将rdd作为参数调用sc.runJob方法，最终在DAGScheduler类中调用submitJob方法提交rdd。在handleJobSubmitted方法中生成ResultStage对象并作为参数创建一个ActiveJob作业对象。所以一个作业中包含多个stage。

**源码:视频71、72**

**job->stage:**在handleJobSubmitted方法中，通过血缘获取shuffleDep类的算子并生成对应的stage，将stage放入数组中作为参数创建ResultStage，并作为参数创建ActiveJob对象，所以一个job中包含了多个stage。调用submitStage方法

```scala
ResultStage和ShuffleMapStage
源码：
private[scheduler] def handleJobSubmitted(jobId: Int,
    finalRDD: RDD[_],
    func: (TaskContext, Iterator[_]) => _,
    partitions: Array[Int],
    callSite: CallSite,
    listener: JobListener,
    properties: Properties) {
  var finalStage: ResultStage = null
  try {
    // New stage creation may throw an exception if, for example, jobs are run on a
    // HadoopRDD whose underlying HDFS files have been deleted.
    finalStage = createResultStage(finalRDD, func, partitions, jobId, callSite)
  } catch {
    case e: Exception =>
      logWarning("Creating new stage failed due to exception - job: " + jobId, e)
      listener.jobFailed(e)
      return
  }
  val job = new ActiveJob(jobId, finalStage, callSite, listener, properties)
  ........
  submitStage(finalStage)	//将ResultStage作为参数调用submitStage方法
}
    
//通过createResultStage方法完成stage的切分并作为参数创建ActiveJob对象。
  private def createResultStage(
      rdd: RDD[_],
      func: (TaskContext, Iterator[_]) => _,
      partitions: Array[Int],
      jobId: Int,
      callSite: CallSite): ResultStage = {
    val parents = getOrCreateParentStages(rdd, jobId)//查找当前的rdd的血缘，返回HashSet数组
    val id = nextStageId.getAndIncrement()
    val stage = new ResultStage(id, rdd, func, partitions, parents, jobId, callSite)//将所有的stage包含在ResultStage对象中。
    stageIdToStage(id) = stage
    updateJobIdStageIdMaps(jobId, stage)
    stage
  }
  
  //查找血缘中shuffleDep类，并且每个shuffle都创建并返回包含所有stage的集合
  private def getOrCreateParentStages(rdd: RDD[_], firstJobId: Int): List[Stage] = {
    getShuffleDependencies(rdd).map { shuffleDep =>
      getOrCreateShuffleMapStage(shuffleDep, firstJobId)//getOrCreateShuffleMapStage方法返回了createShuffleMapStage对象，相当于每个shuffle创建了一个阶段。
    }.toList
  }
    
  //getShuffleDependencies方法查找shuffleDep类型的依赖加入到parents中并返回，交给map方法遍历
  private[scheduler] def getShuffleDependencies(
      rdd: RDD[_]): HashSet[ShuffleDependency[_, _, _]] = {
    val parents = new HashSet[ShuffleDependency[_, _, _]]
    val visited = new HashSet[RDD[_]]
    val waitingForVisit = new Stack[RDD[_]]
    waitingForVisit.push(rdd)
    while (waitingForVisit.nonEmpty) {
      val toVisit = waitingForVisit.pop()
      if (!visited(toVisit)) {
        visited += toVisit
        toVisit.dependencies.foreach {
          case shuffleDep: ShuffleDependency[_, _, _] =>
            parents += shuffleDep//将shuffleDep类型的血缘加入到parents中
          case dependency =>
            waitingForVisit.push(dependency.rdd)
        }
      }
    }
    parents
  }

```

stage->task：疑问？？？？？？？？？？？？？？？？？？？？？？？ 怎么从前往后提交的？？？？？？

```scala
通过递归从后往前遍历ResultStage中的stage，从前往后提交stage
private def submitStage(stage: Stage) {
  val jobId = activeJobForStage(stage)
  if (jobId.isDefined) {
    logDebug("submitStage(" + stage + ")")
    if (!waitingStages(stage) && !runningStages(stage) && !failedStages(stage)) {
      val missing = getMissingParentStages(stage).sortBy(_.id)//查找ResultStage的上一级
      logDebug("missing: " + missing)
      if (missing.isEmpty) {
        logInfo("Submitting " + stage + " (" + stage.rdd + "), which has no missing parents")
        submitMissingTasks(stage, jobId.get)//没有上一级则提交任务
      } else {
        for (parent <- missing) {
          submitStage(parent)//有上一级则递归调用此方法，直到递归边界，即第一个stage。
        }
        waitingStages += stage
      }
    }
  } else {
    abortStage(stage, "No active job for stage " + stage.id, None)
  }
}

提交没有上级stage的任务（对单个stage进行处理）
private def submitMissingTasks(stage: Stage, jobId: Int) {
    logDebug("submitMissingTasks(" + stage + ")")
   	 val tasks: Seq[Task[_]] = try {
          stage match {
            case stage: ShuffleMapStage =>
              partitionsToCompute.map { id =>	//如果是ShuffleMapStage，则计算分区
                val locs = taskIdToLocations(id)
                val part = stage.rdd.partitions(id)
                new ShuffleMapTask(stage.id, stage.latestInfo.attemptId,//每个分区一个Task
                  taskBinary, part, locs, stage.latestInfo.taskMetrics, properties, Option(jobId),
                  Option(sc.applicationId), sc.applicationAttemptId)
              }

            case stage: ResultStage =>
              partitionsToCompute.map { id =>	//如果是ResultStage，则计算分区
                val p: Int = stage.partitions(id)
                val part = stage.rdd.partitions(p)
                val locs = taskIdToLocations(id)
                new ResultTask(stage.id, stage.latestInfo.attemptId,//每个分区生成一个Task
                  taskBinary, part, locs, id, properties, stage.latestInfo.taskMetrics,
                  Option(jobId), Option(sc.applicationId), sc.applicationAttemptId)
             }
     }
     if (tasks.size > 0) {
          logInfo("Submitting " + tasks.size + " missing tasks from " + stage + " (" + stage.rdd + ")")
          stage.pendingPartitions ++= tasks.map(_.partitionId)
          logDebug("New pending partitions: " + stage.pendingPartitions)
          taskScheduler.submitTasks(new TaskSet(
            tasks.toArray, stage.id, stage.latestInfo.attemptId, jobId, properties))//将得到的tasks放入TaskSet集合中，一个stage对应一个TaskSet
          stage.latestInfo.submissionTime = Some(clock.getTimeMillis())
    }
         
 调用submitTasks方法后，会调用backend.reviveOffers()方法，reviveOffers（），ReviveOffers，最后调用executor.launchTask方法，启动线程池threadPool.execute，将TaskRunner对象作为参数，所以该对象中有run方法。在launchTask时会调用task.serializedTask序列化方法和ser.serialize方法进行序列化，之后调用task.run方法开启。见视频87

```

任务的传递：视频88

```scala
Driver发送任务： 
private def launchTasks(tasks: Seq[Seq[TaskDescription]]) {
      for (task <- tasks.flatten) {
        val serializedTask = ser.serialize(task)//序列化任务
      ...
      }
   executorData.executorEndpoint.send(LaunchTask(new SerializableBuffer(serializedTask)))
   //Driver端启动序列化，将序列化的任务发送给executor
 }
Executor接收任务
override def receive: PartialFunction[Any, Unit] = {
    case LaunchTask(data) =>
      if (executor == null) {
        exitExecutor(1, "Received LaunchTask command but executor was null")
      } else {
        val taskDesc = ser.deserialize[TaskDescription](data.value)//进行反序列化
        logInfo("Got assigned task " + taskDesc.taskId)
        executor.launchTask(this, taskId = taskDesc.taskId, attemptNumber = taskDesc.attemptNumber,//executor（计算对象）启动任务
          taskDesc.name, taskDesc.serializedTask)
      }

```



堆外内存是jvm外的内存，由OS管理，需要自己控制分配和释放（spark封装了对外内存的控制和释放功能）。



**cms（面向单核）和G1（面向多核）以及jvm面试重点。HBase面试重点，rowkey设计，分区原理！线程池，preparedstatement与。。的区别  等相关问题。**

```
带有不同参数的同一SQL语句被多次执行的时候。PreparedStatement对象允许数据库预编译SQL语句
1.PreparedStatement是预编译的,对于批量处理可以大大提高效率.也叫JDBC存储过程

3.statement每次执行sql语句，相关数据库都要执行sql语句的编译，preparedstatement是预编译得,preparedstatement支持批处理

1.在Web环境中，有恶意的用户会利用那些设计不完善的、不能正确处理字符串的应用程序。特别是在公共Web站点上,在没有首先通过PreparedStatement对象处理的情况下，所有的用户输入都不应该传递给SQL语句。此外，在用户有机会修改SQL语句的地方，如HTML的隐藏区域或一个查询字符串上，SQL语句都不应该被显示出来。
2.在执行SQL命令时，我们有二种选择：可以使用PreparedStatement对象，也可以使用Statement对象。无论多少次地使用同一个SQL命令，PreparedStatement都只对它解析和编译一次。当使用Statement对象时，每次执行一个SQL命令时，都会对它进行解析和编译。

```



	checkpoint检查点保存时间:在执行行动算子时，才会进行checkpoint操作。因为RDD没有做缓存，所以需要重新计算RDD，然后写出到磁盘。因此可以在checkpoint的点上先进行persist/cache。

	spark的checkpoint可以切断血缘关系，一般存储在hdfs上，原则上是不会丢失的；而persist/cache不会切断血缘。



	groupBy（）底层也是调用groupByKey（），将groupBy的值通过函数处理后作为key转换为对偶元组，再调用groupByKey（）。



	HashPartitioner分区器用到比较多，因为RangePartitioner耦合性太强，对数据源有要求，需要数据可以比较。



9:52  spark切片会调用hadoop的getSplit方法，也有1.1倍数。

9:56行号



10:25   json①传输数据小②JavaScript是函数式语言，json可以在js中直接使用③mysql从7.0开始支持json存储

```scala
spark读取json格式的数据解析并存储为Map数组，并封装到Some类的对象中（一般用sparkSQL读取json文件）
object MysqlAndHBase {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("xxx").setMaster("local[*]")
    val sc = new SparkContext(conf)

    import scala.util.parsing.json.JSON//导入scala的json解析包

    val rdd = sc.textFile("input/user.json")

    val rdd1: RDD[Option[Any]] = rdd.map(JSON.parseFull)
    rdd1.collect.foreach(println)
      
    sc.stop()
  }
}

```

获取mysql中的数据和将数据写入mysql

```scala
获取mysql数据
object MySQL {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("xxx").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val driver = "com.mysql.jdbc.Driver"
    val url = "jdbc:mysql://hadoop102:3306/rdd"
    val username = "root"
    val password = "abc123"

    val jdbcRDD = new JdbcRDD(
      sc,
      () => {
        Class.forName(driver)
        val connection: Connection = DriverManager.getConnection(url, username, password)
        connection
      },
      "select * from rdd where i >= ? and i <= ?",
      1,
      3,
      3,
      resultSet => {println("***");println(resultSet.getInt(1) + "," + resultSet.getString(2) + "," + resultSet.getInt(3))}
    )
    jdbcRDD.collect()

    sc.stop()
  }
}

写入mysql
object MySQLWrite {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("xxx").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val driver = "com.mysql.jdbc.Driver"
    val url = "jdbc:mysql://hadoop102:3306/rdd"
    val username = "root"
    val password = "abc123"

    val rdd: RDD[(String, Int)] = sc.makeRDD(List(("six",16),("six",15)))
    //每个元素都遍历会导致创建大量的连接导致数据库崩溃，而连接类都不支持序列化；所以有以下优化
/*    rdd.foreach{
      case (name,age) => {
        Class.forName(driver)
        val connection: Connection = DriverManager.getConnection(url,username,password)
        var sql = "insert into rdd(name,age) value(?,?)"
        val statement: PreparedStatement = connection.prepareStatement(sql)
        statement.setObject(1,name)
        statement.setObject(2,age)
        statement.executeUpdate()

        statement.close()
        connection.close()
      }
*/
    //优化：将每个分区的数据作为整体发到executor，每个executor创建一个连接，连接数最少。
    rdd.foreachPartition{
      case partition => {
        Class.forName(driver)
        val connection: Connection = DriverManager.getConnection(url,username,password)
        var sql = "insert into rdd(name,age) value(?,?)"
        val statement: PreparedStatement = connection.prepareStatement(sql)

        partition.foreach{
          case (name,age) => {
            statement.setObject(1,name)
            statement.setObject(2,age)
            statement.executeUpdate()
          }
        }
        statement.close()
        connection.close()
      }
    }

    sc.stop()
  }
}

addbatch将一组参数添加到此 PreparedStatement.executeBatch方法批处理命令。

```

从HBase中读取和写入数据：

```scala
object HBaseReader {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("xxx").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val configuration: Configuration = HBaseConfiguration.create()//创建HBase配置类对象，对象中会加入类加载器，加载配置文件等信息。所以需要将HBase-site.xml文件放在加载路径上。
    configuration.set(TableInputFormat.INPUT_TABLE,"fruit")	//指定读取的hbase表

    val rdd: RDD[(ImmutableBytesWritable, Result)] = sc.newAPIHadoopRDD(//通过此类读取HBase
      configuration,				//传入参数配置，
      classOf[TableInputFormat],	//指定表的输入类型
      classOf[ImmutableBytesWritable],//指定rowkey的类型
      classOf[Result]				//指定value的类型
    )
    rdd.foreach{
      case (rowkey,result) => {	//获取的rdd是（rowkey，result）类型
        for(cell <- result.rawCells()){
          println(Bytes.toString(CellUtil.cloneRow(cell)) + "," + Bytes.toString(CellUtil.cloneValue(cell)))
        }
      }
    }
    sc.stop()
  }
}

object HBaseWrite {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("xxx").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val configuration: Configuration = HBaseConfiguration.create()

    val rdd: RDD[(String,String, String)] = sc.makeRDD(List(("1005","name","mango"),("1005","color","yellow")))

    val putRDD: RDD[(ImmutableBytesWritable, Put)] = rdd.map {//转化为规定的格式
      case (id,color, name) => {
        val rowkey = Bytes.toBytes(id)
        val put = new Put(rowkey)
        put.addColumn(Bytes.toBytes("info"), Bytes.toBytes(color), Bytes.toBytes(name))//获取put对象，并加入需要的加入的value信息
        (new ImmutableBytesWritable(rowkey), put)//转化为规定的格式类型
      }
    }

    val jobConf = new JobConf(configuration)	//新建一个带有HBase信息的配置文件
    jobConf.setOutputFormat(classOf[TableOutputFormat])//设置输出表格式类型
    jobConf.set(TableOutputFormat.OUTPUT_TABLE,"fruit")//设置输出到哪个表

    putRDD.saveAsHadoopDataset(jobConf)//此方法只支持k-v类型的rdd，所以除了put，还要写上rowkey

    sc.stop()
  }
}

//创建Hbase表
  val admin = new HBaseAdmin(conf)
  if (admin.tableExists(fruitTable)) {
    admin.disableTable(fruitTable)
    admin.deleteTable(fruitTable)
  }
  admin.createTable(tableDescr)

```





foreachPartition算子以分区为单位。但是也可能出现OOM。

tableInputFormat、ImmutableBytesWritable--Result  11:39



ajex需要有回调函数，在请求相应后执行。JdbcRDD中的参数中也有回调函数。



spark三大数据结构：

	RDD： 弹性分布式数据集

	累加器：分布式共享只写数据（只有Driver端能读到全部数据），如果执行多次行动算子，会出现多加的情况（可以用cache）；如果不执行行动算子，那么不会触发累加器

	广播变量：分布式共享只读数据（将数据发往executor，所有task从executor中获取数据,减少了数据冗余，加快数据获取。val breadcast = sc.broadcast（List（））生成广播数据对象，broadcast.value获取数据）

```scala
spark自带的累加器LongAccumulator
object Accumulator {
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("xxx").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val rdd: RDD[Int] = sc.makeRDD(List(1,2,3,4,5))
    val accumulator = sc.longAccumulator("acc")
    rdd.foreach{
      num => accumulator.add(num)
    }

    println(accumulator.value)

    sc.stop()
  }
}

自定义累加器（继承AccumulatorV2类，并6个重写方法）
object MyAccumulator{
  def main(args: Array[String]): Unit = {
    val conf: SparkConf = new SparkConf().setAppName("xxx").setMaster("local[*]")
    val sc = new SparkContext(conf)

    val accumulator = new BlackListAccumulator
    sc.register(accumulator,"acc")	//注册累加器

    val rdd: RDD[String] = sc.makeRDD(List("hive","hadoop","scale","spark"))
    rdd.foreach{
      word => accumulator.add(word)//会对accumulator进行闭包检测，调用writeReplace方法
    }

    println(accumulator.value)

    sc.stop()
  }
}
class BlackListAccumulator extends AccumulatorV2[String, java.util.HashSet[String]]{

  private val set = new util.HashSet[String]()

  override def isZero: Boolean = set.isEmpty//判断累加器是否为空，不为空则抛异常

  override def copy(): AccumulatorV2[String, util.HashSet[String]] = new BlackListAccumulator		//新建累加器，执行reset和isZero方法，之后发往executor

  override def reset(): Unit = set.clear()	//将新建的累加器清空，然后调用isZero方法

  override def add(v: String): Unit = if(v.contains("h")) set.add(v)

  override def merge(other: AccumulatorV2[String, util.HashSet[String]]): Unit = set.addAll(other.value)	//在Driver归并

  override def value: util.HashSet[String] = set	//获取结果
}

```

	**闭包检测的源码见视频86**：底层在系列化对象时（闭包检测时），会调用AccumylatorV2类中的writeReplace方法。clean是闭包检测的方法，通过反射获取函数（函数最终会变成类）的类名，判断类名是否包含$anonfun$字段检测该类是否闭包；如果闭包，则checkSerializable方法检查是否可以序列化；最后在java的IO类的writeObject0方法中调用writeReplace方法。

	kafkaProducer包含Sender对象，Sender类包含RecordAccumulator类属性对象，RecordAccumulator类包含Deque(双端队列）类属性对象.



自定义分区需要继承Partitioner类，重写numPartitions和getPartition方法。

Spark中读取的json文件是一行一个json对象，与普通的json对象不同。因为Spark按行读取文件。





tasknotserializable



11:37？？ 任务是在stage中划分的，一个stage根据分区划分对应数量的task；所以只有shuffle会产生新的stage，才会生成新的task。

	

	一个节点可以对应多个executor，一个executor可以有多个core，一个core可以执行一个task。

	一般task任务数量是核心数量的2~3倍最好，因为有数据本地化原则，将任务分配到数据所在的节点，移动数据不如移动任务。

![333](F:/Typora/图片/333.PNG)





管理项目打包方式是pom，子项目打包方式是jar

jackson		gson



在对数据进行累加的情况下，用累加器可以不用进行shuffle，提高了效率。累加器只有在执行行动算子时，才会执行。所以要避免出现没有执行行动算子，拿不到值的情况，也要避免多次使用行动算子，导致累加器重复执行，数据重复的问题。可以在累加器之后执行persist/cache进行缓存，这样就不会重复执行累加器。



10:32为什么不重载，scala支持多态么？
