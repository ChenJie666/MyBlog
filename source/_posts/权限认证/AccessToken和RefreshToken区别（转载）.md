---
title: AccessToken和RefreshToken区别（转载）
categories:
- 权限认证
---
项目背景：项目中使用SpringBoot集成OAuth2.0，实现对token的管理，此处包含两种token类型，refresh token和access token，两者都具有有效期，在OAuth的设计模式中往往refresh token的有效期都比较长（一般设置7天），而access token的有效期相对较短（一般为数个小时）。所以在具体的实施过程中，当access token过期而refresh token有效的时候，使用后者重新获取新的access token。

问题描述：最近在使用UAA开源项目时，发现每次使用refresh token刷新access token的时候，不光access token更新了，refresh token 同样也更新了，深究了UAA和OAuth的源码发现出现这种现象的原因由以下两点。

1. 在UAA开源项目中，refresh token有两者使用模式：重复使用和非重复使用。
所谓重复使用指的是登陆后初次生成的refresh token一直保持不变，直到过期；
非重复使用指的是在每一次使用refresh token刷新access token的过程中，refresh token也随之更新，即生成新的refresh token。

2. 在UAA项目中这一设置是通过UaaConfiguration类reuseRefreshTokens(boolean b)(默认为true)来设置完成；
下面是代码重现的结果分析：

3. 首先分析refresh token重复使用的情况，即在UaaConfiguration设置如下：

包名：com.yourcompany.uaa.config，类名：UaaConfiguration类
```java
@Override
public void configure(AuthorizationServerEndpointsConfigurer endpoints) throws Exception {
    Collection<TokenEnhancer> tokenEnhancers = applicationContext.getBeansOfType(TokenEnhancer.class).values();
    TokenEnhancerChain tokenEnhancerChain = new TokenEnhancerChain();
    tokenEnhancerChain.setTokenEnhancers(new ArrayList<>(tokenEnhancers));
    endpoints
        .authenticationManager(authenticationManager)
        .tokenStore(tokenStore())
        .tokenEnhancer(tokenEnhancerChain)
         //该字段设置设置refresh token是否重复使用,true:reuse;false:no reuse.
        .reuseRefreshTokens(true);            
    }
```

用户登陆获取：同时获取access token 和 refresh token
**access token:**
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX25hbWUiOiJhZG1pbiIsInNjb3BlIjpbIm9wZW5pZCJdLCJleHAiOjE1MzkwMDEwNTksImlhdCI6MTUzOTAwMDk2OSwiYXV0aG9yaXRpZXMiOlsiUk9MRV9BRE1JTiIsIlJPTEVfVVNFUiJdLCJqdGkiOiI2YTY3YTQzNC0xNTk2LTQ3YTYtYTNmNS0zZmNjZTljOTJkMjQiLCJjbGllbnRfaWQiOiJ3ZWJfYXBwIn0.ZRSqW7aq3Zph04IuBKGlpyLBeMMf_vZZn8Ac50mJeUZpeWLYr_Mz3cXd0Zlp2DHMRZcpheZQhuqWCa4AaWkTOPuIaeVH-Gpooh_lwO3LPA93sqb4jwdBUoD0A62C4roo71Sz50Fc2WNo0h9t_XSO2L-tS6zFWoxLhqYkVhR_HpGTW_6h0VWixgik8W0lsU4h3oYLfI8G1cdAELtBHYB5n9YllDhEp4_ZXp1npr9UIsYKyJxXOAFBp_j1SBtoqu7fikA2zkIdVh54-EQRZozaII-LZwRpt5sLyCgSrs8eMMdW6ow_TSMyYWCovl5eaRZEv6-VW9XFH7QtORk1W-VjSw
```json
{
  "user_name": "admin",
  "scope": [
    "openid"
  ],
  "exp": 1539001059,
  "iat": 1539000969,
  "authorities": [
    "ROLE_ADMIN",
    "ROLE_USER"
  ],
  "jti": "6a67a434-1596-47a6-a3f5-3fcce9c92d24",
  "client_id": "web_app"
}
```

**refresh token:**
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX25hbWUiOiJhZG1pbiIsInNjb3BlIjpbIm9wZW5pZCJdLCJhdGkiOiI2YTY3YTQzNC0xNTk2LTQ3YTYtYTNmNS0zZmNjZTljOTJkMjQiLCJleHAiOjE1MzkwMDQ1NjksImlhdCI6MTUzOTAwMDk2OSwiYXV0aG9yaXRpZXMiOlsiUk9MRV9BRE1JTiIsIlJPTEVfVVNFUiJdLCJqdGkiOiIxOTNhN2MyZC00Y2YxLTRhZjctODExOS0xZTljOWY5MTZiNmQiLCJjbGllbnRfaWQiOiJ3ZWJfYXBwIn0.XQsgqTkXqrS1X3u21tQqaHIvDZINcAtZ475kYSNikF7mFj8F91pyt9M6YRh9D_l0xmGqRPHldlwfMrxdQhSEir8WdrtfSOar9QpT4fZv9tyn9xPdKG5uq0jrtz2xq5ws17ZL-9PCFZJJnLQ6tLBXJ-hQnGEhA0Jq1JtCfpRIQ3VJM5561iN07yerjcIDfNLKQAGLd7I6Ilw_qRHDGeP0iZg5S-KPL-MApNwDfsxnHinRxeKUC2o2x0pJ8bhFKJQLIa-G4zKYrMhUc9bhzqMSERX3eJvsQldlr_6AoQgPokRTu0VHRa4Z7qOxTUC8hz2VDtxqOvzmQhrzeIyaSoLq1w
```json
{
  "user_name": "admin",
  "scope": [
    "openid"
  ],
  "exp": 1539001151,
  "iat": 1539001061,
  "authorities": [
    "ROLE_ADMIN",
    "ROLE_USER"
  ],
  "jti": "8d2d63ae-0ff0-499a-80a3-8e5a10410f83",
  "client_id": "web_app"
}
```

待access token过期之后，执行刷新操作，重新获取如下refresh token：
```json
{
  "user_name": "admin",
  "scope": [
    "openid"
  ],
  "ati": "8d2d63ae-0ff0-499a-80a3-8e5a10410f83",
  "exp": 1539004569,
  "iat": 1539001061,
  "authorities": [
    "ROLE_ADMIN",
    "ROLE_USER"
  ],
  "jti": "193a7c2d-4cf1-4af7-8119-1e9c9f916b6d",
  "client_id": "web_app"
}
```

<br>
***结果分析：***
通过对比refresh token刷新前后的明文信息可知，两个refresh token的jti（jwt-token-id，token的唯一属性）都为193a7c2d-4cf1-4af7-8119-1e9c9f916b6d，说明两个refresh token是同意个token，并为更新。心细的读者可能发现两个refresh token的加密字符串是不同的，其实这个原因是由于refresh token 中有个ati字段（access-token-id）信息，该字段是当前access token的唯一Id，由于access token更新了（由刷新前后access token的jti不同可证明），故而refresh token也相应作出改变，但是其过期时间等关键信息并未改变。这个也可以从下面的关键代码很明显的看出。
这种模式下的refresh token的过期仍然是以初次生成的时间为准。


<br>
### 2. 现在介绍refresh token 非重复利用的场景：
非重复使用： 即当access token 更新的时候，同时更新refresh token，这样就把refresh token的过期时间一直往后延续。该模式的用意就是通过更新refresh token实现永远不需要再次登陆的目的。除非前后两次对项目的操作时间间隔超出了refresh token的有效时间段。

下面看一下演示效果，同样设置UaaConfiguration：
```java
@Override
public void configure(AuthorizationServerEndpointsConfigurer endpoints) throws Exception {
    Collection<TokenEnhancer> tokenEnhancers = applicationContext.getBeansOfType(TokenEnhancer.class).values();
    TokenEnhancerChain tokenEnhancerChain = new TokenEnhancerChain();
    tokenEnhancerChain.setTokenEnhancers(new ArrayList<>(tokenEnhancers));
    endpoints
        .authenticationManager(authenticationManager)
        .tokenStore(tokenStore())
        .tokenEnhancer(tokenEnhancerChain)
         //该字段设置设置refresh token是否重复使用,true:reuse;false:no reuse.
        .reuseRefreshTokens(false);            
}
```

**access token：**
```json
{
  "user_name": "admin",
  "scope": [
    "openid"
  ],
  "exp": 1539001334,
  "iat": 1539001244,
  "authorities": [
    "ROLE_ADMIN",
    "ROLE_USER"
  ],
  "jti": "773967ae-580d-4352-b459-ccb95d2ed20d",
  "client_id": "web_app"
}
```

**refresh token**
```json
{
  "user_name": "admin",
  "scope": [
    "openid"
  ],
  "ati": "773967ae-580d-4352-b459-ccb95d2ed20d",
  "exp": 1539004844,
  "iat": 1539001244,
  "authorities": [
    "ROLE_ADMIN",
    "ROLE_USER"
  ],
  "jti": "326b1da5-1c78-4954-a5f4-e03e17f999f3",
  "client_id": "web_app"
}
```
待access token过期之后，执行刷新操作，重新获取 refresh token：
```json
{
  "user_name": "admin",
  "scope": [
    "openid"
  ],
  "ati": "ea2addcd-c7ee-441e-a7b6-9e4657502cde",
  "exp": 1539004946,
  "iat": 1539001346,
  "authorities": [
    "ROLE_ADMIN",
    "ROLE_USER"
  ],
  "jti": "a753e625-475f-447d-bea0-15b1fbf1299d",
  "client_id": "web_app"
}
```

结果分析：通过刷新前后refresh token的jti不一致不难看出，refresh token也已随着access token发生了更新。已经变成了两个不同的refresh token了，同时refresh token的过期时间也在一直往后延续，不在是初次生成refresh token时的过期时间了。
所以，在这种模式下，只要在refresh token有效期内执行操作，用户无需再次登陆。


从源码可以分析，在refreshAccessToken()方法中，代码在询问refresh token是否需要重新生成；
在enhance()方法中，代码在给refresh token添加access token关联信息ati，让后再次加密。
