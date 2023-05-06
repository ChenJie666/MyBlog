---
title: Ranger权限管理
categories:
- 权限认证
---
# 一、介绍
## 1.1 什么是Ranger
Apache Ranger是一个用来在Hadoop平台上进行监控，启用服务，以及全方位数据安全访问管理的安全框架。
Ranger的愿景是在Apache Hadoop生态系统中提供全面的安全管理。随着企业业务的拓展，企业可能在多用户环境中运行多个工作任务，这就要求Hadoop内的数据安全性需要扩展为同时支持多种不同的需求进行数据访问，同时还需要提供一个可以对安全策略进行集中管理，配置和监控用户访问的框架。Ranger由此产生！
Ranger的官网：https://ranger.apache.org/

## 1.2 Ranger的目标
- 允许用户使用UI或REST API对所有和安全相关的任务进行集中化的管理
- 允许用户使用一个管理工具对操作Hadoop体系中的组件和工具的行为进行细粒度的授权
- 支持Hadoop体系中各个组件的授权认证标准
- 增强了对不同业务场景需求的授权方法支持，例如基于角色的授权或基于属性的授权
- 支持对Hadoop组件所有涉及安全的审计行为的集中化管理

## 1.3 Ranger支持的框架
- Apache Hadoop
- Apache Hive：Hive支持多种模式的鉴权，如自己写鉴权代码，打jar包后放到lib目录下。这种就没有Ranger方便快捷。
- Apache HBase
- Apache Storm
- Apache Knox
- Apache Solr
- Apache Kafka
- YARN
- NIFI

## 1.4 Ranger工作原理
Ranger主要由三个组件组成：
- Ranger Admin
Ranger的核心是Web应用程序，也称为RangerAdmin模块，此模块由管理策略，审计日志和报告等三部分组成。管理员角色的用户可以通过RangerAdmin提供的web界面或REST APIS来定制安全策略。您可以创建和更新安全访问策略，这些策略被存储在数据库中。各个组件的Plugin定期对这些策略进行轮询。这些策略会由Ranger提供的轻量级的针对不同Hadoop体系中组件的插件来执行。插件会在Hadoop的不同组件的核心进程启动后，启动对应的插件进程来进行安全管理！

- Ranger Plugins
Plugin嵌入在各个集群组件的进程里，是一个轻量级的Java程序。例如，Ranger对Hive的组件，就被嵌入在Hiveserver2里。这些Plugin从Ranger Admin服务端拉取策略，并把它们存储在本地文件中。当接收到来自组件的用户请求时，对应组件的Plugin会拦截该请求，并根据安全策略对其进行评估。

- Ranger UserSync
Ranger提供了一个用户同步工具。您可以从Unix或者LDAP中拉取用户和用户组的信息。这些用户和用户组的信息被存储在Ranger Admin的数据库中，可以在定义策略时使用。


![image.png](Ranger权限管理.assets\2baee3aa6b50402683ab7bac7aa368e4.png)


<br>
# 二、源码编译
需要从官网下载ranger源码，通过maven编译后进行使用。
[ranger2.0.0源码 下载地址](https://dist.apache.org/repos/dist/release/ranger/2.0.0/apache-ranger-2.0.0.tar.gz)

`Ranger2.0要求对应的Hadoop为3.x以上，Hive为3.x以上版本，JDK为1.8以上版本！`

**推荐在Linux 系统上进行编译，比较方便，需要进行如下准备**
- 安装maven-3.6.3(这是ranger2.0.0推荐的maven版本)；
- 安装gcc：yum install -y gcc (需要对C语言进行编译，如果不安装，编译Unix Native Authenticator模块时会报错找不到gcc命令)；
- 安装python2：如果系统自带python2，那么直接忽略，如centos7.x；

解压源码包，进入ranger-2.0.0父项目的路径下，执行如下命令(mvn命令没有写到环境变量的话需要写全mvn的路径)
```
mvn -DskipTests clean compile package install assembly:assembly
```

编译开始，需要等待下载依赖和完成编译打包，耗时个把小时。如果某一个模块编译出错了，可以单独进入该模块进行编译，启动编译命令时加上-X参数，显示debug信息，方便找到错误。

编译完成后，可以在父项目的target文件中找到所有组件的压缩文件
```
[root@bigdata2 target]# ll
total 1605360
drwxr-xr-x 2 root root        28 Sep 10 15:28 antrun
drwxr-xr-x 2 root root       116 Sep 10 15:40 archive-tmp
drwxr-xr-x 3 root root        22 Sep 10 15:28 maven-shared-archive-resources
-rw-r--r-- 1 root root 248578820 Sep 10 15:37 ranger-2.0.0-admin.tar.gz
-rw-r--r-- 1 root root 249667518 Sep 10 15:38 ranger-2.0.0-admin.zip
-rw-r--r-- 1 root root  27796446 Sep 10 15:39 ranger-2.0.0-atlas-plugin.tar.gz
-rw-r--r-- 1 root root  27832766 Sep 10 15:39 ranger-2.0.0-atlas-plugin.zip
-rw-r--r-- 1 root root  31560169 Sep 10 15:40 ranger-2.0.0-elasticsearch-plugin.tar.gz
-rw-r--r-- 1 root root  31606662 Sep 10 15:40 ranger-2.0.0-elasticsearch-plugin.zip
-rw-r--r-- 1 root root  26643418 Sep 10 15:34 ranger-2.0.0-hbase-plugin.tar.gz
-rw-r--r-- 1 root root  26666456 Sep 10 15:34 ranger-2.0.0-hbase-plugin.zip
-rw-r--r-- 1 root root  23972037 Sep 10 15:33 ranger-2.0.0-hdfs-plugin.tar.gz
-rw-r--r-- 1 root root  23998268 Sep 10 15:33 ranger-2.0.0-hdfs-plugin.zip
-rw-r--r-- 1 root root  23831930 Sep 10 15:33 ranger-2.0.0-hive-plugin.tar.gz
-rw-r--r-- 1 root root  23855462 Sep 10 15:34 ranger-2.0.0-hive-plugin.zip
-rw-r--r-- 1 root root  39940594 Sep 10 15:35 ranger-2.0.0-kafka-plugin.tar.gz
-rw-r--r-- 1 root root  39984673 Sep 10 15:35 ranger-2.0.0-kafka-plugin.zip
-rw-r--r-- 1 root root  90990768 Sep 10 15:38 ranger-2.0.0-kms.tar.gz
-rw-r--r-- 1 root root  91107780 Sep 10 15:39 ranger-2.0.0-kms.zip
-rw-r--r-- 1 root root  28391293 Sep 10 15:34 ranger-2.0.0-knox-plugin.tar.gz
-rw-r--r-- 1 root root  28411851 Sep 10 15:34 ranger-2.0.0-knox-plugin.zip
-rw-r--r-- 1 root root  23947177 Sep 10 15:40 ranger-2.0.0-kylin-plugin.tar.gz
-rw-r--r-- 1 root root  23980871 Sep 10 15:40 ranger-2.0.0-kylin-plugin.zip
-rw-r--r-- 1 root root     34222 Sep 10 15:38 ranger-2.0.0-migration-util.tar.gz
-rw-r--r-- 1 root root     37740 Sep 10 15:38 ranger-2.0.0-migration-util.zip
-rw-r--r-- 1 root root  26393845 Sep 10 15:35 ranger-2.0.0-ozone-plugin.tar.gz
-rw-r--r-- 1 root root  26421956 Sep 10 15:35 ranger-2.0.0-ozone-plugin.zip
-rw-r--r-- 1 root root  40301292 Sep 10 15:40 ranger-2.0.0-presto-plugin.tar.gz
-rw-r--r-- 1 root root  40342416 Sep 10 15:40 ranger-2.0.0-presto-plugin.zip
-rw-r--r-- 1 root root  22234270 Sep 10 15:39 ranger-2.0.0-ranger-tools.tar.gz
-rw-r--r-- 1 root root  22248968 Sep 10 15:39 ranger-2.0.0-ranger-tools.zip
-rw-r--r-- 1 root root     42210 Sep 10 15:38 ranger-2.0.0-solr_audit_conf.tar.gz
-rw-r--r-- 1 root root     45636 Sep 10 15:38 ranger-2.0.0-solr_audit_conf.zip
-rw-r--r-- 1 root root  26974799 Sep 10 15:36 ranger-2.0.0-solr-plugin.tar.gz
-rw-r--r-- 1 root root  27010869 Sep 10 15:36 ranger-2.0.0-solr-plugin.zip
-rw-r--r-- 1 root root  23952172 Sep 10 15:39 ranger-2.0.0-sqoop-plugin.tar.gz
-rw-r--r-- 1 root root  23986865 Sep 10 15:39 ranger-2.0.0-sqoop-plugin.zip
-rw-r--r-- 1 root root   4012596 Sep 10 15:39 ranger-2.0.0-src.tar.gz
-rw-r--r-- 1 root root   6257752 Sep 10 15:39 ranger-2.0.0-src.zip
-rw-r--r-- 1 root root  37239595 Sep 10 15:34 ranger-2.0.0-storm-plugin.tar.gz
-rw-r--r-- 1 root root  37269537 Sep 10 15:34 ranger-2.0.0-storm-plugin.zip
-rw-r--r-- 1 root root  32770865 Sep 10 15:38 ranger-2.0.0-tagsync.tar.gz
-rw-r--r-- 1 root root  32782295 Sep 10 15:38 ranger-2.0.0-tagsync.zip
-rw-r--r-- 1 root root  16260331 Sep 10 15:38 ranger-2.0.0-usersync.tar.gz
-rw-r--r-- 1 root root  16281055 Sep 10 15:38 ranger-2.0.0-usersync.zip
-rw-r--r-- 1 root root  23962337 Sep 10 15:35 ranger-2.0.0-yarn-plugin.tar.gz
-rw-r--r-- 1 root root  23993168 Sep 10 15:35 ranger-2.0.0-yarn-plugin.zip
-rw-r--r-- 1 root root    166727 Sep 10 15:28 rat.txt
-rw-r--r-- 1 root root         5 Sep 10 15:32 version
```

>如果编译的是ranger-2.2.0源码，需要安装phthon3; 且编译命令不能加assembly:assembly，会有冲突。

<br>
# 三、部署
[安装部署官网教程](https://cwiki.apache.org/confluence/display/RANGER/Ranger+Installation+Guide)
## 3.1 数据库配置
创建数据库
```
mysql> create database ranger;
```
创建用户
```
mysql> grant all privileges on ranger.* to ranger@'%' identified by 'bigdata123';
```

## 3.2 安装组件
### 3.2.1 RangerAdmin
#### 安装RangerAdmin
①创建目录mkdir /opt/module/ranger-2.0.0
解压ranger-2.0.0-admin.tar.gz到该目录下
```
[root@bigdata1 ranger-2.0.0]# tar -zxvf /opt/software/ranger-2.0.0-admin.tar.gz -C /opt/module/ranger-2.0.0/
```
②配置文件install.properties
```
#mysql驱动
SQL_CONNECTOR_JAR=/opt/module/ranger-2.0.0/ranger-2.0.0-admin/mysql-connector-java-5.1.45.jar
#mysql的主机名和root用户的用户名密码
db_root_user=root
db_root_password=Password@123
db_host=192.168.101.174
#ranger需要的数据库名和用户信息，和2.2.1创建的信息要一一对应
db_name=ranger
db_user=ranger
db_password=bigdata123
#其他ranger admin需要的用户密码
rangerAdmin_password=bigdata123
rangerTagsync_password=bigdata123
rangerUsersync_password=bigdata123
keyadmin_password=bigdata123
#ranger存储审计日志的路径，默认为solr，这里为了方便暂不设置
audit_store=
#策略管理器的url,rangeradmin安装在哪台机器，主机名就为对应的主机名，不能写ip
policymgr_external_url=http://bigdata1:6080
#启动ranger admin进程的linux用户信息
unix_user=hxr
unix_user_pwd=bigdata123
unix_group=hxr
#hadoop的配置文件目录
hadoop_conf=/opt/module/hadoop-3.1.3/etc/hadoop
```
③切换到用户root进行安装
`./setup.sh`
>注意：如果使用`sudo ./setup.sh`安装会找不到JAVA_HOME，但是使用`sudo echo ${JAVA_HOME}` 是可以正常打印的，很奇怪？？？

④root用户下软路由配置文件
只需要执行`./set_globals.sh`就会自动进行软路由
执行结果如下
```
[root@cos-bigdata-hadoop-01 ranger-2.0.0-admin]# sudo -u -i ranger ./set_globals.sh 
usermod：无改变
[2021/08/03 15:27:25]:  [I] Soft linking /etc/ranger/admin/conf to ews/webapp/WEB-INF/classes/conf
```

<br>
#### 启动Ranger Admin
安装时会自动将启动脚本放到/usr/bin目录下，同时根据配置的install.properties自动生成配置文件ranger-admin-site.xml。
执行链接命令时会将/etc/ranger/admin/conf目录链接到ews/webapp/WEB-INF/classes/conf目录。
也会将服务设为开机自启，所以无需我们设置开机自启。

但是自动生成的配置文件有两处错误，我们需要手动修改。

①修改配置文件 /etc/ranger/admin/conf/ranger-admin-site.xml
```
        <property>
                <name>ranger.jpa.jdbc.password</name>
                <value>bigdata123</value>
                <description />
        </property>
        <property>
                <name>ranger.service.host</name>
                <value>192.168.101.179</value>
        </property>
```

②启动和关闭RangerAdmin
```
ranger-admin start/stop/restart
```
启动后其后台进程名为**EmbeddedServer**

③访问UI
管理员账号密码为admin/bigdata123
[http://192.168.101.179:6080](http://192.168.101.179:6080)

### 3.2.2 RangerUsersync
#### 安装
RangerUsersync作为Ranger提供的一个管理模块，可以将Linux机器上的用户和组信息同步到RangerAdmin的数据库中进行管理。也可以同步LDAP等公司现有的用户框架体系中的用户到Ranger Admin中。

①解压
```
[root@bigdata1 ranger-2.0.0]# tar -zxvf /opt/software/ranger-2.0.0-usersync.tar.gz -C /opt/module/ranger-2.0.0/
```

②修改配置文件install.properties
这里既可以配置同步linux上的用户，也可以配置同步ldap上的用户
**Ⅰ. 同步linux用户**
```
#rangeradmin的url
POLICY_MGR_URL =http://192.168.101.179:6080
#同步间隔时间，单位(分钟)
SYNC_INTERVAL = 1
#运行此进程的linux用户
unix_user=hxr
unix_group=hxr
#rangerUserSync的用户密码，参考rangeradmin中install.properties的配置
rangerUsersync_password=bigdata123
#hadoop的配置文件目录
hadoop_conf=/opt/module/hadoop-3.1.3/etc/hadoop
```

**Ⅱ.同步ldap用户**
```
#rangeradmin的url
POLICY_MGR_URL =http://192.168.101.179:6080
#同步间隔时间，单位(分钟)
SYNC_INTERVAL = 60

#运行此进程的linux用户
unix_user=hxr
unix_group=hxr
#rangerUserSync的用户密码，参考rangeradmin中install.properties的配置
rangerUsersync_password=bigdata123
#hadoop的配置文件目录
hadoop_conf=/opt/module/hadoop-3.1.3/etc/hadoop

# 同步的数据源类型，unix为同步linux用户，ldap为同步ldap用户
SYNC_SOURCE = ldap

# 同步时间，单位为min(不能小于60min)
SYNC_INTERVAL = 60  
# ldap地址
SYNC_LDAP_URL = ldap://192.168.101.174:389
# ldap管理员用户密码
SYNC_LDAP_BIND_DN = cn=admin,dc=ldap,dc=chenjie,dc=asia
SYNC_LDAP_BIND_PASSWORD = bigdata123
# 同步用户所在的路径
SYNC_LDAP_SEARCH_BASE = ou=hive,dc=ldap,dc=chenjie,dc=asia
```

③在root用户下安装
`./setup.sh`

④修改配置文件 conf/ranger-ugsync-site.xml 
```
        <property>
                <name>ranger.usersync.enabled</name>
                <value>true</value>
        </property>
```

#### 启动
`ranger-usersync start/stop/restart`

ranger-usersync服务也是开机自启动的，因此之后不需要手动启动！

![可以看到已经将节点上的部分用户同步过来了](Ranger权限管理.assets5018bb6f21d497cb9b0373600b191d2.png)

### 3.2.3 Ranger Hive-plugin
#### 安装
①解压ranger-2.0.0-hive-plugin.tar.gz
```
[root@bigdata1 ranger-2.0.0]# tar -zxvf /opt/software/ranger-2.0.0-hive-plugin.tar.gz -C /opt/module/ranger-2.0.0
```

②修改配置文件inistall.propreties
```
#策略管理器的url地址
POLICY_MGR_URL=http://192.168.101.179:6080
#组件名称可以自定义
REPOSITORY_NAME=hivedev
#hive的安装目录
COMPONENT_INSTALL_DIR_NAME=/opt/module/hive-3.1.2
#hive组件的启动用户
CUSTOM_USER=hxr
#hive组件启动用户所属组
CUSTOM_GROUP=hxr
```

③将hive配置文件软连接到Ranger Hive-plugin目录下
`ln -s /opt/module/hive-3.1.2/conf /opt/module/ranger-2.0.0/ranger-2.0.0-hive-plugin`

#### 启动
使用root用户启动Ranger Hive-plugin
```
./enable-hive-plugin.sh
```
>执行./disable-hive-plugin.sh 可以关闭插件

会在hive的conf目录下生成配置文件hiveserver2-site.xml
```
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?><!--
Licensed to the Apache Software Foundation (ASF) under one or more
contributor license agreements. See the NOTICE file distributed with
this work for additional information regarding copyright ownership.
The ASF licenses this file to You under the Apache License, Version 2.0
(the "License"); you may not use this file except in compliance with
the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--><configuration>
<property>
        <name>hive.security.authorization.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>hive.security.authorization.manager</name>
        <value>org.apache.ranger.authorization.hive.authorizer.RangerHiveAuthorizerFactory</value>
    </property>
    <property>
        <name>hive.security.authenticator.manager</name>
        <value>org.apache.hadoop.hive.ql.security.SessionStateUserAuthenticator</value>
    </property>
    <property>
        <name>hive.conf.restricted.list</name>
        <value>hive.security.authorization.enabled,hive.security.authorization.manager,hive.security.authenticator.manager</value>
    </property>
</configuration>
```

重启hiveserver2生效


<br>
### 3.2.4 Ranger HDFS-plugin
#### 安装
①解压ranger-2.0.0-hdfs-plugin.tar.gz
`tar -zxvf /opt/software/ranger-2.0.0-hdfs-plugin.tar.gz -C /opt/module/ranger-2.0.0`

②修改配置文件inistall.propreties
```
#策略管理器的url地址
POLICY_MGR_URL=http://192.168.101.179:6080
#组件名称可以自定义
REPOSITORY_NAME=hdfsdev
#hdfs的安装目录
COMPONENT_INSTALL_DIR_NAME=/opt/module/hadoop-3.1.3
#hdfs组件的启动用户
CUSTOM_USER=hxr
#hdfs组件启动用户所属组
CUSTOM_GROUP=hxr
```

③创建软连接
```
ln -s /opt/module/hadoop-3.1.3/etc/hadoop  /opt/module/ranger-2.0.0/ranger-2.0.0-hive-plugin/conf
/opt/module/ranger-2.0.0/ranger-2.0.0-hive-plugin/conf
ln -s /opt/module/hadoop-3.1.3/
```

#### 启动
```
[root@bigdata1 ranger-2.0.0-hdfs-plugin]# ./enable-hdfs-plugin.sh
```

>关闭hdfs插件命令为`./disable-hdfs-plugin.sh `。除了关闭插件外，还需要删除hadoop配置文件中ranger相关的配置文件，并且删除hdfs-site.xml中插件添加的相关配置。

重启hdfs生效


<br>
# 三、权限配置
## 3.1 Hive权限管理
### 3.1.1 添加hive组件
在Ranger Admin上配置hive插件。
在首页上点击Hive标签的加号，跳转到hive配置页面
![配置hive页面](Ranger权限管理.assets\51584528a69c49bda39fe077b79ee2fa.png)
>- Service Name：hivedev   (必须与配置文件中的REPOSITORY_NAME一致)
>- Username：hxr 
>- Password：无密码可以随便填
>- jdbc.driverClassName：org.apache.hive.jdbc.HiveDriver
>- jdbc.url：jdbc:hive2://192.168.101.179:10000

**需要注意的是：**
1. hiveserver2需要进行重启才能正常的使用Ranger Hive插件。在UI中配置hive完成后，先进行save，save完成后才会生成权限，否则所有用户都没有任何权限。
2. username需要在core-site.xml中设置代理。

## 3.1.2 使用Ranger对Hive进行权限管理
save之后可以进入配置中，为每个用户进行更细粒度的权限配置。

#### 3.1.2.1 权限配置示例
在ACCESS中可以对权限进行配置
![image.png](Ranger权限管理.assets\4698f13edfbb415fba5a090b1fb32de0.png)

#### 3.1.2.2 脱敏配置示例
在Masking可以指定用户和字段，用户在查询表是将返回的该字段进行脱敏。
![image.png](Ranger权限管理.assetsabac9590c0a4d62b531e73d10f58724.png)

#### 3.1.2.3 行级过滤示例
可以指定用户和需要过滤掉的行，该用户查询时不会返回过滤掉的行记录。
![image.png](Ranger权限管理.assets\9a940ba49c8f4dd48eb6044d0555eb5b.png)

<br>
## 3.2 HDFS权限管理
### 3.2.1 添加hdfs组件
![image.png](Ranger权限管理.assets7959551c514469db7b3b79798adb469.png)

### 3.2.2 使用Ranger对hdfs进行权限管理
![image.png](Ranger权限管理.assets485add2148c4b1da8e49a3a82a35f1d.png)

>注：因为配置了网页端代理用户hxr，所以单独使用没有什么效果，需要配合Kerberos使用。


<br>
# 四、整合Kerberos完成认证鉴权
以上配置的是通过LDAP完成认证，Ranger完成鉴权。
也可以通过Kerberos完成认证，Ranger完成鉴权。

如果Hadoop集群中已经配置了Kerberos安全认证，Ranger也可以与Kerberos配合使用完成用户的认证和权限控制。

**配置见文章:** [Kerberos认证管理](https://www.jianshu.com/writer#/notebooks/45459270/notes/90930960)

## 4.1 创建系统用户和Kerberos主题
Ranger的启动和运行需使用特定的用户，故须在Ranger所在节点创建所需系统用户并在Kerberos中创建所需主体。

1. 创建ranger系统用户
```
useradd ranger -G hadoop
echo ranger | passwd --stdin ranger
```
>参数-G表示创建的ranger同时属于hadoop组和ranger组。

2. 检查HTTP主体是否正常(该主体在Hadoop开启Kerberos时已创建)
```
kinit -kt /etc/security/keytab/spnego.service.keytab HTTP/bigdata1@IOTMARS.COM
```

3. 创建rangeradmin主体
   1）创建主体
   ```
   kadmin -padmin/admin -wPassword@123 -q "addprinc -randkey rangeradmin/bigdata1"
   ```
   2）生成keytab文件
   ```
   kadmin -padmin/admin -wPassword@123 -q "xst -k /etc/security/keytab/rangeradmin.keytab rangeradmin/bigdata1"
   ```
   3）修改keytab文件所有者
   ```
   chown ranger:ranger /etc/security/keytab/rangeradmin.keytab
   ```

4. 创建rangerlookup主体
   1）创建主体
   ```
   kadmin -padmin/admin -wPassword@123 -q "addprinc -randkey rangerlookup/bigdata1"
   ```
   2）生成keytab文件
   ```
   kadmin -padmin/admin -wPassword@123 -q "xst -k /etc/security/keytab/rangerlookup.keytab rangerlookup/bigdata1"
   ```
   3）修改keytab文件所有者
   ```
   chown ranger:ranger /etc/security/keytab/rangerlookup.keytab
   ```

5. 创建rangerusersync主体
   1）创建主体
   ```
   kadmin -padmin/admin -wPassword@123 -q "addprinc -randkey rangerusersync/bigdata1"
   ```
   2）生成keytab文件
   ```
   kadmin -padmin/admin -wPassword@123 -q "xst -k /etc/security/keytab/rangerusersync.keytab rangerusersync/bigdata1"
   ```
   3）修改keytab文件所有者
   ```
   chown ranger:ranger /etc/security/keytab/rangerusersync.keytab
   ```




## 4.2 安装和启动RangerAdmin
#### 安装RangerAdmin

①创建目录mkdir /opt/module/ranger-2.0.0
解压ranger-2.0.0-admin.tar.gz到该目录下

```
[root@bigdata1 ranger-2.0.0]# tar -zxvf /opt/software/ranger-2.0.0-admin.tar.gz -C /opt/module/ranger-2.0.0/
```

②配置文件install.properties

```
#mysql驱动
SQL_CONNECTOR_JAR=SQL_CONNECTOR_JAR=/opt/module/ranger-2.0.0/ranger-2.0.0-admin/mysql-connector-java-5.1.45.jar
#mysql的主机名和root用户的用户名密码
db_root_user=root
db_root_password=Password@123
db_host=192.168.101.174
#ranger需要的数据库名和用户信息，和2.2.1创建的信息要一一对应
db_name=ranger
db_user=ranger
db_password=bigdata123
#其他ranger admin需要的用户密码
rangerAdmin_password=bigdata123
rangerTagsync_password=bigdata123
rangerUsersync_password=bigdata123
keyadmin_password=bigdata123
#ranger存储审计日志的路径，默认为solr，这里为了方便暂不设置
audit_store=
#策略管理器的url,rangeradmin安装在哪台机器，主机名就为对应的主机名，不能写ip地址
policymgr_external_url=http://bigdata1:6080
#启动ranger admin进程的linux用户信息。会将目录所属用户改为ranger
unix_user=ranger
unix_user_pwd=ranger
unix_group=ranger
#hadoop的配置文件目录
hadoop_conf=/opt/module/hadoop-3.1.3/etc/hadoop

#Kerberos相关配置
spnego_principal=HTTP/bigdata1@IOTMARS.COM
spnego_keytab=/etc/security/keytab/spnego.service.keytab
token_valid=30
cookie_domain=
cookie_path=/
admin_principal=rangeradmin/bigdata1@IOTMARS.COM
admin_keytab=/etc/security/keytab/rangeradmin.keytab
lookup_principal=rangerlookup/bigdata1@IOTMARS.COM
lookup_keytab=/etc/security/keytab/rangerlookup.keytab
```

③在root用户下进行安装
```
[root@bigdata1 ranger-2.0.0-admin]# ./setup.sh
```
出现如下信息表示安装成功
```
2021-10-08 14:43:27,184  [I] Ranger all admins default password has already been changed!!
Installation of Ranger PolicyManager Web Application is completed.
```

> 注意：如果使用`sudo ./setup.sh`安装会找不到JAVA_HOME，但是使用`sudo echo ${JAVA_HOME}` 是可以正常打印的，很奇怪？？？

#### 启动Ranger Admin

安装时会自动将启动脚本放到/usr/bin目录下，同时根据配置的install.properties自动生成配置文件ranger-admin-site.xml。
执行链接命令时会将/etc/ranger/admin/conf目录链接到ews/webapp/WEB-INF/classes/conf目录。
也会将服务设为开机自启，所以无需我们设置开机自启。

但是自动生成的配置文件有两处错误，我们需要手动修改。

①修改配置文件 /etc/ranger/admin/conf/ranger-admin-site.xml

```
        <property>
                <name>ranger.jpa.jdbc.password</name>
                <value>bigdata123</value>
                <description />
        </property>
        <property>
                <name>ranger.service.host</name>
                <value>192.168.101.179</value>
        </property>
```

②启动和关闭RangerAdmin
使用ranger用户启动/关闭/重启 ranger-admin
```
[root@bigdata1 ranger-2.0.0-admin]# sudo -i -u ranger ranger-admin start/stop/restart
```

启动后其后台进程名为**EmbeddedServer**

③访问UI
管理员账号密码为admin/bigdata123
[http://192.168.101.179:6080](http://192.168.101.179:6080/)


访问路径还是为 http://192.168.101.179:6080/login.jsp
 
## 4.3 安装RangerUsersync
### 安装
RangerUsersync作为Ranger提供的一个管理模块，可以将Linux机器上的用户和组信息同步到RangerAdmin的数据库中进行管理。也可以同步LDAP等公司现有的用户框架体系中的用户到Ranger Admin中。

①解压

[root@bigdata1 ranger-2.0.0]# tar -zxvf /opt/software/ranger-2.0.0-usersync.tar.gz -C /opt/module/ranger-2.0.0/
②修改配置文件install.properties
这里既可以配置同步linux上的用户，也可以配置同步ldap上的用户

#### Ⅰ. 同步linux用户
```
#rangeradmin的url
POLICY_MGR_URL=http://192.168.101.179:6080
#同步linux用户
SYNC_SOURCE = unix
#同步间隔时间，单位(分钟)
SYNC_INTERVAL = 1
#运行此进程的linux用户
unix_user=hxr
unix_group=hxr
#rangerUserSync的用户密码，参考rangeradmin中install.properties的配置
rangerUsersync_password=bigdata123
#hadoop的配置文件目录
hadoop_conf=/opt/module/hadoop-3.1.3/etc/hadoop
#Kerberos相关配置
usersync_principal=rangerusersync/bigdata1@IOTMARS.COM
usersync_keytab=/etc/security/keytab/rangerusersync.keytab
```
>需要配置Kerberos。

#### Ⅱ. 同步ldap用户
```
#rangeradmin的url
POLICY_MGR_URL=http://192.168.101.179:6080
#运行此进程的linux用户
unix_user=ranger
unix_group=ranger
#rangerUserSync的用户密码，参考rangeradmin中install.properties的配置
rangerUsersync_password=bigdata123
#hadoop的配置文件目录
hadoop_conf=/opt/module/hadoop-3.1.3/etc/hadoop
#Kerberos相关配置
usersync_principal=rangerusersync/bigdata1@IOTMARS.COM
usersync_keytab=/etc/security/keytab/rangerusersync.keytab

# 日志保存路径
logdir=/opt/module/ranger-2.2.0/ranger-2.2.0-usersync/logs

# 同步ldap数据
## 同步的数据源类型，默认为unix，同步linux用户；这里配置为ldap，同步ldap用户
SYNC_SOURCE = ldap
## 同步时间，单位为min (不能小于60min)
SYNC_INTERVAL = 60 
## ldap地址
SYNC_LDAP_URL = ldap://192.168.101.174:389
## ldap管理员用户密码
SYNC_LDAP_BIND_DN = cn=admin,dc=ldap,dc=chenjie,dc=asia
SYNC_LDAP_BIND_PASSWORD = bigdata123
## 定义一个路径
SYNC_LDAP_SEARCH_BASE = ou=hive,dc=ldap,dc=chenjie,dc=asia

# PID保存路径
USERSYNC_PID_DIR_PATH=/var/run/ranger

# 同步用户
## 同步用户所在的路径，默认值为SYNC_LDAP_SEARCH_BASE
SYNC_LDAP_USER_SEARCH_BASE =
## 查找用户的范围，可选base/one/sub，默认为sub
SYNC_LDAP_USER_SEARCH_SCOPE = sub
## default value: person
SYNC_LDAP_USER_OBJECT_CLASS = person
## default value is empty
SYNC_LDAP_USER_SEARCH_FILTER =
## 用户名的属性，默认为 cn
SYNC_LDAP_USER_NAME_ATTRIBUTE = cn
##  default value is memberof,ismemberof
SYNC_LDAP_USER_GROUP_NAME_ATTRIBUTE = memberof,ismemberof
## possible values:  none, lower, upper
SYNC_LDAP_USERNAME_CASE_CONVERSION=lower
SYNC_LDAP_GROUPNAME_CASE_CONVERSION=lower

# 同步用户组
## 是否同步用户的所在组，默认值为 false
SYNC_GROUP_SEARCH_ENABLED=true
SYNC_GROUP_USER_MAP_SYNC_ENABLED=true

##  同步用户组所在的路径，默认值为SYNC_LDAP_SEARCH_BASE
SYNC_GROUP_SEARCH_BASE=
## default value: sub
SYNC_GROUP_SEARCH_SCOPE=
## default value: groupofnames
SYNC_GROUP_OBJECT_CLASS=posixGroup
## default value is empty
SYNC_LDAP_GROUP_SEARCH_FILTER=
## default value: cn
SYNC_GROUP_NAME_ATTRIBUTE=
## 组中的用户属性，默认为 member
SYNC_GROUP_MEMBER_ATTRIBUTE_NAME=memberUid
```
>在ldap中添加用户时，在Membership中指定用户组。

③在root用户下安装
./setup.sh

④修改配置文件 conf/ranger-ugsync-site.xml 
```
        <property>
                <name>ranger.usersync.enabled</name>
                <value>true</value>
        </property>
```

### 启动/关闭/重启
`sudo -i -u ranger ranger-usersync start/stop/restart`

ranger-usersync服务也是开机自启动的，因此之后不需要手动启动！

## 4.4 安装Ranger Hive-plugin
### 安装
①解压ranger-2.0.0-hive-plugin.tar.gz
```
[root@bigdata1 ranger-2.0.0]# tar -zxvf /opt/software/ranger-2.0.0-hive-plugin.tar.gz -C /opt/module/ranger-2.0.0
```
②修改配置文件inistall.propreties
```
#策略管理器的url地址
POLICY_MGR_URL=http://192.168.101.179:6080
#组件名称可以自定义
REPOSITORY_NAME=hivedev
#hive的安装目录
COMPONENT_INSTALL_DIR_NAME=/opt/module/hive-3.1.2
#hive组件的启动用户
CUSTOM_USER=hive
#hive组件启动用户所属组
CUSTOM_GROUP=hadoop
```

### 启动

```
[root@bigdata1 ranger-2.0.0-hive-plugin]# ./enable-hive-plugin.sh
```
>关闭hive插件命令为`./disable-hive-plugin.sh `，除了执行命令外，还需要删除hive配置文件目录下ranger相关的配置文件。

会在hive的conf目录下生成多个配置文件
- ranger-hive-audit.xml
- ranger-hive-security.xml
- ranger-policymgr-ssl.xml
- ranger-security.xml
- hiveserver2-site.xml
```
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?><!--
Licensed to the Apache Software Foundation (ASF) under one or more
contributor license agreements. See the NOTICE file distributed with
this work for additional information regarding copyright ownership.
The ASF licenses this file to You under the Apache License, Version 2.0
(the "License"); you may not use this file except in compliance with
the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--><configuration>
<property>
        <name>hive.security.authorization.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>hive.security.authorization.manager</name>
        <value>org.apache.ranger.authorization.hive.authorizer.RangerHiveAuthorizerFactory</value>
    </property>
    <property>
        <name>hive.security.authenticator.manager</name>
        <value>org.apache.hadoop.hive.ql.security.SessionStateUserAuthenticator</value>
    </property>
    <property>
        <name>hive.conf.restricted.list</name>
        <value>hive.security.authorization.enabled,hive.security.authorization.manager,hive.security.authenticator.manager</value>
    </property>
</configuration>
```
<br>
**重启hiveserver2生效**
```
[root@bigdata1 ranger-2.0.0-hive-plugin]# sudo -i -u hive nohup hiveserver2 1>/opt/module/hive-3.1.2/logs/hive-on-spark.log 2>/opt/module/hive-3.1.2/logs/hive-on-spark.err &
```

<br>
### 在ranger admin上配置hive插件
1. 授予hive用户在Ranger中的Admin角色
添加hive用户，并将hive用户的角色设置为Admin，组设置为hadoop。

2. 配置hive插件
![image.png](Ranger权限管理.assets\7d2c4abcc1fe4af5865bbc87f4e8402e.png)

此时点击Test Connection，会报错如下
```
Connection Failed.
Unable to retrieve any files using given parameters, You can still save the repository and start creating policies, but you would not be able to use autocomplete for resource names. Check ranger_admin.log for more info.

org.apache.ranger.plugin.client.HadoopException: Unable to execute SQL [show databases like "*"]..
Unable to execute SQL [show databases like "*"]..
Error while compiling statement: FAILED: HiveAccessControlException Permission denied: user [rangerlookup] does not have [USE] privilege on [Unknown resource!!].
Permission denied: user [rangerlookup] does not have [USE] privilege on [Unknown resource!!].
```
说明连接是正常的，只是没有访问权限（即是这个访问不通也没有影响，最终hiveserver2会拉取配置的规则缓存到本地目录下）。

配置访问规则即可，规则配置同上。


3. 添加访问权限


<br>
# 五、总结
## 5.1 UI和进程
UI界面：http://192.168.101.179:6080  （admin/bigdata123）

| 组件  | 进程名 | 启动命令 |
|---|---|---|
| Ranger Admin | EmbeddedServer | ranger-admin start/stop/restart  |
| RangerUsersync | UnixAuthenticationService(root用户可见) | ranger-usersync start/stop/restart(root用户下启动)  |

Hive Plugin启动命令： `./enable-hive-plugin.sh` `./disable-hive-plugin.sh`

## 5.2 异常
- 现象：使用Ranger的hive组件后报错
```
User: root is not allowed to impersonate root
```
- 原因：可能是root用户启动的Ranger Hive Plugin，该插件通过权限判断后最终提交任务时是以root用户提交的，所以hadoop需要允许root用户进行外部访问。
- 解决：core-site.xml中添加root代理
```
    <!-- 配置root允许通过代理访问主机节点 -->
    <property>
        <name>hadoop.proxyuser.root.hosts</name>
        <value>*</value>
    </property>
    <!-- 配置root允许通过代理用户所属组 -->
    <property>
        <name>hadoop.proxyuser.root.groups</name>
        <value>*</value>
    </property>
```

## 5.3 添加用户流程
### 5.3.1 创建Kerberos用户
为用户添加kerberos主体，设置密码
```
kadmin.local -q "addprinc chenjie"
```
导出keytab（如果希望导出keytab且密码不改变，需要在KDC所在节点执行如下命令）
```
kadmin.local -q "xst  -norandkey -k ./chenjie.keytab chenjie@IOTMARS.COM"
```

### 5.3.2 创建Ranger用户
如果配置了ranger-usersync插件，可以在对应的ldap中添加用户等待同步；也可以直接在Ranger UI中添加用户。
添加用户后为其设置对应的hive/hdfs权限。

### 5.3.3 beeline连接hiveserver2
首先需要在节点上认证身份
```
kinit chenjie
```
然后通过beeline连接
```
beeline -u "jdbc:hive2://bigdata1:10000/;principal=hive/bigdata1@IOTMARS.COM"
```

### 5.3.4 访问NameNode UI
安装Kerberos客户端，配置配置文件 C:\ProgramData\MIT\Kerberos5\krb5.ini
```
[libdefaults]
 dns_lookup_realm = false
 ticket_lifetime = 24h
 forwardable = true
 rdns = false
 default_realm = IOTMARS.COM

[realms]
 IOTMARS.COM = {
  kdc = 192.168.101.174
  admin_server = 192.168.101.174
 }

[domain_realm]
```
配置完成后，启动Kerberos客户端，认证用户；

最后配置火狐浏览器在访问bigdata1节点时使用Kerberos认证
```
about:config
network.negotiate-auth.trusted-uris = bigdata1
network.auth.use-sspi = false
```

### 5.3.5 DataGrip连接
#### 5.3.5.1 DataGrip客户端
DataGrip中的Hive连接驱动没有整合Kerberos认证，所以需要自定义Hive驱动。

#### 5.3.5.2 新建Driver
1. 创建Driver
![image.png](Ranger权限管理.assets\dabc053842474feb964bf0f713860e7b.png)

2. 配置Driver

![image.png](Ranger权限管理.assets51cf8c64f1a48ce80a249b8a34af196.png)


URL templates：`jdbc:hive2://{host}:{port}/{database}[;<;,{:identifier}={:param}>]`

#### 5.3.5.3 新建连接
1）基础配置
![image.png](Ranger权限管理.assets8bc793970b64b508e9582aef706f719.png)

url：`jdbc:hive2://bigdata1:10000/;principal=hive/bigdata1@IOTMARS.COM`


2）高级配置
![image.png](Ranger权限管理.assets\8ea60d23b1be43339824a94f43ab6a87.png)


配置参数：
```
-Djava.security.krb5.conf="C:\ProgramData\MIT\Kerberos5\krb5.ini"
-Djava.security.auth.login.config="C:\ProgramData\MIT\Kerberos5\chenjie.conf"
-Djavax.security.auth.useSubjectCredsOnly=false
```

3）编写JAAS（Java认证授权服务）配置文件chenjie.conf，内容如下，文件名和路径须和上图中java.security.auth.login.config参数的值保持一致。
```
com.sun.security.jgss.initiate{
      com.sun.security.auth.module.Krb5LoginModule required
      useKeyTab=true
      useTicketCache=false
      keyTab="C:\ProgramData\MIT\Kerberos5\chenjie.keytab"
      principal="hxr@IOTMARS.COM";
};
```

4）将第一步生成的chenjie.keytab文件放到chenjie.conf中配置的keytab的路径下

5）测试连接



<br>
# 六、Ranger整合LDAP
在原先的基础上，继续修改ranger的配置文件ranger-admin-site.xml
```
authentication_method=LDAP
xa_ldap_url=ldap://192.168.101.174:389
xa_ldap_userDNpattern=uid={0},ou=hive,dc=ldap,dc=chenjie,dc=asia
xa_ldap_groupSearchBase=
xa_ldap_groupSearchFilter=
xa_ldap_groupRoleAttribute=
xa_ldap_base_dn=ou=hive,dc=ldap,dc=chenjie,dc=asia
xa_ldap_bind_dn=cn=admin,dc=ldap,dc=chenjie,dc=asia
xa_ldap_bind_password=bigdata123
xa_ldap_referral=
xa_ldap_userSearchFilter=
```
在root用户下 ./setup.sh 进行安装，然后重启 `ranger-admin restart`。
在配置文件中配置的admin的密码仍然有效，登录后仍然是管理员用户。ldap中的用户也可以进行登陆，这些都是普通用户。

<br>
# 七、总结
至此完成了一下功能
1. 通过ranger来对hiveserver2的权限进行验证
2. usersync组件定时同步LDAP的hive用户到Ranger中
3. Ranger的UI可以使用LDAP的ranger组的用户进行登陆

Hive整合LDAP进行登陆认证，翻看文章 [LDAP](https://www.jianshu.com/writer#/notebooks/45459270/notes/91146529)

<br>
# 参考
[详细信息可以浏览官网](Row-level+filtering+and+column-masking+using+Apache+Ranger+policies+in+Apache+Hive)
[usersync for ldap](https://issues.apache.org/jira/browse/RANGER-2406)
[ranger 配置(如LDAP验证登陆)](https://cwiki.apache.org/confluence/display/RANGER/Apache+Ranger+0.5.0+Installation)
