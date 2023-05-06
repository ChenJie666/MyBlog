---
title: 删除浏览器的Cookies
categories:
- SpringBoot
---
###1. 从后台通过java代码删除
创建或获取同名的Cookie，将该cookie的过期时间设为0，路径为根路径。然后添加到response中，会覆盖到浏览器中的原Cookie并立即过期。
```java
        Cookie[] cookies = httpServletRequest.getCookies();
        for (Cookie cookie : cookies) {
            System.out.println("*****cookie:" + cookie.getName());
            cookie.setMaxAge(0);
            cookie.setPath("/");
            assert httpServletResponse != null;
            httpServletResponse.addCookie(cookie);
        }
```
