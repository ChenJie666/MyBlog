---
title: Maven本地jar包导入本地仓库
categories:
- 工具
---
**azkaban-common包一直下载失败，如何从网上下载jar包然后导入到Mavne本地仓库中？步骤如下：**
①将maven的settings.xml文件中的repository仓库地址修改为idea中指定的repository的地址。（如果idea中配置的respository仓库地址就是setting.xml文件中配置的respository地址，可以忽略此步骤）
```
<localRepository>C:\Users\Administrator\.m2epository</localRepository>
```
②执行命令将本地jar包添加到repository仓库中
```
mvn install:install-file -DgroupId=com.github.azkaban.azkaban -DartifactId=azkaban-common -Dversion=3.16.0 -Dpackaging=jar -Dfile=./azkaban-common-3.16.0.jar
```
③查看仓库目录，可以发现已经导入了azkaban-common包。
