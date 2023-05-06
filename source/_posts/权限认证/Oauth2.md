---
title: Oauth2
categories:
- 权限认证
---



#####2.1 客户端配置
***配置客户端详细信息***
- clinetId：识别客户的Id
- secret：值得信赖的客户端安全码，非必须
- authorizedGrantTypes：客户端可以使用的授权类型，默认为空
- authorities：此客户端可以使用的权限（基于Spring Security authorities）
```java
    @Resource
    private BCryptPasswordEncoder bCryptPasswordEncoder;
    //密码编码器
    @Bean
    public BCryptPasswordEncoder bCryptPasswordEncoder(){
        return new BCryptPasswordEncoder();
    }

    /**
     * 客户端配置
     *
     * @param clients
     * @throws Exception
     */
    @Override
    public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
        clients.inMemory()//使用内存存储
                .withClient("c1") //客户端id
                .secret(bCryptPasswordEncoder.encode("abc123"))//设置密码
                .resourceIds("res1")//可访问的资源列表
                .authorizedGrantTypes("authorization_code", "password", "client_credentials", "implicit", "refresh_token")//该client允许的授权类型
                .scopes("all")//允许的授权范围，all只是一个标识，不是全部的意思
                .autoApprove(false)//false跳转到授权页面，true不跳转
                .redirectUris("http://www.baidu.com");//设置回调地址
    }
```

***授权码管理模式***
设置授权码模式的授权码如何存取，暂时采用内存方式
```java
    /**
     * 设置授权码模式的授权码如何存取，暂时采用内存方式
     *
     * @return
     */
    @Bean
    public AuthorizationCodeServices authorizationCodeServices(){
        return new InMemoryAuthorizationCodeServices();
    }
```

#####2.2 令牌管理服务和访问端点
***令牌管理***
- InMemoryTokenStore：默认使用内存管理令牌
- JdbcTokenStore：令牌存储到关系型数据库
- JwtTokenStore：不需要进行令牌存储，用户信息保存到Jwt令牌中，对Jwt令牌中的信息进行校验即可确定身份。
```java
    /**
     * 配置将令牌存储在内存中
     *
     * @return
     */
    @Bean
    public TokenStore tokenStore(){
        //使用内存存储令牌
        return new InMemoryTokenStore();
    }

    @Resource
    private TokenStore tokenStore;

    @Resource
    private ClientDetailsService clientDetailsService;

    /**
     * 设置令牌
     *
     * @return
     */
    @Bean
    public AuthorizationServerTokenServices tokenServices() {
        DefaultTokenServices services = new DefaultTokenServices();
        services.setClientDetailsService(clientDetailsService); //客户端详情服务
        services.setSupportRefreshToken(true); //支持刷新令牌
        services.setTokenStore(tokenStore); //令牌的存储策略
        services.setAccessTokenValiditySeconds(7200); //令牌默认有效时间2小时
        services.setRefreshTokenValiditySeconds(259200); //刷新令牌默认有效期3天
        return services;
    }
```

***令牌访问端点配置***
*配置授权类型*
- authenticationManager：认证管理器，使用资源所有者密码授权模式（password）时，设置这个属性注入一个AuthenticationManager对象。如果自定义UserDetails需要引入该类型。
- userDetailsService：需要自己实现UserDetailsService接口
- authorizationCodeServices：设置密码授权服务，主要用于authorization_code授权码类型模式。
- implicitGrantService：设置隐式授权模式，用来管理隐式授权模式状态。
- tokenGranter：当设置了该接口，授权将会完全交由你来掌握，并忽略以上的几个属性，这个属性在上述四个属性满足不了需求时才会使用。
```java
    //引入授权码管理配置
    @Autowired
    private AuthorizationCodeServices authorizationCodeServices;

    @Resource
    private AuthenticationManager authenticationManager;

    /**
     * 认证管理器
     *
     * @return
     * @throws Exception
     */
    @Bean
    public AuthenticationManager authenticationManager() throws Exception {
        return super.authenticationManager();
    }

    /**
     * 令牌访问端点配置
     *
     * @param endpoints
     * @throws Exception
     */
    @Override
    public void configure(AuthorizationServerEndpointsConfigurer endpoints) throws Exception {
        endpoints
                .authenticationManager(authenticationManager)//认证管理器，密码模式需要
                .authorizationCodeServices(authorizationCodeServices)//授权码服务
                .tokenServices(tokenServices()) //令牌管理服务
                .allowedTokenEndpointRequestMethods(HttpMethod.POST); //运行post提交
    }
```

#####2.3 配置授权端点*
/oauth/authorize：授权端点
/oauth/token：令牌端点
/oauth/confirm_access：用户确认授权提交端点
/oauth/error：授权服务错误信息端点
/oauth/check_token：用于资源服务访问的令牌解析端点
/oauth/token_key：提供公有秘钥的端点，如果使用的是JWT令牌的话。

刷新token的请求地址：POST  http://localhost:9200/uaa/oauth/token?grant_type=refresh_token&refresh_token=xxxxx&client_secret=123456

需要注意的是授权端点这个URL应该被Spring Security保护起来只供授权用户访问。
```java
    /**
     * 对授权端点接口的约束
     *
     * @param security
     * @throws Exception
     */
    @Override
    public void configure(AuthorizationServerSecurityConfigurer security) throws Exception {
        security
                .tokenKeyAccess("permitAll()") // /auth/token_key是公开的
                .checkTokenAccess("permitAll()") // /auth/check_token是公开的
                .allowFormAuthenticationForClients(); //允许表单认证（申请令牌）
    }
```

#####2.4 权限配置资源服务配置
```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    @Bean
    public BCryptPasswordEncoder bCryptPasswordEncoder(){
        return new BCryptPasswordEncoder();
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
                //跨域请求伪造防御失效
                .csrf().disable()
                .authorizeRequests()
                .antMatchers("/").permitAll()
                .antMatchers("/index.html").authenticated()
                .antMatchers("/res1").hasAnyAuthority("")
                .and()
                .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS);
    }

    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        super.configure(auth);
    }

    @Override
    public void configure(WebSecurity web) throws Exception {
        super.configure(web);
    }

}
```

<br>

###3 资源访问
#####3.1 授权码模式：
**请求授权码：**
资源拥有者打开客户端，客户端要求资源拥有者基于授权，它将浏览器重定向到授权服务器，重定向时会附加客户端的身份信息。
请求地址：GET 
 http://localhost:8080/oauth/authorize?client_id=c1&response_type=code&scope=all&redirect_uri=http://www.baidu.com
返回结果：https://www.baidu.com/?code=JNn4Hw
参数列表如下：
- client_id:客户端准入标识，在ClientDetailsServiceConfigurer中指定；
- response_type：授权码模式固定为code；
- scope：客户端权限；
- redirect_uri：跳转的uri，当授权申请成功后会跳转到此地址，并在后面带上code参数（授权码）。

**申请token令牌：**
客户端拿到授权码后向授权服务器索要访问access_token
请求地址：POST 
 http://localhost:8080/oauth/token?client_id=c1&client_secret=abc123&grant_type=authorization_code&code=JNn4Hw&redirect_uri=http://www.baidu.com
返回结果：
```json
{
    "access_token": "4dbef819-d7dd-48b4-b078-e5833efb1e02",
    "token_type": "bearer",
    "refresh_token": "adc93214-f7a8-4a83-8724-0d5ad46bf1e5",
    "expires_in": 7199,
    "scope": "all"
}
```
参数列表如下：
- client_id：客户端准入标识；
- client_secret：客户端秘钥，在ClientDetailsServiceConfigurer中指定；
- grant_type：授权类型，填写authorization_code，表示授权码模式；
- code：授权码，使用一次就会失效，需要重新申请；
- redirect_uri：申请授权码时跳转的url，一定和申请授权码时的重定向地址一致。


#####3.2 简化模式
**直接申请token令牌**
资源拥有者打开客户端，客户端要求资源拥有者给予授权，它将浏览器被重定向到授权服务器，重定向时会附加令牌信息。
请求地址：GET 
 http://localhost:8080/oauth/authorize?client_id=c1&response_type=token&scope=all&redirect_uri=http://www.baidu.com
返回结果：在授权页面填写账号密码并允许授权后跳转路径https://www.baidu.com/#access_token=4dbef819-d7dd-48b4-b078-e5833efb1e02&token_type=bearer&expires_in=6037
注：前端传参数会在#后带上参数。简化模式用于没有服务端的第三方单页面应用，因为没有服务端就无法接收授权码。

#####3.3 密码模式
客户端拿着资源拥有者的用户名和密码向授权服务器请求token令牌
请求地址：POST 
 http://localhost:8080/oauth/token?client_id=c1&client_secret=abc123&grant_type=password&username=admin&password=abc123
返回结果：
```json
{
    "access_token": "4dbef819-d7dd-48b4-b078-e5833efb1e02",
    "token_type": "bearer",
    "refresh_token": "adc93214-f7a8-4a83-8724-0d5ad46bf1e5",
    "expires_in": 5685,
    "scope": "all"
}
```
参数列表如下：
- client_id：客户端准入标识；
- client_secret：客户端秘钥，在ClientDetailsServiceConfigurer中指定；
- grant_type：授权类型，填写password，表示密码模式；
- username：资源拥有者用户名；
- password：资源拥有者密码。
注：密码模式不会用于第三方授权，一般用于我们自己开发的应用。

**注：**直接明文传输client_id和client_secret不安全，可以在postman中使用Basic Auth输入客户端id和客户端密码，最后会在请求header中添加key为Authorizatio，value为Basic 账号:密码(Base64编码)  的请求头。![image.png](Oauth2.assets\1b8e62f137914220b05f1f5026bc6dc6.png)

#####3.4 客户端模式
客户端向授权服务器发送自己的身份信息，并请求token令牌，确认客户端身份无误后，将令牌发送给client。
请求地址：POST  http://localhost:8080/oauth/token?client_id=c1&client_secret=abc123&grant_type=client_credentials
返回结果：
```json
{
    "access_token": "8b984f93-fd21-460c-bbb6-dbea3a86f980",
    "token_type": "bearer",
    "expires_in": 6641,
    "scope": "all"
}
```
参数列表如下：
- client_id：客户端准入标识；
- client_secret：客户端秘钥，在ClientDetailsServiceConfigurer中指定；
- grant_type：授权类型，填写client_credentials，表示客户端模式；
注：这种模式最方便但最不安全。因为不需要账号密码就可以返回token，需要对client绝对信任和client绝对安全。这种模式一般用来提供给我们完全信任的服务器端服务。比如内部系统，合作方系统对接，拉取一组用户信息。

<br>

###3 资源服务器配置
ResourceServerConfigurerAdapter类中的两个重载方法的参数
- ResourceServerSecurityConfigurer：去授权服务器验证传入的令牌是否有效。有效则将权限信息放到UserDetails中
- HttpSecurity：验证该token的Scope权限(在客户端中配置)和允许访问的路径。

**重写`configure(ResourceServerSecurityConfigurer resources`方法**
```java
    private static final String RESOURCE_ID = "res1";    //与授权中心客户端配置一致

    @Resource
    private ResourceServerTokenServices tokenServices;

    @Bean
    public ResourceServerTokenServices tokenServices(){
        RemoteTokenServices service = new RemoteTokenServices();
        service.setCheckTokenEndpointUrl("http://localhost:8080/oauth/check_token");
        service.setClientId("c1");
        service.setClientSecret("abc123");

        return service;
    }

    /**
     * 验证令牌的服务
     *
     * @param resources
     * @throws Exception
     */
    @Override
    public void configure(ResourceServerSecurityConfigurer resources) throws Exception {
        resources.resourceId(RESOURCE_ID) //资源id
                .tokenServices(tokenServices) //到验证服务器验证令牌有效性
                .stateless(true);
    }
```

**重写`configure(HttpSecurity http)`方法，添加安全访问控制**
```java
    /**
     * 设置资源权限
     *
     * @param http
     * @throws Exception
     */
    @Override
    public void configure(HttpSecurity http) throws Exception {
        http
                .csrf().disable()
                .authorizeRequests()
                .antMatchers("/**").access("#oauth2.hasScope('all')")  //用户有"all"授权，可以访问所有接口
                .and()
                .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS);
    }
```

**继承WebSecurityConfigurerAdapter类配置访问权限**
```java
public class WebSecurity extends WebSecurityConfigurerAdapter {

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf().disable()
                .authorizeRequests()
//                .antMatchers("/r/contents").hasAuthority("/contents/")
//                .antMatchers("/r/users").hasAuthority("/users/")
                .antMatchers("/r/**").authenticated()//所有的/r/**的请求必须认证通过
                .anyRequest().permitAll();//除了r/**，其他请求都可以随意访问
    }

}
```

**接口类**
```java
@RestController
@EnableGlobalMethodSecurity(prePostEnabled=true)
public class OrderController {

    @GetMapping(value = "/r/contents")
    @PreAuthorize("hasAnyAuthority('p1')") //方法执行前进行判断，拥有p1权限可以访问该url；
    public String contents(){
        return "访问资源contents";
    }

    @GetMapping(value = "/r/users")
    public String users(){
        return "访问资源users";
    }

    @GetMapping(value = "/list")
    public String r1(){
        return "访问资源list";
    }

}
```





<br>



###4 优化Oauth2
####4.1 使用JWT令牌
通过RemoteTokenServices 进行远程验证token，在大量请求的情况下效率不高，因此采用JWT令牌。
Oauth2已经集成了JWT，所以不需要引入JWT依赖自己实现JWT的方法，直接使用Oauth2提供的方法即可。
#####4.1.1 认证服务器端
**TokenConfig类配置**
- 设置秘钥
- 将内存存储令牌替换为JWT
- 配置JWT参数
```java
@Configuration
public class TokenConfig {

    /**
     * 配置将令牌存储在内存中
     *
     * @return
     */
//    @Bean
//    public TokenStore tokenStore() {
//        //使用内存存储令牌
//        return new InMemoryTokenStore();
//    }

    private String SIGNING_KEY = "uaa123";

    /**
     * 将JWT作为令牌
     *
     * @return
     */
    @Bean
    public TokenStore tokenStore(){
        return new JwtTokenStore(accessTokenConverter());
    }

    /**
     * JWT配置
     *
     * @return
     */
    @Bean
    public JwtAccessTokenConverter accessTokenConverter(){
        JwtAccessTokenConverter converter = new JwtAccessTokenConverter();
        converter.setSigningKey(SIGNING_KEY); //对称秘钥，资源服务器使用该秘钥来验证
        return converter;
    }

}
```

**AuthorizationServer**
- 修改token存储方式
- 引入Jwt的配置
```java
    //token存储方式
    @Resource
    private TokenStore tokenStore;
    //JWT令牌配置
    @Resource
    private JwtAccessTokenConverter accessTokenConverter;

    /**
     * 令牌管理服务
     *
     * @return
     */
    @Bean
    public AuthorizationServerTokenServices tokenServices() {
        DefaultTokenServices services = new DefaultTokenServices();
        services.setClientDetailsService(clientDetailsService); //客户端详情服务
        services.setSupportRefreshToken(true); //支持刷新令牌
        services.setTokenStore(tokenStore); //令牌的存储策略
        //令牌增强,设置JWT令牌
        TokenEnhancerChain tokenEnhancerChain = new TokenEnhancerChain();
        tokenEnhancerChain.setTokenEnhancers(Arrays.asList(accessTokenConverter));
        services.setTokenEnhancer(tokenEnhancerChain);

        services.setAccessTokenValiditySeconds(7200); //令牌默认有效时间2小时
        services.setRefreshTokenValiditySeconds(259200); //刷新令牌默认有效期3天
        return services;
    }
```
得到的token
```
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicmVzMSJdLCJ1c2VyX25hbWUiOiJhZG1pbiIsInNjb3BlIjpbImFsbCJdLCJleHAiOjE1OTQ4NzE3MTUsImF1dGhvcml0aWVzIjpbIi9jb250ZW50cy8iLCIvY29udGVudHMvdmlldy8qKiIsIi91c2Vycy8iLCIvdXNlcnMvdXBkYXRlLyoqIiwiL2NvbnRlbnRzL3VwZGF0ZS8qKiIsIlJPTEVfYWRtaW4iLCIvdXNlcnMvdmlldy8qKiIsIi91c2Vycy9pbnNlcnQvKioiLCIvY29udGVudHMvZGVsZXRlLyoqIiwiL2NvbnRlbnRzL2luc2VydC8qKiIsIi91c2Vycy9kZWxldGUvKioiLCIvIl0sImp0aSI6IjlmMTU1ZTI0LTZjZWItNDk5Zi1hNDU4LWZlZGZlMTQ0MTE3NiIsImNsaWVudF9pZCI6ImMxIn0.-QkrrSaKEkUld-69ib5mMOQPEnlwCNTAQ6YQPMwqRWo",
    "token_type": "bearer",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicmVzMSJdLCJ1c2VyX25hbWUiOiJhZG1pbiIsInNjb3BlIjpbImFsbCJdLCJhdGkiOiI5ZjE1NWUyNC02Y2ViLTQ5OWYtYTQ1OC1mZWRmZTE0NDExNzYiLCJleHAiOjE1OTUxMjM3MTUsImF1dGhvcml0aWVzIjpbIi9jb250ZW50cy8iLCIvY29udGVudHMvdmlldy8qKiIsIi91c2Vycy8iLCIvdXNlcnMvdXBkYXRlLyoqIiwiL2NvbnRlbnRzL3VwZGF0ZS8qKiIsIlJPTEVfYWRtaW4iLCIvdXNlcnMvdmlldy8qKiIsIi91c2Vycy9pbnNlcnQvKioiLCIvY29udGVudHMvZGVsZXRlLyoqIiwiL2NvbnRlbnRzL2luc2VydC8qKiIsIi91c2Vycy9kZWxldGUvKioiLCIvIl0sImp0aSI6IjZlYWE2NTlmLWEzOGMtNGU1OS1hNmZmLWJhYjkzMGM1MmI0YyIsImNsaWVudF9pZCI6ImMxIn0.lYCZzuEUF2btKNOlu3DTLWkWX50I5PpVsIXAIYUCuak",
    "expires_in": 7199,
    "scope": "all",
    "jti": "9f155e24-6ceb-499f-a458-fedfe1441176"
}
```

#####4.1.2 资源服务器端
- 添加秘钥
- 将远程校验替换为本地JWT令牌校验
**tokenStore配置类**
```java
@Configuration
public class TokenConfig {

    private String SIGNING_KEY = "uaa123";

    /**
     * 将JWT作为令牌
     *
     * @return
     */
    @Bean
    public TokenStore tokenStore(){
        return new JwtTokenStore(accessTokenConverter());
    }

    /**
     * 配置JWT令牌
     *
     * @return
     */
    @Bean
    public JwtAccessTokenConverter accessTokenConverter(){
        JwtAccessTokenConverter converter = new JwtAccessTokenConverter();
        converter.setSigningKey(SIGNING_KEY);
        return converter;
    }

}
```
**ResourceServerConfigurerAdapter继承类**
```java
    @Resource
    private TokenStore tokenStore;

    /**
     * 对token进行远程校验
     *
     * @return
     */
//    @Bean
//    public ResourceServerTokenServices tokenServices() {
//        RemoteTokenServices service = new RemoteTokenServices();
//        service.setCheckTokenEndpointUrl("http://localhost:8080/oauth/check_token");
//        service.setClientId("c1");
//        service.setClientSecret("abc123");
//
//        return service;
//    }


    /**
     * 验证令牌的服务
     *
     * @param resources
     * @throws Exception
     */
    @Override
    public void configure(ResourceServerSecurityConfigurer resources) throws Exception {
        resources.resourceId(RESOURCE_ID) //资源id
//                .tokenServices(tokenServices()) //到验证服务器验证令牌有效性
                .tokenStore(tokenStore) //对JWT令牌进行本地验证
                .stateless(true);
    }
```

####4.2 客户端信息配置到数据库
在数据库中创建客户端信息表oauth_client_details，按照官方规格进行创建，框架中已实现数据库的查询，只需要设置为数据库模式即可。
```java
    //客户端详情服务
    @Resource
    private ClientDetailsService clientDetailsService;

    /**
     * 将客户端信息存储到数据库
     *
     * @param dataSource
     * @return
     */
    @Bean
    public ClientDetailsService clientDetailsService(DataSource dataSource) {
        JdbcClientDetailsService jdbcClientDetailsService = new JdbcClientDetailsService(dataSource);
        jdbcClientDetailsService.setPasswordEncoder(bCryptPasswordEncoder);
        return clientDetailsService;
    }
>创建clientDetailsService方法设置数据库配置并重新注入到容器中，

    /**
     * 客户端配置
     *
     * @param clients
     * @throws Exception
     */
    @Override
    public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
        clients.withClientDetails(clientDetailsService);
//        clients.inMemory()//使用内存存储
//                .withClient("c1") //客户端id
//                .secret(bCryptPasswordEncoder.encode("abc123"))//设置密码
//                .resourceIds("res1")//可访问的资源列表
//                .authorizedGrantTypes("authorization_code", "password", "client_credentials", "implicit", "refresh_token")//该client允许的授权类型
//                .scopes("all")//允许的授权范围
//                .autoApprove(false)//false跳转到授权页面，true不跳转
//                .redirectUris("http://www.baidu.com");//设置回调地址
    }
```

####4.3 验证码模式将验证码存储到数据库
分布式环境下，需要将验证码持久化到数据库中，解决数据不同步的问题。

```java
    /**
     * 设置授权码模式的授权码如何存取，暂时采用内存方式
     *
     * @return
     */
//    @Bean
//    public AuthorizationCodeServices authorizationCodeServices(){
//        return new InMemoryAuthorizationCodeServices();
//    }

    @Resource
    private AuthorizationCodeServices authorizationCodeServices;

    /**
     * 授权码存储到数据库
     * @param dataSource
     * @return
     */
    @Bean
    public AuthorizationCodeServices authorizationCodeServices(DataSource dataSource){
        return new JdbcAuthorizationCodeServices(dataSource);
    }

    /**
     * 令牌访问端点配置
     *
     * @param endpoints
     * @throws Exception
     */
    @Override
    public void configure(AuthorizationServerEndpointsConfigurer endpoints) throws Exception {
        endpoints
                .authenticationManager(authenticationManager)//认证管理器
                .authorizationCodeServices(authorizationCodeServices)//授权码服务
                .tokenServices(tokenServices()) //令牌管理服务
                .allowedTokenEndpointRequestMethods(HttpMethod.POST);
    }
```

>


```
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicmVzMSJdLCJ1c2VyX25hbWUiOiJhZG1pbiIsInNjb3BlIjpbIlJPTEVfVVNFUiJdLCJleHAiOjE1OTQ5MjIxNDIsImF1dGhvcml0aWVzIjpbIi9jb250ZW50cy8iLCIvY29udGVudHMvdmlldy8qKiIsIi91c2Vycy8iLCIvdXNlcnMvdXBkYXRlLyoqIiwiL2NvbnRlbnRzL3VwZGF0ZS8qKiIsIlJPTEVfYWRtaW4iLCIvdXNlcnMvdmlldy8qKiIsIi91c2Vycy9pbnNlcnQvKioiLCIvY29udGVudHMvZGVsZXRlLyoqIiwiL2NvbnRlbnRzL2luc2VydC8qKiIsIi91c2Vycy9kZWxldGUvKioiLCIvIl0sImp0aSI6IjQ2NGI2OGMyLTk3MWEtNGUwYS1iMmVhLWZmODdhZmE5YWEyZCIsImNsaWVudF9pZCI6ImMxIn0.-W6VHilfDiNmQ-oSPXNTOet0o4lBkC2X0r7-lP9V528",
    "token_type": "bearer",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicmVzMSJdLCJ1c2VyX25hbWUiOiJhZG1pbiIsInNjb3BlIjpbIlJPTEVfVVNFUiJdLCJhdGkiOiI0NjRiNjhjMi05NzFhLTRlMGEtYjJlYS1mZjg3YWZhOWFhMmQiLCJleHAiOjE1OTQ5MzY1NDIsImF1dGhvcml0aWVzIjpbIi9jb250ZW50cy8iLCIvY29udGVudHMvdmlldy8qKiIsIi91c2Vycy8iLCIvdXNlcnMvdXBkYXRlLyoqIiwiL2NvbnRlbnRzL3VwZGF0ZS8qKiIsIlJPTEVfYWRtaW4iLCIvdXNlcnMvdmlldy8qKiIsIi91c2Vycy9pbnNlcnQvKioiLCIvY29udGVudHMvZGVsZXRlLyoqIiwiL2NvbnRlbnRzL2luc2VydC8qKiIsIi91c2Vycy9kZWxldGUvKioiLCIvIl0sImp0aSI6IjUzM2U2MDNlLWE3NmItNGI4NC1iYTEzLTYxZGNhOTZmMmVkMCIsImNsaWVudF9pZCI6ImMxIn0.GXzrspclRlQjwN0k8WO8rGP_nJfUQApVLv7KWOE11fU",
    "expires_in": 3599,
    "scope": "ROLE_USER",
    "jti": "464b68c2-971a-4e0a-b2ea-ff87afa9aa2d"
}
```
为什么c2没有刷新令牌？？？？？？
```
{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicmVzMiJdLCJ1c2VyX25hbWUiOiJhZG1pbiIsInNjb3BlIjpbIlJPTEVfVVNFUiJdLCJleHAiOjE1OTQ5MjE4MDEsImF1dGhvcml0aWVzIjpbIi9jb250ZW50cy8iLCIvY29udGVudHMvdmlldy8qKiIsIi91c2Vycy8iLCIvdXNlcnMvdXBkYXRlLyoqIiwiL2NvbnRlbnRzL3VwZGF0ZS8qKiIsIlJPTEVfYWRtaW4iLCIvdXNlcnMvdmlldy8qKiIsIi91c2Vycy9pbnNlcnQvKioiLCIvY29udGVudHMvZGVsZXRlLyoqIiwiL2NvbnRlbnRzL2luc2VydC8qKiIsIi91c2Vycy9kZWxldGUvKioiLCIvIl0sImp0aSI6IjJmZjRjOTgzLTE0ZjUtNGI1Mi1iNGQ5LWRhMjFmYWViN2M2ZCIsImNsaWVudF9pZCI6ImMyIn0.jOW9vMeCqX6cnjK6tdRFFs3bRb74VbiW7Zg2vEOQJvE",
    "token_type": "bearer",
    "expires_in": 3599,
    "scope": "ROLE_USER",
    "jti": "2ff4c983-14f5-4b52-b4d9-da21faeb7c6d"
}
```

<br>

###5 分布式系统授权
#####5.1 网关
网关整合OAuth2有两种思路：
- 认证服务器生成jwt令牌，所有请求统一在网关层验证，判断权限等操作；
- 由各资源服务处理，网关只做请求转发。

我们选择第一种，把API网关作为OAuth2.0的资源服务器角色，实现接入客户端权限拦截、令牌解析并转发当前登录用户信息（jsonToken）给微服务，这样下游微服务就不需要关心令牌格式解析以及OAuth2.0相关机制。

API网关在认证授权体系主要负责两件事：
- 作为OAuth2.0的资源服务器角色，实现接入方权限拦截；
- 令牌解析并转发当前登录用户信息（明文token）给微服务，微服务拿到明文token（包含登录用户身份信息和权限信息）后也需要做两件事：
- 用户授权拦截（看当前用户是否有访问该资源的权限）
- 将用户信息存储到当前线程上下文（有利于后续业务逻辑随时获取当前用户信息）

资源权限管理
```yml
@Configuration
public class ResourceServerConfig {

    private static final String RESOURCE_ID = "res1";

    @Resource
    private TokenStore tokenStore;

    @Configuration
    @EnableResourceServer
    public class UAAServerConfig extends ResourceServerConfigurerAdapter {
        @Override
        public void configure(ResourceServerSecurityConfigurer resources) throws Exception {
            resources.resourceId(RESOURCE_ID)
                    .tokenStore(tokenStore)
                    .stateless(true);
        }

        @Override
        public void configure(HttpSecurity http) throws Exception {
            http.authorizeRequests()
                    .antMatchers("/auu/**").permitAll();

        }
    }

    @Configuration
    @EnableResourceServer
    public class OrderServerConfig extends ResourceServerConfigurerAdapter {
        @Override
        public void configure(ResourceServerSecurityConfigurer resources) throws Exception {
            resources.resourceId(RESOURCE_ID)
                    .tokenStore(tokenStore)
                    .stateless(true);
        }

        @Override
        public void configure(HttpSecurity http) throws Exception {
            http.authorizeRequests()
                    .antMatchers("/order/**").access("#oauth2.hasScope('ROLE_API')");
        }
    }

}
```
>网关相当于一个资源服务器，对请求进行`客户端权限认证`，认证通过后将请求转发到对应的微服务中进行`用户权限认证`。

添加过滤器在请求头中添加明文token信息
```java
@Component
public class AuthFilter implements GlobalFilter, Ordered {
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        // 获取权限信息
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (!(authentication instanceof OAuth2Authentication)) {
            chain.filter(exchange);
        }
        OAuth2Authentication oAuth2Authentication = (OAuth2Authentication) authentication;
        Authentication userAuthentication = oAuth2Authentication.getUserAuthentication();
        // 获取用户身份
        String principal = userAuthentication.getName();
        // 获取用户权限
        Collection<? extends GrantedAuthority> authoritiesList = userAuthentication.getAuthorities();
        List<String> authorities = authoritiesList.stream().map(authority -> {
            return ((GrantedAuthority) authority).getAuthority();
        }).collect(Collectors.toList());
        // 获取用户请求中的参数列表
        OAuth2Request oAuth2Request = oAuth2Authentication.getOAuth2Request();
        Map<String, String> requestParameters = oAuth2Request.getRequestParameters();

        // 封装信息并编码
        HashMap<String, Object> jsonToken = new HashMap<>(requestParameters);
        if (userAuthentication != null) {
            jsonToken.put("principal", principal);
            jsonToken.put("authoritiest", authorities);
        }
        JSONObject jsonObject = new JSONObject(jsonToken);
        System.out.println("*****jsonObject：" + jsonObject);
        String encodeToken = Base64Util.encode(jsonObject.toString());

        // 将jsonToke放入到http的header中
        ServerHttpRequest request = exchange.getRequest().mutate().header("json-token", encodeToken).build();
        ServerWebExchange newExchange = exchange.mutate().request(request).build();

        return chain.filter(newExchange);
    }

    @Override
    public int getOrder() {
        return 0;
    }
}
```
>从上下文中获取用户的信息，封装为json串并用base64编码后添加到请求头中，然后通过网关转发到对应的资源服务器中。

在资源服务器对请求头中的token进行鉴权
```java
@Component
public class TokenAuthenticationFilter extends OncePerRequestFilter {
    @SneakyThrows
    @Override
    protected void doFilterInternal(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, FilterChain filterChain) throws ServletException, IOException {
        // 解析出header中的token
        String encodeToken = httpServletRequest.getHeader("json-token");
        if (encodeToken != null) {
            String token = Base64.decodeStr(encodeToken);
            JSONObject jsonObject = new JSONObject(token);
            // 用户信息
            String principal = jsonObject.getString("principal");
            // 用户权限
            JSONArray authoritiesArray = jsonObject.getJSONArray("authorities");
            String authorities = authoritiesArray.join(",");

            System.out.println("*****UserInfo:" + principal + "--" + authorities);
            // 将用户信息和权限填充到UsernamePasswordAuthenticationToken对象中
            UsernamePasswordAuthenticationToken authenticationToken = new UsernamePasswordAuthenticationToken(principal,null,AuthorityUtils.commaSeparatedStringToAuthorityList(authorities));
            authenticationToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(httpServletRequest));
            // 将authenticationToken填充到安全上下文中
            SecurityContextHolder.getContext().setAuthentication(authenticationToken);
        }
        // 继续执行下一个过滤器
        filterChain.doFilter(httpServletRequest,httpServletResponse);
    }
}
```
>OncePerRequestFilter过滤器对每次请求都会进行过滤，非常适合token的解析。将token解码，将信息填充到UsernamePasswordAuthenticationToken对象中，然后填充到安全上下文中。虽然网关层已经校验了客户端权限，但是Oauth2Authentication需要配置资源服务器才会加载到上下文，因此还是需要配置@EnableResourceServer。
>ResourceServerConfigurerAdapter和WebSecurityConfigurerAdapter异同：
- ResourceServerConfigurerAdapter是Oauth2的过滤器，WebSecurityConfigurerAdapter是Security的过滤器
- ResourceServerConfigurerAdapter过滤器优先级比WebSecurityConfigurerAdapter高，我们每声明一个Adapter类，都会产生一个filterChain。一个request（匹配url）只能被一个filterChain处理，因此WebSecurityConfigurerAdapter会失效。


<br>
###注意点
security和oauth2同时存在时，Oauth2资源配置服务类ResourceServerConfigurerAdapter的优先级高于WebSecurityConfigurerAdapter。

AuthorizationServerConfigurerAdapter与WebSecurityConfigurerAdapter不冲突，访问路径权限还是在WebSecurityConfigurerAdapter中配置。
