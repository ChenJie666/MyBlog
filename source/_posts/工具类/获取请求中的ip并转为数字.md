---
title: 获取请求中的ip并转为数字
categories:
- 工具类
---
```java
import org.apache.commons.lang.StringUtils;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import javax.servlet.http.HttpServletRequest;

/**
 * @author fayfox
 */
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
