---
title: Nginx
categories:
- Nginx
---
#nginx作用：
①代理 ②负载均衡(高可用) ③动静分离(将动态资源和静态资源放到不同的服务器上,通过nginx进行代理，提高效率。可以为浏览器设置资源的expires过期时间,通过nginx确定资源的变动时间,资源未改变则浏览器调用缓存，返回状态码304；资源改变则重新请求资源，返回状态码200，适合极少变动的静态资源)
autoindex on; //可以显示文件夹下的所有资源
autoindex_exact_size off;  //显示准确的文件大小
autoindex_localtime on;  //显示时间信息为服务器时间，off为GMT时间
#命令：
nginx -f nginx.cong 可以根据指定的配置文件启动服务
nginx -s reload 可以不用重启nginx，重新加载配置文件
charset utf-8;
docker启动命令：
```
docker run -d -p 80:80 -p 443:443 -v /root/docker/nginx/html:/usr/share/nginx/html  -v /root/docker/nginx/nginx.conf:/etc/nginx/nginx.conf  -v /root/docker/nginx/conf.d:/etc/nginx/conf.d -v /root/docker/nginx/nginx:/var/log/nginx --name nginx nginx
```

#nginx配置文件详解
```conf
#nginx.conf
user  nginx;    //指定nginx worker进程运行用户及用户组
worker_processes  1;    //worker process开启的进程数(每个Nginx进程平均耗费10M~12M内存。建议指定和CPU的数量一致即可)

error_log  /var/log/nginx/error.log warn;   //全局错误日志文件路径和日志输出级别(debug，info，notice，warn，error，erit)
pid        /var/run/nginx.pid;  //进程pid文件的路径
worker_rlimit_nofile 65535  //指定进程可以打开的最多文件描述数目

events {
    use epoll;  //指定Nginx的工作模式,epoll是在linux平台上的高效模式
    worker_connections  1024;   //设定Nginx的工作模式及连接数上限
}


http {
    include       /etc/nginx/mime.types;    //将其他的Nginx配置或第三方模块的配置引用到当前的主配文件中
    default_type  application/octet-stream; //当文件类型未定义时，设定默认类型为二进制流

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"'; //Nginx的HttpLog模块指令，用于指定Nginx日志的输出日志

    access_log  /var/log/nginx/access.log  main;    //

    sendfile        on; //参数on是表示开启高效文件传输模式，默认是关闭状态（off）
    #tcp_nopush     on; //tcp_nopush和tcp_nodelay两个指令设置为on用于防止网络阻塞
    client_max_body_size 20m; //默认允许文件大小为1m

    keepalive_timeout  65;  //设置客户端连接保持活动的超时时间。在超过这个时间之后，服务器会关闭该连接；


    #gzip  on;  //

    include /etc/nginx/conf.d/*.conf;   //将其他的Nginx配置或第三方模块的配置引用到当前的主配文件中
}
```
```conf
#default.conf
upstream smartcook_zuul{
        #ip_hash //默认为round_robin算法,可以指定权重weight;ip_hash算法，通过ip计算hash，使每个ip访问固定的web，保持session一致性;url_hash算法，计算出url的hash，不同用户访问相同的资源，返回缓存到数据;fair算法，根据响应时间分配请求，响应时间短的优先。

        server 192.168.32.128:8100 weight=6 max_fails=3 fail_timeout=20;//fail_timeout时间内(秒)失败max_fails次数后踢出主机；fail_timeout时间后重新请求；
        server 192.168.32.128:8101 weight=4 max_fails=3 fail_timeout=20 max_conns=800;//max_conns最大连接数;backup表示备用，在其他服务都不可用时调用;down表示已弃用;
}

server {
    listen       80;    //listen用于指定虚拟主机的服务端口
    server_name  localhost,updates.jenkins-ci.org;  //指定IP地址或域名，多个域名之间用空格分开

    location /menu {  
        proxy_next_upstream http_502 http_504 error timeout invalid_header;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Accept-Encoding "";
        proxy_set_header Accept-Language "zh-CN";
        rewrite /menu/(.*) /v1/api-menu/menu/$1 break;
        proxy_pass http://gatewayzuul;
    }

    location /menu-anon {  
        proxy_next_upstream http_502 http_504 error timeout invalid_header;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Accept-Encoding "";
        proxy_set_header Accept-Language "zh-CN";
        rewrite /menu-anon/(.*) /v1/api-menu/menu-anon/$1 break;
        proxy_pass http://gatewayzuul;
    }

     location / {
        root   /usr/share/nginx/html;   //用于指定虚拟主机的网页根目录，这个目录可以是相对路径，也可以是绝对路径。
        index  index.html index.htm;    //index用于设定访问的默认首页地址
    }

    #error_page  404              /404.html;    //


    access_log  /var/log/nginx/logstash_access.log; //虚拟主机的访问日志存放路径，最后的main 用于指定访问日志的输出格式。
    error_log   /var/log/nginx/logstash_error.log; 

    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    #location ~ \.php$ {
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
    #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #    include        fastcgi_params;
    #}

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
}

```
>**location详解：**
多个location配置的情况下匹配顺序为：
首先匹配 =，其次匹配^~, 有多个相同匹配模式如^~，匹配程度高的优先匹配，匹配程度相同按从上到下顺序进行匹配，最后是交给/通用匹配。当有匹配成功时候，停止匹配，按当前匹配规则处理请求。
location = /login {}  //开头表示精确匹配，优先级最高
location ^~ /static/ {} //理解为匹配以/static/开头的url路径。nginx不对url做编码，因此请求为/static/20%/aa，可以被规则^~ /static/ /aa匹配到（注意是空格）。优先级次高。
location ~ \.(gif|jpg|png|js|css)\$ {}   //正则匹配url中的字符。优先级次次高。
location ~* \.png\$ {}   //开头表示不区分大小写的正则匹配
location !~ \.xhtml\$ {} //区分大小写不匹配的正则
location !~* \.xhtml\$ {}    //不区分大小写不匹配的正则匹配
location / {}    //通用匹配，任何请求都会匹配到

<br>
**location内部参数解析(代理jenkins，重定向下载请求到清华镜像源)：**
```
location /pub/jenkins/plugins {
        proxy_next_upstream http_502 http_504 error timeout invalid_header;  //当其中一台返回错误码502,504...等错误时，可以分配到下一台服务器程序继续处理。
        proxy_set_header Host mirrors.tuna.tsinghua.edu.cn;  //设置请求头中的目标服务器地址。
        proxy_set_header X-Real-IP \$remote_addr;  //只记录真实发出请求的客户端IP
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;  //用于记录代理信息的，每经过一级代理(匿名代理除外)，代理服务器都会把这次请求的来源IP追加在X-Forwarded-For中。
        proxy_set_header Accept-Encoding "";  //告诉服务器,我可以解压这些格式的数据
        proxy_set_header Accept-Language "zh-CN";  //告诉服务器,我可以接受的语言
        rewrite /pub/jenkins/plugins/(.*) /jenkins/plugins/$1 break;  //重写url
        proxy_pass https://mirrors.tuna.tsinghua.edu.cn;  //转发的域名
}
```
>rewrite最后一项flag参数：
last：本条规则匹配完成后继续向下匹配新的location  URL规则
break：本条规则匹配完成后终止，不在匹配任何规则
rediret：返回302临时重定向
permanent：返回301永久重定向

<br>
**remote_address和X-Forwarded-For:$proxy_add_x_forwarded_for的含义：**
> 用户IP0---> 代理Proxy1（IP1），Proxy1记录用户IP0，并将请求转发个Proxy2时，带上一个Http Header `X-Forwarded-For: IP0`  Proxy2收到请求后读取到请求有 `X-Forwarded-For: IP0`，然后proxy2 继续把链接上来的proxy1 ip**追加**到 X-Forwarded-For 上面，构造出`X-Forwarded-For: IP0, IP1`，继续转发请求给Proxy 3*   同理，Proxy3 按照第二部构造出 `X-Forwarded-For: IP0, IP1, IP2`,转发给真正的服务器，比如NGINX，nginx收到了http请求，里面就是 `X-Forwarded-For: IP0, IP1, IP2` 这样的结果。所以Proxy 3 的IP3，不会出现在这里。nginx 获取proxy3的IP 能通过 remote_address就是真正建立TCP链接的IP，这个不能伪造，是直接产生链接的IP。**$remote_address 无法伪造，因为建立 TCP 连接需要三次握手，如果伪造了源 IP，无法建立 TCP 连接，更不会有后面的 HTTP 请求。


<br>
<br>


![image.png](Nginx.assets\3703dfed64de4259880cb29d15c7c5fa.png)
keepalive：
在两台服务器上安装keepalived，在etc生成的目录keepalived中的配置文件keepalived.conf进行配置。主要配置虚拟主机(绑定虚拟ip到服务器网卡)和检测nginx是否正常的脚本。通过虚拟ip访问主keepalived，由keeepalived监控主nginx并在主nginx宕机后切换到备用nginx。
```config
#keepalived.conf
global_defs {      //全局配置
   notification_email {
     acassen@firewall.loc
     failover@firewall.loc
     sysadmin@firewall.loc
   }
   notification_email_from Alexandre.Cassen@firewall.loc
   smtp_server 192.168.32.128
   smtp_connect_timeout 30
   router_id LVS_DEVELBACK  //设置路由id，即本机的名字
   vrrp_skip_check_adv_addr
   vrrp_strict
   vrrp_garp_interval 0
   vrrp_gna_interval 0
}

vrrp_script chk_http_port {      //nginx检测脚本配置
    script  "/xxx/xxx/nginx_check.sh"      //指定检测脚本的位置
    interval  2    //检测脚本执行的间隔
    weight  -20    //如果检测到nginx宕机，那么nginx权重减少20
}

vrrp_instance  VI_1 {          //虚拟ip配置
        state  MASTER   #指定该服务器的角色；备份服务器上将MASTER 改为 BACKUP
        interface  ens33   //本机网卡名称
        vertual_router_id  51  //唯一标识，主、备机的virtual_router_id必须相同
        priority  90    //主、备机取不同的优先级，主机值较大，备份机值较小
        advert_int  1    //心跳检测主服务器和备份服务器是否宕机，默认间隔1s
        authentication{
            auth_type  PASS    //认证方式为密码,主备都一样
            auth_pass  11111     //密码为11111
        }
        virtual_ipaddress {
            192.168.32.50  #网卡绑定的虚拟IP
        }
    }
}

检测脚本：
```shell
#!/bin/bash
A=`ps  -C  nginx  -no-header | wc -l`
if [ $A -eq 0 ]; then
    /usr/local/nginx/sbin/nginx
    sleep  2
    if [ `ps  -C  nginx  --no-header | wc  -l`  -eq  0 ]; then
        killall  keepalived
    fi
fi


题：nginx有1个master和4个worker，如果每个worker支持最大连接数为1024，那么这个nginx支持多少并发？
答案：1024或2048个；因为一个work单任务，如果链接本机静态资源需要2个链接，如果链接远程资源需要4个链接，那么4个work并发量为1024或2048个。
