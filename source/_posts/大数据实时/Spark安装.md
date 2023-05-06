---
title: Spark安装
categories:
- 大数据实时
---
Local模式
安装使用
1）上传并解压spark安装包
[atguigu@hadoop102 sorfware]$ tar -zxvf spark-2.1.1-bin-hadoop2.7.tgz -C /opt/module/
[atguigu@hadoop102 module]$ mv spark-2.1.1-bin-hadoop2.7 spark
2）官方求PI案例
[atguigu@hadoop102 spark]$ bin/spark-submit \
--class org.apache.spark.examples.SparkPi \
--executor-memory 1G \
--total-executor-cores 2 \
./examples/jars/spark-examples_2.11-2.1.1.jar \
100
（1）基本语法
bin/spark-submit \
--class <main-class>
--master <master-url> \
--deploy-mode <deploy-mode> \
--conf <key>=<value> \
... # other options
<application-jar> \
[application-arguments]
（2）参数说明：
--master 指定Master的地址，默认为Local
--class: 你的应用的启动类 (如 org.apache.spark.examples.SparkPi)
--deploy-mode: 是否发布你的驱动到worker节点(cluster) 或者作为一个本地客户端 (client) (default: client)*
--conf: 任意的Spark配置属性， 格式key=value. 如果值包含空格，可以加引号“key=value” 
application-jar: 打包好的应用jar,包含依赖. 这个URL在集群中全局可见。 比如hdfs:// 共享存储系统， 如果是 file:// path， 那么所有的节点的path都包含同样的jar
application-arguments: 传给main()方法的参数
--executor-memory 1G 指定每个executor可用内存为1G
--total-executor-cores 2 指定每个executor使用的cup核数为2个
3）结果展示
该算法是利用蒙特·卡罗算法求PI

4）准备文件
[atguigu@hadoop102 spark]$ mkdir input
在input下创建3个文件1.txt和2.txt，并输入以下内容
hello atguigu
hello spark
5）启动spark-shell
[atguigu@hadoop102 spark]$ bin/spark-shell
Using Spark's default log4j profile: org/apache/spark/log4j-defaults.properties
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
18/09/29 08:50:52 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
18/09/29 08:50:58 WARN ObjectStore: Failed to get database global_temp, returning NoSuchObjectException
Spark context Web UI available at http://192.168.9.102:4040
Spark context available as 'sc' (master = local[*], app id = local-1538182253312).
Spark session available as 'spark'.
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 2.1.1
      /_/
         
Using Scala version 2.11.8 (Java HotSpot(TM) 64-Bit Server VM, Java 1.8.0_144)
Type in expressions to have them evaluated.
Type :help for more information.

scala>
开启另一个CRD窗口
[atguigu@hadoop102 spark]$ jps
3627 SparkSubmit
4047 Jps
可登录hadoop102:4040查看程序运行

6）运行WordCount程序
scala>sc.textFile("input").flatMap(_.split(" ")).map((_,1)).reduceByKey(_+_).collect
res0: Array[(String, Int)] = Array((hadoop,6), (oozie,3), (spark,3), (hive,3), (atguigu,3), (hbase,6))

scala>
可登录hadoop102:4040查看程序运行

7）WordCount程序分析
数据流分析：
textFile("input")：读取本地文件input文件夹数据；
flatMap(_.split(" "))：压平操作，按照空格分割符将一行数据映射成一个个单词；
map((_,1))：对每一个元素操作，将单词映射为元组；
reduceByKey(_+_)：按照key将值进行聚合，相加；
collect：将数据收集到Driver端展示。

 Yarn模式（重点）
 概述
Spark客户端直接连接Yarn，不需要额外构建Spark集群。有yarn-client和yarn-cluster两种模式，主要区别在于：Driver程序的运行节点。
yarn-client：Driver程序运行在客户端，适用于交互、调试，希望立即看到app的输出
yarn-cluster：Driver程序运行在由RM（ResourceManager）启动的AP（APPMaster）适用于生产环境。
 
安装使用
1）修改hadoop配置文件yarn-site.xml,添加如下内容：
[atguigu@hadoop102 hadoop]$ vi yarn-site.xml
        <!--是否启动一个线程检查每个任务正使用的物理内存量，如果任务超出分配值，则直接将其杀掉，默认是true -->
        <property>
                <name>yarn.nodemanager.pmem-check-enabled</name>
                <value>false</value>
        </property>
        <!--是否启动一个线程检查每个任务正使用的虚拟内存量，如果任务超出分配值，则直接将其杀掉，默认是true -->
        <property>
                <name>yarn.nodemanager.vmem-check-enabled</name>
                <value>false</value>
        </property>
2）修改spark-env.sh，添加如下配置：
[atguigu@hadoop102 conf]$ vi spark-env.sh

YARN_CONF_DIR=/opt/module/hadoop-2.7.2/etc/hadoop
3）分发配置文件
[atguigu@hadoop102 conf]$ xsync /opt/module/hadoop-2.7.2/etc/hadoop/yarn-site.xml
[atguigu@hadoop102 conf]$ xsync spark-env.sh
4）执行一个程序
[atguigu@hadoop102 spark]$ bin/spark-submit \
--class org.apache.spark.examples.SparkPi \
--master yarn \
--deploy-mode client \
./examples/jars/spark-examples_2.11-2.1.1.jar \
100
注意：在提交任务之前需启动HDFS以及YARN集群。
 日志查看
1）修改配置文件spark-defaults.conf
添加如下内容：
spark.yarn.historyServer.address=hadoop102:18080
spark.history.ui.port=18080
2）重启spark历史服务
[atguigu@hadoop102 spark]$ sbin/stop-history-server.sh 
stopping org.apache.spark.deploy.history.HistoryServer
[atguigu@hadoop102 spark]$ sbin/start-history-server.sh 
starting org.apache.spark.deploy.history.HistoryServer, logging to /opt/module/spark/logs/spark-atguigu-org.apache.spark.deploy.history.HistoryServer-1-hadoop102.out
3）提交任务到Yarn执行
[atguigu@hadoop102 spark]$ bin/spark-submit \
--class org.apache.spark.examples.SparkPi \
--master yarn \
--deploy-mode client \
./examples/jars/spark-examples_2.11-2.1.1.jar \
100
4）Web页面查看日志


几种模式对比
模式	Spark安装机器数	需启动的进程	所属者
Local	1	无	Spark
Standalone	3	Master及Worker	Spark
Yarn	1	Yarn及HDFS	Hadoop
 
案例实操
Spark Shell仅在测试和验证我们的程序时使用的较多，在生产环境中，通常会在IDE中编制程序，然后打成jar包，然后提交到集群，最常用的是创建一个Maven项目，利用Maven来管理jar包的依赖。
编写WordCount程序
1）创建一个Maven项目WordCount并导入依赖
<dependencies>
    <dependency>
        <groupId>org.apache.spark</groupId>
        <artifactId>spark-core_2.11</artifactId>
        <version>2.1.1</version>
    </dependency>
</dependencies>
<build>
        <finalName>WordCount</finalName>
        <plugins>
<plugin>
                <groupId>net.alchim31.maven</groupId>
<artifactId>scala-maven-plugin</artifactId>
                <version>3.2.2</version>
                <executions>
                    <execution>
                       <goals>
                          <goal>compile</goal>
                          <goal>testCompile</goal>
                       </goals>
                    </execution>
                 </executions>
            </plugin>
        </plugins>
</build>
2）编写代码
package com.atguigu

import org.apache.spark.{SparkConf, SparkContext}

object WordCount{

  def main(args: Array[String]): Unit = {

//1.创建SparkConf并设置App名称
    val conf = new SparkConf().setAppName("WC")

//2.创建SparkContext，该对象是提交Spark App的入口
    val sc = new SparkContext(conf)

    //3.使用sc创建RDD并执行相应的transformation和action
    sc.textFile(args(0)).flatMap(_.split(" ")).map((_, 1)).reduceByKey(_+_, 1).sortBy(_._2, false).saveAsTextFile(args(1))

//4.关闭连接
    sc.stop()
  }
}
3）打包插件
<plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-assembly-plugin</artifactId>
                <version>3.0.0</version>
                <configuration>
                    <archive>
                        <manifest>
                            <mainClass>WordCount</mainClass>
                        </manifest>
                    </archive>
                    <descriptorRefs>
                        <descriptorRef>jar-with-dependencies</descriptorRef>
                    </descriptorRefs>
                </configuration>
                <executions>
                    <execution>
                        <id>make-assembly</id>
                        <phase>package</phase>
                        <goals>
                            <goal>single</goal>
                        </goals>
                    </execution>
                </executions>
      </plugin>
4）打包到集群测试
bin/spark-submit \
--class WordCount \
--master spark://hadoop102:7077 \
WordCount.jar \
/word.txt \
/out
本地调试
本地Spark程序调试需要使用local提交模式，即将本机当做运行环境，Master和Worker都为本机。运行时直接加断点调试即可。如下：
创建SparkConf的时候设置额外属性，表明本地执行：
val conf = new SparkConf().setAppName("WC").setMaster("local[*]")
    如果本机操作系统是windows，如果在程序中使用了hadoop相关的东西，比如写入文件到HDFS，则会遇到如下异常：

出现这个问题的原因，并不是程序的错误，而是用到了hadoop相关的服务，解决办法是将附加里面的hadoop-common-bin-2.7.3-x64.zip解压到任意目录。

在IDEA中配置Run Configuration，添加HADOOP_HOME变量
