---
title: 域名托管和SSL绑定
categories:
- 系统安全
---
# 一、域名注册
国内的域名注册需要实名审核，所以可以在国外域名网站进行域名注册，推荐namesilo(新用户使用onesaving优惠码优惠1美元)。

# 二、域名托管到阿里云
这里使用[阿里云解析 DNS (aliyun.com)](https://dns.console.aliyun.com/?spm=5176.6660585.multi-content.1.76c37992yBeJlz#/dns/domainList)对我们的域名进行托管。步骤如下：
1. 在域名解析中添加域名，该域名为我们购买的一级域名；
2. 添加域名后会提示 **[未使用云解析DNS，当前配置的解析记录不会生效]**。因为我们在namesilo中购买的域名的默认域名解析器是namesilo提供的(ns1.dnsowl.com/ns2.dnsowl.com/ns3.dnsowl.com)，我们需要将其改为阿里云的DNS解析服务器(ns1.alidns.com/ns2.alidns.com)。
3. 进入[namesilo的domain管理页面](https://www.namesilo.com/account_domains.php)，点击这个图标进入域名服务器管理界面。
![image.png](域名托管和SSL绑定.assets\39ee24f00e42493d8cb5850a815211da.png)
4. 将默认的三个域名服务器删除，改为阿里云的域名服务器。等待几分钟后，阿里云DNS服务的域名会显示正常。
5. namesilo中的域名解析失效，阿里云中的域名解析生效。


# 三、SSL申请和绑定
1. 登录到阿里云SSL控制台的数字证书管理服务，申请购买免费证书。
2. 购买之后，进行证书申请，需要填写证书绑定的域名，申请通过后就可以下载证书。
①.pem扩展名的文件为站点证书文件(默认采用Base64编码)；②.key扩展名的文件为站点密钥文件
3. 配置nginx，可以通过https访问nginx
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
