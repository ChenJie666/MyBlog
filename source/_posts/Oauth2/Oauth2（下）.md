---
title: Oauth2（下）
categories:
- Oauth2
---

# 四、优化

**优化点如下：**

1. **兼容性问题：**
   - 因为既要兼容原始登陆模块，又要兼容新建的管理员模块，所以需要判断是原始用户还是管理员用户。
   - 验证token时需要判断是认证服务颁发的令牌还是老登陆系统颁发的令牌并分别验证。
2. **分布式问题：**ExceptionTransactionFilter中将request请求信息保存到session中，如果是分布式部署，会有访问不到session的问题发生。
3. **异常返回问题：**资源服务器自定义异常返回。



## 4.1 兼容性优化

### 生成令牌

**逻辑**

1. 音箱作为第三方需要通过授权码模式获取令牌，携带令牌访问资源(用户信息在原始的登陆模块中)，校验账号密码时还需要分两种情况如下
   - 密码登陆
   - 验证码登陆
2. 管理员需要通过密码模式获取令牌(管理员信息在新建的内部用户模块中)



**关键点**
需要判断账号密码属于原始用户的还是管理员的，当然后端无法判断，所以可以让登录页面发送请求时主动携带标识位，后端通过该标识位来判断。如内部管理系统登陆页面，在页面代码中发送请求时多带上一个标识位参数。



**代码**

先写一个枚举类记录所有的类型

```java
public enum UserTypeEnum {

    ADMIN(1,"admin","管理员登录"),
    HIFUN_USERNAME(2,"hifun_username","用户账号密码登录"),
    HIFUN_PHONE(3,"hifun_phone","用户手机验证码登录");

    Integer code;
    String codeText;
    String description;

    UserTypeEnum(Integer code, String codeText, String description) {
        this.code = code;
        this.codeText = codeText;
        this.description = description;
    }

    public Integer getCode() {
        return code;
    }

    public String getCodeText() {
        return codeText;
    }

    public String getDescription(){
        return description;
    }

}
```

> 注：手机验证码是通过第三方平台接口来做的，用户相关的登陆最终都会调用原有的用户系统的接口进行验证。

通过Feign来调用用户系统的接口

```java
@FeignClient(name = "hifun-service-user")
public interface HifunFeign {

    /**
     * 验证密码
     *
     * @param id
     * @param password
     * @return
     */
    @PostMapping(path = "/password/check", consumes = "application/json")
    String check(@RequestParam("id") Integer id, @RequestBody String password);

    /**
     * 根据手机号获取用户信息
     *
     * @param mobile
     * @return
     */
    @GetMapping(path = "/user/mobile")
    String mobile(@RequestParam("mobile") String mobile);


    /**
     * 极验初始化接口
     *
     * @param clientType
     * @param ip
     * @param smsType
     * @return
     */
    @GetMapping(path = "/geetest")
    String geetest(@RequestParam("clientType") String clientType, @RequestParam("ip") Integer ip, @RequestParam("smsType") String smsType);

    /**
     * 极验二次验证并发送短信验证码
     *
     * @param geetestPO
     * @return
     */
    @PostMapping(path = "/geetest")
    String geetest(@RequestBody GeetestPO geetestPO);

    /**
     * 校验手机和验证码是否正确
     *
     * @return
     */
    @PostMapping(path = "/login/code")
    String code(@RequestBody CodePO codePO);

    @PostMapping(path = "/password/findPassword")
    void findPassword(@RequestBody PasswordPO passwordPO);

}
```



重写MyUserDetailsServer类中的loadUserByUsername方法

```java
@Service
@Slf4j
public class MyUserDetailsServer implements UserDetailsService {

    @Resource
    private HifunFeign hifunFeign;

    @Resource
    private UserCenterFeign userCenterFeign;

    @Resource
    private HttpServletRequest httpServletRequest;

    /**
     * 将账号密码和权限信息封装到UserDetails对象中返回
     *
     * @param username
     * @return
     * @throws UsernameNotFoundException
     */
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
//        String userType = httpServletRequest.getHeader("User-Type");
        String userType = httpServletRequest.getParameter("user_type");
        System.out.println("*****loadUserByUsername  userType:" + userType);

        //查询数据库获取用户的信息
        if (UserTypeEnum.ADMIN.getCodeText().equals(userType)) {
            // 1.请求头是admin，查询到管理人员数据库
            TbUserPO tbUser = userCenterFeign.getTbUser(username);
            Assert.isTrue(!Objects.isNull(tbUser), "管理员不存在");
            //将用户信息添加到token中
//            UserInfoDTO userInfo = BeanUtil.copyProperties(tbUser, UserInfoDTO.class);
//            JSONObject userObj = new JSONObject(userInfo);
//            String userStr = userObj.toString();
            tbUser.setUsername(tbUser.getId().toString());
            //获取用户的角色和权限
            List<String> roleCodes = userCenterFeign.getRoleCodes(username);
            List<String> authorities = userCenterFeign.getAuthorities(roleCodes);

            //将用户角色添加到用户权限中
            authorities.addAll(roleCodes);

            //设置UserDetails中的authorities属性，需要将String类型转换为GrantedAuthority
            MyUserDetails myUserDetails = BeanUtil.copyProperties(tbUser, MyUserDetails.class);
            myUserDetails.setAuthorities(AuthorityUtils.commaSeparatedStringToAuthorityList(String.join(",", authorities)));

            log.info("UserDetail:" + myUserDetails);
            return myUserDetails;
        } else if (UserTypeEnum.HIFUN_PHONE.getCodeText().equals(userType)) {
            // 2.请求头是hifun_phone，查询火粉的用户中心
//            String userInfo;
//            try {
//                userInfo = hifunFeign.mobile(username);
//            } catch (Exception e) {
//                throw new IllegalArgumentException("该用户不存在");
//            }
//            JSONObject jsonObject = new JSONObject(userInfo);
//            Integer id = jsonObject.getInt("id");

            return new MyUserDetails().setUsername(username).setPassword("hifun")
                    .setAuthorities(AuthorityUtils.commaSeparatedStringToAuthorityList(String.join(",", "hifun")))
                    .setAccountNonExpired(true)
                    .setAccountNonLocked(true)
                    .setCredentialsNonExpired(true)
                    .setEnabled(true);

            //这个User对象是校验client的账号密码时使用的，expire、lock等信息自动填充为true
//            return new User(id.toString(), "hifun", AuthorityUtils.commaSeparatedStringToAuthorityList(String.join(",", "hifun")));
        } else if (UserTypeEnum.HIFUN_USERNAME.getCodeText().equals(userType)) {
            String userInfo;
            try {
                userInfo = hifunFeign.mobile(username);
            } catch (Exception e) {
                throw new IllegalArgumentException("该用户不存在");
            }
            JSONObject jsonObject = new JSONObject(userInfo);
            Integer id = jsonObject.getInt("id");

            return new User(id.toString(), "hifun", AuthorityUtils.commaSeparatedStringToAuthorityList(String.join(",", "hifun")));
        }
//        else {
//            return new User("test", "hifun", AuthorityUtils.commaSeparatedStringToAuthorityList(String.join(",", "hifun")));
//        }
        throw new IllegalArgumentException("未传递用户类型或用户类型不存在");
    }
}
```

重写DaoAuthenticationProvider类中的additionalAuthenticationChecks方法

```java
@Component
public class MyDaoAuthenticationProvider extends DaoAuthenticationProvider {

    @Resource
    private HifunFeign hifunFeign;

    @Resource
    private BCryptPasswordEncoder bCryptPasswordEncoder;


    public MyDaoAuthenticationProvider(UserDetailsService userDetailsService) {
        super();
        // 这个地方一定要对userDetailsService赋值，不然userDetailsService是null
        setUserDetailsService(userDetailsService);
    }

    @Override
    protected void additionalAuthenticationChecks(UserDetails userDetails, UsernamePasswordAuthenticationToken authentication) throws AuthenticationException {
        ServletRequestAttributes requestAttributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        assert requestAttributes != null;
        HttpServletRequest httpServletRequest = requestAttributes.getRequest();
        HttpServletResponse httpServletResponse = requestAttributes.getResponse();

        String presentedPassword = authentication.getCredentials().toString();

//        Cookie[] cookies = httpServletRequest.getCookies();
//        for (Cookie cookie : cookies) {
//            System.out.println("*****cookie:" + cookie.getName());
//            cookie.setMaxAge(0);
//            cookie.setPath("/");
//            assert httpServletResponse != null;
//            httpServletResponse.addCookie(cookie);
//        }

        String userType = httpServletRequest.getParameter("user_type");
        System.out.println("*****additionalAuthenticationChecks userType:" + userType);

        if (authentication.getCredentials() == null) {
            logger.debug("Authentication failed: no credentials provided");

            throw new BadCredentialsException(messages.getMessage(
                    "AbstractUserDetailsAuthenticationProvider.badCredentials",
                    "Bad credentials"));
        }


        // TODO 根据请求头的用户类型进行查询
        if (UserTypeEnum.ADMIN.getCodeText().equals(userType)) {
            // 1.请求头是admin，查询到管理人员数据库
            System.out.println("user_type是admin，查询到管理人员数据库");
            if (!bCryptPasswordEncoder.matches(presentedPassword, userDetails.getPassword())) {
                logger.debug("Authentication failed: password does not match stored value");

                throw new BadCredentialsException(messages.getMessage(
                        "AbstractUserDetailsAuthenticationProvider.badCredentials",
                        "Bad credentials"));
            }
        } else if (UserTypeEnum.HIFUN_PHONE.getCodeText().equals(userType)) {
            // 2.请求头是hifun_phone，校验手机验证码是否正确
            System.out.println("user_type是hifun_phone，校验手机验证码是否正确");
            String phone = userDetails.getUsername();

            CodePO codePO = new CodePO(httpServletRequest.getParameter("app")
                    , (long) IpUtils.getLongIp(), phone, ""
                    , Long.valueOf(httpServletRequest.getParameter("terminal"))
                    , httpServletRequest.getParameter("uuid"), presentedPassword);
            System.out.println("*****additionalAuthenticationChecks  codePO:" + codePO);
            try {
                String code = hifunFeign.code(codePO);
                System.out.println("*****additionalAuthenticationChecks code:" + code);
            } catch (Exception e) {
                logger.debug("Authentication failed: password does not match stored value");
                try {
                    httpServletRequest.setAttribute("message", e.getMessage());
                    httpServletRequest.getRequestDispatcher("/uaa/error").forward(httpServletRequest, httpServletResponse);
                } catch (Exception ex) {
                    e.printStackTrace();
                    throw new IllegalArgumentException(e.getMessage());
                }
                throw new IllegalArgumentException("停止程序直接返回结果");
//                throw new BadCredentialsException(messages.getMessage(
//                        "AbstractUserDetailsAuthenticationProvider.badCredentials",
//                        "Bad credentials"));
            }
        } else if (UserTypeEnum.HIFUN_USERNAME.getCodeText().equals(userType)) {
            // 3.请求头是hifun_username，校验手机密码是否正确
            System.out.println("user_type是hifun_username，校验手机密码是否正确");
            HashMap<Object, Object> map = new HashMap<>();
            map.put("password", presentedPassword);
            System.out.println("*****additionalAuthenticationChecks  id:" + userDetails.getUsername() + " --- password:" + presentedPassword);
            String check = hifunFeign.check(Integer.parseInt(userDetails.getUsername()), new JSONObject(map).toString());
            JSONObject jsonObject = new JSONObject(check);
            JSONObject data = jsonObject.getJSONObject("data");
            Integer success = data.getInt("success");
            if (success == 0) {
                logger.debug("Authentication failed: password does not match stored value");
                try {
                    httpServletRequest.setAttribute("message", "账号密码错误！");
                    httpServletRequest.getRequestDispatcher("/uaa/error").forward(httpServletRequest, httpServletResponse);
                } catch (Exception e) {
                    e.printStackTrace();
                    throw new IllegalArgumentException(e.getMessage());
                }
                throw new IllegalArgumentException("停止程序直接返回结果");
//                throw new BadCredentialsException(messages.getMessage(
//                        "AbstractUserDetailsAuthenticationProvider.badCredentials",
//                        "Bad credentials"));
            }
        }

        String type = httpServletRequest.getHeader("type");
        if ("option".equals(type)) {
            System.out.println("*****type:" + type);
            try {
                httpServletRequest.setAttribute("message", "验证成功！");
                httpServletRequest.getRequestDispatcher("/uaa/success").forward(httpServletRequest, httpServletResponse);
                throw new IllegalArgumentException("停止程序直接返回结果");
            } catch (Exception e) {
                e.printStackTrace();
                throw new IllegalArgumentException(e.getMessage());
            }
//        } else {
//            Cookie[] cookies = httpServletRequest.getCookies();
//            for (Cookie cookie : cookies) {
//                System.out.println("*****cookie:" + cookie.getName());
//                cookie.setMaxAge(0);
//                cookie.setPath("/");
//                assert httpServletResponse != null;
//                httpServletResponse.addCookie(cookie);
//            }
//            Cookie session = new Cookie("SESSION", null);
//            session.setMaxAge(0);
//            session.setPath("/");
//            System.out.println("覆盖cookie");
//            httpServletResponse.addCookie(session);
        }
    }

}
```

> 注：在RequestMatcher中可以对请求参数进行校验
> ![](Oauth2（下）.assets36740fbaf384e09ab1b14d298ae6d8d.png)


### 校验令牌

**逻辑**

1. 原始用户模块有自己的jwt_token，通过该token从菜谱中获取数据。因此需要通过火粉的公钥验证该token是否有效，且给该用户相应的权限以访问菜谱的接口。
2. 管理员是标准的oauth_token，不需要大的改动。



**关键点**

1. 需要从请求中获取火粉或管理员的token。
2. 需要修改token认证过程的源码，解析token并根据各自的令牌特点进行区分并验证该token是否有效，并将token信息提取出来。



**代码**

首先进入OAuth2AuthenticationProcessingFilter的doFilter方法中，因为原始用户的请求头不同，首先改写获取token的方法。

```java
@Component
public class MyTokenExtractor implements TokenExtractor {

    private final static Log logger = LogFactory.getLog(BearerTokenExtractor.class);

    @Override
    public Authentication extract(HttpServletRequest request) {
        String tokenValue = extractToken(request);
        if (tokenValue != null) {
            PreAuthenticatedAuthenticationToken authentication = new PreAuthenticatedAuthenticationToken(tokenValue, "");
            return authentication;
        }
        return null;
    }

    protected String extractToken(HttpServletRequest request) {
        // first check the header...
        String token = extractHeaderToken(request);

        // bearer type allows a request parameter as well
        if (token == null) {
            logger.debug("Token not found in headers. Trying request parameters.");
            token = request.getParameter(OAuth2AccessToken.ACCESS_TOKEN);
            if (token == null) {
                logger.debug("Token not found in request parameters.  Not an OAuth2 request.");
            }
            else {
                request.setAttribute(OAuth2AuthenticationDetails.ACCESS_TOKEN_TYPE, OAuth2AccessToken.BEARER_TYPE);
            }
        }

        return token;
    }

    /**
     * Extract the OAuth bearer token from a header.
     *
     * @param request The request.
     * @return The token, or null if no OAuth authorization header was supplied.
     */
    protected String extractHeaderToken(HttpServletRequest request) {
        //1.首先看是否是火粉的token
        String hifunToken = request.getHeader((String)AuthEnum.HIFUN.getCodeText());
        if (!Objects.isNull(hifunToken)) {
            return hifunToken;
        }
        //2.如果不是，则检查是否是MCook的token
        Enumeration<String> headers = request.getHeaders("Authorization");
        while (headers.hasMoreElements()) { // typically there is only one (most servers enforce that)
            String value = headers.nextElement();
            if ((value.toLowerCase().startsWith(OAuth2AccessToken.BEARER_TYPE.toLowerCase()))) {
                String authHeaderValue = value.substring(OAuth2AccessToken.BEARER_TYPE.length()).trim();
                // Add this here for the auth details later. Would be better to change the signature of this method.
                request.setAttribute(OAuth2AuthenticationDetails.ACCESS_TOKEN_TYPE,
                        value.substring(0, OAuth2AccessToken.BEARER_TYPE.length()).trim());
                int commaIndex = authHeaderValue.indexOf(',');
                if (commaIndex > 0) {
                    authHeaderValue = authHeaderValue.substring(0, commaIndex);
                }
                return authHeaderValue;
            }
        }

        return null;
    }

}
```

在MyJwtAccessTokenConverter 中，其他不变，使用自定义的MyJwtHelper类的decodeAndVerify方法对token进行验证。

```java
@Component
public class MyJwtAccessTokenConverter extends JwtAccessTokenConverter {

    private static final Log logger = LogFactory.getLog(JwtAccessTokenConverter.class);

    private AccessTokenConverter tokenConverter = new DefaultAccessTokenConverter();

    private JwtClaimsSetVerifier jwtClaimsSetVerifier = new NoOpJwtClaimsSetVerifier();

    private JsonParser objectMapper = JsonParserFactory.create();

    private String verifierKey = new RandomValueStringGenerator().generate();

    private Signer signer = new MacSigner(verifierKey);

    private String signingKey = verifierKey;

    private SignatureVerifier verifier;

    @Resource
    private PublicKey publicKey;

    @Override
    protected Map<String, Object> decode(String token) {
        try {
            Jwt jwt = MyJwtHelper.decodeAndVerify(token, verifier, publicKey);
            String claimsStr = jwt.getClaims();
            Map<String, Object> claims = objectMapper.parseMap(claimsStr);
            if (claims.containsKey(EXP) && claims.get(EXP) instanceof Integer) {
                Integer intValue = (Integer) claims.get(EXP);
                claims.put(EXP, new Long(intValue));
            }
            this.getJwtClaimsSetVerifier().verify(claims);
            return claims;
        }
        catch (Exception e) {
            throw new InvalidTokenException("Cannot convert access token to JSON", e);
        }
    }

    public void afterPropertiesSet() throws Exception {
        if (verifier != null) {
            // Assume signer also set independently if needed
            return;
        }
        SignatureVerifier verifier = new MacSigner(verifierKey);
        try {
            verifier = new RsaVerifier(verifierKey);
        }
        catch (Exception e) {
            logger.warn("Unable to create an RSA verifier from verifierKey (ignoreable if using MAC)");
        }
        // Check the signing and verification keys match
        if (signer instanceof RsaSigner) {
            byte[] test = "src/test".getBytes();
            try {
                verifier.verify(test, signer.sign(test));
                logger.info("Signing and verification RSA keys match");
            }
            catch (InvalidSignatureException e) {
                logger.error("Signing and verification RSA keys do not match");
            }
        }
        else if (verifier instanceof MacSigner) {
            // Avoid a race condition where setters are called in the wrong order. Use of
            // == is intentional.
            Assert.state(this.signingKey == this.verifierKey,
                    "For MAC signing you do not need to specify the verifier key separately, and if you do it must match the signing key");
        }
        this.verifier = verifier;
    }

    public void setVerifier(SignatureVerifier verifier) {
        this.verifier = verifier;
    }

    public void setVerifierKey(String key) {
        this.verifierKey = key;
    }

    private boolean isPublic(String key) {
        return key.startsWith("-----BEGIN");
    }

    private class NoOpJwtClaimsSetVerifier implements JwtClaimsSetVerifier {
        @Override
        public void verify(Map<String, Object> claims) throws InvalidTokenException {
        }
    }

}
```

自定义的MyJwtHelper类，主要是decodeAndVerify方法。如果没有jti，说明是火粉的token，用火粉的公钥验证，同时需要将资源权限、用户权限等信息添加到token中；如果有jti，就是oauth2的标准token。

```java
package oauth2.config.auth.rewrite;

import cn.hutool.json.JSONObject;
import io.jsonwebtoken.*;
import oauth2.common.AuthEnum;
import org.bouncycastle.util.encoders.UTF8;
import org.springframework.security.jwt.*;
import org.springframework.security.jwt.Jwt;
import org.springframework.security.jwt.crypto.sign.InvalidSignatureException;
import org.springframework.security.jwt.crypto.sign.SignatureVerifier;

import java.nio.CharBuffer;
import java.security.PublicKey;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;

import static org.springframework.security.jwt.codec.Codecs.*;
import static org.springframework.security.jwt.codec.Codecs.utf8Decode;

/**
 * @Description:
 * @Author: CJ
 * @Data: 2020/9/19 17:03
 */
public class MyJwtHelper {
    static byte[] PERIOD = utf8Encode(".");

    public static Jwt decode(String token) {
        int firstPeriod = token.indexOf('.');
        int lastPeriod = token.lastIndexOf('.');

        if (firstPeriod <= 0 || lastPeriod <= firstPeriod) {
            throw new IllegalArgumentException("JWT must have 3 tokens");
        }
        CharBuffer buffer = CharBuffer.wrap(token, 0, firstPeriod);
        // TODO: Use a Reader which supports CharBuffer
        JwtHeader header = JwtHeaderHelper.create(buffer.toString());

        buffer.limit(lastPeriod).position(firstPeriod + 1);
        byte[] claims = b64UrlDecode(buffer);

        boolean emptyCrypto = lastPeriod == token.length() - 1;

        byte[] crypto;

        if (emptyCrypto) {
            if (!"none".equals(header.parameters.alg)) {
                throw new IllegalArgumentException(
                        "Signed or encrypted token must have non-empty crypto segment");
            }
            crypto = new byte[0];
        }
        else {
            buffer.limit(token.length()).position(lastPeriod + 1);
            crypto = b64UrlDecode(buffer);
        }
        return new JwtImpl(header, claims, crypto);
    }

    public static Jwt decodeAndVerify(String token, SignatureVerifier verifier, PublicKey publicKey) {
        System.out.println("*****进入自定义的token认证方法");
        Jwt jwt = decode(token);
        String claims = jwt.getClaims();
        JSONObject jsonObject = new JSONObject(claims);
        String jti = jsonObject.getStr("jti");
        if (Objects.isNull(jti)) {
            //1.如果没有jti，说明是火粉的token，用火粉的公钥验证
            try {
                Jwts.parserBuilder().setSigningKey(publicKey).build().parseClaimsJws(token);
                String userId = jsonObject.getStr("userId");
                jsonObject.remove("userId");
                jsonObject.putOpt("user_name", userId);
                jsonObject.putOpt("aud", AuthEnum.AUD.getCodeText());
                jsonObject.putOpt("scope", AuthEnum.SCOPE.getCodeText());
                jsonObject.putOpt("authorities", AuthEnum.AUTHORITIES.getCodeText());

                if(jwt instanceof JwtImpl) {
                    JwtImpl jwtImpl = (JwtImpl) jwt;
                    JwtHeader header = jwtImpl.header();
                    byte[] crypto = jwtImpl.getCrypto();
                    claims = jsonObject.toString();

                    jwt = new JwtImpl(header, claims, crypto);
                }
            } catch (JwtException e) {
                throw new InvalidSignatureException("RSA Signature did not match content");
            }
        } else {
            //2.否则就是oauth2的标准token
            jwt.verifySignature(verifier);
        }

        return jwt;
    }

}

/**
 * Helper object for JwtHeader.
 *
 * Handles the JSON parsing and serialization.
 */
class JwtHeaderHelper {

    static JwtHeader create(String header) {
        byte[] bytes = b64UrlDecode(header);
        return new JwtHeader(bytes, parseParams(bytes));
    }

    static HeaderParameters parseParams(byte[] header) {
        Map<String, String> map = parseMap(utf8Decode(header));
        return new HeaderParameters(map);
    }

    private static Map<String, String> parseMap(String json) {
        if (json != null) {
            json = json.trim();
            if (json.startsWith("{")) {
                return parseMapInternal(json);
            }
            else if (json.equals("")) {
                return new LinkedHashMap<String, String>();
            }
        }
        throw new IllegalArgumentException("Invalid JSON (null)");
    }

    private static Map<String, String> parseMapInternal(String json) {
        Map<String, String> map = new LinkedHashMap<String, String>();
        json = trimLeadingCharacter(trimTrailingCharacter(json, '}'), '{');
        for (String pair : json.split(",")) {
            String[] values = pair.split(":");
            String key = strip(values[0], '"');
            String value = null;
            if (values.length > 0) {
                value = strip(values[1], '"');
            }
            if (map.containsKey(key)) {
                throw new IllegalArgumentException("Duplicate '" + key + "' field");
            }
            map.put(key, value);
        }
        return map;
    }

    private static String strip(String string, char c) {
        return trimLeadingCharacter(trimTrailingCharacter(string.trim(), c), c);
    }

    private static String trimTrailingCharacter(String string, char c) {
        if (string.length() >= 0 && string.charAt(string.length() - 1) == c) {
            return string.substring(0, string.length() - 1);
        }
        return string;
    }

    private static String trimLeadingCharacter(String string, char c) {
        if (string.length() >= 0 && string.charAt(0) == c) {
            return string.substring(1);
        }
        return string;
    }

    private static byte[] serializeParams(HeaderParameters params) {
        StringBuilder builder = new StringBuilder("{");

        appendField(builder, "alg", params.alg);
        if (params.typ != null) {
            appendField(builder, "typ", params.typ);
        }
        for (Map.Entry<String, String> entry : params.map.entrySet()) {
            appendField(builder, entry.getKey(), entry.getValue());
        }
        builder.append("}");
        return utf8Encode(builder.toString());

    }

    private static void appendField(StringBuilder builder, String name, String value) {
        if (builder.length() > 1) {
            builder.append(",");
        }
        builder.append("\"").append(name).append("\":\"").append(value).append("\"");
    }
}


/**
 * Header part of JWT
 */
class JwtHeader implements BinaryFormat {
    private final byte[] bytes;

    final HeaderParameters parameters;

    /**
     * @param bytes      the decoded header
     * @param parameters the parameter values contained in the header
     */
    JwtHeader(byte[] bytes, HeaderParameters parameters) {
        this.bytes = bytes;
        this.parameters = parameters;
    }

    @Override
    public byte[] bytes() {
        return bytes;
    }

    @Override
    public String toString() {
        return utf8Decode(bytes);
    }
}

class HeaderParameters {
    final String alg;

    final Map<String, String> map;

    final String typ = "JWT";

    HeaderParameters(String alg) {
        this(new LinkedHashMap<String, String>(Collections.singletonMap("alg", alg)));
    }

    HeaderParameters(Map<String, String> map) {
        String alg = map.get("alg"), typ = map.get("typ");
        if (typ != null && !"JWT".equalsIgnoreCase(typ)) {
            throw new IllegalArgumentException("typ is not \"JWT\"");
        }
        map.remove("alg");
        map.remove("typ");
        this.map = map;
        if (alg == null) {
            throw new IllegalArgumentException("alg is required");
        }
        this.alg = alg;
    }

}

class JwtImpl implements Jwt {
    final JwtHeader header;

    private final byte[] content;

    private final byte[] crypto;

    private String claims;

    /**
     * @param header  the header, containing the JWS/JWE algorithm information.
     * @param content the base64-decoded "claims" segment (may be encrypted, depending on
     *                header information).
     * @param crypto  the base64-decoded "crypto" segment.
     */
    JwtImpl(JwtHeader header, byte[] content, byte[] crypto) {
        this.header = header;
        this.content = content;
        this.crypto = crypto;
        claims = utf8Decode(content);
    }

    JwtImpl(JwtHeader header, String claims, byte[] crypto) {
        this.header = header;
        this.crypto = crypto;
        this.claims = claims;
        content = utf8Encode(claims);
    }

    /**
     * Validates a signature contained in the 'crypto' segment.
     *
     * @param verifier the signature verifier
     */
    @Override
    public void verifySignature(SignatureVerifier verifier) {
        verifier.verify(signingInput(), crypto);
    }

    private byte[] signingInput() {
        return concat(b64UrlEncode(header.bytes()), MyJwtHelper.PERIOD,
                b64UrlEncode(content));
    }

    /**
     * Allows retrieval of the full token.
     *
     * @return the encoded header, claims and crypto segments concatenated with "."
     * characters
     */
    @Override
    public byte[] bytes() {
        return concat(b64UrlEncode(header.bytes()), MyJwtHelper.PERIOD,
                b64UrlEncode(content), MyJwtHelper.PERIOD, b64UrlEncode(crypto));
    }

    @Override
    public String getClaims() {
        return utf8Decode(content);
    }

    @Override
    public String getEncoded() {
        return utf8Decode(bytes());
    }

    public JwtHeader header() {
        return this.header;
    }

    public byte[] getCrypto() {
        return this.crypto;
    }

    @Override
    public String toString() {
        return header + " " + claims + " [" + crypto.length + " crypto bytes]";
    }
}
```

向框架中注入一些需要用到的对象

```
@Configuration
public class TokenConfig {

//    private static final String SIGNING_KEY = "uaa123";

    @Resource
    private UaaFeign uaaClient;

    @Resource
    private Environment environment;

    /**
     * MyJwtAccessTokenConverter类中用来解析原始用户的JWT
     *
     * @return PublicKey
     */
    @Bean
    public PublicKey hifunPublicKey() throws IOException, NoSuchAlgorithmException, InvalidKeySpecException {
        String hifunPublicKey = environment.getProperty("jwt.publicKey");
        System.out.println("***publicKeyStr：" + hifunPublicKey);
        byte[] keyBytes = (new BASE64Decoder()).decodeBuffer(hifunPublicKey);
        X509EncodedKeySpec keySpec = new X509EncodedKeySpec(keyBytes);
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        PublicKey rsaPublicKey = keyFactory.generatePublic(keySpec);
        return rsaPublicKey;
    }

    /**
     * 将Jwt作为令牌
     *
     * @return
     */
    @Bean
    public TokenStore tokenStore() {
        return new JwtTokenStore(jwtAccessTokenConverter());
    }

    /**
     * 配置Jwt令牌（秘钥）
     *
     * @return
     */
    @Bean
    public JwtAccessTokenConverter jwtAccessTokenConverter() {
//        JwtAccessTokenConverter converter = new JwtAccessTokenConverter();
        MyJwtAccessTokenConverter converter = new MyJwtAccessTokenConverter();
//        converter.setSigningKey(SIGNING_KEY);

        String publicKey = uaaClient.publicKey();
        System.out.println("publicKey: " + publicKey);
        converter.setVerifierKey(publicKey);
        converter.setVerifier(new RsaVerifier(publicKey));

        return converter;
    }

}
```

配置框架中的配置TokenStore

```java
@Configuration
public class ResourceServerConfig {

    private static final String RESOURCE_ID = "res1";

    @Resource
    private TokenStore tokenStore;

    @Resource
    private MyAuthExceptionEntryPoint myAuthExceptionEntryPoint;

    @Resource
    private MyAccessDeniedHandler myAccessDeniedHandler;

    @Resource
    private MyTokenExtractor myTokenExtractor;

    @Configuration
    @EnableResourceServer
    public class UserServerConfig extends ResourceServerConfigurerAdapter {
        @Override
        public void configure(ResourceServerSecurityConfigurer resources) throws Exception {
            resources.resourceId(RESOURCE_ID)
                    .tokenStore(tokenStore)
                    .stateless(true)
                    .tokenExtractor(myTokenExtractor)
                    .authenticationEntryPoint(myAuthExceptionEntryPoint)
                    .accessDeniedHandler(myAccessDeniedHandler);
        }

        @Override
        public void configure(HttpSecurity http) throws Exception {
            http.csrf().disable().authorizeRequests()
//                    .antMatchers("/order/**").access("#oauth2.hasScope('ROLE_ADMIN')");
                    .antMatchers("/user/getTbUser**", "/user/getRoleCodes", "/user/getAuthorities","/uc/permission").permitAll()
                    .antMatchers("/user/**").hasAnyAuthority("hifun")/*access("#oauth2.hasScope('ROLE_USER')")*/
                    .antMatchers("/administrator/**").hasAnyAuthority("/users/");
        }
    }

}
```

feign

```java
@FeignClient("TEST-UAA-CENTER")
public interface UaaClient {

    @GetMapping(path = "/uaa/publicKey")
    String publicKey();

}
```









## 4.2 分布式优化

**逻辑**

1. 授权码模式中，session中缓存了上次请求的信息，在分布式中需要对session进行持久化；



**代码**

```xml
        <dependency>
            <groupId>org.springframework.session</groupId>
            <artifactId>spring-session-data-redis</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
        </dependency>
```

**配置**

```yaml
spring:
  redis:
    host: 116.62.148.11
    port: 6380
    password:
    timeout: 1000
    jedis:
      pool:
        max-active: 8  # 连接池最大连接数 (使用负值表示没有限制)
        max-idle: 8    # 连接池中的最大空闲连接
        max-wait: -1s  # 连接池最大阻塞等待时间(使用负值表示没有限制)
        min-idle: 0 # 连接池中的最小空闲连接
  #  session:
  #    store-type: redis
```

**开启session共享**
添加@EnableRedisHttpSession注解即可，会自动将session中的数据存储到redis中。

```java
@EnableRedisHttpSession(maxInactiveIntervalInSeconds = 600)  //spring在多长时间后强制使redis中的session失效,默认是1800.(单位/秒)
public class SessionConfig {}
```

**Redis中的存储结构**

![](Oauth2（下）.assets\872798119abd403e8d2fd4fa580019c6.png)






## 4.3 资源服务器自定义异常返回

### 4.3.1 配置类配置

```java
@Configuration
public class ResourceServerConfig {

    private static final String RESOURCE_ID = "res1";

    @Resource
    private TokenStore tokenStore;

    @Resource
    private MyAuthExceptionEntryPoint myAuthExceptionEntryPoint;

    @Resource
    private MyAccessDeniedHandler myAccessDeniedHandler;

    @Configuration
    @EnableResourceServer
    public class UserServerConfig extends ResourceServerConfigurerAdapter {
        @Override
        public void configure(ResourceServerSecurityConfigurer resources) throws Exception {
            resources.resourceId(RESOURCE_ID)
                    .tokenStore(tokenStore)
                    .stateless(true)
                    .authenticationEntryPoint(myAuthExceptionEntryPoint)
                    .accessDeniedHandler(myAccessDeniedHandler);
        }

        @Override
        public void configure(HttpSecurity http) throws Exception {
            http.authorizeRequests()
//                    .antMatchers("/order/**").access("#oauth2.hasScope('ROLE_ADMIN')");
                    .antMatchers("/user/**").hasAuthority("hifun");
        }
    }
}
```

**原理：**

1. 如果是**不带token**访问需要认证的资源，会抛出AccessDeniedException异常，进入ExceptionTranslationFilter过滤器进行处理，将AccessDeniedException异常**InsufficientAuthenticationException**异常，在sendStartAuthentication方法中调用容器中的自定义的MyAuthExceptionEntryPoint类的commence方法，在该方法中自定义异常处理方式。

   ```java
       protected void sendStartAuthentication(HttpServletRequest request,
               HttpServletResponse response, FilterChain chain,
               AuthenticationException reason) throws ServletException, IOException {
   
           SecurityContextHolder.getContext().setAuthentication(null);
           requestCache.saveRequest(request, response);
           logger.debug("Calling Authentication entry point.");
           authenticationEntryPoint.commence(request, response, reason);
       }
   ```

2. 如果是携带token且token无效或过期，会在OAuth2AuthenticationProcessingFilter过滤器对token进行验证（decode方法）。如果token无效，在JwtAccessTokenConverter类中抛出InvalidTokenException异常；如果token过期，在DefaultTokenServices 的loadAuthentication方法中抛出InvalidTokenException异常。

3. 如果是token权限不足，则会抛出AccessDeniedException异常进入ExceptionTranslationFilter过滤器处理。并调用自定义的异常类。



### 4.3.2 自定义异常类

#### 自定义401异常

```java
@Component
public class MyAuthExceptionEntryPoint implements AuthenticationEntryPoint {

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response, AuthenticationException authException) throws IOException, ServletException {
        Throwable cause = authException.getCause();

        response.setStatus(HttpStatus.OK.value());
        response.setHeader("Content-Type", "application/json;charset=UTF-8");
        CommonResult<String> result = null;
        try {
            if(cause instanceof InvalidTokenException) {
                result = CommonResult.error(HttpStatus.UNAUTHORIZED.value(),"认证失败,无效或过期token");
            }else{
                result = CommonResult.error(HttpStatus.UNAUTHORIZED.value(),"认证失败,没有携带token");
            }
            response.getWriter().write(new ObjectMapper().writeValueAsString(result));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

}
```

#### 自定义403异常

```java
@Component
public class MyAccessDeniedHandler implements AccessDeniedHandler {

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response, AccessDeniedException accessDeniedException) throws IOException, ServletException {
        response.setStatus(HttpStatus.OK.value());
        response.setHeader("Content-Type", "application/json;charset=UTF-8");
        try {
            CommonResult<String> result = CommonResult.error(HttpStatus.FORBIDDEN.value(),"权限不足");
            response.getWriter().write(new ObjectMapper().writeValueAsString(result));
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

}
```



## 4.4 给token失效用户匿名权限

如果接口是没有权限的，但是因为用户的token过期或失效原因导致访问失败，这是不符合逻辑的，所以需要给这种用户匿名权限，使其可以正常访问没有权限的接口。
但是如何区分是401异常还是403异常呢？如果报403但是request中没有token，说明是未携带token；如果报403但是request中有token，则检查token是否有效，token有效则检查token是否过期，如果token未过期说明是token没有权限。



或



区分需要鉴权和无需鉴权的接口的路径，如无需鉴权的借口使用 /xxx-anon/xxxx ，在网关路由时直接过滤掉token参数。

```yaml
      routes:
        - id: SMARTCOOK
          uri: lb://SMARTCOOK
          filters:
            - SetPath=/menu-anon/{path}
            - RemoveResponseHeader=Mars-Token
            - RemoveResponseHeader=Authorization
            - RemoveRequestParameter=access_token
          predicates:
            - Path=/v1/api-menu/menu-anon/{path}  #直接访问接口
```





## 4.5 授权码模式使用自定义的UI界面和路径

> **注意：**
> 如果出现错误"User must be authenticated with Spring Security before authorization can be completed"，是在AuthorizationEndpoint类（/oauth/authorize）中抛出的异常，因为没有经过用户登录直接跳转到了/oauth/authorize接口，导致principle参数为null。
> **原因是在安全配置中开放了/oauth/authorize接口的权限。**

**首先设置用户账号密码验证页面/login**

1. 在resources/public目录下创建登录页面的html文件，提交的接口设置为/uaa/login（接口地址随意）
2. 将创建的html登录页面和提交的接口地址设置到WebSecurityConfigurerAdapter继承类的endpoint对象中
   endpoint ... .formLogin().loginPage("/uaa/public/login1.html").loginProcessingUrl("/uaa/login");
   表示说那个表单登录，请求/oauth/authorize重定向的登录页面地址为/uaa/public/login.html，表单提交认证接口为/uaa/login（与html中提交的接口一致）。
3. 需要通过静态资源映射将请求地址/uaa/public/login1.html映射到真实资源地址classpath:public/login1.html。

```java
@Configuration
public class WebMvcConfigurerAdapter implements WebMvcConfigurer {

    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
//        registry.addViewController("/").setViewName("login");
//        registry.addViewController("/login.html").setViewName("login");
//        registry.addViewController("/uaa/hxrlogin/pages").setViewName("");
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/uaa/hxrlogin/**").addResourceLocations("classpath:hxrlogin/");
//        registry.addResourceHandler("/uaa/public/**").addResourceLocations("classpath:public/");
    }
}
```

**然后修改客户端认证接口/oauth/authorize**

在@EnableAuthorizationServer注释的继承自AuthorizationServerConfigurerAdapter类的授权配置类中的endpoints对象中endpoint ... .pathMapping("/oauth/authorize","/uaa/oauth/authorize");



**修改请求和刷新token的接口/oauth/token**
在@EnableAuthorizationServer注释的继承自AuthorizationServerConfigurerAdapter类的授权配置类中的endpoints对象中endpoint ... .pathMapping("/oauth/token","/uaa/oauth/token");



##### 再设置允许授权页面/oauth/confirm_access

1. 在上述endpoints对象后再跟上 .pathMapping("/oauth/confirm_access","/uaa/oauth/confirm_access");即可
   将请求确认授权页面的默认接口路径/oauth/confirm_access改为/uaa/oauth/confirm_access。
2. 创建接口类，接口路径为需要与配置类中的对应，即/uaa/oauth/confirm_access。因为已经将/oauth/authorize的接口地址改为/uaa/oauth/authorize，因此这里action提交的路径先改为/uaa/oauth/authorize。

```java
@RestController
@SessionAttributes("authorizationRequest")
public class BootGrantController {

    private static final String ERROR = "<html><body><h1>OAuth Error</h1><p>%errorSummary%</p></body></html>";

    @RequestMapping("/uaa/oauth/confirm_access")
    public ModelAndView getAccessConfirmation(Map<String, Object> model, HttpServletRequest request) throws Exception {
        final String approvalContent = createTemplate(model, request);
        if (request.getAttribute("_csrf") != null) {
            model.put("_csrf", request.getAttribute("_csrf"));
        }
        View approvalView = new View() {
            @Override
            public String getContentType() {
                return "text/html";
            }

            @Override
            public void render(Map<String, ?> model, HttpServletRequest request, HttpServletResponse response) throws Exception {
                response.setContentType(getContentType());
                response.getWriter().append(approvalContent);
            }
        };
        return new ModelAndView(approvalView, model);
    }

    protected String createTemplate(Map<String, Object> model, HttpServletRequest request) {
        AuthorizationRequest authorizationRequest = (AuthorizationRequest) model.get("authorizationRequest");
        String clientId = authorizationRequest.getClientId();

        StringBuilder builder = new StringBuilder();
        builder.append("<html><body><h1>OAuth Approval</h1>");
        builder.append("<p>Do you authorize \"").append(HtmlUtils.htmlEscape(clientId));
        builder.append("\" to access your protected resources?</p>");
        builder.append("<form id=\"confirmationForm\" name=\"confirmationForm\" action=\"");

        String requestPath = ServletUriComponentsBuilder.fromContextPath(request).build().getPath();
        if (requestPath == null) {
            requestPath = "";
        }

        builder.append(requestPath).append("/uaa/oauth/authorize\" method=\"post\">");
        builder.append("<input name=\"user_oauth_approval\" value=\"true\" type=\"hidden\"/>");

        String csrfTemplate = null;
        CsrfToken csrfToken = (CsrfToken) (model.containsKey("_csrf") ? model.get("_csrf") : request.getAttribute("_csrf"));
        if (csrfToken != null) {
            csrfTemplate = "<input type=\"hidden\" name=\"" + HtmlUtils.htmlEscape(csrfToken.getParameterName()) +
                    "\" value=\"" + HtmlUtils.htmlEscape(csrfToken.getToken()) + "\" />";
        }
        if (csrfTemplate != null) {
            builder.append(csrfTemplate);
        }

        String authorizeInputTemplate = "<label><input name=\"authorize\" value=\"Authorize\" type=\"submit\"/></label></form>";

        if (model.containsKey("scopes") || request.getAttribute("scopes") != null) {
            builder.append(createScopes(model, request));
            builder.append(authorizeInputTemplate);
        } else {
            builder.append(authorizeInputTemplate);
            builder.append("<form id=\"denialForm\" name=\"denialForm\" action=\"");
            builder.append(requestPath).append("/uaa/oauth/authorize\" method=\"post\">");
            builder.append("<input name=\"user_oauth_approval\" value=\"false\" type=\"hidden\"/>");
            if (csrfTemplate != null) {
                builder.append(csrfTemplate);
            }
            builder.append("<label><input name=\"deny\" value=\"Deny\" type=\"submit\"/></label></form>");
        }

        builder.append("</body></html>");

        return builder.toString();
    }

    private CharSequence createScopes(Map<String, Object> model, HttpServletRequest request) {
        StringBuilder builder = new StringBuilder("<ul>");
        @SuppressWarnings("unchecked")
        Map<String, String> scopes = (Map<String, String>) (model.containsKey("scopes") ?
                model.get("scopes") : request.getAttribute("scopes"));
        for (String scope : scopes.keySet()) {
            String approved = "true".equals(scopes.get(scope)) ? " checked" : "";
            String denied = !"true".equals(scopes.get(scope)) ? " checked" : "";
            scope = HtmlUtils.htmlEscape(scope);

            builder.append("<li><div class=\"form-group\">");
            builder.append(scope).append(": <input type=\"radio\" name=\"");
            builder.append(scope).append("\" value=\"true\"").append(approved).append(">Approve</input> ");
            builder.append("<input type=\"radio\" name=\"").append(scope).append("\" value=\"false\"");
            builder.append(denied).append(">Deny</input></div></li>");
        }
        builder.append("</ul>");
        return builder.toString();
    }


    @RequestMapping("/uaa/oauth/error")
    public ModelAndView handleError(HttpServletRequest request) {
        Map<String, Object> model = new HashMap<String, Object>();
        Object error = request.getAttribute("error");
        // The error summary may contain malicious user input,
        // it needs to be escaped to prevent XSS
        String errorSummary;
        if (error instanceof OAuth2Exception) {
            OAuth2Exception oauthError = (OAuth2Exception) error;
            errorSummary = HtmlUtils.htmlEscape(oauthError.getSummary());
        } else {
            errorSummary = "Unknown error";
        }
        final String errorContent = ERROR.replace("%errorSummary%", errorSummary);
        View errorView = new View() {
            @Override
            public String getContentType() {
                return "text/html";
            }

            @Override
            public void render(Map<String, ?> model, HttpServletRequest request, HttpServletResponse response) throws Exception {
                response.setContentType(getContentType());
                response.getWriter().append(errorContent);
            }
        };
        return new ModelAndView(errorView, model);
    }

}

```

> 这里是直接将html代码写入到java代码中，应该可以从外部文件读入，这里暂时没有做。



## 4.6 网关gateway的优化

1. 上述提到的，转发请求但不改变请求头中的请求地址。
2. 如果访问/menu-anon等无权限的接口，则在gateway中将token去掉。以免token失效导致无法访问无权限接口的问题出现。（最好的还是在oauth框架中，如果token过期或无效，则给匿名用户权限）
3. 对特定的接口地址进行拦截，只能通过feign调用（如通过用户名查询用户的信息接口）



## 4.7 使用refresh_token刷新过期的token

1. 生成token时，将refresh_token存储到redis中，key的过期时间和refresh_token相同。
2. 如果验证token时，发现token过期，则查询redis中是否有对应的refresh_token。
   存在则用refresh_token生成新的token并设置到响应中替换过期的token，并将新的refresh_token存储到redis中。
   不存在则抛出token过期异常，前端页面跳转到登录。

结论：无法实现，因为刷新token需要携带client的密码，而密码无法从数据库中查询，只有客户端知道。



## 4.8 令牌增强

如想创建的令牌中携带令牌的创建时间，就需要对令牌的功能进行增强。

```java
import org.springframework.security.oauth2.common.DefaultOAuth2AccessToken;
import org.springframework.security.oauth2.common.OAuth2AccessToken;
import org.springframework.security.oauth2.provider.OAuth2Authentication;
import org.springframework.security.oauth2.provider.token.TokenEnhancer;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;

@Component
public class MyTokenEnhancer implements TokenEnhancer {

    @Override
    public OAuth2AccessToken enhance(OAuth2AccessToken accessToken, OAuth2Authentication authentication) {
        final Map<String, Object> additionalInfo = new HashMap<>();

        additionalInfo.put("cre", System.currentTimeMillis()/1000);
        // 注意添加的额外信息，最好不要和已有的json对象中的key重名，容易出现错误
        //additionalInfo.put("authorities", user.getAuthorities());

        ((DefaultOAuth2AccessToken) accessToken).setAdditionalInformation(additionalInfo);

        return accessToken;
    }

}
```





## 4.8 账户黑名单

**情况一：**

1. 如果将账号的enabled置为false，表示该账号被禁用。
2. 在刷新token时，框架会检查enabled是否为true，否则抛异常。
   问题是如果token有效时间为一小时，那么最长在这1小时内被禁用的用户依然可以访问，所以需要将该用户拉入黑名单，黑名单有效期和token有效期一致。

**情况二：**
如果用户token中的信息（如过期时间、权限等）变化，原token就不可用，需要放入黑名单，让用户重新登录。

**情况三：**
用户主动注销，则将token放入黑名单，让用户重新登录。

**逻辑**

1. 当用户信息发生变化时，需要将该用户和当前时间存入redis中的黑名单表。
2. 每次请求时，检查黑名单中是否有该请求用户，如果在黑名单中，且token的创建时间比黑名单中的时间要早，则拦截该请求。客户端需要重新登录并获取token。
   如果是刷新token请求，也需要检查refresh_token的用户和创建时间，同上。

**代码**
首先在token中添加token的创建时间。创建TokenEnhancer的实现类，实现enhance方法，在该方法中为accessToken添加信息。

```java
@Component
public class MyTokenEnhancer implements TokenEnhancer {

    @Override
    public OAuth2AccessToken enhance(OAuth2AccessToken accessToken, OAuth2Authentication authentication) {
        final Map<String, Object> additionalInfo = new HashMap<>();

        additionalInfo.put("cre", System.currentTimeMillis()/1000);
        // 注意添加的额外信息，最好不要和已有的json对象中的key重名，容易出现错误
        //additionalInfo.put("authorities", user.getAuthorities());

        ((DefaultOAuth2AccessToken) accessToken).setAdditionalInformation(additionalInfo);

        return accessToken;
    }

}
```

将自定义的类添加到配置中的token增强器链中

```java
@Configuration
@EnableAuthorizationServer
public class AuthorizationServer extends AuthorizationServerConfigurerAdapter {
    
    ......
    
    @Resource
    private MyTokenEnhancer myTokenEnhancer;

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
        tokenEnhancerChain.setTokenEnhancers(Arrays.asList(myTokenEnhancer,accessTokenConverter));
        services.setTokenEnhancer(tokenEnhancerChain);

//        services.setAccessTokenValiditySeconds(7200); //令牌默认有效时间2小时
//        services.setRefreshTokenValiditySeconds(259200); //刷新令牌默认有效期3天
        return services;
    }
```

在**gateway**中设置黑名单过滤器。检查access_token和refresh_token的用户和过期时间。

```java
@Component
public class ExpiredTokenFilter implements GlobalFilter, Ordered {

    private Map<String, Long> expiredMap = Collections.emptyMap();

    @Resource
    private ExpiredTokenFeign expiredTokenFeign;

    @Bean
    @ConditionalOnMissingBean
    public HttpMessageConverters messageConverters(ObjectProvider<HttpMessageConverter<?>> converters) {
        return new HttpMessageConverters(converters.orderedStream().collect(Collectors.toList()));
    }

    /**
     * 定时同步过期用户
     */
    @Scheduled(fixedDelay = 5000)
//    @Scheduled(cron = "${cron.sync_expired_token}")
//    @Scheduled(cron = "0 0/5 * * * ?")
    public void syncBlackIPList() {
        try {
            expiredMap = expiredTokenFeign.getExpiredToken();
            System.out.println("同步过期token:" + expiredMap);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * 筛选已失效的token
     *
     * @param exchange
     * @param chain
     * @return
     */
    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        if (expiredMap.isEmpty()) {
            return chain.filter(exchange);
        }
        ServerHttpRequest request = exchange.getRequest();

        String token = "";
        //从请求头中获取token
        HttpHeaders httpHeaders = request.getHeaders();
        List<String> authorization = httpHeaders.get("Authorization");
        if (!Objects.isNull(authorization)) {
            for (String value : authorization) { // typically there is only one (most servers enforce that)
                if ((value.toLowerCase().startsWith("Bearer".toLowerCase()))) {
                    token = value.substring("Bearer".length()).trim();
                    // Add this here for the auth details later. Would be better to change the signature of this method.
                    int commaIndex = token.indexOf(',');
                    if (commaIndex > 0) {
                        token = token.substring(0, commaIndex);
                    }
                }
            }
        }

        //从参数中获取token
        if (StringUtils.isEmpty(token)) {
            MultiValueMap<String, String> queryParams = request.getQueryParams();
            token = queryParams.getFirst("access_token");
            if (StringUtils.isEmpty(queryParams.getFirst("grant_type"))) {
                token = queryParams.getFirst("refresh_token");
            }
        }

        if (!StringUtils.isEmpty(token)) {
            int firstPeriod = token.indexOf('.');
            int lastPeriod = token.lastIndexOf('.');

            if (firstPeriod <= 0 || lastPeriod <= firstPeriod) {
                throw new IllegalArgumentException("JWT must have 3 tokens");
            }
            CharBuffer buffer = CharBuffer.wrap(token, 0, firstPeriod);

            buffer.limit(lastPeriod).position(firstPeriod + 1);
            byte[] decode = Base64.decode(buffer);
            String content = new String(decode);
            JSONObject jsonObject = new JSONObject(content);
            String userId = jsonObject.getStr("user_name");
            Long createTimestamp = jsonObject.getLong("cre");

            boolean isExpired = expiredMap.containsKey(userId) && expiredMap.get(userId).compareTo(createTimestamp) > 0;
//            Assert.isTrue(!isExpired, "gateway: 令牌已失效，请重新登录");
            if (isExpired) {
                ServerHttpResponse response = exchange.getResponse();

                CommonResult<Object> error = CommonResult.error(HttpStatus.UNAUTHORIZED.value(), "gateway: token已失效，请重新登录");
                byte[] bytes = error.toString().getBytes();
                DataBuffer wrap = response.bufferFactory().wrap(bytes);

                response.setStatusCode(HttpStatus.OK);
                return response.writeWith(Mono.just(wrap));
            }
        }

        return chain.filter(exchange);
    }

    @Override
    public int getOrder() {
        return 0;
    }

}
```

feign请求用户中心获取过期的token名单

```java
@FeignClient(name = "SECURITY-USER")
public interface ExpiredTokenFeign {

    @GetMapping(path = "/feign/user/getExpiredToken")
    Map<String,Long> getExpiredToken();

}
```

在用户中心，如果用户的有效性、角色、权限、用户角色绑定、角色权限绑定发生改变，需要查询对应的用户id，通过异步方式发送到rabbitmq中添加到redis中的过期列表中。



## 4.9 后台如何控制可以修改的权限

用户只能修改其拥有的角色，权限的自集合。如何控制该用户可以修改的权限。



## 4.10 权限分配设计

用户不分级，角色没有分级，权限有分级。
权限包括系统管理（用户管理，权限管理，角色管理等），各子服务的权限等。

1. 用户通过部门和岗位进行分层，与权限无关。如果用户有系统管理权限的用户权限，那么可以根据权限大小对用户的信息和权限进行操作。
2. 用户如果有系统管理权限的角色权限，那么可以创建角色，绑定自己拥有的权限。可以创建新用户绑定该角色。
3. 单独给开发人员开放一个权限管理系统用于权限的管理。

**规划：**

1. 用户表进行分层
2. 再创建一个中间表用于关联用户表和角色表，关联用户和其创建的角色。
3. 如果用户有系统管理权限中的用户管理权限，可以对其子用户进行增删改查，绑定该用户创建的角色。如果用户有角色管理权限，可以对其关联的角色进行增删改查，将其拥有的权限绑定到该角色。如果用户有权限管理权限，可以对其子权限进行。 父级可以查看其所有子级的内容。



## 4.11 删除浏览器的缓存cookie



## 4.12 前端页面定制，并在不跳转的情况下显示错误信息



## 4.13 使用form表单提交的问题

访问/oauth/authorize接口，框架中会自动重定向到其他页面。这回导致以下几个问题

- 1.无法在原页面上显示错误信息；
- 2.无法通过前端或者后台删除浏览器缓存的cookie。

但是使用ajax请求会存在同源问题，导致跳转失败。所以最好的还是通过改写/oauth/authorize的源码，进行正常的响应，将重定向地址放在响应体中让前端自主跳转。



## 4.14 异常捕获

添加如下异常处理类，但是无法处理过滤器链中的异常。

```java
import feign.FeignException;
import oauth2.entities.CommonResult;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ExceptionAdapter {

    @ExceptionHandler({FeignException.class})
    public CommonResult<String> feignException(FeignException feignException) {
        String message = feignException.getMessage();

        return CommonResult.error(message);
    }


    @ExceptionHandler({Exception.class})
    public CommonResult<String> exception(Exception e) {
        String message = e.getMessage();
        e.printStackTrace();

        return CommonResult.error(message);
    }

}
```





# 五、附

## 5.1 JWT工具类

如果想要对JWT令牌进行各种操作，可以使用如下的工具类。

```java
import io.jsonwebtoken.*;
import lombok.Data;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.jwt.JwtHelper;
import org.springframework.stereotype.Component;

import javax.annotation.Resource;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

/**
 * @Author: CJ
 * @Data: 2020/6/11 9:17
 */
@Data
@Component
public class JwtTokenUtil {

//    @Value("${jwt.secret}")
//    private String secret;
    @Value("${jwt.expiration}")
    private Long expiration;
    @Value("${jwt.header}")
    private String header;

    @Resource
    private RSAPrivateKey rsaPrivateKey;

    @Resource
    private RSAPublicKey rsaPublicKey;

//    @Resource
//    private KeyPairConfig keyPairConfig;


    /**
     * 生成jwt令牌
     * @param userDetails
     * @return
     */
    public String generateToken(UserDetails userDetails) {
        HashMap<String, Object> claims = new HashMap<>(2);
        claims.put("sub", userDetails.getUsername());
        claims.put("created", new Date());
        return generateToken(claims);
    }

    /**
     * 令牌的过期时间，加密算法和秘钥
     * @param claims
     * @return
     */
    private String generateToken(Map<String, Object> claims) {
        Date date = new Date(System.currentTimeMillis() + expiration);
        return Jwts.builder().setClaims(claims)
                .setExpiration(date)
                .signWith(rsaPrivateKey,SignatureAlgorithm.RS256)
//                .signWith(SignatureAlgorithm.RS256,keyPairConfig.getPrivateKey())
                .compact();
    }

    /**
     * 获取token中的用户名
     * @param token
     * @return
     */
    public String getUsernameFromToken(String token) {
        String username = null;
        try {
            Claims claims = getClaimsFromToken(token);
            username = claims.getSubject();
        } catch (Exception e) {
//            throw new IllegalArgumentException(e.getMessage());
        }
        return username;
    }

    /**
     * 获取token中的claims
     * @param token
     * @return
     */
    public Claims getClaimsFromToken(String token) {
        Claims claims = null;
        try {
            //获取claims的过程就是对token合法性检验的过程，将token解析为Claims对象
            JwtParser jwtParser = Jwts.parser().setSigningKey(rsaPublicKey);
//            JwtParser jwtParser = Jwts.parser().setSigningKey(keyPairConfig.getPublicKey());
            Jws<Claims> claimsJws = jwtParser.parseClaimsJws(token);
            claims = claimsJws.getBody();
        } catch (ExpiredJwtException e) {
            e.printStackTrace();
            throw new IllegalArgumentException("getClaimsFromToken:" + e.getMessage());
        }

        return claims;
    }

    /**
     * 判断token是否过期
     * @param token
     * @return
     */
    public Boolean isTokenExpired(String token) {
        Claims claims = getClaimsFromToken(token);
        Date expiration = claims.getExpiration();
        return expiration.before(new Date());
    }

    /**
     * 刷新token令牌，将新的生成时间放入claims覆盖原时间并和从新生成token
     * @param token
     * @return
     */
    public String refreshToken(String token) {
        String refreshedToken = null;
        try {
            Claims claims = getClaimsFromToken(token);
            claims.put("created", new Date());
            refreshedToken = generateToken(claims);
        } catch (Exception e) {
//            throw new IllegalArgumentException(e.getMessage());
        }

        return refreshedToken;
    }

    /**
     * 校验token是否合法和过期
     * @param token
     * @param userDetails
     * @return
     */
    public Boolean validateToken(String token, UserDetails userDetails) {
        String username = getUsernameFromToken(token);
        return (username.equals(userDetails.getUsername()) && !isTokenExpired(token));
    }

}
```



## 5.2 IP解析工具类

```java
import org.apache.commons.lang.StringUtils;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;

public class IpUtils {
    private static final String IP_ADDRESS_SEPARATOR = ".";

    private IpUtils() {
        throw new IllegalStateException("Utility class");
    }

    /**
     * 将IP转成十进制整数
     *
     * @param strIp 肉眼可读的ip
     * @return 整数类型的ip
     */
    public static int ip2Long(String strIp) {
        if (StringUtils.isBlank(strIp)) {
            return 0;
        }

        String regex = "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}";
        if (!strIp.matches(regex)) {
            // 非IPv4（基本上是IPv6），直接返回0
            return 0;
        }

        long[] ip = new long[4];
        // 先找到IP地址字符串中.的位置
        int position1 = strIp.indexOf(IP_ADDRESS_SEPARATOR);
        int position2 = strIp.indexOf(IP_ADDRESS_SEPARATOR, position1 + 1);
        int position3 = strIp.indexOf(IP_ADDRESS_SEPARATOR, position2 + 1);
        // 将每个.之间的字符串转换成整型
        ip[0] = Long.parseLong(strIp.substring(0, position1));
        ip[1] = Long.parseLong(strIp.substring(position1 + 1, position2));
        ip[2] = Long.parseLong(strIp.substring(position2 + 1, position3));
        ip[3] = Long.parseLong(strIp.substring(position3 + 1));
        long longIp = (ip[0] << 24) + (ip[1] << 16) + (ip[2] << 8) + ip[3];
        if (longIp > Integer.MAX_VALUE) {
            // 把范围控制在int内，这样数据库可以用int保存
            longIp -= 4294967296L;
        }

        return (int) longIp;
    }

    /**
     * 将十进制整数形式转换成IP地址
     *
     * @param longIp 整数类型的ip
     * @return 肉眼可读的ip
     */
    public static String long2Ip(long longIp) {
        StringBuilder ip = new StringBuilder();
        for (int i = 3; i >= 0; i--) {
            ip.insert(0, (longIp & 0xff));
            if (i != 0) {
                ip.insert(0, IP_ADDRESS_SEPARATOR);
            }
            longIp = longIp >> 8;
        }

        return ip.toString();
    }

    /**
     * 获取客户端IP
     *
     * @return 获取客户端IP（仅在web访问时有效）
     */
    public static String getIp() {
        ServletRequestAttributes requestAttributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (requestAttributes == null) {
            return "127.0.0.1";
        }
        HttpServletRequest request = requestAttributes.getRequest();

        // 首先判断Nginx里设置的真实IP，需要依赖Nginx配置
        String realIp = request.getHeader("x-real-ip");
        if (realIp != null && !realIp.isEmpty()) {
            return realIp;
        }

        String forwardedFor = request.getHeader("x-forwarded-for");
        if (forwardedFor != null && !forwardedFor.isEmpty()) {
            return forwardedFor.split(",")[0];
        }

        return request.getRemoteAddr();
    }

    /**
     * 获取整数类型的客户端IP
     *
     * @return 整数类型的客户端IP
     */
    public static int getLongIp() {
        return ip2Long(getIp());
    }
}
```

## 5.3 固定放开的权限

固定的不需要鉴权的路径可以写在工具类中，可以调用方法自定义添加其他路径，并返回全部的路径。

```java
public class PermitAllUrl {

    private static final String[] ENDPOINTS = {"/actuator/health", "/actuator/env", "/actuator/metrics/**", "/actuator/trace", "/actuator/dump",
            "/actuator/jolokia", "/actuator/info", "/actuator/logfile", "/actuator/refresh", "/actuator/flyway", "/actuator/liquibase",
            "/actuator/heapdump", "/actuator/loggers", "/actuator/auditevents", "/actuator/env/PID", "/actuator/jolokia/**",
            "/v2/api-docs/**", "/swagger-ui.html", "/swagger-resources/**", "/webjars/**"};

    public static String[] permitAllUrl(String...urls) {
        if (Objects.isNull(urls) && urls.length == 0) {
            return ENDPOINTS;
        }

        HashSet<Object> set = new HashSet<>();
        Collections.addAll(set, ENDPOINTS);
        Collections.addAll(set, urls);

        return set.toArray(new String[set.size()]);
    }

}
```


# 六、源码地址

许多都是直接修改源码来实现扩展功能，如果有更加优雅的方式可以实现，欢迎分享。

<https://github.com/ChenJie666/security-uaa>

<https://github.com/ChenJie666/security-user>

https://github.com/ChenJie666/security-gateway
