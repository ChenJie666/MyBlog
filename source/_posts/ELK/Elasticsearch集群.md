---
title: Elasticsearch集群
categories:
- ELK
---
一、ES集群



# 二、集群搭建

**在一个节点上部署安装了ik和拼音分词器的es集群，步骤如下：**

#### ①编辑Dockerfile

vim elasticsearch.dockerfile

```
FROM elasticsearch:5.6.3-alpine
ENV VERSION=5.6.3
ADD https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v$VERSION/elasticsearch-analysis-ik-$VERSION.zip /tmp/
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install file:///tmp/elasticsearch-analysis-ik-$VERSION.zip
ADD https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v$VERSION/elasticsearch-analysis-pinyin-$VERSION.zip /tmp/
RUN /usr/share/elasticsearch/bin/elasticsearch-plugin install file:///tmp/elasticsearch-analysis-pinyin-$VERSION.zip
RUN rm -rf /tmp/*
```

#### ②创建镜像es_ik_py

```
docker build -t es_ik_py . -f elasticsearch.dockerfile
```

#### ③创建启动容器

**节点1：**

```
docker run -d -e ES_JAVA_OPTS="-Xms256m -Xmx256m" --name elasticsearch1 -p 9200:9200 -p 9300:9300 -v /root/es-cluster/es1.yml:/usr/share/elasticsearch/config/elasticsearch.yml  -v /root/es-cluster/data/esdata:/usr/share/elasticsearch/data  es_ik_py01
```

**节点2：**

```
docker run -d -e ES_JAVA_OPTS="-Xms256m -Xmx256m" --name elasticsearch1 -p 9201:9200 -p 9301:9300 -v /root/es-cluster/es2.yml:/usr/share/elasticsearch/config/elasticsearch.yml  -v /root/es-cluster/data:/usr/share/elasticsearch/data es_ik_py02
```

**映射的配置文件**
es1.yml为：

```xml
cluster.name: elasticsearch-cluster
#节点名称，每个节点的名称不能重复
node.name: node-1
network.host: 0.0.0.0
#是不是有资格主节点
node.master: true
node.data: true
http.port: 9200
transport.tcp.port: 9300
discovery.zen.ping.unicast.hosts: ["116.62.148.11:9300","116.62.148.11:9301"]
#开启允许跨域请求资源，head插件需要配置这俩参数
http.cors.enabled: true
http.cors.allow-origin: "*"
http.max_content_length: 200mb
gateway.recover_after_nodes: 2
network.tcp.keep_alive: true
network.tcp.no_delay: true
transport.tcp.compress: true
#集群内同时启动的数据任务个数，默认是 2 个
cluster.routing.allocation.cluster_concurrent_rebalance: 16
#添加或删除节点及负载均衡时并发恢复的线程个数，默认 4 个
cluster.routing.allocation.node_concurrent_recoveries: 16
#初始化数据恢复时，并发恢复线程的个数，默认 4 个
cluster.routing.allocation.node_initial_primaries_recoveries: 16
```

es2.yml为：

```xml
cluster.name: elasticsearch-cluster
#节点名称，每个节点的名称不能重复
node.name: node-2
network.host: 0.0.0.0
#是不是有资格主节点
node.master: true
node.data: true
http.port: 9200
transport.tcp.port: 9300
discovery.zen.ping.unicast.hosts: ["116.62.148.11:9300","116.62.148.11:9301"]
#开启允许跨域请求资源
http.cors.enabled: true
http.cors.allow-origin: "*"
http.max_content_length: 200mb
gateway.recover_after_nodes: 2
network.tcp.keep_alive: true
network.tcp.no_delay: true
transport.tcp.compress: true
#集群内同时启动的数据任务个数，默认是 2 个
cluster.routing.allocation.cluster_concurrent_rebalance: 16
#添加或删除节点及负载均衡时并发恢复的线程个数，默认 4 个
cluster.routing.allocation.node_concurrent_recoveries: 16
#初始化数据恢复时，并发恢复线程的个数，默认 4 个
cluster.routing.allocation.node_initial_primaries_recoveries: 16
```


<br>

#### 备注：

1. **如果容器启动报错为vm.max_map_count to low，则需要修改宿主机系统文件句柄大小**
修改/etc/sysctl.conf
```
# 在文件中增加下面内容
vm.max_map_count=655360
```
重新加载
```
sysctl -p
```

2. **启动容器报错WARNING: IPv4 forwarding is disabled. Networking will not work. 或者 网络不通**
   需要修改 /etc/sysctl.conf 
   ```
   net.ipv4.ip_forward=1
   ```
   然后重启network服务
   ```
   systemctl restart network
   ```
   查看
   ```
   sysctl net.ipv4.ip_forward
   ```

3. **如果容器启动报错为bootstrap checks failed，则需要修改系统文件的内存**
修改/etc/security/limits.conf
```
# 在文件末尾中增加下面内容
* soft nofile 65536
* hard nofile 65536
```
修改/etc/security/limits.d/20-nproc.conf
```
# 在文件末尾中增加下面内容
* soft nofile 65536
* hard nofile 65536
# 注：* 带表 Linux 所有用户名称
* soft nproc 4096
* hard nproc 4096
```
