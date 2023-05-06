---
title: 通过nginx发布IOS包
categories:
- Nginx
---
1. 需要安装nginx并配置支持https协议

2. 编辑 .plist文件：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>items</key>
    <array>
        <dict>
            <key>assets</key>
            <array>
                <dict>
                    <key>kind</key>
                    <string>software-package</string>
                    <key>url</key>
                    <string>https://192.168.32.223/Martian.ipa</string>
                    #设置ipa包的地址
                </dict>
                <dict>
                    <key>kind</key>
                    <string>full-size-image</string>
                    <key>needs-shine</key>
                    <false/>
                    <key>url</key>
                    <string/>
                </dict>
                <dict>
                    <key>kind</key>
                    <string>display-image</string>
                    <key>needs-shine</key>
                    <false/>
                    <key>url</key>
                    <string/>
                </dict>
            </array>
            <key>metadata</key>
            <dict>
                <key>bundle-identifier</key>
                <string>cn.bocweb.Martia</string>
                #设置包的标识id
                <key>bundle-version</key>
                <string>0.2</string>
                <key>kind</key>
                <string>software</string>
                <key>subtitle</key>
                <string>Linked</string>
                <key>title</key>
                <string>Mars</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>v
```


3. 编辑 页面，跳转到 .plist文件
```
<html>
        <head>
                <meta charset="utf-8">
                <title>download</title>
        <head>
        <body>
				<table style="font-size:50px">
					<tr>
						<td>App:  </td>
						<td>Martian.ipa</td>
					</tr>
					<tr>
						<td>版本:  </td>
						<td>0.19</td>
					</tr>
					<tr>
						<td>链接:  </td>
						<td><a href="itms-services:///?action=download-manifest&url=https://192.168.32.223/info.plist">下载</a></td>
					</tr>
				</table>
		</body>
</html>
```
