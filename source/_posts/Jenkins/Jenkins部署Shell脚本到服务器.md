---
title: Jenkins部署Shell脚本到服务器
categories:
- Jenkins
---
### 部署流程
1. 从GitLab上拉取代码;
2. 将脚本复制到目标服务器上的临时目录下;
3. 远程执行脚本进行测试;
4. 执行成功，则将临时目录下的文件覆盖到正式目录下，并删除临时文件。

### 插件
需要安装如下jenkins插件
- Publish Over SSH
- Generic Webhook Trigger

### pipeline脚本：
```sh
pipeline {
  agent any
  //系统参数配置
  options{
    buildDiscarder(logRotator(numToKeepStr:'1'))  //持久化工件和控制台输出，规定pipeline运行的最大个数
    disableConcurrentBuilds() //设置pipeline不能并行运行，放置同时访问共享资源。
    skipDefaultCheckout() //跳过默认设置的代码check out
    skipStagesAfterUnstable() //一旦构建状态变成unstable不稳定状态，跳过该阶段
    timeout(time:1,unit:'HOURS')  //设置该pipeline运行的超时时间，超时的pipeline会自动被终止
    timestamps()  //为控制台输出增加时间戳
  }
  //变量定义
  environment {
    CREDENTIALSID = 'smartcook'
    GIT_URL = 'http://gitlab.iotmars.com/backend/compass/script-hr.git'
    BRANCH = 'master'
    REMOTE_SERVER_IP = '192.168.32.242'
    REMOTE_SERVER_NAME = 'bigdata1'
    REMOTE_SERVER_CREDENTIALSID = 'server_242'
    EMAIL = '792965772@qq.com'
    PROJECT_NAME = 'Script-HR'
    PROJECT_PATH = '/opt/job'
  }
  //定义触发器
  triggers {
    GenericTrigger(
     genericVariables: [
      [key: 'added', value: '$.commits[*].added'],
      [key: 'modified', value: '$.commits[*].modified'],
      [key: 'removed', value: '$.commits[*].removed'],
      [key: 'commits', value: '$.commits[*]']
     ],

     causeString: 'Triggered on $ref',

     token: 'Script-HR',

     printContributedVariables: true,
     printPostContent: true,

     silentResponse: false
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

    //2.将脚本复制到hive所在服务器上的tmp目录下
    stage('Rsync to remote server'){
      steps{
        script{
            withCredentials([usernamePassword(credentialsId: REMOTE_SERVER_CREDENTIALSID, passwordVariable: 'password', usernameVariable: 'username')]) {
              def remote = [:]
              remote.name = REMOTE_SERVER_NAME
              remote.host = REMOTE_SERVER_IP
              remote.user = username
              remote.password = password
              remote.allowAnyHosts = true
              // sshCommand remote: remote, command: "scp -r * ${username}@${REMOTE_SERVER_IP}:/tmp/${PROJECT_NAME}"
              sshCommand remote: remote, command: "mkdir -p /opt/job/tmp"
              sshPut remote: remote, from: '.', into: '/opt/job/tmp'
              sshCommand remote: remote, command: "mv /opt/job/tmp/workspace /opt/job/tmp/${PROJECT_NAME}"
              sshCommand remote: remote, command: "chmod -R +x /opt/job/tmp/${PROJECT_NAME}/*"
            }
        }
      }
    }
    //3.对修改或新增的脚本进行测试
    stage('Test Script'){
      steps{
        script{
          def adds = added.split(',').reverse()
          def modifys = modified.split(',').reverse()
          def removes = removed.split(',').reverse()
            
          def list = []
            
          adds.eachWithIndex { Object value, int index ->
            def reg = "['\[','\]','\"']"
            add_element = value.replaceAll(reg, "")
            println "added:" + add_element
            if (add_element.length() > 0) {
                list.add(add_element)
            }
            mod_element = modifys[index].replaceAll(reg, "")
            println "modified:" + mod_element
            if (mod_element.length() > 0) {
                list.add(mod_element)
            }
            rem_element = removes[index].replaceAll(reg, "")
            println "removed:" + rem_element
            if (rem_element.length() > 0) {
                list.remove(rem_element)
            }
          }
          
          list.remove(".gitignore")
          
          println "Test Script:"
          println list
          
          list.eachWithIndex { Object value, int index ->
            withCredentials([usernamePassword(credentialsId: REMOTE_SERVER_CREDENTIALSID, passwordVariable: 'password', usernameVariable: 'username')]) {
              def remote = [:]
              remote.name = REMOTE_SERVER_NAME
              remote.host = REMOTE_SERVER_IP
              remote.user = username
              remote.password = password
              remote.allowAnyHosts = true
            //   sshScript remote: remote, script: "/tmp/${PROJECT_NAME}/${value}"
              sshCommand remote: remote, command: "sh /opt/job/tmp/${PROJECT_NAME}/${value}"
            }
          }
        }
      }
    }
    //4.将脚本复制到正式目录下
    stage('Copy to dir'){
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
              sshCommand remote: remote, command: "cp -af /opt/job/tmp/${PROJECT_NAME} ${PROJECT_PATH}/"
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
        withCredentials([usernamePassword(credentialsId: REMOTE_SERVER_CREDENTIALSID, passwordVariable: 'password', usernameVariable: 'username')]) {
          def remote = [:]
          remote.name = REMOTE_SERVER_NAME
          remote.host = REMOTE_SERVER_IP
          remote.user = username
          remote.password = password
          remote.allowAnyHosts = true
          sshCommand remote: remote, command: "rm -rf /opt/job/tmp/${PROJECT_NAME}"
        }
      }
      deleteDir() /* clean up our workspace */
      //archiveArtifacts artifacts: 'build/libs/**/*.jar', fingerprint: true
      //junit 'build/reports/**/*.xml'
      //TODO 添加邮箱服务
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

```
pipeline {
  agent any
  //系统参数配置
  options{
    buildDiscarder(logRotator(numToKeepStr:'1'))  //持久化工件和控制台输出，规定pipeline运行的最大个数
    disableConcurrentBuilds() //设置pipeline不能并行运行，放置同时访问共享资源。
    skipDefaultCheckout() //跳过默认设置的代码check out
    skipStagesAfterUnstable() //一旦构建状态变成unstable不稳定状态，跳过该阶段
    timeout(time:1,unit:'HOURS')  //设置该pipeline运行的超时时间，超时的pipeline会自动被终止
    timestamps()  //为控制台输出增加时间戳
  }
  //变量定义
  environment {
    CREDENTIALSID = 'smartcook'
    GIT_URL = 'http://gitlab.iotmars.com/backend/compass/script-hr.git'
    BRANCH = 'master'
    REMOTE_SERVER_IP = '192.168.32.242'
    REMOTE_SERVER_NAME = 'bigdata1'
    REMOTE_SERVER_CREDENTIALSID = 'server_242'
    EMAIL = '792965772@qq.com'
    PROJECT_NAME = 'Script-HR'
    PROJECT_PATH = '/opt/job'
  }
  //定义触发器
  triggers {
    GenericTrigger(
     genericVariables: [
      [key: 'added', value: '$.commits[*].added'],
      [key: 'modified', value: '$.commits[*].modified'],
      [key: 'removed', value: '$.commits[*].removed'],
      [key: 'commits', value: '$.commits[*]']
     ],

     causeString: 'Triggered on $ref',

     token: 'Script-HR',

     printContributedVariables: true,
     printPostContent: true,

     silentResponse: false
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

    //2.将脚本复制到hive所在服务器上的tmp目录下
    stage('Rsync to remote server'){
      steps{
        script{
            withCredentials([usernamePassword(credentialsId: REMOTE_SERVER_CREDENTIALSID, passwordVariable: 'password', usernameVariable: 'username')]) {
              def remote = [:]
              remote.name = REMOTE_SERVER_NAME
              remote.host = REMOTE_SERVER_IP
              remote.user = username
              remote.password = password
              remote.allowAnyHosts = true
              // sshCommand remote: remote, command: "scp -r * ${username}@${REMOTE_SERVER_IP}:/tmp/${PROJECT_NAME}"
              sshCommand remote: remote, command: "mkdir -p /opt/job/tmp"
              sshPut remote: remote, from: '.', into: '/opt/job/tmp'
              sshCommand remote: remote, command: "mv /opt/job/tmp/workspace /opt/job/tmp/${PROJECT_NAME}"
              sshCommand remote: remote, command: "chmod -R +x /opt/job/tmp/${PROJECT_NAME}/*"
            }
        }
      }
    }
    //3.对修改或新增的脚本进行测试
    stage('Test Script'){
      steps{
        script{
          def adds = added.split('\],\[').reverse()
          println "added:" + adds
          def modifys = modified.split('\],\[').reverse()
          println "modifys:" + modifys
          def removes = removed.split('\],\[').reverse()
          println "removes:" + removes
            
          def list = []
            
          adds.eachWithIndex { Object value, int index ->
            def reg = "['\[''\]''\"']"
            
            add_elements = value.replaceAll(reg, "")
            println "add_elements:" + add_elements
            add_elements.split(',').eachWithIndex { Object element, int i ->
                println "add_element:" + element
                if (element.length() > 0) {
                    list.add(element)
                }
            }
            
            mod_elements = modifys[index].replaceAll(reg, "")
            println "mod_elements:" + mod_elements
            mod_elements.split(',').eachWithIndex { Object element, int i ->
                println "modify_element:" + element
                if (element.length() > 0) {
                    list.add(element)
                }
            }
            
            rem_elements = removes[index].replaceAll(reg, "")
            println "rem_elements:" + rem_elements
            rem_elements.split(',').eachWithIndex { Object element, int i ->
                println "remove_element:" + element
                if (element.length() > 0) {
                    list.remove(element)
                }
            }
          }
          
          list.remove(".gitignore")
          
          list = list.sort { a, b ->
          // 排序,从后往前为 ads -> dwt -> dws -> dwd -> ods
            if (a[0,2]=="ads") {
                return -1
            }
            if (a[0,2]=="dwt" && b[0,2]!="ads") {
                return -1
            }
            if (a[0,2]=="dws" && b[0,2]!="ads" && b[0,2]!="dwt") {
                return -1
            }
            if (a[0,2]=="dwd" && b[0,2]!="ads" && b[0,2]!="dws" && b[0,2]!="dwt") {
                return -1
            }
            if (a[0,2]=="ods" && b[0,2]!="ads" && b[0,2]!="dwt" && b[0,2]!="dws" && b[0,2]!="dwd") {
                return -1
            }
            return 1
          }
          
          println "Test Script:"
          println list
          
          list.eachWithIndex { Object value, int index ->
            withCredentials([usernamePassword(credentialsId: REMOTE_SERVER_CREDENTIALSID, passwordVariable: 'password', usernameVariable: 'username')]) {
              def remote = [:]
              remote.name = REMOTE_SERVER_NAME
              remote.host = REMOTE_SERVER_IP
              remote.user = username
              remote.password = password
              remote.allowAnyHosts = true
            //   sshScript remote: remote, script: "/tmp/${PROJECT_NAME}/${value}"
              sshCommand remote: remote, command: "sh /opt/job/tmp/${PROJECT_NAME}/${value}"
            }
          }
        }
      }
    }
    //4.将脚本复制到正式目录下
    stage('Copy to dir'){
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
              sshCommand remote: remote, command: "cp -af /opt/job/tmp/${PROJECT_NAME} ${PROJECT_PATH}/"
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
        withCredentials([usernamePassword(credentialsId: REMOTE_SERVER_CREDENTIALSID, passwordVariable: 'password', usernameVariable: 'username')]) {
          def remote = [:]
          remote.name = REMOTE_SERVER_NAME
          remote.host = REMOTE_SERVER_IP
          remote.user = username
          remote.password = password
          remote.allowAnyHosts = true
          sshCommand remote: remote, command: "rm -rf /opt/job/tmp/${PROJECT_NAME}"
        }
      }
      deleteDir() /* clean up our workspace */
      //archiveArtifacts artifacts: 'build/libs/**/*.jar', fingerprint: true
      //junit 'build/reports/**/*.xml'
      //TODO 添加邮箱服务
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
