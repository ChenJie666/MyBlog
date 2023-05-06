---
title: v2fly搭建
categories:
- 系统安全
---
v2ray作者已经停止维护，改为使用v2fly

# 一、框架安装
## 1.1 linux安装v2fly
docker安装(root用户下)
```
yum install -y docker
systemctl enable docker
systemctl start docker
```
安装v2fly
```
docker run \
--restart=always \
--name=v2fly \
--net=host \
-e TZ="Asia/Shanghai" \
-d \
-v /root/docker/v2fly/conf/config.json:/etc/v2ray/config.json \
-v /root/docker/v2fly/log:/var/log/v2ray \
v2fly/v2fly-core:v4.44.0
```

## 1.2 windows安装
从github查找项目[v2ray-core](https://github.com/v2fly/v2ray-core/releases/tag/v4.44.0)，下载[v2ray-windows-64.zip](https://github.com/v2fly/v2ray-core/releases/download/v5.0.5/v2ray-windows-64.zip)，解压即可使用。
也可以使用[v2rayN图形化软件](https://github.com/2dust/v2rayN/releases)，下载[v2rayN-Core.zip](https://github.com/2dust/v2rayN/releases/download/5.16/v2rayN-Core.zip) (直接下载v2rayN-Core.zip，避免部分功能无法使用)，完成后解压，然后将解压后的v2ray-windows-64中的所有文件覆盖到v2rayN文件夹中即可。

## 1.3 android安装
进入项目[v2rayNG](https://github.com/2dust/v2rayNG/releases)，下载[安装包v2rayNG_1.7.5.apk](https://github.com/2dust/v2rayNG/releases/download/1.7.5/v2rayNG_1.7.5.apk)

也可以使用项目[SagerNet](https://github.com/SagerNet/SagerNet)，下载对应的安装包



# 二、路由设置
官方教程(被墙需要代理): 
[新手上路 | V2Fly.org](https://www.v2fly.org/guide/start.html#%E5%AE%A2%E6%88%B7%E7%AB%AF)
[配置文件格式 | V2Fly.org](https://www.v2fly.org/config/overview.html#%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%E6%A0%BC%E5%BC%8F)
