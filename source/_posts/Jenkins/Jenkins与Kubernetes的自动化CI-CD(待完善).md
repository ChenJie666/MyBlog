---
title: Jenkins与Kubernetes的自动化CI-CD(待完善)
categories:
- Jenkins
---
## **Jenkins与Kubernetes的自动化CI/CD**

### **1概述**

![image.png](Jenkins与Kubernetes的自动化CI-CD(待完善).assets\4cb6f81e6d264ae59b7a792629099410.png)


![image.png](Jenkins与Kubernetes的自动化CI-CD(待完善).assets\3e97105e84e1432fba7c65a96e3b072c.png)


### **2 jenkins在k8s中的部署**

![image.png](Jenkins与Kubernetes的自动化CI-CD(待完善).assets\91d34ed94aef4fc4964f117c11e7056f.png)


如上图所示，Jenkins Master 和 Jenkins Slave 以 Pod 形式运行在 Kubernetes 集群的 Node 上，Master 运行在其中一个节点，并且将其配置数据存储到一个 Volume 上去。Slave 运行在各个节点上，并且它不是一直处于运行状态，它会按照需求动态的创建并自动删除。

创建部署配置文件jenkins.yaml，通过配置文件创建pods和service：

$ kubectl create -f jenkins.yaml

 具体参考博文：https://www.jianshu.com/p/0aef1cc27d3d

优点：Master节点高可用、Slave弹性扩展、易于管理

### **3 Harbor在k8s中的部署**

![image.png](Jenkins与Kubernetes的自动化CI-CD(待完善).assetsfabeb98763f4d5fbe5223796789ee9e.png)



流程说明：

①通过kubectl 命令工具 发起 资源创建kubectl create -f harbor.yaml  ② k8s 处理相关请求后 kube-scheduler 服务 为pod 寻找一个合适的节点并创建pod。  ③ 节点上的kubelet 处理相关资源，使用docker 拉取相关镜像并启动镜像。

创建部署配置文件harbor.yaml，通过配置文件创建pods

kubectl create -f harbor.yml

具体参考博文：https://www.jianshu.com/p/bbb6d3e0beb6

### **2.4pipeline脚本**
```
podTemplate(label:'jnlp-slave',cloud:'kubernetes',containers:[

containerTemplate(

 Name:'jnlp',

Image: ''

alwaysPullImage: true

),

],

Volumes: [

  hostPathVolume(mountPath:'',hostPath:''),

  hostPathVolume(mountPath:'',hostPath:''),

],

imagePullSecrets: ['registry-pull-secret'],

)

{

Node("jnlp-slave"){

//第一步：检出分支

  stage("Git Checkout") {

checkout([$class:'GitSCM',branches:[[name:'$Tag']],doGenerateSubmoduleConfigurations:false,extensions:[], submoduleCfg:[],userRemoteConfigs:[[url:'git@ip:path.git']]])

 }

//第二步：maven构建

  stage("Maven Build"){

sh '''

export JAVA_HOME = path/jdk1.8

      path/maven/bin/mvn clean package -Dmaven.test.skip = true

      git clone git@ip:path.git

      '''

}

//第三步：项目打包成镜像并推送到镜像仓库Harbor中

  stage("Build and Push Image"){

      sh '''

      cat  << EOF  >  Dockerfile

FROM  centos

RUN mkdir  /test

WORKDIR  /test

COPY  ./  /test

EXPOSE  8000

CMD  ["java","-jar","xxx.jar"]

EOF

      docker build -t $REPOSITORY .

      docker login -u 用户名 -p 密码  ip地址

docker push $REPOSITORY

'''

  }

//第四步：部署到Docker主机

  stage("Deploy to K8S"){

sh '''

      cd deploy

sed -i "s/ip/{s/latest/${Tag}/" deploy.yaml

sed -i "s/environment/${Env}/" deploy.yaml

'''

kubernetesDeploy configs:'deploy/deploy.yaml',kubeConfig:[path:''],kubeconfigId:'xxx',secretName:'',ssh:[sshCredentialsId]:'*',sshServer:''],extCredentials:{cretificateAuthorityData:'',clientCertificateData:'',clientKeyData:'',service:[],Url:'https://']

  }

}
```

可以将Pipeline、dockerfile、deployment文件上传到gitlab中进行统一管理。
