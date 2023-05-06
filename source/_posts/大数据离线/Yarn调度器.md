---
title: Yarn调度器
categories:
- 大数据离线
---
# 一、概念
## 1.1 什么是调度器
理想情况下，我们应用对Yarn资源的请求应该立刻得到满足，但现实情况资源往往是有限的，特别是在一个很繁忙的集群，一个应用资源的请求经常需要等待一段时间才能的到相应的资源。在Yarn中，负责给应用分配资源的就是Scheduler。其实调度本身就是一个难题，很难找到一个完美的策略可以解决所有的应用场景。为此，Yarn提供了多种调度器和可配置的策略供我们选择。YARN架构如下:

![image.png](Yarn调度器.assets\325819689c9c43949be7d26df4fcc2bc.png)

- ResourceManager（RM）：负责对各NM上的资源进行统一管理和调度，将AM分配空闲的Container运行并监控其运行状态。对AM申请的资源请求分配相应的空闲Container。主要由两个组件构成：**调度器（Scheduler）**和应用程序管理器（Applications Manager）。
- 调度器（Scheduler）：调度器根据容量、队列等限制条件（如每个队列分配一定的资源，最多执行一定数量的作业等），将系统中的资源分配给各个正在运行的应用程序。调度器仅根据各个应用程序的资源需求进行资源分配，而资源分配单位是Container，从而限定每个任务使用的资源量。Scheduler不负责监控或者跟踪应用程序的状态，也不负责任务因为各种原因而需要的重启（由ApplicationMaster负责）。总之，调度器根据应用程序的资源要求，以及集群机器的资源情况，为用程序分配封装在Container中的资源。调度器是可插拔的，例如CapacityScheduler、FairScheduler。（PS：在实际应用中，只需要简单配置即可）
- 应用程序管理器（Application Manager）：应用程序管理器负责管理整个系统中所有应用程序，包括应用程序提交、与调度器协商资源以启动AM、监控AM运行状态并在失败时重新启动等，跟踪分给的Container的进度、状态也是其职责。ApplicationMaster是应用框架，它负责向ResourceManager协调资源，并且与NodeManager协同工作完成Task的执行和监控。MapReduce就是原生支持的一种框架，可以在YARN上运行Mapreduce作业。有很多分布式应用都开发了对应的应用程序框架，用于在YARN上运行任务，例如Spark，Storm等。如果需要，我们也可以自己写一个符合规范的YARN application。
- NodeManager（NM）：NM是每个节点上的资源和任务管理器。它会定时地向RM汇报本节点上的资源使用情况和各个Container的运行状态；同时会接收并处理来自AM的Container 启动/停止等请求。ApplicationMaster（AM）：用户提交的应用程序均包含一个AM，负责应用的监控，跟踪应用执行状态，重启失败任务等。
- Container：是YARN中的资源抽象，它封装了某个节点上的多维度资源，如内存、CPU、磁盘、网络等，当AM向RM申请资源时，RM为AM返回的资源便是用Container 表示的。YARN会为每个任务分配一个Container且该任务只能使用该Container中描述的资源。

<br>
## 1.2 调度器类型
在Yarn中有三种调度器可以选择：FIFO Scheduler ，Capacity Scheduler，Fair Scheduler

### 1.2.1 FIFO Scheduler(先进先出调度器)
FIFO Scheduler把应用按提交的顺序排成一个队列，在进行资源分配的时候，先给队列中最头上的应用进行分配资源，待最头上的应用需求满足后再给下一个分配。
FIFO Scheduler是最简单也是最容易理解的调度器，也不需要任何配置，但它并不适用于共享集群。大的应用可能会占用所有集群资源，这就导致其它应用被阻塞。在共享集群中，更适合采用Capacity Scheduler或Fair Scheduler，这两个调度器都允许大任务和小任务在提交的同时获得一定的系统资源。

<br>
### 1.2.2 Capacity Scheduler(容量调度器)
**Capacity Scheduler是Apache Hadoop的默认调度器。**
![image.png](Yarn调度器.assets890f6636e204f44a42ae2ca629919b3.png)

#### 1.2.2.1 特点
1. **多队列：**每个队列可配置一定比例的资源，每个队列采用FIFO调度策略。
2. **容量保证：**可为每个队列设置资源最低保证和资源使用上限。
3. **灵活性：**如果一个队列中的资源有剩余，可以暂时共享给那些需要资源的队列，而一旦该队列有任务提交，这些资源会被归还。
4. **多租户：**支持多用户共享集群和多应用同时运行。为了防止同一个用户的作业独占队列中的资源，该调度器会对**同一用户提交的作业占用资源量进行限定**。

![image.png](Yarn调度器.assets\6e35599cd9f94e9994d8286b4dd20106.png)

#### 1.2.2.2 容量调度器的资源分配算法
1. **队列任务分配**
从root开始，使用深度优先算法，优先选择资源占用率最低的队列分配资源，即计算每个队列中正在运行的任务数与其应该分得的计算资源之间的比值，选择一个该比值最小的队列，即最闲的。
2. **队列中的作业资源分配**
默认按照提交作业的优先级和提交时间顺序分配资源。
3. **容器资源分配**
按照容器的优先级分配资源；如果优先级相同，按照数据本地性原则：
(1) 任务和数据在同一节点
(2) 任务和数据在同一机架
(3) 任务和数据不在同一节点也不在同一机架

<br>
### 1.2.3 Fair Scheduler(公平调度器)
**Fair Scheduler是CDH的默认调度器。**
`公平调度器的公平是指在时间尺度上，所有任务获得公平的资源。某一个作业应获资源和实际获取资源的差距叫缺额。调度器会优先为缺额大的作业分配资源。`

![image.png](Yarn调度器.assets\59f5697a393847e0b398be6d3d259ef4.png)

#### 1.2.3.1 与容量调度器相同点
1. 多队列：支持多队列多作业。
2. 容量保证：可为每个队列设置资源最低保证和资源使用上限。
3. 灵活性：如果一个队列中的资源有剩余，可以暂时共享给那些需要资源的队列，而一旦该队列有任务提交，这些资源会被归还。
4. 多租户：支持多用户共享集群和多应用同时运行。为了防止同一个用户的作业独占队列中的资源，该调度器会对同一用户提交的作业占用资源量进行限定。

#### 1.2.3.2 与容量调度器不同点
1. 核心调度策略不同
容量调度器：优先选择资源利用率低的队列
公平调度器：优先选择对资源的**缺额**比例大的
2. 每个队列可以单独设置资源分配方式
容量调度器：FIFO、DRF
公平调度器：FIFO、FAIR、DRF

#### 1.2.3.3 资源分配方式
1. **FIFO策略：**公平调度器每个队列的资源分配策略如果选择FIFO的话，此时公平调度器相当于上面的容量调度器。

2. **Fair策略：**Fair策略（默认）是一种基于最大最小公平算法实现的资源多路复用方式，默认情况下，每个队列内部采用该方式分配资源。即如果三个应用程序同时运行，则每个应用程序可得到1/3的资源（可以通过配置任务的权重来实现资源倾斜）。
**具体资源分配流程和容量调度器一致：**
（1）选择队列：优先选择资源占用率最低的队列进行分配
（2）选择作业：所有任务公平分配资源
（3）选择容器：①任务和数据在同一节点；②任务和数据在同一机架；③任务和数据不在同一节点也不在同一机架
以上三步，每一步都是按照公平策略分配资源。

3. **DRF(Dominant Resource Fairness)策略：**Yarn默认的资源只考虑了内存，但是资源有很多种(例如内存，CPU，网络带宽等)，这样我们很难衡量两个应用应该分配的资源比例。我们可以选择DRF策略实现对不同应用进行不同资源（CPU和内存）的合理分配。

#### 1.2.3.4 Fair策略的资源分配算法
**实际最小资源份额(表示当前应用所需的资源)：**mindshare = Min(资源需求量，配置的最小资源)
**是否饥饿(表示实际分配的资源是否小于所需的资源)：**isNeedy = 资源使用量 < mindshare(实际最小资源份额)
**资源分配比(实际分配资源/所需资源)：**minShareRatio = 资源使用量 / Max(mindshare,1)
**资源使用权重比()：**useToWeightRatio = 资源使用量 / 权重
![image.png](Yarn调度器.assets b494f691c6942879b6968a7383c605e.png)


![image.png](Yarn调度器.assets\155673cb53d043e88a1f1e81d2e3382a.png)

![image.png](Yarn调度器.assets\799c971a987d48f48528a93bfe22d9b2.png)


<br>
# 二、调度器配置
## 2.1 容量调度器配置
修改 hadoop/etc/hadoop/capacity-scheduler.xml文件，添加一条队列
```xml
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<configuration>

  <property>
    <name>yarn.scheduler.capacity.maximum-applications</name>
    <value>10000</value>
    <description>
      Maximum number of applications that can be pending and running.
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.maximum-am-resource-percent</name>
    <value>0.2</value>
    <description>
      Maximum percent of resources in the cluster which can be used to run 
      application masters i.e. controls number of concurrent running
      applications.
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.resource-calculator</name>
    <value>org.apache.hadoop.yarn.util.resource.DefaultResourceCalculator</value>
    <description>
      The ResourceCalculator implementation to be used to compare 
      Resources in the scheduler.
      The default i.e. DefaultResourceCalculator only uses Memory while
      DominantResourceCalculator uses dominant-resource to compare 
      multi-dimensional resources such as Memory, CPU etc.
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.root.queues</name>
    <value>default,flink</value>
    <description>
      The queues at the this level (root is the root queue).
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.root.default.capacity</name>
    <value>60</value>
    <description>Default queue target capacity.</description>
  </property>
    <property>
    <name>yarn.scheduler.capacity.root.flink.capacity</name>
    <value>40</value>
    <description>Default queue target capacity.</description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.root.default.user-limit-factor</name>
    <value>0.5</value>
    <description>
      Default queue user limit a percentage from 0.0 to 1.0.
    </description>
  </property>
    <property>
    <name>yarn.scheduler.capacity.root.flink.user-limit-factor</name>
    <value>0.8</value>
    <description>
      Default queue user limit a percentage from 0.0 to 1.0.
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.root.default.maximum-capacity</name>
    <value>100</value>
    <description>
      The maximum capacity of the default queue. 
    </description>
  </property>
    <property>
    <name>yarn.scheduler.capacity.root.flink.maximum-capacity</name>
    <value>80</value>
    <description>
      The maximum capacity of the default queue. 
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.root.default.state</name>
    <value>RUNNING</value>
    <description>
      The state of the default queue. State can be one of RUNNING or STOPPED.
    </description>
  </property>
    <property>
    <name>yarn.scheduler.capacity.root.flink.state</name>
    <value>RUNNING</value>
    <description>
      The state of the flink queue. State can be one of RUNNING or STOPPED.
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.root.default.acl_submit_applications</name>
    <value>*</value>
    <description>
      The ACL of who can submit jobs to the default queue.
    </description>
  </property>
  <property>
    <name>yarn.scheduler.capacity.root.flink.acl_submit_applications</name>
    <value>*</value>
    <description>
      The ACL of who can submit jobs to the default queue.
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.root.default.acl_administer_queue</name>
    <value>*</value>
    <description>
      The ACL of who can administer jobs on the default queue.
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.node-locality-delay</name>
    <value>40</value>
    <description>
      Number of missed scheduling opportunities after which the CapacityScheduler 
      attempts to schedule rack-local containers. 
      Typically this should be set to number of nodes in the cluster, By default is setting 
      approximately number of nodes in one rack which is 40.
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.queue-mappings</name>
    <value></value>
    <description>
      A list of mappings that will be used to assign jobs to queues
      The syntax for this list is [u|g]:[name]:[queue_name][,next mapping]*
      Typically this list will be used to map users to queues,
      for example, u:%user:%user maps all users to queues with the same name
      as the user.
    </description>
  </property>

  <property>
    <name>yarn.scheduler.capacity.queue-mappings-override.enable</name>
    <value>false</value>
    <description>
      If a queue mapping is present, will it override the value specified
      by the user? This can be used by administrators to place jobs in queues
      that are different than the one specified by the user.
      The default is false.
    </description>
  </property>

</configuration>
```
>**上述配置添加了flink队列，部分配置说明如下**
>1. `yarn.scheduler.capacity.maximum-am-resource-percent=10`  默认等于10，表示如果application master占用的队列空间大于10%，就会堵塞，直到appmaster占用小于10%。生产环境配置10%是正常的，资源较小时可以调大。
>2. `yarn.scheduler.capacity.root.queues=default`  默认队列是default，可以在添加其他队列，如default,hive,flink。
`yarn.scheduler.capacity.root.flink.state=RUNNING`  使定义的flink队列生效
>3. `yarn.scheduler.capacity.root.flink.capacity=60` 设置flink队列的资源分配比例为60；
`yarn.scheduler.capacity.root.flink.maximum-capacity=80`  设置flink队列的最大容量为80；
容量调度器的队列资源分配是弹性的，设置为在60-80之间。
>4. `yarn.scheduler.capacity.root.flink.acl_submit_applications=*`   访问控制，控制谁可以将任务提交到该队列，*表示所有人。
`yarn.scheduler.capacity.root.flink.acl_administer_queue=*`   访问控制，控制谁可以管理（包括提交和取消）该队列的任务，*表示任何人。
>5. `yarn.scheduler.capacity.root.default.user-limit-factor=0.5`   同一用户提交的任务最多可以使用该队列的50%资源
`yarn.scheduler.capacity.root.flink.user-limit-factor=0.8`   同一用户提交的任务最多可以使用该队列的80%资源

**任务优先级**
在yarn-site.xml中增加参数，表示一共可以配置的优先级，如下配置了5个优先级，0是最低优先级，5是最高优先级。
```
<property>
    <name>yarn.cluster.max-application-priority</name>
    <value>5</value>
</property>
```
提交任务指定优先级：`hadoop jar xxx.jar pi -Dmapreduce.job.queuename=hive -Dmapreduce.job.priority=5 1 10000;`
优先级高的会优先分配资源。

<br>
**启动任务时指定队列**
- **hadoop提交：**`hadoop jar xxx.jar pi -Dmapreduce.job.queuename=hive 1 1`;
- **sqoop中提交：**`sqoop import -Dmapreduce.job.queuename=hive --connect xxx ...`;
- **hive中提交：**`set mapreduce.job.ququqname=hive`;
- **spark中提交：**`spark-submit --queue hive xxx`;
- **flink on session中提交：**`yarn-session.sh -s 2 -jm 1024 -tm 2048 -nm flink-on-yarn -qu flink -d`
- **flink的Per-Job-Cluster中提交：**`flink run -m yarn-cluster -ynm dimetl -p1 -ys 1 -yjm 1024 -ytm 1024m -d -c com.iotmars.wecook.StreamWordCount -yqu flinkqueue /opt/jar/flink-demo-0.0.1-SNAPSHOT-jar-with-dependencies.jar --hostname bigdata3 --port 7777`
- **flink全局设置提交队列：**在配置文件flink-conf.yaml中配置`yarn.application.queue: spark`


<br>
##2.2 公平调度器配置
[Apache Hadoop 3.3.3 – Hadoop: Fair Scheduler](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/FairScheduler.html)

修改hadoop/etc/hadoop/yarn-site.xml文件
```
<!--  指定使用fairScheduler的调度方式  -->
<property>
       <name>yarn.resourcemanager.scheduler.class</name>
       <value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler</value>
</property>
 
<!--  指定配置文件路径  -->
<property>
       <name>yarn.scheduler.fair.allocation.file</name>
       <value>/opt/module/hadoop-3.1.3/etc/hadoop/fair-scheduler.xml</value>
</property>
 
<!-- 是否启用资源抢占，如果启用，那么当该队列资源使用
yarn.scheduler.fair.preemption.cluster-utilization-threshold 这么多比例的时候，就从其他空闲队列抢占资源
  -->
<property>
       <name>yarn.scheduler.fair.preemption</name>
       <value>true</value>
</property>
 
<property>
       <name>yarn.scheduler.fair.preemption.cluster-utilization-threshold</name>
       <value>0.8f</value>
</property>
 
<!-- 默认提交到default队列  -->
<property>
       <name>yarn.scheduler.fair.user-as-default-queue</name>
       <value>true</value>
</property>
 
<!-- 如果提交一个任务到不存在的队列，是否允许创建一个新的队列，设置false不允许  -->
<property>
       <name>yarn.scheduler.fair.allow-undeclared-pools</name>
       <value>false</value>
</property>
```
<br>
**添加配置文件fair-scheduler.xml**
```
<?xml version="1.0"?>
<allocations>
  <!-- 增加一个default队列 -->
  <queue name="root">
    <!-- 队列最小资源 -->
    <minResources>51200 mb,30vcores</minResources>
    <!-- 队列最大资源 -->
    <maxResources>102400 mb,50vcores</maxResources>
    <!-- 队列中最多同时运行的应用数，默认50，根据线程数配置 -->
    <maxRunningApps>50</maxRunningApps>
    <!-- 队列中Application Master占用资源的最大比例 -->
    <maxAMShare>0.8</maxAMShare>
    <!-- 该队列资源权重，默认值为1.0 -->
    <weight>1.0</weight>
    <!-- 允许提交任务的用户名和组,格式为： 用户名 用户组；当有多个用户时候，格式为：用户名1,用户名2 用户名1所属组,用户名2所属组 -->
    <aclSubmitApps>*</aclSubmitApps>
    <!-- aclAdministerApps允许管理任务的用户名和组；格式同上。 -->
    <aclAdministerApps>*</aclAdministerApps>

      <!-- 增加一个job队列 -->
      <queue name="default">
        <!-- 队列最小资源 -->
        <minResources>10240 mb,2vcores</minResources>
        <!-- 队列最大资源 -->
        <maxResources>30720 mb,10vcores</maxResources>
        <!-- 队列中最多同时运行的应用数，默认50，根据线程数配置 -->
        <maxRunningApps>10</maxRunningApps>
        <!-- 队列中Application Master占用资源的最大比例 -->
        <maxAMShare>0.8</maxAMShare>
        <!-- 该队列资源权重，默认值为1.0 -->
        <weight>1.0</weight>
        <!-- 队列内部的资源分配策略，默认fair -->
        <schedulingPolicy>fair</schedulingPolicy>
      </queue>

      <!-- 增加一个job队列 -->
      <queue name="job">
        <!-- 队列最小资源 -->
        <minResources>30720 mb,10vcores</minResources>
        <!-- 队列最大资源 -->
        <maxResources>66560 mb,36vcores</maxResources>
        <!-- 队列中最多同时运行的应用数，默认50，根据线程数配置 -->
        <maxRunningApps>10</maxRunningApps>
        <!-- 队列中Application Master占用资源的最大比例 -->
        <maxAMShare>0.8</maxAMShare>
        <!-- 该队列资源权重，默认值为1.0 -->
        <weight>2.0</weight>
        <!-- 队列内部的资源分配策略，默认fair -->
        <schedulingPolicy>fair</schedulingPolicy>
      </queue>
  </queue>

  <!-- 任务队列分配策略，可配置多层规则，从第一个规则开始匹配，直到匹配成功 -->
  <queuePlacementPolicy>
    <!-- specified表示匹配提交任务时指定队列，如未指定提交队列，则继续匹配下一个规则；false表示：如果指定队列不存在，不允许自动创建 -->
    <rule name="specified" create="false" />
    <!-- 提交到root.group.username队列，primaryGroup表示匹配root.group，若root.group不存在，不允许自动创建；nestedUserQueue表示匹配root.group.username队列，若root.group.username不存在，允许自动创建 -->
    <rule name="nestedUserQueue" create="true">
	<rule name="user" create="false"/>
        <rule name="secondaryGroupExistingQueue" create="false"/>
        <rule name="primaryGroup" create="false"/>
    </rule>
    <!-- 最后一个规则必须为reject或者default。Reject表示拒绝创建并提交失败，default表示把任务提交到default队列 -->
    <rule name="default" queue="default" />
  </queuePlacementPolicy>
</allocations>
```

>**minResources:**		最少资源保证量，设置格式为“X mb, Y vcores”，当一个队列的最少资源保证量未满足时，它将优先于其他同级队列获得资源，对于不同的调度策略（后面会详细介绍），最少资源保证量的含义不同，对于fair策略，则只考虑内存资源，即如果一个队列使用的内存资源超过了它的最少资源量，则认为它已得到了满足；对于drf策略，则考虑主资源使用的资源量，即如果一个队列的主资源量超过它的最少资源量，则认为它已得到了满足。
**maxResources:**		最多可以使用的资源量，fair scheduler会保证每个队列使用的资源量不会超过该队列的最多可使用资源量。
**maxRunningApps:**		最多同时运行的应用程序数目。通过限制该数目，可防止超量Map Task同时运行时产生的中间输出结果撑爆磁盘。
**minSharePreemptionTimeout:**	最小共享量抢占时间。如果一个资源池在该时间内使用的资源量一直低于最小资源量，则开始抢占资源。
**schedulingMode/schedulingPolicy:**	队列采用的调度模式，可以是fifo、fair或者drf。
**aclSubmitApps:**	可向队列中提交应用程序的Linux用户或用户组列表，默认情况下为“*”，表示任何用户均可以向该队列提交应用程序。需要注意的是，该属性具有继承性，即子队列的列表会继承父队列的列表。配置该属性时，用户之间或用户组之间用“，”分割，用户和用户组之间用空格分割，比如“user1, user2 group1,group2”。
**aclAdministerApps:**	该队列的管理员列表。一个队列的管理员可管理该队列中的资源和应用程序，比如可杀死任意应用程序。
**queuePlacementPolicy元素：**包含一个规则元素列表，这些规则元素告诉调度程序如何将传入的应用程序放入队列中。规则以列出顺序应用。规则可能会引起争论。所有规则都接受“创建”参数，该参数指示规则是否可以创建新队列。“创建”默认为true；如果设置为false并且规则会将应用程序放置在分配文件中未配置的队列中，则我们继续执行下一条规则。最后一条规则必须是永远不能发出继续的规则。有效规则是：
**specified：**将应用放入请求的队列中。如果应用程序没有请求队列，即指定了“默认”，则我们继续。如果应用程序请求的队列名称以句点开头或结尾，即“ .q1”或“ q1.”之类的名称将被拒绝。
**用户组:用户名：**应用程序以提交用户的名称放置在队列中。用户名中的句点将被替换为“ _dot_”，即用户“ first.last”的队列名称为“ first_dot_last”。
**user:** 表示将提交任务的用户名作为队列名，然后将任务放到这个队列中执行；
**primaryGroup：**表示将提交任务的用户所属的主组作为队列名。组名中的句点将被替换为“ _dot_”，即组“ one.two”的队列名称为“ one_dot_two”。
**secondaryGroupExistingQueue：**表示将提交任务的用户所属的附属组作为队列名。组名中的句点将被替换为“ _dot_”，即，如果存在这样的队列，则以“ one.two”作为其次要组之一的用户将被放入“ one_dot_two”队列中。
>**nestedUserQueue：**将应用程序放入用户队列中，并将用户名放在嵌套规则建议的队列下。这类似于“ user”规则，区别在于“ nestedUserQueue”规则，可以在任何父队列下创建用户队列，而“ user”规则仅在根队列下创建用户队列。请注意，只有在嵌套规则返回父队列时才应用nestedUserQueue规则。可以通过将队列的'type'属性设置为'parent'或通过在该队列下配置至少一个叶子来配置父队列来配置父队列。
>最后一个规则必须为reject或者default。Reject表示拒绝创建并提交失败，default表示把任务提交到配置的队列中。

<br>
**提交任务**
1. 提交任务时指定队列，按照配置规则，任务会到指定的root.test队列
`hadoop jar xxx.jar pi -Dmapreduce.job.queuename=root.test 1 1;`
2. 用户为test:test，提交任务时不指定队列，按照配置规则，任务会到root.test.test队列
`hadoop jar xxx.jar pi 1 1;`


<br>
# 三、参考
[https://hadoop.apache.org/docs/r2.7.2/hadoop-yarn/hadoop-yarn-site/FairScheduler.html](https://hadoop.apache.org/docs/r2.7.2/hadoop-yarn/hadoop-yarn-site/FairScheduler.html)
[https://blog.cloudera.com/untangling-apache-hadoop-yarn-part-4-fair-scheduler-queue-basics/](https://blog.cloudera.com/untangling-apache-hadoop-yarn-part-4-fair-scheduler-queue-basics/)
[https://www.bilibili.com/video/BV1Qp4y1n7EN?p=139&spm_id_from=pageDriver](https://www.bilibili.com/video/BV1Qp4y1n7EN?p=139&spm_id_from=pageDriver)
