---
title: jenkins
categories:
- Jenkins
---
官网介绍：
①创建两个数据卷
docker volume create jenkins-docker-certs
docker volume create jenkins-data
②运行容器
docker container run --name jenkins-tutorial --rm --detach \
  --network jenkins --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client --env DOCKER_TLS_VERIFY=1 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  --volume "$HOME":/home --publish 8080:8080 jenkinsci/blueocean





>docker启动jenkins中可以启动docker：
通过docker启动jenkins，并且docker中可以构建docker镜像：
> #dockerfile
>FROM jenkins:latest
USER root
RUN apt-get update \
      && apt-get upgrade -y \
      && apt-get install -y sudo libltdl-dev \
      && rm -rf /var/lib/apt/lists/*
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers
USER jenkins
>#Here you can install some Jenkins plugins if you want

>启动镜像（在/etc/hosts中添加映射将通过nginx代理到国内镜像）：
docker run --name jenkins -d -p 8081:8080 -p 50001:50000 -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):$(which docker) --add-host updates.jenkins-ci.org:192.168.32.128 jesusperales/jenkins-docker-run-inside

jesusperales/jenkins-docker-run-inside的dockerfile：
```
FROM jenkins/jenkins:lts

LABEL maintainer="jesus.peralesmr@uanl.edu.mx"

USER root
RUN apt-get update \
      && apt-get upgrade -y \
      && apt-get install -y sudo libltdl-dev \
      && rm -rf /var/lib/apt/lists/*
RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

USER jenkins
```

因为默认是jenkins用户登录，需要添加docker权限：
sudo groupadd docker 
sudo usermod -aG docker jenkins
sudo cat /etc/group
sudo chmod a+rw /var/run/docker.sock


>#更改jenkins的默认镜像源
>方式一：修改镜像源的url地址(因为jenkins会通过数字签名验证镜像源是否有效，所以这个方法不可靠)：
①$ cd {你的Jenkins工作目录}/updates  #进入更新配置位置
②$ vim default.json  
在vim中替换官方镜像源为清华镜像源
1）:1,$s/http:\/\/updates.jenkins-ci.org\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g
2）:1,$s/http:\/\/www.google.com/https:\/\/www.baidu.com/g
③或通过sed命令替换$ sed -i 's/http:\/\/updates.jenkins-ci.org\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g' default.json && sed -i 's/http:\/\/www.google.com/https:\/\/www.baidu.com/g' default.json
>
>方式二：将请求引向nginx，重定向到清华镜像源
https://blog.csdn.net/scc95599/article/details/104656973
①hosts文件添加127.0.0.1   updates.jenkins-ci.org
②安装docker版nginx，添加如下配置到/etc/nginx/conf.d/default.conf文件：
location /download/plugins {
        proxy_next_upstream http_502 http_504 error timeout invalid_header;
        proxy_set_header Host mirrors.tuna.tsinghua.edu.cn;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        rewrite /download/plugins/(.*) /jenkins/plugins/$1 break;
        proxy_pass https://mirrors.tuna.tsinghua.edu.cn;
}
③启动nginx：docker run -d -p 80:80 -v nginx:/usr/share/nginx/html -v /root/nginx/default.conf:/etc/nginx/conf.d/default.conf --name nginx nginx
注意：需要在docker容器中的hosts添加192.168.32.128   updates.jenkins-ci.org和192.168.32.128   ftp-nyc.osuosl.org。因为重启后hosts会重置，最好在创建容器时添加hosts中的映射ip和域名。


docker安装jenkins：
1.拉取镜像：docker pull jenkinsci/blueocean

> blueocean版本优势：
①.清晰的可视化，对CI/CD pipelines, 可以快速直观的观察项目pipeline状态。
②.pipeline可编辑(开发中)，可视化编辑pipeline，现在只能通过配置中Pipeline的Pipeline script编辑。
pipeline精确度，通过UI直接介入pipeline的中间问题。
③.集成代码分支和pull请求。

2.启动jenkins：sudo docker run -itd -p 8080:8080 -p 50000:50000 --name jenkins --privileged=true  -v jenkins_data:/var/jenkins_home jenkinsci/blueocean

>①-p 8080:8080        映射jenkinsci/blueocean 容器的端口8080到主机上的端口8080。 第一个数字代表主机上的端口，而最后一个代表容器的端口。如果您为此选项指定 -p 49000:8080 ，您将通过端口49000访问主机上的Jenkins。
②-p 50000:50000        可选）将 jenkinsci/blueocean 容器的端口50000 映射到主机上的端口50000。 如果您在其他机器上设置了一个或多个基于JNLP的Jenkins代理程序，而这些代理程序又与 jenkinsci/blueocean 容器交互（充当“主”Jenkins服务器，或者简称为“Jenkins主”）， 则这是必需的。默认情况下，基于JNLP的Jenkins代理通过TCP端口50000与Jenkins主站进行通信。
③-v jenkins-data:/var/jenkins_home        （可选，但强烈建议）映射在容器中的`/var/jenkins_home` 目录到具有名字 jenkins-data 的volume。 如果这个卷不存在，那么这个 docker run 命令会自动为你创建卷。 如果您希望每次重新启动Jenkins（通过此 docker run ... 命令）时保持Jenkins状态，则此选项是必需的 。 
④-v /var/run/docker.sock:/var/run/docker.sock        （可选 /var/run/docker.sock 表示Docker守护程序通过其监听的基于Unix的套接字。 该映射允许 jenkinsci/blueocean 容器与Docker守护进程通信， 如果 jenkinsci/blueocean 容器需要实例化其他Docker容器，则该守护进程是必需的。 


两个问题：
①nginx不能代理docker中的jenkins，因为docker不通过宿主机直接通过虚拟网卡访问外网
②docker中的jenkins不能发送邮件，也是因为jenkins访问的docker容器中的smtp服务，而不是宿主机的smtp服务


附：centos7通过SMTP服务发送邮件：
1.安装mailx程序    yum install -y mailx
2.修改配置文件    vim /etc/mail.rc，添加
set from=18851703029@163.com    # 设置发信人邮箱和昵称
set smtp=smtp.163.com    # smtp地址
set smtp-auth-user=18851703029@163.com    #邮箱账号
set smtp-auth-password=YGFAXZNLYFSIWFTA  #邮箱密码，如果没有权限，则需要填写授权码
set mstp-auth=login     # 认证方式
set ssl-verify=ignore    # 忽略证书警告
3.通过命令发送邮件      echo '请查收，收到请回复' | mail -s '会议' 792965772@qq.com
