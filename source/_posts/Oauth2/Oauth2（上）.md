---
title: Oauth2（上）
categories:
- Oauth2
---
# 一、简介

## 1.1 业务场景

公司原来使用的是自建的用户登陆系统，但是只有登陆功能，没有鉴权功能。


现公司有如下业务场景：

1. 需要接入各大智能音箱，音箱需要通过标准的Oauth2授权码模式获取令牌从而拿到服务器资源；
2. 后台管理界面需要操作权限 ；
3. 后期要做开发者平台，需要授权码模式。 

所以在以上业务场景下开始自建Oauth2框架，框架需要兼容公司原有的用户登陆系统。


## 1.3 Oauth2框架
Oauth2扩展了Security的授权机制。


# 二、相关概念

## 2.1 单点登陆

即一个token可以访问多个微服务。


## 2.2 授权方式

### ①授权码模式

第三方应用通过客户端进行登录，如果通过github账号进行登录，那么第三方应用会跳转到github的资源服务器地址，携带了client_id、redirect_uri、授权类型(code模式)和state(防止csrf攻击的token,可以不填)。随后资源服务器会重定向到第三方应用url并携带code和state参数，随后第三方应用携带code、client_id和client_secret再去请求授权服务器，先验证code是否有效，有效则发放认证token，携带该token可以取资源服务器上的资源。

授权码模式（authorization code）是功能最完整、流程最严密的授权模式，code保证了token的安全性，即使code被拦截，由于没有app_secret，也是无法通过code获得token的。



**如当我们登陆CSDN的时候，可以使用第三方Github账号密码进行登陆并获取头像等信息。**

首先需要注册CSDN的信息

- 应用名称
- 应用网站
- 重定向标识 redirect_uri
- 客户端标识 client_id
- 客户端秘钥 client_secret

如github认证服务器中可以对客户端进行注册，需要填写应用名称、网站地址、应用描述和重定向地址。这样github就记录了该应用并产生一个client_id和client_secret。
![](Oauth2（上）.assets\de0f929920604dd9a7e3d8b81d16b10a.png)


**获取令牌流程图如下：**

![](Oauth2（上）.assets\53b4b394f12f477b99ba17f18dec235e.png)




**优点**

- 不会造成我们的账号密码泄漏
- Token不会暴露给前端浏览器



**看下测试实例**

```json
# 指定授权方式为code模式，携带客户端id、重定向地址等信息访问。
GET https://oauth.marssenger.com/oauth/authorize?client_id=c1&response_type=code&scope=ROLE_ADMIN&redirect_uri=http://www.baidu.com
# 会跳转到登陆页面，输入账号密码。如果信息正常，会携带code跳转到重定向地址。
https://www.baidu.com/?code=YEQCZO
# 然后携带code访问授权服务器，就可以获取到令牌了。
https://oauth.marssenger.com/oauth/token?client_id=c1&client_secret=123456&grant_type=authorization_code&code=YEQCZO&redirect_uri=http://www.baidu.com
# 最终得到令牌如下
{
    "access_token": "ey......Jgw",
    "token_type": "bearer",
    "refresh_token": "ey......J-A",
    "expires_in": 86399,
    "scope": "ROLE_ADMIN",
    "cre": 1622694842,
    "jti": "fd970e49-082f-492e-9418-b21b45452f2d"
}
```

> access_token：访问令牌，携带此令牌访问资源
> token_type：有MAC Token与Bearer Token两种类型，两种的校验算法不同，RFC 6750建议Oauth2采用 Bearer Token。
> refresh_token：刷新令牌，使用此令牌可以延长访问令牌的过期时间。
> expires_in：过期时间，单位为秒。
> scope：范围，与定义的客户端范围一致。
> cre：自定义添加的令牌创建日期
> jti： jwt的唯一身份标识，主要用来作为一次性token,从而回避重放攻击。

**为什么需要使用code去换取token，而不是直接返回token？**
1. 如果直接获取token，那么client_secret需要写在url中，这样容易造成客户端秘密泄漏。
2. 如果重定向地址是http协议传输的，可能导致code被截获泄漏，但是code只能使用一次，所以如果code失效，可以及时发现被攻击。code换取token这一步一般使用的是https协议，避免被中间人攻击。
>The code exchange step ensures that an attacker isn’t able to intercept the access token, since the access token is always sent via a secure backchannel between the application and the OAuth server.


### ②简化模式

第三方应用通过客户端进行登录，通过github账号访问资源服务器，认证完成后重定向到redirect_uri并携带token，省略了通过授权码再去获取token的过程。

适用于公开的浏览器单页应用，令牌直接从授权服务器返回，不支持刷新令牌，且没有code安全保证，令牌容易因为被拦截窃听而泄露。

![](Oauth2（上）.assets\76ba0eeff949469d90d7dfcda4f15dc7.png)




**看下测试实例**

```
# 指定授权方式为token模式，携带客户端id、重定向地址等信息访问。
GET https://oauth.marssenger.com/oauth/authorize?client_id=c1&response_type=token&scope=ROLE_ADMIN&redirect_uri=http://www.baidu.com
# 直接获取到了access_token，不支持刷新令牌
https://www.baidu.com/#access_token=ey......u0Q&token_type=bearer&expires_in=86399&cre=1622695736&jti=13a726b2-70d4-421e-8d5b-3a26233214cc
```



### ③密码模式

直接向第三方应用提供资源服务器的账号密码，第三方应用通过账号密码请求获取资源服务器上的资源。会向第三方应用暴露账号密码，除非特别信任该应用。

![](Oauth2（上）.assetsd10b1466a464375926f47f1da54d2d8.png)




**看下测试实例**

```json
# 指定授权方式为password，携带客户端id密码、用户账号密码等信息访问。
GET https://oauth.marssenger.com/oauth/token?client_id=c1&client_secret=123456&grant_type=password&username=admin&password=abc123&user_type=admin
# 获取令牌
{
    "access_token": "ey......_SA",
    "token_type": "bearer",
    "refresh_token": "ey......brw",
    "expires_in": 86399,
    "scope": "ROLE_ADMIN ROLE_APPLICATION",
    "cre": 1622691146,
    "jti": "c31a69bc-0eba-4e93-8f78-c0f8c04a2b11"
}
```



### ④客户端模式

不通过资源所有者，直接以第三方应用的秘钥和id获取资源服务器的token。

![](Oauth2（上）.assets