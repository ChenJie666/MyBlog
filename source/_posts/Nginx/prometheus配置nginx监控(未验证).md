---
title: prometheus配置nginx监控(未验证)
categories:
- Nginx
---
##一、nginx-vts方案
vts源码 https://github.com/vozlt/nginx-module-vts
exporter源码 https://github.com/hnlq715/nginx-vts-exporter
1、下载nginx，编译安装，把vts模块加进去 --add-module=/root/nginx-module-vts（这里我是直接用yum安装出来的nginx参数，nginx -V查看参数）
```
./configure --add-module=/root/nginx-module-vts --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-mail --with-mail_ssl_module --with-file-aio --with-ipv6 --with-cc-opt='-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic'

make && make install
```

2、nginx.conf加入以下配置，server可写到conf.d/default.conf 等目录
```conf
http {
    vhost_traffic_status_zone;
    server {
        listen 8088;
        location /status {
            vhost_traffic_status_display;
            vhost_traffic_status_display_format html;
        }
    }
}
```

3、下载nginx-vts-exporter并启动（修改端口等其他参数配置使用–help参看）
nohup /bin/nginx-vts-exporter -nginx.scrape_uri=http://localhost:8088/status/format/json &
(这里的uri端口需要指定成上面配置的vts界面端口，我用的8088)

4、需要监控uri情况的域名配置文件中写入该行配置vhost_traffic_status_filter_by_set_key \$uri uri::\$server_name; 不监控uri情况的域名无需配置。这种uri信息情况是我最需要拿到的，好多教程都没讲这玩意，至于国家分布那些对我来说没啥用，就全都没加

![image.png](prometheus配置nginx监控(未验证).assets\276d33ea4e664d4c8daa3b42388cdaac.png)

示例
```
server {
listen 80;
server_name nginx.test.com;
vhost_traffic_status_filter_by_set_key $uri uri::$server_name;   #这行用于显示uri信息
location / {
    proxy_pass http://nginx_test_worker/;
   }
}
```

5、grafana图我用的是2949，但是并不符合要求，主要是加上了如下这种展示uri访问情况的图

![image.png](prometheus配置nginx监控(未验证).assets\1362dec3bd28471b97abd24062416581.png)


##二、nginx-lua(openresty)方案

1、安装openresty
```
sudo yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo

sudo yum install openresty
```

2、git clone https://github.com/knyar/nginx-lua-prometheus

3、添加 nginx 配置文件 conf.d/prometheus.conf
```
lua_shared_dict prometheus_metrics 10M;
lua_package_path "/usr/local/openresty/lualib/ngx/?.lua";   #指定为git上扒下来的nginx-lua-prometheus代码路径
init_by_lua '
        prometheus = require("prometheus").init("prometheus_metrics")
        metric_requests = prometheus:counter(
                "nginx_http_requests_total", "Number of HTTP requests", {"host", "status"})
        metric_latency = prometheus:histogram(
                "nginx_http_request_duration_seconds", "HTTP request latency", {"host"})
        metric_connections = prometheus:gauge(
                "nginx_http_connections", "Number of HTTP connections", {"state"})
        metric_requests_uri = prometheus:counter(
                "nginx_http_requests_uri_total", "Number of HTTP requests_uri", {"host","uri", "status"})
        ';
log_by_lua '
        metric_requests:inc(1, {ngx.var.server_name, ngx.var.status})
        metric_requests_uri:inc(1, {ngx.var.server_name,ngx.var.request_uri, ngx.var.status})  #这行配置是git上默认配置没有的，目的是拿到uri信息
        metric_latency:observe(tonumber(ngx.var.request_time), {ngx.var.server_name})
';

server {
        listen 9145;
        server_name nginxlua.test.com;

        location /metrics {
          content_by_lua '
          metric_connections:set(ngx.var.connections_reading, {"reading"})
          metric_connections:set(ngx.var.connections_waiting, {"waiting"})
          metric_connections:set(ngx.var.connections_writing, {"writing"})
          prometheus:collect()
          ';
        }
}
```

4、nginx机器9145对应端口接入prometheus

5、gafana上用的图是 462，加上下面这个promql显示出uri分布情况

![image.png](prometheus配置nginx监控(未验证).assets\49f1e7aebf4142fa9227eb8db212d861.png)

两种方法最后经过压测选择了第一种vts的方案，具体用那种根据自身情况选择吧
