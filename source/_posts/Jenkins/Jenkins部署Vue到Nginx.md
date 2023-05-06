---
title: Jenkins部署Vue到Nginx
categories:
- Jenkins
---
1.安装NodeJS和Publish Over SSH插件

2.配置NodeJS得到版本：

![image.png](Jenkins部署Vue到Nginx.assets\7bcf7f8bd76a481093cb09f6e5405abe.png)

3.在系统设置中配置远程服务器的信息
![image.png](Jenkins部署Vue到Nginx.assets\2fcd600e0f4b432b9901cc72abafb9f8.png)

4.添加Webhooks
http://192.168.32.128:8080/generic-webhook-trigger/invoke?token=Iotmars_CMS_Vue

5.pipeline脚本
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
    CREDENTIALSID = 'smartcook'
    GIT_URL = 'http://gitlab.iotmars.com/loushenghua/zhcpadmin.git'
    BRANCH = 'master'
    EMAIL = '792965772@qq.com'
  }
  tools {
    nodejs 'NodeJS_14.9.0'
  }

  triggers {
    GenericTrigger (
      genericVariables: [
        [key: 'ref',value: '$.ref']
      ],
      causeString: 'Triggered on $ref',
      token: 'Iotmars_CMS_Vue',
            
      printContributedVariables: true,
      printPostContent: true,
            
      silentResponse: false,
            
      regexpFilterText: '$ref',
      regexpFilterExpression: "refs/heads/master"
    )
  }
  
  stages {
    stage('Git Checkout'){
      steps {
        retry(3){
        //1.拉取源码
          git (
            branch:"${BRANCH}" ,
            credentialsId:"${CREDENTIALSID}",
            url: "${GIT_URL}" ,
            changelog: true 
          )
        }
      }
    }
    stage('Vue Build') {
      steps { 
        retry(3){
          //2.打包
        //   nodejs() {
            // some block
        //   }
        //   sh 'node -v'
          sh 'npm -v'
          sh 'npm install'
          sh 'npm run build'
          sh 'tar -zcvf dist.tar dist'
        }
      }
    }
    stage('Push Dist'){
      steps{
        retry(3){
          script{
            //3.部署
            sshPublisher(publishers: [sshPublisherDesc(configName: '128', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: '''source ~/.bash_profile >/dev/null 2>&1;
              cd /root/nginx/html;
              rm -rf iotmars;
              tar -zxvf dist.tar;
              mv dist iotmars;
              rm -rf dist.tar dist;''', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '/', remoteDirectorySDF: false, removePrefix: '', sourceFiles: 'dist.tar')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)]
            )
            sshPublisher(publishers: [sshPublisherDesc(configName: '248', transfers: [sshTransfer(cleanRemote: false, excludes: '', execCommand: '''source ~/.bash_profile >/dev/null 2>&1;
              cd /root/nginx/html;
              rm -rf aliyun;
              tar -zxvf dist.tar;
              mv dist aliyun;
              rm -rf dist.tar dist;''', execTimeout: 120000, flatten: false, makeEmptyDirs: false, noDefaultExcludes: false, patternSeparator: '[, ]+', remoteDirectory: '/', remoteDirectorySDF: false, removePrefix: '', sourceFiles: 'dist.tar')], usePromotionTimestamp: false, useWorkspaceInPromotion: false, verbose: false)]
            )
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
