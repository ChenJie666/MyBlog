---
title: Kerberos认证管理
categories:
- 权限认证
---
# 一、Windows中的认证
## 1.1 单机认证
NTLM Hash是支持Net NTML认证协议及本地认证过程中的一个重要参与物，其长度为32位，由数字与字母组成。NTLM前身是LM Hash，目前基本淘汰。
1. Windows本身不存储用户的明文密码。它会将用户的明文密码经过指纹加密算法后存储在SAM数据库中。
2. 当用户登陆时，将用户输入的明文密码也加密成NTML Hash，与SAM数据库中的NTML Hash进行比较。


## 1.2 网络认证
在内网渗透中，经常遇到工作组环境，工作组间的机器无法互相建立一个完美的信任机制，只能点对点，没有**信托机构**。
假设A与B属于一个工作组，A想访问B注解上的资料，需要将一个存在于B主机上的账户凭证发送到B主机，经过认证才能访问B主机上的资源。最常见的服务就是SMB服务，端口号为445。

微软采用了NTLM(NT LAN Manager)协议进行多节点之间的验证。
1. Server接收到Client发送的用户名后，判断本地账户列表是否有用户名share_user。如果没有，返回认证失败；如果有，生成16位的随机字符串challenge，并从本地查找share_user对应的密码指纹NTLM Hash，使用NTLM Hash加密Challenge，生成Net-NTLM Hash存储在内存中，并将Challenge发送给Client。
2. Client接收到Challenge后，将自己提供的share_user的密码加密为NTLM Hash，然后使用NTLM Hash加密Challenge，这个结果叫Response，发送给Server。
3. Server接收到Client发送的Response，将Response与之前的Net-NTLM Hash进行比较，如果相等，则认证通过。

![image.png](Kerberos认证管理.assets\578c54447e914618969101538814cfe6.png)


<br>
# 二、Kerberos验证体系
## 2.1 概念
**Kerberos是一种网络协议**，设计目的是通过密钥系统为客户端和服务器应用系统提供强大的认证服务。该认证过程的实现不依赖于主机操作系统的认证，无需基于主机地址的信任，不要求网络上所有主机的物理安全，**并假设网络上传送的数据包可以被任意读取、修改和插入数据**。在以上情况下，Kerberos作为一种可信任的**第三方认证服务**，是通过传统的密码技术(如共享密钥)执行认证服务的。
Kerberos是比NTLM更新的验证体系，不怕中间人攻击，而NTLM的Net-NTLM Hash是有可能被拦截并破解的。

Kerberos 中有以下一些概念需要了解
1. KDC(Key Distribute Center)：密钥分发中心，负责存储用户信息，管理发放票据。
2. Realm：Kerberos所管理的一个领域或范围，称之为一个Realm
3. Principal：Kerberos所管理的一个用户或者一个服务，可以理解为Kerberos中保存的一个账号，其格式通常如下：primary/instance@realm  ，即 账号/实例名@域名，其中instance可以省略。
4. Keytab：Kerberos中的用户认证，可通过密码或者密钥文件证明身份，keytab指密钥文件。


## 2.2 从原理上来分析
Authentication解决的是“如何证明某个人确确实实就是他或她所声称的那个人”的问题。对于如何进行Authentication，我们采用这样的方法：如果一个秘密（secret）仅仅存在于A和B，那么有个人对B声称自己就是A，B通过让A提供这个秘密来证明这个人就是他或她所声称的A。这个过程实际上涉及到3个重要的关于Authentication的方面：
- Secret如何表示。
- A如何向B提供Secret。
- B如何识别Secret。

基于这3个方面，我们把Kerberos Authentication进行最大限度的简化：整个过程涉及到Client和Server，他们之间的这个Secret我们用一个Key（KServer-Client）来表示。Client为了让Server对自己进行有效的认证，向对方提供如下两组信息：
- 代表Client自身Identity的信息，为了简便，它以明文的形式传递。
- 将Client的Identity使用 KServer-Client作为Public Key、并采用对称加密算法进行加密。

由于KServer-Client仅仅被Client和Server知晓，所以被Client使用KServer-Client加密过的Client Identity只能被Client和Server解密。同理，Server接收到Client传送的这两组信息，先通过KServer-Client对后者进行解密，随后将机密的数据同前者进行比较，如果完全一样，则可以证明Client能过提供正确的KServer-Client，而这个世界上，仅仅只有真正的Client和自己知道KServer-Client，所以可以对方就是他所声称的那个人。

**如何使得client和server双方拿到KServer-Client且保证该KServer-Client是短期有效的，防止被破解？**

这里引入了第三方角色KDC(Kerberos Distribution Center)，其包含以下三个组件：
- AD(account database)：存储所有client的白名单，只有存在于白名单的client才能顺利申请到TGT(Ticket Granting Ticket，即申请票据的票据)
- AS(Authentication Service)：为client提供认证服务，通过认证后返回TGT
- TGS(Ticket Granting Service)：为client提供通过TGT兑换Ticket的服务，生成某个服务的ticket

**KDC分发SServer-Client的简单的过程：**首先Client向KDC发送一个对SServer-Client的申请。这个申请的内容可以简单概括为“我是某个Client，我需要一个Session Key用于访问某个Server ”。KDC在接收到这个请求的时候，生成一个随机串Session Key，为了保证这个Session Key仅仅限于发送请求的Client和他希望访问的Server知晓，KDC会为这个Session Key生成两个Copy，分别被Client和Server使用。然后从Account Database中查询Client和Server的密码指纹NTLM Hash分别对这两个Copy进行对称加密，前者加密得到Client Hash。对于后者，和Session Key一起被加密的还包含关于Client的一些信息，称为TGT。
通过TGT向AS请求获取认证Server端的Ticket。

但是Client Hash和Ticket并不是分别发送给Client和Server端的，而是都发送给Client端，这样避免了网络延迟等情况导致Server端未收到Ticket，无法验证Client的请求。最后统一由Client发送给Server。这样Client端会收到两个信息，一个是自己的密码指纹可以解密的Client Hash，另一个是Server的密码指纹才能解密的Ticket。

**如果避免B客户端伪造为A客户端请求KDC认证的情况发生呢？**
因为KDC会查询A客户端的密码指纹NTLM Hash进行对称加密，B客户端不知道这个指纹，是无法解密Client Hash的。但是存在暴力破解的情况，所以Client需要更多信息才证明自己的合法性，这里引入了Timestamp标记了创建时间，如果时间花费过多，那么存在中间人拦截后暴力破解伪造请求的可能性。

Client使用自己的指纹解密Client Hash后获取Session Key，创建Authenticator(Client Info + Timestamp)并使用Session Key进行加密。随后将Authenticator和缓存的Ticket发送给Server进行验证。

Server端收到请求后，使用自己的密码指纹解密Ticket，获取到Session Key，Client Info和Timestamp，然后使用Session Key解密Authenticator获取Client Info和Timestamp，比较两个Client Info和Timestamp，如果Client Info相同且时间戳在合理误差内，则验证通过。

**Kerberos一个重要的优势在于它能够提供双向认证：**
不但Server可以对Client 进行认证，Client也能对Server进行认证。如果Client需要对他访问的Server进行认证，会在它向Server发送的Credential中设置一个是否需要认证的Flag。Server在对Client认证成功之后，会把Authenticator中的Timestamp提出出来，通过Session Key进行加密，当Client接收到并使用Session Key进行解密之后，如果确认Timestamp和原来的完全一致，那么他可以认定Server正式他试图访问的Server。因为Server获取Session Key的唯一途径是使用本机的密码指纹来解密Session Ticket，这样就可以认证Server。

**小结**
Kerberos实际上一个基于Ticket的认证方式。Client想要获取Server端的资源，先得通过Server的认证；而认证的先决条件是Client向Server提供从KDC获得的一个有Server的密码指纹进行加密的Session Ticket（Session Key + Client Info）。可以这么说，Session Ticket是Client进入Server领域的一张门票。而这张门票必须从一个合法的Ticket颁发机构获得，这个颁发机构就是Client和Server双方信任的KDC， 同时这张Ticket具有超强的防伪标识：它是被Server的密码指纹加密的。对Client来说， 获得Session Ticket是整个认证过程中最为关键的部分。

## 2.3 详细流程
**知识点**
- 每次通信，消息包含两部分，一部分可解码，一部分不可解码。
- 服务端不会直接向KDC通信
- KDC保存所有机器的账户名和密码
- KDC本身具有一个密码


**流程**
![image.png](Kerberos认证管理.assetsf08500a968a430bb1635b525fc05aba.png)
1. Client与AS通讯获取TGT(Ticket Granting Ticket)：想要获取http服务，需要向KDC进行认证并返回TGT。Kerberos可以通过kinit获取。
   - 请求信息包含：①用户名/ID ②IP地址 

   AS收到之后会查询AD，验证该用户是否信任，如果信任，AS会生成随机串Session Key。查询Client的密码指纹并使用该指纹加密Challenge得到加密的Session Key，同时使用KDC的密码指纹加密Session Key和Client Info。
   - 响应消息包含两个加密数据包：①TGT(Challenge，Client Info，Timestamp，TGT到期时间，Session Key) ②Client指纹加密的Session Key

   Client收到两个数据包，加密的Session Key可以使用自己的密码指纹解密得到Session Key，另一个TGT无法解密先进行缓存。

2. Client与TGS通讯获取Ticket：上一步获取了TGT和加密的Session Key，现在就可以向KDC请求访问某一个Server的Ticket了。TGT原封不动，将Client Info和Timestamp经过Session Key加密后得到Client Hash，明文Client Info和Server Info作为请求数据进行请求。
   - 请求信息包括：①TGT ②Client Hash ③Client Info和Server Info

   TGS收到请求后，使用自己的密码指纹解密TGT，获取Session Key和Timestamp，使用Session Key解密Client Hash获得Client Info和Timestamp。对比两个Timestamp是否在合理误差内，检查认证器是否已在HTTP服务端的缓存中（避免应答攻击），获取客户端信息比较是否相同，再判断Client是否有访问Server的权限。如果都通过，则TGS会再生成一个随机串Server Session Key，将Client Info，Server Info，Timestamp，Server Session Key，Ticket生命周期用Server的密码指纹进行加密生成Ticket后返回。
   - 响应信息包括：①Ticket(Client Info，Server Info，Timestamp，Server Session Key，Ticket生命周期) ②Client指纹加密后的(Client Info，Server Session Key，Timestamp，生命周期)

   Client收到两个数据包，加密的Authenticator可以使用自己的密码指纹解密得到Server Session Key，另一个TGT无法解密先进行缓存。

3. Client与Server通讯：每次获取Http服务，在Ticket没有过期，或者无更新的情况下，都可直接进行访问。将Client Info，Server Session Key，Timestamp和生命周期用Server Session Key进行加密后得到Authenticator。将Authenticator和Ticket作为请求数据进行请求。
   - 请求信息包括：①Authenticator(Client Info，Server Session Key，Timestamp，生命周期) ②Ticket

   Server收到请求后，通过自己的指纹解密Ticket得到Server Session Key，Client Info和Timestamp。使用Server Session Key解密Authenticator，对比两个Timestamp是否在合理误差内，是否已经过期，获取客户端信息比较是否相同。如果通过则能成功访问Server的资源。


<br>
# 三、Kerberos使用
## 3.1 相关命令
| 说明 | 命令 |
| --- | --- |
| 进入kadmin | kadmin.local / kadmin |
| 创建数据库 | kdb5_util create -r HADOOP.COM -s　 |
| 启动kdc服务 | systemctl start krb5kdc |
| 启动kadmin服务 | systemctl start kadmin |
| 修改当前密码 | kpasswd |
| 测试keytab可用性 | kinit -k -t /home/chen/cwd.keytab [chenweidong@HADOOP.COM](mailto:chenweidong@HADOOP.COM) |
| 查看keytab | klist -e -k -t /home/chen/cwd.keytab　 |
| 清除缓存 | kdestroy |
| 通过keytab文件认证hxr用户登录 | kinit hxr -kt /home/chen/cwd.keytab [chenweidong@HADOOP.COM](mailto:chenweidong@HADOOP.COM) |

| kadmin模式中 | 命令 |
| --- | --- |
| 生成随机key的principal | addprinc -randkey root/[master@HADOOP.COM](mailto:master@HADOOP.COM) |
| 生成指定key的principal | addprinc -pw admin/[admin@HADOOP.COM](mailto:admin@HADOOP.COM) |
| 查看principal | listprincs |
| 修改admin/admin的密码 | cpw -pw xxxx admin/admin |
| 添加/删除principle | addprinc/delprinc admin/admin |
| 直接生成到keytab | ktadd -k /home/chen/cwd.keytab [chenweidong@HADOOP.COM](mailto:chenweidong@HADOOP.COM)xst -norandkey -k /home/chen/cwd.keytab [chenweidong@HADOOP.COM](mailto:chenweidong@HADOOP.COM) #注意：在生成keytab文件时需要加参数”-norandkey”，否则会导致直接使用kinit [chenweidong@HADOOP.COM](mailto:chenweidong@HADOOP.COM)初始化时会提示密码错误。 |
| 设置密码策略(policy) | addpol -maxlife "90 days" -minlife "75 days" -minlength 8 -minclasses 3 -maxfailure 10 -history 10 user |
| 添加带有密码策略的用户 | addprinc -policy user hello/[admin@HADOOP.COM](mailto:admin@HADOOP.COM) |
| 修改用户的密码策略 | modprinc -policy user1 hello/[admin@HADOOP.COM](mailto:admin@HADOOP.COM) |
| 删除密码策略 | delpol [-force] user |
| 修改密码策略 | modpol -maxlife "90 days" -minlife "75 days" -minlength 8 -minclasses 3 -maxfailure 10 user |

## 3.2 Kerberos安装
### 3.2.1 安装Kerberos相关服务
选择集群中的一台注解作为Kerberos服务端，安装KDC，所有主机都需要部署Kerveros客户端。
**服务端主机安装命令**
```
yum install -y krb5-server
```
**客户端主机安装命令**
```
yum install -y krb5-workstation krb5-libs
```

### 3.2.2 修改配置文件
**服务端**
/var/kerberos/krb5kdc/kdc.conf
```
[kdcdefaults]
 kdc_ports = 88
 kdc_tcp_ports = 88

[realms]
 IOTMARS.COM = { 
  #master_key_type = aes256-cts
  acl_file = /var/kerberos/krb5kdc/kadm5.acl
  dict_file = /usr/share/dict/words
  admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
  supported_enctypes = aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal camellia256-cts:normal camellia128-cts:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal
 }
```
- [kdcdefaults] 对kdc进行配置，指定了kdc的端口
- [realms] 对域进行详细的配置
- keytab是最终获取到的Ticket，可以在Server进行验证。这个- keytab是admin的Ticket，不需要去AS和TGS换取Ticket，而是在本地保存了Ticket。
- supported_enctypes是支持的加密类型

只需要修改域的名称即可，端口号、文件位置和加密算法可以不修改。

**客户端**
修改配置 /etc/krb5.conf 并同步到所有客户端节点和服务端节点
```
# Configuration snippets may be placed in this directory as well
includedir /etc/krb5.conf.d/

[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log

[libdefaults]
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = true
 rdns = false
 pkinit_anchors = FILE:/etc/pki/tls/certs/ca-bundle.crt
 default_realm = IOTMARS.COM
 #default_ccache_name = KEYRING:persistent:%{uid}

[realms]
 IOTMARS.COM = {
  kdc = 192.168.101.174
  admin_server = 192.168.101.174
 }
[domain_realm]
 #.example.com = EXAMPLE.COM
 #example.com = EXAMPLE.COM
```
- default_realm：每次输入principal都需要写全primary/instance@realm，如果配置了default_realm就可以省略@realm；
- dns_lookup_kdc：请求kdc时是否需要经过dns。我们直接访问ip即可，设为false；
- default_ccache_name：与系统不兼容，需要注释掉；
- kdc：kdc服务所在的域名或ip
- admin_server：admin_server可以向kdc服务注册自己的信息。需要填写kdc所在的域名或ip。
- [domain_realm] 表示进行域名转换，匹配到的域名都转换到指定的域。这里可以不写。

### 3.2.3 初始化KDC数据库
在服务端执行如下命令，并根据提示输入密码
```
kdb5_util create -s -r IOTMARS.COM
```
- -s选项指定将数据库的主节点密钥存储在文件中，从而可以在每次启动KDC时自动重新生成主节点密钥。记住主密钥，稍后回使用。
- -d指定数据库名字

查看目录/var/kerberos/krb5kdc，发现多了4个文件（principal，principal.kadm5，principal.kadm5.lock，principal.ok），如果需要再次初始化KDC数据库，需要先删除这些文件。

### 3.2.4 修改管理员权限配置文件
在服务端主机修改/var/kerberos/krb5kdc/kadm5.acl文件
```
*/admin@IOTMARS.COM     *
```
表示realm域中的admin组下的所有用户拥有所有权限。

### 3.2.5 启动Kerberos服务
在服务端启动KDC，并设置开机自启
```
systemctl start krb5kdc
systemctl enable krb5kdc
```
在主节点启动Kadmin，该服务为KDC数据库访问入口，即我们配置的admin_server服务
```
systemctl start kadmin
systemctl enable kadmin
```

### 3.2.6 创建Kerberos管理员用户
在KDC服务端执行如下命令创建管理员账户，并按提示创建管理员账户的密码，我自己将密码设置为Password@123。
```
kadmin.local -q "addprinc admin/admin"
```
- kadmin.local相当于是KDC数据库的本地客户端，可以通过该命令来操作KDC数据库。
- -q 就是 -query，表示执行-q后面的语句。
- addprinc即add principal，增加一个账户信息，此处增加了一个管理员账户，且省略了@realm。

本地客户端登陆是不需要账号密码的，所以是安全的。
创建的管理员账户就是为了远程客户端也可以进行访问。

## 3.3 Kerberos使用
登录后双击Tab，可以看到所有的kadmin命令
```
kadmin.local:  
?                 delpol            get_principal     list_policies     modprinc
addpol            delprinc          get_principals    listpols          purgekeys
add_policy        delstr            getprincs         list_principals   q
addprinc          del_string        getprivs          listprincs        quit
add_principal     exit              get_privs         list_requests     rename_principal
ank               getpol            get_strings       lock              renprinc
change_password   get_policies      getstrs           lr                setstr
cpw               get_policy        ktadd             modify_policy     set_string
delete_policy     getpols           ktrem             modify_principal  unlock
delete_principal  getprinc          ktremove          modpol            xst
```

### 3.3.1 Kerberos数据库操作
1. 登陆数据库
   1）本地登陆（无需认证）
   ```
   kadmin.local
   ```
   2）远程登录（需要进行主体认证）
   ```
   kadmin
   ```
   按提示输入密码完成认证即可登陆。
 

2. 创建Kerberos主体
   ```
   kadmin.local -q "addprinc test"
   ```
   或登录后输入
   ```
   kadmin.local: addprinc test
   ```

3. 修改主体密码
   ```
   kadmin.local: cpw test
   ```

4. 删除主体
   ```
   kadmin.local: delprinc test
   ```

5. 查看所有主体
   ```
   kadmin.local: list_principals
   ```
   可以看到除了我们创建的主体外，还有几个程序自动创建的主体。
   ```
   kadmin.local:  list_principals
   K/M@IOTMARS.COM
   admin/admin@IOTMARS.COM
   kadmin/admin@IOTMARS.COM
   kadmin/changepw@IOTMARS.COM
   kadmin/cos-bigdata-mysql@IOTMARS.COM
   kiprop/cos-bigdata-mysql@IOTMARS.COM
   krbtgt/IOTMARS.COM@IOTMARS.COM
   ```

6. 需要退出客户端时输入：exit

### 3.3.2 Kerberos认证操作
1. 密码认证
   1）使用kinit进行主体认证
   ```
   kinit test
   ```
   输入密码正确后，没有任何报错信息，则认证成功.

   2）查看认证凭证
   ```
   [root@cos-bigdata-hadoop-01 kerberos]# klist
   Ticket cache: FILE:/tmp/krb5cc_0
   Default principal: test@IOTMARS.COM
   
   Valid starting       Expires              Service principal
   2021-09-24T18:46:59  2021-09-25T18:46:59  krbtgt/IOTMARS.COM@IOTMARS.COM
   ```

2. 密钥文件认证
   1）首先需要生成主体test的keytab密钥文件，可以生成到指定目录/root/test.keytab
   ```
   kadmin.local -q "xst  -norandkey -k /root/test.keytab test@IOTMARS.COM"
   ```
   注：-norandkey的作用是声明不随机生成密码。若不加该参数，会为该用户生成随机密码并写入到密钥文件中。这样会导致之前的密码失效，只能使用密钥文件进行认证。

   2）使用keytab进行认证
   ```
   kinit -kt /root/test.keytab test
   ```
   -kt表示使用密钥文件进行认证。

3. 销毁凭证
   ```
   kdestroy
   ```

<br>
# 四、Hadoop Kerberos配置
**需要进行认证的环节：**
- 启动各个hadoop进程
- 各个服务之间通讯
- 通过hadoop fs命令操作数据
- NameNode Web认证并操作数据
- 提交yarn任务需要进行认证，且认证用户需要有/user等目录的权限
- 启动和连接 hive/hiveserver2 (hive on spark)，并提交执行任务

## 4.1 认证原理
启动hadoop集群的用户就是该集群的超级用户，而在core-site.xml中配置的hadoop.http.staticuser.user信息就是通过NameNode的UI或hadoop命令进行访问的静态用户，一旦配置为超级用户，那么任何用户都可以通过NameNode的UI或者hadoop命令对集群中的数据进行操作，这造成了数据的不安全。所以我们必须引入Kerberos进行用户认证。

![image.png](Kerberos认证管理.assets\3ba0822c59794068bee8d292a82e9ceb.png)

**流程如下：**
1. 首先在客户端输入kinit命令，携带principal，到KDC的AS服务进行认证；
2. AS服务访问Database获取用户的Principal然后进行认证。认证通过后，返回TGT给客户端；
3. 客户端获取TGT后，缓存到本地，然后携带TGT访问TGS服务；
4. TGS服务会查询Database获取目标节点的相关信息，完成目标节点的认证，并验证TGT是否有效，有效则可以换取访问目标节点的Server Ticket；
5. 获取到Server Ticket后，客户端就可以与目标节点进行交互了


**主要工作**
1. 创建系统用户
2. 创建Kerberos主体
3. 导出主体的keytab到主机
4. 配置Hadoop配置文件，包括启用Kerberos认证、指定keytab位置等。
5. 配置Https协议。
6. 切换为LinuxContainerExecutor，设置对应权限和配置文件。

<br>
## 4.2 创建Hadoop系统用户和组

为Hadoop开启Kerberos，需为不同服务准备不同的用户，启动服务时需要使用相应的用户。须在所有节点创建以下用户和用户组。

| **User:Group**    | **Daemons**                                         |
| ----------------- | --------------------------------------------------- |
| **hdfs:hadoop**   | NameNode, Secondary NameNode, JournalNode, DataNode |
| **yarn:hadoop**   | ResourceManager, NodeManager                        |
| **mapred:hadoop** | MapReduce JobHistory Server                         |

创建hadoop组
```
[root@bigdata1 ~]# groupadd hadoop
[root@bigdata2 ~]# groupadd hadoop
[root@bigdata3 ~]# groupadd hadoop
```
创建各用户并设置密码
```
[root@bigdata1 ~]# useradd hdfs -g hadoop
[root@bigdata1 ~]# echo hdfs | passwd --stdin  hdfs

[root@bigdata1 ~]# useradd yarn -g hadoop
[root@bigdata1 ~]# echo yarn | passwd --stdin yarn

[root@bigdata1 ~]# useradd mapred -g hadoop
[root@bigdata1 ~]# echo mapred | passwd --stdin mapred


[root@bigdata2 ~]# useradd hdfs -g hadoop
[root@bigdata2 ~]# echo hdfs | passwd --stdin  hdfs

[root@bigdata2 ~]# useradd yarn -g hadoop
[root@bigdata2 ~]# echo yarn | passwd --stdin yarn

[root@bigdata2 ~]# useradd mapred -g hadoop
[root@bigdata2 ~]# echo mapred | passwd --stdin mapred


[root@bigdata3 ~]# useradd hdfs -g hadoop
[root@bigdata3 ~]# echo hdfs | passwd --stdin  hdfs

[root@bigdata3 ~]# useradd yarn -g hadoop
[root@bigdata3 ~]# echo yarn | passwd --stdin yarn

[root@bigdata3 ~]# useradd mapred -g hadoop
[root@bigdata3 ~]# echo mapred | passwd --stdin mapred
```

<br>
### 4.3 为Hadoop各服务创建Kerberos主体(Principal)
主体格式如下：ServiceName/HostName@REALM，例如 dn/bigdata1@IOTMARS.COM

**1. 各服务所需主体如下**
环境：3台节点，主机名分别为bigdata1，bigdata2，bigdata3

| **服务**           | **所在主机** | **主体（Principal）** |
| ------------------ | ------------ | --------------------- |
| NameNode           | bigdata1     | nn/bigdata1           |
| DataNode           | bigdata1     | dn/bigdata1           |
| DataNode           | bigdata2     | dn/bigdata2           |
| DataNode           | bigdata3     | dn/bigdata3           |
| Secondary NameNode | bigdata3     | sn/bigdata3           |
| ResourceManager    | bigdata2     | rm/bigdata2           |
| NodeManager        | bigdata1     | nm/bigdata1           |
| NodeManager        | bigdata2     | nm/bigdata2           |
| NodeManager        | bigdata3     | nm/bigdata3           |
| JobHistory Server  | bigdata3     | jhs/bigdata3          |
| Web UI             | bigdata1     | HTTP/bigdata1         |
| Web UI             | bigdata2     | HTTP/bigdata2         |
| Web UI             | bigdata3     | HTTP/bigdata3         |

**2. 创建主体说明**
1） 路径准备：为服务创建的主体，需要通过密钥文件keytab文件进行认证，故需为各服务准备一个安全的路径用来存储keytab文件。
```
[root@bigdata1 ~]# mkdir /etc/security/keytab/
[root@bigdata1 ~]# chown -R root:hadoop /etc/security/keytab/
[root@bigdata1 ~]# chmod 770 /etc/security/keytab/
```
2）管理员主体认证
为执行创建主体的语句，需登录Kerberos 数据库客户端，登录之前需先使用Kerberos的管理员用户进行认证，执行以下命令并根据提示输入密码。
```
[root@bigdata1 ~]# kinit admin/admin
```
3）登录数据库客户端，输入密码
```
[root@bigdata1 ~]# kadmin
```
4）执行创建主体的语句 
```
kadmin:  addprinc -randkey test/test
kadmin:  xst -k /etc/security/keytab/test.keytab test/test
```
- addprinc：增加主体
- -randkey：密码随机，因hadoop各服务均通过keytab文件认证，故密码可随机生成
- test/test：新增的主体
- xst：将主体的密钥写入keytab文件
- -k /etc/security/keytab/test.keytab：指明keytab文件路径和文件名
- test/test：主体

为方便创建主体，可使用如下命令
```
[root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey test/test"
[root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/test.keytab test/test"
```
- -p：主体
- -w：密码
- -q：执行语句

**3. 创建主体**
1）在所有节点创建keytab文件目录
```
[root@bigdata1 ~]# mkdir /etc/security/keytab/
[root@bigdata1 ~]# chown -R root:hadoop /etc/security/keytab/
[root@bigdata1 ~]# chmod 770 /etc/security/keytab/

[root@bigdata2 ~]# mkdir /etc/security/keytab/
[root@bigdata2 ~]# chown -R root:hadoop /etc/security/keytab/
[root@bigdata2 ~]# chmod 770 /etc/security/keytab/

[root@bigdata3 ~]# mkdir /etc/security/keytab/
[root@bigdata3 ~]# chown -R root:hadoop /etc/security/keytab/
[root@bigdata3 ~]# chmod 770 /etc/security/keytab/
```

2）以下命令在bigdata1节点执行
NameNode（bigdata1）
```
[root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey nn/bigdata1"
[root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/nn.service.keytab nn/bigdata1"
```
DataNode（bigdata1）
```
[root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey dn/bigdata1"
[root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/dn.service.keytab dn/bigdata1"
```
NodeManager（bigdata1）
```
[root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey nm/bigdata1"
[root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/nm.service.keytab nm/bigdata1"
```
Web UI（bigdata1）
```
[root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey HTTP/bigdata1"
[root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/spnego.service.keytab HTTP/bigdata1"
```

2）以下命令在bigdata2执行
ResourceManager（bigdata2）
```
[root@bigdata2 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey rm/bigdata2"
[root@bigdata2 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/rm.service.keytab rm/bigdata2"
```
DataNode（bigdata2）
```
[root@bigdata2 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey dn/bigdata2"
[root@bigdata2 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/dn.service.keytab dn/bigdata2"
```
NodeManager（bigdata2）
```
[root@bigdata2 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey nm/bigdata2"
[root@bigdata2 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/nm.service.keytab nm/bigdata2"
```
Web UI（bigdata2）
```
[root@bigdata2 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey HTTP/bigdata2"
[root@bigdata2 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/spnego.service.keytab HTTP/bigdata2"
```

3）以下命令在bigdata3执行
DataNode（bigdata3）
```
[root@bigdata3 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey dn/bigdata3"
[root@bigdata3 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/dn.service.keytab dn/bigdata3"
```
Secondary NameNode（bigdata3）
```
[root@bigdata3 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey sn/bigdata3"
[root@bigdata3 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/sn.service.keytab sn/bigdata3"
```
NodeManager（bigdata3）
```
[root@bigdata3 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey nm/bigdata3"
[root@bigdata3 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/nm.service.keytab nm/bigdata3"
```
JobHistory Server（bigdata3）
```
[root@bigdata3 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey jhs/bigdata3"
[root@bigdata3 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/jhs.service.keytab jhs/bigdata3"
```
Web UI（bigdata3）
```
[root@bigdata3 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey HTTP/bigdata3"
[root@bigdata3 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/spnego.service.keytab HTTP/bigdata3"
```

**4.修改所有节点keytab文件的所有者和访问权限**
```
[root@bigdata1 ~]# chown -R root:hadoop /etc/security/keytab/
[root@bigdata1 ~]# chmod 660 /etc/security/keytab/*

[root@bigdata2 ~]# chown -R root:hadoop /etc/security/keytab/
[root@bigdata2 ~]# chmod 660 /etc/security/keytab/*

[root@bigdata3 ~]# chown -R root:hadoop /etc/security/keytab/
[root@bigdata3 ~]# chmod 660 /etc/security/keytab/*
```
 
<br>
### 4.4 修改Hadoop配置文件
需要修改的内容如下，修改完毕需要分发所改文件。

**1. core-site.xml**
```
    <!-- Kerberos主体到系统用户的映射机制 -->
    <property>
      <name>hadoop.security.auth_to_local.mechanism</name>
      <value>MIT</value>
    </property>

    <!-- Kerberos主体到系统用户的具体映射规则 -->
    <property>
      <name>hadoop.security.auth_to_local</name>
      <value>
        RULE:[2:$1/$2@$0]([ndsj]n\/.*@IOTMARS\.COM)s/.*/hdfs/
        RULE:[2:$1/$2@$0]([rn]m\/.*@IOTMARS\.COM)s/.*/yarn/
        RULE:[2:$1/$2@$0](jhs\/.*@IOTMARS\.COM)s/.*/mapred/
        DEFAULT
      </value>
    </property>

    <!-- 启用Hadoop集群Kerberos安全认证 -->
    <property>
      <name>hadoop.security.authentication</name>
      <value>kerberos</value>
    </property>

    <!-- 启用Hadoop集群授权管理 -->
    <property>
      <name>hadoop.security.authorization</name>
      <value>true</value>
    </property>

    <!-- Hadoop集群间RPC通讯设为仅认证模式 -->
    <property>
      <name>hadoop.rpc.protection</name>
      <value>authentication</value>
    </property>
```
>此处`[2:$1/$2@$0]`中的 '2' 表示主体名包含了`$`1和`$2`两部分，`$1`和`$2`组成了主体名，`$0`是域名。`([ndj]n\/.*@IOTMARS\.COM)s/.*/hdfs/` 是通过正则表达式进行匹配，主体匹配上规则，`s`表示替换，`.*`表示所有内容，即将主体全部替换为hdfs，对应主机上的hdfs用户；若匹配不上，进行下一个规则的匹配。如果都没有匹配上，则使用`DEFAULT`规则，即只取`$1`的部分替换全部内容，对应主机上的`$1`用户。

**2. hdfs-site.xml**
读取文件时，需要先访问NameNode获取block信息，然后去block所在节点获取数据；此过程需要进行Kerberos认证，dfs.block.access.token.enable参数设置为true，则在NameNode返回block信息还会返回block所在节点的token，这样客户端在获取block时不再需要进行DataNode节点的认证。
```
    <!-- 访问DataNode数据块时需通过Kerberos认证 -->
    <property>
      <name>dfs.block.access.token.enable</name>
      <value>true</value>
    </property>

    <!-- NameNode服务的Kerberos主体,_HOST会自动解析为服务所在的主机名 -->
    <property>
      <name>dfs.namenode.kerberos.principal</name>
      <value>nn/_HOST@IOTMARS.COM</value>
    </property>

    <!-- NameNode服务的Kerberos密钥文件路径 -->
    <property>
      <name>dfs.namenode.keytab.file</name>
      <value>/etc/security/keytab/nn.service.keytab</value>
    </property>

    <!-- Secondary NameNode服务的Kerberos主体 -->
    <property>
      <name>dfs.secondary.namenode.kerberos.principal</name>
      <value>sn/_HOST@IOTMARS.COM</value>
    </property>

    <!-- Secondary NameNode服务的Kerberos密钥文件路径 -->
    <property>
      <name>dfs.secondary.namenode.keytab.file</name>
      <value>/etc/security/keytab/sn.service.keytab</value>
    </property>


    <!-- NameNode Web服务的Kerberos主体 -->
    <property>
      <name>dfs.namenode.kerberos.internal.spnego.principal</name>
      <value>HTTP/_HOST@IOTMARS.COM</value>
    </property>

    <!-- WebHDFS REST服务的Kerberos主体 -->
    <property>
      <name>dfs.web.authentication.kerberos.principal</name>
      <value>HTTP/_HOST@IOTMARS.COM</value>
    </property>

    <!-- Secondary NameNode Web UI服务的Kerberos主体 -->
    <property>
      <name>dfs.secondary.namenode.kerberos.internal.spnego.principal</name>
      <value>HTTP/_HOST@IOTMARS.COM</value>
    </property>

    <!-- Hadoop Web UI的Kerberos密钥文件路径 -->
    <property>
      <name>dfs.web.authentication.kerberos.keytab</name>
      <value>/etc/security/keytab/spnego.service.keytab</value>
    </property>

    <!-- DataNode服务的Kerberos主体 -->
    <property>
      <name>dfs.datanode.kerberos.principal</name>
      <value>dn/_HOST@IOTMARS.COM</value>
    </property>

    <!-- DataNode服务的Kerberos密钥文件路径 -->
    <property>
      <name>dfs.datanode.keytab.file</name>
      <value>/etc/security/keytab/dn.service.keytab</value>
    </property>

    <!-- 配置NameNode Web UI 使用HTTPS协议 -->
    <property>
      <name>dfs.http.policy</name>
      <value>HTTPS_ONLY</value>
    </property>

    <!-- 配置DataNode数据传输保护策略为仅认证模式 -->
    <property>
      <name>dfs.data.transfer.protection</name>
      <value>authentication</value>
    </property>
```

**3. mapred-site.xml**
```
    <!-- 历史服务器的Kerberos主体 -->
    <property>
      <name>mapreduce.jobhistory.keytab</name>
      <value>/etc/security/keytab/jhs.service.keytab</value>
    </property>

    <!-- 历史服务器的Kerberos密钥文件 -->
    <property>
      <name>mapreduce.jobhistory.principal</name>
      <value>jhs/_HOST@IOTMARS.COM</value>
    </property>
```
>**这个_HOST官网解释如下：**
Hadoop simplifies the deployment of configuration files by allowing the hostname component of the service principal to be specified as the _HOST wildcard. Each service instance will substitute _HOST with its own fully qualified hostname at runtime. This allows administrators to deploy the same set of configuration files on all nodes. However, the keytab files will be different.
>但是实际使用发现貌似不是主机名称，很奇怪！

**实际测试发现：**
1. 启动Datanode时，会调用KerberosUtil.java中的getLocalHostName()方法
   ```
     /* Return fqdn of the current host */
     static String getLocalHostName() throws UnknownHostException {
       return InetAddress.getLocalHost().getCanonicalHostName();
     }
   ```
   可以发现使用的是java.net包中的getCanonicalHostName()方法获取全限定主机名。需要在/etc/hosts中的第一行添加  
   ```
   [本机ip] [hostname]
   ```
   各个节点启动时会读取这个hostname并赋值给_HOST。

2. 启动SecondaryNameNode时，会读取配置中的值
   ```
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>cos-bigdata-test-hadoop-03:9868</value>
    </property>
   ```
   启动SecondaryNameNode就会将_HOST设置为cos-bigdata-test-hadoop-03。

3. 启动NameNode时，会读取配置中的值
   ```
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://cos-bigdata-test-hadoop-01:9820</value>
    </property>
   ```
   启动NameNode就会将_HOST设置为cos-bigdata-test-hadoop-01。

4. 启动ResouceManager时，会读取配置中的值
   ```
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>cos-bigdata-test-hadoop-02</value>
    </property>
   ```
   启动ResouceManager就会将_HOST设置为cos-bigdata-test-hadoop-02。

**4. yarn-site.xml**
```
    <!-- Resource Manager 服务的Kerberos主体 -->
    <property>
      <name>yarn.resourcemanager.principal</name>
      <value>rm/_HOST@IOTMARS.COM</value>
    </property>

    <!-- Resource Manager 服务的Kerberos密钥文件 -->
    <property>
      <name>yarn.resourcemanager.keytab</name>
      <value>/etc/security/keytab/rm.service.keytab</value>
    </property>

    <!-- Node Manager 服务的Kerberos主体 -->
    <property>
      <name>yarn.nodemanager.principal</name>
      <value>nm/_HOST@IOTMARS.COM</value>
    </property>

    <!-- Node Manager 服务的Kerberos密钥文件 -->
    <property>
      <name>yarn.nodemanager.keytab</name>
      <value>/etc/security/keytab/nm.service.keytab</value>
    </property>
```
>需要注意的是，即使通过了kerberos认证的用户，如果该用户不是所有yarn服务器的用户且与启动yarn服务的用户不同组），那么会报错 **User xxx not found**

修改完成后分发配置文件到其他节点。

<br>
## 4.5 配置HDFS使用HTTPS安全传输协议
Keytool是java数据证书的管理工具，使用户能够管理自己的公/私钥对及相关证书。
-keystore    指定密钥库的名称及位置(产生的各类信息将存在.keystore文件中)
-genkey(或者-genkeypair)      生成密钥对
-alias  为生成的密钥对指定别名，如果没有默认是mykey
-keyalg  指定密钥的算法 RSA/DSA 默认是DSA

1）生成 keystore的密码及相应信息的密钥库
   ```
   keytool -keystore /etc/security/keytab/keystore -alias jetty -genkey -keyalg RSA
   ```
   注意：CN设置为访问的域名，即hosts中配置的cos-bigdata-test-hadoop-01

2）修改keystore文件的所有者和访问权限
   ```
   chown -R root:hadoop /etc/security/keytab/keystore
   chmod 660 /etc/security/keytab/keystore
   ```
   注意：
   （1）密钥库的密码至少6个字符，可以是纯数字或者字母或者数字和字母的组合等等
   （2）确保hdfs用户（HDFS的启动用户）具有对所生成keystore文件的读权限

3）将该证书分发到集群中的每台节点的相同路径
```
xsync /etc/security/keytab/keystore
```

4）修改hadoop配置文件ssl-server.xml.example，
该文件位于$HADOOP_HOME/etc/hadoop目录
修改文件名为ssl-server.xml
修改以下内容
```
<!-- SSL密钥库路径 -->
<property>
  <name>ssl.server.keystore.location</name>
  <value>/etc/security/keytab/keystore</value>
</property>

<!-- SSL密钥库密码 -->
<property>
  <name>ssl.server.keystore.password</name>
  <value>123456</value>
</property>

<!-- SSL可信任密钥库路径 -->
<property>
  <name>ssl.server.truststore.location</name>
  <value>/etc/security/keytab/keystore</value>
</property>

<!-- SSL密钥库中密钥的密码 -->
<property>
  <name>ssl.server.keystore.keypassword</name>
  <value>Password@123</value>
</property>

<!-- SSL可信任密钥库密码 -->
<property>
  <name>ssl.server.truststore.password</name>
  <value>Password@123</value>
</property>
```
分发配置文件到所有的节点。

5）将证书添加到jdk的信任库中
默认每分钟Secondarynamenode会发起fetchImage的https请求，如果不配置自签名证书可信任，就会导致请求失败，Secondarynamenode功能失效。报错如下
```
2021-10-15 10:52:08,774 INFO org.apache.hadoop.hdfs.server.namenode.TransferFsImage: Opening connection to https://cos-bigdata-test-hadoop-01:9871/imagetransfer?getimage=1&txid=4419&storageInfo=-64:2014770126:1634089984720:CID-b3e0e3d0-2f3d-49f2-a41c-5725d56b89b5&bootstrapstandby=false
2021-10-15 10:52:08,802 ERROR org.apache.hadoop.hdfs.server.namenode.SecondaryNameNode: Exception in doCheckpoint
javax.net.ssl.SSLHandshakeException: Error while authenticating with endpoint: https://cos-bigdata-test-hadoop-01:9871/imagetransfer?getimage=1&txid=4419&storageInfo=-64:2014770126:1634089984720:CID-b3e0e3d0-2f3d-49f2-a41c-5725d56b89b5&bootstrapstandby=false
   ......
Caused by: javax.net.ssl.SSLHandshakeException: sun.security.validator.ValidatorException: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
```
首先导出证书
```
keytool -export -rfc -alias jetty -file cos-bigdata-test-hadoop-01.cet -keystore /etc/security/keytab/keystore -storepass bigdata123 -keypass bigdata123
```
将证书添加到secondarynamenode所在节点的jdk的信任库中，jdk的信任库文件是cacerts。
```
keytool -import -v -trustcacerts -alias cos-bigdata-test-hadoop-01 -file /etc/security/keytab/cos-bigdata-test-hadoop-01.crt -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit
```

<br>
## 4.6 配置Yarn使用LinuxContainerExecutor
- DefaultContainerExecutor：默认的启动Container进程的程序，该进程所属的用户是启动Resourcemanager的用户，而不是提交任务的用户。
- LinuxContainerExecutor：与DefaultContanerExecutor不同点是，启动Container进程的用户是提交任务的用户，而不是启动ResourceManager的用户。需要保证启动任务的用户是系统用户，否则会找不到用户。

1）修改所有节点的container-executor所有者和权限，要求其所有者为root，所有组为hadoop（启动NodeManger的yarn用户的所属组），权限为6050。其默认路径为$HADOOP_HOME/bin
```
[root@bigdata1 ~]# chown root:hadoop /opt/module/hadoop-3.1.3/bin/container-executor
[root@bigdata1 ~]# chmod 6050 /opt/module/hadoop-3.1.3/bin/container-executor

[root@bigdata2 ~]# chown root:hadoop /opt/module/hadoop-3.1.3/bin/container-executor
[root@bigdata2 ~]# chmod 6050 /opt/module/hadoop-3.1.3/bin/container-executor

[root@bigdata3 ~]# chown root:hadoop /opt/module/hadoop-3.1.3/bin/container-executor
[root@bigdata3 ~]# chmod 6050 /opt/module/hadoop-3.1.3/bin/container-executor
```

2）修改所有节点的container-executor.cfg文件的所有者和权限，要求该文件及其所有的上级目录的所有者均为root，所有组为hadoop（启动NodeManger的yarn用户的所属组），权限为400。其默认路径为$HADOOP_HOME/etc/hadoop
```
[root@bigdata1 ~]# chown root:hadoop /opt/module/hadoop-3.1.3/etc/hadoop/container-executor.cfg
[root@bigdata1 ~]# chown root:hadoop /opt/module/hadoop-3.1.3/etc/hadoop
[root@bigdata1 ~]# chown root:hadoop /opt/module/hadoop-3.1.3/etc
[root@bigdata1 ~]# chown root:hadoop /opt/module/hadoop-3.1.3
[root@bigdata1 ~]# chown root:hadoop /opt/module
[root@bigdata1 ~]# chmod 400 /opt/module/hadoop-3.1.3/etc/hadoop/container-executor.cfg

[root@bigdata2 ~]# chown root:hadoop /opt/module/hadoop-3.1.3/etc/hadoop/container-executor.cfg
[root@bigdata2 ~]# chown root:hadoop /opt/module/hadoop-3.1.3/etc/hadoop
[root@bigdata2 ~]# chown root:hadoop /opt/module/hadoop-3.1.3/etc
[root@bigdata2 ~]# chown root:hadoop /opt/module/hadoop-3.1.3
[root@bigdata2 ~]# chown root:hadoop /opt/module
[root@bigdata2 ~]# chmod 400 /opt/module/hadoop-3.1.3/etc/hadoop/container-executor.cfg

[root@bigdata3 ~]# chown root:hadoop /opt/module/hadoop-3.1.3/etc/hadoop/container-executor.cfg
[root@bigdata3 ~]# chown root:hadoop /opt/module/hadoop-3.1.3/etc/hadoop
[root@bigdata3 ~]# chown root:hadoop /opt/module/hadoop-3.1.3/etc
[root@bigdata3 ~]# chown root:hadoop /opt/module/hadoop-3.1.3
[root@bigdata3 ~]# chown root:hadoop /opt/module
[root@bigdata3 ~]# chmod 400 /opt/module/hadoop-3.1.3/etc/hadoop/container-executor.cfg
```

3）修改$HADOOP_HOME/etc/hadoop/container-executor.cfg
内容如下
```
# nodemanager所在的组
yarn.nodemanager.linux-container-executor.group=hadoop
# 设置禁止启动的yarn的用户，可以将启动集群的几个超级用户禁用其启动任务
banned.users=hdfs,yarn,mapred
# 我们创建的用户的用户id是1000+，此处表示启动任务的最小用户id，阻止系统超级用户启动任务
min.user.id=1000
# 设置允许启动任务的系统用户
allowed.system.users=
feature.tc.enabled=false
```

4）修改$HADOOP_HOME/etc/hadoop/yarn-site.xml文件
增加以下内容
```
<!-- 配置Node Manager使用LinuxContainerExecutor管理Container -->
<property>
  <name>yarn.nodemanager.container-executor.class</name>
  <value>org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor</value>
</property>

<!-- 配置Node Manager的启动用户的所属组 -->
<property>
  <name>yarn.nodemanager.linux-container-executor.group</name>
  <value>hadoop</value>
</property>
<!-- LinuxContainerExecutor脚本路径 -->
<property>
  <name>yarn.nodemanager.linux-container-executor.path</name>
  <value>/opt/module/hadoop-3.1.3/bin/container-executor</value>
</property>
```

5）分发container-executor.cfg和yarn-site.xml文件到其他节点

<br>
# 五、安全模式下启动Hadoop
## 5.1 修改特定本地路径权限
| **local** | $HADOOP_LOG_DIR             | hdfs:hadoop | drwxrwxr-x |
| --------- | --------------------------- | ----------- | ---------- |
| **local** | dfs.namenode.name.dir       | hdfs:hadoop | drwx------ |
| **local** | dfs.datanode.data.dir       | hdfs:hadoop | drwx------ |
| **local** | dfs.namenode.checkpoint.dir | hdfs:hadoop | drwx------ |
| **local** | yarn.nodemanager.local-dirs | yarn:hadoop | drwxrwxr-x |
| **local** | yarn.nodemanager.log-dirs   | yarn:hadoop | drwxrwxr-x |

1）$HADOOP_LOG_DIR（所有节点）

该变量位于hadoop-env.sh文件，默认值为 ${HADOOP_HOME}/logs
```
[root@bigdata1 ~]# chown hdfs:hadoop /opt/module/hadoop-3.1.3/logs/

[root@bigdata1 ~]# chmod 775 /opt/module/hadoop-3.1.3/logs/

[root@bigdata2 ~]# chown hdfs:hadoop /opt/module/hadoop-3.1.3/logs/

[root@bigdata2 ~]# chmod 775 /opt/module/hadoop-3.1.3/logs/

[root@bigdata3 ~]# chown hdfs:hadoop /opt/module/hadoop-3.1.3/logs/

[root@bigdata3 ~]# chmod 775 /opt/module/hadoop-3.1.3/logs/
```

2）dfs.namenode.name.dir（NameNode节点）

该参数位于hdfs-site.xml文件，默认值为file://${hadoop.tmp.dir}/dfs/name
```
[root@bigdata1 ~]# chown -R hdfs:hadoop /opt/module/hadoop-3.1.3/data/dfs/name/

[root@bigdata1 ~]# chmod 700 /opt/module/hadoop-3.1.3/data/dfs/name/
```

3）dfs.datanode.data.dir（DataNode节点）

该参数为于hdfs-site.xml文件，默认值为file://${hadoop.tmp.dir}/dfs/data
```
[root@bigdata1 ~]# chown -R hdfs:hadoop /opt/module/hadoop-3.1.3/data/dfs/data/

[root@bigdata1 ~]# chmod 700 /opt/module/hadoop-3.1.3/data/dfs/data/
```

4）dfs.namenode.checkpoint.dir（SecondaryNameNode节点）

该参数位于hdfs-site.xml文件，默认值为file://${hadoop.tmp.dir}/dfs/namesecondary
```
[root@bigdata3 ~]# chown -R hdfs:hadoop /opt/module/hadoop-3.1.3/data/dfs/namesecondary/

[root@bigdata3 ~]# chmod 700 /opt/module/hadoop-3.1.3/data/dfs/namesecondary/
```

5）yarn.nodemanager.local-dirs（NodeManager节点）

该参数位于yarn-site.xml文件，默认值为file://${hadoop.tmp.dir}/nm-local-dir
```
[root@bigdata1 ~]# chown -R yarn:hadoop /opt/module/hadoop-3.1.3/data/nm-local-dir/

[root@bigdata1 ~]# chmod -R 775 /opt/module/hadoop-3.1.3/data/nm-local-dir/

[root@bigdata2 ~]# chown -R yarn:hadoop /opt/module/hadoop-3.1.3/data/nm-local-dir/

[root@bigdata2 ~]# chmod -R 775 /opt/module/hadoop-3.1.3/data/nm-local-dir/

[root@bigdata3 ~]# chown -R yarn:hadoop /opt/module/hadoop-3.1.3/data/nm-local-dir/

[root@bigdata3 ~]# chmod -R 775 /opt/module/hadoop-3.1.3/data/nm-local-dir/
```

6）yarn.nodemanager.log-dirs（NodeManager节点）

该参数位于yarn-site.xml文件，默认值为$HADOOP_LOG_DIR/userlogs
```
[root@bigdata1 ~]# chown yarn:hadoop /opt/module/hadoop-3.1.3/logs/userlogs/

[root@bigdata1 ~]# chmod 775 /opt/module/hadoop-3.1.3/logs/userlogs/

[root@bigdata2 ~]# chown yarn:hadoop /opt/module/hadoop-3.1.3/logs/userlogs/

[root@bigdata2 ~]# chmod 775 /opt/module/hadoop-3.1.3/logs/userlogs/

[root@bigdata3 ~]# chown yarn:hadoop /opt/module/hadoop-3.1.3/logs/userlogs/

[root@bigdata3 ~]# chmod 775 /opt/module/hadoop-3.1.3/logs/userlogs/
```

7）HADOOP_PID_DIR
如果修改过该参数，则需要保证该存储pid文件的路径允许hdfs:hadoop用户访问。我在profile文件中将HADOOP_PID_DIR设置为${HADOOP_HOME}/pids/hdfs，则需要修改该路径的用户和权限
```
[root@bigdata1 ~]# chown -R hdfs:hadoop /opt/module/hadoop-3.1.3/pids/hdfs
[root@bigdata1 ~]# chmod -R 775 /opt/module/hadoop-3.1.3/pids/hdfs

[root@bigdata2 ~]# chown -R hdfs:hadoop /opt/module/hadoop-3.1.3/pids/hdfs
[root@bigdata2 ~]# chmod -R 775 /opt/module/hadoop-3.1.3/pids/hdfs

[root@bigdata3 ~]# chown -R hdfs:hadoop /opt/module/hadoop-3.1.3/pids/hdfs
[root@bigdata3 ~]# chmod -R 775 /opt/module/hadoop-3.1.3/pids/hdfs
```

8）HADOOP_MAPRED_PID_DIR
如果修改过该参数，则需要保证该存储pid文件的路径允许mapred:hadoop用户访问。我在profile文件中将HADOOP_MAPRED_PID_DIR设置为${HADOOP_HOME}/pids/mapred，则需要修改该路径的用户和权限
```
[root@bigdata1 ~]# chown -R mapred:hadoop /opt/module/hadoop-3.1.3/pids/mapred
[root@bigdata1 ~]# chmod -R 775 /opt/module/hadoop-3.1.3/pids/mapred

[root@bigdata2 ~]# chown -R mapred:hadoop /opt/module/hadoop-3.1.3/pids/mapred
[root@bigdata2 ~]# chmod -R 775 /opt/module/hadoop-3.1.3/pids/mapred

[root@bigdata3 ~]# chown -R mapred:hadoop /opt/module/hadoop-3.1.3/pids/mapred
[root@bigdata3 ~]# chmod -R 775 /opt/module/hadoop-3.1.3/pids/mapred
```

<br>
## 5.2 启动HDFS

需要注意的是，启动不同服务时需要使用对应的用户

**1. 单点启动**

（1）启动NameNode
```
[root@bigdata1 ~]# sudo -i -u hdfs hdfs --daemon start namenode
```
（2）启动DataNode
```
[root@bigdata1 ~]# sudo -i -u hdfs hdfs --daemon start datanode

[root@bigdata2 ~]# sudo -i -u hdfs hdfs --daemon start datanode

[root@bigdata3 ~]# sudo -i -u hdfs hdfs --daemon start datanode
```
（3）启动SecondaryNameNode
```
[root@bigdata3 ~]# sudo -i -u hdfs hdfs --daemon start secondarynamenode
```
**说明：**
- -i：重新加载环境变量

- -u：以特定用户的身份执行后续命令


**2. 群起**

1）在主节点（bigdata1）配置hdfs用户到所有节点的免密登录。
```
ssh-keygen -t rsa
ssh-copy-id bigdata2
ssh-copu-id bigdata3
```
2）修改主节点（bigdata1）节点的$HADOOP_HOME/sbin/start-dfs.sh脚本，在顶部增加以下环境变量。在顶部增加如下内容
```
HDFS_DATANODE_USER=hdfs

HDFS_NAMENODE_USER=hdfs

HDFS_SECONDARYNAMENODE_USER=hdfs
```
注：\$HADOOP_HOME/sbin/stop-dfs.sh也需在顶部增加上述环境变量才可使用。

3）以root用户执行群起脚本，即可启动HDFS集群。
```
[root@bigdata1 ~]# start-dfs.sh
```
**3.查看HFDS web页面**

访问地址为 https://bigdata1:9871

查看节点是否都注册成功。

**注：**如果遇到Datanode无法注册的问题，可能是jdk的jce版本问题。[下载](https://www.oracle.com/technetwork/java/javase/downloads/jce8-download-2133166.html)，解压得到的local_policy.jar和US_export_policy.jar替换到$JAVA_HOME/jre/lib/security目录下。然后同步到其他节点，因为NodeManager同样会遇到这个问题。


<br>
## 5.3 修改HDFS特定路径访问权限

| **hdfs** | /                                          | hdfs:hadoop   | drwxr-xr-x  |
| -------- | ------------------------------------------ | ------------- | ----------- |
| **hdfs** | /tmp                                       | hdfs:hadoop   | drwxrwxrwxt |
| **hdfs** | /user                                      | hdfs:hadoop   | drwxrwxr-x  |
| **hdfs** | yarn.nodemanager.remote-app-log-dir        | yarn:hadoop   | drwxrwxrwxt |
| **hdfs** | mapreduce.jobhistory.intermediate-done-dir | mapred:hadoop | drwxrwxrwxt |
| **hdfs** | mapreduce.jobhistory.done-dir              | mapred:hadoop | drwxrwx---  |

说明：hdfs是启动集群的用户，所以是超级用户，将hdfs下的特定路径的所属用户组进行更改。若上述路径不存在，需手动创建

1）创建hdfs/hadoop主体，执行以下命令并按照提示输入密码
```
[root@bigdata1 ~]# kadmin.local -q "addprinc hdfs/hadoop"
```
2）认证hdfs/hadoop主体，执行以下命令并按照提示输入密码
```
[root@bigdasta1 ~]# kinit hdfs/hadoop
```
>需要获取hdfs的超级用户时，需要认证为hdfs/hadoop；需要获取kerberos管理员权限时，需要认证为admin/admin。

3）按照上述要求修改指定路径的所有者和权限
（1）修改/、/tmp、/user路径
```
[root@bigdasta1 ~]# hadoop fs -chown hdfs:hadoop / /tmp /user
[root@bigdasta1 ~]# hadoop fs -chmod 755 /
[root@bigdasta1 ~]# hadoop fs -chmod 1777 /tmp
[root@bigdasta1 ~]# hadoop fs -chmod 775 /user
```
（2）参数yarn.nodemanager.remote-app-log-dir位于yarn-site.xml文件，默认值/tmp/logs
```
[root@bigdasta1 ~]# hadoop fs -chown yarn:hadoop /tmp/logs
[root@bigdasta1 ~]# hadoop fs -chmod 1777 /tmp/logs
```
（3）参数mapreduce.jobhistory.intermediate-done-dir位于mapred-site.xml文件，默认值为/tmp/hadoop-yarn/staging/history/done_intermediate，需保证该路径的所有上级目录（除/tmp）的所有者均为mapred，所属组为hadoop，权限为770
```
[root@bigdasta1 ~]# hadoop fs -chown -R mapred:hadoop /tmp/hadoop-yarn/staging/history/done_intermediate
[root@bigdasta1 ~]# hadoop fs -chmod -R 1777 /tmp/hadoop-yarn/staging/history/done_intermediate

[root@bigdasta1 ~]# hadoop fs -chown mapred:hadoop /tmp/hadoop-yarn/staging/history/
[root@bigdasta1 ~]# hadoop fs -chown mapred:hadoop /tmp/hadoop-yarn/staging/
[root@bigdasta1 ~]# hadoop fs -chown mapred:hadoop /tmp/hadoop-yarn/

[root@bigdasta1 ~]# hadoop fs -chmod 770 /tmp/hadoop-yarn/staging/history/
[root@bigdasta1 ~]# hadoop fs -chmod 770 /tmp/hadoop-yarn/staging/
[root@bigdasta1 ~]# hadoop fs -chmod 770 /tmp/hadoop-yarn/
``` 

（4）参数mapreduce.jobhistory.done-dir位于mapred-site.xml文件，默认值为/tmp/hadoop-yarn/staging/history/done，需保证该路径的所有上级目录（除/tmp）的所有者均为mapred，所属组为hadoop，权限为770
```
[root@bigdasta1 ~]# hadoop fs -chown -R mapred:hadoop /tmp/hadoop-yarn/staging/history/done
[root@bigdasta1 ~]# hadoop fs -chmod -R 750 /tmp/hadoop-yarn/staging/history/done

[root@bigdasta1 ~]# hadoop fs -chown mapred:hadoop /tmp/hadoop-yarn/staging/history/
[root@bigdasta1 ~]# hadoop fs -chown mapred:hadoop /tmp/hadoop-yarn/staging/
[root@bigdasta1 ~]# hadoop fs -chown mapred:hadoop /tmp/hadoop-yarn/

[root@bigdasta1 ~]# hadoop fs -chmod 770 /tmp/hadoop-yarn/staging/history/
[root@bigdasta1 ~]# hadoop fs -chmod 770 /tmp/hadoop-yarn/staging/
[root@bigdasta1 ~]# hadoop fs -chmod 770 /tmp/hadoop-yarn/
```

<br>
## 5.4 启动Yarn

**1. 单点启动**
**启动ResourceManager**
```
[root@bigdata2 ~]# sudo -i -u yarn yarn --daemon start resourcemanager
```
**启动NodeManager**
```
[root@bigdata1 ~]# sudo -i -u yarn yarn --daemon start nodemanager

[root@bigdata2 ~]# sudo -i -u yarn yarn --daemon start nodemanager

[root@bigdata3 ~]# sudo -i -u yarn yarn --daemon start nodemanager
```

**2. 群起**
1）在Yarn主节点（bigdata2）配置**yarn**用户到所有节点的免密登录。
```

```
2）修改主节点（bigdata2）的$HADOOP_HOME/sbin/start-yarn.sh，在顶部增加以下环境变量。在顶部增加如下内容
```
YARN_RESOURCEMANAGER_USER=yarn

YARN_NODEMANAGER_USER=yarn
```
**注：stop-yarn.sh也需在顶部增加上述环境变量才可使用。**

3）以root用户执行$HADOOP_HOME/sbin/start-yarn.sh脚本即可启动yarn集群。
```
[root@bigdata2 ~]# start-yarn.sh
```

**3. 访问Yarnweb页面**

访问地址为 http://bigdata2:8088
查看节点是否都注册成功

## 5.5 启动HistoryServer
**1.启动历史服务器**
```
[root@bigdata3 ~]# sudo -i -u mapred mapred --daemon start historyserver
```

**2. 查看历史服务器web页面**

访问地址为 http://bigdata3:19888


<br>
# 六、安全集群使用说明
## 6.1 用户要求
**1. 具体要求**
以下使用说明均基于普通用户，安全集群对用户有以下要求：
1）集群中的每个节点都需要创建该用户
2）该用户需要属于hadoop用户组
3）需要创建该用户对应的Kerberos主体

**2. 实操**
此处以hxr用户为例，具体操作如下 
1）创建用户（存在可跳过），须在所有节点执行
```
[root@bigdata1 ~]# useradd hxr
[root@bigdata1 ~]# echo hxr| passwd --stdin hxr

[root@bigdata2 ~]# useradd hxr
[root@bigdata2 ~]# echo hxr| passwd --stdin hxr

[root@bigdata3 ~]# useradd hxr
[root@bigdata3 ~]# echo hxr| passwd --stdin hxr
```

2）加入hadoop组，须在所有节点执行
```
[root@bigdata1 ~]# usermod -a -G hadoop hxr
[root@bigdata2 ~]# usermod -a -G hadoop hxr
[root@bigdata3 ~]# usermod -a -G hadoop hxr
```

3）创建主体
```
[root@bigdata1 ~]# kadmin -p admin/admin -wadmin -q"addprinc -pw bigdata123 hxr"
```

<br>
## 6.2 访问HDFS集群文件
### 6.2.1 Shell命令
1. 认证
```
[hxr@bigdata1 ~]$ kinit hxr
```
2. 查看当前认证用户
```
[hxr@bigdata1 ~]$ kinit hxr
```
3. 执行命令
```
[hxr@bigdata1 ~]$ hadoop fs -ls /
```
4.注销认证
```
[hxr@bigdata1 ~]$ kdestroy
```
5.再次执行查看命令
```
[hxr@bigdata1 ~]$ hadoop fs -ls /
```

### 6.2.2 Win系统web页面
1. 安装Kerberos客户端
   官网： [http://web.mit.edu/kerberos/dist/#kfw-3.2](http://web.mit.edu/kerberos/dist/#kfw-3.2)
   下载地址：[http://web.mit.edu/kerberos/dist/kfw/4.1/kfw-4.1-amd64.msi](http://web.mit.edu/kerberos/dist/kfw/4.1/kfw-4.1-amd64.msi)

   1）下载之后按照提示安装
   2）编辑C:\ProgramData\MIT\Kerberos5\krb5.ini文件，内容如下
```
[libdefaults]
 dns_lookup_realm = false
 ticket_lifetime = 24h
 forwardable = true
 rdns = false
 default_realm = IOTMARS.COM

[realms]
 IOTMARS.COM = {
  kdc = 192.168.101.174
  admin_server = 192.168.101.174
 }

[domain_realm]
```
>注意：安装完成后，会自动将kerberos的bin目录路径加到环境变量中。如果安装了JDK的用户需要注意将kerberos的环境变量挪到JDK变量之前，因为JDK中也有 kinit, klist 等命令，系统会按环境变量顺序来使用命令。

2. 配置火狐浏览器
1）打开浏览器，在地址栏输入“about:config”，点击回车
2）搜索“network.negotiate-auth.trusted-uris”，修改值为要访问的主机名（bigdata1）
3）搜索“network.auth.use-sspi”，双击将值变为false

3. 认证
1）启动Kerberos客户端，点击Get Ticket
2）输入主体名和密码，点击OK
3）认证成功

4. 访问HDFS
https://bigdata1:9871 

5. 注销认证；删除缓存数据并重启浏览器，再次访问HDFS，访问失败。

### 6.2.3 IOS系统web页面
Mac OS系统预安装了Kerberos，需要修改配置。[官方教程](http://web.mit.edu/macdev/KfM/Common/Documentation/preferences-osx.html)

创建配置文件 /etc/krb5.conf ，配置文件内容同上
```
[libdefaults]
 dns_lookup_realm = false
 ticket_lifetime = 24h
 forwardable = true
 rdns = false
 default_realm = IOTMARS.COM

[realms]
 IOTMARS.COM = {
  kdc = 192.168.101.174
  admin_server = 192.168.101.174
 }

[domain_realm]
```
执行命令 `kinit xxx` 进行认证。
可以直接通过Safari访问。

也可以使用火狐浏览器，配置同上。


<br>
## 6.3 提交MapReduce任务
1. 认证
```
[hxr@bigdata1 ~]$ kinit hxr
```

2.提交任务
```
[hxr@bigdata1 ~]$ hadoop jar /opt/module/hadoop-3.1.3/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.1.3.jar pi 1 1
```

<br>
# 七、Hive用户认证配置
## 7.1 前置要求
### 7.1.1 Hadoop集群启动Kerberos认证
按照上述步骤为Hadoop集群开启Kerberos安全认证。

Hadoop开启Kerberos认证后，直接通过bin/hive命令启动hive本地客户端，也需要通过kinit 进行认证，否则无法读取到hdfs上的数据。

如果hive配置的执行引擎是spark，那么spark向yarn提交任务时需要Kerberos认证，此时即是是hive本地客户端，也需要在hive-site.xml中配置Kerberos认证。

以下是对Hive和HiveServer2服务进行Kerberos配置，为hive的本地提交任务和远程提交任务提供Kerberos认证。

### 7.1.2 创建Hive系统用户和Kerberos主体
1. 创建系统用户
```
[root@bigdata1 ~]# useradd hive -g hadoop
[root@bigdata1 ~]# echo hive | passwd --stdin hive

[root@bigdata2 ~]# useradd hive -g hadoop
[root@bigdata2 ~]# echo hive | passwd --stdin hive

[root@bigdata3 ~]# useradd hive -g hadoop
[root@bigdata3  ~]# echo hive | passwd --stdin hive
```

2. 创建Kerberos主体并生成keytab文件
创建hive用户的Kerberos主体
   ```
   [root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey hive/bigdata1"
   [root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey hive/bigdata2"
   [root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"addprinc -randkey hive/bigdata3"
   ```
   在Hive所部署的节点生成keytab文件
   ```
   [root@bigdata1 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/hive.service.keytab hive/bigdata1"
   [root@bigdata2 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/hive.service.keytab hive/bigdata2"
   [root@bigdata3 ~]# kadmin -padmin/admin -wadmin -q"xst -k /etc/security/keytab/hive.service.keytab hive/bigdata3"
   ```
3. 修改keytab文件所有者和访问权限
   ```
   [root@bigdata1 ~]# chown -R root:hadoop /etc/security/keytab/
   [root@bigdata1 ~]# chmod 660 /etc/security/keytab/hive.service.keytab

   [root@bigdata2 ~]# chown -R root:hadoop /etc/security/keytab/
   [root@bigdata2 ~]# chmod 660 /etc/security/keytab/hive.service.keytab

   [root@bigdata3 ~]# chown -R root:hadoop /etc/security/keytab/
   [root@bigdata3 ~]# chmod 660 /etc/security/keytab/hive.service.keytab
   ```

## 7.2 配置认证
1. 修改\$HIVE_HOME/conf/hive-site.xml文件，增加如下属性
```
<!-- HiveServer2启用Kerberos认证 -->
<property>
    <name>hive.server2.authentication</name>
    <value>kerberos</value>
</property>

<!-- HiveServer2服务的Kerberos主体 -->
<property>
    <name>hive.server2.authentication.kerberos.principal</name>
    <value>hive/_HOST@IOTMARS.COM</value>
</property>

<!-- HiveServer2服务的Kerberos密钥文件 -->
<property>
    <name>hive.server2.authentication.kerberos.keytab</name>
    <value>/etc/security/keytab/hive.service.keytab</value>
</property>

<!-- Metastore启动认证 -->
<property>
    <name>hive.metastore.sasl.enabled</name>
    <value>true</value>
</property>
<!-- Metastore Kerberos密钥文件 -->
<property>
    <name>hive.metastore.kerberos.keytab.file</name>
    <value>/etc/security/keytab/hive.service.keytab</value>
</property>
<!-- Metastore Kerberos主体 -->
<property>
    <name>hive.metastore.kerberos.principal</name>
    <value>hive/_HOST@IOTMARS.COM</value>
</property>
```
2. 修改\$HADOOP_HOME/etc/hadoop/core-site.xml文件，具体修改如下
1）删除以下参数
```
<property>
    <name>hadoop.http.staticuser.user</name>
    <value>hxr</value>
</property>

<property>
    <name>hadoop.proxyuser.hxr.hosts</name>
    <value>*</value>
</property>

<property>
    <name>hadoop.proxyuser.hxr.groups</name>
    <value>*</value>
</property>

<property>
    <name>hadoop.proxyuser.hxr.users</name>
    <value>*</value>
</property>
```
>hadoop.http.staticuser.user是指定访问Namenode网页时的用户。目前已经被Kerberos取代了，所以可以删除。

2）增加以下参数
```
<property>
    <name>hadoop.proxyuser.hive.hosts</name>
    <value>*</value>
</property>

<property>
    <name>hadoop.proxyuser.hive.groups</name>
    <value>*</value>
</property>

<property>
    <name>hadoop.proxyuser.hive.users</name>
    <value>*</value>
</property>
```
>proxyuser就是为了hiveserver2进行配置的。试想一下，[hive]用户启动了hive客户端，如果[zhangsan]用户提交了一个hive任务，那么是以哪个用户身份向yarn提交任务呢？是以[hive]的身份提交任务，所以会造成权限的混乱。此时我们配置proxyuser代理用户为启动hiveserver2进程的[hive]用户，再次执行hive任务，那么此时一些启动和善后任务由代理用户[hive]执行，但是向yarn提交任务的用户是[zhangsan]。

3.分发配置core-site.xml文件
```
[root@bigdata1 ~]# xsync $HADOOP_HOME/etc/hadoop/core-site.xml
```
4.重启Hadoop集群
```
[root@bigdata1 ~]# stop-dfs.sh
[root@bigdata1 ~]# start-dfs.sh

[root@bigdata2 ~]# stop-yarn.sh
[root@bigdata2 ~]# start-yarn.sh
```

## 7.3 启动hiveserver2
注：需使用hive用户启动

修改日志文件所属用户
```
[root@bigdata1 ~]# chown -R hive:hadoop /opt/module/hive-3.1.2/logs
```

如果是hive-on-spark，需要修改指定的spark日志存储路径的权限（如指定spark.eventLog.dir = hdfs://bigdata1:9820/spark/history）
```
[root@bigdata1 ~]# hadoop fs -chown hive:hadoop /spark/history
[root@bigdata1 ~]# hadoop fs -chmod 777 /spark/history
```

hive用户启动并输出日志
```
[root@bigdata1 ~]# sudo -i -u hive nohup hiveserver2 1>/opt/module/hive-3.1.2/logs/hive-on-spark.log 2>/opt/module/hive-3.1.2/logs/hive-on-spark.err &
```

<br>
# 八、Hive Kerberos认证使用说明
以下说明均基于普通用户

注意：如果是本地hive启动的hive任务，那么当前用户就是启动hive客户端的用户；如果是启动了hiveserver2，然后通过远程客户端提交的任务，那么当前用户就是远程登陆的用户，而不是启动hiveserver2的用户。
此时就需要注意hdfs上执行任务所需目录的权限问题，包括spark-history、/user/[用户名] 等路径的读写权限。

## 8.1 beeline客户端
1.认证，执行以下命令，并按照提示输入密码
```
[hxr@bigdata1 ~]$ kinit hxr
```
2.使用beeline客户端连接hiveserver2
```
[hxr@bigdata1 ~]$ beeline
```
使用如下url进行连接
```
beeline> !connect jdbc:hive2://bigdata1:10000/;principal=hive/bigdata1@IOTMARS.COM
```

3.查看当前登陆用户(当前kinit认证的用户)
```
0: jdbc:hive2://bigdata1:10000/> select current_user();

+------+
| _c0  |
+------+
| hxr  |
+------+
1 row selected (0.454 seconds)
```

<br>
## 8.2 Win系统DataGrip客户端
DataGrip中的Hive连接驱动没有整合Kerberos认证，所以需要自定义Hive驱动。

### 8.2.1 新建Driver
1. 创建Driver
![image.png](Kerberos认证管理.assets\5d223d206b8040f383ca6c9e9bc4c766.png)

2. 配置Driver

![image.png](Kerberos认证管理.assets\3a1e6217319d406fb315d5b4b0ba8a82.png)


URL templates：`jdbc:hive2://{host}:{port}/{database}[;<;,{:identifier}={:param}>]`

### 8.2.2 新建连接
1）基础配置
![image.png](Kerberos认证管理.assets\2c8638510f8d4f598c32c43178397175.png)

url：`jdbc:hive2://bigdata1:10000/;principal=hive/bigdata1@IOTMARS.COM`


2）高级配置
![image.png](Kerberos认证管理.assets\31bf0e9ee45248d08a871b947a0a7d35.png)


配置参数：
```
-Djava.security.krb5.conf="C:\ProgramData\MIT\Kerberos5\krb5.ini"
-Djava.security.auth.login.config="C:\ProgramData\MIT\Kerberos5\hxr.conf"
-Djavax.security.auth.useSubjectCredsOnly=false
```

3）编写JAAS（Java认证授权服务）配置文件hxr.conf，内容如下，文件名和路径须和上图中java.security.auth.login.config参数的值保持一致。
```
com.sun.security.jgss.initiate{
      com.sun.security.auth.module.Krb5LoginModule required
      useKeyTab=true
      useTicketCache=false
      keyTab="C:\ProgramData\MIT\Kerberos5\hxr.keytab"
      principal="hxr@IOTMARS.COM";
};
```

4）为用户生成keytab文件，在krb5kdc所在节点（192.168.101.174）执行以下命令
```
[root@192.168.101.174 ~]# kadmin.local -q"xst -norandkey -k /root/hxr.keytab hxr"
```

5）将上一步生成的hxr.keytab文件放到hxr.conf中配置的keytab的路径下

6）测试连接

<br>
## 8.3 IOS系统DataGrip客户端
同Win系统的配置。


<br>
# 九、数仓全流程认证
Hadoop启用Kerberos安全认证之后，之前的非安全环境下的全流程调度脚本和即席查询引擎均会遇到认证问题，故需要对其进行改进。

**需要认证的框架如下：**
- flume导出到hdfs
- 运行hive任务脚本
- datax导入hdfs业务数据到hdfs
- sqoop导出hdfs数据到报表库
- Presto即席查询

## 9.1 准备工作
此处统一将数仓的全部数据资源的所有者设为hive用户，全流程的每步操作均认证为hive用户。

1. 创建用户
前面已经创建过了可以跳过
```
[root@bigdata1 ~]# useradd hive -g hadoop
[root@bigdata1 ~]# echo hive | passwd --stdin hive

[root@bigdata2 ~]# useradd hive -g hadoop
[root@bigdata2 ~]# echo hive | passwd --stdin hive

[root@bigdata3 ~]# useradd hive -g hadoop
[root@bigdata3  ~]# echo hive | passwd --stdin hive
```

2. 为hive用户创建主体
现在创建的主体是为了用户进行登陆使用，注意与先前创建的用于hive服务认证的主体hive/bigdata1@IOTMARS.COM进行区别。
1）创建主体
```
   [root@bigdata1 ~]# kadmin -padmin/admin -wPassword@123 -q"addprinc -randkey hive"
```

2）生成keytab文件
```
   [root@bigdata1 ~]# kadmin -padmin/admin -wPassword@123 -q"xst -k /etc/security/keytab/hive.keytab hive"
```
3）修改keytab文件的所有者和访问权限
```
   [root@bigdata1 ~]# chown hive:hadoop /etc/security/keytab/hive.keytab
   [root@bigdata1 ~]# chmod 440 /etc/security/keytab/hive.keytab
```
4）分发到其他节点

3. 修改HDFS存储数据的路径所有者
```
[root@bigdata3 logs]# hadoop fs -chown -R hive:hadoop /warehouse
[root@bigdata3 logs]# hadoop fs -chown -R hive:hadoop /origin_data
```

## 9.2 DataX认证配置
需要添加三个参数
- "haveKerberos": "true"
- "kerberosKeytabFilePath": "/etc/security/keytab/hive.keytab"
- "kerberosPrincipal": "hive@IOTMARS.COM"

例:
```
        "writer": {
          "name": "hdfswriter",
          "parameter": {
            "defaultFS": "hdfs://192.168.101.179:9820",
            "fileType": "text",
            "path": "/origin_data/compass/fineDB/FR_DIM_PRODUCT",
            "fileName": "FR_DIM_PRODUCT",
            "writeMode": "nonConflict",
            "fieldDelimiter": "	",
            "haveKerberos": "true",
            "kerberosKeytabFilePath": "/etc/security/keytab/hive.keytab",
            "kerberosPrincipal": "hive@IOTMARS.COM",
            "column": [
              {
                "name": "cinvcname_real",
                "type": "string"
              },
              {
                "name": "channel1",
                "type": "string"
              }
            ]
          }
        }
```

注：如果出现异常Message stream modified (41)，将/etc/krb5.conf中的renew_lifetime = xxx注释掉即可。

实际使用中还出现了异常如下
```
org.apache.hadoop.ipc.RemoteException(java.io.IOException): File /origin_data/compass/fineDB/FR_DIM_PRODUCT__49f79963_22df_4c74_85c3_f67ea52d83b4/FR_DIM_PRODUCT__59313560_d74b_418d_bd9f_814bfa17288f could only be written to 0 of the 1 minReplication nodes. There are 3 datanode(s) running and 3 node(s) are excluded in this operation.
```
因为Hadoop集群的hdfs-site.xml中配置了dfs.data.transfer.protection=authentication，而Datax没有配置，在Datax源码中加上`hadoopConf.set("dfs.data.transfer.protection", "authentication");`后重新打包即可。

## 9.3 Flume认证配置
修改/opt/module/flume/conf/kafka-flume-hdfs.conf配置文件，增加以下参数
```
a1.sinks.k1.hdfs.kerberosPrincipal=hive@IOTMARS.COM
a1.sinks.k1.hdfs.kerberosKeytab=/etc/security/keytab/hive.keytab
```

## 9.4 Hive脚本认证配置
数仓各层脚本均需在顶部加入如下认证语句
`kinit -kt /etc/security/keytab/hive.keytab hive`

注：可以使用sed命令快速添加语句，`sed -i '1 a text' file` 表示将text内容加入到file文件的第1行之后

## 9.5 Sqoop认证配置
修改sqoop每日同步脚本/home/atguigu/bin/mysql_to_hdfs.sh
在顶部增加如下认证语句
```
kinit -kt /etc/security/keytab/hive.keytab hive
```

例：
```
#!/bin/bash
kinit -kt /etc/security/keytab/hive.keytab hive

sqoop=/opt/module/sqoop-1.4.6/bin/sqoop

if [ -n '$1' ];then
  do_date=$1
else
  do_date=`date -d '-1 day' +%F`
fi

import_data(){
$sqoop import \
--connect "jdbc:mysql://192.168.101.174:3306/azkaban?characterEncoding=utf-8&useSSL=false" \
--username root \
--password Password@123 \
--query "$2 and \$CONDITIONS" \
--num-mappers 1 \
--target-dir /origin_data/compass/fineDB/$1/$do_date \
--delete-target-dir \
--fields-terminated-by '	' \
--compress \
--compression-codec lzop \
--null-string '\N' \
--null-non-string '\N'
}

import_data test "select * from executors where 1=1"
```

## 9.6 Azkaban认证配置
只是调度脚本，不需要认证。
需要注意的是，调度脚本中的认证命令`kinit -kt /etc/security/keytab/hive.keytab hive`需要有权限，可以保证能成功执行。

注：可以创建一个azkaban:hadoop用户来启动azkaban。

## 9.7 Presto认证配置
待续

## 9.8 Kylin认证配置
待续

## 9.9 Flink On Yarn认证配置
### 9.9.1 使用本地主机的token认证
1. 在本地Kerberos客户端完成用户认证获取token
`kinit chenjie`
2. 在Flink的配置文件flink-conf.yaml中添加配置
```
security.kerberos.login.use-ticket-cache: true
```
这是直接运行Flink向Yarn提交任务时就会自动完成Kerberos认证。
但是token会过期，推荐使用keytab完成认证。

### 9.9.2 使用keytab认证
这种方式时通过客户端将keytab提交到Hadoop集群，再通过YARN分发keytab给AM和其他 worker container，具体步骤如下：
1. Flink客户端在提交任务时，将keytab上传至HDFS，将其作为AM需要本地化的资源。
2. AM container初始化时NodeManager将keytab拷贝至container的资源目录，然后再AM启动时通过UserGroupInformation.loginUserFromKeytab()来重新认证。
3. 当AM需要申请其他worker container时，也将 HDFS 上的keytab列为需要本地化的资源，因此worker container也可以仿照AM的认证方式进行认证。
4. 此外AM和container都必须额外实现一个线程来定时刷新TGT。
5. 任务运行结束后，集群中的keytab也会随container被清理掉。

![image.png](Kerberos认证管理.assets