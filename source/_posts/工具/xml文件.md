---
title: xml文件
categories:
- 工具
---
xmln(可以理解为import导包)
XML NameSpace的缩写，XML文件标签名都是自定义的，防止与其他人XML标签重名，用于区分
xmlns:xsi
文件遵守XML规范，xsi全名：xml schema instance的缩写，是指具体用到的schema资源文件里定义的元素所准守的规范。即xsi:schemaLocation空间命名为xmln值的这个文件里定义的元素需要遵守的标准。
xsi:schemaLocation(可以理解为第一个值导包，第二个值导入包内具体文件)
XML元素所遵守的规范，它的值(URI)是成对出现的，第一个值表示命名空间，第二个值则表示描述该命名空间的模式文档的具体位置，两个值之间以空格分隔。

如果还需要导入其他文件，则要添加xmln:所在包名，xsi:schemaLocation也要定义

```
<beans
    xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:mvc="http://www.springframework.org/schema/mvc"
    xsi:schemaLocation="
			http://www.springframework.org/schema/beans 
			http://www.springframework.org/schema/beans/spring-beans-3.1.xsd
			http://www.springframework.org/schema/mvc
			http://www.springframework.org/schema/mvc/spring-mvc-3.1.xsd">
```
