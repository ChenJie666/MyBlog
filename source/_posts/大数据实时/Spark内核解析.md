---
title: Spark内核解析
categories:
- 大数据实时
---
rdd和pairrdd：rdd中保存的是v、双v和action类型的函数；pairRDD中保存的是k-v类型的函数。rdd调用k-v类型的函数时会通过RDD的伴生对象中的隐式转换函数implicit def rddToPairRDDFunctions进行二次编译。



spark的url	spark：//host：port

类加载器，加载类和资源（配置文件等）

反射调用方法只是普通调用，不会产生线程和进程，进程是开启一个新的类，线程是thread.start()开启。

多线程的锁是监听器monitor

后台用于处理数据和通讯

spark shell 不能用集群模式

Driver是运行在AM主方法进程上的线程。Driver线程中会执行方法创建上下文。上下文的类可以理解为Driver。

本地化级别：进程本地化（） 节点本地化（） 机架本地化（）

RDD：首选位置

ExecutorBackend，通讯终端的名字是Executor。计算器是Executor对象。

NettyRpcEnv

Dispatcher：调度器

RpcEndpoint：终端的生命周期为constructor -> onStart -> receive* -> onStop



内核术语：

RPC：JVM进程之间进行交互的方式；rpcEvn 环境对象

inbox：收件箱

backend：后台（处理数据和通讯）
endpoint：终端（集群中的节点都是终端）

终端是内部通讯，后台与其他交互。





每个shuffleMapTask和resultTask都有读和写的操作。shuffleMapTask的写方法在类中，resultTask会读取RDD并计算。

分为三部分①整体架构②组件的通讯方式③任务的调度、分配和执行

源码解析：

```scala
向yarn提交了一个任务：
bin/spark-submit \
--class org.apache.spark.examples.SparkPi \
--master yarn \
--deploy-mode client \
./examples/jars/spark-examples_2.11-2.1.1.jar \
100

执行spark-submit脚本，实际开启了一个java虚拟机，执行了SparkSubmit类的main方法，产生sparksubmit进程
exec "${SPARK_HOME}"/bin/spark-class org.apache.spark.deploy.SparkSubmit "$@"

TODO 执行SparkSubmit类的main方法：
  def main(args: Array[String]): Unit = {
    val appArgs = new SparkSubmitArguments(args)//内部通过parse(args.asJava)调用handle方法，handle方法中通过模式匹配将参数赋值给对象属性，将属性封装为SparkSubmitArguments对象

    appArgs.action match {
    //内部通过action = Option(action).getOrElse(SUBMIT)给action赋值为SUBMIT
      case SparkSubmitAction.SUBMIT => submit(appArgs)//执行submit方法，传入封装的参数
      case SparkSubmitAction.KILL => kill(appArgs)
      case SparkSubmitAction.REQUEST_STATUS => requestStatus(appArgs)
    }
  }

TODO 执行submit方法
private def submit(args: SparkSubmitArguments): Unit = {
    val (childArgs, childClasspath, sysProps, childMainClass) = prepareSubmitEnvironment(args)	//将参数进行封装处理，其中childMainClass后面会用到
    doRunMain()	//如果不是单机模式，调用doRunMain方法
    def doRunMain(): Unit = {
        ...
        runMain(childArgs, childClasspath, sysProps, childMainClass, args.verbose)//最后会调用runMain方法
    }
    
TODO 执行runMain方法：
    private def runMain(......): Unit = {
        Thread.currentThread.setContextClassLoader(loader)//装载类加载器
        addJarToClasspath(jar, loader)//加载资源
        //通过反射获取childMainClass的main方法，然后调用main方法
        mainClass = Utils.classForName(childMainClass)
        val mainMethod = mainClass.getMethod("main", new Array[String](0).getClass)
        mainMethod.invoke(null, childArgs.toArray)
    }
    
TODO prepareSubmitEnvironment方法封装childMainClass
    private[deploy] def prepareSubmitEnvironment(args: SparkSubmitArguments)｛
    	var childMainClass = ""
    	if (deployMode == CLIENT || isYarnCluster) {childMainClass = args.mainClass}
    	if (isYarnCluster) {childMainClass = "org.apache.spark.deploy.yarn.Client"}
    	(childArgs, childClasspath, sysProps, childMainClass)	//作为返回值返回
	}
/*
如果是client模式，childMainClass就是args.mainClass，在SparkSubmitArguments类中进行模式匹配：
      case CLASS =>
        mainClass = value
CLASS是“--class”，将命令行中的给定的类传给mainClass；
如果是cluster模式，childMainClass就是"org.apache.spark.deploy.yarn.Client"
*/
所以client模式一上来就运行给定的任务，而cluster模式会先运行client类的main方法。
```

```scala
添加依赖：
<groupId>org.apache.spark</groupId>
<artifactId>spark-yarn_2.11</artifactId>
<version>2.1.1</version>
//进入Client类：
private object Client extends Logging {
    def main(argStrings: Array[String]) {
        val args = new ClientArguments(argStrings)//将参数封装为一个对象
    	new Client(args, sparkConf).run()//新建yarnclient对象并运行run方法
        private val amMemory = ...
        private val amMemoryOverhead = ...
        private val amCores = ...//同时还配置了ApplicationMaster的一些属性
  	}
}
//调用主构造函数会执行构造函数中的可执行语句，新建了yarn的客户端yarnClient
private[spark] class Client(
    val args: ClientArguments,
    val hadoopConf: Configuration,
    val sparkConf: SparkConf)
  extends Logging {
  private val yarnClient = YarnClient.createYarnClient
  private val yarnConf = new YarnConfiguration(hadoopConf)
}
/*
yarnClient继承自YarnClientImpl，也继承了YarnClientImpl中的rmClient和rmAddress，可以认为该yarnClient对象中包含了ResourceManager的url地址，可以与RM进行通讯。
  protected ApplicationClientProtocol rmClient;
  protected InetSocketAddress rmAddress;
*/
//进入new Client(args, sparkConf).run()方法
  def run(): Unit = {
    this.appId = submitApplication()//提交用户应用
    val report = getApplicationReport(appId)//等待提交的返回结果用于展示
    val state = report.getYarnApplicationState
	val (yarnApplicationState, finalApplicationStatus) = monitorApplication(appId)//监听作业的状态
  }
//进入submitApplication（）方法
  def submitApplication(): ApplicationId = {
	  yarnClient.init(yarnConf)//yarnClient即是上面创建的yarn客户端对象
      yarnClient.start()//与yarn进行联通
      //创建提交的appContext
      val containerContext = createContainerLaunchContext(newAppResponse)
      val appContext = createApplicationSubmissionContext(newApp, containerContext)
      yarnClient.submitApplication(appContext)//真正向yarn提交应用
  }
//进入yarnClient的submitApplication（）方法
public ApplicationId submitApplication（ApplicationSubmissionContext appContext）{
    rmClient.submitApplication(request);
}
//进入创建提交对象appContext的createContainerLaunchContext()方法
private def createContainerLaunchContext(newAppResponse: GetNewApplicationResponse)= {
	val amClass =
      if (isClusterMode) {
        Utils.classForName("org.apache.spark.deploy.yarn.ApplicationMaster").getName
      } else {
        Utils.classForName("org.apache.spark.deploy.yarn.ExecutorLauncher").getName
      }
    val amArgs =
      Seq(amClass) ++ userClass ++ userJar ++ primaryPyFile ++ primaryRFile ++ userArgs ++ Seq( "--properties-file", buildPath(YarnSparkHadoopUtil.expandEnvironment(Environment.PWD) , LOCALIZED_CONF_DIR, SPARK_CONF_FILE))
	val commands = prefixEnv ++ Seq(
        YarnSparkHadoopUtil.expandEnvironment(Environment.JAVA_HOME) + "/bin/java", "-server" ) ++ javaOpts ++ amArgs ++
}
/*上面的方法拼接了一个command指令，发往ResourceManager节点，
如果是cluster模式，拼接为/bin/java  org.apache.spark.deploy.yarn.ApplicationMaster启动进程
如果不是cluster模式，拼接为/bin/java  org.apache.spark.deploy.yarn.ExecutorLauncher启动进程
所以启动sparkshell，shell只能启动client模式，所以可以jps看到有ExecutorLauncher进程

尽管client启动了ExecutorLauncher类的main方法，ExecutorLauncher，但是main方法会调用ApplicationMaster的main方法，两者效果一样，进程名字不同。
  def main(args: Array[String]): Unit = {
    ApplicationMaster.main(args)
  }
*/
将拼接的command发往ResourceManager，ResourceManager会在一个节点上启动ApplicationMaster进程。
```

至此，客户端的操作结束了，开始yarn的框架搭建：

```scala
//进入ApplicationMaster类
object ApplicationMaster extends Logging {
  def main(args: Array[String]): Unit = {
    val amArgs = new ApplicationMasterArguments(args)//对参数的封装
  }
  //将RMClient对象作为参数创建AppMaster对象master，那么可以和RM进行交互
  SparkHadoopUtil.get.runAsSparkUser { () =>
      master = new ApplicationMaster(amArgs, new YarnRMClient)
      System.exit(master.run())
  }
}
//进入ApplicationMaster对象的主构造方法
private[spark] class ApplicationMaster(args: ApplicationMasterArguments,
  client: YarnRMClient) extends Logging {
    private val heartbeatInterval = {......}//心跳周期
    
}
//进入run方法
final def run(): Int = {
    val appAttemptId = client.getAttemptId()//这是yarn进行任务时的全局id，即AppMaster进程的id
    if (isClusterMode) {
        runDriver(securityMgr)
      } else {
        runExecutorLauncher(securityMgr)
      }
    
}
/*如果是cluster，执行runDriver方法，即运行Driver类，此时任务划分stage，然后生成taskset
如果不是，执行runExecutorLauncher方法
*/
//进入runExecutorLauncher方法
  private def runExecutorLauncher(securityMgr: SecurityManager): Unit = {
    val port = sparkConf.getInt("spark.yarn.am.port", 0)
    rpcEnv = RpcEnv.create("sparkYarnAM", Utils.localHostName, port, sparkConf, securityMgr,
      clientMode = true)
    val driverRef = waitForSparkDriver()
    addAmIpFilter()
    registerAM(sparkConf, rpcEnv, driverRef, sparkConf.get("spark.driver.appUIAddress", ""),securityMgr)

    // In client mode the actor will stop the reporter thread.
    reporterThread.join()
  }
/*
client模式也需要向RM注册AM，获取资源再进行分配；不同的是少了startUserApplication()方法，没有在AppMaster上启动Driver线程，因为在提交任务的节点上已经启动了Driver线程。所以client模式和cluster模式最大区别在于Driver在提交任务的节点启动还是在AppMaster上启动。
*/
//进入runDriver方法
private def runDriver(securityMgr: SecurityManager): Unit = {
    userClassThread = startUserApplication()//创建Driver线程，生成taskset
    
    rpcEnv = sc.env.rpcEnv//创建交互环境对象
    val driverRef = runAMEndpoint(//通过amEndpoint = rpcEnv.setupEndpoint创建AppMaster终端
          sc.getConf.get("spark.driver.host"),
          sc.getConf.get("spark.driver.port"),
          isClusterMode = true)	//得到Driver的引用
    registerAM(sc.getConf, rpcEnv, driverRef, sc.ui.map(_.appUIAddress).getOrElse(""),
          securityMgr)//向yarn注册AppMaster
}
//进入startUserApplication()方法
private def startUserApplication(): Thread = {
    val userClassLoader = ...... //获取类加载器
    //在ApplicationMasterArguments中将--class的参数封装成了userClass属性★★★
    val mainMethod = userClassLoader.loadClass(args.userClass)
      .getMethod("main", classOf[Array[String]])
    val userThread = new Thread {
        override def run() {
        	mainMethod.invoke(null, userArgs.toArray)//调用用户提交类的main方法，生成sc对象
        }
    }
    userThread.setContextClassLoader(userClassLoader)
    userThread.setName("Driver")//命名为Driver线程
    userThread.start()//启动线程，执行run方法，调用用户提交类的main方法
    userThread//返回Driver线程，Driver线程我们可以获取
}
/*由上可知，我们提交的类不应该称为Driver，而是ApplicationMaster主线程中启动的一个Driver线程，所以jps看不到Driver线程；同时Driver主线程被调用，生成sparkcontext上下文对象，sc中包含了后台的通讯对象CoarseGrainedSchedulerBackend
*/
//进入注册AppMaster的方法registerAM
private def registerAM(...){
    //client是YarnRMClient对象，表示向RM注册并传入参数，申请资源
    allocator = client.register(driverUrl, 
      driverRef,
      yarnConf,
      _sparkConf,
      uiAddress,
      historyAddress,
      securityMgr,
      localResources)
    allocator.allocateResources()//分配资源
}
//进入allocateResources()方法
def allocateResources(): Unit = synchronized {
	val allocatedContainers = allocateResponse.getAllocatedContainers()//返回可用的容器资源
    if (allocatedContainers.size > 0) {
        handleAllocatedContainers(allocatedContainers.asScala)//容器不为空，则分配资源
    }
}
//进入handleAllocatedContainers方法
def handleAllocatedContainers(allocatedContainers: Seq[Container]) = {
    // Match incoming requests by host
    // Match remaining by rack
    // Assign remaining that are neither node-local nor rack-local
    //以上进行本地化操作（进程本地化，节点本地化，机架本地化），将任务与节点关联；然后运行容器
    runAllocatedContainers(containersToUse)
}
//进入runAllocatedContainers方法,为每个可用的container创建NMClient，并启动container
private def runAllocatedContainers(containersToUse: ArrayBuffer[Container]): Unit = {
    for (container <- containersToUse) {
	  launcherPool.execute(new Runnable {//ThreadUtils.newDaemonCachedThreadPool线程池对象
   		override def run(): Unit = {
            new ExecutorRunnable(
                  Some(container),
                  conf,
                  sparkConf,
                  driverUrl,
                  executorId,
                  executorHostname,
                  executorMemory,
                  executorCores,
                  appAttemptId.getApplicationId.toString,
                  securityMgr,
                  localResources
                ).run()	//获取NodeManager客户端，用于连接NodeManager
                updateInternalState() 
        }
      }
    }
}                     
//进入ExecutorRunnable对象的run方法
def run(): Unit = {
    logDebug("Starting Executor Container")
    nmClient = NMClient.createNMClient()//创建nodemanager的客户端
    nmClient.init(conf)
    nmClient.start()//启动nodemanager的客户端
    startContainer()//启动nodemanager中的container
  }
//进入startContainer()方法
def startContainer(): java.util.Map[String, ByteBuffer] = {
    val commands = prepareCommand()
    ctx.setCommands(commands.asJava)
}
//进入prepareCommand()方法
private def prepareCommand(): List[String] = {
    val commands = prefixEnv ++ Seq(
      YarnSparkHadoopUtil.expandEnvironment(Environment.JAVA_HOME) + "/bin/java",
      "-server") ++
      javaOpts ++
    //执行java指令，在NodeManager上创建CoarseGrainedExecutorBackend进程
      Seq("org.apache.spark.executor.CoarseGrainedExecutorBackend",
        "--driver-url", masterAddress,
        "--executor-id", executorId,
        "--hostname", hostname,
        "--cores", executorCores.toString,
        "--app-id", appId) ++
      userClassPath ++
}
/*
最终拼成指令 /bin/java  org.apache.spark.executor.CoarseGrainedExecutorBackend，向nodemanager发送指令运行CoarseGrainedExecutorBackend类，该类是通讯后台，只做通讯，不进行计算
*/
```

在NodeManager上创建CoarseGrainedExecutorBackend进程：

```scala
private[spark] object CoarseGrainedExecutorBackend extends Logging {
    def main(args: Array[String]){
        run(driverUrl, executorId, hostname, cores, appId, workerUrl, userClassPath)
        System.exit(0)
    }
}
//进入run方法
private def run(...){
    val fetcher = RpcEnv.create(//抓取环境对象的信息
        "driverPropsFetcher",
        hostname,
        port,
        executorConf,
        new SecurityManager(executorConf),
        clientMode = true)
    val driver = fetcher.setupEndpointRefByURI(driverUrl)//创建driver的引用
    //通过创建CoarseGrainedExecutorBackend()
    env.rpcEnv.setupEndpoint("Executor", new CoarseGrainedExecutorBackend()
}//将其封装为endpoint，封装时名字为executor，所以也可以称为executor
//进入实现类NettyRpcEnv的setupEndpoint方法
override def setupEndpoint(name: String, endpoint: RpcEndpoint): RpcEndpointRef = {
    dispatcher.registerRpcEndpoint(name, endpoint)//向调度器注册终端程序
}
/*
registerRpcEndpoint方法中会创建一个EndpointData（终端数据）对象，该对象中包含了一个inbox（收件箱）对象，inbox中有一个messages = new LinkedList[InboxMessage]集合，默认会messages.add(OnStart)往里面添加OnStart对象。
RpcEndpoint终端的生命周期为constructor -> onStart -> receive* -> onStop，所有的终端都遵循这个生命周期
*/
//CoarseGrainedExecutorBackend收到onStart信息
rivate[spark] class CoarseGrainedExecutorBackend(...){
    override def onStart() {
        rpcEnv.asyncSetupEndpointRefByURI(driverUrl).flatMap { ref =>
          // This is a very fast action so we can use "ThreadUtils.sameThread"
          driver = Some(ref)
          ref.ask[Boolean](RegisterExecutor(executorId, self, hostname, cores, extractLogUrls))//向driver发送ask请求，反向注册到driver
        }
    }
    override def receive: PartialFunction[Any, Unit] = {
        case RegisteredExecutor => { executor = new Executor(executorId, hostname, env, userClassPath, isLocal = false) }//返回注册成功信息，则创建Executor计算对象★★★
        case LaunchTask(data) => {executor.launchTask(this, taskId = taskDesc.taskId, attemptNumber = taskDesc.attemptNumber,taskDesc.name, taskDesc.serializedTask)}//如果driver端通过CoarseGraineSchedulerBackend对象发送启动任务信息，则启动任务executor.launchTask
}
                             
//Driver类中的SparkContext类中SchedulerBackend类对象处理这个ask请求：
class SparkContext(config: SparkConf) extends Logging {
    private var _schedulerBackend: SchedulerBackend = _
}
//查看SchedulerBackend的实现类CoarseGrainedSchedulerBackend
private[spark] class CoarseGrainedSchedulerBackend(...){
    class DriverEndpoint(//该终端内部类中同样有onStart、receive、onStop方法
        override def onStart(){}
        override def receive={}
        override def receiveAndReply(context: RpcCallContext)= {
         ......
         executorRef.send(RegisteredExecutor)//处理完请求后向注册的Executor发送消息
        }//Driver启动的SparkContext上下文对象的属性中有CoarseGrainedSchedulerBackend类对象，其内部类接收CoarseGrainedExecutorBackend发送的请求并向其进行回复,收到注册成功信息则创建executor对象
        override def onStop(){}
}
```

至此，yarn中的架构建立完成，等待driver发送计算任务。

任务的调度和划分：

```scala
def runJob[T, U: ClassTag](...）{
    dagScheduler.runJob(rdd, cleanedFunc, partitions, callSite, resultHandler, localProperties.get)
}
//进入dagScheduler.runJob方法（DAGScheduler类中）
def submitJob[T, U](...): JobWaiter[U] = {
	eventProcessLoop.post(JobSubmitted(jobId, rdd, func2, partitions.toArray, callSite, waiter,SerializationUtils.clone(properties)))//向阻塞式双端队列中放置任务
}
//进入eventProcessLoop.post方法
def post(event: E): Unit = {
    eventQueue.put(event)//向阻塞式双端队列中放提交的任务（封装在eventProcessLoop对象中）
}
//与此相对应的，在DAGScheduler类中有onReceive方法从队列中取数据
override def onReceive(event: DAGSchedulerEvent): Unit = {
    val timerContext = timer.time()
    try {
      doOnReceive(event)//从eventProcessLoop对象中取队列中的数据
    } finally {
      timerContext.stop()
    }
  }
//进入doOnReceive方法，取数据并判断数据的类型
private def doOnReceive(event: DAGSchedulerEvent): Unit = event match {
    case JobSubmitted(jobId, rdd, func, partitions, callSite, listener, properties) =>
      dagScheduler.handleJobSubmitted(jobId, rdd, func, partitions, callSite, listener, properties)//如果是JobSubmitted，则执行dagScheduler.handleJobSubmitted方法
}
//进入handleJobSubmitted方法
private[scheduler] def handleJobSubmitted(...){
    finalStage = createResultStage(finalRDD, func, partitions, jobId, callSite)       
    val job = new ActiveJob(jobId, finalStage, callSite, listener, properties)       submitStage(finalStage)//提交当前阶段的作业
}
//进入createResultStage方法
private def createResultStage(...){
    val parents = getOrCreateParentStages(rdd, jobId)//得到上级的stages
    val stage = new ResultStage(id, rdd, func, partitions, parents, jobId, callSite)//将上级的stages包装到resultStage中
    stage//将stage返回
}
//
private def getOrCreateParentStages(rdd: RDD[_], firstJobId: Int): List[Stage] = {
    getShuffleDependencies(rdd).map { shuffleDep =>
      getOrCreateShuffleMapStage(shuffleDep, firstJobId)//如果匹配到一个shuffleDep，然后切分为一个stage
    }.toList
}
//进入getShuffleDependencies(rdd)方法
private[scheduler] def getShuffleDependencies(
      rdd: RDD[_]): HashSet[ShuffleDependency[_, _, _]] = {//rdd一定是最后一个shuffleRDD
    val parents = new HashSet[ShuffleDependency[_, _, _]]
    val visited = new HashSet[RDD[_]]
    val waitingForVisit = new Stack[RDD[_]]
    waitingForVisit.push(rdd)
    while (waitingForVisit.nonEmpty) {
      val toVisit = waitingForVisit.pop()
      if (!visited(toVisit)) {
        visited += toVisit
        toVisit.dependencies.foreach {//对只有一个shuffleDependency对象的集合进行遍历
          case shuffleDep: ShuffleDependency[_, _, _] =>
            parents += shuffleDep//将这个shuffleDependency加入到parents集合中
          case dependency =>
            waitingForVisit.push(dependency.rdd)
        }
      }
    }
    parents//只在while循环了一遍，parents中只有一个shuffleDependency对象
  }
//进入dependencies方法
final def dependencies: Seq[Dependency[_]] = {
    checkpointRDD.map(r => List(new OneToOneDependency(r))).getOrElse {
      if (dependencies_ == null) {
        dependencies_ = getDependencies//dependencies_为空，所以调用getDependencies方法
      }
      dependencies_
    }
  }
//进入getDependencies方法
override def getDependencies: Seq[Dependency[_]] = {
    List(new ShuffleDependency(prev, part, serializer, keyOrdering, aggregator, mapSideCombine))//返回只有一个shuffleDependency对象的集合，该对象包含了上一个rdd的信息
}
//getOrCreateShuffleMapStage方法
private def getOrCreateShuffleMapStage(...) = {
    shuffleIdToMapStage.get(shuffleDep.shuffleId) match {
      case Some(stage) =>
        stage

      case None => 
        createShuffleMapStage(shuffleDep, firstJobId)//如果新建了一个stage，则递归调用createShuffleMapStage方法，通过递归，得到所有的stage。
    }
}
//进入createShuffleMapStage方法
def createShuffleMapStage(...) : ShuffleMapStage = {
    val rdd = shuffleDep.rdd//这个rdd是shuffleRDD的上一个rdd
    val numTasks = rdd.partitions.length
    val parents = getOrCreateParentStages(rdd, jobId)//对rdd再次调用getOrCreateParentStages方法
    val stage = new ShuffleMapStage(id, rdd, numTasks, parents, jobId, rdd.creationSite, shuffleDep)
}
/*
再次调用getOrCreateParentStages，得到shuffle前最后一个rdd的所有的依赖，然后从后往前，将每一个窄依赖的rdd进行push到队列中，直到遇到宽依赖的rdd，再次创建stage；直到所有的rdd都被遍历，所有的shuffle都创建了stage；然后从队列中弹栈，因为队列中的rdd都已经visited了，所以都不执行，返回stage的集合parents。
与下面的getMissingParentStages的区别是，getMissingParentStages将所有的stage放到一个集合中，而上面的方法返回一个层层包裹的stage对象，最里层是最开始的stage，最外层是resultStage。
*/
                           
//进入handleJobSubmitted中的submitStage方法
private def submitStage(stage: Stage) {
    if (!waitingStages(stage) && !runningStages(stage) && !failedStages(stage)) {
        val missing = getMissingParentStages(stage).sortBy(_.id)
        logDebug("missing: " + missing)
        if (missing.isEmpty) {
          logInfo("Submitting " + stage + " (" + stage.rdd + "), which has no missing parents")
          submitMissingTasks(stage, jobId.get)//如果没有shuffle，则提交stage
        } else {
          for (parent <- missing) {
            submitStage(parent)//如果有shuffle，则遍历stage，每个stage递归调用次方法的submitMissingTasks方法提交stage
          }
          waitingStages += stage
        }
      }
}
//进入getMissingParentStages(stage)方法（和getOrCreateParentStages方法相同）
private def getMissingParentStages(stage: Stage): List[Stage] = {
    val missing = new HashSet[Stage]
    val visited = new HashSet[RDD[_]]
    // We are manually maintaining a stack here to prevent StackOverflowError
    // caused by recursively visiting
    val waitingForVisit = new Stack[RDD[_]]
    def visit(rdd: RDD[_]) {
      if (!visited(rdd)) {
        visited += rdd
        val rddHasUncachedPartitions = getCacheLocs(rdd).contains(Nil)
        if (rddHasUncachedPartitions) {
          for (dep <- rdd.dependencies) {
            dep match {
              case shufDep: ShuffleDependency[_, _, _] =>
                val mapStage = getOrCreateShuffleMapStage(shufDep, stage.firstJobId)//通过递归调用不断将前一级创建的stage的集合合并到后一级的集合中，直到得到所有的stage，每个stage都有id号。
                if (!mapStage.isAvailable) {
                  missing += mapStage
                }
              case narrowDep: NarrowDependency[_] =>
                waitingForVisit.push(narrowDep.rdd)
            }
          }
        }
      }
    }
    waitingForVisit.push(stage.rdd)
    while (waitingForVisit.nonEmpty) {
      visit(waitingForVisit.pop())
    }
    missing.toList//返回本层递归的值
  }
//进入submitMissingTasks方法,每阶段匹配ShuffleMapStage或ResultStage，查找分区，每个分区新建一个task（DAGScheduler类）
private def submitMissingTasks(stage: Stage, jobId: Int) {
    //匹配stage，返回任务首选位置信息
    val taskIdToLocations: Map[Int, Seq[TaskLocation]] = try {
      stage match {
        case s: ShuffleMapStage =>
          partitionsToCompute.map { id => (id, getPreferredLocs(stage.rdd, id))}.toMap
        case s: ResultStage =>
          partitionsToCompute.map { id =>
            val p = s.partitions(id)
            (id, getPreferredLocs(stage.rdd, p))
          }.toMap
      }
    }
    //匹配stage，根据分区生成task
    val tasks: Seq[Task[_]] = try {
      stage match {
        case stage: ShuffleMapStage =>
          partitionsToCompute.map { id =>
            val locs = taskIdToLocations(id)
            val part = stage.rdd.partitions(id)
            new ShuffleMapTask(stage.id, stage.latestInfo.attemptId,
              taskBinary, part, locs, stage.latestInfo.taskMetrics, properties, Option(jobId),Option(sc.applicationId), sc.applicationAttemptId) 
          }
        case stage: ResultStage =>
          partitionsToCompute.map { id =>
            val p: Int = stage.partitions(id)
            val part = stage.rdd.partitions(p)
            val locs = taskIdToLocations(id)
            new ResultTask(stage.id, stage.latestInfo.attemptId,
              taskBinary, part, locs, id, properties, stage.latestInfo.taskMetrics,
              Option(jobId), Option(sc.applicationId), sc.applicationAttemptId)
          }
      }
    }
    taskScheduler.submitTasks(new TaskSet(tasks.toArray, stage.id, stage.latestInfo.attemptId, jobId, properties))//将每个stage的所有任务封装为TaskSet进行提交
}
//进入partitionsToCompute方法
val partitionsToCompute: Seq[Int] = stage.findMissingPartitions()
//进入findMissingPartitions方法，返回所有的分区
override def findMissingPartitions(): Seq[Int] = {
    val missing = (0 until numPartitions).filter(id => outputLocs(id).isEmpty)
    assert(missing.size == numPartitions - _numAvailableOutputs,
      s"${missing.size} missing, expected ${numPartitions - _numAvailableOutputs}")
    missing
}   
//Stage类中的numPartitions属性值
val numPartitions = rdd.partitions.length//所有stage都是根据最后一个rdd（即shufDep.rdd）创建出来的，所以stage的分区数是根据这个rdd的分区数来决定的
/*
val parents = getOrCreateParentStages(rdd, jobId) 和 val stage = new ShuffleMapStage(id, rdd, numTasks, parents, jobId, rdd.creationSite, shuffleDep) 找到shuffleDep后就会根据该依赖的rdd再次调用方法找到shuffleDep，直到不再有shuffleDep；然后创建stage，返回给上一层，再创建stage，第一次stage，形参层层包裹的stage。所以创建每层stage的都是以最后一个rdd为参数的。
*/     
                           
//进入submitTasks方法
override def submitTasks(taskSet: TaskSet) {
    val manager = createTaskSetManager(taskSet, maxTaskFailures)
    schedulableBuilder.addTaskSetManager(manager, manager.taskSet.properties)//将taskSet包装为taskSetManager，然后加入到rootPool任务池中（schedulableBuilder具体有FIFO和Fair两种实现）
    backend.reviveOffers()//发送信息给自己
}
//进入backend.reviveOffers()方法（CoarseGrainedSchedulerBackend类）
class CoarseGrainedSchedulerBackend（...）{
    class DriverEndpoint(...){  //后台中的内部类--终端
        override def receive: PartialFunction[Any, Unit] = {
            case ReviveOffers =>
            makeOffers()
        }
        override def reviveOffers() {
            driverEndpoint.send(ReviveOffers)//发送信息给自己
        }
    }
}
//CoarseGrainedSchedulerBackend接收
override def receive: PartialFunction[Any, Unit] = {
    case ReviveOffers =>
        makeOffers()//模式匹配后调用makeOffers方法
}               
//进入makeOffers方法
private def makeOffers() {
   val activeExecutors = executorDataMap.filterKeys(executorIsAlive)
   val workOffers = activeExecutors.map { case (id, executorData) =>
        new WorkerOffer(id, executorData.executorHost, executorData.freeCores)
      }.toIndexedSeq//获取可用资源
   launchTasks(scheduler.resourceOffers(workOffers))//在可用资源上启动任务
}
//进入launchTasks方法
private def launchTasks(tasks: Seq[Seq[TaskDescription]]) {
    val serializedTask = ser.serialize(task)//将任务序列化
    //向GoarseGrainedExecutorBackend发送用LaunchTask对象封装后的序列化任务
    executorData.executorEndpoint.send(LaunchTask(new erializableBuffer(serializedTask)))
}
//查看GoarseGrainedExecutorBackend的receive方法
override def receive: PartialFunction[Any, Unit] = {
    case RegisteredExecutor => executor = new Executor(executorId, hostname, env, userClassPath, isLocal = false)
    case LaunchTask(data) => {
    	val taskDesc = ser.deserialize[TaskDescription](data.value)//反序列化任务
    	executor.launchTask(this, taskId = taskDesc.taskId, attemptNumber = taskDesc.attemptNumber,taskDesc.name, taskDesc.serializedTask)//计算对象启动任务
    }
}
//进入executor.launchTask方法(Executor类)
def launchTask(...){
    val taskDesc = ser.deserialize[TaskDescription](data.value)
	val tr = new TaskRunner(context, taskId = taskId, attemptNumber = attemptNumber, taskName,serializedTask)
    runningTasks.put(taskId, tr)
    threadPool.execute(tr)//调用线程池线程执行tr的run（）方法，即ShuffleMapTask和ResultTask的run方法
}
                           
                           
                           
                           
/*
ShuffleMapTask和ResultTask的run方法都继承自父类Task，父类的run方法又会调用子类的runTask方法。ShuffleMapTask的runTask开始执行任务，并会将结果进行写出落盘；
ResultTask的runTask开始执行任务，并会读取
*/
//进入ShuffleMapTask的runTask方法
override def runTask(context: TaskContext): MapStatus = {
    .....
    var writer: ShuffleWriter[Any, Any] = null
    val manager = SparkEnv.get.shuffleManager//获取环境对象中的shuffleManager，shuffleManager只有一个实现类SortShuffleManager，那么manager就是SortShuffleManager
      writer = manager.getWriter[Any, Any](dep.shuffleHandle, partitionId, context)//启动写入流
      writer.write(rdd.iterator(partition, context).asInstanceOf[Iterator[_ <: Product2[Any, Any]]])
      writer.stop(success = true).get
}
//进入manager.getWriter方法，根据传入的参数handle类型不同，采用了不同的shuffle处理方式
override def getWriter[K, V](
      handle: ShuffleHandle,
      mapId: Int,
      context: TaskContext): ShuffleWriter[K, V] = {
    numMapsForShuffle.putIfAbsent(
      handle.shuffleId, handle.asInstanceOf[BaseShuffleHandle[_, _, _]].numMaps)
    val env = SparkEnv.get
    handle match {
      case unsafeShuffleHandle: SerializedShuffleHandle[K @unchecked, V @unchecked] =>
        new UnsafeShuffleWriter(
          env.blockManager,
          shuffleBlockResolver.asInstanceOf[IndexShuffleBlockResolver],
          context.taskMemoryManager(),
          unsafeShuffleHandle,
          mapId,
          context,
          env.conf)
      case bypassMergeSortHandle: BypassMergeSortShuffleHandle[K @unchecked, V @unchecked] =>
        new BypassMergeSortShuffleWriter(
          env.blockManager,
          shuffleBlockResolver.asInstanceOf[IndexShuffleBlockResolver],
          bypassMergeSortHandle,
          mapId,
          context,
          env.conf)
      case other: BaseShuffleHandle[K @unchecked, V @unchecked, _] =>//默认为BaseShuffleHandle
        new SortShuffleWriter(shuffleBlockResolver, other, mapId, context)
    }
  }
/*
如果dep.mapSideCombine为false，则可以为BypassMergeSortShuffleHandle。所以reduceByKey不能采用BypassMergeSortShuffleWriter。reduceByKey的函数中的属性mapSideCombine: Boolean = true默认值为true。创建shuffleRDD：new ShuffledRDD[K, V, C]().setMapSideCombine(mapSideCombine)会传入该属性，所以dep.mapSideCombine得到为true。

private[spark] object SortShuffleWriter {
  def shouldBypassMergeSort(conf: SparkConf, dep: ShuffleDependency[_, _, _]): Boolean = {
    // We cannot bypass sorting if we need to do map-side aggregation.
    if (dep.mapSideCombine) { //不能是会进行预聚合的算子
      require(dep.aggregator.isDefined, "Map-side combine without Aggregator specified!")
      false
    } else {
      val bypassMergeThreshold: Int = conf.getInt("spark.shuffle.sort.bypassMergeThreshold", 200) //从配置文件中获取可以进行bypassmerge的分区数的阈值属性，如果没有则默认为200个分区
      dep.partitioner.numPartitions <= bypassMergeThreshold
    }
  }
}
*/
if (SortShuffleWriter.shouldBypassMergeSort(SparkEnv.get.conf, dependency)) {
	new BypassMergeSortShuffleHandle[K, V]() //如果dep.mapSideCombine为false
}
/*
如果在依赖中声明了聚合器的情况下不能使用UnsafeShuffleWriter。如reduceByKey算子中创建的shuffleRDD：new ShuffledRDD[K, V, C]().setAggregator(aggregator)会指定聚合器，不能用UnsafeShuffleWriter。
def canUseSerializedShuffle(dependency: ShuffleDependency[_, _, _]): Boolean = {
    val shufId = dependency.shuffleId
    val numPartitions = dependency.partitioner.numPartitions
    if (dependency.aggregator.isDefined) { //如果aggregator已经定义了，就不能用UnsafeShuffleWriter写出
      log.debug(
        s"Can't use serialized shuffle for shuffle $shufId because an aggregator is defined")
      false
    } else if (numPartitions > MAX_SHUFFLE_OUTPUT_PARTITIONS_FOR_SERIALIZED_MODE) {//分区数不能大于指定的值1<<24
      log.debug(s"Can't use serialized shuffle for shuffle $shufId because it has more than " +
        s"$MAX_SHUFFLE_OUTPUT_PARTITIONS_FOR_SERIALIZED_MODE partitions")
      false
    } else {
      log.debug(s"Can use serialized shuffle for shuffle $shufId")
      true
    }
  }
}
*/
elseif (SortShuffleManager.canUseSerializedShuffle(dependency)) {
	new SerializedShuffleHandle[K, V]()
}
/*
其他情况
*/
else {
	new BaseShuffleHandle(shuffleId, numMaps, dependency)//所以有预聚合，分区数大于200，有聚合器的情况下只能使用SortShuffleWriter
}
*/

//进入SortShuffleWriter类的write方法
override def write(records: Iterator[Product2[K, V]]): Unit = {
    //如果有预聚合的话用ExternalSorter
    sorter = if (dep.mapSideCombine) {
      require(dep.aggregator.isDefined, "Map-side combine without Aggregator specified!")
      new ExternalSorter[K, V, C](
        context, dep.aggregator, Some(dep.partitioner), dep.keyOrdering, dep.serializer)
    } else {
     //否则用ExternalSorter，两者的参数不同，形成重载
      new ExternalSorter[K, V, V](
        context, aggregator = None, Some(dep.partitioner), ordering = None, dep.serializer)
    }
     sorter.insertAll(records)//向排序器中插入数据进行排序。内部会进行判断，如果需要spill（）溢写磁盘，则会释放内存releaseMemory（）中缓存的已经溢写完成的数据。该溢写方法中记录了批处理大小batchSize、分段segment等信息，和进行溢写的方法，最关键的是partitionId信息，写到对应的磁盘文件中。writeIndexFileAndCommit方法写出数据文件dataFile和indexFile。视频见day10_14
}
                           
                           
                           
//进入ResultTask的runTask方法,读取过程涉及许多方法
override def runTask(context: TaskContext): U = {
    val (rdd, func) = ser.deserialize[(RDD[T], (TaskContext, Iterator[T]) => U)](...)
	func(context, rdd.iterator(partition, context))
}
final def iterator(split: Partition, context: TaskContext): Iterator[T] = {
    if (storageLevel != StorageLevel.NONE) {
      getOrCompute(split, context)//执行
    } else {
      computeOrReadCheckpoint(split, context)
    }
}                        
override def compute(split: Partition, context: TaskContext): Iterator[(K, C)] = {
    val dep = dependencies.head.asInstanceOf[ShuffleDependency[K, V, C]]
    SparkEnv.get.shuffleManager.getReader(dep.shuffleHandle, split.index, split.index + 1, context).read().asInstanceOf[Iterator[(K, C)]]
}
                           
//进入TaskRunner的run方法(Executor类)
override def run(): Unit = {
    task = ser.deserialize[Task[Any]](taskBytes, Thread.currentThread.getContextClassLoader)
    val res = task.run(
            taskAttemptId = taskId,
            attemptNumber = attemptNumber,
            metricsSystem = env.metricsSystem)
}

```



![网络编程](F:/Typora/图片/网络编程.PNG)

序列化+动态代理+远程调用：



java的Runtime.getRuntime().exec(commandStr)可以调用执行cmd指令



new PrintWriter()	

cmd /c notepad打开记事本命令

输出流





BIO(阻塞IO，tomcat默认):进程会一直等待IO处理的数据。
 NIO(非阻塞IO，redis的多路复用)：进程会轮询IO处理是否完成，期间线程不阻塞。
 AIO(异步IO，window系统支持)：如果IO处理完成，会通知进程并将数据缓存在指定位置（类似回调方法），进程不需要关心IO处理。

RDD  PairRDD

GIT  SVN

kafka物理偏移量

indexFile  dataFile两个文件

bypass什么时候起作用：是否是预聚合，bypassMergeThrold<=200。面试重点：需要结合底层代码来讲。底层用的是sortShuffleManager，writer时有多个handle，bypass只是其中一种情况。。。。。。
//所以有预聚合，分区数大于200，有聚合器的情况下只能使用SortShuffleWriter



动态占用机制：重点

所以cache会丢数据，因为动态占用机制可能会淘汰数据。

concurrentHashMap用到了分段锁，线程安全。HashMap线程不安全，HashTable线程安全

storage存储cache数据和广播变量；other存储rdd数据；execution存储计算过程。

钨丝计划：将堆内堆外的内存作为同一管理

去中心化：ngix宕掉整个系统宕机；redis如果一个节点宕掉，集群还能运行；

动态内存管理、静态内存管理、动态占用

Garbage first：面向多核的垃圾回收器（）  -XX:+UseG1GC指定使用G1垃圾回收器

Driver端不用于计算，但是累加器和collect等算计会返回大数据就可能出现OOM



trancient导致rdd为null产生空指针异常就，可以用广播变量解决。

闭包检测会对序列化进行检查。





javaSerial(user,"e:/user.dat");用java序列化器对对象进行序列化并保存到指定路径。
kryoSerial(user,"e:/user.dat");用kryo序列化器对对象进行序列化并保存到指定路径。

kryoDeserial(User.class,"e:/user1.dat")；将指定目录进行反序列为User类对象。

ArrayList和HashMap中的数组属性是用transient修饰的，所以序列化器序列化不了ArrayList和HashMap中的数据；而kryo可以进行序列化。
spark程序从redis中获取到的set集合，因为内部属性是用transcient修饰的，导致无法序列化出现空指针异常。如果因为序列化问题导致空指针异常，可以用广播变量广播。

kryo优势：①序列化后文件是java序列化的10倍，减少网络io  ②能绕过java序列化的机制（如transcient不起作用）
