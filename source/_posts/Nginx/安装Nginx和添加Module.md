---
title: 安装Nginx和添加Module
categories:
- Nginx
---
# 一、安装Nginx
安装编译工具及库文件
```
yum -y install make zlib zlib-devel libtool  
yum -y install openssl openssl-devel
yum -y install gcc gcc-c++
```
## 1.1 下载pcre
PCRE 作用是让 Nginx 支持 Rewrite 功能。

1. 下载安装包
```
wget http://downloads.sourceforge.net/project/pcre/pcre/8.45/pcre-8.45.tar.gz
```
2. 解压
```
tar -zxvf pcre-8.45.tar.gz
```
3. 进入安装包目录，编译安装
```
cd pcre-8.45

./configure
make && make install
```
4. 查看版本
```
pcre-config --version
```

## 1.2 安装nginx
1. 下载安装包
```
wget http://nginx.org/download/nginx-1.20.2.tar.gz
```
2. 解压
```
tar -zxvf nginx-1.20.2.tar.gz
```
3. 进入安装包目录，编译安装
```
cd nginx-1.20.2.tar.gz
./configure --prefix=/opt/module/nginx-1.20.2 --with-http_stub_status_module --with-http_ssl_module --with-pcre=/opt/software/pcre-8.45
make && make install
```

4. nginx常用命令

| 命令 | 说明 |
| --- | --- |
| nginx -s reload	| 在nginx已经启动的情况下重新加载配置文件(平滑重启) |
| nginx -s repopen	| 重新打开日志文件 |
| nginx -c /特定目录/nginx.conf	| 以特定目录下的配置文件启动nginx |
| nginx -s stop | 立即停止服务 |
| nginx -s quit | 优雅关闭服务 |
| nginx -t	| 检查当前配置文件是否正确 |
| nginx -t -c /特定目录/nginx.conf	| 检测特定目录下的nginx配置文件是否正确 |
| nginx -v	| 显示版本信息 |
| nginx -V	| 显示版本信息和编译选项 |
| nginx -h	| 显示 nginx 可以设置的参数(上面的参数都是从这个命令显示出来的) |

>注：不推荐将nginx命令放到环境变量中，直接使用绝对路径来执行nginx命令

## 1.3 加入服务开机重启
1. 编辑脚本
```
[Unit]
Description=nginx
Documentation=https://nginx.org
After=network.target
 
[Service]
Type=simple
User=root
ExecStart= /opt/module/nginx-1.20.2/sbin/nginx
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
根据实际情况修改Service中的User和ExecStart的属性，然后将将本放到 `/usr/lib/systemd/system/nginx.service` 路径下。

2. 设为开机自启动
`systemctl enable nginx.service`

3. 启动服务
`systemctl start nginx.service`

## 1.4 为nginx访问添加用户密码
1. 安装httpd用于密码加密
```
yum install -y httpd
```
2. 创建密码文件并写入账号密码
```
htpasswd -cmb /opt/module/nginx-1.20.2/conf/.htpasswd hive hive
```
>.htpasswd为生成的文件，htpasswd -c(覆盖)  -b(直接从命令行获取密码)  -m(使用MD5加密)  -s(使用crypt()加密)  -D(从认证文件中删除用户记录)


<br>
# 二、添加Module
1. 下载模块包
[spnego-http-auth-nginx-module](https://github.com/stnoonan/spnego-http-auth-nginx-module)，该包支持Kerberos认证的

2. 配置
```
[root@cos-bigdata-mysql nginx-1.20.2]# cd /opt/software/nginx-1.20.2.tar.gz
[root@cos-bigdata-mysql nginx-1.20.2]# ./configure --prefix=/opt/module/nginx-1.20.2 --with-http_stub_status_module --with-http_ssl_module --with-pcre=/opt/software/pcre-8.45 --add-module=/opt/software/spnego-http-auth-nginx-module-1.1.1
```
3. 编译
```
[root@cos-bigdata-mysql nginx-1.20.2]# make
```
4. 更新
将运行程序nginx改名为nginx.bak，并将安装包下的nginx文件复制到原nginx的位置
```
[root@cos-bigdata-mysql nginx-1.20.2]# mv /opt/module/nginx-1.20.2/sbin/nginx /opt/module/nginx-1.20.2/sbin/nginx.bak
[root@cos-bigdata-mysql nginx-1.20.2]# cp /opt/software/nginx-1.20.2/objs/nginx /opt/module/nginx-1.20.2/sbin/nginx
```
然后更新
```
[root@cos-bigdata-mysql nginx-1.20.2]# make upgrade
```
