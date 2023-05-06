---
title: Security
categories:
- 权限认证
---
![过滤器链](Security.assets\266a11f9453141889e5d5d519fa5cc3a.png)

**流程图如下：**
![1622701717884.png](Security.assets\2406f262a4b8452aa60b572c0ab7a13a.png)

WebSecurityConfigurerAdapter 的三个重载方法的参数
- HttpSecurity ：认证方式和资源权限设置（包括csrf、cors、自动登录RemeberMe、登出、设置token认证过滤器、设置session、资源访问权限、）；
- AuthenticationManagerBuilder ：设置角色和权限信息（账号密码及其角色权限存储到内存，或将角色信息存储在数据库中,从数据库中动态加载用户账号密码及其权限），设置UserDetailsService和BCryptPasswordEncoder；
- WebSecurity ：设置不需要鉴权静态资源访问路径。

基本原理：
通过SecurityContextHolder.getContext().setAuthentication(authenticationToken)将token设置到上下文中，
在UsernamePasswordAuthenticationFilter过滤器中会通过AuthenticationManager的authenticate方法对Security上下文中的token进行校验（实现UserDetailsService和UserDetails）。

###HttpBasic认证方式
```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {
   
   @Override
   protected void configure(HttpSecurity http) throws Exception {
      http.httpBasic()//开启httpbasic认证
      .and()
      .authorizeRequests()
      .anyRequest()
      .authenticated();//所有请求都需要登录认证才能访问
   }

}
```
访问服务器中的资源需要进行认证，默认用户名为user，密码为启动服务器时产生的密码。

当然我们也可以通过application.yml指定配置用户名密码:
```xml
spring:
    security:
      user:
        name: admin
        password: admin
```

***原理***
![image](Security.assets\3fc18f9ee5514dd39c1459d60e78d05a.png)
*   首先，HttpBasic模式要求传输的用户名密码使用Base64模式进行加密。如果用户名是 `"admin"`  ，密码是“ admin”，则将字符串`"admin:admin"`使用Base64编码算法加密。加密结果可能是：YWtaW46YWRtaW4=。
*   然后，在Http请求中使用Authorization作为一个Header，“Basic YWtaW46YWRtaW4=“作为Header的值，发送给服务端。（注意这里使用Basic+空格+加密串）
*   服务器在收到这样的请求时，到达BasicAuthenticationFilter过滤器，将提取“ Authorization”的Header值，并使用用于验证用户身份的相同算法Base64进行解码。
*   解码结果与登录验证的用户名密码匹配，匹配成功则可以继续过滤器后续的访问。


###formLogin认证模式
Spring Security支持我们自己定制登录页面，即formLogin模式登录认证模式。
***依赖***
<dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
</dependency>

***代码***
![认证方式](Security.assetsff61f1b0c014a3186d0eba30df547a6.png)

```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    /**
     * 采用formLogin方式进行认证
     *
     * @param http
     * @throws Exception
     */
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf().disable() //禁用csrf攻击防御
                //1.formLogin配置段
                .formLogin()
                .loginPage("/login.html")//用户访问资源时先跳转到该登录页面
                .loginProcessingUrl("/login")//登录表单中的action的地址，在该接口中进行认证
                .usernameParameter("username")//登录表单form中的用户名输入框input的name名，缺省是username
                .passwordParameter("password")//登录表单form中的密码输入框input的name名，缺省是password
                .defaultSuccessUrl("/index")//登录成功后默认跳转的路径
                .failureUrl("/login.html") //登录失败后返回登录页
                .and()
                //2.authorizeRequests配置端
                .authorizeRequests()
                .antMatchers("/login.html","/login").permitAll() //不需要验证即可访问
                .antMatchers("/biz1","/biz2").hasAnyAuthority("ROLE_user","ROLE_admin")//user和admin权限可以访问的路径，等同于hasAnyRole("user","admin")
//                .antMatchers("/syslog","/sysuser").hasAnyRole("admin")//admin角色可以访问的路径
                .antMatchers("/syslog").hasAuthority("sys:log")//权限id，有该id的用户可以访问
                .antMatchers("/sysuser").hasAuthority("sys:user")
                .anyRequest().authenticated();
    }

    /**
     * 将角色信息存储在内存中
     * @param auth
     * @throws Exception
     */
    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        auth.inMemoryAuthentication()
                .withUser("user")
                .password(bCryptPasswordEncoder().encode("abc123"))
                .roles("user")
                .and()
                .withUser("admin")
                .password(bCryptPasswordEncoder().encode("abc123"))
//                .authorities("sys:log","sys:user")
                .roles("admin")
                .and()
                .passwordEncoder(bCryptPasswordEncoder());//配置BCrypt加密
    }

    @Bean
    public BCryptPasswordEncoder bCryptPasswordEncoder(){
        return new BCryptPasswordEncoder();
    }

    /**
     * 静态资源访问不需要鉴权
     * @param web
     * @throws Exception
     */
    @Override
    public void configure(WebSecurity web) throws Exception {
        web.ignoring().antMatchers("/css/**", "/fonts/**", "img/**", "js/**");
    }
}
```

#####自定义的登陆处理逻辑
***登陆成功后的处理逻辑***
```java
@Component
public class MyAuthenticationSuccessHandler extends SavedRequestAwareAuthenticationSuccessHandler {

    @Value("${spring.security.loginType}")
    private String loginType;

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response, Authentication authentication) throws ServletException, IOException {
        if ("JSON".equalsIgnoreCase(loginType)) {
            //登录成功后返回登录成功信息
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(new ObjectMapper().writeValueAsString(CommonResult.success().setData("/index.html")));
        } else {
            //登录成功后跳转到拦截发生时访问的路径
            super.onAuthenticationSuccess(request,response,authentication);
        }
    }

}
```
将.defaultSuccessUrl()方法替换为successHandler()方法。


***登陆失败后的处理逻辑***
```java
@Component
public class MyAuthenticationFailureHandler extends SimpleUrlAuthenticationFailureHandler {

    @Value("${spring.security.loginType}")
    private String loginType;

    @Override
    public void onAuthenticationFailure(HttpServletRequest request, HttpServletResponse response, AuthenticationException exception) throws IOException, ServletException {
        if ("JSON".equalsIgnoreCase(loginType)) {
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(new ObjectMapper().writeValueAsString(CommonResult.error().setMessage("用户名或密码错误")));
        } else {
            super.onAuthenticationFailure(request,response,exception);
        }
    }

}
```
将failureUrl()方法替换为failureHandler()方法。


#####自定义登陆页面和跳转
```java
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <title>首页</title>
</head>
<body>
    <h1>业务系统登录</h1>
    <form action="/login" method="post">
        <span>用户</span><input type="text" name="username" id="username"/> <br>
        <span>密码</span><input type="password" name="password" id="password"/> <br>
        <input type="button" onclick="login()" value="登录">
    </form>

    <script src="https://cdn.staticfile.org/jquery/1.12.3/jquery.min.js"></script>
    <script>
        function login(){
            var username = $("#username").val();
            var password = $("#password").val();
            // var username = document.getElementById("username").valueOf();
            // var password = document.getElementById("password").valueOf();
            if (username === "" || password === "") {
                alert("用户名或密码不能为空");
                return;
            }
            $.ajax({
                type: "POST",
                url: "/login",
                data: {
                    "username": username,
                    "password": password
                },
                success: function(json){
                    if (json.code === 200) {
                        location.href = json.data;
                    }else{
                        alert(json.message);
                    }
                },
                error: function(error){
                    console.log(e.responseText)
                }
            })
        }
    </script>

</body>
</html>
```
***逻辑***
- 如果登陆密码错误，则弹框提示用户名密码错误
- 如果登录成功，则跳转到index.html


###Spring Security与session的创建使用
***四种模式***
- always：如果当前请求没有session存在，Spring Security创建一个session。
- never：不主动创建session，如果session存在，会使用该session。
- ifRequired(默认)：在需要时才创建session
- stateless：不会创建或使用任何session。适用于接口型的无状态应用，该方式节省资源。


***会话超时配置***
- server.servlet.session.timeout=15m
- spring.session.timeout=15m
```xml
#springboot限制session最少过期时间为1min，所以此时session过期时间为1min
server:
  servlet:
    session
      timeout: 10s
```


***session保护***
- 默认情况下，Security启用了migrationSession保护方式，对同一个cookies的session用户，每次登录都会创建一个新的http会话，就http会话失效且属性会复制到新会话中。
- 设置为none，原始会话不会失效
- 设置为newSession，将创建一个干净的会话，不复制旧会话中的任何属性。

***cookie保护***
session存储在cookie中，通过如下配置保证cookie的安全。
```xml
server:
  servlet:
    session:
      cookie:
        http-only: true #浏览器脚本无法访问cookie
        secure: true #仅通过https连接发送cookie，http无法携带cookie
```

***限制最大登录用户数量***
同一账号允许同时登陆的最大数量
```java
http.sessionManagement()
        .maximumSessions(1) //最大登录数为1
        .maxSessionsPreventsLogin(false) //false表示允许再次登录但会踢出之前的登陆；true表示不允许再次登录
        .expiredSessionStrategy(new MyExpiredSessionStrategy());//会话过期后进行的自定义操作
```

自定义会话超时处理
```java
@Component
public class MyExpiredSessionStrategy implements SessionInformationExpiredStrategy {

    /**
     * session超时后该方法会被回调
     * @param event
     * @throws IOException
     * @throws ServletException
     */
    @Override
    public void onExpiredSessionDetected(SessionInformationExpiredEvent event) throws IOException, ServletException {
        CommonResult commonResult = CommonResult.error().setMessage("其他设别登录，当前设备已下线");
        event.getResponse().setContentType("application/json;charset=UTF-8");
        event.getResponse().getWriter().write(new ObjectMapper().writeValueAsString(commonResult));
    }
}
```



***总结代码配置***
配置session模式和过期跳转路径：
```java
 http.sessionManagement()
        .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED) //设置session创建模式
        .invalidSessionUrl("/login.html") //sessin失效后跳转路径
        .sessionFixation().migrateSession() //重新登录后创建新session并复制属性
        .maximumSessions(1) //最大登录数为1
        .maxSessionsPreventsLogin(false)//false表示允许再次登录但会踢出之前的登陆；true表示不允许再次登录
        .expiredSessionStrategy(new MyExpiredSessionStrategy());//会话过期后进行的自定义操作
```

完整SecurityConfig类代码
```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    /**
     * 采用httpbasic方式进行认证
     * @param http
     * @throws Exception
     */
//    @Override
//    protected void configure(HttpSecurity http) throws Exception {
//        http.httpBasic()//开启httpbasic认证
//        .and()
//                .authorizeRequests()
//                .anyRequest()
//                .authenticated();//所有请求都需要登录认证
//    }

    @Resource
    private MyAuthenticationSuccessHandler mySuthenticationSuccessHandler;

    @Resource
    private MyAuthenticationFailureHandler myAuthenticationFailureHandler;

    @Resource
    private CaptchaCodeFilter captchaCodeFilter;

    /**
     * 采用formLogin方式进行认证
     *
     * @param http
     * @throws Exception
     */
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
                //设置过滤器
                .addFilterBefore(captchaCodeFilter,UsernamePasswordAuthenticationFilter.class) //将验证码过滤器放到账号密码前面执行
                //退出登录
                .logout()
                .logoutUrl("/logout") //退出登录的请求接口
                .logoutSuccessUrl("/login.html") //退出登录后跳转的路径
                .deleteCookies("JSESSIONID") //退出时删除浏览器中的cookie
                .and()
                //禁用csrf攻击防御
                .csrf().disable()
                //1.formLogin配置段
                .formLogin()
                .loginPage("/login.html")//用户访问资源时先跳转到该登录页面
                .loginProcessingUrl("/login")//登录表单中的action的地址，在该接口中进行认证
                .usernameParameter("username")//登录表单form中的用户名输入框input的name名，缺省是username
                .passwordParameter("password")//登录表单form中的密码输入框input的name名，缺省是username
//                .defaultSuccessUrl("/index")//登录成功后默认跳转的路径
                .successHandler(mySuthenticationSuccessHandler)//使用自定义的成功后的逻辑
//                .failureUrl("/login.html") //登录失败后返回登录页
                .failureHandler(myAuthenticationFailureHandler) //使用自定义的失败后的逻辑
                .and()
                //2.authorizeRequests配置端
                .authorizeRequests()
                .antMatchers("/login.html", "/login","/kaptcha").permitAll() //不需要验证即可访问
                .antMatchers("/biz1", "/biz2").hasAnyAuthority("ROLE_user", "ROLE_admin")//user和admin权限可以访问的路径，等同于hasAnyRole("user","admin")
//                .antMatchers("/syslog","/sysuser").hasAnyRole("admin")//admin角色可以访问的路径
                .antMatchers("/syslog").hasAuthority("sys:log")//权限id，有该id的用户可以访问
                .antMatchers("/sysuser").hasAuthority("sys:user")
                .anyRequest().authenticated()
                .and()
                .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED)
                .invalidSessionUrl("/login.html")
                .sessionFixation().migrateSession()
                .maximumSessions(1) //最大登录数为1
                .maxSessionsPreventsLogin(false)//false表示允许再次登录但会踢出之前的登陆；true表示不允许再次登录
                .expiredSessionStrategy(new MyExpiredSessionStrategy());//会话过期后进行的自定义操作
    }

    /**
     * 将角色信息存储在内存中
     * @param auth
     * @throws Exception
     */
    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        auth.inMemoryAuthentication()
                .withUser("user")
                .password(bCryptPasswordEncoder().encode("abc123"))
                .roles("user")
                .and()
                .withUser("admin")
                .password(bCryptPasswordEncoder().encode("abc123"))
//                .authorities("sys:log","sys:user")
                .roles("admin")
                .and()
                .passwordEncoder(bCryptPasswordEncoder());//配置BCrypt加密
    }

    @Bean
    public BCryptPasswordEncoder bCryptPasswordEncoder(){
        return new BCryptPasswordEncoder();
    }

    /**
     * 静态资源访问不需要鉴权
     * @param web
     * @throws Exception
     */
    @Override
    public void configure(WebSecurity web) throws Exception {
        web.ignoring().antMatchers("/css/**", "/fonts/**", "img/**", "js/**");
    }

}
```



###方法级别过滤的注解
**四个方法级别的过滤注解：**
@EnableGlobalMethodSecurity(prePostEnabled
 = true)使用表达式时间方法级别的安全性 4个注解可用（hasRole hasAnyRole hasAuthority hasAnyAuthority）。
- @PreAuthorize
例：@PreAuthorize("hasRole('admin')") 在方法执行前进行判断，如果当前用户不是admin角色，则拒绝访问，抛出异常。
- @PreFilter
例：@PreFilter(filterTarget="ids",value="filterObject%2==0") 在方法执行前对参数数组ids进行过滤，对数组中的值filterObject进行判断，不满足条件的参数剔除。
- @PostAuthorize
例：@PostAuthorize("returnObject.name == authentication.name")  在方法执行后进行判断，如果不满足条件，则拒绝访问，抛出异常。
- @PostFilter
例：@PostFilter("filterObject.name == authentication.name") 在方法执行之后对返回值数组进行过滤，将不满足条件的返回值剔除。


###记住密码RememberMe
通过创建并验证remember-me session，可以不输入账号密码进行登录。

#####memory模式实现记住密码
后台配置：http.rememberMe()
前端配置：<label><input type="checkbox" name="remember-me"/>记住密码</label>
如果前端采用的是ajax方式进行请求
```js
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <title>首页</title>
</head>
<body>
    <h1>业务系统登录</h1>
    <form action="/login" method="post">
        <span>用户</span><input type="text" name="username" id="username"/> <br>
        <span>密码</span><input type="password" name="password" id="password"/> <br>
        <input type="button" onclick="login()" value="登录">
        <label><input type="checkbox" name="remember-me" id="remember-me" />记住密码</label>
    </form>

    <script src="https://cdn.staticfile.org/jquery/1.12.3/jquery.min.js"></script>
    <script>
        function login(){
            var username = $("#username").val();
            var password = $("#password").val();
            var rememberMe = $("#remember-me").is(":checked");
            if (username === "" || password === "") {
                alert("用户名或密码不能为空");
                return;
            }
            $.ajax({
                type: "POST",
                url: "/login",
                data: {
                    "username": username,
                    "password": password,
                    "remember-me-new": rememberMe
                },
                success: function(json){
                    if (json.code === 200) {
                        location.href = json.data;
                    }else{
                        alert(json.message);
                    }
                },
                error: function(error){
                    console.log(e.responseText)
                }
            })
        }
    </script>

</body>
</html>
```
```java
http.rememberMe()
    .rememberMeParameter("remember-me-new") //前端传入的参数名需要对应
    .rememberMeCookieName("remember-me-cookie") //生成的cookie的名称
    .tokenValiditySeconds(60*60*24*2) //该session的有效期
```
*新增一个remember-me session*
![image.png](Security.assets\84b312b577cd4d6ab5655da41d9d2081.png)

***原理***
通过创建remember-me session，存储了remember-me token，令牌记录了用户名、过期时间和signatureValue。signatureValue是用户名、过期时间、密码和预定义key的MD5加密后的签名。

进行登录时，通过RememberMeAuthenticationFilter过滤器进行过滤。

#####数据库模式实现记住密码
![image.png](Security.assets\37fdc082bdab4f92a947df0ba8147cf1.png)

***依赖***
```
<dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>
<dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
</dependency>
```
***配置***
```yml
spring:
  datasource:
    url: jdbc:mysql://116.62.148.11:3306/xxx?useUnicode=true&characterEncoding=utf-8
    driver-class-name: com.mysql.jdbc.Driver
    username: root
    password: abc123
```

***数据库表创建***
```sql
CREATE TABLE persistent_logins (
    username varchar(64) NOT NULL,
    series varchar(64) NOT NULL,
    token varchar(64) NOT NULL,
    last_used timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (series)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```
***java代码***
```java
    http.rememberMe()
      .rememberMeParameter("remember-me-new") //前端传入的参数名需要对应
      .rememberMeCookieName("remember-me-cookie") //生成的cookie的名称
      .tokenValiditySeconds(60*60*24*2) //该session的有效期
      .tokenRepository(persistentTokenRepository()) //配置remember-me的token存储在指定的数据库中，缺省为存储在内存中。

    /**
     * 注入dataSource对象
     */
    @Resource
    private DataSource dataSource;

    /**
     * 将数据库连接封装到框架中
     *
     * @return
     */
    @Bean
    public PersistentTokenRepository persistentTokenRepository() {
        JdbcTokenRepositoryImpl tokenRepository = new JdbcTokenRepositoryImpl();
        tokenRepository.setDataSource(dataSource);

        return tokenRepository;
    }
```

![数据库存储的token](Security.assets