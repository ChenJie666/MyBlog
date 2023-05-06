---
title: V2fly流量伪装(WebSocket-+-TLS-+-Web)
categories:
- 系统安全
---
[WebSocket + TLS + Web | 新 V2Ray 白话文指南 (v2fly.org)](https://guide.v2fly.org/advanced/wss_and_web.html#%E9%85%8D%E7%BD%AE)

**V2fly在正常使用的情况下添加流量伪装(WebSocket + TLS + Web)**

# 一、安装配置Nginx
```
docker run -d -p --net=host -v /root/docker/nginx/html:/usr/share/nginx/html -v /root/docker/nginx/conf.d:/etc/nginx/conf.d -v /root/docker/nginx/nginx:/var/log/nginx --name nginx nginx:stable
```
配置文件default.conf放到/root/docker/nginx/conf.d，最终被映射到Nginx容器的/etc/nginx/conf.d路径下。
域名绑定的SSL的证书和密钥放到/root/docker/nginx/conf.d/cert文件夹下，同样会被映射到容器中。的/etc/nginx/conf.d/cert文件夹下
```
server {
    #listen  80;
    #SSL 访问端口号为 443
    listen 443 ssl http2; 
    #填写绑定证书的域名
    server_name aws.jianghuan.top; 

    #证书文件名称
    ssl_certificate /etc/nginx/conf.d/cert/9637220_aws.jianghuan.top.pem;
    #私钥文件名称
    ssl_certificate_key /etc/nginx/conf.d/cert/9637220_aws.jianghuan.top.key;

    ssl_session_cache shared:MozSSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    
    #支持的协议配置和加密套件
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3; 
    ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
    ssl_prefer_server_ciphers off;

    add_header Content-Type text/plain;
    charset utf-8;
    access_log  /var/log/nginx/access.log  main;
    error_log /var/log/nginx/access.err;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }
    
    location /sharepicture {
        if ($http_upgrade != "websocket") { # WebSocket协商失败时返回404
            return 404;
        }
        proxy_redirect off;
        proxy_pass http://127.0.0.1:9005; # WebSocket监听在回函地址的9005端口上
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        # Show real Ip in v2ray access.log
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

}
```

# 二、修改v2fly配置文件
```
{
    "stats": {},
    "api": {
        "tag": "api",
        "services": [
            "StatsService"
        ]
    },
    "policy": {
        "levels": {
            "0": {
                "statsUserUplink": true,
                "statsUserDownlink": true
            }
        },
        "system": {
            "statsInboundUplink": true,
            "statsInboundDownlink": true,
            "statsOutboundUplink": true,
            "statsOutboundDownlink": true
        }        
    },
    "log": {
        "access": "/var/log/v2ray/access.log",
        "error": "/var/log/v2ray/error.log",
        "loglevel": "info"
    },
    "inbounds": [{
        "tag": "websocket",
        "port": 9005,
        "protocol": "vmess",
        "listen": "127.0.0.1",
        "settings": {
            "clients": [{
                "email": "chenjie",
                "id": "632ae3b5-311f-204b-xxxx-e6dc3e32969c",
                "alterId": 0,
                "level": 0
            },{
                "email": "chenjierouter",
                "id": "3bccf389-8988-afa9-xxxx-8519cc85fb38",
                "alterId": 0,
                "level": 0
            },{
                "email": "wuyingfeng",
                "id": "e5a92143-3293-bbd0-xxxx-22ea4abd8ca1",
                "alterId": 0,
                "level": 0
            },{
                "email": "zhengkai",
                "id": "bcd85082-6e37-403a-xxxx-db3c2452c46a",
                "alterId": 0,
                "level": 0
            },{
                "email": "wangbo",
                "id": "4b91c0fe-3ccb-62cf-xxxx-fab8534848e6",
                "alterId": 0,
                "level": 0
            }]
        },
        "streamSettings":{
            "network": "ws",
            "wsSettings": {
                "path": "/sharepicture"
            }
        }
    },
    {
        "listen": "127.0.0.1",
        "port": 10085,
        "protocol": "dokodemo-door",
        "settings": {
            "address": "127.0.0.1"
        },
        "tag": "api"
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
    ],
    "routing": {
        "rules": [{
            "inboundTag": [
                "api"
            ],
            "outboundTag": "api",
            "type": "field"
        }],
        "domainStrategy": "AsIs"
    }
}
```
修改客户端配置
![image.png](V2fly流量伪装(WebSocket-+-TLS-+-Web).assets\7902bf46eaf442dc8a6203a298539164.png)

通过网站https://c.earr.one/生成clash的配置文件，然后放到nginx的html路径下，供用户订阅。


**流量统计**
```
docker exec -it v2fly v2ctl api --server=127.0.0.1:10085 StatsService.QueryStats 'pattern: "" reset: false'
docker exec -it v2fly v2ctl api --server=127.0.0.1:10085 StatsService.GetStats 'name: "user>>>chenjie>>>traffic>>>uplink" reset: false'
```

>记录一个代理失败的问题：在路由器的padavan中使用clash客户端连接v2fly，配置完成后查看clash的ui页面，发现配置没有问题但是没有流量经过。
>原因分析：将日志等级调整为DEBUG，查看日志输出，发现是路由器的系统时间是错的，与v2fly服务器时间差太多导致代理失败。
>问题解决：在crontab中设置定时任务同步网络时间 `* */1 * * * ntpd -n -q -p time1.aliyun.com`
