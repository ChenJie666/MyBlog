---
title: SSH+MySQL
categories:
- MySQL
---
# 一、数据库设置
创建用户，设置用户的host为localhost（如果是docker启动的mysql，host需要设置为宿主机的IP）
```
mysql> grant all privileges on *.* to 'cj'@'81.68.79.183' identified by 'cj';
```
别忘了刷新设置到内存使其生效
```
flush privileges;
```

<br>
# 二、服务器设置
实现的功能为从跳板节点跳转到mysql节点
跳板节点为192.168.101.179
mysql节点为192.168.101.174

## 2.1 配置免密登陆
```
ssh-keygen -t rsa
```
将公钥发送到本机
```
ssh-copy-id localhost
```
将私钥发送到需要登陆到本服务器的服务器上
```
rsync -av id_rsa user@ip:~/.ssh
```
修改密钥的权限
```
chmod 600 id_rsa
```
修改配置文件/etc/ssh/sshd_config中的允许密钥登陆的一条配置
```
PubkeyAuthentication yes 
```
重启sshd服务
```
systemctl restart sshd
```

## 2.2 启动ssh隧道
在跳板节点192.168.101.179上执行命令如下，启动隧道
```
ssh -CPNf -L 0.0.0.0:3307:192.168.101.174:3306 root@192.168.101.174
```
>参数解释：
>- C： 使用压缩功能，是可选的，加快速度。
>- P： 用一个非特权端口进行出去的连接。
>- f： SSH完成认证并建立port forwarding后转入后台运行。
>- N： 不执行远程命令。该参数在只打开转发端口时很有用（V2版本SSH支持）
>- L： 创建本地连接。

在跳板节点192.168.101.179上查看进程
```
[hxr@cos-bigdata-hadoop-01 ~]$ netstat -nap | grep 3307
tcp        0      0 127.0.0.1:3307          0.0.0.0:*               LISTEN      21822/ssh           
tcp6       0      0 ::1:3307                :::*                    LISTEN      21822/ssh

[hxr@cos-bigdata-hadoop-01 ~]$ netstat -nap | grep 192.168.101.174
tcp        0      0 192.168.101.179:44102   192.168.101.174:22      ESTABLISHED 21822/ssh
```
在mysql节点192.168.101.174上查看进程
```
[root@cos-bigdata-mysql ~]# netstat -nap | grep 192.168.101.179
tcp        0      0 192.168.101.174:22      192.168.101.179:44102   ESTABLISHED 25435/sshd: root@pt
```

<br>
# 三、连接数据库
## 3.1 Navicat客户端连接
流程是先登录到ssh配置的服务器上，然后执行登陆MySQL的命令。所以单纯的希望通过Navicat的ssh通道进行连接，其实不需要创建ssh通道，只需要找一台可以访问mysql节点的跳板机即可，ssh上配置该跳板机的登陆方式，常规中配置数据库的连接方式。

现在我们配置了ssh通道，那么就通过该通道来代理 mysql节点 来实现数据库的访问。

①首先设置ssh连接，连接到服务器
![image.png](SSH+MySQL.assets