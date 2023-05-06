---
title: Umeng埋点
categories:
- 前端
---
友盟数据上报策略：1.启动时上报 2.关闭时上报 3.周期性上报

#App埋点数据收集流程图：
![image.png](Umeng埋点.assets\55debd3b4cdd4b0e9afc7a19167d6dd8.png)

友盟统计指标：
①用户app激活数据信息明细
②付费订单数据
③拍下订单数据
④注册事件分析数据
⑤获得监测单元列表
⑥获得用户计划列表
⑦获取用户自定义事件
⑧获得点击激活数据
⑨获得计划注册登录数据
⑩获取留存数据

1.用户：设备id，唯一性
2.新增用户：首次打开应用的用户
3.活跃用户：指定时间段内打开过app的用户
4.月活率：活跃用户/总用户数
5.沉默用户：两天时间没有启动过app的用户
6.版本分布：计算各版本的新增用户、活跃用户、启动次数
7.本周回流用户：上周没有启动，本周启动的用户
8.连续n周活跃用户：连续n周，每周至少启动一次
9.忠诚用户：连续5周以上活跃用户
10.连续活跃用户：连续两周以上
11.近期流失用户：连续n（2 <= n <= 4）周没有启动应用的用户
12.留存用户
13.用户新鲜度：每天启动应用的新老用户比例
14.单次使用时长：每次启动使用时间长度
15.日使用时长：每天使用累加值


python取数据：
```python
#各类包调用
import requests   
import pandas as pd

#定义获取token的函数，此处相当于获取一个密匙来进一步获取数据
def authorize(user, pasw):
    url = 'http://api.umeng.com/authorize'
    body = {'email': "%s"%(user), 'password': '%s'%(pasw)}
    response = requests.post(url, params = body)
    return response.json()['auth_token']
authorize('XXXXX', 'XXXX')  #参数user代表友盟账号，pasw代表友盟密码，返回token，重要的密匙


#定义获取全部APP的基本数据的函数
def base(auth_token):
    url = 'http://api.umeng.com/apps/base_data?auth_token=%s'%(auth_token)
    response = requests.get(url)
    return response.json()
base('XXXX')#参数auth_token是代表上面获取的token，返回当前app的基本数据，如今日活跃用户、昨日登录用户等


#定义获取app列表的函数，此处可获取到每个app对应的appkey,也是一个重要的密匙，来进一步获取某个app的数据
def apps(auth_token):
    url = 'http://api.umeng.com/apps?&auth_token=%s'%(auth_token)
    response = requests.get(url)
    return response.json()
apps('XXXX')#参数auth_token是代表上面获取的token，返回当前公司的app列表

#定义获取某个app任意日期的基本数据的函数
def base_data(appkey, date, auth_token):
    url = 'http://api.umeng.com/base_data?appkey=%s&date=%s&auth_token=%s'%(appkey,date,auth_token)
    response = requests.get(url)
    return response.json()
base_data('XXXX', 'XXXX-XX-XX', 'XXX')#参数appkey为上述apps获取的结果，date为选择日期的数据，格式为yyyy-mm-dd
```
