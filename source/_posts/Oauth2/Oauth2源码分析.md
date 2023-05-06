---
title: Oauth2源码分析
categories:
- Oauth2
---
# 二、授权码模式源码分析
### 2.1 第一次请求/oauth/authorize

请求的完整url如下，有参数client_id,response_type,redirect_uri。
```
http://localhost:9500/oauth/authorize?client_id=c1&response_type=code&scope=ROLE_ADMIN&redirect_uri=http://www.taobao.com
```
这一步时已经完成了用户认证并获取到了UserDetails。
访问**AuthorizationEndPoint**中的/oauth/authorize，里面会判断client信息和用户信息，如果user没有Authentication，则会报错，跳转到ExceptionTranslationFilter类中，请求转发到/login路径，并将现请求路径存储到session的saverequest中。

![1599553678755.png](Oauth2源码分析.assets\44b2b8419f6a4bbf99f5bf4a12622170.png)


```java
@RequestMapping(value = "/oauth/authorize")
public ModelAndView authorize(Map<String, Object> model, @RequestParam Map<String, String> parameters,SessionStatus sessionStatus,Principal principal) {
 
    	//通过参数client_id,response_type,redirect_uri和scope创建AuthorizationRequest
		AuthorizationRequest authorizationRequest = getOAuth2RequestFactory().createAuthorizationRequest(parameters);
 
		Set<String> responseTypes = authorizationRequest.getResponseTypes();
 
		if (!responseTypes.contains("token") && !responseTypes.contains("code")) {
			throw new UnsupportedResponseTypeException("Unsupported response types: " + responseTypes);
		}
                // 判断clientId是否为空
		if (authorizationRequest.getClientId() == null) {
			throw new InvalidClientException("A client id must be provided");
		}
 
		try {
                     // 判断user是否认证，认证失败则跳转到/login路径
			if (!(principal instanceof Authentication) || !((Authentication) principal).isAuthenticated()) {
				throw new InsufficientAuthenticationException(
						"User must be authenticated with Spring Security before authorization can be completed.");
			}
 
                // 验证client信息
			ClientDetails client = getClientDetailsService().loadClientByClientId(authorizationRequest.getClientId());
 
           ...
    }
}
```





### 2.2 ExceptionTranslationFilter

```java
public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
			throws IOException, ServletException {
		HttpServletRequest request = (HttpServletRequest) req;
		HttpServletResponse response = (HttpServletResponse) res;
 
		try {
			chain.doFilter(request, response);
 
			logger.debug("Chain processed normally");
		}
		catch (IOException ex) {
			throw ex;
		}
		catch (Exception ex) {
			// Try to extract a SpringSecurityException from the stacktrace
			Throwable[] causeChain = throwableAnalyzer.determineCauseChain(ex);
			RuntimeException ase = (AuthenticationException) throwableAnalyzer
					.getFirstThrowableOfType(AuthenticationException.class, causeChain);
 
			if (ase == null) {
				ase = (AccessDeniedException) throwableAnalyzer.getFirstThrowableOfType(
						AccessDeniedException.class, causeChain);
			}
 
			if (ase != null) {
                 // 进入到此方法中
				handleSpringSecurityException(request, response, chain, ase);
			}
			...
		}
	}
 
 
 
private void handleSpringSecurityException(HttpServletRequest request,
			HttpServletResponse response, FilterChain chain, RuntimeException exception)
			throws IOException, ServletException {
		if (exception instanceof AuthenticationException) {
			logger.debug(
					"Authentication exception occurred; redirecting to authentication entry point",
					exception);
             // 没有验证身份信息，跳转到/login界面
			sendStartAuthentication(request, response, chain,
					(AuthenticationException) exception);
		}
        ...
}
 
 
protected void sendStartAuthentication(HttpServletRequest request,
			HttpServletResponse response, FilterChain chain,
			AuthenticationException reason) throws ServletException, IOException {
        
		SecurityContextHolder.getContext().setAuthentication(null);
                // 将saveRequest存到session中，方便身份验证成功后调用
		requestCache.saveRequest(request, response);
		logger.debug("Calling Authentication entry point.");
                // 请求重定向到/login
		authenticationEntryPoint.commence(request, response, reason);
}
```



### 2.3 requestCache.saveRequest(request,response)

	requestCache的常用的实现类是HttpSessionRequestCache，一般是访问url时系统判断用户未获得授权，ExceptionTranslationFilter会存储savedRequest到session中，名为“SPRING_SECURITY_SAVED_REQUEST”。

	SavedRequest里面包含原先访问的url地址、cookie、header、parameter等信息，一旦Authentication认证成功，successHandler.onAuthenticationSuccess(SavedRequestAwareAuthenticationSuccessHandler)会从session中抽取savedRequest，继续访问原先的url。

```java
public class HttpSessionRequestCache implements RequestCache {
	static final String SAVED_REQUEST = "SPRING_SECURITY_SAVED_REQUEST";  
  /**
	 * HttpSessionRequestCache Stores the current request, provided the configuration properties allow it.
	 */
	public void saveRequest(HttpServletRequest request, HttpServletResponse response) {
		if (requestMatcher.matches(request)) {
			DefaultSavedRequest savedRequest = new DefaultSavedRequest(request,
					portResolver);
 
			if (createSessionAllowed || request.getSession(false) != null) {
				// Store the HTTP request itself. Used by
				// AbstractAuthenticationProcessingFilter
				// for redirection after successful authentication (SEC-29)
				request.getSession().setAttribute(this.sessionAttrName, savedRequest);
				logger.debug("DefaultSavedRequest added to Session: " + savedRequest);
			}
		}
		else {
			logger.debug("Request not saved as configured RequestMatcher did not match");
		}
	}
}
```



### 2.4 重定向到/login

	由于是第一次访问qq认证服务器，所以需要用户登录校验身份。在WebSecurityConfigurerAdapter的继承类中，找到存储在缓存中的用户名密码，填写完毕。


![1599553813790.png](Oauth2源码分析.assets\3a9ecd9b6bee42c2a2c42bff6613ec19.png)


	点击“Sign In”按钮后，post请求/login路径，按照FilterChainProxy的filter链运行到UsernamePasswordAuthenticationFilter，验证通过后执行successHandler.onAuthenticationSuccess(request, response, authResult)，获取session中的savedrequest，重定向到原先的地址/oauth/authorize，并附带完整请求参数。

```java
public class SavedRequestAwareAuthenticationSuccessHandler extends
		SimpleUrlAuthenticationSuccessHandler {
	protected final Log logger = LogFactory.getLog(this.getClass());
 
	private RequestCache requestCache = new HttpSessionRequestCache();
 
	@Override
	public void onAuthenticationSuccess(HttpServletRequest request,
			HttpServletResponse response, Authentication authentication)
			throws ServletException, IOException {
             // HttpSessionRequestCache.getRequest ,找名为SPRING_SECURITY_SAVED_REQUEST的session
		SavedRequest savedRequest = requestCache.getRequest(request, response);
 
		if (savedRequest == null) {
			super.onAuthenticationSuccess(request, response, authentication);
 
			return;
		}
		String targetUrlParameter = getTargetUrlParameter();
		if (isAlwaysUseDefaultTargetUrl()
				|| (targetUrlParameter != null && StringUtils.hasText(request
						.getParameter(targetUrlParameter)))) {
			requestCache.removeRequest(request, response);
			super.onAuthenticationSuccess(request, response, authentication);
 
			return;
		}
 
		clearAuthenticationAttributes(request);
 
		// Use the DefaultSavedRequest URL
           // 获得原先存储在SavedRequest中的redirectUrl,即/oauth/authorize
		String targetUrl = savedRequest.getRedirectUrl();
		logger.debug("Redirecting to DefaultSavedRequest Url: " + targetUrl);
		getRedirectStrategy().sendRedirect(request, response, targetUrl);
	}
 
	public void setRequestCache(RequestCache requestCache) {
		this.requestCache = requestCache;
	}
}
```



### 2.5 第二次请求/oauth/authorize

	这次请求就硬气多了，请求中携带了Authentication的session，系统验证通过，生成授权码，存储在InMemoryAuthorizationCodeServices中的concurrenthashmap中，且返回给请求参数中的redirect_uri，即http://localhost:8081/aiqiyi/qq/redirect。

```
http://localhost:8080/oauth/authorize?client_id=aiqiyi&response_type=code&redirect_uri=http://localhost:8081/aiqiyi/qq/redirect
```

```java
@RequestMapping(value = "/oauth/authorize")
	public ModelAndView authorize(Map<String, Object> model, @RequestParam Map<String, String> parameters,
			SessionStatus sessionStatus, Principal principal) {
                ...
            if (authorizationRequest.isApproved()) {
				if (responseTypes.contains("token")) {
					return getImplicitGrantResponse(authorizationRequest);
				}
				if (responseTypes.contains("code")) {
                    // 返回code给redirect_uri
					return new ModelAndView(getAuthorizationCodeResponse(authorizationRequest,
							(Authentication) principal));
				}
			}
                ...
}
```



```java
public class InMemoryAuthorizationCodeServices extends RandomValueAuthorizationCodeServices {
 
	protected final ConcurrentHashMap<String, OAuth2Authentication> authorizationCodeStore = new ConcurrentHashMap<String, OAuth2Authentication>();
 
	@Override
	protected void store(String code, OAuth2Authentication authentication) {
		this.authorizationCodeStore.put(code, authentication);
	}
 
	@Override
	public OAuth2Authentication remove(String code) {
		OAuth2Authentication auth = this.authorizationCodeStore.remove(code);
		return auth;
	}
 
}
```


>到了这里我们总结下刚才都发生了什么。首先aiqiyi向qq发出/oauth/authorize的请求，qq服务器的AuthorizationEndPoint判断用户是否登录，如果没有登录则先跳转到/login界面，同时存储首次request的信息，保存在session中。用户登录并授权后，程序自动获取刚存储在session中的savedrequest，再次访问/oauth/authorize。验证client信息和user信息成功后，重定向到redirect_uri，并传参数code。



### 2.6 client接收code并向oauth server请求/oauth/token

	以下代码自行写在client的controller里，用于接收qq服务端传递来的code，并请求/oauth/token。

```java
	@RequestMapping("/aiqiyi/qq/redirect")
    public String getToken(@RequestParam String code){
        log.info("receive code {}",code);
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        MultiValueMap<String, String> params= new LinkedMultiValueMap<>();
        params.add("grant_type","authorization_code");
        params.add("code",code);
        params.add("client_id","aiqiyi");
        params.add("client_secret","secret");
        params.add("redirect_uri","http://localhost:8081/aiqiyi/qq/redirect");
        HttpEntity<MultiValueMap<String, String>> requestEntity = new HttpEntity<>(params, headers);
        ResponseEntity<String> response = restTemplate.postForEntity("http://localhost:8080/oauth/token", requestEntity, String.class);
        String token = response.getBody();
        log.info("token => {}",token);
        return token;
    }
```



### 2.7 TokenEndPoint生成access_token

具体代码在上一章已介绍，这里不做详述。注意的是会从InMemoryAuthorizationCodeServices中提取hashmap验证code是否正确。

## 3 总结

![Snipaste_2020-09-08_16-34-58.jpg](Oauth2源码分析.assets\9777fc32f9ec44128ad1e618fc89d222.png)


<br>
<br>
# 三、密码模式源码分析

## 1.访问/oauth/token

	此时FilterChainProxy的filter顺序如下。重要的Filter有**ClientCredentialsTokenEndpointFilter**和**BasicAuthenticationFilter**，前者从request parameters中抽取client信息，后者从header Authorization Basic XXXX中抽取client信息。

![image.png](Oauth2源码分析.assets\703038b7d682492ea024073b4ea6cc05.png)


	启动项目，程序自动会启动几个endpoints，如/oauth/token,/oauth/authorize等。

### 1.1 parameters

**ClientCredentialsTokenEndpointFilter**会从parameter中抽取client_id,client_secret信息，并进行client的身份验证。

> localhost:8080/oauth/token?username=250577914&password=123456&grant_type=password&client_id=aiqiyi&client_secret=secret

![img](Oauth2源码分析.assets\d921821306c2401a91ca156f2335b3d9.png)

```java
    /**
     * 验证请求方式，
     **/
	@Override
	public Authentication attemptAuthentication(HttpServletRequest request, HttpServletResponse response) throws AuthenticationException, IOException, ServletException {
 
		if (allowOnlyPost && !"POST".equalsIgnoreCase(request.getMethod())) {
			throw new HttpRequestMethodNotSupportedException(request.getMethod(), new String[] { "POST" });
		}
 
		String clientId = request.getParameter("client_id");
		String clientSecret = request.getParameter("client_secret");
 
		// 如果用户已经完成认证，那么不需要再执行该过滤器。否则对客户端信息进行认证。
		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
		if (authentication != null && authentication.isAuthenticated()) {
			return authentication;
		}
 
		if (clientId == null) {
			throw new BadCredentialsException("No client credentials presented");
		}
 
		if (clientSecret == null) {
			clientSecret = "";
		}
 
		clientId = clientId.trim();
		UsernamePasswordAuthenticationToken authRequest = new UsernamePasswordAuthenticationToken(clientId,clientSecret);
 
        //如果该请求没有进行过认证，将clientId和clientSecret构建token进行认证。
		return this.getAuthenticationManager().authenticate(authRequest);
 
	}
```



### 1.2 Basic Auth

	Postman发送请求如下，Basic Auth中填写client_id和client_secret信息。点击update requests后，postman会将client信息用base64加密，写在header——Authorization中。

![img](Oauth2源码分析.assets\93ad02f7390646c8bd72419abf8fe712.png)

![img](Oauth2源码分析.assets\18bf314198ce4e60bbe8a70a80c00bbc.png)

	这样一来，**ClientCredentialsTokenEndpointFilter**会由于参数中没有client_id自动跳过。**BasicAuthenticationFilter**会获取header中的Authorization Basic，提取出客户端信息。

```java
	@Override
	protected void doFilterInternal(HttpServletRequest request,
			HttpServletResponse response, FilterChain chain)
					throws IOException, ServletException {
		final boolean debug = this.logger.isDebugEnabled();
 
		String header = request.getHeader("Authorization");
 
		if (header == null || !header.startsWith("Basic ")) {
			chain.doFilter(request, response);
			return;
		}
 
		try {
            // Base64 反解码
			String[] tokens = extractAndDecodeHeader(header, request);
			assert tokens.length == 2;
 
			String username = tokens[0];
 
 
			if (authenticationIsRequired(username)) {
				UsernamePasswordAuthenticationToken authRequest = new UsernamePasswordAuthenticationToken(
						username, tokens[1]);
				authRequest.setDetails(
						this.authenticationDetailsSource.buildDetails(request));
				Authentication authResult = this.authenticationManager
						.authenticate(authRequest);
 
		
 
				SecurityContextHolder.getContext().setAuthentication(authResult);
 
				this.rememberMeServices.loginSuccess(request, response, authResult);
 				//空方法，可以重写该方法记录用户的登录情况
				onSuccessfulAuthentication(request, response, authResult);
			}
 
		}
		catch (AuthenticationException failed) {
			 ...
		}
 
		chain.doFilter(request, response);
	}
```

	无论是哪一种方式访问/oauth/token，都事先验证了client信息，并作为authentication存储在SecurityContextHolder中。传递到TokenEndPoint的principal是client，paramters包含了user的信息和grantType。

![](Oauth2源码分析.assets\77e29aa06c1b403b8d6e2e53ab9ecbad.png)



<br>
## 2. 携带Access_token访问api

### 2.1 access_token放在parameter中

	OAuth2AuthenticationProcessingFilter，从request中提取access_token，构建PreAuthenticatedAuthenticationToken并验证。

```java
	public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) throws IOException,ServletException {
 
		final boolean debug = logger.isDebugEnabled();
		final HttpServletRequest request = (HttpServletRequest) req;
		final HttpServletResponse response = (HttpServletResponse) res;
 
		try {
            //extract方法从request中提取access_token并构建PreAuthenticatedAuthenticationToken
			Authentication authentication = tokenExtractor.extract(request);
			
			if (authentication == null) {
				if (stateless && isAuthenticated()) {
					SecurityContextHolder.clearContext();
				}
				
			}
			else {
				request.setAttribute(OAuth2AuthenticationDetails.ACCESS_TOKEN_VALUE, authentication.getPrincipal());
				if (authentication instanceof AbstractAuthenticationToken) {
					AbstractAuthenticationToken needsDetails = (AbstractAuthenticationToken) authentication;
					needsDetails.setDetails(authenticationDetailsSource.buildDetails(request));
				}
 
                // OAuth2AuthenticationManager验证PreAuthenticatedAuthenticationToken
				Authentication authResult = authenticationManager.authenticate(authentication);
 
				
				eventPublisher.publishAuthenticationSuccess(authResult);
				SecurityContextHolder.getContext().setAuthentication(authResult);
 
			}
		}
		catch (OAuth2Exception failed) {
			SecurityContextHolder.clearContext();
 
			eventPublisher.publishAuthenticationFailure(new BadCredentialsException(failed.getMessage(), failed),
					new PreAuthenticatedAuthenticationToken("access-token", "N/A"));
 
			authenticationEntryPoint.commence(request, response,
					new InsufficientAuthenticationException(failed.getMessage(), failed));
 
			return;
		}
 
		chain.doFilter(request, response);
	}
```

	tokenExtractor.extract(request)实际调用的是**BearTokenExtractor**里的extract方法，从Authorization header   “Bearer  xxxx”中抽取token，或者从request parameters抽取名为“access_token”的参数值。

```java
	@Override
	public Authentication extract(HttpServletRequest request) {
		String tokenValue = extractToken(request);
		if (tokenValue != null) {
                          // 记为PreAuthenticatedAuthenticationToken
			PreAuthenticatedAuthenticationToken authentication = new PreAuthenticatedAuthenticationToken(tokenValue, "");
			return authentication;
		}
		return null;
	}
```

	 构建后的authentication参数如
下，tokenType="Bearer"，principal=token值。再根据**OAuth2AuthenticationManager**验证该authentication的合法性。

![Snipaste_2020-09-08_16-14-32.jpg](Oauth2源码分析.assets9f944ac8104457b83054d79eb913937.png)


<br>
### 2.2 access_token存于header中

	postman发送如下请求，将access_token写在Authorization的header里，前缀是Bearer。

![Snipaste_2020-09-08_16-15-06.jpg](Oauth2源码分析.assets\9b58dd3ded114e2c9b733a32f4a4d314.png)


	同样是OAuth2AuthenticationProcessingFilter拦截，从request header中提取token，记为PreAuthenticatedAuthenticationToken，用OAuth2AuthenticationManager进行验证。



## 3. 访问/oauth/check_token

	当oauthserver和resourceserver不在一个应用程序时，访问resource，会自动转交到oauthserver的/oauth/check_token，获得access_token的验证结果。

### 3.1 配置ResouceServer

配置application.yml

```yml
server:
  port: 8081
security:
  oauth2:
    client:
      client-id: aiqiyi
      client-secret: secret
      access-token-uri: http://localhost:8080/oauth/token
      user-authorization-uri: http://localhost:8080/oauth/authorize
      user-logout-uri: http://localhost:8080/oauth/logout
    resource:
      id: qq
      token-info-uri: http://localhost:8080/oauth/check_token
      prefer-token-info: true
      filter-order: 3
  basic:
    enabled: false
```



配置ResouceServerConfigurerAdapter

```java
@Configuration
@EnableResourceServer
@Order(SecurityProperties.ACCESS_OVERRIDE_ORDER)
public class ResourceServerConfig extends ResourceServerConfigurerAdapter {
 
	@Value("${security.oauth2.resource.id}")
	public String RESOURCE_ID;
 
 
 
	@Autowired
    public RemoteTokenServices remoteTokenServices;
	
	@Override
	public void configure(ResourceServerSecurityConfigurer resources) throws Exception {
        // 存入resource_id，到时候与oauthserver中client对应的resourceid进行比对
		resources.resourceId(RESOURCE_ID).stateless(true);
		resources.tokenServices(remoteTokenServices);
	}
}
```




<br>
## /oauth/token流程

### TokenEndpoint
```java
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

        //获取token
		OAuth2AccessToken token = getTokenGranter().grant(tokenRequest.getGrantType(), tokenRequest);
		if (token == null) {
			throw new UnsupportedGrantTypeException("Unsupported grant type: " + tokenRequest.getGrantType());
		}

		return getResponse(token);

	}
```

![image.png](Oauth2源码分析.assets\7fdbe11b09b748529f8ddb5b01d4f96f.png)


1. 请求TokenEndpoint类的/oauth/token接口，参数为Map(存储grant_type、username、password)和Principal(已认证的Authentication对象)
2. 接口从参数Principal中获取clientId
3. 根据clientId调用loadClientByClientId方法从数据库中获取客户端对象
4. 根据获取的客户端对象构建TokenRequest对象(如果parameter中没有scope，则将数据库中查询到的scope；将parameter、clientId、scopes和grantType作为参数构建TokenRequest)
5. 遍历TokenRequest中的scope(从数据库查询得到)与从数据获取的scopes进行对比，判断当前请求是否有scope权限。？？？
6. 通过getTokenGranter方法创建TokenGranter并重写了其中的grant方法。代码如下。
```java
//AuthorizationServerEndpointsConfigurer类的getTokenStore和TokenGranter方法
    public TokenStore getTokenStore() {
		return tokenStore();
	}
	private TokenGranter tokenGranter() {
		if (tokenGranter == null) {
			tokenGranter = new TokenGranter() {
				private CompositeTokenGranter delegate;

				@Override
				public OAuth2AccessToken grant(String grantType, TokenRequest tokenRequest) {
					if (delegate == null) {
						delegate = new CompositeTokenGranter(getDefaultTokenGranters());
					}
					return delegate.grant(grantType, tokenRequest);
				}
			};
		}
		return tokenGranter;
	}
```
调用grant方法会对tokenGranters列表(存储了5种TokenGranter)进行遍历，如果不符合grantType参数会返回null，直到找到符合grantType参数的TokenGranter(grantType为**password**，对应**ResourceOwnerPasswordTokenGranter**)，并调用grant方法生成并返回OAuth2AccessToken。代码如下。
```java
//CompositeTokenGranter类的grant方法
	public OAuth2AccessToken grant(String grantType, TokenRequest tokenRequest) {
		for (TokenGranter granter : tokenGranters) {
			OAuth2AccessToken grant = granter.grant(grantType, tokenRequest);
			if (grant!=null) {
				return grant;
			}
		}
		return null;
	}
```
在grant方法中对client的信息进行校验，然后调用getAccessToken方法获取token。代码如下。
```java
//AbstractTokenGranter的grant和getAccessToken方法
	public OAuth2AccessToken grant(String grantType, TokenRequest tokenRequest) {

		if (!this.grantType.equals(grantType)) { //this.grantType: "authorization_code"，grantType: "password"
			return null;
		}
		
		String clientId = tokenRequest.getClientId();
		ClientDetails client = clientDetailsService.loadClientByClientId(clientId);
		validateGrantType(grantType, client);

		if (logger.isDebugEnabled()) {
			logger.debug("Getting access token for: " + clientId);
		}

		return getAccessToken(client, tokenRequest);

	}

	protected OAuth2AccessToken getAccessToken(ClientDetails client, TokenRequest tokenRequest) {
		return tokenServices.createAccessToken(getOAuth2Authentication(client, tokenRequest));
	}
```
在getAccessToken方法中调用了DefaultTokenServices(ResourceOwnerPasswordTokenGranter中的属性)的createAccessToken方法。其中参数为getOAuth2Authentication方法返回的OAuth2Authentication对象。首先来看getOAuth2Authentication方法，ResourceOwnerPasswordTokenGranter重写了父类的方法(这就是需要选择合适的TokenGranter类的原因)。代码如下。
```java
//ResourceOwnerPasswordTokenGranter类的getOAuth2Authentication方法
	@Override
	protected OAuth2Authentication getOAuth2Authentication(ClientDetails client, TokenRequest tokenRequest) {

		Map<String, String> parameters = new LinkedHashMap<String, String>(tokenRequest.getRequestParameters());
		String username = parameters.get("username");
		String password = parameters.get("password");
		// Protect from downstream leaks of password
		parameters.remove("password");

		Authentication userAuth = new UsernamePasswordAuthenticationToken(username, password);
		((AbstractAuthenticationToken) userAuth).setDetails(parameters);
		try {
			userAuth = authenticationManager.authenticate(userAuth);
		}
		catch (AccountStatusException ase) {
			//covers expired, locked, disabled cases (mentioned in section 5.2, draft 31)
			throw new InvalidGrantException(ase.getMessage());
		}
		catch (BadCredentialsException e) {
			// If the username/password are wrong the spec says we should send 400/invalid grant
			throw new InvalidGrantException(e.getMessage());
		}
		if (userAuth == null || !userAuth.isAuthenticated()) {
			throw new InvalidGrantException("Could not authenticate user: " + username);
		}
		
		OAuth2Request storedOAuth2Request = getRequestFactory().createOAuth2Request(client, tokenRequest);		
		return new OAuth2Authentication(storedOAuth2Request, userAuth);
	}
```
createAccessToken方法以OAuth2Authentication 作为参数，先从tokenStore中获取AccessToken，如果为null，则创建OAuth2RefreshToken，然后创建DefaultOAuth2AccessToken，并放入OAuth2RefreshToken和scope。然后将OAuth2AccessToken和OAuth2RefreshToken存储到TokenStore中。最终返回通过TokenEnhancer的enhance方法加强后的OAuth2AccessToken。
代码如下。
```java
//DefaultTokenServices类的createAccessToken方法
	@Transactional
	public OAuth2AccessToken createAccessToken(OAuth2Authentication authentication) throws AuthenticationException {

		OAuth2AccessToken existingAccessToken = tokenStore.getAccessToken(authentication);
		OAuth2RefreshToken refreshToken = null;
		if (existingAccessToken != null) {
			if (existingAccessToken.isExpired()) {
				if (existingAccessToken.getRefreshToken() != null) {
					refreshToken = existingAccessToken.getRefreshToken();
					// The token store could remove the refresh token when the
					// access token is removed, but we want to
					// be sure...
					tokenStore.removeRefreshToken(refreshToken);
				}
				tokenStore.removeAccessToken(existingAccessToken);
			}
			else {
				// Re-store the access token in case the authentication has changed
				tokenStore.storeAccessToken(existingAccessToken, authentication);
				return existingAccessToken;
			}
		}

		// Only create a new refresh token if there wasn't an existing one
		// associated with an expired access token.
		// Clients might be holding existing refresh tokens, so we re-use it in
		// the case that the old access token
		// expired.
		if (refreshToken == null) {
			refreshToken = createRefreshToken(authentication);
		}
		// But the refresh token itself might need to be re-issued if it has
		// expired.
		else if (refreshToken instanceof ExpiringOAuth2RefreshToken) {
			ExpiringOAuth2RefreshToken expiring = (ExpiringOAuth2RefreshToken) refreshToken;
			if (System.currentTimeMillis() > expiring.getExpiration().getTime()) {
				refreshToken = createRefreshToken(authentication);
			}
		}

		OAuth2AccessToken accessToken = createAccessToken(authentication, refreshToken);
		tokenStore.storeAccessToken(accessToken, authentication);
		// In case it was modified
		refreshToken = accessToken.getRefreshToken();
		if (refreshToken != null) {
			tokenStore.storeRefreshToken(refreshToken, authentication);
		}
		return accessToken;

	}

	@Transactional(noRollbackFor={InvalidTokenException.class, InvalidGrantException.class})
	public OAuth2AccessToken refreshAccessToken(String refreshTokenValue, TokenRequest tokenRequest) throws AuthenticationException {
        ......
	}

	private OAuth2AccessToken createAccessToken(OAuth2Authentication authentication, OAuth2RefreshToken refreshToken) {
		DefaultOAuth2AccessToken token = new DefaultOAuth2AccessToken(UUID.randomUUID().toString());
		int validitySeconds = getAccessTokenValiditySeconds(authentication.getOAuth2Request());
		if (validitySeconds > 0) {
			token.setExpiration(new Date(System.currentTimeMillis() + (validitySeconds * 1000L)));
		}
		token.setRefreshToken(refreshToken);
		token.setScope(authentication.getOAuth2Request().getScope());

        //如果存在TokenEnhancer，那么对token进行加强
		return accessTokenEnhancer != null ? accessTokenEnhancer.enhance(token, authentication) : token;
	}

	private OAuth2RefreshToken createRefreshToken(OAuth2Authentication authentication) {
		if (!isSupportRefreshToken(authentication.getOAuth2Request())) {
			return null;
		}
		int validitySeconds = getRefreshTokenValiditySeconds(authentication.getOAuth2Request());
		String value = UUID.randomUUID().toString();
		if (validitySeconds > 0) {
			return new DefaultExpiringOAuth2RefreshToken(value, new Date(System.currentTimeMillis()
					+ (validitySeconds * 1000L)));
		}
		return new DefaultOAuth2RefreshToken(value);
	}
```
如果TokenEnhancer存在，那么对OAuth2AccessToken进行加强。**可以通过对TokenStore进行配置来实现OAuth2AccessToken的加强。如下。**
```java
  @Bean
    public TokenStore tokenStore() {
        return new JwtTokenStore(accessTokenConverter());
    }
    @Bean
    public JwtAccessTokenConverter accessTokenConverter() {
        JwtAccessTokenConverter converter = new JwtAccessTokenConverter();
        return converter;
    }

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
上述代码配置了JwtAccessTokenConverter，所以使用该类中的enhance方法对OAuth2AccessToken进行加强，返回的还是OAuth2AccessToken对象。
加强后的OAuth2AccessToken 将原始的accessToken作为JTI，
```java
//JwtAccessTokenConverter中的enhance方法
	public OAuth2AccessToken enhance(OAuth2AccessToken accessToken, OAuth2Authentication authentication) {
		DefaultOAuth2AccessToken result = new DefaultOAuth2AccessToken(accessToken);
		Map<String, Object> info = new LinkedHashMap<String, Object>(accessToken.getAdditionalInformation());
		String tokenId = result.getValue();
		if (!info.containsKey(TOKEN_ID)) {
			info.put(TOKEN_ID, tokenId);
		}
		else {
			tokenId = (String) info.get(TOKEN_ID);
		}
		result.setAdditionalInformation(info);
		result.setValue(encode(result, authentication));
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
			}
			catch (IllegalArgumentException e) {
			}
			Map<String, Object> refreshTokenInfo = new LinkedHashMap<String, Object>(
					accessToken.getAdditionalInformation());
			refreshTokenInfo.put(TOKEN_ID, encodedRefreshToken.getValue());
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
		}
		return result;
	}

	protected String encode(OAuth2AccessToken accessToken, OAuth2Authentication authentication) {
		String content;
		try {
			content = objectMapper.formatMap(tokenConverter.convertAccessToken(accessToken, authentication));
		}
		catch (Exception e) {
			throw new IllegalStateException("Cannot convert access token to JSON", e);
		}
		String token = JwtHelper.encode(content, signer).getEncoded();
		return token;
	}
```

**原始token和加强token对比**
![原始token](Oauth2源码分析.assets\12328b3e22ac4b76b25776a3a1258752.png)

![加强token](Oauth2源码分析.assets\1608721ffb724fb2a4412d70c909fa4d.png)

**最终得到token**
>{
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicmVzMSJdLCJ1c2VyX25hbWUiOiJ7XCJwaG9uZVwiOlwiMTU4ODg4ODg4ODhcIixcImlkXCI6MzcsXCJlbWFpbFwiOlwibGVlLmx1c2lmZXJAZ21haWwuY29tXCIsXCJ1c2VybmFtZVwiOlwiYWRtaW5cIn0iLCJzY29wZSI6WyJST0xFX0FETUlOIl0sImV4cCI6MTU5OTYzNDUzNiwiYXV0aG9yaXRpZXMiOlsiL2NvbnRlbnRzLyIsIi9jb250ZW50cy92aWV3LyoqIiwiL3VzZXJzLyIsIi91c2Vycy91cGRhdGUvKioiLCIvY29udGVudHMvdXBkYXRlLyoqIiwiUk9MRV9hZG1pbiIsIi91c2Vycy92aWV3LyoqIiwiL3VzZXJzL2luc2VydC8qKiIsIi9jb250ZW50cy9kZWxldGUvKioiLCIvY29udGVudHMvaW5zZXJ0LyoqIiwiL3VzZXJzL2RlbGV0ZS8qKiIsIi8iXSwianRpIjoiOGM3MDExMmYtYWVlZS00MzU5LTljMGMtNTc0NWZkZDcyZmZmIiwiY2xpZW50X2lkIjoiYzEifQ.VpI5o3U2Qk80HktHuDjXdvFDIvskSiUxV0kQmJgYF_k",
    "token_type": "bearer",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOlsicmVzMSJdLCJ1c2VyX25hbWUiOiJ7XCJwaG9uZVwiOlwiMTU4ODg4ODg4ODhcIixcImlkXCI6MzcsXCJlbWFpbFwiOlwibGVlLmx1c2lmZXJAZ21haWwuY29tXCIsXCJ1c2VybmFtZVwiOlwiYWRtaW5cIn0iLCJzY29wZSI6WyJST0xFX0FETUlOIl0sImF0aSI6IjhjNzAxMTJmLWFlZWUtNDM1OS05YzBjLTU3NDVmZGQ3MmZmZiIsImV4cCI6MTU5OTY0ODkzNiwiYXV0aG9yaXRpZXMiOlsiL2NvbnRlbnRzLyIsIi9jb250ZW50cy92aWV3LyoqIiwiL3VzZXJzLyIsIi91c2Vycy91cGRhdGUvKioiLCIvY29udGVudHMvdXBkYXRlLyoqIiwiUk9MRV9hZG1pbiIsIi91c2Vycy92aWV3LyoqIiwiL3VzZXJzL2luc2VydC8qKiIsIi9jb250ZW50cy9kZWxldGUvKioiLCIvY29udGVudHMvaW5zZXJ0LyoqIiwiL3VzZXJzL2RlbGV0ZS8qKiIsIi8iXSwianRpIjoiNDA0MmM3YzMtMDFiMi00ZjE2LWJlODktNTA2YWRhMDIwODM0IiwiY2xpZW50X2lkIjoiYzEifQ.myCOpcWbLmxE_jVEzKDwVLFpK8OizCet56lqCMSCIW8",
    "expires_in": 3044,
    "scope": "ROLE_ADMIN",
    "jti": "8c70112f-aeee-4359-9c0c-5745fdd72fff"
}

<br>
密码模式最终是在DefaultTokenServices类的createAccessToken方法中生成token和refreshToken，最终返回OAuth2AccessToken对象。
