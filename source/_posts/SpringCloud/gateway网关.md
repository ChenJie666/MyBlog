---
title: gateway网关
categories:
- SpringCloud
---
***application.yml配置文件***
```yaml
server:
  port: 8100

spring:
  application:
    name: gateway-server
  zipkin:
    base-url: http://192.168.32.128:9411
    enabled: true
    sender:
      type: web
  sleuth:
    sampler:
      #采样率介于0到1之间，1表示全部采集
      probability: 1
  cloud:
    config:
      discovery:
        enabled: true
        serviceId: config-center
      profile: dev
      fail-fast: true
    gateway:
      default-filters:  #全局过滤器
        - name: Hystrix
          args:
            name: fallbackcmd  #使用HystrixCommand打包剩余的过滤器，并命名为fallbackcmd
            fallbackUri: forward:/fallback  #配置fallbackUri，降级逻辑被调用
      discovery:
        locator:
          enabled: true
      routes:
        - id: MENU-CENTER
          uri: lb://MENU-CENTER
          filters:
            - SetPath=/menu-anon/{path}
          predicates:
            - Path=/v1/api-menu/menu-anon/{path}  #直接访问菜谱接口
        - id: MENU-CENTER
          uri: lb://MENU-CENTER
          filters:
            - SetPath=/menu/{path}
          predicates:
            - Path=/v1/api-menu/menu/{path}   #需要权限验证
      globalcors: #跨域配置
        corsConfigurations:
          '[/**]':
            allowedOrigins: "*"
            allowedMethods: "*"

eureka:
  client:
    fetch-registry: true
    register-with-eureka: true
    service-url:
      defaultZone: http://hxr:hxr123@192.168.32.128:8761/eureka/
  instance:
    instance-id: ${spring.application.name}:${server.port}
    prefer-ip-address: true

#设置feign客户端负载均衡和超时时间(OpenFeign默认支持ribbon)
ribbon:
  #开启ribbon负载均衡
  eureka:
      enabled: true
  #建立连接所用的时间
  ConnectTimeout: 100
  #建立连接后服务器响应时间
  ReadTimeout: 500


hystrix:
  command:
    default:
      execution:
        isolation:
          thread:
            timeoutInMilliseconds: 5000 # 设置hystrix的超时时间为5000ms

management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: always

cron:
  black-ip: 0 0/5 * * * ?
```
```
            routes: 
                - predicates:
                    - Path=/acct/**
                  filters:
                      - StripPrefix=1
                  uri: lb://acctsvi
                - predicates:
                    - Path=/msg/**
                  filters:
                      - StripPrefix=1
                  uri: lb://msgsvi     
                - predicates:
                    - Path=/email/**
                  filters:
                      - StripPrefix=1
                  uri: lb://email  
```
>上述配置filters中的StripPrefix也是内建的过滤器工厂Bean名称，设定值为1表示将路由中的第一个层去除，其余保留用来转发请求。
```
        gateway:
            default-filters:
                - RewritePath=/api/.*?/(?<remaining>.*), /$\{remaining}
            routes: 
                - predicates:
                    - Path=/api/acct/**
                  uri: lb://acctsvi
                - predicates:
                    - Path=/api/msg/**
                  uri: lb://msgsvi     
                - predicates:
                    - Path=/api/email/**
                  uri: lb://email  
```
>RewritePath，它也是内建的过滤器工厂，可以运用[规则表示式](https://openhome.cc/Gossip/Regex/)来进行路径重写，因此，也可以这么设置api前置。


***pom.xml***
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.2.5.RELEASE</version>
    </parent>

    <groupId>com.iotmars</groupId>
    <artifactId>gateway</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <spring-cloud.version>Hoxton.SR3</spring-cloud.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-gateway</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-config</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-openfeign</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-oauth2</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-netflix-hystrix</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-zipkin</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-devtools</artifactId>
            <optional>true</optional>
            <scope>runtime</scope>
        </dependency>

        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
        </dependency>

        <!-- swagger -->
        <dependency>
            <groupId>io.springfox</groupId>
            <artifactId>springfox-swagger-ui</artifactId>
            <version>2.9.2</version>
        </dependency>
        <dependency>
            <groupId>io.springfox</groupId>
            <artifactId>springfox-swagger2</artifactId>
            <version>2.9.2</version>
        </dependency>

        <dependency>
            <groupId>org.apache.commons</groupId>
            <artifactId>commons-lang3</artifactId>
            <version>3.4</version>
        </dependency>


    </dependencies>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.cloud</groupId>
                <artifactId>spring-cloud-dependencies</artifactId>
                <version>${spring-cloud.version}</version>
                <scope>import</scope>
                <type>pom</type>
            </dependency>
        </dependencies>
    </dependencyManagement>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>
```
