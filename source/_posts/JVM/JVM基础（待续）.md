---
title: JVM基础（待续）
categories:
- JVM
---
HotSpot


java.lang.OutOfMemoryError: GC overhead limit exceeded

这其实是JVM的一种推断，如果垃圾回收耗费了98%的时间，但是回收的内存还不到2%，那么JVM会认为即将发生OOM，让程序提前结束。当然我们可以使用-XX:-UseGCOverheadLimit，关掉这个特性。

但是这么做没有意义，如果你关掉这个特性，程序最终还是会报OOM，说到底要么是内存不足，要么是内存泄漏，从你分配的内存看应该是内存泄漏，你应该找出内存在哪里泄漏了，然后fix掉。你说业务线程池的BlockingQueue几乎占满。会不会是你使用了无界队列，然后任务消费过慢导致任务堆积？
