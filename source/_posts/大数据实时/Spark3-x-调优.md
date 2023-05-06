---
title: Spark3-x-调优
categories:
- 大数据实时
---
```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>org.example</groupId>
    <artifactId>Spark-opti</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <scala.binary.version>2.12</scala.binary.version>
        <spark.version>3.0.0</spark.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-core_${scala.binary.version}</artifactId>
            <scope>provided</scope>
            <version>${spark.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-sql_${scala.binary.version}</artifactId>
            <scope>provided</scope>
            <version>${spark.version}</version>
        </dependency>
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-hive_${scala.binary.version}</artifactId>
            <scope>provided</scope>
            <version>${spark.version}</version>
        </dependency>


    </dependencies>

    <build>
        <plugins>
            <!-- 编译scala所需插件 -->
            <plugin>
                <groupId>org.scala-tools</groupId>
                <artifactId>maven-scala-plugin</artifactId>
                <version>2.15.1</version>
                <executions>
                    <execution>
                        <id>compile-scala</id>
                        <goals>
                            <goal>add-source</goal>
                            <goal>compile</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>test-compile-scala</id>
                        <goals>
                            <goal>add-source</goal>
                            <goal>testCompile</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>net.alchim31.maven</groupId>
                <artifactId>scala-maven-plugin</artifactId>
                <version>4.6.1</version>
                <executions>
                    <execution>
                        <!-- 声明绑定到maven的compile阶段 -->
                        <goals>
                            <goal>compile</goal>
                            <goal>testCompile</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>

            <!-- assembly打包插件 -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-assembly-plugin</artifactId>
                <version>3.3.0</version>
                <executions>
                    <execution>
                        <id>make-assembly</id>
                        <phase>package</phase>
                        <goals>
                            <goal>single</goal>
                        </goals>
                    </execution>
                </executions>
                <configuration>
                    <archive>
                        <manifest></manifest>
                    </archive>
                    <descriptorRefs>
                        <descriptorRef>jar-with-dependencies</descriptorRef>
                    </descriptorRefs>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <source>1.8</source>
                    <target>1.8</target>
                </configuration>
            </plugin>
        </plugins>
    </build>

</project>
```

<br>
Spark的五种JOIN策略解析
- **Shuffle Hash Join**
当要JOIN的表数据量比较大时，可以选择Shuffle Hash Join。这样可以将大表进行按照JOIN的key进行重分区，保证每个相同的JOIN key都发送到同一个分区中。

   **Shuffle Hash Join的基本步骤主要有以下两点：**
   - 首先，对于两张参与JOIN的表，分别按照join key进行重分区，该过程会涉及Shuffle，其目的是将相同join key的数据发送到同一个分区，方便分区内进行join。
   - 其次，对于每个Shuffle之后的分区，会将小表的分区数据构建成一个Hash table，然后根据join key与大表的分区数据记录进行匹配。

   **条件与特点**
   - 仅支持等值连接，join key不需要排序
   - 支持除了全外连接(full outer joins)之外的所有join类型
   - 需要对小表构建Hash map，属于内存密集型的操作，如果构建Hash表的一侧数据比较大，可能会造成OOM
   - 将参数spark.sql.join.prefersortmergeJoin (default true)置为false

- **Broadcast Hash Join**
  也称之为Map端JOIN。当有一张表较小时，我们通常选择Broadcast Hash Join，这样可以避免Shuffle带来的开销，从而提高性能。比如事实表与维表进行JOIN时，由于维表的数据通常会很小，所以可以使用Broadcast Hash Join将维表进行Broadcast。这样可以避免数据的Shuffle(在Spark中Shuffle操作是很耗时的)，从而提高JOIN的效率。在进行 Broadcast Join 之前，Spark 需要把处于 Executor 端的数据先发送到 Driver 端，然后 Driver 端再把数据广播到 Executor 端。如果我们需要广播的数据比较多，会造成 Driver 端出现 OOM。

   **Broadcast Hash Join主要包括两个阶段：**
   - Broadcast阶段 ：小表被缓存在executor中
   - Hash Join阶段：在每个 executor中执行Hash Join

   **条件与特点**
   - Broadcast Hash Join相比其他的JOIN机制而言，效率更高。但是，Broadcast Hash Join属于网络密集型的操作(数据冗余传输)，除此之外，需要在Driver端缓存数据，所以当小表的数据量较大时，会出现OOM的情况
   - 被广播的小表的数据量要小于spark.sql.autoBroadcastJoinThreshold值，默认是10MB(10485760)
   - 被广播表的大小阈值不能超过8GB，spark2.4源码如下：BroadcastExchangeExec.scala
   ```
   longMetric("dataSize") += dataSize
   if (dataSize >= (8L << 30)) {
      throw new SparkException(
         s"Cannot broadcast the table that is larger than 8GB: ${dataSize >> 30} GB")
   }
   ```
   - 基表不能被broadcast，比如左连接时，只能将右表进行广播。形如：fact_table.join(broadcast(dimension_table)，可以不使用broadcast提示，当满足条件时会自动转为该JOIN方式。

- **Sort Merge Join**
该JOIN机制是Spark默认的，可以通过参数spark.sql.join.preferSortMergeJoin进行配置，默认是true，即优先使用Sort Merge Join。一般在两张大表进行JOIN时，使用该方式。Sort Merge Join可以减少集群中的数据传输，该方式不会先加载所有数据的到内存，然后进行hashjoin，但是在JOIN之前需要对join key进行排序。具体图示：![image.png](Spark3-x-调优.assets\614f82828cbc4bd69dd8ac8fa0aecd97.png)

   **Sort Merge Join主要包括三个阶段：**
  - Shuffle Phase : 两张大表根据Join key进行Shuffle重分区
  - Sort Phase: 每个分区内的数据进行排序
  - Merge Phase: 对来自不同表的排序好的分区数据进行JOIN，通过遍历元素，连接具有相同Join key值的行来合并数据集

   **条件与特点**
   - 仅支持等值连接
  - 支持所有join类型
  - Join Keys是排序的
  - 参数spark.sql.join.prefersortmergeJoin (默认true)设定为true


- **Cartesian Join**
如果 Spark 中两张参与 Join 的表没指定join key（ON 条件）那么会产生 Cartesian product join，这个 Join 得到的结果其实就是两张行数的乘积。

   **条件**
   - 仅支持内连接
   - 支持等值和不等值连接
   - 开启参数spark.sql.crossJoin.enabled=true

- **Broadcast Nested Loop Join**
该方式是在没有合适的JOIN机制可供选择时，最终会选择该种join策略。优先级为：Broadcast Hash Join > Sort Merge Join > Shuffle Hash Join > cartesian Join > Broadcast Nested Loop Join。
在Cartesian 与Broadcast Nested Loop Join之间，如果是内连接，或者非等值连接，则优先选择Broadcast Nested Loop策略，当时非等值连接并且一张表可以被广播时，会选择Cartesian Join。

   **条件与特点**
   - 支持等值和非等值连接
   - 支持所有的JOIN类型，主要优化点如下：
   - 当右外连接时要广播左表
   - 当左外连接时要广播右表
   - 当内连接时，要广播左右两张表
