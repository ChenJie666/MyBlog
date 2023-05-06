---
title: Oauth2代码
categories:
- 权限认证
---
源码：https://github.com/ChenJie666/security.git

###1 代码
#####1.1 认证服务器代码
***配置类AuthorizationServer***
```java
@Configuration
@EnableAuthorizationServer
public class AuthorizationServer extends AuthorizationServerConfigurerAdapter {

    @Resource
    private BCryptPasswordEncoder bCryptPasswordEncoder;

    //token存储方式
    @Resource
    private TokenStore tokenStore;

    //客户端详情服务
    @Resource
    private ClientDetailsService clientDetailsService;

    //授权码服务
    @Autowired
    private AuthorizationCodeServices authorizationCodeServices;

    //认证管理器
    @Autowired
    private AuthenticationManager authenticationManager;

    /**
     * 设置授权码模式的授权码如何存取，暂时采用内存方式
     *
     * @return
     */
    @Bean
    public AuthorizationCodeServices authorizationCodeServices(){
        return new InMemoryAuthorizationCodeServices();
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
                .scopes("all")//允许的授权范围
                .autoApprove(false)//false跳转到授权页面，true不跳转
                .redirectUris("http://www.baidu.com");//设置回调地址
    }

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
        services.setAccessTokenValiditySeconds(7200); //令牌默认有效时间2小时
        services.setRefreshTokenValiditySeconds(259200); //刷新令牌默认有效期3天
        return services;
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

    /**
     * 对授权端点接口的安全约束
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

}
```

***配置类SecurityConfig ***
```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    @Bean
    public BCryptPasswordEncoder bCryptPasswordEncoder(){
        return new BCryptPasswordEncoder();
    }

    /**
     * 认证管理器
     *
     * @return
     * @throws Exception
     */
    @Bean
    @Override
    public AuthenticationManager authenticationManagerBean() throws Exception {
        return super.authenticationManagerBean();
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
                //跨域请求伪造防御失效
                .csrf().disable()
                .authorizeRequests()
                .antMatchers("/r/r1").hasAnyAuthority("p1")
                .antMatchers("/login*").permitAll()
                .anyRequest().authenticated()
                .and()
                .formLogin();
//                .sessionManagement()
//                .sessionCreationPolicy(SessionCreationPolicy.STATELESS);
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

***配置类TokenConfig ***
```java
@Configuration
public class TokenConfig {

    /**
     * 配置将令牌存储在内存中
     *
     * @return
     */
    @Bean
    public TokenStore tokenStore() {
        //使用内存存储令牌
        return new InMemoryTokenStore();
    }

}
```

***实现UserDetails类***
```java
@Component
@Data
public class MyUserDetails implements UserDetails {

    private String username;
    private String password;
    boolean accountNonExpired = true; // 账号是否过期
    boolean accountNonLocked = true; //用户是否被锁定
    boolean credentialsNonExpired = true; //凭证是否过期
    boolean enabled = true; //账号是否可用
    Collection<? extends GrantedAuthority> authorities; //用户权限集合

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return username;
    }

    @Override
    public boolean isAccountNonExpired() {
        return accountNonExpired;
    }

    @Override
    public boolean isAccountNonLocked() {
        return accountNonLocked;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return credentialsNonExpired;
    }

    @Override
    public boolean isEnabled() {
        return enabled;
    }
}
```

***实现MyUserDetailsServer ***
```java
@Service
@Slf4j
public class MyUserDetailsServer implements UserDetailsService {

    @Resource
    private MyUserDetailsServerMapper myUserDetailsServerMapper;

    /**
     * 将账号密码和权限信息封装到UserDetails对象中返回
     * @param username
     * @return
     * @throws UsernameNotFoundException
     */
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        //通过查询数据库获取用户的账号密码
        MyUserDetails myUserDetails = myUserDetailsServerMapper.findByUsername(username);

        List<String> roleCodes = myUserDetailsServerMapper.findRoleByUsername(username);
        List<String> authorities = myUserDetailsServerMapper.findAuthorityByRoleCodes(roleCodes);

        //将用户角色添加到用户权限中
        authorities.addAll(roleCodes);

        //设置UserDetails中的authorities属性，需要将String类型转换为GrantedAuthority
        myUserDetails.setAuthorities(AuthorityUtils.commaSeparatedStringToAuthorityList(String.join(",",authorities)));

        log.info("UserDetail:" + myUserDetails);
        return myUserDetails;
    }

}
```

***查询RBAC数据库***
```java
@Component
public interface MyUserDetailsServerMapper {

    /**
     * 根据用户名查询
     * @param username
     * @return
     */
    @Select("SELECT username,password " +
            "FROM tb_user " +
            "WHERE username=#{username}")
    MyUserDetails findByUsername(@Param("username") String username);

    /**
     * 根据用户名查询角色列表
     * @param username
     * @return
     */
    @Select("SELECT r.enname " +
            "FROM tb_role r " +
            "LEFT JOIN tb_user_role ur ON ur.role_id=r.id " +
            "LEFT JOIN tb_user u ON u.id=ur.user_id " +
            "WHERE u.username=#{username}")
    List<String> findRoleByUsername(@Param(value = "username") String username);

    /**
     * 根据用户角色查询权限
     * @param roleCodes
     * @return
     */
    @Select("<script> " +
            "SELECT url " +
            "FROM tb_permission p " +
            "LEFT JOIN tb_role_permission rp ON rp.permission_id=p.id " +
            "LEFT JOIN tb_role r ON r.id=rp.role_id " +
            "WHERE r.enname IN " +
            "<foreach collection='roleCodes' item='roleCode' open='(' separator=',' close=')'> " +
            "#{roleCode} " +
            "</foreach> " +
            "</script>")
    List<String> findAuthorityByRoleCodes(@Param(value = "roleCodes") List<String> roleCodes);

}
```

#####1.2 资源服务器
验证token有效性
请求地址：http://localhost:8080/oauth/check_token?token=4dbef819-d7dd-48b4-b078-e5833efb1e02
返回结果：
```json
{
    "aud": [
        "res1"
    ],
    "user_name": "admin",
    "scope": [
        "all"
    ],
    "active": true,
    "exp": 1594799642,
    "authorities": [
        "/contents/",
        "/contents/view/**",
        "/users/",
        "/users/update/**",
        "/contents/update/**",
        "ROLE_admin",
        "/users/view/**",
        "/users/insert/**",
        "/contents/delete/**",
        "/contents/insert/**",
        "/users/delete/**",
        "/"
    ],
    "client_id": "c1"
}
```
