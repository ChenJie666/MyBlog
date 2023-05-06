---
title: OSS服务器上传与删除
categories:
- 工具类
---
springboot默认可以接收的文件大小为1MB，在配置中设置上传文件的大小
```yml
spring:
  servlet:
    multipart:
      max-file-size: 5MB
      max-request-size: 5MB
```

***依赖***
<dependency>
            <groupId>com.aliyun.oss</groupId>
            <artifactId>aliyun-sdk-oss</artifactId>
            <version>3.1.0</version>
</dependency>

***配置文件***
```
aliyun:
  oss:
    endpoint: oss-cn-hangzhou.aliyuncs.com # oss对外服务的访问域名
    accessKeyId: xxxxxxxxxx # 访问身份验证中用到用户标识
    accessKeySecret: xxxxxxxxxxxx # 用户用于加密签名字符串和oss用来验证签名字符串的密钥
    bucketName: wecook # oss的存储空间
    webUrl: https://wecook.oss-cn-hangzhou.aliyuncs.com # 文件上传成功后的回调地址
```

***配置类***
```java
@Configuration
@Data
@ConfigurationProperties("aliyun.oss")
public class OSSConfig {

    private String endpoint;
    // 云账号AccessKey有所有API访问权限
    private String accessKeyId;
    private String accessKeySecret;
    private String bucketName;
    private String folder;
    private String webUrl;

    @Bean
    public OSSClientBuilder ossClient(){
        return new OSSClientBuilder();
    }

}
```

***工具类***
```java
@Component
@Slf4j
public class OSSUtil {

    @Value("${aliyun.oss.endpoint}")
    private String endpoint;
    // 云账号AccessKey有所有API访问权限
    @Value("${aliyun.oss.accessKeyId}")
    private String accessKeyId;
    @Value("${aliyun.oss.accessKeySecret}")
    private String accessKeySecret;
    @Value("${aliyun.oss.bucketName}")
    private String bucketName;
    @Value("${aliyun.oss.folder}")
    private String folder;
    @Value("${aliyun.oss.webUrl}")
    private String webUrl;

    @Autowired
    private OSSClientBuilder ossClientBuilder;


    public FileDTO uploadPic(MultipartFile file) throws IOException {

//        log.info("ossConfig**********" + ossConfig);

//        endpoint = ossConfig.getEndpoint();
//        accessKeyId = ossConfig.getAccessKeyId();
//        accessKeySecret = ossConfig.getAccessKeySecret();
//        bucketName = ossConfig.getBucketName();
//        folder = ossConfig.getFolder();
//        webUrl = ossConfig.getWebUrl();

        // 创建OSSClient实例
        OSS ossClient = ossClientBuilder.build(endpoint, this.accessKeyId, this.accessKeySecret);

        log.info(this.accessKeyId);

        // 判断容器是否存在，不存在则创建公共读取权限的容器
        if (!ossClient.doesBucketExist(this.bucketName)) {
//            ossClient.createBucket(bucketName);
            CreateBucketRequest createBucketRequest = new CreateBucketRequest(this.bucketName);
            createBucketRequest.setCannedACL(CannedAccessControlList.PublicRead);
            ossClient.createBucket(createBucketRequest);
        }

        // 设置文件位置
        String uuid = UUID.randomUUID().toString().replace("-", "");
        String fileOldName = file.getOriginalFilename();
        String subFolder = "/jiuzhidao/";
        String filePath = folder + subFolder + uuid + "-" + fileOldName;
        // 获取图片高宽
        BufferedImage bufferedImage = ImageIO.read(file.getInputStream());
        int width = bufferedImage.getWidth();
        int height = bufferedImage.getHeight();

        // 上传文件流。
        try {
            ossClient.putObject(this.bucketName, filePath, new ByteArrayInputStream(file.getBytes()));
            log.info("------OSS文件上传成功------" + filePath);
        } finally {
            // 关闭OSSClient
            ossClient.shutdown();
        }

        FileDTO fileDTO = new FileDTO().setOldName(fileOldName).setWebUrl(this.webUrl + "/" + filePath).setFileBucket(this.bucketName)
                .setFileSize(file.getSize()).setFolder(folder).setFileAPUrl(filePath).setHeight(height).setWidth(width);

        return fileDTO;

    }

    public void removePic(String picName) throws Exception {

        OSS ossClient = ossClientBuilder.build(endpoint, this.accessKeyId, this.accessKeySecret);

        ossClient.deleteObject(bucketName, picName);

    }

}
```

***业务类***
```java
// 允许上传的格式
    private static final String[] IMAGE_TYPE = new String[]{".bmp", ".jpg", ".jpeg", ".gif", ".png"};

    @Override
    public CommonResult uploadPic(MultipartFile file) {

        boolean isLegal = false;
        for (String type : IMAGE_TYPE) {
            if (StringUtils.endsWithIgnoreCase(file.getOriginalFilename(), type)) {
                isLegal = true;
                break;
            }
        }

        if (!isLegal) {
            return new CommonResult(400, "图片格式错误");
        }

        try {
            FileDTO fileDTO = ossUtil.uploadPic(file);
            return new CommonResult<FileDTO>(200, "上传图片成功", fileDTO);
        } catch (IOException e) {
            return new CommonResult(500, "图片上传失败");
        }

    }


    @Override
    public CommonResult removePic(String picName) {
        try {
            ossUtil.removePic(picName);
        } catch (Exception e) {
            e.printStackTrace();
            return new CommonResult(500, "图片删除失败");
        }

        return new CommonResult(200, "图片删除成功");
    }
```



***请求***
- 上传：http://localhost:9001/jiuzhidao/uploadPic
body选择form/data，key选择file，value选择上传的文件
- 删除：http://192.168.32.151:9001/jiuzhidao/removePic?fileName=/images/jiuzhidao/339b1d58d4a045b6ac4800e6c00f14be-wine.png
