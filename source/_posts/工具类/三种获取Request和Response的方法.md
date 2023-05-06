---
title: 三种获取Request和Response的方法
categories:
- 工具类
---
###1.通过静态方法获取，你也可以封装一个静态方法出来
```java
@GetMapping(value = "")
public String center() {
    ServletRequestAttributes servletRequestAttributes = (ServletRequestAttributes)RequestContextHolder.getRequestAttributes();
    HttpServletRequest request = servletRequestAttributes.getRequest();
    HttpServletResponse response = servletRequestAttributes.getResponse();
    //...
}
```

###2.通过参数直接获取，只要在你的方法上加上参数，Springboot就会帮你绑定，你可以直接使用。如果你的方法有其他参数，把这两个加到后面即可。
```java
@GetMapping(value = "")
public String center(HttpServletRequest request,HttpServletResponse response) {
    //...
}
```

###3.注入到类，这样就不用每个方法都写了
```java
@Autowired
private HttpServletRequest request;
 
@Autowired
private HttpServletResponse response;
 
@GetMapping(value = "")
public String center() {
    //...
}
```
