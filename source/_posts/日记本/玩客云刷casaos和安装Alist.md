---
title: 玩客云刷casaos和安装Alist
categories:
- 日记本
---
| 架构 | 输出结果 | 
| --- | --- |
| i386 | i386，i686 |
| amd64 | x86_64 |
| arm_garbage | arm, armel |
| armv7 | armv7l, armhf |
| arm64 | aarch64, armv8l |
| mips* | mips |
| mips64* | mips64 |
>输入`uname -m`可以查看对应的架构，玩客云输出的是armv7l，对应的是armv7架构。在安装软件时需要注意对应的版本。


玩客云armbian固件下载地址：https://github.com/hzyitc/armbian-onecloud/releases
需要注意的是，casaos还不能支持最新版的底包，所以我们需要下载之前的老版本。在下载页面上往下拉，找到6.1.9这个版本。我们需要去下载带mini和burn字样的刷机包。mini代表最小安装包，burn代表线刷包。


1. 检查时间
`date -R`

如果时区及时间不对。执行下面的操作
`cp /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime`

再次检查时间
`date -R`


2. 接下来是添加系统的软件源，这样可以提高安装成功率。输入：
`nano /etc/apt/sources.list`

然后按方向键到最后在空白处添加以下代码：
```
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-updates main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye-backports main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bullseye-security main contrib non-free
```
按ctrl+x进行保存

3. 然后就是安装casaos系统了，casaos的安装只要这一条代码就可以
`wget -qO- https://get.casaos.io | bash`

如果你的网络不好，可以执行这个国内源代码试试（注意使用了国内源的一键安装以后是无法自动升级casaos系统的）：
`curl -fsSL cn-get.casaos.io | bash`

小贴士：有很多小伙伴会卡在安装这步，主要还是网络问题。因为casaos的软件源在国外，大家有加速环境的最好能用上。
另外，还总结了一些方法：

换源是可以把原先的软件源用“#”注释掉。比如
`# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bullseye main contrib non-free`
这句前面加了“#”，系统就不会运行这句代码了。同样地可以把复制粘贴的新代码去掉注释，这样就会有更多的新软件源。
另外有的网友不添加软件源反而安装成功了，大家也可以试试。（我怀疑是网络原因，与换源无关）
最后还有小伙伴说他用最新版的底包刷机就成功了，我之前刷机的时候是不成功的。也许是casaos更新了版本的缘故。

4. 安装好以后，在ssh里运行这一段命令，安装alist的docker镜像：
`docker run -d --restart=always -v /etc/alist:/opt/alist/data -p 5244:5244 -e PUID=0 -e PGID=0 -e UMASK=022 --name="alist" xhofe/alist:latest`

在运行这个命令来查看alist的用户密码：
`docker exec -it alist ./alist admin`
