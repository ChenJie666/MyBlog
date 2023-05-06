---
title: SSH登录
categories:
- Linux
---
# 一、密钥登陆原理
如果主机A需要免密登陆主机B，那么需要有凭证能证明主机A是主机B信任的节点。此时就需要主机A生成一个密钥对(私钥与公钥)，私钥是主机A保留的，公钥则需要给到主机B，保存在文件authorized_keys中(如果保存了该外部节点的公钥，则表示信任该节点)。

简单流程如下：
1. 主机A向主机B发送登录请求；
2. 主机B检查自己的./ssh/authorized_keys中是否有主机A的公钥，如果有，进入步骤3；
3. 主机B使用主机A的公钥加密一段随机字符串，并发送给A；
4. 主机A使用自己的私钥进行解密；
5. 主机A将步骤4解密的字符串发送给主机B；
6. 主机B对比字符串是否一致，一致则允许登录。

![image.png](SSH登录.assets5b208da5a6a49809d3b00e26b56cb03.png)


<br>
# 二、ssh服务器配置文件
OpenSSH（即常说的ssh）的常用配置文件有两个/etc/ssh/ssh_config和sshd_config。，其中ssh_config为客户端配置文件，设置与客户端相关的应用可通过此文件实现；sshd_config为服务器配置文件，设置与服务器相关的应用可通过此文件实现。
一般来说我们常用的都是sshd_config配置文件。
在sshd_config配置文件中，以“# ”（#加空格）开头的是注释信息，以“#”开头的是默认配置信息。

## 2.1配置文件
**/etc/ssh/ssh_config配置解释如下：**
```shell
# Site-wide defaults for various options    # 带“#”表示该句为注释不起作，该句不属于配置文件原文，意在说明下面选项均为系统初始默认的选项。说明一下，实际配置文件中也有很多选项前面加有“#”注释，虽然表示不起作用，其实是说明此为系统默认的初始化设置。
Host *    # "Host"只对匹配后面字串的计算机有效，“*”表示所有的计算机。从该项格式前置一些可以看出，这是一个类似于全局的选项，表示下面缩进的选项都适用于该设置，可以指定某计算机替换*号使下面选项只针对该算机器生效。
ForwardAgent no    # "ForwardAgent"设置连接是否经过验证代理（如果存在）转发给远程计算机。
ForwardX11 no    # "ForwardX11"设置X11连接是否被自动重定向到安全的通道和显示集（DISPLAY set）。
RhostsAuthentication no    # "RhostsAuthentication"设置是否使用基于rhosts的安全验证。
RhostsRSAAuthentication no    # "RhostsRSAAuthentication"设置是否使用用RSA算法的基于rhosts的安全验证。
RSAAuthentication yes    # "RSAAuthentication"设置是否使用RSA算法进行安全验证。
PasswordAuthentication yes    # "PasswordAuthentication"设置是否使用口令验证。
FallBackToRsh no    # "FallBackToRsh"设置如果用ssh连接出现错误是否自动使用rsh，由于rsh并不安全，所以此选项应当设置为"no"。
UseRsh no    # "UseRsh"设置是否在这台计算机上使用"rlogin/rsh"，原因同上，设为"no"。
BatchMode no    # "BatchMode"：批处理模式，一般设为"no"；如果设为"yes"，交互式输入口令的提示将被禁止，这个选项对脚本文件和批处理任务十分有用。
CheckHostIP yes    # "CheckHostIP"设置ssh是否查看连接到服务器的主机的IP地址以防止DNS欺骗。建议设置为"yes"。
StrictHostKeyChecking no    # "StrictHostKeyChecking"如果设为"yes"，ssh将不会自动把计算机的密匙加入"$HOME/.ssh/known_hosts"文件，且一旦计算机的密匙发生了变化，就拒绝连接。
IdentityFile ~/.ssh/identity    # "IdentityFile"设置读取用户的RSA安全验证标识。

#Port 22  # 设置sshd监听端口号，默认情况下为22，可以设置多个监听端口号，即重复使用Prot这个设置项。修改后记得重启sshd，以及在防火墙中添加端口。出于安全考虑，端口指定为小于等于65535，并且非22或22变种的值
Cipher blowfish   # “Cipher”设置加密用的密钥，blowfish可以自己随意设置。
EscapeChar ~   # “EscapeChar”设置escape字符。

#ListenAddress 0.0.0.0
#ListenAddress ::         # 设置sshd监听（绑定）的IP地址，0.0.0.0表示监听所有IPv4的地址。出于安全考虑，设置为指定IP地址，而非所有地址。::是IPv6的地址不需要改。

Protocol 2   # 有部分sshd_config配置文件会有此选项。这个选项设置的是ssh协议版本，可以是1也可以是2。出于安全考虑，设置为最新协议版本。

HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key　　# Hostkey设置包含私人密钥的文件

#SyslogFacility AUTH   # SyslogFacility AUTHPRIV
　　当有人使用ssh登录系统时，ssh会记录信息，记录类型为AUTHPRIV，sshd服务日志存放在/var/log/secure

#LogLevel INFO　　# 设置记录sshd日志信息的级别

#LoginGraceTime 2m　　# 设置指定时间内没有成功登录，将会断开连接，若无单位则默认时间为秒。

#PermitRootLogin yes　　# 是否允许root登录，默认是允许的，但建议设置为no
#PasswordAuthentication yes　　# 是否使用密码验证。当然也可以设置为no，不使用密码验证，转而使用密钥登录

#PermitEmptyPasswords no　　# 是否允许空密码的用户登录，默认为no，不允许

#PrintMotd yes　　# 是否打印登录提示信息，提示信息存储在/etc/moed文件中

#PrintLastLog yes　　# 显示上次登录信息。默认为yes

#UseDNS yes　　# 一般来说为了要判断客户端来源是否正常合法，因此会使用DNS去反查客户端的主机名。但通常在内网互连时，设置为no，使连接快写。
```


**/etc/ssh/sshd_config 配置解释如下：**
```shell
Port 22　　# "Port"设置sshd监听的端口号。
ListenAddress 192.168.1.1　　# "ListenAddress”设置sshd服务器绑定的IP地址。
HostKey /etc/ssh/ssh_host_key　　# "HostKey”设置包含计算机私人密匙的文件。
ServerKeyBits 1024　　# "ServerKeyBits”定义服务器密匙的位数。
LoginGraceTime 600　　# "LoginGraceTime”设置如果用户不能成功登录，在切断连接之前服务器需要等待的时间（以秒为单位）。
KeyRegenerationInterval 3600　　# "KeyRegenerationInterval”设置在多少秒之后自动重新生成服务器的密匙（如果使用密匙）。重新生成密匙是为了防止用盗用的密匙解密被截获的信息。
PermitRootLogin no　　# "PermitRootLogin”设置是否允许root通过ssh登录。这个选项从安全角度来讲应设成"no"。
IgnoreRhosts yes　　# "IgnoreRhosts”设置验证的时候是否使用“rhosts”和“shosts”文件。
IgnoreUserKnownHosts yes　　# "IgnoreUserKnownHosts”设置ssh daemon是否在进行RhostsRSAAuthentication安全验证的时候忽略用户的"$HOME/.ssh/known_hosts”
StrictModes yes　　# "StrictModes”设置ssh在接收登录请求之前是否检查用户家目录和rhosts文件的权限和所有权。这通常是必要的，因为新手经常会把自己的目录和文件设成任何人都有写权限。
X11Forwarding no　　# "X11Forwarding”设置是否允许X11转发。
PrintMotd yes　　# "PrintMotd”设置sshd是否在用户登录的时候显示“/etc/motd”中的信息。
SyslogFacility AUTH　　# "SyslogFacility”设置在记录来自sshd的消息的时候，是否给出“facility code”。
LogLevel INFO　　# "LogLevel”设置记录sshd日志消息的层次。INFO是一个好的选择。查看sshd的man帮助页，已获取更多的信息。
RhostsAuthentication no　　# "RhostsAuthentication”设置只用rhosts或“/etc/hosts.equiv”进行安全验证是否已经足够了。
RhostsRSAAuthentication no　　# "RhostsRSA”设置是否允许用rhosts或“/etc/hosts.equiv”加上RSA进行安全验证。
RSAAuthentication yes　　# "RSAAuthentication”设置是否允许只有RSA安全验证。
PasswordAuthentication yes　　# "PasswordAuthentication”设置是否允许口令验证。
PermitEmptyPasswords no　　# "PermitEmptyPasswords”设置是否允许用口令为空的帐号登录。
AllowUsers admin　　# "AllowUsers”的后面可以跟任意的数量的用户名的匹配串，这些字符串用空格隔开。主机名可以是域名或IP地址。
```

## 2.2 调优
## 2.2.1 UseDNS


```
#############1. 关于 SSH Server 的整体设定##############
GSSAPIAuthentication no # 通常情况下我们在连接 OpenSSH服务器的时候假如 UseDNS选项是打开的话，服务器会先根据客户端的 IP地址进行 DNS PTR反向查询出客户端的主机名，然后根据查询出的客户端主机名进行DNS正向A记录查询，并验证是否与原始 IP地址一致，通过此种措施来防止客户端欺骗。平时我们都是动态 IP不会有PTR记录，所以打开此选项也没有太多作用。我们可以通过关闭此功能来提高连接 OpenSSH 服务器的速度。
Port 22   #port用来设置sshd监听的端口，为了安全起见，建议更改默认的22端口为5位以上陌生端口
Protocol 2  #设置协议版本为SSH1或SSH2，SSH1存在漏洞与缺陷，选择SSH2
ListenAddress 0.0.0.0  #用来设置sshd服务器绑定的IP地址，监听的主机适配卡，举个例子来说，如果您有两个 IP， 分别是 192.168.0.11 及 192.168.2.20 ，那么只想要开放 192.168.0.11 时，就可以设置为：ListenAddress 192.168.0.11

#############2. 说明主机的 Private Key 放置的档案##########　　　
ListenAddress ::   #HostKey用来设置服务器秘钥文件的路径
HostKey /etc/ssh/ssh_host_key   #设置SSH version 1 使用的私钥
HostKey /etc/ssh/ssh_host_rsa_key  #设置SSH version 2 使用的 RSA 私钥
HostKey /etc/ssh/ssh_host_dsa_key   #设置SSH version 2 使用的 DSA 私钥

Compression yes   #设置是否可以使用压缩指令

KeyRegenerationInterval 1h   #KeyRegenerationInterval用来设置多长时间后系统自动重新生成服务器的秘钥，（如果使用密钥）。重新生成秘钥是为了防止利用盗用的密钥解密被截获的信息。

ServerKeyBits 768   #ServerKeyBits用来定义服务器密钥的长度，指定临时服务器密钥的长度。仅用于SSH-1。默认值是 768(位)。最小值是 512 。


SyslogFacility AUTHPRIV   #SyslogFacility用来设定在记录来自sshd的消息的时候，是否给出“facility code”

LogLevel INFO   #LogLevel用来设定sshd日志消息的级别


#################3.安全认证方面的设定################
#############3.1、有关安全登录的设定###############
Authentication:   #限制用户必须在指定的时限内认证成功，0 表示无限制。默认值是 120 秒。
LoginGraceTime 2m   #LoginGraceTime用来设定如果用户登录失败，在切断连接前服务器需要等待的时间，单位为秒
PermitRootLogin yes   #PermitRootLogin用来设置能不能直接以超级用户ssh登录，root远程登录[Linux](http://lib.csdn.net/base/linux "Linux知识库")很危险，建议注销或设置为no

StrictModes yes   #StrictModes用来设置ssh在接收登录请求之前是否检查用户根目录和rhosts文件的权限和所有权，建议开启，建议使用默认值"yes"来预防可能出现的低级错误。

RSAAuthentication yes   #RSAAuthentication用来设置是否开启RSA密钥验证，只针对SSH1

PubkeyAuthentication yes   #PubkeyAuthentication用来设置是否开启公钥验证，如果使用公钥验证的方式登录时，则设置为yes

AuthorizedKeysFile     .ssh/authorized_keys   #AuthorizedKeysFile用来设置公钥验证文件的路径，与PubkeyAuthentication配合使用,默认值是".ssh/authorized_keys"。该指令中可以使用下列根据连接时的实际情况进行展开的符号： %% 表示'%'、%h 表示用户的主目录、%u 表示该用户的用户名。经过扩展之后的值必须要么是绝对路径，要么是相对于用户主目录的相对路径

#############3.2、安全验证的设定###############
# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#RhostsRSAAuthentication no
##是否使用强可信主机认证(通过检查远程主机名和关联的用户名进行认证)。仅用于SSH-1。
###这是通过在RSA认证成功后再检查 ~/.rhosts 或 /etc/hosts.equiv 进行认证的。出于安全考虑，建议使用默认值"no"。

# similar for protocol version 2
#HostbasedAuthentication no
##这个指令与 RhostsRSAAuthentication 类似，但是仅可以用于SSH-2。

# Change to yes if you don't trust ~/.ssh/known_hosts for
# RhostsRSAAuthentication and HostbasedAuthentication

#IgnoreUserKnownHosts no
##IgnoreUserKnownHosts用来设置ssh在进行RhostsRSAAuthentication安全验证时是否忽略用户的“/$HOME/.ssh/known_hosts”文件
# Don't read the user's ~/.rhosts and ~/.shosts files

#IgnoreRhosts yes
##IgnoreRhosts用来设置验证的时候是否使用“~/.rhosts”和“~/.shosts”文件

# To disable tunneled clear text passwords, change to no here!
#PasswordAuthentication yes
##PasswordAuthentication用来设置是否开启密码验证机制，如果用密码登录系统，则设置yes

#PermitEmptyPasswords no
#PermitEmptyPasswords用来设置是否允许用口令为空的账号登录系统，设置no

#PasswordAuthentication yes
##是否允许使用基于密码的认证。默认为"yes"。
PasswordAuthentication yes

# Change to no to disable s/key passwords
##设置禁用s/key密码
#ChallengeResponseAuthentication yes
##ChallengeResponseAuthentication 是否允许质疑-应答(challenge-response)认证
ChallengeResponseAuthentication no


########3.3、与 Kerberos 有关的参数设定，指定是否允许基于Kerberos的用户认证########
#Kerberos options
#KerberosAuthentication no
##是否要求用户为PasswdAuthentication提供的密码必须通过Kerberos KDC认证，要使用Kerberos认证，
###服务器必须提供一个可以校验KDC identity的Kerberos servtab。默认值为no

#KerberosOrLocalPasswd yes
##如果Kerberos密码认证失败，那么该密码还将要通过其他的的认证机制，如/etc/passwd
###在启用此项后，如果无法通过Kerberos验证，则密码的正确性将由本地的机制来决定，如/etc/passwd，默认为yes

#KerberosTicketCleanup yes
##设置是否在用户退出登录是自动销毁用户的ticket

#KerberosGetAFSToken no
##如果使用AFS并且该用户有一个Kerberos 5 TGT,那么开启该指令后，
###将会在访问用户的家目录前尝试获取一个AFS token,并尝试传送 AFS token 给 Server 端，默认为no

 

####3.4、与 GSSAPI 有关的参数设定，指定是否允许基于GSSAPI的用户认证，仅适用于SSH2####
##GSSAPI 是一套类似 Kerberos 5 的通用网络安全系统接口。
###如果你拥有一套 GSSAPI库，就可以通过 tcp 连接直接建立 cvs 连接，由 GSSAPI 进行安全鉴别。

# GSSAPI options
#GSSAPIAuthentication no
##GSSAPIAuthentication 指定是否允许基于GSSAPI的用户认证，默认为no

GSSAPIAuthentication yes
#GSSAPICleanupCredentials yes
##GSSAPICleanupCredentials 设置是否在用户退出登录是自动销毁用户的凭证缓存
GSSAPICleanupCredentials yes

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication mechanism.
# Depending on your PAM configuration, this may bypass the setting of
# PasswordAuthentication, PermitEmptyPasswords, and
# "PermitRootLogin without-password". If you just want the PAM account and
# session checks to run without PAM authentication, then enable this but set
# ChallengeResponseAuthentication=no
#UsePAM no
##设置是否通过PAM验证
UsePAM yes

# Accept locale-related environment variables
##AcceptEnv 指定客户端发送的哪些环境变量将会被传递到会话环境中。
###[注意]只有SSH-2协议支持环境变量的传递。指令的值是空格分隔的变量名列表(其中可以使用'*'和'?'作为通配符)。
####也可以使用多个 AcceptEnv 达到同样的目的。需要注意的是，有些环境变量可能会被用于绕过禁止用户使用的环境变量。
#####由于这个原因，该指令应当小心使用。默认是不传递任何环境变量。

AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL
AllowTcpForwarding yes

##AllowTcpForwarding设置是否允许允许tcp端口转发，保护其他的tcp连接

#GatewayPorts no
##GatewayPorts 设置是否允许远程客户端使用本地主机的端口转发功能，出于安全考虑，建议禁止

 

#############3.5、X-Window下使用的相关设定###############

#X11Forwarding no
##X11Forwarding 用来设置是否允许X11转发
X11Forwarding yes

#X11DisplayOffset 10
##指定X11 转发的第一个可用的显示区(display)数字。默认值是 10 。
###可以用于防止 sshd 占用了真实的 X11 服务器显示区，从而发生混淆。
X11DisplayOffset 10

#X11UseLocalhost yes

 

#################3.6、登入后的相关设定#################

#PrintMotd yes
##PrintMotd用来设置sshd是否在用户登录时显示“/etc/motd”中的信息，可以选在在“/etc/motd”中加入警告的信息

#PrintLastLog yes
#PrintLastLog 是否显示上次登录信息

#TCPKeepAlive yes
##TCPKeepAlive 是否持续连接，设置yes可以防止死连接
###一般而言，如果设定这项目的话，那么 SSH Server 会传送 KeepAlive 的讯息给 Client 端，以确保两者的联机正常！
####这种消息可以检测到死连接、连接不当关闭、客户端崩溃等异常。在这个情况下，任何一端死掉后， SSH 可以立刻知道，而不会有僵尸程序的发生！

#UseLogin no
##UseLogin 设置是否在交互式会话的登录过程中使用。默认值是"no"。
###如果开启此指令，那么X11Forwarding 将会被禁止，因为login不知道如何处理 xauth cookies 。
####需要注意的是，在SSH底下本来就不接受 login 这个程序的登入，如果指UsePrivilegeSeparation ，那么它将在认证完成后被禁用。
UserLogin no　　　　　　　

#UsePrivilegeSeparation yes
##UsePrivilegeSeparation 设置使用者的权限
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#ShowPatchLevel no

#UseDNS yes
##UseDNS是否使用dns反向解析

#PidFile /var/run/sshd.pid

#MaxStartups 10
##MaxStartups 设置同时允许几个尚未登入的联机，当用户连上ssh但并未输入密码即为所谓的联机，
###在这个联机中，为了保护主机，所以需要设置最大值，预设为10个，而已经建立联机的不计算入内，
####所以一般5个即可，这个设置可以防止恶意对服务器进行连接

#MaxAuthTries 6
##MaxAuthTries 用来设置最大失败尝试登陆次数为6，合理设置辞职，可以防止攻击者穷举登录服务器
#PermitTunnel no

 

############3.7、开放禁止用户设定############

#AllowUsers<用户名1> <用户名2> <用户名3> ...
##指定允许通过远程访问的用户，多个用户以空格隔开

#AllowGroups<组名1> <组名2> <组名3> ...
##指定允许通过远程访问的组，多个组以空格隔开。当多个用户需要通过ssh登录系统时，可将所有用户加入一个组中。

#DenyUsers<用户名1> <用户名2> <用户名3> ...
##指定禁止通过远程访问的用户，多个用户以空格隔开

#DenyGroups<组名1> <组名2> <组名3> ...
##指定禁止通过远程访问的组，多个组以空格隔开。

# no default banner path
#Banner /some/path

# override default of no subsystems
Subsystem       sftp    /usr/libexec/openssh/sftp-server
ClientAliveInterval 3600
ClientAliveCountMax 0
```

重启 OpenSSH服务器 `sudo systemctl restart sshd`
如果是kali系统，重启的是ssh服务 `sudo systemctl restart ssh`


<br>
# 三、密钥登陆
**基础命令**
- ssh-keygen :产生公钥和私钥对
- ssh-copy-id:将本机的秘钥复制到远程机器的authorized_keys文件中，ssh-copy-id也能让你有远程机器的home，/root/.ssh，和/root/.ssh/authorized_keys的权利。

## 3.1 服务器节点间免密登陆
**登录到hxr用户，配置免密登陆。**
1. 生成密钥对
```
ssh-keygen -t rsa
```

2. 发送公钥到本机
将公钥发送到user@host上，即可免密登陆该host节点。该命令会将公钥写到指定节点host的.ssh/authorized_keys文件中，拥有该文件中的公钥对应私钥的节点都允许远程登录。
```
ssh-copy-id bigdata1
```
>如果没有出现输入密码框，直接拒绝访问，那么需要在ssh服务配置文件/etc/ssh/sshd_config 中修改或添加 PasswordAuthentication yes

3. 分别ssh登陆一下所有虚拟机
```
ssh bigdata2
ssh bigdata3
```

## 3.2 xshell等客户端免密登陆
1. 在本机生成密钥对
```
ssh-keygen -t rsa
```
2. 添加公钥到本机
```
cat id_rsa.pub >> authorized_keys
```
>需要注意修改authorized_keys文件的权限为644或600，否则会登陆失败。

3. 导出私钥id_rsa作为客户端登陆的密钥即可。
