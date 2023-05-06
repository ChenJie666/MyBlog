---
title: java--jar-和-java--cp
categories:
- 工具
---
# 运行jar包
我们有以下两种方法运行jar包
- java -jar Test.jar
- java -cp com.test.Test Test.jar


## java -jar
我们解压jar包，META-INF文件夹下都有MANIFEST.MF，内容如下：
```
Manifest-Version: 1.0
Archiver-Version: Plexus Archiver
Created-By: Apache Maven
Built-By: Administrator
Build-Jdk: 1.8.0_201
Main-Class: com.iotmars.udtf.ModelJsonUDTF
```
java -jar就是通过Main-Class来找到主类并执行其中的main()。如果你的MANIFEST.MF文件中没有Main-Class，就会提示Cant load main-class之类的错误。所以在导出jar包的时候一定要指定main-class。

**执行顺序为：**
1. 通过MANIFEST.MF中的Main-Class找到入口类，启动程序
2. 启动JVM，分配内存（java内存结构和GC知识）
3. 根据引用关系加载类（类加载、类加载器、双亲委托机制)，初始化静态块等
4. 执行程序，在虚拟机栈创建方法栈桢，局部变量等信息


## java -cp
对于java -cp就不需要指定Main-Class来指定入口。因为可以通过在参数中指定主类，执行程序。
```
java -cp build/libs/Groovy-1.0-SNAPSHOT.jar com.imooc.gradle.todo.App
```
