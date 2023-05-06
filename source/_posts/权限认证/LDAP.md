---
title: LDAP
categories:
- 权限认证
---
# 一、概念
轻型目录访问协议（英文：Lightweight Directory Access Protocol，缩写：LDAP，/ˈɛldæp/）是一个开放的，中立的，工业标准的应用协议，通过IP协议提供访问控制和维护分布式信息的目录信息。

| 关键字 | 英文全称          | 含义                                                         |
| ------ | ----------------- | ------------------------------------------------------------ |
| dc     | Domain Component  | 域名的一部分，如域名为example.com，变成dc=example,dc=com     |
| uid    | User Id           | 用户ID，如"cj"                                               |
| ou     | Organization Unit | 组织单位，类似Linux文件系统中的子目录，它是一个容器对象，组织单位可以包含其他各种对象（包括其他阻止单元），如"tech" |
| cn     | Common Name       | 公共名称，如"Thomas Johansson"                               |
| sn     | Surname           | 姓，如"Johansson"                                            |
| dn     | Distinguished     | 唯一辨别名，类似于Linux文件系统中的绝对路径，每个对象都有一个唯一的名称，如"uid=tom,ou=market,dc=example,dc=com"，在一个目录树中DN总是唯一的。 |
| rdn    | Relative dn       | 相对辨别名，类似于文件系统中的相对路径，它是与目录树结构无关的部分，如"uid=tom"或"cn=Thomas Johansson" |
| c      | Country           | 国家，如"CN"或"US"等                                         |
| o      | Organization      | 组织名，如"Example, Inc."                                    |


DN的两种设置：①基于cn(姓名)，如"cn=Tom Johansson, ou=auth, dc=etiantian, dc=org"。最常见的cn是从/etc/group转来的条目。  ②基于uid(User ID)，"uid=cj, ou=auth, dc=etiantian, dc=org"。最常见的uid是/etc/passwd转来的条目。

Base DN：LDAP目录树的最顶部就是根，也就是Base DN。

LDIF格式：LDIF(Light Directory Information Format)格式是用于LDAP数据导入、导出的格式。LDIF是LDAP数据库信息的一种文本格式。

<br>
如下图，managers这一列表示的是部门，所以objectClass为organizationUnit；Test的属性是一个人，用common name表示其属性。其中每个dn必须从下到上包含上层dn，并且一直写到根。
dn：cn=test，ou=managers，ou=dlw.com

![传统结构](LDAP.assets\1b41e3072fbe4412995fef3ee3a63e7a.png)

![DNS式结构](LDAP.assetsce276af483544c0b123aa6beb191d24.png)


**优点**
用LDAP的原因，主要可以总结为三点：轻，快，好。
- 轻，表现在搭建简单，开放的Internet标准，支持跨平台的Internet协议。与市场上和开源领域的大多数产品兼容。配置简单，重复开发和对接的成本低。
- 快，读的速度快。目录是一个为查询、浏览和搜索而优化的数据库，它成树状结构组织数据，类似文件目录一样。目录数据库和关系数据库不同，它有优异的读性能（但写性能差，并且没有事务处理、回滚等复杂功能，不适于存储修改频繁的数据。）
- 好，动态，灵活，易扩展。

<br>
# 二、部署
## 2.1 安装服务端
```
docker run -d -p 389:389  -p 636:636 --name openldap --privileged=true -v /root/docker/ldap/data:/var/lib/ldap -v /root/docker/ldap/ldap.d:/etc/ldap/slapd.d --env LDAP_ORGANISATION="se" --env LDAP_DOMAIN="ldap.chenjie.asia" --env LDAP_ADMIN_PASSWORD="bigdata123" osixia/openldap
```
>其中 -p 389:389 \ TCP/IP访问端口，-p 636:636 \ SSL连接端口。
--nameldap 容器名称为ldap
--env LDAP_ORGANISATION="es" 配置LDAP组织名称
--env LDAP_DOMAIN="ldap.chenjie.asia" 配置LDAP域名
--env LDAP_ADMIN_PASSWORD="abc123" 配置LDAP密码
默认登录用户名：admin

## 2.2 安装客户端
```
docker run -d --privileged -p 8080:80 --name ldapadmin --env PHPLDAPADMIN_HTTPS=false --env PHPLDAPADMIN_LDAP_HOSTS=192.168.32.244 osixia/phpldapadmin
```
>--privileged 特权模式启动(使用该参数，container内的root拥有真正的root权限。否则，container内的root只是外部的一个普通用户权限。)
--env PHPLDAPADMIN_HTTPS=false 禁用HTTPS
--env PHPLDAPADMIN_LDAP_HOSTS =192.168.32.244 配置openLDAP的IP或者域名

## 2.3 操作
### 2.3.1 登陆
访问[http://192.168.32.244:8080](http://192.168.32.244:8080)页面，账号Login DN为`cn=admin,dc=ldap,dc=chenjie,dc=asia`，密码为`abc123`。

### 2.3.2 添加用户

## 2.4 命令
①查找目录下所有的用户
`ldapsearch  -LLL -w abc123 -x -H ldap://192.168.32.244:389 -D"cn=admin,dc=ldap,dc=chenjie,dc=asia" -b "ou=it,dc=ldap,dc=chenjie,dc=asia"`
②查找目录下指定的用户
`ldapsearch  -LLL -w abc123 -x -H ldap://192.168.32.244:389 -D"cn=admin,dc=ldap,dc=chenjie,dc=asia" -b "ou=it,dc=ldap,dc=chenjie,dc=asia" "cn=chenjie"`
>-LLL: 去除无用的信息
>-x: 简答认证方式
>-W: 不需要在命令上写密码 ldapapp -x -D "cn=Manager,dc=suixingpay,dc=com" -W
>-w: 密码 ldapapp -x -D "cn=Manager,dc=suixingpay,dc=com" -w 123456
>-H: 连接地址
>-h: hostname/ipaddress
>-D: 指定用户管理员的账号和域
>-p: 端口 明文389 密文636
>-v: 显示详细
>-f: filename.ldif文件
>-a: 新增条目

<!--
③认证密码
`ldapwhoami -vvv -h http://192.168.32.244 -p 389 -D 'cn=chenjie,dc=ldap,dc=chenjie,dc=asia' -x -w chenjie`   命令有问题，报错
-->

<br>
# 三、LDAP
## 3.1 LDAP整合Hive
在hive-site.xml中进行配置
```
    <!-- 登陆认证使用LDAP -->
    <property>
        <name>hive.server2.authentication</name>
        <value>LDAP</value>
    </property>
    <property>
        <name>hive.server2.authentication.ldap.url</name>
        <value>ldap://192.168.101.174:389</value>
    </property>
    <property>
        <name>hive.server2.authentication.ldap.baseDN</name>
        <value>ou=hive,dc=ldap,dc=chenjie,dc=asia</value>
    </property>
```
配置完成后重启hiveserver2服务即可。

`需要注意的是，hive中配置的ldap只会读取配置的baseDN下的用户，而不会递归读取baseDN下的所有子目录中的用户`

注：可以使用LDAP+Ranger来为hiveserver2进行认证鉴权，但大数据框架更通用的认证鉴权方式是Kerberos+Ranger。


## 3.2 LDAP整合jenkins
进入Manage Jenkins -> Configure Global Security ，在访问控制中选择LDAP，配置如下。用户的权限控制可以通过Manage and Assign Roles来实现。

![image.png](LDAP.assets18f99ecf13b4d7bb30e1f1287c1cc87.png)

>`需要注意的是，一旦使用LDAP，那么原来的管理员账户会失效，需要再指定一个LDAP中的用户给其管理员权限，否则LDAP中的全部用户都没有任何权限。`如果不幸的事发生，那么有两个方法来获取管理员权限：
>①LDAP中创建一个与原管理员账号同名的用户，那么该用户就是超级管理员。
>②修改jenkins的配置文件了，该配置文件在docker中的位置是 **/var/jenkins_home/config.xml**，修改内容如下：
>```
><securityRealm class="hudson.security.HudsonPrivateSecurityRealm">    
>    <disableSignup>false</disableSignup>
>    <enableCaptcha>false</enableCaptcha>
></securityRealm>
>```
>修改完成后使用原来的管理员账户进行登陆，重新保存一下LDAP配置，并给一个用户超级管理员角色即可。

以上都完成后，可以使用Test LDAP Settings按钮进行用户登陆测试，user为uid，password为对应的用户密码。

![image.png](LDAP.assets\748f13497e4b43c3babf1d26dd556d64.png)

## 3.3 LDAP整合Ranger
修改ranger的配置文件ranger-admin-site.xml
```
authentication_method=LDAP
xa_ldap_url=ldap://192.168.101.174:389
xa_ldap_userDNpattern=uid={0},ou=hive,dc=ldap,dc=chenjie,dc=asia
xa_ldap_groupSearchBase=
xa_ldap_groupSearchFilter=
xa_ldap_groupRoleAttribute=
xa_ldap_base_dn=ou=hive,dc=ldap,dc=chenjie,dc=asia
xa_ldap_bind_dn=cn=admin,dc=ldap,dc=chenjie,dc=asia
xa_ldap_bind_password=abc123
xa_ldap_referral=
xa_ldap_userSearchFilter=
```
在root用户下 ./setup.sh 进行安装，然后重启 `ranger-admin restart`。
在配置文件中配置的admin的密码仍然有效，登录后仍然是管理员用户。ldap中的用户也可以进行登陆，这些都是普通用户。

## 3.4 LDAP整合Clickhouse

[官网配置](https://clickhouse.tech/docs/en/operations/external-authenticators/ldap/)

## 3.5 LDAP整合Azkaban
查看[官网文档](https://azkaban.readthedocs.io/en/latest/userManager.html#custom-user-manager)，实现LDAP整合Azkaban，需要我们自己写类实现UserManager接口，将项目打成jar包放到指定目录下。
在Github上可以找到[大佬写的项目](https://github.com/researchgate/azkaban-ldap-usermanager) ，已经实现了UserManager接口。我们只需要拉代码打包，然后将jar包然后放到azkaban上即可。步骤如下：

①打包
win上打包命令如下 `gradlew.bat build`
打包完成后在 ./build/libs 目录下既可获取jar包

②部署
在azkaban的web目录下创建文件夹./extlib ，将jar包放到文件夹下即可。

③配置文件
azkaban.properties
```
# Azkaban UserManager class
#user.manager.class=azkaban.user.XmlUserManager
#user.manager.xml.file=conf/azkaban-users.xml
user.manager.class=net.researchgate.azkaban.LdapUserManager

user.manager.ldap.host=192.168.101.174
user.manager.ldap.port=389
user.manager.ldap.useSsl=false
user.manager.ldap.userBase=ou=azkaban,dc=ldap,dc=chenjie,dc=asia
user.manager.ldap.userIdProperty=uid
user.manager.ldap.emailProperty=mail
user.manager.ldap.bindAccount=cn=admin,dc=ldap,dc=chenjie,dc=asia
user.manager.ldap.bindPassword=bigdata123
user.manager.ldap.allowedGroups=
user.manager.ldap.groupSearchBase=dc=ldap,dc=chenjie,dc=asia
user.manager.ldap.embeddedGroups=false
```
>将user.manager.class配置为类路径net.researchgate.azkaban.LdapUserManager，然后配置ldap的信息，按自身实际情况配置即可。

## 3.6 LDAP整合Kerberos
当Hadoop配置了Kerberos，需要通过Kerberos认证才能进行集群的操作。同时该用户又需要配置到Ranger才能完成权限鉴定，所以将Kerberos和Ranger都整合LDAP，只需要在LDAP完成配置即可。

[官网配置流程](http://web.mit.edu/kerberos/krb5-current/doc/admin/conf_ldap.html)


## 3.7 LDAP整合Grafana
[官网配置](https://grafana.com/docs/grafana/latest/auth/ldap/)
1. 在 $WORKING_DIR/conf 目录下创建配置文件 custom.ini
```
[auth.ldap]
enabled = true
config_file = /opt/module/grafana-8.2.2/conf/ldap.toml
allow_sign_up = true
```
2. 修改config_file中配置的 ldap.toml文件
```
[[servers]]
# Ldap server host (specify multiple hosts space separated)
host = "192.168.101.174"
# Default port is 389 or 636 if use_ssl = true
port = 389
# Set to true if LDAP server should use an encrypted TLS connection (either with STARTTLS or LDAPS)
use_ssl = false
# If set to true, use LDAP with STARTTLS instead of LDAPS
start_tls = false
# set to true if you want to skip ssl cert validation
ssl_skip_verify = false

# Search user bind dn
# Search user bind dn
bind_dn = "cn=admin,dc=ldap,dc=chenjie,dc=asia"
# Search user bind password
# If the password contains # or ; you have to wrap it with triple quotes. Ex """#password;"""
bind_password = 'bigdata123'

# User search filter, for example "(cn=%s)" or "(sAMAccountName=%s)" or "(uid=%s)"
search_filter = "(cn=%s)"

# An array of base dns to search through
search_base_dns = ["ou=grafana,dc=ldap,dc=chenjie,dc=asia"]

## For Posix or LDAP setups that does not support member_of attribute you can define the below settings
## Please check grafana LDAP docs for examples
group_search_filter = "(&(objectClass=posixGroup)(memberUid=%s))"
group_search_base_dns = ["ou=grafana,dc=ldap,dc=chenjie,dc=asia"]
group_search_filter_user_attribute = "uid"

[servers.attributes]
name = "givenName"
surname = "sn"
username = "cn"
member_of = "memberOf"
email =  "mail"

# Map ldap groups to grafana org roles
[[servers.group_mappings]]
group_dn = "cn=admins,ou=grafana,dc=ldap,dc=chenjie,dc=asia"
org_role = "Admin"
# To make user an instance admin  (Grafana Admin) uncomment line below
# grafana_admin = true
# The Grafana organization database id, optional, if left out the default org (id 1) will be used
# org_id = 1

[[servers.group_mappings]]
group_dn = "cn=editors,ou=grafana,dc=ldap,dc=chenjie,dc=asia"
org_role = "Editor"

[[servers.group_mappings]]
# If you want to match all (or no ldap groups) then you can use wildcard
group_dn = "*"
org_role = "Viewer"
```
>这里配置了admins组中的用户都拥有admin权限，editors组中的用户都拥有Editor权限，其他用户都是访客权限。

## 3.8 LDAP整合Atlas
[官网配置](http://atlas.apache.org/#/Authentication)

修改配置文件${ATLAS_HOME}conf/atlas-application.properties，添加如下配置
```
#### ldap.type= LDAP or AD
atlas.authentication.method.file=true
atlas.authentication.method.file.filename=sys:atlas.home/conf/users-credentials.properties

######## LDAP properties #########
atlas.authentication.method.ldap.url=ldap://192.168.101.174:389
atlas.authentication.method.ldap.userDNpattern=uid={0},ou=atlas,dc=ldap,dc=chenjie,dc=asia
atlas.authentication.method.ldap.groupSearchBase=ou=atlas,dc=ldap,dc=chenjie,dc=asia
atlas.authentication.method.ldap.groupSearchFilter=member=uid={0},ou=atlas,dc=ldap,dc=chenjie,dc=asia
atlas.authentication.method.ldap.groupRoleAttribute=uid
atlas.authentication.method.ldap.base.dn=ou=atlas,dc=ldap,dc=chenjie,dc=asia
atlas.authentication.method.ldap.bind.dn=cn=admin,dc=ldap,dc=chenjie,dc=asia
atlas.authentication.method.ldap.bind.password=bigdata123
atlas.authentication.method.ldap.referral=ignore
atlas.authentication.method.ldap.user.searchfilter=uid={0}
atlas.authentication.method.ldap.default.role=ROLE_USER
```

## 3.9 LDAP整合GitLab
待续
