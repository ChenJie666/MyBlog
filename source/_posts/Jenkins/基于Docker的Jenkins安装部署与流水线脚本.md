---
title: 基于Docker的Jenkins安装部署与流水线脚本
categories:
- Jenkins
---
# 一. Docker

## 1.1 docker安装

> **安装相关依赖**
> sudo yum install -y yum-utils device-mapper-persistent-data lvm2
>
> **国内源**
> sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
>
> **安装docker**
> sudo yum -y install docker-ce
>
> **服务自启动**
> systemctl enable docker
>
> **设置阿里云镜像**
> sudo mkdir -p /etc/docker
> sudo tee /etc/docker/daemon.json <<-'EOF'
> {
>   "registry-mirrors": ["https://a05qb3lx.mirror.aliyuncs.com"]
> }
> EOF
>
> **启动服务**
> sudo systemctl daemon-reload
> sudo systemctl restart docker

## 1.2 docker常用命令

> **查看所有docker容器**
> docker  ps  -a
>
> **启动新容器**
> docker  run -d --name (指定容器名字) -p (端口):(端口) -v (数据路径):(数据路径) (镜像名):(版本)
>
> **进入容器内部**
> docker  exec  -it  (容器名字)  /bin/bash 
>
> **查看容器的日志**
> docker  logs  (容器名字)	


<br>
# 二. Jenkins

## 2.1 jenkins安装

> **拉取镜像**
> docker pull jesusperales/jenkins-docker-run-inside
>
> **启动镜像**
> docker run --name jenkins -d -p 8080:8080 -p 50000:50000 -v /var/run/docker.sock:/var/run/docker.sock -v \$(which docker):\$(which docker) --add-host updates.jenkins-ci.org:(nginx所在节点的ip地址) jesusperales/jenkins-docker-run-inside
>
> **访问服务**
> http://ip:8080

生产项目中还需要将配置文件(-v /root/jenkins/conf/config.xml:/var/jenkins_home/config.xml)，项目文件等挂载到宿主机上。

## 2.2 参数介绍

> ①-p 8080:8080        jenkins通讯端口。
>
> ②-p 50000:50000       基于JNLP的Jenkins代理通过TCP端口50000与Jenkins主站进行通信，即可以通过浏览器直接执行java应用程序。
>
> ③-v /var/run/docker.sock:/var/run/docker.sock	用于docker客户端与守护进程通讯
>
> ④-v \$(which docker):$(which docker)	docker指令脚本
>
> ⑤--add-host updates.jenkins-ci.org:192.168.32.128	添加本地DNS域名解析

## 2.3 配置

> **修改权限**
> 因为默认是jenkins用户登录，需要添加docker权限
> docker exec  -it  jenkins /bin/bash
> sudo groupadd docker 
> sudo usermod -aG docker jenkins
> sudo cat /etc/group
> sudo chmod a+rw /var/run/docker.sock
>
> **配置maven仓库为阿里云仓库**
>
> 将容器中的配置文件settings.xml复制到宿主机
> docker cp jenkins:/var/jenkins_home/tools/hudson.tasks.Maven_MavenInstallation/mvn3.5.0/conf/settings.xml  ~/
>
> 将<mirror></mirrors>标签内容该为如下配置
>
> ```
> <mirror>
>      <id>alimaven</id>
>      <mirrorOf>central</mirrorOf>
>      <name>aliyun maven</name>
>      <url>http://maven.aliyun.com/nexus/content/repositories/central/</url>
>     </mirror>
> </mirrors>
> ```
>
> 将在宿主机修改完成后的配置文件settings.xml覆盖回容器中
> docker cp jenkins:/var/jenkins_home/tools/hudson.tasks.Maven_MavenInstallation/mvn3.5.0/conf  ~/settings.xml

## 2.4 存在的问题
jenkins需要安装大量的第三方插件，但是所有的数据源都是指向国外仓库，导致国内下载插件缓慢甚至大量失败，因此需要配置国内的镜像源。
![1592498234178.png](基于Docker的Jenkins安装部署与流水线脚本.assets\13e6383c17524be8ab5298d31bc32e68.png)

> 方式一：修改镜像源的url地址(因为jenkins会通过数字签名验证镜像源是否有效，所以这个方法不可靠)：
>
> ①\$ cd {你的Jenkins工作目录}/updates  #进入更新配置位置
> ②\$ vim default.json  
> 在vim中替换官方镜像源为清华镜像源
> 1）http:\/\/updates.jenkins-ci.org\/download/ 替换为 https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins
> 2）/http:\/\/www.google.com/ 替换为 https:\/\/www.baidu.com
> **或通过sed命令替换**
>$ sed -i 's/http:\/\/updates.jenkins-ci.org\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g' default.json && sed -i 's/http:\/\/www.google.com/https:\/\/www.baidu.com/g' default.json

> 方式二：将请求引向nginx，通过nginx进行代理，重定向到清华镜像源，具体见第三章。


<br>
# 三. Nginx

## 3.1 nginx安装

> **拉取镜像**
> docker pull jesusperales/jenkins-docker-run-inside
>
> **启动镜像**
> docker run -d -p 80:80 -p 81:81 -p 82:82 -v /root/nginx/html:/usr/share/nginx/html  -v /root/nginx/nginx.conf:/etc/nginx/nginx.conf  -v /root/nginx/conf.d:/etc/nginx/conf.d -v /root/nginx/log:/var/log/nginx --name nginx nginx



## 3.2 配置文件

> 将请求引向nginx，重定向到清华镜像源
> https://blog.csdn.net/scc95599/article/details/104656973
> ①添加本地DNS域名解析updates.jenkins-ci.org
> echo '127.0.0.1 updates.jenkins-ci.org' >> /etc/hosts
>
> ②创建文件
> vim ~/root/nginx/conf.d/jenkins_redirect.conf
>添加如下配置内容
> ```xml
> server {
>     listen       80;
>     server_name updates.jenkins-ci.org;
> 
>     #charset koi8-r;
>     #access_log  /var/log/nginx/host.access.log  main;
> 
>     location /download/plugins {
> 	proxy_next_upstream http_502 http_504 error timeout invalid_header;
> 	proxy_set_header Host mirrors.tuna.tsinghua.edu.cn;
> 	proxy_set_header X-Real-IP $remote_addr;
> 	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
> 	proxy_set_header Accept-Encoding "";
> 	proxy_set_header Accept-Language "zh-CN";
> 	rewrite /download/plugins/(.*) /jenkins/plugins/$1 break;
> 	proxy_pass https://mirrors.tuna.tsinghua.edu.cn;
>     }
> 
>     location /pub/jenkins/plugins {
> 	proxy_next_upstream http_502 http_504 error timeout invalid_header;
>         proxy_set_header Host mirrors.tuna.tsinghua.edu.cn;
>         proxy_set_header X-Real-IP $remote_addr;
>         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
>         proxy_set_header Accept-Encoding "";
>         proxy_set_header Accept-Language "zh-CN";
>         rewrite /pub/jenkins/plugins/(.*) /jenkins/plugins/$1 break;
>         proxy_pass https://mirrors.tuna.tsinghua.edu.cn;
>     }
> 
> #    location / {
> #        root   /usr/share/nginx/html;
> #        index  index.html index.htm;
> #    }
> 
>     error_page   500 502 503 504  /50x.html;
>     location = /50x.html {
>         root   /usr/share/nginx/html;
>     }
> 
>     access_log  /var/log/nginx/mirrors.access.log;
>     error_log   /var/log/nginx/mirrors.error.log;
> 
> }
> ```


<br>
# 四. Pipeline脚本

## 4.1 自动化部署脚本

####方式一：通过账号密码远程登录

```groovy
pipeline {
  agent any
  //系统参数配置
  options{
    buildDiscarder(logRotator(numToKeepStr:'2'))  //持久化工件和控制台输出，规定pipeline运行的最大个数
    disableConcurrentBuilds() //设置pipeline不能并行运行，放置同时访问共享资源。
    skipDefaultCheckout() //跳过默认设置的代码check out
    skipStagesAfterUnstable() //一旦构建状态变成unstable不稳定状态，跳过该阶段
    timeout(time:1,unit:'HOURS')  //设置该pipeline运行的超时时间，超时的pipeline会自动被终止
    timestamps()  //为控制台输出增加时间戳
  }
  //变量定义
  environment {   
    CREDENTIALSID = 'smartcook'
    GIT_URL = 'http://gitlab.iotmars.com/backend/smartcook/smartcook.git'
    BRANCH = 'dev'
    ALIYUN_NAMESPACE = 'wecook'
    ALIYUN_REPOSITORY = 'menu-center-dev'
    IMAGE_VERSION = '0.0.1-SNAPSHOT'
    DOCKER_CONTAINER_NAME = 'smartcook'
    REMOTE_SERVER_IP = '192.168.32.128'
    REMOTE_SERVER_NAME = 'localhost.localdomain'
    REMOTE_SERVER_CREDENTIALSID = 'server_128'
    REMOTE_REPOSITORY_CREDENTIALSID = 'hxr_aliyun'
    SERVER_PORT = '8002'
    EMAIL = '792965772@qq.com'
  }
  //定义工具
  triggers {
    GenericTrigger (
      genericVariables: [
        [key: 'ref',value: '$.ref']
      ],
      causeString: 'Triggered on $ref',
      token: 'Smartcook_Menu-Center',
            
      printContributedVariables: true,
      printPostContent: true,
            
      silentResponse: false,
            
      regexpFilterText: '$ref',
      regexpFilterExpression: "refs/heads/dev"
    )
  }

  stages {
    //1.拉取源码
    stage('Git Checkout'){
      steps {
        retry(3){
          git (
            branch:"${BRANCH}" ,
            credentialsId:"${CREDENTIALSID}" ,
            url: "${GIT_URL}" ,
            changelog: true 
          )
        }
      }
    }
    //2.编译成jar包
    stage('Maven Build') {
      steps { 
        retry(3){
          sh "mvn -Dmaven.test.failure.ignore=true clean package"
        }
      }
    }
    //3.构建镜像并上传到阿里云镜像仓库
    stage('Build and Push Image'){
      steps{
        withCredentials([usernamePassword(credentialsId: 'hxr_aliyun', passwordVariable: 'password', usernameVariable: 'username')]) {
          script{
            out=sh(script:"ls ./Dockerfile",returnStatus:true)
            println out
            if( out == 2 ){
              println "创建默认Dockerfile"
              sh '''
                cat  <<  EOF  >  Dockerfile
                FROM openjdk:8-jdk-alpine
                VOLUME /tmp
                ADD ./target/*.jar app.jar
                EXPOSE ${SERVER_PORT}
                ENTRYPOINT ["java","-Xmx200m","-Xms200m","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
EOF
              '''
            }
          retry(3){
            sh """
              docker build -t ${DOCKER_CONTAINER_NAME} .
              sudo docker login --username=${username} --password=${password} registry.cn-hangzhou.aliyuncs.com
              sudo docker tag ${DOCKER_CONTAINER_NAME} registry.cn-hangzhou.aliyuncs.com/${ALIYUN_NAMESPACE}/${ALIYUN_REPOSITORY}:${IMAGE_VERSION}
              sudo docker push registry.cn-hangzhou.aliyuncs.com/${ALIYUN_NAMESPACE}/${ALIYUN_REPOSITORY}:${IMAGE_VERSION}
            """
            }
          }
        }
      }
    }
    //4.拉取镜像并启动
    stage('Pull Image and Run'){
      steps{
        retry(3){
          script{
            withCredentials([usernamePassword(credentialsId: REMOTE_SERVER_CREDENTIALSID, passwordVariable: 'password', usernameVariable: 'username')]) {
              def remote = [:]
              remote.name = REMOTE_SERVER_NAME
              remote.host = REMOTE_SERVER_IP
              remote.user = username
              remote.password = password
              remote.allowAnyHosts = true
              withCredentials([usernamePassword(credentialsId: REMOTE_REPOSITORY_CREDENTIALSID, passwordVariable: 'password', usernameVariable: 'username')]) {
                //从阿里云镜像仓库中拉取镜像并启动
                sshCommand remote: remote, command: "sudo docker login --username=\"${username}\" --password=\"${password}\" registry.cn-hangzhou.aliyuncs.com"
                sshCommand remote: remote, command: "sudo docker pull registry.cn-hangzhou.aliyuncs.com/\"${ALIYUN_NAMESPACE}\"/\"${ALIYUN_REPOSITORY}\":\"${IMAGE_VERSION}\""
                sshCommand remote: remote, command: "docker stop \"${DOCKER_CONTAINER_NAME}\" || true"
                sshCommand remote: remote, command: "docker rm  \"${DOCKER_CONTAINER_NAME}\" || true"
                sshCommand remote: remote, command: "docker run -it -d -p \"${SERVER_PORT}\":\"${SERVER_PORT}\" --name \"${DOCKER_CONTAINER_NAME}\" registry.cn-hangzhou.aliyuncs.com/\"${ALIYUN_NAMESPACE}\"/\"${ALIYUN_REPOSITORY}\":\"${IMAGE_VERSION}\""
              }
            }
          }
        }
      }
    }
  }
  post {
    always {
      echo 'This will always run'
      script{
        currentBuild.description = "
 always"
      }
      deleteDir() /* clean up our workspace */
      //archiveArtifacts artifacts: 'build/libs/**/*.jar', fingerprint: true
      //junit 'build/reports/**/*.xml'
      //TODO 添加邮箱服务
    }
    success {
      println("success!!!!!!!")
      script{
        currentBuild.description = "
 success"
      }
      //mail  to: "${EMAIL}", 
      //      subject: "Success Pipeline: ${currentBuild.fullDisplayName}",
      //      body: "Success with ${env.BUILD_URL}" /*该构建的url地址*/
    }
    failure {
      echo 'This will run only if failed'
      script{
        currentBuild.description = "
 failure"
      }
      //mail  to: "${EMAIL}", 
      //      subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
      //      body: "Something is wrong with ${env.BUILD_URL}" /*该构建的url地址*/
    }
  }
}
```


<br>
####方式二：通过设置私钥凭证的方式远程登录

**如果不会写流水线语法，有两种解决方式：**
- 可以访问官网[https://support.cloudbees.com/hc/en-us/articles/203802500-Injecting-Secrets-into-Jenkins-Build-Jobs#inpipelines](https://support.cloudbees.com/hc/en-us/articles/203802500-Injecting-Secrets-into-Jenkins-Build-Jobs#inpipelines)查看如何生成withCredentials的pipeline写法。
- 也可以在项目中点击`流水线语法`来访问片段生成器，如下图所示。
![image.png](基于Docker的Jenkins安装部署与流水线脚本.assets\96ac78c403324bb18bfbbd34aaaa06bd.png)

```groovy
pipeline {
  agent any
  options{
    buildDiscarder(logRotator(numToKeepStr:'2'))  //持久化工件和控制台输出，规定pipeline运行的最大个数
    disableConcurrentBuilds() //设置pipeline不能并行运行，放置同时访问共享资源。
    skipDefaultCheckout() //跳过默认设置的代码check out
    skipStagesAfterUnstable() //一旦构建状态变成unstable不稳定状态，跳过该阶段
    timeout(time:1,unit:'HOURS')  //设置该pipeline运行的超时时间，超时的pipeline会自动被终止
    timestamps()  //为控制台输出增加时间戳
  }
  environment {
    CREDENTIALSID = 'CJsGitlab'
    GIT_URL = 'http://gitlab.iotmars.com/backend/duerosbots.git'
    BRANCH = 'master'
    ALIYUN_NAMESPACE = 'wecook'
    ALIYUN_REPOSITORY = 'menu-center-dev'
    IMAGE_VERSION = '0.0.1-SNAPSHOT'
    DOCKER_CONTAINER_NAME = 'duerosbots'
    REMOTE_SERVER_IP = '121.41.68.248'
    REMOTE_SERVER_NAME = 'iotmars.ecs.area.h03'
    REMOTE_SERVER_CREDENTIALSID = 'server_aliyun_248'
    REMOTE_REPOSITORY_CREDENTIALSID = 'hxr_aliyun'
    SERVER_PORT = '8090'
    EMAIL = '792965772@qq.com'
  }
  //定义工具
  tools {
    maven "mvn3.5.0"
  }
  //定义远程触发器
  triggers {
    GenericTrigger (
      genericVariables: [
        [key: 'ref',value: '$.ref']
      ],
      causeString: 'Triggered on $ref',
      token: 'Smartcook_Menu-Center',
            
      printContributedVariables: true,
      printPostContent: true,
            
      silentResponse: false,
            
      regexpFilterText: '$ref',
      regexpFilterExpression: "refs/heads/dev"
    )
  }

  stages {
    stage('Git Checkout'){
      steps {
        retry(3){
        //1.拉取源码
          git (
            branch:"${BRANCH}" ,
            credentialsId:"${CREDENTIALSID}" ,
            url: "${GIT_URL}" ,
            changelog: true 
          )
        }
      }
    }
    stage('Maven Build') {
      steps { 
        //2.编译成jar包
        retry(3){
          sh "mvn -Dmaven.test.failure.ignore=true clean package"
        }
      }
    }
    stage('Build and Push Image'){
      steps{
        //3.构建镜像
        withCredentials([usernamePassword(credentialsId: REMOTE_REPOSITORY_CREDENTIALSID, passwordVariable: 'password', usernameVariable: 'username')]) {
          script{
            //判断路径下是否有dockerfile文件，没有则创建默认的dockerfile
            out=sh(script:"ls ./Dockerfile",returnStatus:true)
            println out
            if( out == 2 ){
              println "创建默认Dockerfile"
              sh '''
                cat  <<  EOF  >  Dockerfile
                FROM openjdk:8-jdk-alpine
                VOLUME /tmp
                ADD ./target/*.jar app.jar
                EXPOSE ${SERVER_PORT}
                ENTRYPOINT ["java","-Xmx200m","-Xms200m","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
EOF
              '''
            }
          retry(3){
            sh """
              docker build -t ${DOCKER_CONTAINER_NAME} .
              sudo docker login --username=${username} --password=${password} registry.cn-hangzhou.aliyuncs.com
              sudo docker tag ${DOCKER_CONTAINER_NAME} registry.cn-hangzhou.aliyuncs.com/${ALIYUN_NAMESPACE}/${ALIYUN_REPOSITORY}:${IMAGE_VERSION}
              sudo docker push registry.cn-hangzhou.aliyuncs.com/${ALIYUN_NAMESPACE}/${ALIYUN_REPOSITORY}:${IMAGE_VERSION}
            """
            }
          }
        }
      }
    }
    
    stage('Pull Image and Run'){
      steps{
        retry(3){
          script{
          	//通过私钥登录到远程服务器
            withCredentials([sshUserPrivateKey(credentialsId: REMOTE_SERVER_CREDENTIALSID, keyFileVariable: 'keyFile', passphraseVariable: 'passphrase', usernameVariable: 'username')]) {
              def remote = [:]
              remote.name = REMOTE_SERVER_NAME
              remote.host = REMOTE_SERVER_IP
              remote.user = username
              remote.identityFile = keyFile
              remote.port = 22
              remote.allowAnyHosts = true
              withCredentials([usernamePassword(credentialsId: REMOTE_REPOSITORY_CREDENTIALSID, passwordVariable: 'password', usernameVariable: 'username')]) {
                //4.拉取镜像并启动
                sshCommand remote: remote, command: "sudo docker login --username=\"${username}\" --password=\"${password}\" registry.cn-hangzhou.aliyuncs.com"
                sshCommand remote: remote, command: "sudo docker pull registry.cn-hangzhou.aliyuncs.com/\"${ALIYUN_NAMESPACE}\"/\"${ALIYUN_REPOSITORY}\":\"${IMAGE_VERSION}\""
                sshCommand remote: remote, command: "docker stop \"${DOCKER_CONTAINER_NAME}\" || true"
                sshCommand remote: remote, command: "docker rm  \"${DOCKER_CONTAINER_NAME}\" || true"
                sshCommand remote: remote, command: "docker run -it -d -p \"${SERVER_PORT}\":\"${SERVER_PORT}\" --name \"${DOCKER_CONTAINER_NAME}\" registry.cn-hangzhou.aliyuncs.com/\"${ALIYUN_NAMESPACE}\"/\"${ALIYUN_REPOSITORY}\":\"${IMAGE_VERSION}\""
              }
            }
          }
        }
      }
    }
  }
  post {
    always {
      echo 'This will always run'
      script{
        currentBuild.description = "
 always"
      }
      deleteDir() /* clean up our workspace */
      //archiveArtifacts artifacts: 'build/libs/**/*.jar', fingerprint: true
      //junit 'build/reports/**/*.xml'
      //TODO 添加邮箱服务
    }
    success {
      println("success!!!!!!!")
      script{
        currentBuild.description = "
 success"
      }
      //mail  to: "${EMAIL}", 
      //      subject: "Success Pipeline: ${currentBuild.fullDisplayName}",
      //      body: "Success with ${env.BUILD_URL}" /*该构建的url地址*/
    }
    failure {
      echo 'This will run only if failed'
      script{
        currentBuild.description = "
 failure"
      }
      //mail  to: "${EMAIL}", 
      //      subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
      //      body: "Something is wrong with ${env.BUILD_URL}" /*该构建的url地址*/
    }
  }
}   
```


<br>
#### 方式三：通过私钥文件远程登录(将pem文件放到jenkins容器中)

```groovy
pipeline {
  agent any
  options{
    buildDiscarder(logRotator(numToKeepStr:'2'))  //持久化工件和控制台输出，规定pipeline运行的最大个数
    disableConcurrentBuilds() //设置pipeline不能并行运行，放置同时访问共享资源。
    skipDefaultCheckout() //跳过默认设置的代码check out
    skipStagesAfterUnstable() //一旦构建状态变成unstable不稳定状态，跳过该阶段
    timeout(time:1,unit:'HOURS')  //设置该pipeline运行的超时时间，超时的pipeline会自动被终止
    timestamps()  //为控制台输出增加时间戳
  }
  environment {
    CREDENTIALSID = 'CJsGitlab'
    GIT_URL = 'http://gitlab.iotmars.com/backend/duerosbots.git'
    BRANCH = 'master'
    ALIYUN_NAMESPACE = 'wecook'
    ALIYUN_REPOSITORY = 'menu-center-dev'
    IMAGE_VERSION = '0.0.1-SNAPSHOT'
    DOCKER_CONTAINER_NAME = 'duerosbots'
    REMOTE_SERVER_IP = '121.41.68.248'
    REMOTE_SERVER_NAME = 'iotmars.ecs.area.h03'
    REMOTE_SERVER_CREDENTIALSID = 'server_128'
    REMOTE_SERVER_USERNAME = 'root'
    REMOTE_SERVER_IDENTITYFILE = '/home/jenkins/.ssh/M20200509_162337marssenger.pem'
    REMOTE_REPOSITORY_CREDENTIALSID = 'hxr_aliyun'
    SERVER_PORT = '8090'
    EMAIL = '792965772@qq.com'
  }
  //定义工具
  tools {
    maven "mvn3.5.0"
  }
  //定义远程触发器
  triggers {
    GenericTrigger (
      genericVariables: [
        [key: 'ref',value: '$.ref']
      ],
      causeString: 'Triggered on $ref',
      token: 'Smartcook_Menu-Center',
            
      printContributedVariables: true,
      printPostContent: true,
            
      silentResponse: false,
            
      regexpFilterText: '$ref',
      regexpFilterExpression: "refs/heads/dev"
    )
  }

  stages {
    stage('Git Checkout'){
      steps {
        retry(3){
        //1.拉取源码
          git (
            branch:"${BRANCH}" ,
            credentialsId:"${CREDENTIALSID}" ,
            url: "${GIT_URL}" ,
            changelog: true 
          )
        }
      }
    }
    stage('Maven Build') {
      steps { 
        //2.编译成jar包
        retry(3){
          sh "mvn -Dmaven.test.failure.ignore=true clean package"
        }
      }
    }
    stage('Build and Push Image'){
      steps{
        //3.构建镜像
        withCredentials([usernamePassword(credentialsId: 'hxr_aliyun', passwordVariable: 'password', usernameVariable: 'username')]) {
          script{
            out=sh(script:"ls ./Dockerfile",returnStatus:true)
            println out
            if( out == 2 ){
              println "创建默认Dockerfile"
              sh '''
                cat  <<  EOF  >  Dockerfile
                FROM openjdk:8-jdk-alpine
                VOLUME /tmp
                ADD ./target/*.jar app.jar
                EXPOSE ${SERVER_PORT}
                ENTRYPOINT ["java","-Xmx200m","-Xms200m","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
EOF
              '''
            }
          retry(3){
            sh """
              docker build -t ${DOCKER_CONTAINER_NAME} .
              sudo docker login --username=${username} --password=${password} registry.cn-hangzhou.aliyuncs.com
              sudo docker tag ${DOCKER_CONTAINER_NAME} registry.cn-hangzhou.aliyuncs.com/${ALIYUN_NAMESPACE}/${ALIYUN_REPOSITORY}:${IMAGE_VERSION}
              sudo docker push registry.cn-hangzhou.aliyuncs.com/${ALIYUN_NAMESPACE}/${ALIYUN_REPOSITORY}:${IMAGE_VERSION}
            """
            }
          }
        }
      }
    }
    
    stage('Pull Image and Run'){
      steps{
        retry(3){
          script{
            def remote = [:]
            remote.name = REMOTE_SERVER_NAME
            remote.host = REMOTE_SERVER_IP
            remote.user = REMOTE_SERVER_USERNAME
            remote.port = 22
            remote.identityFile = '/home/jenkins/.ssh/M20200509_162337marssenger.pem'
            remote.allowAnyHosts = true
            withCredentials([usernamePassword(credentialsId: REMOTE_REPOSITORY_CREDENTIALSID, passwordVariable: 'password', usernameVariable: 'username')]) {
              //4.拉取镜像并启动
              sshCommand remote: remote, command: "sudo docker login --username=\"${username}\" --password=\"${password}\" registry.cn-hangzhou.aliyuncs.com"
              sshCommand remote: remote, command: "sudo docker pull registry.cn-hangzhou.aliyuncs.com/\"${ALIYUN_NAMESPACE}\"/\"${ALIYUN_REPOSITORY}\":\"${IMAGE_VERSION}\""
              sshCommand remote: remote, command: "docker stop \"${DOCKER_CONTAINER_NAME}\" || true"
              sshCommand remote: remote, command: "docker rm  \"${DOCKER_CONTAINER_NAME}\" || true"
              sshCommand remote: remote, command: "docker run -it -d -p \"${SERVER_PORT}\":\"${SERVER_PORT}\" --name \"${DOCKER_CONTAINER_NAME}\" registry.cn-hangzhou.aliyuncs.com/\"${ALIYUN_NAMESPACE}\"/\"${ALIYUN_REPOSITORY}\":\"${IMAGE_VERSION}\""
            }
          }
        }
      }
    }
  }
  post {
    always {
      echo 'This will always run'
      script{
        currentBuild.description = "
 always"
      }
      deleteDir() /* clean up our workspace */
      //archiveArtifacts artifacts: 'build/libs/**/*.jar', fingerprint: true
      //junit 'build/reports/**/*.xml'
      //TODO 添加邮箱服务
    }
    success {
      println("success!!!!!!!")
      script{
        currentBuild.description = "
 success"
      }
      //mail  to: "${EMAIL}", 
      //      subject: "Success Pipeline: ${currentBuild.fullDisplayName}",
      //      body: "Success with ${env.BUILD_URL}" /*该构建的url地址*/
    }
    failure {
      echo 'This will run only if failed'
      script{
        currentBuild.description = "
 failure"
      }
      //mail  to: "${EMAIL}", 
      //      subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
      //      body: "Something is wrong with ${env.BUILD_URL}" /*该构建的url地址*/
    }
  }
}
```


<br>
## 4.2 pipeline脚本设置

### 4.2.1 脚本路径为配置文件在仓库中的路径

![image.png](基于Docker的Jenkins安装部署与流水线脚本.assets\4a075bc2a9b040df82b527e15e8afa10.png)



### 4.2.2 配置钩子程序
需要安装插件Generic Webhook Trigger

在gitlab的项目settings=>Integrations中设置jenkins项目的url：
http://192.168.32.128:8080/generic-webhook-trigger/invoke?token=Smartcook_Menu-Center

token需要和脚本中的TRIGGER_TOKEN对应
```
 triggers {
    GenericTrigger (
      genericVariables: [
        [key: 'ref',value: '$.ref']
      ],
      causeString: 'Triggered on $ref',
      token: 'Smartcook_Menu-Center',
            
      printContributedVariables: true,
      printPostContent: true,
            
      silentResponse: false,
            
      regexpFilterText: '$ref',
      regexpFilterExpression: "refs/heads/dev"
    )
  }
```

**可以指定前置任务完成后触发**
`triggers { upstream(upstreamProjects: 'Smartcook_Register-Center', threshold: hudson.model.Result.SUCCESS) }`


<br>
## 4.3 邮箱服务设置

### 4.3.1 系统配置

①下载插件Email Extension Plugin
②在**系统配置**中设置**系统管理员邮箱**
![image.png](基于Docker的Jenkins安装部署与流水线脚本.assets\13a8a6bdaa8f49dfbdd7423b2289d803.png)
③在**系统配置**的**Extended E-mail Notification**中进行设置
User Name必须与系统管理员邮箱一致，Password是获取的邮箱第三方登录授权码。
![image.png](基于Docker的Jenkins安装部署与流水线脚本.assets4b455a72b08455eac39ca493b9ac8de.png)



### 4.3.2 邮件脚本(一般添加在pipeline脚本的always{}中)

```html
emailext body: '''<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>${ENV, var="JOB_NAME"}-第${BUILD_NUMBER}次构建日志</title>
</head>

<body leftmargin="8" marginwidth="0" topmargin="8" marginheight="4"
    offset="0">
    <table width="95%" cellpadding="0" cellspacing="0"
        style="font-size: 11pt; font-family: Tahoma, Arial, Helvetica, sans-serif">
        <tr>
            <td>(本邮件是程序自动下发的，请勿回复！)</td>
        </tr>
        <tr>
            <td><h2>
                    <font color="#0000FF">构建结果 - ${BUILD_STATUS}</font>
                </h2></td>
        </tr>
        <tr>
            <td><br />
            <b><font color="#0B610B">构建信息</font></b>
            <hr size="2" width="100%" align="center" /></td>
        </tr>
        <tr>
            <td>
                <ul>
                    <li>项目名称&nbsp;：&nbsp;${PROJECT_NAME}</li>
                    <li>构建编号&nbsp;：&nbsp;第${BUILD_NUMBER}次构建</li>
                    <li>SVN&nbsp;版本：&nbsp;${SVN_REVISION}</li>
                    <li>触发原因：&nbsp;${CAUSE}</li>
                    <li>构建日志：&nbsp;<a href="${BUILD_URL}console">${BUILD_URL}console</a></li>
                    <li>构建&nbsp;&nbsp;Url&nbsp;：&nbsp;<a href="${BUILD_URL}">${BUILD_URL}</a></li>
                    <li>工作目录&nbsp;：&nbsp;<a href="${PROJECT_URL}ws">${PROJECT_URL}ws</a></li>
                    <li>项目&nbsp;&nbsp;Url&nbsp;：&nbsp;<a href="${PROJECT_URL}">${PROJECT_URL}</a></li>
                </ul>
            </td>
        </tr>
        <tr>
            <td><b><font color="#0B610B">Changes Since Last
                        Successful Build:</font></b>
            <hr size="2" width="100%" align="center" /></td>
        </tr>
        <tr>
            <td>
                <ul>
                    <li>历史变更记录 : <a href="${PROJECT_URL}changes">${PROJECT_URL}changes</a></li>
                </ul> ${CHANGES_SINCE_LAST_SUCCESS,reverse=true, format="Changes for Build #%n:<br />%c<br />",showPaths=true,changesFormat="<pre>[%a]<br />%m</pre>",pathFormat="&nbsp;&nbsp;&nbsp;&nbsp;%p"}
            </td>
        </tr>
        <tr>
            <td><b>Failed Test Results</b>
            <hr size="2" width="100%" align="center" /></td>
        </tr>
        <tr>
            <td><pre
                    style="font-size: 11pt; font-family: Tahoma, Arial, Helvetica, sans-serif">$FAILED_TESTS</pre>
                <br /></td>
        </tr>
        <tr>
            <td><b><font color="#0B610B">构建日志 (最后 100行):</font></b>
            <hr size="2" width="100%" align="center" /></td>
        </tr>
        <!-- <tr>
            <td>Test Logs (if test has ran): <a
                href="${PROJECT_URL}ws/TestResult/archive_logs/Log-Build-${BUILD_NUMBER}.zip">${PROJECT_URL}/ws/TestResult/archive_logs/Log-Build-${BUILD_NUMBER}.zip</a>
                <br />
            <br />
            </td>
        </tr> -->
        <tr>
            <td><textarea cols="80" rows="30" readonly="readonly"
                    style="font-family: Courier New">${BUILD_LOG, maxLines=100}</textarea>
            </td>
        </tr>
    </table>
</body>
</html>''', subject: '${BUILD_STATUS} - ${PROJECT_NAME} - Build # ${BUILD_NUMBER} !', to: "${EMAIL}"
```


> ***全局邮件变量解释***
>         \${FILE,path="PATH"} 包括指定文件（路径）的含量相对于工作空间根目录
>         path文件路径，好比你用jenkins+git，他执行Pipeline的时候，找文件的路径就是从拉下来的代码开始
>         \${BUILD_NUMBER} 当前构建的编号
>         \${JOB_DESCRIPTION} 项目描述
>         \${SVN_REVISION} svn版本号。还支持Subversion插件出口的SVN_REVISION_n版本
>         \${CAUSE} 显示谁、通过什么渠道触发这次构建
>         \${CHANGES } -显示上一次构建之后的变化
>         \${BUILD_ID}显示当前构建生成的ID
>         \${PROJECT_NAME} 显示项目的全名
>         \${PROJECT_DISPLAY_NAME} 显示项目的显示名称
>         \${JENKINS_URL} 显示Jenkins服务器的url地址
>         \${BUILD_LOG_MULTILINE_REGEX}按正则表达式匹配并显示构建日志。
>         \${BUILD_LOG} 最终构建日志。
>         \${PROJECT_URL} 显示项目的URL地址。
>         \${BUILD_STATUS} -显示当前构建的状态(失败、成功等等)
>         \${BUILD_URL} -显示当前构建的URL地址。
>         \${CHANGES_SINCE_LAST_SUCCESS} -显示上一次成功构建之后的变化。
>         \${CHANGES_SINCE_LAST_UNSTABLE} -显示显示上一次不稳固或者成功的构建之后的变化。
>         \${FAILED_TESTS} -如果有失败的测试，显示这些失败的单元测试信息。
>         \${JENKINS_URL} -显示Jenkins服务器的地址。(你能在“系统配置”页改变它)。
>         \${PROJECT_URL} -显示项目的URL。
>         \${SVN_REVISION} -显示SVN的版本号。
>         \${TEST_COUNTS} -显示测试的数量。

<br>
# 五、使用LDAP进行登陆认证
进入Manage Jenkins -> Configure Global Security ，在访问控制中选择LDAP，配置如下。用户的权限控制可以通过Manage and Assign Roles来实现。

![image.png](基于Docker的Jenkins安装部署与流水线脚本.assets\4bf27d78c7094c4ca357a31ef156e80f.png)

>`需要注意的是，一旦使用LDAP，那么原来的管理员账户会失效，需要再指定一个LDAP中的用户给其管理员权限，否则LDAP中的全部用户都没有任何权限。`如果不幸的事发生，那么有两个方法来获取管理员权限：
>①LDAP中创建一个与原管理员账号同名的用户，那么该用户就是超级管理员。
>②修改jenkins的配置文件了，该配置文件在docker中的位置是 **/var/jenkins_home/config_cp.xml**，修改内容如下：
>```
><securityRealm class="hudson.security.HudsonPrivateSecurityRealm">    
>    <disableSignup>false</disableSignup>
>    <enableCaptcha>false</enableCaptcha>
></securityRealm>
>```
>修改完成后使用原来的管理员账户进行登陆，重新保存一下LDAP配置，并给一个用户超级管理员角色即可。

以上都完成后，可以使用Test LDAP Settings按钮进行用户登陆测试，user为uid，password为对应的用户密码。

![image.png](基于Docker的Jenkins安装部署与流水线脚本.assets\9d8b0ab1b34c4560b504d734e5621bf9.png)
