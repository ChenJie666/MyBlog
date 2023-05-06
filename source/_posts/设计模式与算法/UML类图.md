---
title: UML类图
categories:
- 设计模式与算法
---
# 一、UML类图
# 1.1 概念
类图(Class diagram)：是显示了模型的静态结构，特别是模型中存在的类、类的内部结构以及它们与其他类的关系等。类图不显示暂时性的信息。类图是面向对象建模的主要组成部分。它既用于应用程序的系统分类的一般概念建模，也用于详细建模，将模型转换成编程代码。类图也可用于数据建模。

# 1.2 类图基础属性
\- 表示private  
\# 表示protected 
\~ 表示default,也就是包权限  
\_ 下划线表示static  
斜体表示抽象  
![image.png](UML类图.assets8357c5ae14e7787c0edd27ae8d69c.png)


# 1.3 类的关系
**在UML类图中，常见的有以下几种关系: 泛化（Generalization）, 实现（Realization），关联（Association)，聚合（Aggregation），组合(Composition)，依赖(Dependency)。**

**a、实现（Realization）**
表示类对接口的实现。
UML图中实现使用一条带有空心三角箭头的虚线指向接口，如下：
![image](UML类图.assets