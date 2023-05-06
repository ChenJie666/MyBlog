---
title: linux功能组件命令
categories:
- Linux
---
###nc命令相关
**nc的作用**
（1）实现任意TCP/UDP端口的侦听，nc可以作为server以TCP或UDP方式侦听指定端口
（2）端口的扫描，nc可以作为client发起TCP或UDP连接
（3）机器之间传输文件
（4）机器之间网络测速  

**安装**
yum install nc -y
yum install nmap -y

**参数**
1) -l
用于指定nc将处于侦听模式。指定该参数，则意味着nc被当作server，侦听并接受连接，而非向其它地址发起连接。
2) -k/-p <port>
-k<通信端口> 强制 nc 待命链接.当客户端从服务端断开连接后，过一段时间服务端也会停止监听。 但通过选项 -k 我们可以强制服务器保持连接并继续监听端口。
-p<通信端口> 设置本地主机使用的通信端口，有可能会关闭。
3) -s 
指定发送数据的源IP地址，适用于多网卡机 
4) -u
 指定nc使用UDP协议，默认为TCP
5) -v
输出交互或出错信息，新手调试时尤为有用
6）-w
超时秒数，后面跟数字 
7）-z
表示zero，表示扫描时不发送任何数据

**例子：**
启动7777端口
nc -lk 7777

<br>
###启动服务命令
nohup java -jar hxr-logclient.jar 1>/dev/null 2>&1 &
