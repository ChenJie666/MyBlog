---
title: Oauth2源码分析(上)
categories:
- Oauth2
---
# 前言

**拦截器顺序：**

```
    FilterComparator() {
        int order = 100;
        put(ChannelProcessingFilter.class, ord![21580557-a1b4bb0cec787209.png](https://upload-images.jianshu.io/upload_images/21580557-064e10f042fb0e86.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
er);
        order += STEP;
        put(ConcurrentSessionFilter.class, order);
        order += STEP;
        put(WebAsyncManagerIntegrationFilter.class, order);
        order += STEP;
        put(SecurityContextPersistenceFilter.class, order);
        order += STEP;
        put(HeaderWriterFilter.class, order);
        order += STEP;
        put(CorsFilter.class, order);
        order += STEP;
        put(CsrfFilter.class, order);
        order += STEP;
        put(LogoutFilter.class, order);
        order += STEP;
        filterToOrder.put(
            "org.springframework.security.oauth2.client.web.OAuth2AuthorizationRequestRedirectFilter",
            order);
        order += STEP;
        put(X509AuthenticationFilter.class, order);
        order += STEP;
        put(AbstractPreAuthenticatedProcessingFilter.class, order);
        order += STEP;
        filterToOrder.put("org.springframework.security.cas.web.CasAuthenticationFilter",
                order);
        order += STEP;
        filterToOrder.put(
            "org.springframework.security.oauth2.client.web.OAuth2LoginAuthenticationFilter",
            order);
        order += STEP;
        put(UsernamePasswordAuthenticationFilter.class, order);
        order += STEP;
        put(ConcurrentSessionFilter.class, order);
        order += STEP;
        filterToOrder.put(
                "org.springframework.security.openid.OpenIDAuthenticationFilter", order);
        order += STEP;
        put(DefaultLoginPageGeneratingFilter.class, order);
        order += STEP;
        put(ConcurrentSessionFilter.class, order);
        order += STEP;
        put(DigestAuthenticationFilter.class, order);
        order += STEP;
        put(BasicAuthenticationFilter.class, order);
        order += STEP;
        put(RequestCacheAwareFilter.class, order);
        order += STEP;
        put(SecurityContextHolderAwareRequestFilter.class, order);
        order += STEP;
        put(JaasApiIntegrationFilter.class, order);
        order += STEP;
        put(RememberMeAuthenticationFilter.class, order);
        order += STEP;
        put(AnonymousAuthenticationFilter.class, order);
        order += STEP;
        put(SessionManagementFilter.class, order);
        order += STEP;
        put(ExceptionTranslationFilter.class, order);
        order += STEP;
        put(FilterSecurityInterceptor.class, order);
        order += STEP;
        put(SwitchUserFilter.class, order);
    }
```

> 认证流程：Filter->构造Token->AuthenticationManager->转给Provider处理->认证处理成功后续操作或者不通过抛异常



**Security中的关键类：**

- ①UsernamePasswordAuthenticationFilter：如果是账号密码认证，从请求参数中获取账号密码，封装成为未认证过的UsernamePasswordAuthenticationToken对象，调用attemptAuthentication方法进行认证，在attemptAuthentication方法中会调用AuthenticationManager的authenticate方法对未认证的Authenticate对象token进行认证；
- ②UsernamePasswordAuthenticationToken：Authentication的子类，是验证方式的一种，有待验证和已验证两个构造方法。调用authenticate方法对其进行验证。principal参数的类型一般为UserDetails、String、AuthenticatedPrincipal、Principal；
- ③ProviderManager：在AuthenticationProvider的authenticate方法中会遍历AuthenticationProvider接口实现类的集合，遍历时会调用AuthenticationProvider实现类AbstractUserDetailsAuthenticationProvider的support方法判断需要验证的Authentication对象是否符合AuthenticationProvider的类型。直到support方法判断为true；
- ④AbstractUserDetailsAuthenticationProvider(AuthenticationProvider的实现类)：support方法为true，匹配上合适的AuthenticationProvider实现类后(UsernamePasswordAuthenticationToken匹配的是AbstractUserDetailsAuthenticationProvider抽象类)，调用AuthenticationProvider的authenticate方法进行验证(所以真正进行验证的是AuthenticationProvider实现类的authenticate方法)；
- ⑤DaoAuthenticationProvider(AuthenticationProvider和AbstractUserDetailsAuthenticationProvider的子类)：在authenticate方法中对Authentication对象token进行认证，取出对象中的username，在retrieveUser方法中调用UserDetailsService对象的loadUserByUsername(username)方法得到UserDetails对象，如果UserDetails对象不是null，则认证通过；最后调用继承自父类AbstractUserDetailsAuthenticationProvider的createSuccessAuthentication的方法，构建已认证的UsernamePasswordAuthenticationToken对象并返回。

> 构建已认证的UsernamePasswordAuthenticationToken对象并设置到上下文中SecurityContextHolder.getContext().setAuthentication(authenticationToken); 表示该请求已认证完成，后续安全拦截器放行。
> 构建已认证的UsernamePasswordAuthenticationToken的第三个参数是该用户所拥有的权限，后续的鉴权拦截器会根据传入的权限信息对请求进行鉴权。

![21580557-a1b4bb0cec787209.png](Oauth2源码分析(上).assets\d38a7162f16b4817934649f281da38d9.png)

**继承关系图**
![AuthenticationManager](Oauth2源码分析(上).assets\18942209ed9c468c9f83b446c53bceed.png)

![21580557-069e9c62f9d5f45b.png](Oauth2源码分析(上).assets5c6a049c0cd4456b91d8e549d7406c9.png)




<br>
# 一、授权码模式源码

## 1.1 概述

**流程图：**

![1622700752041.png](Oauth2源码分析(上).assets