---
title: V2ray路由设置
categories:
- 系统安全
---
官方教程(被墙需要代理): 
[新手上路 | V2Fly.org](https://www.v2fly.org/guide/start.html#%E5%AE%A2%E6%88%B7%E7%AB%AF)
[配置文件格式 | V2Fly.org](https://www.v2fly.org/config/overview.html#%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%E6%A0%BC%E5%BC%8F)



# 一、普通路由规则
## 1.1 域名路由规则的写法：
一个数组，数组每一项是一个域名的匹配。有以下几种形式：
- 纯字符串：当此字符串匹配目标域名中任意部分，该规则生效。比如 sina.com 可以匹配 sina.com、sina.com.cn、sina.company 和 www.sina.com，但不匹配 sina.cn。
- 正则表达式：由 regexp: 开始，余下部分是一个正则表达式。当此正则表达式匹配目标域名时，该规则生效。例如 regexp:\.goo.*\.com$ 匹配 www.google.com、fonts.googleapis.com，但不匹配 google.com。
- 子域名（推荐）：由 domain: 开始，余下部分是一个域名。当此域名是目标域名或其子域名时，该规则生效。例如 domain:v2ray.com 匹配 www.v2ray.com、v2ray.com，但不匹配 xv2ray.com。
- 完整匹配：由 full: 开始，余下部分是一个域名。当此域名完整匹配目标域名时，该规则生效。例如 full:v2ray.com 匹配 v2ray.com 但不匹配 www.v2ray.com。
- 从文件中加载域名：形如 ext:file:tag，必须以 ext: 开头，后面跟文件名（不含扩展名）和标签，文件存放在 V2Ray 核心的资源目录中(环境变量v2ray.location.asset或V2RAY_LOCATION_ASSET，默认值为 v2ray 文件同路径。)，文件格式与 geosite.dat 相同，标签必须在文件中存在。
- 预定义域名列表：由 geosite: 开头，余下部分是一个类别名称（域名列表），如 geosite:google 或者 geosite:cn。名称及域名列表参考预定义域名列表。
```
category-ads：包含了常见的广告域名。
category-ads-all：包含了常见的广告域名，以及广告提供商的域名。
tld-cn：包含了 CNNIC 管理的用于中国大陆的顶级域名，如以 .cn、.中国 结尾的域名。
tld-!cn：包含了非中国大陆使用的顶级域名，如以 .hk（香港）、.tw（台湾）、.jp（日本）、.sg（新加坡）、.us（美国）.ca（加拿大）等结尾的域名。
geolocation-cn：包含了常见的大陆站点域名。
geolocation-!cn：包含了常见的非大陆站点域名，同时包含了 tld-!cn。
cn：相当于 geolocation-cn 和 tld-cn 的合集。
apple：包含了 Apple 旗下绝大部分域名。
google：包含了 Google 旗下绝大部分域名。
microsoft：包含了 Microsoft 旗下绝大部分域名。
facebook：包含了 Facebook 旗下绝大部分域名。
twitter：包含了 Twitter 旗下绝大部分域名。
telegram：包含了 Telegram 旗下绝大部分域名。
```
更多域名类别，请查看 [data 目录](https://github.com/v2fly/domain-list-community/tree/master/data)


## 1.2 IP路由规则的写法:
一个数组，数组内每一项代表一个 IP 范围。当某一项匹配目标 IP 时，此规则生效。有以下几种形式：

- IP：形如 127.0.0.1。
- [CIDR](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing)：形如 10.0.0.0/8。
- GeoIP：
   - 形如 geoip:cn 为正向匹配，即为匹配「中国大陆 IP 地址」。后面跟[双字符国家或地区代码](https://zh.wikipedia.org/wiki/%E5%9C%8B%E5%AE%B6%E5%9C%B0%E5%8D%80%E4%BB%A3%E7%A2%BC)，支持所有可以上网的国家和地区。
   - 形如 geoip:!cn 为反向匹配，即为匹配「非中国大陆 IP 地址」。后面跟[双字符国家或地区代码](https://zh.wikipedia.org/wiki/%E5%9C%8B%E5%AE%B6%E5%9C%B0%E5%8D%80%E4%BB%A3%E7%A2%BC)，支持所有可以上网的国家和地区。
   - 特殊值：geoip:private（V2Ray 3.5+），包含所有私有地址，如 127.0.0.1。
- 从文件中加载 IP：
   - 形如 ext:file:tag 和 ext-ip:file:tag 为正向匹配，即为匹配 「tag 内的 IP 地址」。
   - 形如 ext:file:!tag 和 ext-ip:file:!tag 为反向匹配，即为匹配「非 tag 内的 IP 地址」。
   - 必须以 ext: 或 ext-ip: 开头，后面跟文件名、标签或 !标签，文件存放在资源目录中，文件格式与 geoip.dat 相同，标签必须在文件中存在。
   >**TIP:**
   ext:geoip.dat:cn 和 ext-ip:geoip.dat:cn 等价于 geoip:cn；
   ext:geoip.dat:!cn 和 ext-ip:geoip.dat:!cn 等价于 geoip:!cn。


## 1.3 Port端口写法
目标端口范围，有三种形式：
- a-b：a 和 b 均为正整数，且小于 65536。这个范围是一个前后闭合区间，当端口落在此范围内时，此规则生效。
- a：a 为正整数，且小于 65536。当目标端口为 a 时，此规则生效。
- 以上两种形式的混合（V2Ray 4.18+），以逗号 "," 分隔。形如：53,443,1000-2000。

<br>
# 二、Policy本地策略
本地策略可以配置一些用户相关的权限，比如连接超时设置。V2Ray 处理的每一个连接都对应一个用户，按照用户的等级（level）应用不同的策略。本地策略可根据等级的不同而变化。

## 2.1 PolicyObject
PolicyObject 对应配置文件的 policy 项。
```
{
    "levels": {
        "0": {
            "handshake": 4,
            "connIdle": 300,
            "uplinkOnly": 2,
            "downlinkOnly": 5,
            "statsUserUplink": false,
            "statsUserDownlink": false,
            "bufferSize": 10240
        }
    },
    "system": {
        "statsInboundUplink": false,
        "statsInboundDownlink": false,
        "statsOutboundUplink": false,
        "statsOutboundDownlink": false
    }
}
```

### ①level: map{string: LevelPolicyObject}

一组键值对，每个键是一个字符串形式的数字（JSON 的要求），比如 "0"、"1" 等，双引号不能省略，此数字对应用户等级。每一个值是一个 LevelPolicyObject.

>TIP
每个入站出站代理现在都可以设置用户等级，V2Ray 会根据实际的用户等级应用不同的本地策略。

### ②system: SystemPolicyObject
V2Ray 系统的策略

<br>
## 2.2 LevelPolicyObject
```
{
    "handshake": 4,
    "connIdle": 300,
    "uplinkOnly": 2,
    "downlinkOnly": 5,
    "statsUserUplink": false,
    "statsUserDownlink": false,
    "bufferSize": 10240
}
```

### ①handshake: number

连接建立时的握手时间限制。单位为秒。默认值为 4。在入站代理处理一个新连接时，在握手阶段（比如 VMess 读取头部数据，判断目标服务器地址），如果使用的时间超过这个时间，则中断该连接。

### ②connIdle: number

连接空闲的时间限制。单位为秒。默认值为 300。在入站出站代理处理一个连接时，如果在 connIdle 时间内，没有任何数据被传输（包括上行和下行数据），则中断该连接。

### ③uplinkOnly: number

当连接下行线路关闭后的时间限制。单位为秒。默认值为 2。当服务器（如远端网站）关闭下行连接时，出站代理会在等待 uplinkOnly 时间后中断连接。

### ④downlinkOnly: number

当连接上行线路关闭后的时间限制。单位为秒。默认值为 5。当客户端（如浏览器）关闭上行连接时，入站代理会在等待 downlinkOnly 时间后中断连接。

>TIP
在 HTTP 浏览的场景中，可以将 uplinkOnly 和 downlinkOnly 设为 0，以提高连接关闭的效率。

### ⑤statsUserUplink: true | false

当值为 true 时，开启当前等级的所有用户的上行流量统计。

### ⑥statsUserDownlink: true | false

当值为 true 时，开启当前等级的所有用户的下行流量统计。

### ⑦bufferSize: number

每个连接的内部缓存大小。单位为 kB。当值为 0 时，内部缓存被禁用。

默认值 (V2Ray 4.4+):

在 ARM、MIPS、MIPSLE 平台上，默认值为 0。
在 ARM64、MIPS64、MIPS64LE 平台上，默认值为 4。
在其它平台上，默认值为 512。
默认值 (V2Ray 4.3-):

在 ARM、MIPS、MIPSLE、ARM64、MIPS64、MIPS64LE 平台上，默认值为 16。
在其它平台上，默认值为 2048。

>TIP
bufferSize 选项会覆盖 环境变量中 v2ray.ray.buffer.size 的设定。

<br>
## 2.3 SystemPolicyObject
```
{
    "statsInboundUplink": false,
    "statsInboundDownlink": false,
    "statsOutboundUplink": false,
    "statsOutboundDownlink": false
}
```

### ①statsInboundUplink: true | false

当值为 true 时，开启所有入站代理的上行流量统计。

### ②statsInboundDownlink: true | false

当值为 true 时，开启所有入站代理的下行流量统计。

### ③statsOutboundUplink: true | false

（ V2Ray 4.26.0+ ）当值为 true 时，开启所有出站代理的上行流量统计。

### ④statsOutboundDownlink: true | false

（ V2Ray 4.26.0+ ） 当值为 true 时，开启所有出站代理的下行流量统计。


<br>
# 三、高级路由

**①V2RayN高级路由策略PAC设置规则**
```
[
  {
    "outboundTag": "proxy",
    "domain": [
      "#以下三行是GitHub网站，为了不影响下载速度走代理",
      "github.com",
      "githubassets.com",
      "githubusercontent.com",
      "v2fly.org"
    ]
  },
  {
    "outboundTag": "block",
    "domain": [
      "#阻止CrxMouse鼠标手势收集上网数据",
      "mousegesturesapi.com"
    ]
  },
  {
    "outboundTag": "direct",
    "domain": [
      "bitwarden.com",
      "bitwarden.net",
      "baiyunju.cc",
      "letsencrypt.org",
      "adblockplus.org",
      "safesugar.net",
      "#下两行谷歌广告",
      "googleads.g.doubleclick.net",
      "adservice.google.com",
      "#【以下全部是geo预定义域名列表】",
      "#下一行是所有私有域名",
      "geosite:private",
      "#下一行包含常见大陆站点域名和CNNIC管理的大陆域名，即geolocation-cn和tld-cn的合集",
      "geosite:cn",
      "#下一行包含所有Adobe旗下域名",
      "geosite:adobe",
      "#下一行包含所有Adobe正版激活域名",
      "geosite:adobe-activation",
      "#下一行包含所有微软旗下域名",
      "geosite:microsoft",
      "#下一行包含微软msn相关域名少数与上一行微软列表重复",
      "geosite:msn",
      "#下一行包含所有苹果旗下域名",
      "geosite:apple",
      "#下一行包含所有广告平台、提供商域名",
      "geosite:category-ads-all",
      "#下一行包含可直连访问谷歌网址，需要替换为加强版GEO文件，如已手动更新为加强版GEO文件，删除此行前面的#号使其生效",
      "#geosite:google-cn",
      "#下一行包含可直连访问苹果网址，需要替换为加强版GEO文件，如已手动更新为加强版GEO文件，删除此行前面的#号使其生效",
      "#geosite:apple-cn"
    ]
  },
  {
    "type": "field",
    "outboundTag": "proxy",
    "domain": [
      "#GFW域名列表",
      "geosite:gfw",
      "geosite:greatfire"
    ]
  },
  {
    "type": "field",
    "port": "0-65535",
    "outboundTag": "direct"
  }
]
```
>说明：上面V2Ray高级路由规则集，完美实现了PAC代理模式，效果完全一样。其原理是，GFW黑名单中的域名走代理，剩余的其他连接0-65535所有端口的所有国内、外网站流量全部直连。
>如需要更新官方geo文件，请参考[《V2Ray路由规则加强版资源文件geoip.dat、geosite.dat下载网址、更新方法》](https://baiyunju.cc/7583)https://baiyunju.cc/7583　。
>其中，第三行直连域名规则中的域名较多，其实这一行”direct”规则原本可以全部删掉，但是在使用中发现，有一些本来可以直连的域名，也被放入GFW列表中走代理了，为了避免有漏网域名没走直连，因此直接将之前基础路由功能中的直接域名列表复制过来，与后面两行规则并不冲突。


**②Whitelist白名单（绕过大陆代理模式）**
也就是CNNIC 管理的用于中国大陆的顶级域名，以及服务器位于中国内陆的IP，全部直连，其他所有网址代理。

不过，其中有一些可以连接没有被墙的国外网址，也放进了直连规则内，如果不需要可以自己修改。
```
[
  {
    "port": "",
    "outboundTag": "proxy",
    "ip": [],
    "domain": [
      "#以下三行是GitHub网站，为了不影响下载速度走代理",
      "github.com",
      "githubassets.com",
      "githubusercontent.com"
    ],
    "protocol": []
  },
  {
    "type": "field",
    "outboundTag": "block",
    "domain": [
      "#阻止CrxMouse鼠标手势收集上网数据",
      "mousegesturesapi.com",
      "#下一行广告管理平台网址，在ProductivityTab（原iChrome）浏览器插件页面显示",
      "cf-se.com"
    ]
  },
  {
    "type": "field",
    "port": "",
    "outboundTag": "direct",
    "ip": [
      "geoip:private",
      "geoip:cn"
    ],
    "domain": [
      "bitwarden.com",
      "bitwarden.net",
      "gravatar.com",
      "gstatic.com",
      "baiyunju.cc",
      "letsencrypt.org",
      "adblockplus.org",
      "safesugar.net",
      "#下两行谷歌广告",
      "googleads.g.doubleclick.net",
      "adservice.google.com",
      "#【以下全部是geo预定义域名列表】",
      "#下一行包含所有私有域名",
      "geosite:private",
      "#下一行包含常见大陆站点域名和CNNIC管理的大陆域名，即geolocation-cn和tld-cn的合集",
      "geosite:cn",
      "#下一行包含所有Adobe旗下域名",
      "geosite:adobe",
      "#下一行包含所有Adobe正版激活域名",
      "geosite:adobe-activation",
      "#下一行包含所有微软旗下域名",
      "geosite:microsoft",
      "#下一行包含微软msn相关域名少数与上一行微软列表重复",
      "geosite:msn",
      "#下一行包含所有苹果旗下域名",
      "geosite:apple",
      "#下一行包含所有广告平台、提供商域名",
      "geosite:category-ads-all",
      "#下一行包含可直连访问谷歌网址，需要替换为加强版GEO文件，如已手动更新为加强版GEO文件，删除此行前面的#号使其生效",
      "#geosite:google-cn",
      "#下一行包含可直连访问苹果网址，需要替换为加强版GEO文件，如已手动更新为加强版GEO文件，删除此行前面的#号使其生效",
      "#geosite:apple-cn"
    ],
    "protocol": []
  },
  {
    "type": "field",
    "port": "0-65535",
    "outboundTag": "proxy"
  }
]
```

**③全局代理**
所有上网连接全部走代理。
```
[
  {
    "port": "",
    "outboundTag": "block",
    "ip": [],
    "domain": [
      "#阻止CrxMouse鼠标手势收集上网数据",
      "mousegesturesapi.com",
      "#下一行广告管理平台网址，在ProductivityTab（原iChrome）浏览器插件页面显示",
      "cf-se.com"
    ],
    "protocol": []
  },
  {
    "type": "field",
    "port": "0-65535",
    "outboundTag": "proxy"
  }
]
```

**④全局直连**

所有上网连接全部直连。
```
[
  {
    "port": "",
    "outboundTag": "block",
    "ip": [],
    "domain": [
      "#阻止CrxMouse鼠标手势收集上网数据",
      "mousegesturesapi.com",
      "#下一行广告管理平台网址，在ProductivityTab（原iChrome）浏览器插件页面显示",
      "cf-se.com"
    ],
    "protocol": []
  },
  {
    "port": "",
    "outboundTag": "proxy",
    "ip": [],
    "domain": [
      "#下一行ProductivityTab（原iChrome）浏览器插件",
      "ichro.me"
    ],
    "protocol": []
  },
  {
    "type": "field",
    "port": "0-65535",
    "outboundTag": "direct"
  }
]
```


**⑤全局阻断**
阻断所有上网连接。
```
[
  {
    "type": "field",
    "port": "0-65535",
    "outboundTag": "block",
    "ip": [],
    "domain": [],
    "protocol": []
  }
]
```

>**几点重要说明:** 高级路由功能中“预定义规则集列表”中的各行规则，不要随意改变排列顺序。因为，越在上面的规则，优先级别越大。调整顺序后，也会改变代理模式。
例如，在黑名单PAC代理模式规则集中，第二行是“proxy”代理规则，如果里面添加了域名baiyunju.cc，而第三行“direct”直连规则中，也添加了baiyunju.cc这个网址，那么，因为第二行比第三行更靠前，因此baiyunju.cc会按照第二行的规则连接网络，忽略第三行的设置。


**⑥自定义服务器配置代理内网和外网**
```
{
    "log":{
        "access":"",
        "error":"",
        "loglevel":"warning"
    },
    "inbounds":[
        {
            "tag":"socks",
            "port":10808,
            "listen":"0.0.0.0",
            "protocol":"socks",
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ]
            },
            "settings":{
                "auth":"noauth",
                "udp":true,
                "allowTransparent":false
            }
        },
        {
            "tag":"http",
            "port":10809,
            "listen":"0.0.0.0",
            "protocol":"http",
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ]
            },
            "settings":{
                "udp":false,
                "allowTransparent":false
            }
        }
    ],
    "outbounds":[
        {
            "tag":"proxy_inner",
            "protocol":"vmess",
            "settings":{
                "vnext":[
                    {
                        "address":"ap-east-1.compute.amazonaws.com",
                        "port":6005,
                        "users":[
                            {
                                "id":"xxxxxxxxxx-405E-D56B-7118-0C160D0F3DF9",
                                "email":"792965772@qq.com",
                                "security":"auto"
                            }
                        ]
                    }
                ]
            },
            "streamSettings":{
                "network":"tcp"
            },
            "mux":{
                "enabled":false,
                "concurrency":-1
            }
        },
        {
            "tag":"proxy_outer",
            "protocol":"vmess",
            "settings":{
                "vnext":[
                    {
                        "address":"ap-east-1.compute.amazonaws.com",
                        "port":8003,
                        "users":[
                            {
                                "id":"xxxxxxxx-405E-D56B-7118-0C160D0F3DF9",
                                "email":"792965772@qq.com",
                                "security":"auto"
                            }
                        ]
                    }
                ]
            },
            "streamSettings":{
                "network":"tcp"
            },
            "mux":{
                "enabled":false,
                "concurrency":-1
            }
        },
        {
            "tag":"direct",
            "protocol":"freedom",
            "settings":{

            }
        },
        {
            "tag":"block",
            "protocol":"blackhole",
            "settings":{
                "response":{
                    "type":"http"
                }
            }
        }
    ],
    "routing":{
        "domainStrategy":"IPIfNonMatch",
        "rules":[
            {
                "type":"field",
                "outboundTag":"proxy_outer",
                "domain":[
                    "#以下三行是GitHub网站，为了不影响下载速度走代理",
                    "geosite:github",
                    "geosite:google",
                    "geosite:v2ray",
                    "#GFW域名列表",
                    "geosite:greatfire"
                ],
                "port": "0-65535"
            },
            {
                "type":"field",
                "outboundTag":"proxy_inner",
                "ip":[
                    "192.168.32.0/24",
                    "192.168.101.0/24"
                ],
                "port": "0-65535"
            },
            {
                "type":"field",
                "outboundTag":"proxy_inner",
                "domain":[
                    "gitlab.iotmars.com"
                ],
                "port": "0-65535"
            },
            {
                "type":"field",
                "outboundTag":"block",
                "domain":[
                    "#阻止CrxMouse鼠标手势收集上网数据",
                    "mousegesturesapi.com",
                    "#包含所有广告平台、提供商域名",
                    "geosite:category-ads-all"
                ],
                "port": "0-65535"
            },
            {
                "type":"field",
                "outboundTag":"direct",
                "domain":[
                    "bitwarden.com",
                    "bitwarden.net",
                    "baiyunju.cc",
                    "letsencrypt.org",
                    "adblockplus.org",
                    "safesugar.net",
                    "#下两行谷歌广告",
                    "googleads.g.doubleclick.net",
                    "adservice.google.com",
                    "#【以下全部是geo预定义域名列表】",
                    "#下一行包含常见大陆站点域名和CNNIC管理的大陆域名，即geolocation-cn和tld-cn的合集",
                    "geosite:cn",
                    "#下一行包含所有Adobe旗下域名",
                    "geosite:adobe",
                    "#下一行包含所有Adobe正版激活域名",
                    "geosite:adobe-activation",
                    "#下一行包含所有微软旗下域名",
                    "geosite:microsoft",
                    "#下一行包含微软msn相关域名少数与上一行微软列表重复",
                    "geosite:msn",
                    "#下一行包含所有苹果旗下域名",
                    "geosite:apple",
                    "#下一行包含可直连访问谷歌网址，需要替换为加强版GEO文件，如已手动更新为加强版GEO文件，删除此行前面的#号使其生效",
                    "#geosite:google-cn",
                    "#下一行包含可直连访问苹果网址，需要替换为加强版GEO文件，如已手动更新为加强版GEO文件，删除此行前面的#号使其生效",
                    "#geosite:apple-cn"
                ],
                "port": "0-65535"
            }
        ]
    }
}
```
>注：从上往下匹配，所以需要注意规则摆放顺序

<br>
# 三、域名解析策略
domainStrategy: "AsIs" | "IPIfNonMatch" | "IPOnDemand"
域名解析策略。
- AsIs：只使用域名进行路由选择，默认值；
- IPIfNonMatch：当域名没有匹配任何基于域名的规则时，将域名解析成 IP（A 记录或 AAAA 记录），进行基于 IP 规则的匹配；
当一个域名有多个 IP 地址时，会尝试匹配所有的 IP 地址，直到其中一个与某个 IP 规则匹配为止；
解析后的 IP 仅在路由选择时起作用，转发的数据包中依然使用原始域名。
- IPOnDemand：当匹配时碰到任何基于 IP 的规则，立即将域名解析为 IP 进行匹配。

<br>
**V2Ray域名策略解析选择哪个更好？**
虽然V2Ray官方解释”AsIs”是默认值，但是实际上，在几款主流客户端中，有的默认值是”AsIs”，有的是”IPIfNonMatch”。

因此，选择”AsIs”或”IPIfNonMatch”都可以。

但是，如果在自定义路由设置规则时，添加了匹配IP的路由代理规则，比如geoip:cn、geoip:private，或者直接添加的IP地址规则，那么，建议必须选择位于中间的”IPIfNonMatch”，不然，匹配IP地址的路由规则不会生效。

<br>
# 四、代理模式
“清除系统代理”、“自动配置系统代理”、“不改变系统代理”，是什么意思？应选择哪一个？哪个是V2Ray全局代理？
- “清除系统代理”：禁用Windows系统（IE）代理，不能翻墙；
- “自动配置系统代理”：全局代理模式，所有连接走VPN（再通过V2Ray客户端的路由设置进行分流，达到类似PAC代理模式的效果）；
- “不改变系统代理”：根据Windows设置内的代理状态决定是否开启代理，也就是维持Windows系统（IE）设置。

<br>
# 五、内网代理
启动v2ray，会自动打开计算机的代理模式。![image.png](V2ray路由设置.assetsb1e5c2a2543559f15083b31bba72c.png)

默认配置中，内网地址(包括192.168.\*)是不使用代理的，所以想内网穿透后让v2ray代理内网地址，那么需要进行修改。如需要代理192.168.101.184，则将配置中的192.168.\* 删除。
