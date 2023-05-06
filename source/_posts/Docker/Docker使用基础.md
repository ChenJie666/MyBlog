---
title: Docker使用基础
categories:
- Docker
---
# 一、Docker部署
## 1.1 安装docker
### 1.1.1 准备
**安装相关依赖**
```shell
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```
**国内源**
```shell
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```
### 1.1.2 安装
**安装docker**
```shell
sudo yum -y install docker-ce
```
**服务自启动**
```shell
systemctl enable docker
```
### 1.1.3 服务启动和优化
**设置阿里云镜像**
```shell
sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://4bj4rdum.mirror.aliyuncs.com/"]
}
EOF
```
**启动服务**
```shell
sudo systemctl daemon-reload
sudo systemctl restart docker
```
**查看docker信息**
```
docker info
```
>找到如下信息表示镜像加速器生效：
>```
>Registry Mirrors:
>  https://4bj4rdum.mirror.aliyuncs.com/
>```

## 1.2 删除docker
**查询所有docker安装**
```
yum list installed | grep docker
```
**删除查询到的所有安装**
```
yum remove -y  xxxxx    
```
**删除镜像和容器**
```
rm -rf /var/lib/docker
```
**查找所有的docker文件**
```
find / -name docker      
```
**删除所有的docker文件**
```
rm -rf xxx
```

<br>
# 二、Docker使用
## 2.1 Docker相关概念
### 2.1.1 Docker镜像
Docker 的镜像实际上由一层一层的文件系统组成，这种层级的文件系统就是联合文件系统(UnionFS)。
- bootfs(引导文件系统)主要包含bootloader和kernel，其中boot加载器主要是用来引导加载内核。Linux刚启动时会加载bootfs，在Docker镜像的最底层是bootfs。当boot加载完成之后整个内核就存在内存中了，此时内存的使用权已由bootfs(boot文件系统)转交给内核，此时系统就会卸载bootfs(boot文件系统)。
- roorfs(root文件系统)在bootfs(boot文件系统)之上。包含的就是典型Linux系统中的 /dev ，/proc，/bin ，/etc 等标准的目录和文件。可以是一种或多种操作系统，先以只读方式加载，引导结束完整性检查。
- Base Image是基础镜像
- Image是子镜像
- Container是可写层，docker中运行的程序在这一层执行；Docker第一次启动时初始可写层为空。运行时从镜像中读取数据(写时复制)，并屏蔽镜像中的更改数据。

![image.png](Docker使用基础.assets\8872a03c840e4874b701272b065b9fee.png)



### 2.1.2 网络模式

| Docker网络模式 | 配置                      | 说明                                                         |
| -------------- | ------------------------- | ------------------------------------------------------------ |
| bridge模式     | --net=bridge               | 默认网络，docker启动后创建一个docker0网桥，默认创建的容器也是添加到这个网桥中，IP地址为172.17.0.0/16     |
| host模式       | --net=host                 | 容器不会获得一个独立的network namespace，而是与宿主机共用一个          |
| container模式  | --net=container:NAME_or_ID | 与指定的容器使用同一个network namespace，网卡配置也都是相同的。 kubernetes中的pod就是多个容器共享一个Network namespace。 |
| none模式       | --net=none                 | 容器有独立的Network namespace，但并没有对其进行任何网络设置，如分配veth pair 和网桥连接，配置IP等。 |

**查看网络相关信息：**
- ifconfig   查看所有的网卡
- brctl show   查看所有的网桥（需要先安装工具 **yum install -y bridge-utils**）
- docker network ls   查看网络模式

### 2.1.2.1 Bridge模式

**原理：**创建一个docker0默认网桥，使用veth-pair技术创建一对虚拟网卡，一端放到新建的容器中，并重命名为eth0，另一端放到宿主机中，以veth+随机7个字符串命名，并将这个网络设备加入到docker0网桥中，网桥自动为容器分配一个IP，并设置docker0的IP为容器默认网关。
所以容器默认网络都加入了这个网桥，因此都可以彼此通信。同时在iptables添加SNAT转换网络段IP，以便容器访问外网。
容器的命名空间和宿主机的命名空间相互隔离，宿主机的命名空间中的网卡veth可以发送到容器的命名空间的网卡eth0。

![Docker主机默认网络](Docker使用基础.assetseacb65870844a6aa34d62d5b709bcda.png)

**例：**
当我们未启动容器时，使用ip addr命令查看网卡，与docker相关的只有一张docker0网卡。当我们启动一个容器后，使用ip addr查看发现多了一张网卡如下：
```
26: veth7dc0e4f@if25: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default 
    link/ether b2:17:ec:b5:72:a1 brd ff:ff:ff:ff:ff:ff link-netnsid 3
    inet6 fe80::b017:ecff:feb5:72a1/64 scope link 
       valid_lft forever preferred_lft forever
```
然后我们在容器中查看网卡
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
25: eth0@if26: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.2/16 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:acff:fe11:2/64 scope link 
       valid_lft forever preferred_lft forever
```
总结：我们每安装一个容器，docker就会给容器分配一个ip，使用veth-pair技术在宿主机和容器中创建的两张虚拟网卡。veth-pair就是一对的虚拟设备接口，他们都是成对出现的，一端接着协议，一端彼此连接。正因为有这个特性，evth-pair充当一个桥梁，连接各种虚拟网络设备。

我们可以查看docker0网卡的详细信息，执行命令`docker network inspect bridge`
```
[root@cos-bigdata-mysql ~]# docker network inspect bridge
[
    {
        "Name": "bridge",
        "Id": "f09103f08695050dd23f900f96ccfc04716435b12c0866cfd7e4c16095cf1d7f",
        "Created": "2021-07-21T11:09:15.718636023+08:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.17.0.0/16",
                    "Gateway": "172.17.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Containers": {
            "723532d51bf32422282b04b5e5274d164cf49ecc880a201975658387c90f0a04": {
                "Name": "openldap",
                "EndpointID": "64f100c3fdd10f0dc85e5dbd6cc19d9e7549dfd00a99dc06d933d900bf4c0ca1",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            },
            "ea68b9dc02f652711e07a930ca65de2793e5c37952eb1f61e8f8decd7bd5762a": {
                "Name": "redis",
                "EndpointID": "d584f5caf9d2e5634b918e091ab27ec6607de815cbc92968b9720c064b4bbd18",
                "MacAddress": "02:42:ac:11:00:03",
                "IPv4Address": "172.17.0.3/16",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.bridge.default_bridge": "true",
            "com.docker.network.bridge.enable_icc": "true",
            "com.docker.network.bridge.enable_ip_masquerade": "true",
            "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
            "com.docker.network.bridge.name": "docker0",
            "com.docker.network.driver.mtu": "1500"
        },
        "Labels": {}
    }
]
```
可以发现docker0的网关是172.17.0.1，网段是172.0.0.1/16，这个网段可以分配的ip数量是2^16-2。在启动新的容器后， 会为该容器分配改网段上的IP地址。

**容器之间通讯流程：**
1. 容器1通过容器中的虚拟网卡eth0@if26与宿主机上的对应网卡veth7dc0e4f@if25进行通讯。
2. 而docker0网卡相当于路由器，当veth7dc0e4f@if25网卡会与路由器进行通讯，路由器会将veth7dc0e4f@if25网卡的IP地址记录到路由表中，然后准备将消息发送到目标IP。
3. 路由器通过寻找路由表或进行广播的方式找到目标ip的网卡，然后讲消息发送到目标网卡，该网卡再与其对应的网卡进行通讯，将消息发送到目标容器中。

<br>
##### 自定义网卡
除了使用默认的docker0，我们可以创建自己的bridge网络，容器中可以通过其他容器名进行访问。创建容器的时候指定网络为mynet并指定ip即可。

**优点**
1. 自定义网卡相比docker0进行了很多功能的完善，如自动实现了--link功能。
2. 不同集群使用不同网络，互相隔离，保证集群是安全和健康的。

>**创建一个新的bridge网络（创建虚拟网卡，注意网段不能与其他网卡冲突）**
docker network create --driver bridge --subnet=192.168.1.0/16 --gateway=192.168.1.1 mynet
**删除虚拟网卡**
docker network rm mynet
**查看网络信息**
docker network inspect mynet
**创建容器并指定容器ip**
docker run -e TZ="Asia/Shanghai" --privileged -itd -h hadoop01.com --name hadoop01 --network=mynet --ip 172.18.12.1 centos /usr/sbin/init


**打通不同网段下的容器的网络(即将容器加入到网络中)**
如我们创建了上述的新的bridge网络mynet，并创建了一个容器，容器IP地址为192.168.1.12，那么该容器与docker0网络中的IP为172.17.0.3的redis容器就不再一个网络中，所以这两个容器是网络隔离的。那么我们可以使用如下命令将连个容器的网络进行打通。
```
docker network connect mynet redis
```
执行该命令后再次查看mynet网络的详细信息
```
docker network inspect mynet
```
可以发现该命令将redis容器加入到了mynet的网络中，并给该容器添加了一个新的IP地址
```
[root@cos-bigdata-mysql ~]# docker network inspect mynet
[
    {
        "Name": "mynet",
        "Id": "95a5db07a2b21b4a94fcce482dc944c772cf79435515b6bf4d2fd172bcf2cbfa",
        "Created": "2021-07-21T11:14:24.600592551+08:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.18.12.0/16",
                    "Gateway": "172.18.1.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Containers": {
            "5e9d26990618c952b2bd27644996987cc6d09618f3e2166e56a0be9c759d3632": {
                "Name": "mysql57",
                "EndpointID": "a31825bb5d9379054fe7343efbcd9f4d9aeb17ff3fe9899becbe4ee99ed4c730",
                "MacAddress": "02:42:ac:12:0c:02",
                "IPv4Address": "172.18.12.2/16",
                "IPv6Address": ""
            },
            "ea68b9dc02f652711e07a930ca65de2793e5c37952eb1f61e8f8decd7bd5762a": {
                "Name": "redis",
                "EndpointID": "8f8aa18b307f01cede808d4572d8fff71a9ca6b3dc759f71dfee8318447edb26",
                "MacAddress": "02:42:ac:12:00:01",
                "IPv4Address": "172.18.0.1/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```
这样mynet网络中的容器可以和原本是docker0网络中的redis容器进行通讯。


### 2.1.2.2 Host模式
如果启动容器的时候使用host模式，那么这个容器将不会获得一个独立的Network Namespace，而是和宿主机共用一个Network Namespace。容器将不会虚拟出自己的网卡，配置自己的IP等，而是使用宿主机的IP和端口。但是，容器的其他方面，如文件系统、进程列表等还是和宿主机隔离的。

![Docker主机Host网络](Docker使用基础.assets\99ef66af2fae4b81847c5916019d0f86.png)

### 2.1.2.3 Container模式
这个模式指定新创建的容器和已经存在的一个容器共享一个 Network Namespace，而不是和宿主机共享。新创建的容器不会创建自己的网卡，配置自己的 IP，而是和一个指定的容器共享 IP、端口范围等。同样，两个容器除了网络方面，其他的如文件系统、进程列表等还是隔离的。两个容器的进程可以通过 lo 网卡设备通信。

![Docker主机Container网络](Docker使用基础.assets\5f34687094a041768e8e49f22ae50a7c.png)

### 2.1.2.4 None模式
使用none模式，Docker容器拥有自己的Network Namespace，但是，并不为Docker容器进行任何网络配置。也就是说，这个Docker容器没有网卡、IP、路由等信息。需要我们自己为Docker容器添加网卡、配置IP等。

这种网络模式下容器只有lo回环网络，没有其他网卡。none模式可以在容器创建时通过--network=none来指定。这种类型的网络没有办法联网，封闭的网络能很好的保证容器的安全性。

<br>
### 2.1.3 数据卷
数据卷是经过特别设计的目录，可以绕过联合文件系统（UFS）为一个或多个容器提供访问。设计目的是为了数据的持久化，独立于容器的生命周期，因此Docker不会在删除容器时，删除挂载的数据卷，也不会存在类似的垃圾回收机制，对容器引用的数据卷进行处理。


<br>
## 2.2 Docker容器启动
**基本启动容器命令如下：**
docker run -itd mysql:5.6

**可以添加的参数如下：**
- **指定容器端口映射：** -p 8080:8080
- **指定容器数据卷：** -v /root/docker/redis/data:/data 
- **指定容器名称：** --name nginx
- **指定环境变量：** -e SEATA_IP=192.168.32.128
- **指定容器自动重启：** --restart=always
- **指定容器网络环境：** --net=host   
- **指定容器时区：**  -e TZ='Asia/Shanghai'   
- **指定pid：**   --pid="host"   
- **指定容器的hostname：** -h "mars"
- **在容器的host文件中添加映射：** --add-host updates.jenkins-ci.org:192.168.101.128
- **让容器获取宿主机root权限：** --privileged=true
- **关联另一个容器的容器名，与--add-host类似：** --link=[]
- **开放一个端口或一组端口：** --expose=[]
- **指定容器使用的DNS服务器(默认和宿主一致)：** --dns 8.8.8.8
- **指定容器DNS搜索域名，默认和宿主一致：** --dns-search example.com
- **指定运行内存：**
-m,--memory                 内存限制，格式是数字加单位，单位可以为 b,k,m,g。最小为 4M
--memory-swap               内存+交换分区大小总限制。格式同上。必须必-m设置的大
--memory-reservation        内存的软性限制。格式同上
--oom-kill-disable          是否阻止 OOM killer 杀死容器，默认没设置
--oom-score-adj             容器被 OOM killer 杀死的优先级，范围是[-1000, 1000]，默认为 0
--memory-swappiness         用于设置容器的虚拟内存控制行为。值为 0~100 之间的整数
--kernel-memory             核心内存限制。格式同上，最小为 4M
- **指定CPU：**
--cpuset="0-2" or --cpuset="0,1,2"   绑定容器到指定CPU运行；
--vm 1                      启动 1 个内存工作线程
--vm-bytes 280M             每个线程分配 280M 内存

<br>
## 2.3 Docker常用命令
#### 查看帮助文档
```
man docker-run/docker-logs/docker-top/docker-exec
```
####简单命令
```
docker info
docker images
docker pull [用户名][仓库名]:[版本号]
docker rmi [imageId/imageName]
docker ps -a -l
docker start/restart/stop/kill/rm [containId/containName]
docker port [containId/containName]  #查看容器端口
docker top [containId/containName]  # 查看运行中容器的进程
```
#### 进入容器
```
docker exec -ti ceff85e1747d /bin/bash
docker exec -ti ceff85e1747d /bin/sh
```
#### 在容器中执行命令
```
docker exec nginx bash -c 'nginx -s reload'
```
#### 容器文件复制
```shell
docker cp dev_smartcook.sql mysql:/tmp
docker cp mysql:/tmp/dev_smartcook.sql /root
```

#### 查看容器日志
显示最近5分钟的日志
```
docker logs --since 5m -f [dockerName]
```
显示最近100条日志
```
docker logs --tail 100 -f [dockerName]
```

#### 修改容器参数
```shell
docker container update --restart=always 容器名字 
```

#### 清除无效数据
```shell
docker system prune
docker container prune
docker network prune
docker images prune 清除
```

#### 数据卷操作
```shell
docker volume create --name redis01  # 创建别名为redis01的数据卷
docker volume rm redis01 # 删除名为redis01的数据卷
docker volume ls  # 查看所有的数据卷
docker volume prune # 删除所有未使用的数据卷
docker run -it --name mysql2 --volumes-from mysql1 mysql:5.6 # 启动mysql2容器并共享mysql1的数据卷
```

#### inspect命令
docker inspect是docker客户端的原生命令，用于查看docker对象的底层基础信息。包括容器的id、创建时间、运行状态、启动参数、目录挂载、网路配置等等。
```shell
docker inspect [imageId]  # 查看镜像的详细信息
docker inspect [containId]  # 查看容器的详细信息
docker inspect [volumeName]  # 查看数据卷的详细信息
docker network inspect [networkName] # 查看网络信息
```
>--format,-f：Format the output using the given Go template
>--size,-s：Display total file sizes if the type is container
>--type：	Return JSON for specified type

#### 构建镜像
```
docker build -t [tagname] [path/url]
```

#### 查看容器占用内存
**找到容器对应的进程：**
```
ps -ef [containID]
```
获得容器对应的pid后，就可以使用top、pmap、ps等查看进程内存的命令查看容器的内存占用情况了。

**①使用top命令查看进程的内存占用：**
```
top -p 5140
```
按e可切换内存单位。按大写P可以按CPU占用大小逆序排序，大写M可以按内存占用大小逆序排序。
>**内容解释：**
>PID：进程的ID
>USER：进程所有者
>PR：进程的优先级别，越小越优先被执行
>NInice：值
>VIRT：进程占用的虚拟内存
>RES：进程占用的物理内存
>SHR：进程使用的共享内存
>S：进程的状态。S表示休眠，R表示正在运行，Z表示僵死状态，N表示>该进程优先值为负数
>%CPU：进程占用CPU的使用率
>%MEM：进程使用的物理内存和总内存的百分比
>TIME+：该进程启动后占用的总的CPU时间，即占用CPU使用时间的累加值。
>COMMAND：进程启动命令名称

**②使用pmap命令**
```
pmap -d 5140
```

**③使用ps命令**
```
ps -e -o 'pid,comm,args,pcpu,rsz,vsz,stime,user,uid' | grep 5140
```
>其中rsz为实际内存
>
>![image.png](Docker使用基础.assets\5b4dbc71ab014e7ebb21ab5910369ea0.png)

<br>
## 2.4 Docker不常用命令
####简单命令
````
docker search [name]  # 查找镜像
````
#### 上传镜像
①登陆到dockerhub
```
docker login
```
②标记镜像后
```
docker tag [镜像名] [用户名][仓库名]:[版本号]
```
③上传
```
docker push [用户名][仓库名]:[版本号]
```

<br>
## 2.5 Dockerfile
- ENV：用于为镜像定义所需的环境变量，并可被kockerfile文件位于其后的其他指令所调用
- RUN：run指令是在构建镜像时运行的命令，创建Docker镜像的步骤，也就是docker bulid中执行的，其实就是顺着Dockerfile文件的指令顺序运行。
- CMD：CMD命令是当Docker镜像被启动后Docker容器将会默认执行的命令。一个Dockerfile中只能有一个CMD命令，如果指定了多条命令，只有最后一条会被执行。
- ENTRYPOINT：ENTRYPOINT 允许你把你的容器启动时候去执行某件事情，让你的容器变成可执行的。
  **CMD与ENTRYPOINT的区别：**CMD命令设置容器启动后默认执行的命令及其参数，但CMD设置的命令能够被docker run命令后面的命令行参数替换ENTRYPOINT配置容器启动时的执行命令（不会被忽略，一定会被执行，即使运行 docker run时指定了其他命令）
- ADD：高级复制文件。可以是URL路径，把你指定的文件下载到本地，并打包进镜像中。
- WORKDIR：用于为Dockerfile中所有的RUN、CMD、ENTRYPOINT、COPY、ADD指定设定工作目录。
如：`WORKDIR /usr/local;` `nginx-1.19.2.tar.gz ./`     其中./表示的路径是 /usr/local；
- VOLUME：指定容器的挂载点目录，不支持宿主机的挂载点目录；
- EXPOSE：因为我们不能确定镜像启动的容器运行在哪个宿主机，因此无法指定绑定地址，并且宿主机的空闲端口也是不确定，我们只能指定镜像暴露的端口，在启动后去动态绑定至宿主机的随机端口和所有地址。
也就是说我们写在dockerfile文件的暴露端口并不能直接暴露，只能说是可以暴露，在“ docker run -P ”的时候才会去暴露所有的端口。
- FROM：说明在哪个镜像的基础上构造镜像，必须在第一个非注释行，为后续命令提供运行环境；
- MAINTAINER：已过时
- LABEL：用于为镜像添加元数据。使用LABEL指定元数据时，一条LABEL指定可以指定一或多条元数据，指定多条元数据时不同元数据之间通过空格分隔。推荐将所有的元数据通过一条LABEL指令指定，以免生成过多的中间镜像。如 `LABEL version=“1.0” description=“这是一个Web服务器” by=“IT笔录”`
- COPY：从宿主机复制文件或目录到容器内的指定路径，容器内的路径必须存在，不能自动创建

<br>
## 2.6 Docker容器迁移
①从容器创建一个新的镜像
```
docker commit -a "cj" -m "openldap" openldap openldap:cj
```
>-a :提交的镜像作者；
>-c :使用Dockerfile指令来创建镜像；
>-m :提交时的说明文字；
>-p :在commit时，将容器暂停。

②打包镜像
```
docker save -o openldap.tar openldap:cj
```
>-o :输出到的文件

③拷贝到目标服务器
```
rsync openldap.tar root@192.168.101.174:`pwd`
```
>两台服务器上都需要安装rsync，不安装的话也可以通过scp命令来传输。

④新服务器载入镜像
执行如下命令将打包后的镜像导入
```
docker load --input openldap.tar
```
>--input , -i : 指定导入的文件，代替 STDIN
--quiet , -q : 精简输出信息。

⑤运行容器
```
docker run -d -p 389:389  -p 636:636 --name openldap --env LDAP_ORGANISATION="se" --env LDAP_DOMAIN="ldap.chenjie.asia" --env LDAP_ADMIN_PASSWORD="abc123" osixia/openldap
```

<br>
# 三、docker-compose
## 3.1 概念
docker-compose是一个编排多容器分布式部署的工具，提供命令集管理容器化应用的完整开发周期，包括服务构建，启动和停止。
1.利用Dockerfile定义运行环境镜像
2.使用docker-compose.yml定义组成应用的各服务
3.运行docker-compose up启动应用

## 3.2 docker-compose安装
①下载编译好的二进制包，安装到linux系统中  
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
②修改可执行权限  chmod +x  /usr/local/bin/docker-compose
③查看版本  docker-compose -version

## 3.3 配置文件
1. image：指定服务的镜像名称或镜像 ID。如果镜像在本地不存在，Compose 将会尝试拉取这个镜像。
2. build：服务除了可以基于指定的镜像，还可以基于一份 Dockerfile，在使用 up 启动之时执行构建任务，这个构建标签就是 build，它可以指定 Dockerfile 所在文件夹的路径。Compose 将会利用它自动构建这个镜像，然后使用这个镜像启动服务容器。
如果你同时指定了 image 和 build 两个标签，那么 Compose 会构建镜像并且把镜像命名为 image 后面的那个名字。
```
build: /path/to/build/dir
# 如果你要指定 Dockerfile 文件需要在 build 标签的子级标签中使用 dockerfile 标签指定
build:
  context: ../
  dockerfile: path/of/Dockerfile
# 可以在构建过程中指定环境变量，但是在构建成功后取消
build:
  context: .
  args:
    - buildno=1
    - password=secret
```
3. command：使用 command 可以覆盖容器启动后默认执行的命令。
```
command: bundle exec thin -p 3000
# 或
command: [bundle, exec, thin, -p, 3000]
```
4.container_name：容器的命名
5.depends_on：指定容器的启动先后顺序。
```
version: '2'
services:
  web:
    build: .
    depends_on:
      - db
      - redis
  redis:
    image: redis
  db:
    image: postgres
```
注意的是，默认情况下使用 docker-compose up web 这样的方式启动 web 服务时，也会启动 redis 和 db 两个服务，因为在配置文件中定义了依赖关系。
6. environment
```
environment:
    - MYSQL_ROOT_PASSWORD=hxr
```
7. external_links：在使用Docker过程中，我们会有许多单独使用docker run启动的容器，为了使Compose能够连接这些不在docker-compose.yml中定义的容器，我们需要一个特殊的标签，就是external_links，它可以让Compose项目里面的容器连接到那些项目配置外部的容器（前提是外部容器中必须至少有一个容器是连接到与项目内的服务的同一个网络里面）。
格式如下：
```
external_links:
 - redis_1
 - project_db_1:mysql
 - project_db_1:postgresql
```
8. extra_hosts：添加主机名的标签，就是往/etc/hosts文件中添加一些记录，与Docker client的--add-host类似：
```
extra_hosts:
 - "somehost:162.242.195.82"
 - "otherhost:50.31.209.229"
```
9. links：还记得上面的depends_on吧，那个标签解决的是启动顺序问题，这个标签解决的是容器连接问题，与Docker client的--link一样效果，会连接到其它服务中的容器。
格式如下：
```
links:
 - db
 - db:database
 - redis
```
使用的别名将会自动在服务容器中的/etc/hosts里创建。例如：
```
172.12.2.186  db
172.12.2.186  database
172.12.2.187  redis
```
相应的环境变量也将被创建。
10. pid：将PID模式设置为主机PID模式，跟主机系统共享进程命名空间。容器使用这个标签将能够访问和操纵其他容器和宿主机的名称空间。
```
pid: "host"
```
11. ports：映射端口的标签。
12. volumes：挂载一个目录或者一个已存在的数据卷容器。
13. volumes_from：从其它容器或者服务挂载数据卷，可选的参数是 :ro或者 :rw，前者表示容器只读，后者表示容器对数据卷是可读可写的。默认情况下是可读可写的。
```
volumes_from:
  - service_name
  - service_name:ro
  - container:container_name
  - container:container_name:rw
```
14. network_mode：网络模式，与Docker client的--net参数类似，只是相对多了一个service:[service name] 的格式。
例如：
```
network_mode: "bridge"
network_mode: "host"
network_mode: "none"
network_mode: "service:[service name]"
network_mode: "container:[container name/id]"
```
15. networks：加入指定网络。

<br>
## 3.4 compose文件
```yml
version: '3' # 文件的版本号
services:      # 需要启动的所有服务
  nginx01:       # 启动的服务名为nginx
    container_name: nginx01  # 指定容器名
    image: nginx  # 需要启动的镜像名称和版本
    ports:
      - 80:80     # 端口映射
    links:
      - app       # 当前容器可以访问或挂载到的项目名
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d  # 数据卷
      - nginxvolume:/etc/nginx/conf.d     # 此处使用的卷名前会将加上项目名(所在文件夹名)，需要和创建的卷名对应
    networks:     # 代表当前服务使用哪个网络桥
        - hello
  nginx02:       # 启动的服务名为nginx
    container_name: nginx01  # 指定容器名
    image: nginx  # 需要启动的镜像名称和版本
    ports:
      - 81:80     # 端口映射
    links:
      - app       # 当前容器可以访问或挂载到的项目名
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d  # 数据卷
      - nginxvolume:/etc/nginx/conf.d     # 此处使用的卷名前会将加上项目名(所在文件夹名)，需要和创建的卷名对应
    networks:     # 代表当前服务使用哪个网络桥
      - hello
        
  mysql:
    container_name: mysql
    image: mysql:5.7.32
    ports:
      - 3306:3306
    volumes:
      - /root/mysql/conf:/etc/mysql
      - /root/mysql/log:/var/log/mysql
      - /root/mysql/data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=hxr
    networks:
      - hello
  
      
volumes:  # 如果绑定到数据卷，需要另外定义该卷名
  nginxvolume: # 声明指令的卷名 compose自动创建该卷名但是会在之前加入项目名
    external: 
      false # false表示创建的卷会添加上项目名，如果是true表示创建的卷不加项目名。
            
network:  # 定义服务用到的桥
  hello: # 定义桥的名称，默认创建的就是 bridge。
    external: 
      false # false表示创建添加上项目名的网桥，如果是true表示使用外部已存在的网桥。
```
通过 docker-compose up -d 指令在后台启动所有容器，如果不加-d参数，会在当前对话中启动服务。默认启动docker-compose.yml，可以-f指定启动文件。


[https://www.jianshu.com/p/2217cfed29d7](https://www.jianshu.com/p/2217cfed29d7)


<br>
# 四、Docker部署
## 4.1 jar包部署
**创建dockerfile文件**
```
FROM java:8/openjdk:8-jdk-alpine
VOLUME /tmp
ADD asrs-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8764
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
```
**构建镜像**
```shell
docker build -t newworkhourbackend .
```
**启动容器**
```shell
docker run -p 8764:8764 -d newworkhourbackend
```
>备注：
>1.-Djava.security.egd=file:/dev/./urandom  用于jvm高效的产生随机数。
>2.可以通过制定--restart参数让容器关闭后重启：docker run-m 512m--memory-swap1G-it-p6379:6379--restart=always--name redis-d redis
参数为①no - 容器退出时，不重启容器②on-failure - 只有在非0状态退出时才从新启动容器③always - 无论退出状态是如何，都重启容器
如果创建时未指定 --restart=always ,可通过 update 命令：docker update --restart=always xxx
>4.使用docker exec -it name/id /bin/bash进入容器中，一般不使用docker attach name/id进入容器中。（如果没有/bin/bash指令，则使用/bin/sh）
>5.如果容器中没有vim命令，执行apt-get install vim安装vim；如果安装命令出错，需要先执行更新命令apt-get update。

<br>
## 4.2 常见中间件部署
#### Redis
```shell
docker run -d --privileged=true -p 6379:6379 --restart always -v /root/docker/redis/conf/redis.conf:/etc/redis/redis.conf -v /root/docker/redis/data:/data --name myredis redis redis-server /etc/redis/redis.conf --appendonly yes
```
>--restart always                                                  -> 开机启动
>--privileged=true                                                   -> 提升容器内权限
>-v /root/docker/redis/conf:/etc/redis/redis.conf      -> 映射配置文件
>-v /root/docker/redis/data:/data                              -> 映射数据目录
>--appendonly yes                                                    -> 开启数据持久化

#### RabbitMQ
```shell
docker pull rabbitmq:management
docker run -d -p 5672:5672 -p 15672:15672  --name rabbitmq rabbitmq:management
```

#### ES可视化组件 elasticsearch-head
```shell
docker pull mobz/elasticsearch-head:5
docker run -d -p 9100:9100 --name es-head mobz/elasticsearch-head:5
```
#### MySQL
```shell
docker run -d --restart always --name mysql -p 3306:3306 -v /root/docker/mysql/conf:/etc/mysql -v /root/docker/mysql/log:/var/log/mysql -v /root/docker/mysql/lib:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=cj mysql:5.7
```
>/etc/mysql ：默认存放配置文件的路径
>/var/lib/mysql ：默认存放binlog日志的路径


#### Tomcat
```
docker run --name tomcat -p 8080:8080 -v /root/docker/tomcat/conf:/conf -v /root/docker/tomcat/logs:/logs -v /root/docker/tomcat/webapps:/usr/local/tomcat/webapps -d tomcat:8.5.78-jre8-temurin-focal
```
