---
title: Jsoup、Tika
categories:
- 随笔
---
###Jsoup
//解析网页
Document document = Jsoup.parse(new URL(url),30000);
//所有js中的方法都可以使用
Element element = document.getElementById("app");
//获取所有的li元素
Elements elements = element.getElementByTag("li");


###Tika
Apache Tika是基于java的内容检测和分析的工具包，可检测并提取来自上千种不同文件类型（如PPT，XLS和PDF）中的元数据和结构化文本。 它提供了命令行界面、GUI界面和一个java库。Tika可帮助搜索引擎抓取内容后的数据处理。
