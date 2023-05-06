---
title: SprintBoot同时配置http和https登录
categories:
- SpringBoot
---
###配置https登录
**生成证书放大resources目录下**
```
keytool -genkey -alias tomcat -dname "CN=Andy,OU=kfit,O=kfit,L=HaiDian,ST=BeiJing,C=CN" -storetype PKCS12 -keyalg RSA -keysize 2048 -keystore keystore.p12 -validity 365
```
**配置文件**
```
server:
  port: 444 #https端口号
  ssl:
    protocol: TLS
    key-store: classpath:keystore.p12 #证书的路径
    key-store-password: abc123 #证书密码
    key-store-type: PKCS12 #秘钥库类型
    keyAlias: tomcat #证书别名
```

**注意**
①配置完成后请求接口可能会报错
java.lang.UnsatisfiedLinkError: org.apache.tomcat.jni.SSL.renegotiatePending(J)
目前的方法时降低tomcat的版本为9.0.12
```
        <dependency>
            <groupId>org.apache.tomcat.embed</groupId>
            <artifactId>tomcat-embed-core</artifactId>
            <version>9.0.12</version>
        </dependency>
```
适配tomcat的版本将springboot版本降到2.1.7
```
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.1.7.RELEASE</version>
    </parent>
```
②https配置后无法通过http访问接口。需要另外配置http登陆。


<br>
###配置http登录
**配置文件**
http:
  port: 8070

**配置类**
```java
@Configuration
public class TomcatConfig {

    @Value("${http.port}")
    private Integer port;

    @Value("${server.port}")
    private Integer httpsPort;

    @Bean
    public ServletWebServerFactory servletContainer() {
        TomcatServletWebServerFactory tomcat = new TomcatServletWebServerFactory() {
            @Override
            protected void postProcessContext(Context context) {
                // 如果要强制使用https，请松开以下注释
                // SecurityConstraint constraint = new SecurityConstraint();
                // constraint.setUserConstraint("CONFIDENTIAL");
                // SecurityCollection collection = new SecurityCollection();
                // collection.addPattern("/*");
                // constraint.addCollection(collection);
                // context.addConstraint(constraint);
            }
        };
        tomcat.addAdditionalTomcatConnectors(createStandardConnector()); // 添加http
        return tomcat;
    }

    // 配置http
    private Connector createStandardConnector() {
        // 默认协议为org.apache.coyote.http11.Http11NioProtocol
        Connector connector = new Connector(TomcatServletWebServerFactory.DEFAULT_PROTOCOL);
        connector.setSecure(false);
        connector.setScheme("http");
        connector.setPort(port);
        connector.setRedirectPort(httpsPort); // 当http重定向到https时的https端口号
        return connector;
    }

}
```
