---
title: Python使用Requests库进行简单接口测试
categories:
- Python
---
#####1. 从本地读取图片并进行base64编码，作为参数进行图像识别请求。并记录总请求次数，失败次数和超时次数。

```py
import requests
import uuid
import base64
import time

with open("C:\Users\Administrator\Desktop\yiguotupain\1.jpg", 'rb') as f:
    base64_data = base64.b64encode(f.read())
    s = base64_data.decode()

uid = uuid.uuid4()
suid = ''.join(str(uid).split('-'))

request_url = "http://openapi.37cang.cn/vis/detectImage"
data = {"imgCode": suid, "imgBase64": s, "imgFormat": "jpg", "modelCode": "CSM2020092100016", "requestType": "10"}
head = {"Content-Type": "application/x-www-form-urlencoded; charset=UTF-8", 'Connection': 'close'}

# 可变参数
request_count = 20
request_interval = 0.1
timeout = 1

timeout_count = 0
failure_count = 0
for i in range(request_count):
    r = requests.post(request_url, data=data)

    # 响应内容
    print(r.text)

    # 失败统计
    if r.status_code != 200:
        failure_count += 1

    # 超时统计
    print(r.elapsed.total_seconds())
    if r.elapsed.total_seconds() >= timeout:
        timeout_count += 1

    # 每次请求间隔时间
    # time.sleep(request_interval)

print("总请求次数：{}, 超时次数{}, 失败次数{}", request_count, timeout_count, failure_count)
```


#####2. 使用线程池进行并发测试
```py
import requests
import uuid
import base64
import threading

with open("C:\Users\Administrator\Desktop\yiguotupain\1.jpg", 'rb') as f:
    base64_data = base64.b64encode(f.read())
    s = base64_data.decode()

uid = uuid.uuid4()
suid = ''.join(str(uid).split('-'))

request_url = "http://openapi.37cang.cn/vis/detectImage"
data = {"imgCode": suid, "imgBase64": s, "imgFormat": "jpg", "modelCode": "CSM2020092100016", "requestType": "10"}
head = {"Content-Type": "application/x-www-form-urlencoded; charset=UTF-8", 'Connection': 'close'}

# 可变参数
request_count = 50
request_interval = 0.1
timeout = 1

timeout_count = 0
failure_count = 0
lock = threading.Lock()


def run(n):
    r = requests.post(request_url, data=data)

    # 响应内容
    print(r.text)

    # 失败统计
    if r.status_code != 200:
        global failure_count
        lock.acquire()
        try:
            failure_count += 1
        finally:
            lock.release()

    # 超时统计
    print(r.elapsed.total_seconds())
    if r.elapsed.total_seconds() >= timeout:
        global timeout_count
        lock.acquire()
        try:
            timeout_count += 1
        finally:
            lock.release()


threads = []
for i in range(request_count):
    t = threading.Thread(target=run, args=("t" + str(i),))
    t.start()
    threads.append(t)
    print("start")

for t in threads:
    t.join()

print("总请求次数:%s, 超时次数:%s, 失败次数:%s" % (request_count, timeout_count, failure_count))
```
