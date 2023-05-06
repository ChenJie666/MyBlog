---
title: Idea
categories:
- 工具
---
## 1. Idea无法检索插件
选择HTTP Proxy，勾选Auto-detect proxy settings和Automatic proxy configuration URL：plugins.jetbrains.com

## 2. Idea常规配置
**创建类自动注解**
Setting->File and Code Templates，在File Header中添加
```
/**
 * @author CJ
 * @date: ${DATE} ${TIME}
 */
```

**大小写不敏感**
setting --> Editor --> General --> Code Completion
去掉Match case的对勾

**字体大小**
setting --> Editor -->  Font
修改Size大小


## 3. 控制台信息显示不全
Cause: java.sql.SQLException: io.seata.core.exception.RmTransactio... (1305 bytes)]
在Setting->Console中调大Override console cycyle buffer size的值。

## 4. Idea集成Scala
1. 安装scala到本地，并把%SCALA_HOME%/bin放到环境变量Path中
2. 下载scala版本对应的idea插件，安装到idea中
[插件下载地址](https://plugins.jetbrains.com/plugin/1347-scala/versions)
注意：需要与idea版本相同

3. 在Project Structure的Global Libraries中导入scala的sdk包。

## 5. 在webapp文件夹下，新建文件时没有jsp文件。
需要为项目部署Tomcat（artifact），部署完成后就可以在webapp下创建jps文件。如果找不到项目的artifact，Reimport All Maven Projects后再试。

## 6.可以安装插件 Maven Helper(解决maven冲突)、Translation
