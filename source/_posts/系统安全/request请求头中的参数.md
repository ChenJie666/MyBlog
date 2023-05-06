---
title: request请求头中的参数
categories:
- 系统安全
---
* request.getContextPath()  返回站点的根目录

* request.getRealpath("/")得到的是实际的物理路径，也就是你的项目所在服务器中的路径

* request.getScheme() 等到的是协议名称，默认是http

* request.getServerName() 得到的是在服务器的配置文件中配置的服务器名称 比如:localhost .baidu.com 等等

* request.getServerPort() 得到的是服务器的配置文件中配置的端口号 比如 8080等等

完整路径 = request.getScheme() + "://"
            + request.getServerName() + ":" + request.getServerPort();
    String path = request.getScheme() + "://" + request.getServerName()
            + ":" + request.getServerPort() + request.getContextPath()
