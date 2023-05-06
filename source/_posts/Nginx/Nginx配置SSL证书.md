---
title: Nginx配置SSL证书
categories:
- Nginx
---
# 一、部署
**启动容器**
```
docker run -d -p 80:80 -p 443:443 -v /root/docker/nginx/html:/usr/share/nginx/html -v /root/docker/nginx/conf.d:/etc/nginx/conf.d -v /root/docker/nginx/nginx:/var/log/nginx --name nginx nginx:stable
```

<br>
# 二、腾讯云SSL证书部署
申请证书后，从网站下载证书，解压。如下是腾讯云的SSL证书的目录结构。
```
chenjie.asia
│   chenjie.asia.csr
│   chenjie.asia.key  
│   chenjie.asia.pem
└───Apache
│   │   1_root_bundle.crt
│   │   2_chenjie.asia.crt
│   │   3_chenjie.asia.key
│   
└───IIS
│   │   chenjie.asia.pfx
│   │   keystorePass.txt
│
└───Nginx
│   │   1_chenjie.asia_bundle.crt
│   │   2_chenjie.asia.key
│
└───Tomcat
│   │   chenjie.asia.jks
│   │   keystorePass.txt
```
因为我们使用的是Nginx，所以将Nginx下的1_chenjie.asia_bundle.crt和2_chenjie.asia.key文件复制到/root/docker/nginx/conf.d/cert目录下，因为数据卷映射关系，证书会被映射到容器中，路径为/etc/nginx/conf.d/cert/。

然后配置default.conf文件，配置如下：
```
server {
    listen  80;
    #SSL 访问端口号为 443
    listen 443 ssl; 
    #填写绑定证书的域名
    server_name cloud.tencent.com; 
    #证书文件名称
    ssl_certificate /etc/nginx/conf.d/cert/1_chenjie.asia_bundle.crt;
    #私钥文件名称
    ssl_certificate_key /etc/nginx/conf.d/cert/2_chenjie.asia.key;

    ssl_session_timeout 5m;
    #请按照以下协议配置
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2; 
    #请按照以下套件配置，配置加密套件，写法遵循 openssl 标准。
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE; 
    ssl_prefer_server_ciphers on;

    charset utf-8;
    access_log  /var/log/nginx/access.log  main;
    error_log /var/log/nginx/access.err;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

}
```
>Nginx 版本为 nginx/1.15.0 以上请使用 listen 443 ssl 代替 listen 443 和 ssl on。

配置完成后重启nginx容器，或进入容器执行`/usr/sbin/nginx -s reload`。

访问[http://chenjie.asia/](http://chenjie.asia/)和[https://chenjie.asia/](https://chenjie.asia/)
都能成功。

<br>
# 三、自建SSL证书并部署
**制作密钥**
```
openssl genrsa -out chenjie.key 2048
```
 **制作证书**
```
 openssl req -new -x509 -days 365 -key test.key -out chenjie.crt
```
获取到密钥和证书。

步骤同上，将chenjie.key和chenjie.crt放到/root/docker/nginx/conf.d/ssl目录下。
然后配置default.conf文件：
```
server {
    listen  80;
    #SSL 访问端口号为 443
    listen 443 ssl; 
    #填写绑定证书的域名
    server_name cloud.tencent.com; 
    #证书文件名称
#    ssl_certificate /etc/nginx/conf.d/cert/1_chenjie.asia_bundle.crt;
    #私钥文件名称
#    ssl_certificate_key /etc/nginx/conf.d/cert/2_chenjie.asia.key;
    ssl_certificate /etc/nginx/conf.d/ssl/chenjie.crt;
    ssl_certificate_key /etc/nginx/conf.d/ssl/chenjie.key;


    ssl_session_timeout 5m;
    #请按照以下协议配置
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2; 
    #请按照以下套件配置，配置加密套件，写法遵循 openssl 标准。
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE; 
    ssl_prefer_server_ciphers on;

    charset utf-8;
    access_log  /var/log/nginx/access.log  main;
    error_log /var/log/nginx/access.err;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

}
```

重启nginx，访问https时会提示证书不受信任。
