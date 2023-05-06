---
title: JVM虚拟机
categories:
- 设计模式与算法
---
# 一、面试题
1. 谈谈你对JVM的理解？
2. java8虚拟机和之前的变化？
3. 什么是OOM，什么是StackOverFlowError？怎么分析
4. JVM常用调优参数有哪些？
5. 内存快照如何抓取，怎么分析Dump文件？
6. 谈谈你对JVM中的类加载器的认识？

1. JVM的位置
2. JVM的体系结构
3. 类加载器
4. 双亲委派机制
5. 沙箱安全机制
6. Native
7. PC寄存器
8. 方法区
9.栈
10. 三种JVM
11. 堆
12. 新生区、老年区
13. 永久区
14. 堆内存调优
15. GC （常用算法）
16. JMM
17. 总结

# 二、JVM虚拟机
![JVM架构图](JVM虚拟机.assets\6308a0314068432da71107aa40c1b940.png)
## 2.1 JVM的位置
![image.png](JVM虚拟机.assets\6434ac3a011d44feb517f789c97ada94.png)

![Java内存](JVM虚拟机.assets\6769a2e4a6fc4f4681ab5b0d821208aa.png)

![类的加载过程](JVM虚拟机.assets