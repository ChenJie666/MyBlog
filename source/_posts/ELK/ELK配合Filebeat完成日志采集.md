---
title: ELK配合Filebeat完成日志采集
categories:
- ELK
---
# 一、组件介绍
## 1.1 Filebeat

Filebeat是本地文件的日志数据采集器，可监控日志目录或特定日志文件（tail file），并将它们转发给Elasticsearch或Logstatsh进行索引、kafka等。带有内部模块（auditd，Apache，Nginx，System和MySQL），可通过一个指定命令来简化通用日志格式的收集，解析和可视化。

Filebeat涉及两个组件：查找器prospector和采集器harvester，来读取文件(tail file)并将事件数据发送到指定的输出。

启动Filebeat时，它会启动一个或多个查找器prospector，查看你为日志文件指定的本地路径。对于prospector所在的每个日志文件，prospector启动采集器harvester。每个harvester都会为新内容读取单个日志文件，并将新日志数据发送到libbeat，后者将聚合事件并将聚合数据发送到Filebeat配置的输出。

ELK是Logstash、Elasticsearch、Kibana三大开源框架首字母大写简称。

## 1.2 Logstash

![1585818645361.png](ELK配合Filebeat完成日志采集.assets6693d117b7f40a4a95715ef285e31ba.png)

Logstash是一个数据分析软件，主要目的是分析log日志。如上图所示，Logstash主要分为三个部分，input、filter和output（input：设置数据来源 ; filter：可以对数据进行一定的加工处理过滤 ; output：设置输出目标）

filter是logstash功能强大的原因，filter的插件介绍：

**①grok**

grok模式的语法如下：

**%{SYNTAX:SEMANTIC}**

SYNTAX：代表匹配值的类型,例如3.44可以用NUMBER类型所匹配,127.0.0.1可以使用IP类型匹配。  SEMANTIC：代表存储该值的一个变量名称,例如 3.44 可能是一个事件的持续时间,127.0.0.1可能是请求的client地址。所以这两个值可以用 %{NUMBER:duration} %{IP:client} 来匹配，IPORHOST、HTTPDATE等是封装过的正则表达式，直接使用即可，无需自己再写。。

也可以选择将数据类型转换添加到Grok模式。默认情况下，所有语义都保存为字符串。如果想转换成默认的数据类型，可以%{NUMBER:num:int}将num语义从一个字符串转换为一个整数。目前唯一支持的转换是int和float。

```filter {
 # 解析日志生成相关的IP，访问地址，日志级别
 grok {
 match => { 
 "message" => "%{SYSLOG5424SD:time} %{IP:hostip} %{URIPATHPARAM:url}\s*%{LOGLEVEL:loglevel}" 
 }
 }
 #解析log生成的时间为时间戳
 grok{
 match => {
 "message" => "%{TIMESTAMP_ISO8601:log_create_date}"
 }
 }
}
```

**②geoip**

根据ip地址获取经纬度，国家，城市，地区等信息。

wget [http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz](http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz)

tar -zxvf GeoLite2-City.tar.gz

cp GeoLite2-City.mmdb /data/logstash/
```
filter {
 geoip {
 source => "message"
 }
}
output{stdout{codec=>rubydebug}}

#输入：183.60.92.253
#输出：
{
 "type" => "std",
 "@version" => "1",
 "@timestamp" => 2019-03-19T05:39:26.714Z,
 "host" => "zzc-203",
 "message" => "183.60.92.253",
 "geoip" => {
 "country_code3" => "CN",
 "latitude" => 23.1167,
 "region_code" => "44",
 "region_name" => "Guangdong",
 "location" => {
 "lon" => 113.25,
 "lat" => 23.1167
 },
 "city_name" => "Guangzhou",
 "country_name" => "China",
 "continent_code" => "AS",
 "country_code2" => "CN",
 "timezone" => "Asia/Shanghai",
 "ip" => "183.60.92.253",
 "longitude" => 113.25
 }
}


filter {
 geoip {
 source => "http_x_forwarded_for"  # 取自nginx中的客户端ip
 target => "geoip"
 database => "/data/logstash/GeoLite2-City.mmdb"
 add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
 add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}" ]
 }
 mutate {
 convert => [ "[geoip][coordinates]", "float" ]
 }
}
```

**③mutate**

```
filter {
 mutate {
 #将字段的值转换为其他类型，例如将字符串转换为整数。如果字段值是数组，则将转换所有成员。
 convert => {
 "fieldname" => "integer"
 "booleanfield" => "boolean"
 }
 }
 mutate {
 #将现有字段复制到另一个字段。将覆盖现有目标字段。
 copy => { "source_field" => "dest_field" }
 }
 mutate {
 #使用分隔符将字段拆分为数组
 split => { "fieldname" => "," }
 }
}
```

**④date**

```filter {
 # 将log_create_date日期解析为指定格式，并将@timestamp字段替换为该日期
 date {
 match => [ "log_create_date", "yyyy-MM-dd HH:mm:ss" ]
 target => "@timestamp" 
 }
}
```

**⑤useragent**

```
filter {
 if [user_ua] != "-" {
 useragent {
 target => "agent"   #agent将过来出的user agent的信息配置到了单独的字段中
 source => "user_ua"   #这个表示对message里面的哪个字段进行分析
 }
 }
}
```

**⑥ruby脚本**

```
filter {
 #利用ruby代码来动态修改logstash event
 ruby {
 # Cancel 90% of events
 path => "/mnt/elastic/logstash-6.5.1/config/test.rb"
 # script_params => { "message" => "%{message}" }
 }
 json {
 source => "json"
 remove_field => ["json","message"]
 }
}
```

**⑦dissect：分隔符解析**

```
filter {
 dissect {
 mapping => {
 "message" => "%{ts} %{+ts} %{+ts} %{src} %{} %{prog}[%{pid}]: %{msg}"
 }
 }
}
```
Dissect过滤器是一种拆分操作。与常规拆分操作(其中一个分隔符应用于整个字符串)不同，此操作将一组分隔符应用于字符串值。Dissect不使用正则表达式，速度非常快。

语法解释
我们看到上面使用了和Grok很类似的%{}语法来表示字段，这显然是基于习惯延续的考虑。不过示例中%{+ts}的加号就不一般了。dissect 除了字段外面的字符串定位功能以外，还通过几个特殊符号来处理字段提取的规则：

%{+key}这个+表示，前面已经捕获到一个key字段了，而这次捕获的内容，自动添补到之前 key 字段内容的后面。
%{+key/2}这个/2表示，在有多次捕获内容都填到 key字段里的时候，拼接字符串的顺序谁前谁后。/2表示排第2位。
%{}是一个空的跳过字段。
%{?string}这个?表示，这块只是一个占位，并不会实际生成捕获字段存到事件里面。
%{?string} %{&string}当同样捕获名称都是string，但是一个?一个&的时候，表示这是一个键值对。
填充符
字段的->后缀例如%{function->}，表示忽略它右边的填充，否则右边的多余填充将拆分到下一个字段中。


## 1.3 Elasticsearch

 Elasticsearch是一个开源的分布式、RESTful 风格的搜索和数据分析引擎，它的底层是开源库Apache Lucene。Lucene是当下最先进、高性能、全功能的搜索引擎库。为了解决Lucene使用时的繁复性，Elasticsearch对其进行了封装，内部采用 Lucene 做索引与搜索，提供了一套简单一致的 RESTful API 来帮助我们实现存储和检索。    当然，Elasticsearch 不仅仅是 Lucene，并且也不仅仅只是一个全文搜索引擎。 它可以被下面这样准确地形容：

*   一个分布式的实时文档存储，每个字段可以被索引与搜索；

*   一个分布式实时分析搜索引擎；

*   能胜任上百个服务节点的扩展，并支持 PB 级别的结构化或者非结构化数据。

由于Elasticsearch的功能强大和使用简单，维基百科、卫报、Stack Overflow、GitHub等都纷纷采用它来做搜索。现在，Elasticsearch已成为全文搜索领域的主流软件之一。

## 1.4 Kibana

Kibana 是为 Elasticsearch设计的开源分析和可视化平台。你可以使用 Kibana 来搜索，查看存储在 Elasticsearch 索引中的数据并与之交互。你可以很容易实现高级的数据分析和可视化，以图标的形式展现出来。

**实时监控**：通过 histogram 面板，配合不同条件的多个 queries 可以对一个事件走很多个维度组合出不同的时间序列走势。时间序列数据是最常见的监控报警了。  **问题分析**：搜索，通过下钻数据排查问题，通过分析根本原因来解决问题；实时可见性，可以将对系统的检测和警报结合在一起，便于跟踪 SLA 和性能问题；历史分析，可以从中找出趋势和历史模式，行为基线和阈值，生成一致性报告。

**总结：**

整一套软件可以当作一个MVC模型，logstash是controller层，Elasticsearch是一个model层，kibana是view层。首先将数据传给logstash，它将数据进行过滤和格式化（转成JSON格式），然后传给Elasticsearch进行存储、建搜索的索引，kibana提供前端的页面再进行搜索和图表可视化，它是调用Elasticsearch的接口返回的数据进行可视化。logstash和Elasticsearch是用Java写的，kibana使用node.js框架。

<br>
# 二、总体结构

![1585818270028.png](ELK配合Filebeat完成日志采集.assets\1dc4641e317240e59d11a4792cfd3fcc.png)

<br>
# 三、准备工作
##3.1 微服务配置
添加依赖
```
<dependency>
      <groupId>net.logstash.logback</groupId>
      <artifactId>logstash-logback-encoder</artifactId>
     <version>4.10</version>
</dependency>
```
在微服务classpath路径下添加logback日志框架的配置文件logback.xml
```
<configuration>
    <include resource="org/springframework/boot/logging/logback/defaults.xml"/>
    <springProperty scope="context" name="springAppName" source="spring.application.name"/>

    <!-- 日志在工程中的输出位置 -->
    <property name="LOG_FILE" value="${BUILD_FOLDER:-build}/${springAppName}"/>
    <property name="SERVICE_NAME" value="Smartcook"/>

    <!-- 工程名字 -->
    <contextName>${SERVICE_NAME}</contextName>

    <!-- 控制台的日志输出样式 -->
    <property name="CONSOLE_LOG_PATTERN"
              value="logback--%clr(%d{yyyy-MM-dd HH:mm:ss.SSS}){faint} %clr(${LOG_LEVEL_PATTERN:-%5p}) %clr(${PID:- }){magenta} %clr(---){faint} %clr([%15.15t]){faint} %m%n${LOG_EXCEPTION_CONVERSION_WORD:-%wEx}}"/>

    <!-- 控制台输出 -->
    <appender name="console" class="ch.qos.logback.core.ConsoleAppender">
        <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
            <level>INFO</level>
        </filter>
        <!-- 日志输出编码 -->
        <encoder>
            <pattern>${CONSOLE_LOG_PATTERN}</pattern>
            <charset>utf8</charset>
        </encoder>
    </appender>

    <!-- 日志输出为文件 -->
    <!--<appender name="FILE" class="ch.qos.logback.core.FileAppender">-->
    <!--&lt;!&ndash; $使用变量FILE_PATH的格式,类似Linux中使用的格式：${FILE_PATH} &ndash;&gt;-->
    <!--<file>logs/file.log</file>-->
    <!--<encoder>-->
    <!--&lt;!&ndash; 指定输出格式 &ndash;&gt;-->
    <!--<pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{0} -%msg%n</pattern>-->
    <!--</encoder>-->
    <!--</appender>-->

    <!-- 日志输出为文件，且每天回滚为新文件，文件保留30天 -->
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">　　　　　　　　　　　
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">　　　　　　　　　　　　　
            <fileNamePattern>logs/logFile.%d{yyyy-MM-dd}.log</fileNamePattern>　　　　　　　　　　　　
            <maxHistory>30</maxHistory>　
        </rollingPolicy>

        <!--日志文件最大的大小 -->
        <triggeringPolicy
                class="ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy">
            <MaxFileSize>10MB</MaxFileSize>
        </triggeringPolicy>

        <encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
            <!--格式化输出：%d表示日期，%thread表示线程名，%-5level：级别从左显示5个字符宽度%msg：日志消息，%n是换行符 -->
            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level
                %logger{50} - %msg %n
            </pattern>
        </encoder>
    </appender>

    <!--为logstash输出的Appender -->
    <!--<appender name="logstash" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
        <destination>192.168.32.128:5044</destination>
        <encoder charset="UTF-8" class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
            <jsonFactoryDecorator class="net.logstash.logback.decorate.CharacterEscapesJsonFactoryDecorator">
                <escape>
                    <targetCharacterCode>10</targetCharacterCode>
                    <escapeSequence> </escapeSequence>
                </escape>
            </jsonFactoryDecorator>
            <providers>
                <pattern>
                    <pattern>
                        {
                        "timestamp":"%date{ISO8601}",
                        "user":"test",
                        "message":"[%d{yyyy-MM-dd HH:mm:ss.SSS}][%p][%t][%L{80}|%L]%m"}%n
                        }
                    </pattern>
                </pattern>
            </providers>
        </encoder>
        <keepAliveDuration>5 minutes</keepAliveDuration>
    </appender>-->

    <!--<appender name="logstash" class="net.logstash.logback.appender.LogstashTcpSocketAppender">-->
        <!--<destination>192.168.32.128:5044</destination>-->
        <!--<encoder class="net.logstash.logback.encoder.LogstashEncoder" />-->
        <!--<keepAliveDuration>5 minutes</keepAliveDuration>-->
    <!--</appender>-->

    <!-- 为logstash输出的JSON格式的Appender -->
    <appender name="logstash"
              class="net.logstash.logback.appender.LogstashTcpSocketAppender">
        <destination>192.168.32.128:5044</destination>
        <!-- 日志输出编码 -->
        <encoder
                class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
            <providers>
                <timestamp>
                    <timeZone>UTC</timeZone>
                </timestamp>
                <pattern>
                    <pattern>
                        {
                        "level": "%level",
                        "service": "${springAppName:-}",
                        "trace": "%X{X-B3-TraceId:-}",
                        "span": "%X{X-B3-SpanId:-}",
                        "exportable": "%X{X-Span-Export:-}",
                        "pid": "${PID:-}",
                        "thread": "%thread",
                        "class": "%logger{40}",
                        "stack_trace": "%exception{30}",
                        "message": "%message"
                        }
                    </pattern>
                </pattern>
            </providers>
        </encoder>
    </appender>

    <!-- 日志输出级别 -->
    <root level="INFO">
        <appender-ref ref="console"/>
        <appender-ref ref="logstash"/>
        <appender-ref ref="FILE"/>
    </root>
</configuration>
```

logback在.yml文件中的配置(会每日滚动生成带有日期后缀的文件)：  logging:  level:  root: info  file: logs/${spring.application.name}.log

## 3.2 Nginx配置

Nginx配置文件规定日志输出格式：
```conf
log_format main '$server_name $remote_addr - $remote_user [$time_local] "$request" '
'$status $upstream_status $body_bytes_sent "$http_referer" '
'"$http_user_agent" "$http_x_forwarded_for" '
'$ssl_protocol $ssl_cipher $upstream_addr $request_time $upstream_response_time';
```
 如果不经过logstash的处理，可以直接写成json格式：
```

log_format main '{"server_name":"$server_name",'
                '"remote_addr":"$remote_addr",'
                '"remote_user":"$remote_user",'
                '"time_local":"$time_local",'
                '"request":"$request",'
                '"status":"$status",'
                '"upstream_status":"$upstream_status",'
                '"body_bytes_sent":"$body_bytes_sent",'
                '"http_referer":"$http_referer",'
                '"http_user_agent":"$http_user_agent",'
                '"http_x_forwarded_for":"$http_x_forwarded_for",'
                '"ssl_protocol":"$ssl_protocol",'
                '"ssl_cipher":"$ssl_cipher",'
                '"upstream_addr":"$upstream_addr",'
                '"request_time ":"$request_time",'
                '"upstream_response_time":"$upstream_response_time"'
                '}';
```

访问日志中一个典型的记录如下：
192.168.1.102 - scq2099yt [18/Mar/2013:23:30:42 +0800] "GET /stats/awstats.pl?config=scq2099yt HTTP/1.1" 200 899 "http://192.168.1.1/pv/" "Mozilla/4.0 (compatible; MSIE 6.0; Windows XXX; Maxthon)"

>每个样式的含义如下：
\$server_name：虚拟主机名称。
\$remote_addr：远程客户端的IP地址。
-：空白，用一个“-”占位符替代，历史原因导致还存在。
\$remote_user：远程客户端用户名称，用于记录浏览者进行身份验证时提供的名字，如登录百度的用户名scq2099yt，如果没有登录就是空白。
[\$time_local]：访问的时间与时区，比如18/Jul/2012:17:00:01 +0800，时间信息最后的"+0800"表示服务器所处时区位于UTC之后的8小时。
\$request：请求的URI和HTTP协议，这是整个PV日志记录中最有用的信息，记录服务器收到一个什么样的请求
\$status：记录请求返回的http状态码，比如成功是200。
\$upstream_status：upstream状态，比如成功是200.
\$upstream_addr:后端服务器的IP地址
在server{}中添加：add_header backendIP \$upstream_addr;add_header backendCode \$upstream_status;
\$body_bytes_sent：发送给客户端的文件主体内容的大小，比如899，可以将日志每条记录中的这个值累加起来以粗略估计服务器吞吐量。
\$http_referer：记录从哪个页面链接访问过来的。 
\$http_user_agent：客户端浏览器信息
\$http_x_forwarded_for：客户端的真实ip，通常web服务器放在反向代理的后面，这样就不能获取到客户的IP地址了，通过\$remote_add拿到的IP地址是反向代理服务器的iP地址。反向代理服务器在转发请求的http头信息中，可以增加x_forwarded_for信息，用以记录原有客户端的IP地址和原来客户端的请求的服务器地址。
\$ssl_protocol：SSL协议版本，比如TLSv1。
\$ssl_cipher：交换数据中的算法，比如RC4-SHA。 
\$upstream_addr：upstream的地址，即真正提供服务的主机地址。 
\$request_time：整个请求的总时间。 
\$upstream_response_time：请求过程中，upstream的响应时间。

<br>
# 四、拉取镜像
**注意filebeat和elk的版本需要一致**
docker pull sebp/elk:7.6.1
docker pull elastic/filebeat:7.6.1

# 五、配置文件

**1)宿主机上创建文件夹**
mkdir -p /root/elk4log/conf.d  
mkdir -p /root/filebeat/conf.d

**2)在文件夹下编写配置文件**
vim /root/elk4log/conf.d/02-beats-input.conf
```
input {    
    tcp {         
        mode => "server"
        port => 5044
        codec => json_lines
        type => "microserver"
    }  
}
input {
    beats {
        port => 5045
        codec => json
        type => "nginx"
    }
}
filter {
    date {
        match => ["time_local","dd/MMM/yyyy:HH:mm:ss Z"]  # 解析"14/Mar/2017:00:00:02 +0800"
        target => "time_local"	# 指定覆盖到的字段，缺省为@timestamp
    }
}
output{
    if [type] == "microserver" {
        elasticsearch {
            hosts => ["192.168.32.128:9200"]  # 127.0.0.7:9200
            index => "smartcook-log-%{+YYYY.MM.dd}"
            #manage_template => true
            #template => ""
            #template_name => "apache_elastic_example"
            #template_overwrite => true
        }
    }

    if [type] == "nginx" {
        elasticsearch {
            hosts => ["192.168.32.128:9200"]  # 127.0.0.7:9200
            index => "nginx-zuul-log-%{+YYYY.MM.dd}"
            manage_template => true
            #文件中的template的名字需要与index对应，用*匹配日期
            template => "/etc/logstash/conf.d/gateway_zuul_template.json" 
            template_name => "nginx-zuul-log"
            template_overwrite => true
        }
    }
}
```

vim /root/elk4log/conf.d/gateway_zuul_template.json
```
{
  "order": 0,   
  "template": "nginx-zuul-log*", 
  "settings": {
    "index": {
      "number_of_shards": "5",  
      "number_of_replicas": "1",  
      "refresh_interval": "20s" 
    }
  },
  "mappings": {
    "properties": {
      "@timestamp": {
        "type": "date"
      },
      "@version": {
        "type": "keyword"
      },
      "server_name": {
        "type":"keyword"
      },
      "remote_addr": {
        "type": "text"
      },
      "remote_user": {
        "type":"keyword"
      },
      "time_local": {
        "type": "date"
      },
      "request": {
        "type": "text"
      },
      "status": {
        "type": "integer"
      },
      "upstream_status": {
        "type": "integer"
      },
      "body_bytes_sent": {
        "type": "long"
      },
      "http_referer": {
        "type": "text"
      },
      "http_user_agent": {
        "type": "text"
      },
      "http_x_forwarded_for": {
        "type": "text"
      },
      "ssl_protocol": {
        "type": "keyword"
      },
      "ssl_cipher": {
        "type": "keyword"
      },
      "upstream_addr": {
        "type": "text"
      },
      "request_time": {
        "type": "date"
      },
      "upstream_response_time": {
        "type": "long"
      }
    }
  }
}
```

vim /root/filebeat/conf.d/filebeat.yml
```
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/gateway_access.log

#============================= Filebeat modules ===============================
filebeat.config.modules:
  # Glob pattern for configuration loading
  path: ${path.config}/modules.d/*.yml
  # Set to true to enable config reloading
  reload.enabled: true

output.logstash:
  # The Logstash hosts
    hosts: ["192.168.32.128:5045"]
```

<br>
# 六、启动容器
##6.1 启动elk
docker run -d --name elk4log -p 5601:5601 -p 9200:9200 -p 5044:5044 -p 5045:5045 -v /root/elk4log/logstash/conf.d:/etc/logstash/conf.d  -v /root/elk4log/elasticsearch/config:/opt/elasticsearch/config -v /root/elk4log/elasticsearch/data:/var/lib/elasticsearch/nodes sebp/elk

>注：  #5601 - Kibana web 接口  #9200 - Elasticsearch JSON 接口  #5044 - Logstash 微服务日志监听接口  #5045 - Logstash Nginx日志监听接口

##6.2 启动filebeat
docker run -d --name=filebeat -v /root/filebeat/conf.d/filebeat.yml:/usr/share/filebeat/filebeat.yml --volumes-from nginx elastic/filebeat:7.6.1
>注 : 如果es启动报错，需要先修改宿主机的配置
sudo sh -c "echo 'vm.max_map_count=655360' >> /etc/sysctl.conf"  
sysctl -p 使配置生效

##6.3 访问UI页面
通过[http://192.168.32.128:5601](http://192.168.32.128:5601)访问Kibana

**注：时区问题**  logstash和es使用的都是UTC时间，而kibana默认读取浏览器的时区，所以kibana显示的时间会比logstash和es的多8小时。如果需要调整如下：
```
filter {
  date {
    match => ["message","UNIX_MS"]
    target => "@timestamp"   
  }
  ruby { 
    code => "event.set('timestamp', event.get('@timestamp').time.localtime + 8*60*60)" 
  }
  ruby {
    code => "event.set('@timestamp',event.get('timestamp'))"
  }
  mutate {
    remove_field => ["timestamp"]
  }
}
```

将日志通过logstash导入到redis中的文档参见：[https://blog.csdn.net/d597180714/article/details/82382703](https://blog.csdn.net/d597180714/article/details/82382703)
