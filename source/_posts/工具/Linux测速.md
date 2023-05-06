---
title: Linux测速
categories:
- 工具
---
获取speedtest脚本进行测速
```
wget https://raw.github.com/sivel/speedtest-cli/master/speedtest.py
chmod a+rx speedtest.py
chown root:root speedtest.py
mv speedtest.py /usr/local/bin/speedtest
speedtest
```
```
[root@ip-172-31-34-202 software]# speedtest 
Retrieving speedtest.net configuration...
Testing from Amazon.com (15.152.54.183)...
Retrieving speedtest.net server list...
Selecting best server based on ping...
Hosted by GSL Networks (Tokyo) [395.51 km]: 11.404 ms
Testing download speed................................................................................
Download: 530.86 Mbit/s
Testing upload speed................................................................................................
Upload: 94.70 Mbit/s
```
