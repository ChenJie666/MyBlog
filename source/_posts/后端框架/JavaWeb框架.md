---
title: JavaWeb框架
categories:
- 后端框架
---
# 一、Web服务器
## 1.1 种类
- IIS：微软开发的Web服务器，Windows中自带

- Tomcat：Tomcat服务器是一个免费开源的Web应用服务器，属于轻量级应用服务器，在中小型系统和并发用户不是很多的场合下被普遍使用，是开发和调试JSP程序的首选。Tomcat运行在JVM之上，它和HTTP服务器一样，绑定IP地址并监听TCP端口，同时还包含以下指责：管理Servlet程序的生命周期将URL映射到指定的Servlet进行处理与Servlet程序合作处理HTTP请求——根据HTTP请求生成HttpServletResponse对象并传递给Servlet进行处理，将Servlet中的HttpServletResponse对象生成的内容返回给浏览器。

- Nginx/Apache：严格的来说，Apache/Nginx 应该叫做「HTTP Server」，一个 HTTP Server 关心的是 HTTP 协议层面的传输和访问控制，所以在 Apache/Nginx 上你可以看到代理、负载均衡等功能；而 Tomcat 则是一个「Application Server」，或者更准确的来说，是一个「Servlet/JSP」应用的容器（Ruby/Python 等其他语言开发的应用也无法直接运行在 Tomcat 上）。

>虽然Tomcat也可以认为是HTTP服务器，但通常它仍然会和Nginx配合在一起使用：动静态资源分离——运用Nginx的反向代理功能分发请求：所有动态资源的请求交给Tomcat，而静态资源的请求（例如图片、视频、CSS、JavaScript文件等）则直接由Nginx返回到浏览器，这样能大大减轻Tomcat的压力。负载均衡，当业务压力增大时，可能一个Tomcat的实例不足以处理，那么这时可以启动多个Tomcat实例进行水平扩展，而Nginx的负载均衡功能可以把请求通过算法分发到各个不同的实例进行处理。

## 1.2 Tomcat服务器
### 1.2.1 目录结构
Tomcat
└─bin  启动脚本
└─conf  配置文件
└─lib  依赖
└─logs  日志
└─temp  临时文件
└─webapps  项目目录
    └─docs
    └─examples
    └─host-manager
    └─manager
    └─ROOT  默认访问的项目
└─work  Tomcat工作目录

### 1.2.2 idea启动Tomcat
![image.png](JavaWeb框架.assets