---
title: 玩客云docker安装openwrt作为旁路由
categories:
- 日记本
---
# 一、安装openwrt
[jyhking/onecloud - Docker Image | Docker Hub](https://hub.docker.com/r/jyhking/onecloud)

1. 安装docker
`apt install docker.io`
2. 打开网卡混杂模式：在混杂模式下的网卡能够接收一切通过它的数据，而不管该数据目的地址是否是它。如果通过程序将网卡的工作模式设置为 “混杂模式”，那么网卡将接受所有流经它的数据帧.
`ip link set eth0 promisc on`
3. 创建网络(根据玩客云所在网段修改，如玩客云IP:192.168.1.175，则192.168.0.0/24改成192.168.1.0/24，192.168.0.1改成主路由地址)
`docker network create -d macvlan --subnet=192.168.100.0/24 --gateway=192.168.100.1 -o parent=eth0 macnet`
4. 拉取运行镜像
`docker pull jyhking/onecloud:1.1`
`docker run -itd --name=OneCloud --restart=always --network=macnet --privileged=true jyhking/onecloud:1.1 /sbin/init`
镜像 https://www.right.com.cn/forum/thread-8024126-1-1.html


🔵更新软件（非必要）

`apt-get update && apt-get upgrade`

🔵安装 Docker

`apt install docker.io`

🔵打开网卡混杂模式

`ip link set eth0 promisc on`

🔵创建网络

`docker network create -d macvlan --subnet=192.168.0.0/24 --gateway=192.168.0.1 -o parent=eth0 macnet`

>🔘[↑自己根据 玩客云 所在网段修改，如：玩客云IP:192.168.1.175，则192.168.0.0/24 改成 192.168.1.0/24，192.168.0.1改成主路由地址]

🔵拉取 OpenWRT 镜像

`docker pull jyhking/onecloud:1.1`

🔵创建容器

`docker run -itd --name=onecloud --restart=always --network=macnet --privileged=true -v /root/docker/onecloud/config:/etc/config -v /root/docker/onecloud/core:/etc/openclash/core jyhking/onecloud:1.1 /sbin/init`


🔵根据主路由 DHCP 分配里找到一个主机名叫 OpenWRT 的，复制它的IPv4 地址粘贴到浏览器就能进入 OpenWRT 了，管理密码是 password


<br>
# 二、配置旁路由
1. 成功启动openwrt后，在路由器后台中寻找openwrt所在的ip地址，进入openwrt(默认密码是password)。
2. 打开 网络->接口->修改

![image.png](玩客云docker安装openwrt作为旁路由.assetse3a13cb451040578171aaeb8112f2fc.png)

因为修改了静态ip地址，所以输入静态ip地址进入openwrt，再次 打开 网络->接口->修改

![image.png](玩客云docker安装openwrt作为旁路由.assets\990264e0227a43e09a989c93cb51e9e2.png)

![image.png](玩客云docker安装openwrt作为旁路由.assets\20fc51f4c5e649b997d01e0dfd70b11d.png)

![image.png](玩客云docker安装openwrt作为旁路由.assets\d3c16383683b408fa47b2fb44d7ecbf2.png)


3. 接下来修改路由器中的默认网关和DNS服务器，指向openwrt所在ip。这样主路由的DHCP服务器在为接入的设备分配IP地址时会自动为其设置网关和DNS服务器为openwrt所在服务器。

![image.png](玩客云docker安装openwrt作为旁路由.assets\4e0b739fe00d409781216543446f8387.png)

修改完成后重启主路由。
这样将openwrt作为旁路由的设置完成。

<br>
# 三、配置代理
OpenWrt上的PassWall中包含V2ray、SSR等客户端，但是没有Clash，此处先安装Clash客户端。

进入openwrt容器中
`docker exec -it onecloud /bin/sh`
用于在 OpenWrt 系统中查看当前系统的架构信息
`opkg print-architecture`
输出结果
```
arch all 1
arch noarch 1
arch arm_cortex-a5_vfpv4 10
```
那么符合架构的插件的下载地址为 [https://op.supes.top/packages/arm_cortex-a5_vfpv4/luci-app-openclash_0.45.112-239_all.ipk](https://op.supes.top/packages/arm_cortex-a5_vfpv4/luci-app-openclash_0.45.112-239_all.ipk)

<br>
**安装插件：有两种方法，一种是通过openwrt页面进行安装，另一种是通过命令进行安装**
- **方法一**
   1. 在网页[Openwrt Download Server (supes.top)](https://op.supes.top/packages/)中下载[对应的openclash插件](https://op.supes.top/packages/arm_cortex-a5_vfpv4/luci-app-openclash_0.45.112-239_all.ipk)，
在openwrt的 系统->文件传输 中上传下载的ipk文件，然后在上传文件列表中点击安装，
如果报错则需要先更新opkg `opkg update`后再次进行安装，然后就可以在软件包中找到刚安装的luci-app-openclash。
   2. 在 openclash->插件设置->版本更新 内更新Dev内核。如果无法更新Dev内核，那么只能通过方法二中的第二步，使用命令的方式进行更新。

- **方法二**
   1. 下载luci-app-openclash
      `wget https://op.supes.top/packages/arm_cortex-a5_vfpv4/luci-app-openclash_0.45.112-239_all.ipk`
      安装luci-app-openclash
      `opkg install luci-app-openclash_0.45.112-239_all.ipk`

   2. 安装内核
      安装依赖
      ```
      #iptables
      opkg update
      opkg install coreutils-nohup bash iptables dnsmasq-full curl ca-certificates ipset ip-full iptables-mod-tproxy iptables-mod-extra libcap libcap-bin ruby ruby-yaml kmod-tun kmod-inet-diag unzip luci-compat luci luci-base
      #nftables
      opkg update
      opkg install coreutils-nohup bash dnsmasq-full curl ca-certificates ipset ip-full libcap libcap-bin ruby ruby-yaml kmod-tun kmod-inet-diag unzip kmod-nft-tproxy luci-compat luci luci-base
      ```
      如果出现异常**Could not lock /var/lock/opkg.lock: Resource temporarily unavailable**，执行`rm -f /var/lock/opkg.lock`后继续安装。
      如果出现异常*** pkg_hash_check_unresolved: cannot find dependency kernel (= 5.15.110-1-6b9bd4963d3b1d3f8d9e6511f2d73cf0) for kmod-nf-reject**，`wget https://downloads.openwrt.org/snapshots/targets/x86/64/packages/kernel_5.15.110-1-94722c175737d5d5ca67a7ccacfc3e60_x86_64.ipk;opkg install kernel_5.15.110-1-94722c175737d5d5ca67a7ccacfc3e60_x86_64.ipk`
      进入内核安装目录
      `cd /etc/openclash/core/`
      下载内核安装包
      `wget https://github.com/vernesong/OpenClash/releases/download/Clash/clash-linux-armv7.tar.gz`
      `wget https://github.com/vernesong/OpenClash/releases/download/TUN-Premium/clash-linux-armv7-2022.06.19-13-ga45638d.gz`
      解压内核安装包
      `tar -zxvf clash-linux-armv7.tar.gz`
      `gzip -dk clash-linux-armv7-2022.06.19-13-ga45638d.gz;mv clash-linux-armv7-2022.06.19-13-ga45638d clash_tun `
      给予最高权限
     `chmod 777 clash`
     `chmod 777 clash_tun`


**最后说明**
完成安装后重启设备，进入 OpenClash 后在 “全局设置”>“版本更新”内将 Dev, TUN, Game 进行更新，模式设置推荐使用 Fake-IP (TUN - 混合) 模式，启用本地DNS，如何配置节点可查看[OpenWrt 安装 OpenClash 插件并配置节点 - 彧繎博客 (opclash.com)](https://opclash.com/luyou/80.html)


<br>
# 四、远程唤醒
