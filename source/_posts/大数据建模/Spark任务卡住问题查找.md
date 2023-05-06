---
title: Spark任务卡住问题查找
categories:
- 大数据建模
---
## 一、如果是task一直没有启动
那么可能是没有足够资源进行分配导致一直pending

## 二、如果是task一直在running
那么可能是任务复杂将CPU占满。可以通过进程jstack工具来查找那个线程占用了CPU。

<br>
**Spark Task一直Running问题排查示例：**
1. spark任务中有个stage阶段卡住了，查看页面信息得到任务所在的节点和端口。
![image.png](Spark任务卡住问题查找.assets\2f76c5dde915439aa94a65987844e166.png)
2. 登陆节点后，使用`netstat -nap | grep 45209`命令查询45209端口的进程信息
```
[root@cos-bigdata-test-hadoop-02 ~]# netstat -nap | grep 45209
tcp6       0      0 192.168.101.185:45209   :::*                    LISTEN      30770/java          
tcp6       0      0 192.168.101.185:45209   192.168.101.186:44002   ESTABLISHED 30770/java
```
得到该进程的pid为30770
3. 然后使用 `top -p 30770` 命令查看该进程，发现确实CPU占用非常高，说明某项操作将CPU占满，此时task并未失败，而是一直在进行。
4. 通过`top -Hp 30770`将该进程内部线程信息打印，获得哪条线程占用CPU高
```
[root@cos-bigdata-test-hadoop-02 ~]# top -Hp 30770
top - 16:22:31 up 81 days,  5:06,  1 user,  load average: 0.80, 0.38, 0.40
Threads:  45 total,   1 running,  44 sleeping,   0 stopped,   0 zombie
%Cpu(s):  6.2 us,  0.4 sy,  0.0 ni, 93.5 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem : 32778468 total,  2338892 free, 12535300 used, 17904276 buff/cache
KiB Swap:  8257532 total,  7893420 free,   364112 used. 19729380 avail Mem 

  PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND                                      
 1741 chenjie   20   0   13.2g   3.9g  39364 R 99.7 12.4   1:51.22 java                                         
30802 chenjie   20   0   13.2g   3.9g  39364 S  0.3 12.4   0:01.74 java                                         
30770 chenjie   20   0   13.2g   3.9g  39364 S  0.0 12.4   0:00.00 java                                         
30771 chenjie   20   0   13.2g   3.9g  39364 S  0.0 12.4   0:02.02 java                                         
30772 chenjie   20   0   13.2g   3.9g  39364 S  0.0 12.4   0:04.23 java 
```
5. 通过jstack {pid} 将进程堆栈打印，并将上一轮操作中获取的线程号在jstack文件中查询，定位线程（获取的线程号为十进制，需将获取的线程id转换为十六进制，再进行对照）



<br>
参考文章：[Spark Task一直Running问题排查](https://blog.csdn.net/Aeve_imp/article/details/107644922?spm=1001.2101.3001.6661.1&utm_medium=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1.pc_relevant_default&depth_1-utm_source=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1.pc_relevant_default&utm_relevant_index=1)
