---
title: Azkaban
categories:
- 大数据离线
---
[官网](https://azkaban.readthedocs.io/en/latest/createFlows.html)

# 一、脚本编写
## 1.1 Sqoop从Gitlab上拉取脚本
①Git安装
在azkaban-executor节点上安装git
```
yum install -y git 
```
② 拉取脚本
可以在拉取命令中指定
```
nodes:
  - name: cloneScript
    type: command
    config:
      command: git clone -b 
master http://xxx:xxxx@gitlab.iotmars.com/backend/compass/jobscript.git
      retries: 2
      retry.backoff: 5000
```

如果希望避免账号密码外泄，也可以指定默认的账号密码；这里用简单的store模式（认证信息会被明文保存在一个本地文件中，并且没有过期限制）来实现：
```
git config --global credential.helper store
```
默认情况下，所使用的存储文件是~/.git-credentials文件，里面每条凭据一行，一般格式为：
```
http://xxx:xxx@gitlab.iotmars.com
```
这里可以直接填写明文的账号密码。但是为了安全，这里的password一般并不是账户的密码，以Github为例，这里使用的是AccessToken（oauth2:access_token），可以在Settings-Developer Settings-Personal access tokens中生成新的密钥，然后配置git-credentials使用此密钥访问。
配置好credentials服务和密钥后，在其它使用git命令需要认证的时候，就会自动从这里读取用户认证信息完成认证了。


## 1.2 脚本完整版实例
需要创建两个文件，一个文件flow20.project用于指定版本号
```
azkaban-flow-version: 2.0
```
另一个是流程配置文件，示例如下
```
config:
  user.to.proxy: hxr
  failure.emails: 792965772@qq.com

nodes:
  - name: cloneScript
    type: command
    config:
      command: git clone http://gitlab.iotmars.com/backend/compass/jobscript.git
      retries: 2
      retry.backoff: 5000
      
# ----------------------------------------------
      
  - name: hdfs2ods.sh
    type: command
    config:
      command: sh jobscript/hdfs2ods/hdfs2ods.sh all
      retries: 2
      retry.backoff: 5000
    dependsOn:
      - cloneScript
      
# ----------------------------------------------
      
  - name: ods2ba_device_catagory.sh
    type: command
    config:
      command: sh jobscript/ods2ads/ods2ba_device_catagory.sh ${dt}
      retries: 2
      retry.backoff: 5000
    dependsOn:
      - hdfs2ods.sh
```


指定固定的executor执行任务：在Flow Parameters 中 指定参数 useExecutor 为azkaban数据库executors表中注册的节点的id号。
