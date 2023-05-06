---
title: JWT-token的刷新（转载）
categories:
- 权限认证
---
jwt token刷新方案可以分为两种：一种是校验token前刷新，第二种是校验失败后刷新。

我们先来说说第二种方案
验证失效后，Oauth2框架会把异常信息发送到OAuth2AuthenticationEntryPoint类里处理。这时候我们可以在这里做jwt token刷新并跳转。
网上大部分方案也是这种：失效后，使用refresh_token获取新的access_token。并将新的access_token设置到response.header然后跳转，前端接收并无感更新新的access_token。

这里就不多做描述，可以参考这两篇：

https://www.cnblogs.com/xuchao0506/p/13073913.html

https://blog.csdn.net/m0_37834471/article/details/83213002

接着说第一种，其实两种方案的代码我都写过，最终使用了第一种。原因是兼容其他token刷新方案。

我在使用第二种方案并且jwt token刷新功能正常使用后，想换一种token方案做兼容。

切换成memory token的时候，发现OAuth2AuthenticationEntryPoint里面拿不到旧的token信息导致刷新失败。

我们翻一下源码

DefaultTokenServices.java
```
public OAuth2Authentication loadAuthentication(String accessTokenValue) throws AuthenticationException,
            InvalidTokenException {
        OAuth2AccessToken accessToken = tokenStore.readAccessToken(accessTokenValue);
        if (accessToken == null) {
            throw new InvalidTokenException("Invalid access token: " + accessTokenValue);
        }
        else if (accessToken.isExpired()) {
            // 失效后accessToken即被删除
            tokenStore.removeAccessToken(accessToken);
            throw new InvalidTokenException("Access token expired: " + accessTokenValue);
        }
 
        // 忽略部分代码
        return result;
    }
```

可以看到JwtTokenStore的removeAccessToken：它是一个空方法，什么也没做。所以我们在OAuth2AuthenticationEntryPoint依然能拿到旧的token并作处理。
![image.png](JWT-token的刷新（转载）.assets\28e49f23dcb645a38e09477c60c0b9d1.png)

但是其他的token策略在token过期后，被remove掉了。一点信息都没留下，巧妇难为无米之炊。所以，我之后选择选择了第一种方案，在token校验remove前做刷新处理。

jwt token刷新的方案是这样的：

客户端发送请求大部分只携带access_token，并不携带refresh_token、client_id及client_secret等信息。所以我是先把refresh_token、client_id等信息放到access_token里面。

因为jwt并不具有续期的功能，所以在判断token过期后，立刻使用refresh_token刷新。并且在response的header里面添加标识告诉前端你的token实际上已经过期了需要更新。

当然，其他的类似memory token、redis token可以延期的，更新策略就没这么复杂：直接延长过期时间并且不需要更新token。



说了这么多，放token刷新相关代码：

首先，我们需要把refresh_token、client_id、client_secret放入到access_token中，以便刷新。所以我们需要重写JwtAccessTokenConverter的enhance方法。

OauthJwtAccessTokenConverter.java
```
public class OauthJwtAccessTokenConverter extends JwtAccessTokenConverter {
    private JsonParser objectMapper = JsonParserFactory.create();
 
    public OauthJwtAccessTokenConverter(SecurityUserService userService) {
        // 使用SecurityContextHolder.getContext().getAuthentication()能获取到User信息
        super.setAccessTokenConverter(new OauthAccessTokenConverter(userService));
    }
 
    @Override
    public OAuth2AccessToken enhance(OAuth2AccessToken accessToken, OAuth2Authentication authentication) {
        DefaultOAuth2AccessToken result = new DefaultOAuth2AccessToken(accessToken);
        Map<String, Object> info = new LinkedHashMap<String, Object>(accessToken.getAdditionalInformation());
        String tokenId = result.getValue();
        if (!info.containsKey(TOKEN_ID)) {
            info.put(TOKEN_ID, tokenId);
        } else {
            tokenId = (String) info.get(TOKEN_ID);
        }
 
        // access_token 包含自动刷新过期token需要的数据(client_id/secret/refresh_token)
        Map<String, Object> details = (Map<String, Object>) authentication.getUserAuthentication().getDetails();
        if (!Objects.isNull(details) && details.size() > 0) {
            info.put(OauthConstant.OAUTH_CLIENT_ID,
                    details.getOrDefault("client_id", details.get(OauthConstant.OAUTH_CLIENT_ID)));
 
            info.put(OauthConstant.OAUTH_CLIENT_SECRET,
                    details.getOrDefault("client_secret", details.get(OauthConstant.OAUTH_CLIENT_SECRET)));
        }
 
        OAuth2RefreshToken refreshToken = result.getRefreshToken();
        if (refreshToken != null) {
            DefaultOAuth2AccessToken encodedRefreshToken = new DefaultOAuth2AccessToken(accessToken);
            encodedRefreshToken.setValue(refreshToken.getValue());
            // Refresh tokens do not expire unless explicitly of the right type
            encodedRefreshToken.setExpiration(null);
            try {
                Map<String, Object> claims = objectMapper
                        .parseMap(JwtHelper.decode(refreshToken.getValue()).getClaims());
                if (claims.containsKey(TOKEN_ID)) {
                    encodedRefreshToken.setValue(claims.get(TOKEN_ID).toString());
                }
            } catch (IllegalArgumentException e) {
            }
            Map<String, Object> refreshTokenInfo = new LinkedHashMap<String, Object>(
                    accessToken.getAdditionalInformation());
            refreshTokenInfo.put(TOKEN_ID, encodedRefreshToken.getValue());
            // refresh token包含client id/secret, 自动刷新过期token时用到。
            if (!Objects.isNull(details) && details.size() > 0) {
                refreshTokenInfo.put(OauthConstant.OAUTH_CLIENT_ID,
                        details.getOrDefault("client_id", details.get(OauthConstant.OAUTH_CLIENT_ID)));
 
                refreshTokenInfo.put(OauthConstant.OAUTH_CLIENT_SECRET,
                        details.getOrDefault("client_secret", details.get(OauthConstant.OAUTH_CLIENT_SECRET)));
            }
            refreshTokenInfo.put(ACCESS_TOKEN_ID, tokenId);
            encodedRefreshToken.setAdditionalInformation(refreshTokenInfo);
            DefaultOAuth2RefreshToken token = new DefaultOAuth2RefreshToken(
                    encode(encodedRefreshToken, authentication));
            if (refreshToken instanceof ExpiringOAuth2RefreshToken) {
                Date expiration = ((ExpiringOAuth2RefreshToken) refreshToken).getExpiration();
                encodedRefreshToken.setExpiration(expiration);
                token = new DefaultExpiringOAuth2RefreshToken(encode(encodedRefreshToken, authentication), expiration);
            }
            result.setRefreshToken(token);
            info.put(OauthConstant.OAUTH_REFRESH_TOKEN, token.getValue());
        }
        result.setAdditionalInformation(info);
        result.setValue(encode(result, authentication));
        return result;
    }
}
```

信息准备好了，就要开始处理刷新。就是改写DefaultTokenServices的loadAuthentication方法。

OauthTokenServices.java
```
public class OauthTokenServices extends DefaultTokenServices {
    private static final Logger logger = LoggerFactory.getLogger(OauthTokenServices.class);
 
    private TokenStore tokenStore;
    // 自定义的token刷新处理器
    private TokenRefreshExecutor executor;
 
    public OauthTokenServices(TokenStore tokenStore, TokenRefreshExecutor executor) {
        super.setTokenStore(tokenStore);
        this.tokenStore = tokenStore;
        this.executor = executor;
    }
 
    @Override
    public OAuth2Authentication loadAuthentication(String accessTokenValue) throws AuthenticationException, InvalidTokenException {
        OAuth2AccessToken accessToken = tokenStore.readAccessToken(accessTokenValue);
        executor.setAccessToken(accessToken);
        // 是否刷新token
        if (executor.shouldRefresh()) {
            try {
                logger.info("refresh token.");
                String newAccessTokenValue = executor.refresh();
                // token如果是续期不做remove操作，如果是重新生成则删除旧的token
                if (!newAccessTokenValue.equals(accessTokenValue)) {
                    tokenStore.removeAccessToken(accessToken);
                }
                accessTokenValue = newAccessTokenValue;
            } catch (Exception e) {
                logger.error("token refresh failed.", e);
            }
        }
 
        return super.loadAuthentication(accessTokenValue);
    }
}
```

类里面的TokenRefreshExecutor就是我们的重点。这个类定义了两个比较重要的接口。

shouldRefresh：是否需要刷新

refresh：刷新

TokenRefreshExecutor.java
```
public interface TokenRefreshExecutor {
 
    /**
     * 执行刷新
     * @return
     * @throws Exception
     */
    String refresh() throws Exception;
 
    /**
     * 是否需要刷新
     * @return
     */
    boolean shouldRefresh();
 
    void setTokenStore(TokenStore tokenStore);
 
    void setAccessToken(OAuth2AccessToken accessToken);
 
    void setClientService(ClientDetailsService clientService);
}
```


然后我们来看看jwt刷新器，

OauthJwtTokenRefreshExecutor.java
```
public class OauthJwtTokenRefreshExecutor extends AbstractTokenRefreshExecutor {
 
    private static final Logger logger = LoggerFactory.getLogger(OauthJwtTokenRefreshExecutor.class);
 
    @Override
    public boolean shouldRefresh() {
        // 旧token过期才刷新
        return getAccessToken() != null && getAccessToken().isExpired();
    }
 
    @Override
    public String refresh() throws Exception{
        HttpServletRequest request = ServletUtil.getRequest();
        HttpServletResponse response = ServletUtil.getResponse();
        MultiValueMap<String, Object> parameters = new LinkedMultiValueMap<>();
        // OauthJwtAccessTokenConverter中存入access_token中的数据，在这里使用
        parameters.add("client_id", TokenUtil.getStringInfo(getAccessToken(), OauthConstant.OAUTH_CLIENT_ID));
        parameters.add("client_secret", TokenUtil.getStringInfo(getAccessToken(), OauthConstant.OAUTH_CLIENT_SECRET));
        parameters.add("refresh_token", TokenUtil.getStringInfo(getAccessToken(), OauthConstant.OAUTH_REFRESH_TOKEN));
        parameters.add("grant_type", "refresh_token");
        // 发送刷新的http请求
        Map result = RestfulUtil.post(getOauthTokenUrl(request), parameters);
 
        if (Objects.isNull(result) || result.size() <= 0 || !result.containsKey("access_token")) {
            throw new IllegalStateException("refresh token failed.");
        }
 
        String accessToken = result.get("access_token").toString();
        OAuth2AccessToken oAuth2AccessToken = getTokenStore().readAccessToken(accessToken);
        OAuth2Authentication auth2Authentication = getTokenStore().readAuthentication(oAuth2AccessToken);
        // 保存授权信息，以便全局调用
        SecurityContextHolder.getContext().setAuthentication(auth2Authentication);
 
        // 前端收到该event事件时，更新access_token
        response.setHeader("event", "token-refreshed");
        response.setHeader("access_token", accessToken);
        // 返回新的token信息
        return accessToken;
    }
 
    private String getOauthTokenUrl(HttpServletRequest request) {
        return String.format("%s://%s:%s%s%s",
                request.getScheme(),
                request.getLocalAddr(),
                request.getLocalPort(),
                Strings.isNotBlank(request.getContextPath()) ? "/" + request.getContextPath() : "",
                "/oauth/token");
    }
}
```

类写完了，开始使用。
```
@Configuration
public class TokenConfig {
 
    @Bean
    public TokenStore tokenStore(AccessTokenConverter converter) {
        return new JwtTokenStore((JwtAccessTokenConverter) converter);
        // return new InMemoryTokenStore();
    }
 
    @Bean
    public AccessTokenConverter accessTokenConverter(SecurityUserService userService) {
        JwtAccessTokenConverter accessTokenConverter = new OauthJwtAccessTokenConverter(userService);
        accessTokenConverter.setSigningKey("sign_key");
        return accessTokenConverter;
        /*DefaultAccessTokenConverter converter = new DefaultAccessTokenConverter();
        DefaultUserAuthenticationConverter userTokenConverter = new DefaultUserAuthenticationConverter();
        userTokenConverter.setUserDetailsService(userService);
        converter.setUserTokenConverter(userTokenConverter);
        return converter;*/
    }
    @Bean
    public TokenRefreshExecutor tokenRefreshExecutor(TokenStore tokenStore,
                                                     ClientDetailsService clientService) {
        TokenRefreshExecutor executor = new OauthJwtTokenRefreshExecutor();
        // TokenRefreshExecutor executor = new OauthTokenRefreshExecutor();
        executor.setTokenStore(tokenStore);
        executor.setClientService(clientService);
        return executor;
    }
 
    @Bean
    public AuthorizationServerTokenServices tokenServices(TokenStore tokenstore,
                                                          AccessTokenConverter accessTokenConverter,
                                                          ClientDetailsService clientService,
                                                          TokenRefreshExecutor executor) {
 
        OauthTokenServices tokenServices = new OauthTokenServices(tokenstore, executor);
        // 非jwtConverter可注释setTokenEnhancer
        tokenServices.setTokenEnhancer((TokenEnhancer) accessTokenConverter);
        tokenServices.setSupportRefreshToken(true);
        tokenServices.setClientDetailsService(clientService);
        tokenServices.setReuseRefreshToken(true);
        return tokenServices;
    }
}
```

然后是认证服务器相关代码
```
@Configuration
@EnableAuthorizationServer
public class AuthorizationServerConfiguration extends AuthorizationServerConfigurerAdapter {
 
    @Autowired
    private AuthenticationManager manager;
    @Autowired
    private SecurityUserService userService;
    @Autowired
    private TokenStore tokenStore;
    @Autowired
    private AccessTokenConverter tokenConverter;
    @Autowired
    private AuthorizationServerTokenServices tokenServices;
 
    @Override
    public void configure(AuthorizationServerEndpointsConfigurer endpoints) throws Exception {
        endpoints.tokenStore(tokenStore)
                .authenticationManager(manager)
                .allowedTokenEndpointRequestMethods(HttpMethod.GET, HttpMethod.POST)
                .userDetailsService(userService)
                .accessTokenConverter(tokenConverter)
                .tokenServices(tokenServices);
    }
 
    @Override
    public void configure(AuthorizationServerSecurityConfigurer security) throws Exception {
        security.tokenKeyAccess("permitAll()") //url:/oauth/token_key,exposes public key for token verification if using JWT tokens
                .checkTokenAccess("isAuthenticated()") //url:/oauth/check_token allow check token
                .allowFormAuthenticationForClients();
    }
 
    @Override
    public void configure(ClientDetailsServiceConfigurer clients) throws Exception {
        clients.withClientDetails(clientDetailsService());
    }
 
    public ClientDetailsService clientDetailsService() {
        return new OauthClientService();
    }
}
```

接着是前端处理, 用的axios。　　
```
service.interceptors.response.use(res => {
    // 缓存自动刷新生成的新token
    if (res.headers['event'] && "token-refreshed" === res.headers['event']) {
      setToken(res.headers['access_token'])
      store.commit('SET_TOKEN', res.headers['access_token'])
    }
    // 忽略部分代码
}
```

这样就做到了jwt无感刷新。　　

讲完了jwt的token刷新，多嘴说说memory token的刷新。

上面讲了，memory token刷新策略比较简单，每次请求过来直接给token延期即可。

OauthTokenRefreshExecutor.java
```
public class OauthTokenRefreshExecutor extends AbstractTokenRefreshExecutor {
    private int accessTokenValiditySeconds = 60 * 60 * 12;
 
    @Override
    public boolean shouldRefresh() {
        // 与jwt不同，因为每次请求都需要延长token失效时间，所以这里是token未过期时就需要刷新
        return getAccessToken() != null && !getAccessToken().isExpired();
    }
 
    @Override
    public String refresh() {
        int seconds;
        if (getAccessToken() instanceof DefaultOAuth2AccessToken) {
            // 获取client中的过期时间, 没有则默认12小时
            if (getClientService() != null) {
                OAuth2Authentication auth2Authentication = getTokenStore().readAuthentication(getAccessToken());
                String clientId = auth2Authentication.getOAuth2Request().getClientId();
                ClientDetails client = getClientService().loadClientByClientId(clientId);
                seconds = client.getAccessTokenValiditySeconds();
            } else {
                seconds = accessTokenValiditySeconds;
            }
            // 只修改token失效时间
            ((DefaultOAuth2AccessToken) getAccessToken()).setExpiration(new Date(System.currentTimeMillis() + (seconds * 1000l)));
        }
        // 返回的还是旧的token
        return getAccessToken().getValue();
    }
}
```

然后修改TokenConfig相关bean注册即可。
