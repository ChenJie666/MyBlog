---
title: Kerberos整合Ldap
categories:
- 权限认证
---
http://web.mit.edu/kerberos/krb5-current/doc/admin/conf_ldap.html

```
Hi,
I have configured the sssd with AD server.
Now i'm able to run query.
Thanks
Let me know if anyone having any query.
[View solution in original post](https://community.cloudera.com/t5/Support-Questions/user-not-found-while-running-hive-query-from-kerberos-user/m-p/221533#M183407)
```

LDAP 用来做账号管理，Kerberos作为认证。授权一般来说是由应用来决定的，通过在 LDAP 数据库中配置一些属性可以让应用程序来进行授权判断。

在Kerberos安全机制里，一个principal就是realm里的一个对象，一个principal总是和一个密钥（secret key）成对出现的。

这个principal的对应物可以是service，可以是host，也可以是user，对于Kerberos来说，都没有区别。

Kdc(Key distribute center)知道所有principal的secret key，但每个principal对应的对象只知道自己的那个secret key。这也是 "共享密钥" 的由来。




由于集群一般来说变化的比较小，服务认证比较合适；但在多租户的集群上，Kerberos这种需要独占操作系统静态kinit自己的Principal的方式，完全无法接受；另一方面，企业、开源组件中较多使用LDAP做认证，Kerberos比较小众，因此比较好的方式是Kerberos+LDAP，LDAP作为总的用户认证中心，使用thrift server的用户通过LDAP做认证。
