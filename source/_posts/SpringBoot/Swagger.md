---
title: Swagger
categories:
- SpringBoot
---
###Swagger配置
Swagger是一个规范和完整的框架，用于生成、描述、调用好可视化RESTful风格的Web服务。
1.生成在线接口文档
2.方便接口测试

***依赖***
<dependency>
                <groupId>io.springfox</groupId>
                <artifactId>springfox-swagger2</artifactId>
                <scope>provided</scope>
                <version>2.9.2</version>
</dependency>
<dependency>
                <groupId>io.springfox</groupId>
                <artifactId>springfox-swagger-ui</artifactId>
                <scope>provided</scope>
                <version>2.9.2</version>
</dependency>

***注解***
配置类上添加@EnableSwagger2
接口类上添加@Api(value = "Q6应用云提供给设备端的API", tags = {"Q6应用云提供给设备端的API"})
接口方法上添加@ApiOperation(value = "查询时钟信息")
接口方法参数上添加@ApiParam(name = "model", value = "设备型号", required = false
实体类上添加@ApiModel(value = "开机欢迎语对象")
属性上添加@ApiModelProperty(value = "开机欢迎语ID", hidden = true)  hidden表示swagger-ui中不显示该属性

***配置类***
```java
@Configuration
@EnableSwagger2
public class SwaggerConfig {

    @Bean
    public Docket webApiConfig() {

        return new Docket(DocumentationType.SWAGGER_2)
                .groupName("bookkeep")  //分组名
                .apiInfo(webApiInfo())
                .select()
                .paths(Predicates.not(PathSelectors.regex("/admin/.*")))
                .paths(Predicates.not(PathSelectors.regex("/error.*")))
                .build();

    }

    private ApiInfo webApiInfo() {

        return new ApiInfoBuilder()
                .title("账单中心API文档")
                .description("本文档描述了账单的接口服务")
                .version("1.0")
                .contact(new Contact("CJ", "", "792965772@qq.com"))
                .build();
    }

}
```

如果想在项目中引入依赖的项目的配置类，需要在主启动类中添加注解@ComponentScan（basePackages = "com.cj"），指定需要扫描的包，将本项目包和依赖项目中的包都进行扫描并添加到容器中。

访问http://localhost:8001/swagger-ui.html


###生产环境关闭 swagger
