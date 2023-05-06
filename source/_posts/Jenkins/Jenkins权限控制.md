---
title: Jenkins权限控制
categories:
- Jenkins
---
###系统配置
- 1.jenkins自带的权限配置太简单，需要下载jenkins的插件	
Role-based Authorization Strategy
- 2.打开  系统管理 --> 全局安全配置  会发现多了Role-Based Strategy授权策略，同时系统管理中出现了Manage and Assign Roles选项。
选择Role-Based Strategy，然后在Manage and Assign Roles中对用户权限进行配置
![image.png](Jenkins权限控制.assets\2066e25e22414927ac83e60a1bd0dc41.png)


###权限配置
权限配置分为两部分：
- 管理角色：角色又分为全局角色(Global roles)和项目角色(Item roles)。全局角色中的权限对全局都有效，项目角色中的权限会匹配对应的项目并分配相应的权限。![image.png](Jenkins权限控制.assets\84fb8ad2e2a04fa9bff77db0439a7b37.png)
- 分配角色 ：需要给用户分配全局角色，如果想实现对项目的精细化控制，需要再分配一个项目角色。![image.png](Jenkins权限控制.assets\dbc630d94a85414a9f770dae2218ac67.png)


###权限控制下的远程触发
在开启用户鉴权后使用 GitLab 的 WebHook 来触发 Jenkins 构建时，test 请求就会提示 403 鉴权错误，因为匿名用户没有任务读权限。
**方案一：**
开启匿名用户的 job read 权限。开启 job 的 read 权限后副作用是任何人都可以查看你在 jenkins server 上的构建任务，这对于位于公网上的 jenkins 实例无疑是不安全的。

**方案二：**
通过 Jenkins 的 token 来完成鉴权并向 trigger 的 url 发送请求。步骤如下：
1.  首先获取 Jenkins 用户的 Application ID 和 token。使用一个有效账户登录 Jenkins，然后在左侧边栏中进入 People，选择自己的账户，再点击右侧 Configure，在右部面板找到 API Token 这一栏，点击 Show API Token 即可查看当前用户的 Application ID 和 Token，同时也可以在这里重置 Token。
2.  获取请求地址，在 Job 的 configure 界面，勾选 Build Triggers 下的 Trigger builds remotely，token 自己填写一个，然后得到地址 `JENKINS_URL`
    /job/ `JOB_NAME`
    /build?token= `TOKEN_NAME`
    或者 /buildWithParameters?token= `TOKEN_NAME`
3.  在需要继承系统的 WebHook 中填写该 URL，在 host 前面加上 [Application ID]:[Token]@，比如http://admin:116354ab74c35a62a2d2a44ba308d70b21@192.168.32.128:8080/job/Smartcook_Menu-Center/build?token=Smartcook_Menu-Center

**方案三：**
下载插件
```
    triggers {
        GenericTrigger (
            genericVariables: [
                [key: 'ref',value: '$.ref']
            ],
            causeString: 'Triggered on $ref',
            token: 'trigger_test',
            
            printContributedVariables: true,
            printPostContent: true,
            
            silentResponse: false,
            
            regexpFilterText: '$ref',
            regexpFilterExpression: 'refs/heads/' + 'dev'
        )
    }
```

请求路径：
http://192.168.32.128:8080/generic-webhook-trigger/invoke?token=trigger_test
