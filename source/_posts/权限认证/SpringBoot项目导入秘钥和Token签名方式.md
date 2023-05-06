---
title: SpringBoot项目导入秘钥和Token签名方式
categories:
- 权限认证
---
###导入公私钥进行加密解密(JJWT框架实现)
```
@Configuration
@Data
public class KeyPairConfig {


    /**
     * 方式一：通过jjwt框架生成秘钥，每次启动都会更换。可以开放公钥接口给其他资源服务。
     */
    private final KeyPair keyPair = Keys.keyPairFor(SignatureAlgorithm.RS256);
    @Bean
    public RSAPublicKey publicKey() {
        RSAPublicKey aPublic = (RSAPublicKey) keyPair.getPublic();

        System.out.println(Base64.encode(aPublic.getEncoded()));

        return aPublic;
    }

    @Bean
    public RSAPrivateKey privateKey(){
        RSAPrivateKey aPrivate = (RSAPrivateKey) keyPair.getPrivate();

        System.out.println(Base64.encode(aPrivate.getEncoded()));

        return aPrivate;
    }

    /**
     * 方式二：通过读取指定路径的秘钥库。可以开放公钥接口给其他资源服务。
     */
    String location = "uaacenter.jks";
    String storepass = "uaacenter";
    String keypass = "uaacenter";
    String alias = "uaacenter";
    KeyPair keyPair;
    {
        ClassPathResource resource = new ClassPathResource(location);
        KeyStoreKeyFactory keyStoreKeyFactory = new KeyStoreKeyFactory(resource, storepass.toCharArray());
        keyPair = keyStoreKeyFactory.getKeyPair(alias,keypass.toCharArray());
    }
    @Bean
    public RSAPublicKey publicKey() {
        RSAPublicKey aPublic = (RSAPublicKey) keyPair.getPublic();

        System.out.println(Base64.encode(aPublic.getEncoded()));

        return aPublic;
    }

    @Bean
    public RSAPrivateKey privateKey(){
        RSAPrivateKey aPrivate = (RSAPrivateKey) keyPair.getPrivate();

        System.out.println(Base64.encode(aPrivate.getEncoded()));

        return aPrivate;
    }

}
```
```
//加密
Jwts.builder().setClaims(claims).setExpiration(date).signWith(rsaPrivateKey,SignatureAlgorithm.RS256).compact();
//解密
Claims claims = Jwts.parser().setSigningKey(rsaPublicKey).parseClaimsJws(token).getBody();
```

###通过JwtHelper框架生成（可以使用公钥解密）
```
@SpringBootTest(classes = oauth2.UaaApplication9500.class)
@RunWith(SpringRunner.class)
public class KeyPairTest {

    @Test
    public void testCreateToken(){
        String location = "uaacenter.jks";
        String storepass = "uaacenter";
        String keypass = "uaacenter";
        String alias = "uaacenter";
        //加载证书
        ClassPathResource resource = new ClassPathResource(location);
        //读取证书
        KeyStoreKeyFactory keyStoreKeyFactory = new KeyStoreKeyFactory(resource,storepass.toCharArray());
        //获取证书中的一对秘钥
        KeyPair keyPair = keyStoreKeyFactory.getKeyPair(alias,keypass.toCharArray());
        //获取私钥
        RSAPrivateKey aPrivate = (RSAPrivateKey)keyPair.getPrivate();

        System.out.println(Base64.encode(aPrivate.getEncoded()));

        //创建令牌，需要私钥加盐[RSA算法]
        Jwt jwt = JwtHelper.encode("abcdefg", new RsaSigner(aPrivate));
        //将令牌用base64编码得到token
        String token = jwt.getEncoded();

        System.out.println(token);
    }

    @Value("${jwt.publicKey}")
    String aPublic;

    @Test
    public void testParseToken(){
        //TODO 方式一：通过代码从证书库获得公钥
        String location = "uaacenter.jks";
        String storepass = "uaacenter";
        String keypass = "uaacenter";
        String alias = "uaacenter";
        //加载证书
        ClassPathResource resource = new ClassPathResource(location);
        //读取证书
        KeyStoreKeyFactory keyStoreKeyFactory = new KeyStoreKeyFactory(resource,storepass.toCharArray());
        //获取证书中的一对秘钥
        KeyPair keyPair = keyStoreKeyFactory.getKeyPair(alias,keypass.toCharArray());
        //获取公钥
        RSAPublicKey aPublic = (RSAPublicKey)keyPair.getPublic();

        System.out.println(Base64.encode(aPublic.getEncoded()));

        //TODO 方式二：通过openssl指令获取公钥
        //从配置文件中读取。需要带上begin和end信息，并且去掉换行符
        System.out.println(aPublic); //"-----BEGIN PUBLIC KEY-----MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAo668mNH7H86PzBCHsMsm7/Hxg4tK6YVWBWt74faDVrew6AzHfXz1S74ZoG5ftWt7hsQh2cFzpbnuMIYrhZatTEhnYNJA6T47meSb476WSc70/59w+21EIeQTbWUNhBZeA9r/M2u5ItBBJksyWSmMM6c2YRCeF7HC/KHFFGhWc46y9x6r3iqOrwnCAsrSjz9cIEvlCVgewLMxU5x9H/INZoqH3ZR8jUv/fIxFfju11izUrpxTb16SYC/t46Lb5l0Kynmrv4OOolGk0yJgeH3vgDnS/3OhlD08vGujnI6os7acCcXwEq3SDHvtOfd/Q/CBbUcDSQuk9ecyvtgFVRvOEwIDAQAB-----END PUBLIC KEY-----";


        //TODO 解析之前得到的token
        String token = "eyJhbGciOiJSUzI1NiJ9.eyJ1c2VySWQiOjEwMDAwLCJpYXQiOjE1OTc4MDMzOTEsImV4cCI6MTYwMDM5NTM5MX0.AyF31VB1v2JMKSBEps0dh6pMa0f8kLSJFP_8ORLoYhJagK1UuA8322Tee7Lxv6QS4OCTqD36fZ4baUn36KJh2ZDr40nUI2Vf6v6Ee9XTx_PQ83qRpl1vVQnK7RR5jGd_qQqpctyeYvVJRqcSCrkMK7gs6RwdPr9PO9SE5Y8ALYYNo7ZLCFikyan6hs_pbvVCK6C6YBYSTYWNvH-bqa8bgDjbVQtYleKYrioM-1nC3fgKjt-ondRTG3MT-QP7vkc6LYCEzuIOAUVAiLcMiOSXhKX54lW4MiQzKRqAPCaowy_CoDdg9n3MeW2IUpbAHMagkuxOeJRpFyDa5h3uIvUCGQ";
        //解码后获得jwt并通过公钥验证是否有效
        Jwt jwt = JwtHelper.decodeAndVerify(token, new RsaVerifier(aPublic));
        String claims = jwt.getClaims();

        System.out.println(claims);
    }
}
```
