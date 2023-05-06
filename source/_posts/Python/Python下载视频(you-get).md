---
title: Python下载视频(you-get)
categories:
- Python
---
###安装you-get
python -m pip install --upgrade pip
pip3 install you-get

注：Windows环境Anaconda遇“Can't connect to HTTPS URL because the SSL module is not available”情况，需要把D:\Anaconda3\Libraryin下的libcrypto-1_1-x64.*和libssl-1_1-x64.*的所有文件复制到D:\Anaconda3\DLLs文件夹下。

###找到视频所在地址
you-get -i https://www.bilibili.com/video/BV1jT4y1772T?from=search&seid=16713774746936702829
```
site:                Bilibili
title:               【2020夏季赛】《狮话狮说》第二期——蛇蛇的咆哮！Huanfeng你别跑！
streams:             # Available quality and codecs
    [ DASH ] ____________________________________
    - format:        dash-flv
      container:     mp4
      quality:       高清 1080P
      size:          96.9 MiB (101589252 bytes)
    # download-with: you-get --format=dash-flv [URL]

    - format:        dash-flv720
      container:     mp4
      quality:       高清 720P
      size:          63.8 MiB (66898519 bytes)
    # download-with: you-get --format=dash-flv720 [URL]
```
获取视频内容和

###下载指定清晰度的视频
you-get --format=dash-flv720 https://www.bilibili.com/video/BV1jT4y1772T?from=search&seid=16713774746936702829

可添加的参数
- -o ：指定存储地址
- -0 ：指定存储文件名称
