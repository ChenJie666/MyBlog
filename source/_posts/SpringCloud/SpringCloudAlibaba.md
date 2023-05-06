---
title: SpringCloudAlibaba
categories:
- SpringCloud
---
![image.png](SpringCloudAlibaba.assets\115f58f75aff40b7b3a9065c1f513999.png)

#SpringCloudAlibaba
nacos支持AP和CP的切换。

一般来说，如果不需要存储服务级别的信息且服务实例是通过nacos-client注册，并能够保持心跳上报，那么就可以选择AP模式。当前主流的服务如SpringCloud和Dubbo服务，都适用于AP模式，AP模式为了服务的可能性而减弱了一致性，因此AP模式下只支持注册临时实例。

如果需要在服务级别编辑或存储配置信息，那么CP是必须的，K8S服务和DNS服务则适用于CP模式。
CP模式下则支持持久化实例，此时是以Raft协议为集群运行模式，该模式下注册实例之前必须先注册服务，如果服务不存在，会返回错误。

以cp模式启动nacos
curl -X PUT "$NACOS_SERVER:8848/nacos/v1/ns/operator/switches?entry=serverMode&value=CP"

```
<dependencyManagement>
<dependency>
        <groupId>com.alibaba.cloud</groupId>
        <artifactId>spring-cloud-alibaba-dependencies</artifactId>
        <version>2.1.0.RELEASE</version>
        <type>pom</type>
        <scope>import</scope>
</dependencyManagement>
```
***组件包括***
- Sentinel：
- Nacos：动态服务发现、配置管理和服务管理平台
- RocketMQ：基于java的高性能分布式消息和流计算平台
- Dubbo：高性能Java RPC框架
- Seata：高性能微服务分布式事务解决方案
- Alibaba Cloud OSS：对象存储服务
- Alibaba Cloud SchedulerX：分布式任务调度中间件，支持周期性的任务与固定时间点触发任务

###Nacos（Naming&Configuration Service）
Nacos = Eureka + Config + Bus
Nacoss和Eureka一样是AP（Availabiity、Partition tolerance）

方式一：
通过docker部署
拉取镜像
docker pull nacos/nacos-server:1.2.1
挂载目录
mkdir -p /root/nacos/logs/                      #新建logs目录
mkdir -p /root/nacos/init.d/          
启动容器
docker  run \
--name nacos -d \
-p 8848:8848 \
--privileged=true \
--restart=always \
-e JVM_XMS=256m \
-e JVM_XMX=256m \
-e MODE=standalone \
-e PREFER_HOST_MODE=hostname \
-v /root/nacos/logs:/home/nacos/logs \
-v /root/nacos/init.d:/home/nacos/init.d \
nacos/nacos-server

方式二：
通过docker-compose部署,包含prometheus/grafana等监控组件
1.拉取仓库
git clone --depth 1 https://github.com/nacos-group/nacos-docker.git
2.运行docker-compose
cd nacos-docker
docker-compose -f example/standalone-derby.yaml up -d 

启动之后通过http://116.62.148.11:8848/nacos访问UI界面，默认账号密码都为nacos

***依赖***
<dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-nacos-discovery</artifactId>
</dependency>
***配置***
spring:
  application:
    name: nacos-payment-provider
  cloud:
    nacos:
      discovery:
        server-addr: http://116.62.148.11:8848/  #配置Nacos地址

management:
  endpoints:
    web:
      exposure:
        include: "*"
***注解***
@EnableDiscoveryClient

![已注册的服务](SpringCloudAlibaba.assets99a9d836ba34f2f85c0b4743c8ef325.png)

###RestTemplate请求实现负载均衡
编写消费者模块，注册到nacos，通过RestTemplate对象请求微服务
***依赖***
Nacos已经集成Ribbon组价，可以实现负载均衡。
***配置***
无配置
***注解***
在注入RestTemplate的方法上添加@LoadBalance注解


###Nacos作为配置中心服务和总线服务
***依赖***
<dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-alibaba-nacos-config</artifactId>
</dependency>
***配置***
- bootstrap.yml配置
```
# nacos配置
server:
  port: 3377

spring:
  application:
    name: nacos-config-client
  cloud:
    nacos:
      discovery:
        server-addr: http://116.62.148.11:8848/  #Nacos服务注册中心地址，最后需要加 / 符号。
      config:
        server-addr: http://116.62.148.11:8848 #Nacos作为配置中心地址，最后一定不能加 / 符号。
        file-extension: yaml #指定yaml格式的配置
        group: DEFAULT_GROUP #指定分组
        # namespace: cf64e8f5-a429-4ad5-a10c-f23ec3c62849  #指定命名空间ID，缺省是public保留空间。
```
- application.yml配置
```
spring:
  profiles:
    active: dev #表示开发环境
```
***注解***
在controller类上添加@RefreshScope注解，支持Nacos的配置动态刷新功能

***配置文件***
配置文件在Nacos的UI中填写，文件名格式为\${prefix}-\${spring.profile.active}.\${file-extension} , 如nacos-config-client-dev.yml ; 会同时读取nacos-config-client.yml配置文件的内容，如果两个配置文件内容冲突，nacos-config-client-dev.yml的配置优先级最高。

***Nacos中配置文件的三级目录：Namespace、Group和DataID***
默认Namespace=public，Group=DEFAULT_GROUP，DataID是配置文件名，默认Cluster是DEFAULT。

![image.png](SpringCloudAlibaba.assets\2de928a925da4f03baaebc285088bf80.png)

- Namespace用于隔离不同的环境，如开发、测试、生存环境等。
- Group可以把不同的微服务划分到同一个分组中。如可以给杭州机房的Service微服务起集群名为HZ，给广州机房的Service微服务起集群名为GZ，还可以尽量让同一个机房的微服务互相调用，提升性能。
- 最后是Instance，就是微服务的实例。

###Nacos的集群配置和持久化
#####持久化
默认Nacos使用内置数据库derby数据库。如果启动多个Nacos节点会有一致性问题。可以通过Nacos采用了集中式存储的方式来支持集群化部署，目前只支持MySQL。

***数据库建表语句***
```sql
/******************************************/
/*   数据库全名 = nacos_config   */
/*   表名称 = config_info   */
/******************************************/
CREATE TABLE `config_info` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `data_id` varchar(255) NOT NULL COMMENT 'data_id',
  `group_id` varchar(255) DEFAULT NULL,
  `content` longtext NOT NULL COMMENT 'content',
  `md5` varchar(32) DEFAULT NULL COMMENT 'md5',
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间',
  `src_user` text COMMENT 'source user',
  `src_ip` varchar(20) DEFAULT NULL COMMENT 'source ip',
  `app_name` varchar(128) DEFAULT NULL,
  `tenant_id` varchar(128) DEFAULT '' COMMENT '租户字段',
  `c_desc` varchar(256) DEFAULT NULL,
  `c_use` varchar(64) DEFAULT NULL,
  `effect` varchar(64) DEFAULT NULL,
  `type` varchar(64) DEFAULT NULL,
  `c_schema` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_configinfo_datagrouptenant` (`data_id`,`group_id`,`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='config_info';

/******************************************/
/*   数据库全名 = nacos_config   */
/*   表名称 = config_info_aggr   */
/******************************************/
CREATE TABLE `config_info_aggr` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `data_id` varchar(255) NOT NULL COMMENT 'data_id',
  `group_id` varchar(255) NOT NULL COMMENT 'group_id',
  `datum_id` varchar(255) NOT NULL COMMENT 'datum_id',
  `content` longtext NOT NULL COMMENT '内容',
  `gmt_modified` datetime NOT NULL COMMENT '修改时间',
  `app_name` varchar(128) DEFAULT NULL,
  `tenant_id` varchar(128) DEFAULT '' COMMENT '租户字段',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_configinfoaggr_datagrouptenantdatum` (`data_id`,`group_id`,`tenant_id`,`datum_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='增加租户字段';


/******************************************/
/*   数据库全名 = nacos_config   */
/*   表名称 = config_info_beta   */
/******************************************/
CREATE TABLE `config_info_beta` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `data_id` varchar(255) NOT NULL COMMENT 'data_id',
  `group_id` varchar(128) NOT NULL COMMENT 'group_id',
  `app_name` varchar(128) DEFAULT NULL COMMENT 'app_name',
  `content` longtext NOT NULL COMMENT 'content',
  `beta_ips` varchar(1024) DEFAULT NULL COMMENT 'betaIps',
  `md5` varchar(32) DEFAULT NULL COMMENT 'md5',
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间',
  `src_user` text COMMENT 'source user',
  `src_ip` varchar(20) DEFAULT NULL COMMENT 'source ip',
  `tenant_id` varchar(128) DEFAULT '' COMMENT '租户字段',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_configinfobeta_datagrouptenant` (`data_id`,`group_id`,`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='config_info_beta';

/******************************************/
/*   数据库全名 = nacos_config   */
/*   表名称 = config_info_tag   */
/******************************************/
CREATE TABLE `config_info_tag` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `data_id` varchar(255) NOT NULL COMMENT 'data_id',
  `group_id` varchar(128) NOT NULL COMMENT 'group_id',
  `tenant_id` varchar(128) DEFAULT '' COMMENT 'tenant_id',
  `tag_id` varchar(128) NOT NULL COMMENT 'tag_id',
  `app_name` varchar(128) DEFAULT NULL COMMENT 'app_name',
  `content` longtext NOT NULL COMMENT 'content',
  `md5` varchar(32) DEFAULT NULL COMMENT 'md5',
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间',
  `src_user` text COMMENT 'source user',
  `src_ip` varchar(20) DEFAULT NULL COMMENT 'source ip',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_configinfotag_datagrouptenanttag` (`data_id`,`group_id`,`tenant_id`,`tag_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='config_info_tag';

/******************************************/
/*   数据库全名 = nacos_config   */
/*   表名称 = config_tags_relation   */
/******************************************/
CREATE TABLE `config_tags_relation` (
  `id` bigint(20) NOT NULL COMMENT 'id',
  `tag_name` varchar(128) NOT NULL COMMENT 'tag_name',
  `tag_type` varchar(64) DEFAULT NULL COMMENT 'tag_type',
  `data_id` varchar(255) NOT NULL COMMENT 'data_id',
  `group_id` varchar(128) NOT NULL COMMENT 'group_id',
  `tenant_id` varchar(128) DEFAULT '' COMMENT 'tenant_id',
  `nid` bigint(20) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`nid`),
  UNIQUE KEY `uk_configtagrelation_configidtag` (`id`,`tag_name`,`tag_type`),
  KEY `idx_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='config_tag_relation';

/******************************************/
/*   数据库全名 = nacos_config   */
/*   表名称 = group_capacity   */
/******************************************/
CREATE TABLE `group_capacity` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `group_id` varchar(128) NOT NULL DEFAULT '' COMMENT 'Group ID，空字符表示整个集群',
  `quota` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '配额，0表示使用默认值',
  `usage` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '使用量',
  `max_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '单个配置大小上限，单位为字节，0表示使用默认值',
  `max_aggr_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '聚合子配置最大个数，，0表示使用默认值',
  `max_aggr_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '单个聚合数据的子配置大小上限，单位为字节，0表示使用默认值',
  `max_history_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '最大变更历史数量',
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_group_id` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='集群、各Group容量信息表';

/******************************************/
/*   数据库全名 = nacos_config   */
/*   表名称 = his_config_info   */
/******************************************/
CREATE TABLE `his_config_info` (
  `id` bigint(64) unsigned NOT NULL,
  `nid` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `data_id` varchar(255) NOT NULL,
  `group_id` varchar(128) NOT NULL,
  `app_name` varchar(128) DEFAULT NULL COMMENT 'app_name',
  `content` longtext NOT NULL,
  `md5` varchar(32) DEFAULT NULL,
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `src_user` text,
  `src_ip` varchar(20) DEFAULT NULL,
  `op_type` char(10) DEFAULT NULL,
  `tenant_id` varchar(128) DEFAULT '' COMMENT '租户字段',
  PRIMARY KEY (`nid`),
  KEY `idx_gmt_create` (`gmt_create`),
  KEY `idx_gmt_modified` (`gmt_modified`),
  KEY `idx_did` (`data_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='多租户改造';


/******************************************/
/*   数据库全名 = nacos_config   */
/*   表名称 = tenant_capacity   */
/******************************************/
CREATE TABLE `tenant_capacity` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `tenant_id` varchar(128) NOT NULL DEFAULT '' COMMENT 'Tenant ID',
  `quota` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '配额，0表示使用默认值',
  `usage` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '使用量',
  `max_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '单个配置大小上限，单位为字节，0表示使用默认值',
  `max_aggr_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '聚合子配置最大个数',
  `max_aggr_size` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '单个聚合数据的子配置大小上限，单位为字节，0表示使用默认值',
  `max_history_count` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '最大变更历史数量',
  `gmt_create` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `gmt_modified` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='租户容量信息表';


CREATE TABLE `tenant_info` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `kp` varchar(128) NOT NULL COMMENT 'kp',
  `tenant_id` varchar(128) default '' COMMENT 'tenant_id',
  `tenant_name` varchar(128) default '' COMMENT 'tenant_name',
  `tenant_desc` varchar(256) DEFAULT NULL COMMENT 'tenant_desc',
  `create_source` varchar(32) DEFAULT NULL COMMENT 'create_source',
  `gmt_create` bigint(20) NOT NULL COMMENT '创建时间',
  `gmt_modified` bigint(20) NOT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tenant_info_kptenantid` (`kp`,`tenant_id`),
  KEY `idx_tenant_id` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin COMMENT='tenant_info';

CREATE TABLE `users` (
	`username` varchar(50) NOT NULL PRIMARY KEY,
	`password` varchar(500) NOT NULL,
	`enabled` boolean NOT NULL
);

CREATE TABLE `roles` (
	`username` varchar(50) NOT NULL,
	`role` varchar(50) NOT NULL,
	UNIQUE INDEX `idx_user_role` (`username` ASC, `role` ASC) USING BTREE
);

CREATE TABLE `permissions` (
    `role` varchar(50) NOT NULL,
    `resource` varchar(512) NOT NULL,
    `action` varchar(8) NOT NULL,
    UNIQUE INDEX `uk_role_permission` (`role`,`resource`,`action`) USING BTREE
);

INSERT INTO users (username, password, enabled) VALUES ('nacos', '$2a$10$EuWPZHzz32dJN7jexM34MOeYirDdFAZm2kuWj7VEOJhhZkDrxfvUu', TRUE);

INSERT INTO roles (username, role) VALUES ('nacos', 'ROLE_ADMIN');
```
***nacos配置文件custom.properties***
```
#*************** Spring Boot Related Configurations ***************#
### Default web context path:
server.servlet.contextPath=/nacos
### Default web server port:
server.port=8848

#*************** Network Related Configurations ***************#
### If prefer hostname over ip for Nacos server addresses in cluster.conf:
# nacos.inetutils.prefer-hostname-over-ip=false

### Specify local server's IP:
# nacos.inetutils.ip-address=

#*************** Config Module Related Configurations ***************#
### If user MySQL as datasource:
# spring.datasource.platform=mysql

### Count of DB:
# db.num=1

### Connect URL of DB:
# db.url.0=jdbc:mysql://1.1.1.1:3306/nacos?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true
# db.user=user
# db.password=password
spring.datasource.platform=mysql

db.num=1
db.url.0=jdbc:mysql://116.62.148.11:3306/nacos_config?characterEncoding=utf8&connectTimeout=1000&socketTimeout=3000&autoReconnect=true
db.user=root
db.password=abc123

#*************** Naming Module Related Configurations ***************#
### Data dispatch task execution period in milliseconds:
# nacos.naming.distro.taskDispatchPeriod=200

### Data count of batch sync task:
# nacos.naming.distro.batchSyncKeyCount=1000

### Retry delay in milliseconds if sync task failed:
# nacos.naming.distro.syncRetryDelay=5000

### If enable data warmup. If set to false, the server would accept request without local data preparation:
# nacos.naming.data.warmup=true

### If enable the instance auto expiration, kind like of health check of instance:
# nacos.naming.expireInstance=true

### If enable the empty service auto clean, services with an empty instance are automatically cleared
nacos.naming.empty-service.auto-clean=false
### The empty service cleanup task delays startup time in milliseconds
nacos.naming.empty-service.clean.initial-delay-ms=60000
### The empty service cleanup task cycle execution time in milliseconds
nacos.naming.empty-service.clean.period-time-ms=20000

#*************** CMDB Module Related Configurations ***************#
### The interval to dump external CMDB in seconds:
# nacos.cmdb.dumpTaskInterval=3600

### The interval of polling data change event in seconds:
# nacos.cmdb.eventTaskInterval=10

### The interval of loading labels in seconds:
# nacos.cmdb.labelTaskInterval=300

### If turn on data loading task:
# nacos.cmdb.loadDataAtStart=false

#*************** Metrics Related Configurations ***************#
### Metrics for prometheus
#management.endpoints.web.exposure.include=*

### Metrics for elastic search
management.metrics.export.elastic.enabled=false
#management.metrics.export.elastic.host=http://localhost:9200

### Metrics for influx
management.metrics.export.influx.enabled=false
#management.metrics.export.influx.db=springboot
#management.metrics.export.influx.uri=http://localhost:8086
#management.metrics.export.influx.auto-create-db=true
#management.metrics.export.influx.consistency=one
#management.metrics.export.influx.compressed=true

#*************** Access Log Related Configurations ***************#
### If turn on the access log:
server.tomcat.accesslog.enabled=true

### The access log pattern:
server.tomcat.accesslog.pattern=%h %l %u %t "%r" %s %b %D %{User-Agent}i

### The directory of access log:
server.tomcat.basedir=

#*************** Access Control Related Configurations ***************#
### If enable spring security, this option is deprecated in 1.2.0:
#spring.security.enabled=false

### The ignore urls of auth, is deprecated in 1.2.0:
nacos.security.ignore.urls=/,/error,/**/*.css,/**/*.js,/**/*.html,/**/*.map,/**/*.svg,/**/*.png,/**/*.ico,/console-fe/public/**,/v1/auth/**,/v1/console/health/**,/actuator/**,/v1/console/server/**

### The auth system to use, currently only 'nacos' is supported:
nacos.core.auth.system.type=nacos

### If turn on auth system:
nacos.core.auth.enabled=false

### The token expiration in seconds:
nacos.core.auth.default.token.expire.seconds=18000

### The default token:
nacos.core.auth.default.token.secret.key=SecretKey012345678901234567890123456789012345678901234567890123456789

### Turn on/off caching of auth information. By turning on this switch, the update of auth information would have a 15 seconds delay.
nacos.core.auth.caching.enabled=false

#*************** Istio Related Configurations ***************#
### If turn on the MCP server:
nacos.istio.mcp.server.enabled=false
```

重启后Nacos会将内部数据库的数据同步到MySQL中。

#####集群部署
***配置文件***


***通过Nginx负载均衡***
```
upstream nacoses {
    server 192.168.32.128:8848;
}

server {
    listen 80;
    server_name nacos.com;

    location /nacos {
        proxy_next_upstream http_502 http_504 error timeout invalid_header;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Accept-Encoding "";
        proxy_set_header Accept-Language "zh-CN";
        proxy_pass http://nacoses;
    }

    access_log  /var/log/nginx/nacos_access.log main;
    error_log   /var/log/nginx/nacos_error.log;
}
```

***启动容器***
docker网络模式指定为host模式，Host 模式并没有为容器创建一个隔离的网络环境。而之所以称之为host模式，是因为该模式下的 Docker 容器会和 host 宿主机共享同一个网络 namespace，故 Docker Container可以和宿主机一样，使用宿主机的eth0，实现和外界的通信。换言之，Docker Container的 IP 地址即为宿主机 eth0 的 IP 地；

docker run --name nacos  --net=host --env MODE=cluster --env NACOS_SERVERS=192.168.32.128:8848,192.168.32.128:8849,192.168.32.128:8850 --env MYSQL_DATABASE_NUM=1 --env MYSQL_SERVICE_HOST=116.62.148.11 --env MYSQL_SERVICE_PORT=3306 --env MYSQL_SERVICE_DB_NAME=nacos_config --env MYSQL_SERVICE_USER=root --env MYSQL_SERVICE_PASSWORD=abc123 --env NACOS_SERVER_PORT=8848 -v /root/nacos/logs:/home/nacos/logs -d nacos/nacos-server

docker run --name nacos1  --net=host --env MODE=cluster --env NACOS_SERVERS=192.168.32.128:8848,192.168.32.128:8849,192.168.32.128:8850 --env MYSQL_DATABASE_NUM=1 --env MYSQL_SERVICE_HOST=116.62.148.11 --env MYSQL_SERVICE_PORT=3306 --env MYSQL_SERVICE_DB_NAME=nacos_config --env MYSQL_SERVICE_USER=root --env MYSQL_SERVICE_PASSWORD=abc123 --env NACOS_SERVER_PORT=8849 -v /root/nacos/logs1:/home/nacos/logs -d nacos/nacos-server

docker run --name nacos2  --net=host --env MODE=cluster --env NACOS_SERVERS=192.168.32.128:8848,192.168.32.128:8849,192.168.32.128:8850 --env MYSQL_DATABASE_NUM=1 --env MYSQL_SERVICE_HOST=116.62.148.11 --env MYSQL_SERVICE_PORT=3306 --env MYSQL_SERVICE_DB_NAME=nacos_config --env MYSQL_SERVICE_USER=root --env MYSQL_SERVICE_PASSWORD=abc123 --env NACOS_SERVER_PORT=8850 -v /root/nacos/logs2:/home/nacos/logs -d nacos/nacos-server


#Sentinel
Sentinal是独立的组件，通过界面化的细粒度统一配置。可以适配多种生态，如SpringCloud、redis、MQ、nacos、zookeeper等。
![image.png](SpringCloudAlibaba.assets5dcf27d10594532917c7e56c9300553.png)


***部署***
docker pull bladex/sentinel-dashboard
docker run --name sentinel  -d -p 8858:8858 -d  bladex/sentinel-dashboard

***依赖***
<dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-starter-alibaba-sentinel</artifactId>
</dependency>
<!-- 数据持久化 -->
<dependency>
            <groupId>com.alibaba.csp</groupId>
            <artifactId>sentinel-datasource-nacos</artifactId>
</dependency>
***配置***
```
spring:
  application:
    name: cloudalibaba-sentinel-service
  cloud:
    nacos:
      discovery:
        server-addr: 192.168.32.128:8848
    sentinel:
      transport:
        dashboard: 192.168.32.128:8858
        #簇点链路端口，默认8719端口，假如被占用会自动从8719开始依次+1扫描，直至找到未占用的端口
        port: 8719

#开放所有路径用于图形化展示，默认只开放了info、health两个端点
management:
  endpoints:
    web:
      exposure:
        include: '*'
```
***注解***

#####流量控制模式
![image.png](SpringCloudAlibaba.assets2fd8b73424e46f59f2f822105592c41.png)
***阈值类型***
- QPS：每秒钟的请求数量
- 线程数：调用该api的线程数达到阈值的时候，进行限流
***流控模式***
- 直接：api达到限流条件时，直接限流
- 关联：当关联的资源达到阈值时，就限流自己。如支付接口资源达到阈值，限流订单接口。
- 链路：只记录指定链路上的流量（指定资源从入口资源进来的流量，如果达到阈值，就进行限流）
***流控效果***
- 快速失败：直接失败，抛异常
- Warm Up：根据codeFactor（冷加载因子，默认为3）的值，从阈值/codeFactor，经过设置的预热时长，才达到设置的QPS阈值。
- 排队等待：限流后不会将多余的请求直接失败，而是排队消费。

如果被限流，就会返回错误信息：Blocked by Sentinel (flow limiting)；需要后续添加fallback方法进行异常处理。

#####降级模式
![image.png](SpringCloudAlibaba.assets\16a77a9054e24d4fbfd7dc00d0dac64f.png)
Sentinel与Hystrix不同的是，Sentinel断路器没有半开状态，过了时间窗口就会关闭断路器，正常接收请求。
***平均响应时间（RT）***
平均响应时间 超出阈值 且 QPS >=5 ，满足这两个条件后触发降级，在窗口期过后关闭断路器。
RT最大为4900（更大的需要通过-Dcsp.sentinel.statistic.max.rt=XXXX才能生效）
***异常比例***
QPS >=5 且 异常比例（秒级统计）超过阈值时，触发降级；时间窗口结束后，关闭降级。
***异常数***
当资源近1分钟的异常数目超过阈值之后会进行熔断。统计时间窗口是分钟级别的，若timewindow小于60秒，则结束熔断状态后仍可能再进入熔断状态。

#####热点key规则
对携带指定参数的请求进行限流并降级处理。
![image.png](SpringCloudAlibaba.assets\5c5c01c286c94b339b0b0e26b7b47787.png)
***依赖***

***注解***
@SentinelResource(value = "testHotKey",blockHandler = "testHotKey_Handler")  value唯一表示该热点规则，blockHandler指定fallback方法。
***接口方法***
```java
    /**
     * 热点规则管理的接口
     */
    @GetMapping("/testHotKey")
    @SentinelResource(value = "testHotKey",blockHandler = "testHotKey_Handler")
    public String testHotKey(@RequestParam(value = "p1", required = false) String p1, @RequestParam(value = "p2", required = false) String p2) {
        return "-----testHotKey";
    }

    /**
     * fallback方法
     */
    public String testHotKey_Handler(String p1, String p2, BlockException exception){
        return "-----testHotKey_Handler,o(π_π)o";
    }
```
***Sentinel配置***
![image.png](SpringCloudAlibaba.assets\32ea9774fd0a4a10ba1ceff9578a9704.png)
对value为testHotKey的接口进行请求，且存在参数p1的请求会进行限流。

***参数例外项***
当参数为某些固定值时，改变原有的限流规则。
![image.png](SpringCloudAlibaba.assets\300e81b80d64483a94d426420d9c8ca0.png)
当第一个参数值为cj时，改变限流阈值为3。

*注意*
@SentinelResource注解处理的是Sentinel控制台配置的违规情况，用blockHandler方法进行兜底处理。
@RuntimeException是java运行时异常，@SentinelResource中配置的兜底方法不会生效。
即热点规则不对代码运行异常进行限流和降级。

#####系统规则
![image.png](SpringCloudAlibaba.assets\16fe62d102eb403d83042084579c6c24.png)
从整个系统的负载（参考值为核数cores*2.5）、平均响应时间、线程数、入口QPS、CPU使用率方面进行请求的限流。

#####SentinelResource注解接口
- 规则异常处理
***接口***
```java
@GetMapping("/byResource")
@SentinelResource(value = "byResource",
       blockHandlerClass = CustomerBlockHandler.class,
       blockHandler = "handlerException2")
public CommonResult byResource(){
       return new CommonResult(200, "按资源名称限流测试OK", new Payment(2020L, "serial001"));
}
```
***定义全局方法***
```java
public class CustomerBlockHandler {
    public static CommonResult handlerException(BlockException exception) {
        return new CommonResult(4444, "按客户自定义，global handlerException-----1");
    }

    public static CommonResult handlerException2(BlockException exception) {
        return new CommonResult(4444, "按客户自定义，global handlerException-----2");
    }
}
```
*必须是静态方法*

- 代码异常处理
```java
    @GetMapping("/byResource/{id}")
    @SentinelResource(value = "byResource",fallback = "handlerFallback")
    public CommonResult byResource(@PathVariable Long id) {
        if (id == 4) {
            throw new RuntimeException("代码异常");
        }
        return new CommonResult(200, "按资源名称限流测试OK", new Payment(id, "serial001"));
    }

    public CommonResult handlerFallback(@PathVariable Long id, Throwable e) {
        Payment payment = new Payment(id, "null");
        return new CommonResult(444, "fallback异常内容：" + e.getMessage(), payment);
    }
```
*可以处理规则异常，也可以处理代码异常*

- 代码异常和规则异常处理
```java
@GetMapping("/byResource/{id}")
@SentinelResource(value = "byResource",
        blockHandlerClass = CustomerBlockHandler.class,
        blockHandler = "handlerException",
        fallback = "handlerFallback")
public CommonResult byResource(@PathVariable Long id) {
    if (id == 4) {
        throw new RuntimeException("代码异常");
    }
    return new CommonResult(200, "按资源名称限流测试OK", new Payment(id, "serial001"));
}

public CommonResult handlerException(@PathVariable Long id,BlockException exception) {
    return new CommonResult(444, exception.getClass().getCanonicalName() + "	 服务不可用");
}

public CommonResult handlerFallback(@PathVariable Long id, Throwable e) {
    Payment payment = new Payment(id, "null");
    return new CommonResult(444, "fallback异常内容：" + e.getMessage(), payment);
}
```

- 忽略某种异常
@SentinelResource(value = "byResource", exceptionsToIgnore = {IllegalArgumentException.class})
发生该异常时不再进行降级。

*注意*
Sentinel中定义规则时资源名必须要与@SentinelResource的value属性一致。


###Sentinel整合ribbon+openFeign+fallback

***依赖***
<dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
***配置***
#激活Sentinel对Feign的支持
feign:
  sentinel:
    enabled: true
***注解***
主启动类上添加@EnableFeignClients注解
Service层通过@FeignClient(value = "nacos-payment-provider",fallback = PaymentFallbackService.class)对生产者微服务进行访问，并使用默认的负载均衡策略。
***代码***
```java
//TODO 消费者接口类
@RestController
public class FeignController {

    @Resource
    private PaymentService paymentService;

    @GetMapping("/consumer/paymentSQL/{id}")
    public CommonResult<Payment> paymentSQL(@PathVariable("id") Long id) {
        return paymentService.getPayment(id);
    }
}

//通过Feign对微服务进行访问
@FeignClient(value = "nacos-payment-provider",fallback = PaymentFallbackService.class) //fallback方法进行兜底
public interface PaymentService {

    @GetMapping(value = "/payment/nacos/{id}")
    public CommonResult<Payment> getPayment(@PathVariable("id") Long id);

}

//Feign的异常处理类
@Component
public class PaymentFallbackService implements PaymentService {
    @Override
    public CommonResult<Payment> getPayment(Long id) {
        return new CommonResult<>(44444,"服务降级返回，---PaymentFallbackService",new Payment(id,"errorSerial"));
    }
}
```


###Sentinel规则的持久化
一旦重启应用，sentinel的规则就会消失，生产环境中需要将配置规则进行持久化。将限流规则持久化进Nacos保存，只要刷新8401某个rest地址，sentinel控制台的流控规则就能看到，只要Nacos里面的配置不删除，针对8401上的sentinel上的流控规则持续有效。

***依赖***
<dependency>
            <groupId>com.alibaba.csp</groupId>
            <artifactId>sentinel-datasource-nacos</artifactId>
</dependency>
***配置***
- 项目配置
```
spring:
  application:
    name: cloudalibaba-sentinel-service
  cloud:
    nacos:
      discovery:
        server-addr: 192.168.32.128:8848
    sentinel:
      transport:
        dashboard: 192.168.32.128:8858
        #默认8719端口，假如被占用会自动从8719开始依次+1扫描，直至找到未占用的端口
        port: 8719
      datasource:
        ds1:
          nacos:
            server-addr: 192.168.32.128:8848
            dataId: cloudalibaba-sentinel-service 
            groupId: DEFAULT_GROUP
            data-type: json
            rule-type: flow
```
- Nacos配置
在配置管理中发布配置，DataID和Group分别和配置文件中的配置对应，配置格式为JSON。配置内容如下：
```json
[
    {
        "resource":"byResource",
        "limitApp":"default",
        "grade":1,
        "count":1,
        "strategy":0,
        "controlBehavior":0,
        "clusterMode":false
    }
]
```
resource：资源名称；
limitApp：来源应用；
grade：阈值类型，0表示线程数，1表示QPS；
count：单机阈值；
strategy：流控模式，0表示直接，1表示关联，2表示链路；
controlBehavior：流控效果，0表示快速失败，1表示Warm Up，2表示排队等待；
clusterMode：是否是集群；


每次项目注册到sentinel时都会从Nacos中获取该项目对应的访问规则。
