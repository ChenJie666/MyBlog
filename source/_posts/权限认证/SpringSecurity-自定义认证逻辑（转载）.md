---
title: SpringSecurity-自定义认证逻辑（转载）
categories:
- 权限认证
---
###1.认证流程简析
AuthenticationProvider 定义了 Spring Security 中的验证逻辑，我们来看下 AuthenticationProvider 的定义：
```java
public interface AuthenticationProvider {
 Authentication authenticate(Authentication authentication)
   throws AuthenticationException;
 boolean supports(Class<?> authentication);
}
```
可以看到，AuthenticationProvider 中就两个方法：

authenticate 方法用来做验证，就是验证用户身份。
supports 则用来判断当前的 AuthenticationProvider 是否支持对应的 Authentication。
这里又涉及到一个东西，就是 Authentication。

在 Spring Security 中有一个非常重要的对象叫做 Authentication，我们可以在任何地方注入 Authentication 进而获取到当前登录用户信息，Authentication 本身是一个接口，它实际上对 java.security.Principal 做的进一步封装，我们来看下 Authentication 的定义：
```java
public interface Authentication extends Principal, Serializable {
 Collection<? extends GrantedAuthority> getAuthorities();
 Object getCredentials();
 Object getDetails();
 Object getPrincipal();
 boolean isAuthenticated();
 void setAuthenticated(boolean isAuthenticated) throws IllegalArgumentException;
}
```

1.getAuthorities 方法用来获取用户的权限。
2.getCredentials 方法用来获取用户凭证，一般来说就是密码。
3.getDetails 方法用来获取用户携带的详细信息，可能是当前请求之类的东西。
4.getPrincipal 方法用来获取当前用户，可能是一个用户名，也可能是一个用户对象。
5.isAuthenticated 当前用户是否认证成功。

Authentication 作为一个接口，它定义了用户，或者说 Principal 的一些基本行为，它有很多实现类：

在这些实现类中，我们最常用的就是 UsernamePasswordAuthenticationToken 了，而每一个 Authentication 都有适合它的 AuthenticationProvider 去处理校验。例如处理 UsernamePasswordAuthenticationToken 的 AuthenticationProvider 是 DaoAuthenticationProvider。

所以大家在 AuthenticationProvider 中看到一个 supports 方法，就是用来判断 AuthenticationProvider 是否支持当前 Authentication。

###2.自定义认证思路
了解了认真流程，我们可以自定义一个 AuthenticationProvider 代替 DaoAuthenticationProvider，并重写它里边的 additionalAuthenticationChecks 方法，下面在重写的过程中，我们来加入验证码的校验逻辑。

首先我们需要验证码，网上一个现成的验证码库 kaptcha，首先我们添加该库的依赖，如下：
```
<dependency>
    <groupId>com.github.penggle</groupId>
    <artifactId>kaptcha</artifactId>
    <version>2.3.2</version>
</dependency>
```

然后我们提供一个实体类用来描述验证码的基本信息：
```java
@Bean
Producer verifyCode() {
    Properties properties = new Properties();
    properties.setProperty("kaptcha.image.width", "150");
    properties.setProperty("kaptcha.image.height", "50");
    properties.setProperty("kaptcha.textproducer.char.string", "0123456789");
    properties.setProperty("kaptcha.textproducer.char.length", "4");
    Config config = new Config(properties);
    DefaultKaptcha defaultKaptcha = new DefaultKaptcha();
    defaultKaptcha.setConfig(config);
    return defaultKaptcha;
}
```
这段配置很简单，我们就是提供了验证码图片的宽高、字符库以及生成的验证码字符长度。
接下来提供一个返回验证码图片的接口：
```java
@RestController
public class VerifyCodeController {
    @Autowired
    Producer producer;
    @GetMapping("/vc.jpg")
    public void getVerifyCode(HttpServletResponse resp, HttpSession session) throws IOException {
        resp.setContentType("image/jpeg");
        String text = producer.createText();
        session.setAttribute("verify_code", text);
        BufferedImage image = producer.createImage(text);
        try(ServletOutputStream out = resp.getOutputStream()) {
            ImageIO.write(image, "jpg", out);
        }
    }
}
```
这里我们生成验证码图片，并将生成的验证码字符存入 HttpSession 中。注意这里我用到了 try-with-resources ，可以自动关闭流

接下来我们来自定义一个 MyAuthenticationProvider 继承自 DaoAuthenticationProvider，并重写 additionalAuthenticationChecks 方法：
```java
public class MyAuthenticationProvider extends DaoAuthenticationProvider {

    @Override
    protected void additionalAuthenticationChecks(UserDetails userDetails, UsernamePasswordAuthenticationToken authentication) throws AuthenticationException {
        HttpServletRequest req = ((ServletRequestAttributes) RequestContextHolder.getRequestAttributes()).getRequest();
        String code = req.getParameter("code");
        String verify_code = (String) req.getSession().getAttribute("verify_code");
        if (code == null || verify_code == null || !code.equals(verify_code)) {
            throw new AuthenticationServiceException("验证码错误");
        }
        super.additionalAuthenticationChecks(userDetails, authentication);
    }
}
```
1.首先获取当前请求，注意这种获取方式，在基于 Spring 的 web 项目中，我们可以随时随地获取到当前请求，获取方式就是我上面给出的代码。
2.从当前请求中拿到 code 参数，也就是用户传来的验证码。
3.从 session 中获取生成的验证码字符串。
4.两者进行比较，如果验证码输入错误，则直接抛出异常。
5.最后通过 super 调用父类方法，也就是 DaoAuthenticationProvider 的 additionalAuthenticationChecks 方法，该方法中主要做密码的校验。

MyAuthenticationProvider 定义好之后，接下来主要是如何让 MyAuthenticationProvider 代替 DaoAuthenticationProvider。

所有的 AuthenticationProvider 都是放在 ProviderManager 中统一管理的，所以接下来我们就要自己提供 ProviderManager，然后注入自定义的 MyAuthenticationProvider，这一切操作都在 SecurityConfig 中完成。

###3.测试
启动项目，我们开始测试
首先可以给一个错误的验证码，如下：

![image.png](SpringSecurity-自定义认证逻辑（转载）.assets\7dff03302aae471e85bc68384af8a7d8.png)
接下来，请求 /vc.jpg 获取验证码：

![image.png](SpringSecurity-自定义认证逻辑（转载）.assetsabf6128d5a54a82943aa867e6bd74f7.png)
最后，所有的都输入正确，再来看下：

![image.png](SpringSecurity-自定义认证逻辑（转载）.assets\1296cd96a24540dc9eea7c5ec1f3f296.png)
