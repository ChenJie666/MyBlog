---
title: SpringBoot配置类
categories:
- SpringBoot
---
- 静态资源访问配置类：
addResourceHandler是访问资源的请求路径，addResourceLocations是静态资源的存放路径。
如下配置，访问http://localhost:88/aligenie/tiger.png就会在static文件夹中查找tiger.png文件并返回内容。
```
@Configuration
public class WebConfig extends WebMvcConfigurerAdapter {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/aligenie/**").addResourceLocations("classpath:/static/");
    }

}
```

- 全局异常处理类：
用于接收项目中产生的IllegalArgumentException异常对象，封装后返回给调用者。
```
@RestControllerAdvice
public class ExceptionHandlerAdvice {

    @ExceptionHandler({ IllegalArgumentException.class })
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result badRequestException(IllegalArgumentException exception) {
        String data = exception.getMessage();
        return new Result().error(data);
    }
}
```
