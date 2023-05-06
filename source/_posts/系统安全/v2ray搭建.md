---
title: v2ray搭建
categories:
- 系统安全
---
# 一、起因
最近在学习Elasticsearch的分析器，苦于没有中文贴，只能上[es的官网](https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-analyzers.html)进行学习。在公司的时候能正常上网，但是到家后发现家里的网络无法访问，提示 `访问 www.elastic.co 的请求遭到拒绝`，于是想到通过使用别家的网络进行访问。

**准备：**一台有公网ip的服务器（我这里选择了一台腾讯云服务器）

<br>
# 二、实现
## 方式一、通过SSR实现
参见dockerhub上的镜像：[https://registry.hub.docker.com/r/4kerccc/shadowsocksr](https://registry.hub.docker.com/r/4kerccc/shadowsocksr)

#### 搭建服务器端的SSR（ShadowSocksR）
**启动容器（shadowsocksr 容器中的22和80端口用于远程登陆和ssr连接）：**
```
docker run -itd -p 1000:22 -p 80:80 --name ssr 4kerccc/shadowsocksr:latest
```

**如果需要通过xshell连接：**
ip：116.62.148.11
port：1000
用户名：root 
密码：4ker.cc

**默认配置为：**
远程端口: 80 (此端口为容器端口，使用时请换位本地映射端口)
密码: 4ker.cc
认证协议: auth_sha1_v4
混淆方式: http_simple
加密方法: chacha20

**如何修改端口和密码：**
进入容器或远程连接后 修改/etc/shadowsocks.json文件
里面80为端口，4ker.cc为连接密码，都可自行修改.
修改后重启容器即可。

#### SSR的WIN客户端
上网搜一下就有

**注：之前还是挺好用的，但是最近貌似访问不了了，而且安全性、客户端等各个方面都没有v2ray好用，因此推荐使用v2ray实现！！！**

<br>
## 方式二、通过v2ray实现
#### 创建配置文件
vim /root/v2ray/conf/config.json
```
{
    "log": {
        "access": "/var/log/v2ray/access.log",
        "error": "/var/log/v2ray/error.log",
        "loglevel": "warning"
    },
    "inbounds": [{
        "port": 9005,
        "protocol": "vmess",
        "listen": "0.0.0.0",
        "settings": {
            "decryption":"none",
            "clients": [{
                "id": "  XXXXXXXX-405E-D56B-7118-0C160D0F3DF9",
                "level": 1
            }]
        },
        "streamSettings":{
            "network":"tcp",
            "security":"auto"
        }
    },
    {
        "port": 9105,
        "protocol": "shadowsocks",
        "listen": "0.0.0.0",
        "settings": {
            "method": "aes-256-gcm",
            "password": "XXXXXXXX-405E-D56B-7118-0C160D0F3DF9",
            "level": 0,
            "network": "tcp",
            "ivCheck": false
        }
    }],
    "outbounds": [{
            "protocol": "freedom",
            "settings": {}
        },
        {
            "protocol": "blackhole",
            "settings": {},
            "tag": "blocked"
        }
    ]
}
```
>同时开启SS和VMESS协议，端口分别为9105和9005

#### 安装v2ray
```
docker run \
--restart=always \
--name=v2ray \
--net=host \
-v /root/v2ray/conf/config.json:/etc/v2ray/config.json \
-v /root/v2ray/log:/var/log/v2ray \
-d \
v2ray/official:latest
```
>注：截止当前该镜像只有一个版本，v2ray的版本为4.22.1

#### 配置win客户端
**步骤如下**
1. **下载压缩包**
下一个win端的[客户端v2rayN](https://github.com/2dust/v2rayN)


2. **解压后打开v2rayN.exe**
![image.png](v2ray搭建.assets\3e6e4fc8135e4cbd9cd3af8a62aeb613.png)

3. 添加服务器

![image.png](v2ray搭建.assets\67f26ddd115b45b78aaaecc38cea5f3e.png)

根据传输协议选择添加的服务器类型，端口、用户ID、alterId需要与配置文件中的一致；

4. 右键测试服务器速度，如果测速正常则连接成功
![image.png](v2ray搭建.assets\8d951af1dbe942e2ba91211b7537e882.png)

5. 启动代理
![image.png](v2ray搭建.assets80a0f21a73746449d3bd5cf180bf130.png)

<br>
# 三、结果
进入[测速网站](https://www.speedtest.cn/)进行测速，发现测速节点变成了中国腾讯云，表明搭建成功
![image.png](v2ray搭建.assets