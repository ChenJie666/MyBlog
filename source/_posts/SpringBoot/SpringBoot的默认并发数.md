---
title: SpringBoot的默认并发数
categories:
- SpringBoot
---
###Spring Boot应用支持的最大并发量是多少？

Spring Boot 能支持的最大并发量主要看其对Tomcat的设置，可以在配置文件中对其进行更改。当在配置文件中敲出max后提示值就是它的默认值。

我们可以看到默认设置中，Tomcat的最大线程数是200，最大连接数是10000。

###并发量指的是连接数，还是线程数？

当然是连接数。

###200个线程如何处理10000条连接？

 Tomcat有两种处理连接的模式，一种是BIO，一个线程只处理一个Socket连接，另一种就是NIO，一个线程处理多个Socket连接。由于HTTP请求不会太耗时，而且多个连接一般不会同时来消息，所以一个线程处理多个连接没有太大问题。

###为什么不开几个线程？

多开线程的代价就是，增加上下文切换的时间，浪费CPU时间，另外还有就是线程数增多，每个线程分配到的时间片就变少。多开线程≠提高处理效率。

###那增大最大连接数呢？

增大最大连接数，支持的并发量确实可以上去。但是在没有改变硬件条件的情况下，这种并发量的提升必定以牺牲响应时间为代价。

###配置文件明明就是空的，这些提示内容是哪里加载的？

默认生成的配置文件确实是空的，就是普通的文本文件，不要错以为这些内容是被隐藏掉的。首先是IDE要支持，IDE支持Spring Boot项目就知道该从哪里加载数据。Spring Boot的默认配置信息，都在 spring-boot-autoconfigure-版本号.jar 这个包中。其中上述Tomcat的配置在/web/ServerProperties.java中。下图是用jd-gui反编译看的，你也可以在spring boot项目中找到依赖包查看。
![image.png](SpringBoot的默认并发数.assets\de66c8680eb64600b4fbbfe80de2806f.png)

![image.png](SpringBoot的默认并发数.assets\2e9a40fe1cff4f1cb642ccd8fefc6291.png)
