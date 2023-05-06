---
title: Oauth2的返回格式和白名单逻辑优化（转载）
categories:
- 权限认证
---
###自定义登录认证结果
其实我们只要找到一个关键类就可以自定义Oauth2的登录认证接口了，它就是org.springframework.security.oauth2.provider.endpoint.TokenEndpoint,其中定义了我们非常熟悉的登录认证接口，我们只要自己重写登录认证接口，直接调用默认的实现逻辑，然后把默认返回的结果处理下即可，下面是默认的实现逻辑；

```
@FrameworkEndpoint
public class TokenEndpoint extends AbstractEndpoint {

 @RequestMapping(value = "/oauth/token", method=RequestMethod.POST)
 public ResponseEntity<OAuth2AccessToken> postAccessToken(Principal principal, @RequestParam
 Map<String, String> parameters) throws HttpRequestMethodNotSupportedException {

  if (!(principal instanceof Authentication)) {
   throw new InsufficientAuthenticationException(
     "There is no client authentication. Try adding an appropriate authentication filter.");
  }

  String clientId = getClientId(principal);
  ClientDetails authenticatedClient = getClientDetailsService().loadClientByClientId(clientId);

  TokenRequest tokenRequest = getOAuth2RequestFactory().createTokenRequest(parameters, authenticatedClient);

  if (clientId != null && !clientId.equals("")) {
   // Only validate the client details if a client authenticated during this
   // request.
   if (!clientId.equals(tokenRequest.getClientId())) {
    // double check to make sure that the client ID in the token request is the same as that in the
    // authenticated client
    throw new InvalidClientException("Given client ID does not match authenticated client");
   }
  }
  if (authenticatedClient != null) {
   oAuth2RequestValidator.validateScope(tokenRequest, authenticatedClient);
  }
  if (!StringUtils.hasText(tokenRequest.getGrantType())) {
   throw new InvalidRequestException("Missing grant type");
  }
  if (tokenRequest.getGrantType().equals("implicit")) {
   throw new InvalidGrantException("Implicit grant type not supported from token endpoint");
  }

  if (isAuthCodeRequest(parameters)) {
   // The scope was requested or determined during the authorization step
   if (!tokenRequest.getScope().isEmpty()) {
    logger.debug("Clearing scope of incoming token request");
    tokenRequest.setScope(Collections.<String> emptySet());
   }
  }

  if (isRefreshTokenRequest(parameters)) {
   // A refresh token has its own default scopes, so we should ignore any added by the factory here.
   tokenRequest.setScope(OAuth2Utils.parseParameterList(parameters.get(OAuth2Utils.SCOPE)));
  }

  OAuth2AccessToken token = getTokenGranter().grant(tokenRequest.getGrantType(), tokenRequest);
  if (token == null) {
   throw new UnsupportedGrantTypeException("Unsupported grant type: " + tokenRequest.getGrantType());
  }

  return getResponse(token);

 }
}
```

我们将需要的JWT信息封装成对象，然后放入到我们的通用返回结果的data属性中去

```
/**
 * Oauth2获取Token返回信息封装
 * Created by macro on 2020/7/17.
 */
@Data
@EqualsAndHashCode(callSuper = false)
@Builder
public class Oauth2TokenDto {
    /**
     * 访问令牌
     */
    private String token;
    /**
     * 刷新令牌
     */
    private String refreshToken;
    /**
     * 访问令牌头前缀
     */
    private String tokenHead;
    /**
     * 有效时间（秒）
     */
    private int expiresIn;
}
```

创建一个AuthController，自定义实现Oauth2默认的登录认证接口；
```
/**
 * 自定义Oauth2获取令牌接口
 * Created by macro on 2020/7/17.
 */
@RestController
@RequestMapping("/oauth")
public class AuthController {

    @Autowired
    private TokenEndpoint tokenEndpoint;

    /**
     * Oauth2登录认证
     */
    @RequestMapping(value = "/token", method = RequestMethod.POST)
    public CommonResult<Oauth2TokenDto> postAccessToken(Principal principal, @RequestParam Map<String, String> parameters) throws HttpRequestMethodNotSupportedException {
        OAuth2AccessToken oAuth2AccessToken = tokenEndpoint.postAccessToken(principal, parameters).getBody();
        Oauth2TokenDto oauth2TokenDto = Oauth2TokenDto.builder()
                .token(oAuth2AccessToken.getValue())
                .refreshToken(oAuth2AccessToken.getRefreshToken().getValue())
                .expiresIn(oAuth2AccessToken.getExpiresIn())
                .tokenHead("Bearer ").build();

        return CommonResult.success(oauth2TokenDto);
    }
}
```

再次调用登录认证接口，我们可以发现返回结果已经变成了符合我们通用返回结果的格式了！
![image.png](Oauth2的返回格式和白名单逻辑优化（转载）.assets\425aaddff2e74fb78821694db98b438b.png)

###自定义网关鉴权失败结果
这里有个非常简单的改法，只需添加一行代码，修改网关的安全配置ResourceServerConfig，设置好资源服务器的ServerAuthenticationEntryPoint即可；
```
/**
 * 资源服务器配置
 * Created by macro on 2020/6/19.
 */
@AllArgsConstructor
@Configuration
@EnableWebFluxSecurity
public class ResourceServerConfig {
    private final AuthorizationManager authorizationManager;
    private final IgnoreUrlsConfig ignoreUrlsConfig;
    private final RestfulAccessDeniedHandler restfulAccessDeniedHandler;
    private final RestAuthenticationEntryPoint restAuthenticationEntryPoint;

    @Bean
    public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
        http.oauth2ResourceServer().jwt()
                .jwtAuthenticationConverter(jwtAuthenticationConverter());
        //自定义处理JWT请求头过期或签名错误的结果（新添加的）
        http.oauth2ResourceServer().authenticationEntryPoint(restAuthenticationEntryPoint);
        http.authorizeExchange()
                .pathMatchers(ArrayUtil.toArray(ignoreUrlsConfig.getUrls(),String.class)).permitAll()//白名单配置
                .anyExchange().access(authorizationManager)//鉴权管理器配置
                .and().exceptionHandling()
                .accessDeniedHandler(restfulAccessDeniedHandler)//处理未授权
                .authenticationEntryPoint(restAuthenticationEntryPoint)//处理未认证
                .and().csrf().disable();
        return http.build();
    }
}
```

添加完成后，再次访问需要权限的接口，就会返回我们想要的结果了。
![image.png](Oauth2的返回格式和白名单逻辑优化（转载）.assetse0c0bd6c05a4a5089c33b091bd35b70.png)

###兼容白名单接口
其实对于白名单接口一直有个问题，当携带过期或签名不正确的JWT令牌访问时，会直接返回token过期的结果，明明就是个白名单接口，只不过携带的token不对就不让访问了，显然有点不合理。
其实我们只要在Oauth2默认的认证过滤器前面再加个过滤器，如果是白名单接口，直接移除认证头即可，首先定义好我们的过滤器；
```
/**
 * 白名单路径访问时需要移除JWT请求头
 * Created by macro on 2020/7/24.
 */
@Component
public class IgnoreUrlsRemoveJwtFilter implements WebFilter {
    @Autowired
    private IgnoreUrlsConfig ignoreUrlsConfig;
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, WebFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        URI uri = request.getURI();
        PathMatcher pathMatcher = new AntPathMatcher();
        //白名单路径移除JWT请求头
        List<String> ignoreUrls = ignoreUrlsConfig.getUrls();
        for (String ignoreUrl : ignoreUrls) {
            if (pathMatcher.match(ignoreUrl, uri.getPath())) {
                request = exchange.getRequest().mutate().header("Authorization", "").build();
                exchange = exchange.mutate().request(request).build();
                return chain.filter(exchange);
            }
        }
        return chain.filter(exchange);
    }
}
```

然后把这个过滤器配置到默认的认证过滤器之前即可，在ResourceServerConfig中进行配置；
```
/**
 * 资源服务器配置
 * Created by macro on 2020/6/19.
 */
@AllArgsConstructor
@Configuration
@EnableWebFluxSecurity
public class ResourceServerConfig {
    private final AuthorizationManager authorizationManager;
    private final IgnoreUrlsConfig ignoreUrlsConfig;
    private final RestfulAccessDeniedHandler restfulAccessDeniedHandler;
    private final RestAuthenticationEntryPoint restAuthenticationEntryPoint;
    private final IgnoreUrlsRemoveJwtFilter ignoreUrlsRemoveJwtFilter;

    @Bean
    public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
        http.oauth2ResourceServer().jwt()
                .jwtAuthenticationConverter(jwtAuthenticationConverter());
        //自定义处理JWT请求头过期或签名错误的结果
        http.oauth2ResourceServer().authenticationEntryPoint(restAuthenticationEntryPoint);
        //对白名单路径，直接移除JWT请求头（新添加的）
        http.addFilterBefore(ignoreUrlsRemoveJwtFilter, SecurityWebFiltersOrder.AUTHENTICATION);
        http.authorizeExchange()
                .pathMatchers(ArrayUtil.toArray(ignoreUrlsConfig.getUrls(),String.class)).permitAll()//白名单配置
                .anyExchange().access(authorizationManager)//鉴权管理器配置
                .and().exceptionHandling()
                .accessDeniedHandler(restfulAccessDeniedHandler)//处理未授权
                .authenticationEntryPoint(restAuthenticationEntryPoint)//处理未认证
                .and().csrf().disable();
        return http.build();
    }

}
```
