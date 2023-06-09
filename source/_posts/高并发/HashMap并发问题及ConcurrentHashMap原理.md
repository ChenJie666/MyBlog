---
title: HashMap并发问题及ConcurrentHashMap原理
categories:
- 高并发
---
# 一、HashMap并发：
## 1.1 问题
1. 首先size等公共变量不是原子性的。
2. 扩容时会产生环形链表，导致查询key哈希到环形链表所在桶且不存在该key的情况下会无限循环导致OOM。

## 1.2 扩容原理：
1）扩容
创建一个新的Entry空数组，长度是原数组的2倍。
2）rehash
遍历原Entry数组，把所有的Entry重新Hash到新数组。为什么要重新Hash呢？因为长度扩大以后，Hash的规则也随之改变。
![image.png](HashMap并发问题及ConcurrentHashMap原理.assets c217c958c1a400e886bb8adc0f19443.png)

## 1.3 产生问题原因：
假设一个HashMap已经到了Resize的临界点。此时有两个线程A和B，在同一时刻对HashMap进行Put操作：
![image.png](HashMap并发问题及ConcurrentHashMap原理.assets\d78cb038e9654a4fa761401ad2f8c741.png)
![image.png](HashMap并发问题及ConcurrentHashMap原理.assets\17db2ddbeea0415c84e6baa38f31c17e.png)
此时达到Resize条件，两个线程各自进行Rezie的第一步，也就是扩容，假如此时线程B遍历到Entry3对象，刚执行完红框里的这行代码，线程就被挂起。对于线程B来说：
e = Entry3
next = Entry2
这时候线程A畅通无阻地进行着Rehash，当ReHash完成后，结果如下（图中的e和next，代表线程B的两个引用）：
![image.png](HashMap并发问题及ConcurrentHashMap原理.assets\469c9deec4744e6f9f65e756d82ebd97.png)

直到这一步，看起来没什么毛病。接下来线程B恢复，继续执行属于它自己的ReHash。线程B刚才的状态是：
>***补充知识点：线程1和线程2在运行时有自己独立的工作内存，互不干扰，线程1本应该不会取到线程2的结果；但是在进行hash操作时会调用sun.misc.Hashing.stringHash32 方法，强制读取主内存，线程2的结果写入主内存后，线程1就会得到改变后的值***

e = Entry3
next = Entry2
![image.png](HashMap并发问题及ConcurrentHashMap原理.assetse8476c5e4f24d1a8794622eb94fa832.png)
当执行到上面这一行时，显然 i = 3，因为刚才线程A对于Entry3的hash结果也是3。
![image.png](HashMap并发问题及ConcurrentHashMap原理.assets\51856c8c6e0143c4adcc8d7ebb56adeb.png)
我们继续执行到这两行，Entry3放入了线程B的数组下标为3的位置，并且e指向了Entry2。此时e和next的指向如下：
e = Entry2
next = Entry2

整体情况如图所示：
![image.png](HashMap并发问题及ConcurrentHashMap原理.assets\7bc30ff5027f41ef9156529d066c32e4.png)

接着是新一轮循环，又执行到红框内的代码行：
![image.png](HashMap并发问题及ConcurrentHashMap原理.assetsaa7cbb2b5a1456ea3ad545ff2ebd062.png)

e = Entry2
next = Entry3
整体情况如图所示：
![image.png](HashMap并发问题及ConcurrentHashMap原理.assets