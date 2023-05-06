---
title: Kali命令
categories:
- Linux
---
[Index of /kali-images](http://old.kali.org/kali-images/)
[Kali Linux 官网](https://www.kali.org/)

如果要用xshell连接，需要先启动ssh服务
```
systemctl start ssh
```

1. 修改源为中科大源 vim /etc/apt/sources.list
```
# deb http://http.kali.org/kali kali-rolling main contrib non-free
deb http://mirrors.ustc.edu.cn/kali kali-rolling main non-free contrib
deb-src http://mirrors.ustc.edu.cn/kali kali-rolling main non-free contrib
```
>deb代表软件位置，deb-src代表软件的源代码位置。
跟在网址后的选项是源中的文件夹，表示实际使用到的软件包类型。

Kali Rolling是Kali的即时更新版，只要Kali中有更新，更新包就会放入Kli Rolling中，供用户下载使用。他为用户提供了一个稳定更新的版本，同时会带有最新的更新安装包。这是我们最常使用的源。
在Kali Rolling下有3类软件包：main、non-free和contrib。Kali apt源的软件包类型说明：
|dists区域|软件包组件标准|
|--|--|
|main|遵从Debian自由软件指导方针(DFSG),并且不依赖于non-free|
|contrib|遵从Debian自由软件指导方针(DFSG),但依赖于non-free|
|non-free|不遵从Debian自由软件指导方针(DFSG)|
注：DFSG是Debian自由软件指导方针(Debian Free Software Guidelines)，此方针中大体包括自由的再次发行、源代码、禁止歧视人士或组织等规定。

2. 更新已安装的软件包的最新版本的列表
```
apt update
```
>apt update 的作用是从/etc/apt/sources.list文件中定义的源中获取最新的软件包列表。即运行apt update并没有更新软件，而是相当于windows下面的检查更新，获取包的最新状态。

3. 更新所有软件包
```
apt upgrade
```
或
```
apt dist-upgrade
```
>区别：upgrade升级时，如果软件包有相依性，此软件包就不会被升级。
dist-upgrade升级时，如果软件包有相依性问题，会移除旧版(如果其他包依赖旧版本，就会报错)，直接安装新版本(所以通常dist-upgrade会被任务是有升级风险的)

4. apt和apt-get区别
apt是一条linux命令，适用于deb包管理式的操作系统，主要用于自动从互联网的软件仓库中搜索、安装、升级、卸载软件或操作系统。deb包是Debian软件包格式的文件扩展名。
apt可以看作apt-get和apt-cache命令的子集，可以为包管理提供必要的命令选项。
apt提供了大多数与apt-get及apt-cache有的功能，但更方便使用
apt-get虽然没有被弃用，但作为普通用户，还是应该首先使用apt。
注：apt install和pat-get install功能一样，都是安装软件包，没有区别。

5. 配置静态ip
vim /etc/network/interfaces
```
auto eth0
iface eth0 inet static
address 192.168.2.66
netmask 255.255.255.0
gateway 192.168.2.1
```
>确保与所在的局域网的网段相同，且ip地址未被使用(即无法ping通的地址)。注意网关需要与宿主机相同，在NAT模式下需要查看对应网卡的网关地址(在vmware中 【编辑->虚拟网络编辑器->NAT设置】 中查看，同时需要关闭[使用本机DHCP服务将IP地址分配给虚拟机]选项)

重启网络服务
```
systemctl stop NetworkManager
systemctl restart networking
systemctl restart networking
systemctl start NetworkManager
```
>关闭NetworkManager服务，该服务是网络服务的图形管理工具，该服务会自动接管networking服务，有可能造成重启networking服务时配置不生效的问题

修改默认DNS
vim /etc/resolv.conf
```
nameserver 114.114.114.114
```

6. 配置临时ip
```
ifconfig eth0 192.168.2.65
```
还可给一张网卡再配置一个或多个临时ip
```
ifconfig eth0:1 192.168.101.60 
```

这些临时ip，会在重启电脑或重启网络服务时失效。

7. 受限制的网络使用NAT模式更换ip地址
在虚拟机配置中修改为NAT模式，在VMWARE的【编辑->虚拟网络编辑器】中打开[使用本机DHCP服务将IP地址分配给虚拟机]选项。

然后修改Kali网络配置
vim /etc/network/interfaces
```
auto eth0
iface eth0 inet dhcp
```

重启网络服务
```
systemctl stop NetworkManager
systemctl restart networking
systemctl restart networking
systemctl start NetworkManager
```

查看网关
```
route -n
```


<br>
## 8. 服务器域名和IP
### 8.1正向解析ip地址
- 通过ping方式
   ```
   ping www.baidu.com -c 1
   ```

- 通过nslookup
   ```
   nslookup www.baidu.com
   ```
   通过nslookup可以得到更加详细的信息

- 通过dig命令
   ```
   dig @114.114.114.114 www.baidu.com
   ```

dig命令可以指定DNS服务器进行解析，加上any后可以所有
```
└─$ dig @8.8.8.8 baidu.com any 

; <<>> DiG 9.18.0-2-Debian <<>> @8.8.8.8 baidu.com any
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 6312
;; flags: qr rd ra; QUERY: 1, ANSWER: 17, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;baidu.com.			IN	ANY

;; ANSWER SECTION:
baidu.com.		6671	IN	SOA	dns.baidu.com. sa.baidu.com. 2012145367 300 300 2592000 7200
baidu.com.		21071	IN	NS	ns7.baidu.com.
baidu.com.		21071	IN	NS	ns3.baidu.com.
baidu.com.		21071	IN	NS	dns.baidu.com.
baidu.com.		21071	IN	NS	ns2.baidu.com.
baidu.com.		21071	IN	NS	ns4.baidu.com.
baidu.com.		71	IN	A	220.181.38.251
baidu.com.		71	IN	A	220.181.38.148
baidu.com.		6671	IN	MX	20 mx1.baidu.com.
baidu.com.		6671	IN	MX	20 jpmx.baidu.com.
baidu.com.		6671	IN	MX	20 mx50.baidu.com.
baidu.com.		6671	IN	MX	20 usmx01.baidu.com.
baidu.com.		6671	IN	MX	10 mx.maillb.baidu.com.
baidu.com.		6671	IN	MX	15 mx.n.shifen.com.
baidu.com.		6671	IN	TXT	"_globalsign-domain-verification=qjb28W2jJSrWj04NHpB0CvgK9tle5JkOq-EcyWBgnE"
baidu.com.		6671	IN	TXT	"v=spf1 include:spf1.baidu.com include:spf2.baidu.com include:spf3.baidu.com include:spf4.baidu.com a mx ptr -all"
baidu.com.		6671	IN	TXT	"google-site-verification=GHb98-6msqyx_qqjGl5eRatD3QTHyVB6-xQ3gJB5UwM"

;; Query time: 84 msec
;; SERVER: 8.8.8.8#53(8.8.8.8) (TCP)
;; WHEN: Sat May 14 03:01:12 EDT 2022
;; MSG SIZE  rcvd: 631
```

### 8.2 反向解析域名
- dig -x
```
dig -x 114.114.114.114

; <<>> DiG 9.18.0-2-Debian <<>> -x 114.114.114.114
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 60999
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;114.114.114.114.in-addr.arpa.	IN	PTR

;; ANSWER SECTION:
114.114.114.114.in-addr.arpa. 37 IN	PTR	public1.114dns.com.

;; Query time: 11 msec
;; SERVER: 114.114.114.114#53(114.114.114.114) (UDP)
;; WHEN: Sat May 14 03:12:11 EDT 2022
;; MSG SIZE  rcvd: 89
```
解析出DNS服务器114.114.114.114的域名为public1.114dns.com.

- 查询DNS服务器的版本信息
```
└─$ dig txt chaos VERSION.BIND @ns3.dnsv4.com     
;; Warning: query response not set
;; Warning: Message parser reports malformed message packet.

; <<>> DiG 9.18.0-2-Debian <<>> txt chaos VERSION.BIND @ns3.dnsv4.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 46619
;; flags: rd ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; QUESTION SECTION:
;VERSION.BIND.			CH	TXT

;; ANSWER SECTION:
VERSION.BIND.		0	CH	TXT	"DNSPod AUTHORITY DNS 7.2.2203.00"

;; Query time: 15 msec
;; SERVER: 129.211.176.242#53(ns3.dnsv4.com) (UDP)
;; WHEN: Sat May 14 03:15:34 EDT 2022
;; MSG SIZE  rcvd: 75
```
可以查询到域名为ns3.dnsv4.com的DNS服务器版本号为DNSPod AUTHORITY DNS 7.2.2203.00，可以通过google查询这个版本的楼栋进行渗透。

- 查询网站的域名注册信息和备案信息
```
└─$ whois baidu.com   
   Domain Name: BAIDU.COM
   Registry Domain ID: 11181110_DOMAIN_COM-VRSN
   Registrar WHOIS Server: whois.markmonitor.com
   Registrar URL: http://www.markmonitor.com
   Updated Date: 2022-01-25T09:00:46Z
   Creation Date: 1999-10-11T11:05:17Z
   Registry Expiry Date: 2026-10-11T11:05:17Z
   Registrar: MarkMonitor Inc.
   Registrar IANA ID: 292
   Registrar Abuse Contact Email: abusecomplaints@markmonitor.com
   Registrar Abuse Contact Phone: +1.2086851750
   Domain Status: clientDeleteProhibited https://icann.org/epp#clientDeleteProhibited
   Domain Status: clientTransferProhibited https://icann.org/epp#clientTransferProhibited
   Domain Status: clientUpdateProhibited https://icann.org/epp#clientUpdateProhibited
   Domain Status: serverDeleteProhibited https://icann.org/epp#serverDeleteProhibited
   Domain Status: serverTransferProhibited https://icann.org/epp#serverTransferProhibited
   Domain Status: serverUpdateProhibited https://icann.org/epp#serverUpdateProhibited
   Name Server: NS1.BAIDU.COM
   Name Server: NS2.BAIDU.COM
   Name Server: NS3.BAIDU.COM
   Name Server: NS4.BAIDU.COM
   Name Server: NS7.BAIDU.COM
   DNSSEC: unsigned
   URL of the ICANN Whois Inaccuracy Complaint Form: https://www.icann.org/wicf/
>>> Last update of whois database: 2022-05-14T07:20:39Z <<<
```

可以使用[maltego](https://www.baidu.com/link?url=mfvks--EQQ9fmCej_VIGuA408KX6gxQch1wU24D5hoYWW59Mmpn6DqqbzVezib6-&wd=&eqid=83d9576e000d639f00000004627f6abd)工具进行子域名查询
