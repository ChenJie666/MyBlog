---
title: Sqoop源码
categories:
- 大数据离线
---
# 一、源码概览
查看sqoop脚本的命令，发现最终会调用org.apache.sqoop.Sqoop类来运行任务。
```
exec ${HADOOP_COMMON_HOME}/bin/hadoop org.apache.sqoop.Sqoop "$@"
```

org.apache.sqoop.Sqoop的main方法如下
```
  public static void main(String [] args) {
    if (args.length == 0) {
      System.err.println("Try 'sqoop help' for usage.");
      System.exit(1);
    }

    int ret = runTool(args);
    System.exit(ret);
  }

  public static int runTool(String [] args) {
    return runTool(args, new Configuration());
  }

  public static int runTool(String [] args, Configuration conf) {
    // Expand the options
    String[] expandedArgs = null;
    try {
      expandedArgs = OptionsFileUtil.expandArguments(args);
    } catch (Exception ex) {
      LOG.error("Error while expanding arguments", ex);
      System.err.println(ex.getMessage());
      System.err.println("Try 'sqoop help' for usage.");
      return 1;
    }

    String toolName = expandedArgs[0];
    Configuration pluginConf = SqoopTool.loadPlugins(conf);
    SqoopTool tool = SqoopTool.getTool(toolName);
    if (null == tool) {
      System.err.println("No such sqoop tool: " + toolName
          + ". See 'sqoop help'.");
      return 1;
    }

    Sqoop sqoop = new Sqoop(tool, pluginConf);
    return runSqoop(sqoop, Arrays.copyOfRange(expandedArgs, 1, expandedArgs.length));
  }
```
如果参数为0，直接退出。否则对参数进行解析并写入到options中，如果参数是options-file，则读取文件并将文件中的配置写入到options中。参数处理如下:
org.apache.sqoop.util.OptionsFileUtil
```
  public static String[] expandArguments(String[] args) throws Exception {
    List<String> options = new ArrayList<String>();

    for (int i = 0; i < args.length; i++) {
      if (args[i].equals(Sqoop.SQOOP_OPTIONS_FILE_SPECIFIER)) {
        if (i == args.length - 1) {
          throw new Exception("Missing options file");
        }

        String fileName = args[++i];
        File optionsFile = new File(fileName);
        BufferedReader reader = null;
        StringBuilder buffer = new StringBuilder();
        try {
          reader = new BufferedReader(new FileReader(optionsFile));
          String nextLine = null;
          while ((nextLine = reader.readLine()) != null) {
            nextLine = nextLine.trim();
            if (nextLine.length() == 0 || nextLine.startsWith("#")) {
              // empty line or comment
              continue;
            }

            buffer.append(nextLine);
            if (nextLine.endsWith("\")) {
              if (buffer.charAt(0) == '\'' || buffer.charAt(0) == '"') {
                throw new Exception(
                    "Multiline quoted strings not supported in file("
                      + fileName + "): " + buffer.toString());
              }
              // Remove the trailing back-slash and continue
              buffer.deleteCharAt(buffer.length()  - 1);
            } else {
              // The buffer contains a full option
              options.add(
                  removeQuotesEncolosingOption(fileName, buffer.toString()));
              buffer.delete(0, buffer.length());
            }
          }

          // Assert that the buffer is empty
          if (buffer.length() != 0) {
            throw new Exception("Malformed option in options file("
                + fileName + "): " + buffer.toString());
          }
        } catch (IOException ex) {
          throw new Exception("Unable to read options file: " + fileName, ex);
        } finally {
          if (reader != null) {
            try {
              reader.close();
            } catch (IOException ex) {
              LOG.info("Exception while closing reader", ex);
            }
          }
        }
      } else {
        // Regular option. Parse it and put it on the appropriate list
        options.add(args[i]);
      }
    }
```
获取所有参数后，取第一个参数，这个参数指定了使用的SqoopTool。框架已经为了我准备了大量的SqoopTool用于数据在不同数据库间流转。
org.apache.sqoop.tool.SqoopTool
```
  static {
    // All SqoopTool instances should be registered here so that
    // they can be found internally.
    TOOLS = new TreeMap<String, Class<? extends SqoopTool>>();
    DESCRIPTIONS = new TreeMap<String, String>();

    registerTool("codegen", CodeGenTool.class,
        "Generate code to interact with database records");
    registerTool("create-hive-table", CreateHiveTableTool.class,
        "Import a table definition into Hive");
    registerTool("eval", EvalSqlTool.class,
        "Evaluate a SQL statement and display the results");
    registerTool("export", ExportTool.class,
        "Export an HDFS directory to a database table");
    registerTool("import", ImportTool.class,
        "Import a table from a database to HDFS");
    registerTool("import-all-tables", ImportAllTablesTool.class,
        "Import tables from a database to HDFS");
    registerTool("import-mainframe", MainframeImportTool.class,
            "Import datasets from a mainframe server to HDFS");
    registerTool("help", HelpTool.class, "List available commands");
    registerTool("list-databases", ListDatabasesTool.class,
        "List available databases on a server");
    registerTool("list-tables", ListTablesTool.class,
        "List available tables in a database");
    registerTool("merge", MergeTool.class,
        "Merge results of incremental imports");
    registerTool("metastore", MetastoreTool.class,
        "Run a standalone Sqoop metastore");
    registerTool("job", JobTool.class,
        "Work with saved jobs");
    registerTool("version", VersionTool.class,
        "Display version information");
  }
```
如果找到SqoopTool，则执行runSqoop
```
  public static int runSqoop(Sqoop sqoop, String [] args) {
    try {
      String [] toolArgs = sqoop.stashChildPrgmArgs(args);
      return ToolRunner.run(sqoop.getConf(), sqoop, toolArgs);
    } catch (Exception e) {
      LOG.error("Got exception running Sqoop: " + e.toString());
      e.printStackTrace();
      if (System.getProperty(SQOOP_RETHROW_PROPERTY) != null) {
        throw new RuntimeException(e);
      }
      return 1;
    }

  }
```
这里执行ToolRunner.run()方法
org.apache.hadoop.util.ToolRunner
```
    public static int run(Configuration conf, Tool tool, String[] args) throws Exception {
        if (conf == null) {
            conf = new Configuration();
        }

        GenericOptionsParser parser = new GenericOptionsParser(conf, args);
        tool.setConf(conf);
        String[] toolArgs = parser.getRemainingArgs();
        return tool.run(toolArgs);
    }
```
虽然看起来是执行的hadoop包中的run方法，但是最终还是执行的Sqoop.run()方法。
org.apache.sqoop.Sqoop
```
  public int run(String [] args) {
    if (options.getConf() == null) {
      // Configuration wasn't initialized until after the ToolRunner
      // got us to this point. ToolRunner gave Sqoop itself a Conf
      // though.
      options.setConf(getConf());
    }

    try {
      options = tool.parseArguments(args, null, options, false);
      tool.appendArgs(this.childPrgmArgs);
      tool.validateOptions(options);
    } catch (Exception e) {
      // Couldn't parse arguments.
      // Log the stack trace for this exception
      LOG.debug(e.getMessage(), e);
      // Print exception message.
      System.err.println(e.getMessage());
      return 1; // Exit on exception here.
    }

    return tool.run(options);
  }
```

parseArguments方法对参数进行解析。
org.apache.sqoop.tool.SqoopTool类
```
  public SqoopOptions parseArguments(String [] args,
      Configuration conf, SqoopOptions in, boolean useGenericOptions)
      throws ParseException, SqoopOptions.InvalidOptionsException {
    SqoopOptions out = in;

    if (null == out) {
      out = new SqoopOptions();
    }

    if (null != conf) {
      // User specified a configuration; use it and override any conf
      // that may have been in the SqoopOptions.
      out.setConf(conf);
    } else if (null == out.getConf()) {
      // User did not specify a configuration, but neither did the
      // SqoopOptions. Fabricate a new one.
      out.setConf(new Configuration());
    }

    // This tool is the "active" tool; bind it in the SqoopOptions.
    //TODO(jarcec): Remove the cast when SqoopOptions will be moved
    //              to apache package
    out.setActiveSqoopTool((com.cloudera.sqoop.tool.SqoopTool)this);

    String [] toolArgs = args; // args after generic parser is done.
    if (useGenericOptions) {
      try {
        toolArgs = ConfigurationHelper.parseGenericOptions(
            out.getConf(), args);
      } catch (IOException ioe) {
        ParseException pe = new ParseException(
            "Could not parse generic arguments");
        pe.initCause(ioe);
        throw pe;
      }
    }

    // Parse tool-specific arguments.
    ToolOptions toolOptions = new ToolOptions();
    configureOptions(toolOptions);
    CommandLineParser parser = new SqoopParser();
    CommandLine cmdLine = parser.parse(toolOptions.merge(), toolArgs, true);
    applyOptions(cmdLine, out);
    this.extraArguments = cmdLine.getArgs();
    return out;
  }
```
真正的参数解析是在SqoopParser这个类的parse方法中。
org.apache.commons.cli.Parser类
```
    public CommandLine parse(Options options, String[] arguments, Properties properties, boolean stopAtNonOption) throws ParseException {
        Iterator it = options.helpOptions().iterator();

        while(it.hasNext()) {
            Option opt = (Option)it.next();
            opt.clearValues();
        }

        this.setOptions(options);
        this.cmd = new CommandLine();
        boolean eatTheRest = false;
        if (arguments == null) {
            arguments = new String[0];
        }

        List tokenList = Arrays.asList(this.flatten(this.getOptions(), arguments, stopAtNonOption));
        ListIterator iterator = tokenList.listIterator();

        while(true) {
            do {
                if (!iterator.hasNext()) {
                    this.processProperties(properties);
                    this.checkRequiredOptions();
                    return this.cmd;
                }

                String t = (String)iterator.next();
                if ("--".equals(t)) {
                    eatTheRest = true;
                } else if ("-".equals(t)) {
                    if (stopAtNonOption) {
                        eatTheRest = true;
                    } else {
                        this.cmd.addArg(t);
                    }
                } else if (t.startsWith("-")) {
                    if (stopAtNonOption && !this.getOptions().hasOption(t)) {
                        eatTheRest = true;
                        this.cmd.addArg(t);
                    } else {
                        this.processOption(t, iterator);
                    }
                } else {
                    this.cmd.addArg(t);
                    if (stopAtNonOption) {
                        eatTheRest = true;
                    }
                }
            } while(!eatTheRest);

            while(iterator.hasNext()) {
                String str = (String)iterator.next();
                if (!"--".equals(str)) {
                    this.cmd.addArg(str);
                }
            }
        }
    }
```
该方法中，将参数和参数的值依次插入到LinkedList中进行存储(使用-和--开头的参数和值都会进行存储)。

参数解析完成后执行run方法中的tool.run(options)方法，随着参数不同，选择的SqoopTool不同，会执行不同的代码。

当我们第一个参数是**import**时，那么使用的SqoopTool是**ImportTool**。
下面是ImportTool的run方法。
org.apache.sqoop.tool.ImportTool
```
  @Override
  public int run(SqoopOptions options) {
    HiveImport hiveImport = null;

    if (allTables) {
      // We got into this method, but we should be in a subclass.
      // (This method only handles a single table)
      // This should not be reached, but for sanity's sake, test here.
      LOG.error("ImportTool.run() can only handle a single table.");
      return 1;
    }

    if (!init(options)) {
      return 1;
    }

    codeGenerator.setManager(manager);

    try {
      if (options.doHiveImport()) {
        hiveImport = new HiveImport(options, manager, options.getConf(), false);
      }

      // Import a single table (or query) the user specified.
      importTable(options, options.getTableName(), hiveImport);
    } catch (IllegalArgumentException iea) {
        LOG.error("Imported Failed: " + iea.getMessage());
        if (System.getProperty(Sqoop.SQOOP_RETHROW_PROPERTY) != null) {
          throw iea;
        }
        return 1;
    } catch (IOException ioe) {
      LOG.error("Encountered IOException running import job: "
          + StringUtils.stringifyException(ioe));
      if (System.getProperty(Sqoop.SQOOP_RETHROW_PROPERTY) != null) {
        throw new RuntimeException(ioe);
      } else {
        return 1;
      }
    } catch (ImportException ie) {
      LOG.error("Error during import: " + ie.toString());
      if (System.getProperty(Sqoop.SQOOP_RETHROW_PROPERTY) != null) {
        throw new RuntimeException(ie);
      } else {
        return 1;
      }
    } finally {
      destroy(options);
    }

    return 0;
  }
```
首先看到执行了init方法
```
  @Override
  protected boolean init(SqoopOptions sqoopOpts) {
    boolean ret = super.init(sqoopOpts);
    codeGenerator.setManager(manager);
    return ret;
  }
```
在run方法中执行init(options)时，会创建数据源管理器manager，具体创建过程如下
org.apache.sqoop.tool.BaseSqoopTool类
```
  protected boolean init(SqoopOptions sqoopOpts) {
    // Get the connection to the database.
    try {
      JobData data = new JobData(sqoopOpts, this);
      this.manager = new ConnFactory(sqoopOpts.getConf()).getManager(data);
      return true;
    } catch (Exception e) {
      LOG.error("Got error creating database manager: "
          + StringUtils.stringifyException(e));
      if (System.getProperty(Sqoop.SQOOP_RETHROW_PROPERTY) != null) {
        throw new RuntimeException(e);
      }
    }

    return false;
  }
```
在run方法中执行init(options)时，会根据命令行参数，利用org.apache.sqoop.ConnFactory生成对应的ConnManager对象，管理各种数据库的访问。
org.apache.sqoop.ConnFactory类
```
  public ConnManager getManager(JobData data) throws IOException {
    com.cloudera.sqoop.SqoopOptions options = data.getSqoopOptions();
    String manualDriver = options.getDriverClassName();
    String managerClassName = options.getConnManagerClassName();

    // User has specified --driver argument, but he did not specified
    // manager to use. We will use GenericJdbcManager as this was
    // the way sqoop was working originally. However we will inform
    // user that specifying connection manager explicitly is more cleaner
    // solution for this case.
    if (manualDriver != null && managerClassName == null) {
      LOG.warn("Parameter --driver is set to an explicit driver however"
        + " appropriate connection manager is not being set (via"
        + " --connection-manager). Sqoop is going to fall back to "
        + GenericJdbcManager.class.getCanonicalName() + ". Please specify"
        + " explicitly which connection manager should be used next time."
      );
      return new GenericJdbcManager(manualDriver, options);
    }

    // If user specified explicit connection manager, let's use it
    if (managerClassName != null){
      ConnManager connManager = null;

      try {
        Class<ConnManager> cls = (Class<ConnManager>)
          Class.forName(managerClassName);

        // We have two constructor options, one is with or without explicit
        // constructor. In most cases --driver argument won't be allowed as the
        // connectors are forcing to use their building class names.
        if (manualDriver == null) {
          Constructor<ConnManager> constructor =
            cls.getDeclaredConstructor(com.cloudera.sqoop.SqoopOptions.class);
          connManager = constructor.newInstance(options);
        } else {
          Constructor<ConnManager> constructor =
            cls.getDeclaredConstructor(String.class,
                                       com.cloudera.sqoop.SqoopOptions.class);
          connManager = constructor.newInstance(manualDriver, options);
        }
      } catch (ClassNotFoundException e) {
        LOG.error("Sqoop could not found specified connection manager class "
          + managerClassName  + ". Please check that you've specified the "
          + "class correctly.");
        throw new IOException(e);
      } catch (NoSuchMethodException e) {
        LOG.error("Sqoop wasn't able to create connnection manager properly. "
          + "Some of the connectors supports explicit --driver and some "
          + "do not. Please try to either specify --driver or leave it out.");
        throw new IOException(e);
      } catch (Exception e) {
        LOG.error("Problem with bootstrapping connector manager:"
          + managerClassName);
        LOG.error(e);
        throw new IOException(e);
      }
      return connManager;
    }
    // Try all the available manager factories.
    for (ManagerFactory factory : factories) {
      LOG.debug("Trying ManagerFactory: " + factory.getClass().getName());
      ConnManager mgr = factory.accept(data);
      if (null != mgr) {
        LOG.debug("Instantiated ConnManager " + mgr.toString());
        return mgr;
      }
    }

    throw new IOException("No manager for connect string: "
        + data.getSqoopOptions().getConnectString());
  }
```

init方法初始化数据库管理器之后，将其赋值给codeGenerator。接着执行importTable方法
```
  protected boolean importTable(SqoopOptions options, String tableName,
      HiveImport hiveImport) throws IOException, ImportException {
    String jarFile = null;

    // Generate the ORM code for the tables.
    jarFile = codeGenerator.generateORM(options, tableName);

    Path outputPath = getOutputPath(options, tableName);

    // Do the actual import.
    ImportJobContext context = new ImportJobContext(tableName, jarFile,
        options, outputPath);

    // If we're doing an incremental import, set up the
    // filtering conditions used to get the latest records.
    if (!initIncrementalConstraints(options, context)) {
      return false;
    }

    if (options.isDeleteMode()) {
      deleteTargetDir(context);
    }

    if (null != tableName) {
      manager.importTable(context);
    } else {
      manager.importQuery(context);
    }

    if (options.isAppendMode()) {
      AppendUtils app = new AppendUtils(context);
      app.append();
    } else if (options.getIncrementalMode() == SqoopOptions.IncrementalMode.DateLastModified) {
      lastModifiedMerge(options, context);
    }

    // If the user wants this table to be in Hive, perform that post-load.
    if (options.doHiveImport()) {
      // For Parquet file, the import action will create hive table directly via
      // kite. So there is no need to do hive import as a post step again.
      if (options.getFileLayout() != SqoopOptions.FileLayout.ParquetFile) {
        hiveImport.importTable(tableName, options.getHiveTableName(), false);
      }
    }

    saveIncrementalState(options);

    return true;
  }
```
通过 this.codeGenerator.generateORM(options, tableName); 来将表结构对应的 java 类写入 jar 文件，这个 jar 文件和其他 options 会构造出一个 ExportJobContext 对象，根据 --update_mode 参数来决定更新方式
org.apache.sqoop.tool.CodeGenTool类
```
  public String generateORM(SqoopOptions options, String tableName)
      throws IOException {
    String existingJar = options.getExistingJarName();
    if (existingJar != null) {
      // This code generator is being invoked as part of an import or export
      // process, and the user has pre-specified a jar and class to use.
      // Don't generate.
      if (manager.isORMFacilitySelfManaged()) {
        // No need to generated any ORM.  Ignore any jar file given on
        // command line also.
        LOG.info("The connection manager declares that it self manages mapping"
            + " between records & fields and rows & columns.  The jar file "
            + " provided will have no effect");
      }
      LOG.info("Using existing jar: " + existingJar);
      return existingJar;
    }
    if (manager.isORMFacilitySelfManaged()) {
      // No need to generated any ORM.  Ignore any jar file given on
      // command line also.
      LOG.info("The connection manager declares that it self manages mapping"
          + " between records & fields and rows & columns.  No class will"
          + " will be generated.");
      return null;
    }
    LOG.info("Beginning code generation");

    if (options.getFileLayout() == SqoopOptions.FileLayout.ParquetFile) {
      String className = options.getClassName() != null ?
          options.getClassName() : options.getTableName();
      if (className.equalsIgnoreCase(options.getTableName())) {
        className = "codegen_" + className;
        options.setClassName(className);
        LOG.info("Will generate java class as " + options.getClassName());
      }
    }

    CompilationManager compileMgr = new CompilationManager(options);
    ClassWriter classWriter = new ClassWriter(options, manager, tableName,
        compileMgr);
    classWriter.generate();
    compileMgr.compile();
    compileMgr.jar();
    String jarFile = compileMgr.getJarFilename();
    this.generatedJarFiles.add(jarFile);
    return jarFile;
  }
```
在 SqoopOptions 类下会保存目标表的所有字段，针对字段会做一个过滤，是否等于 java 保留关键字，如果等于就用在前面加一个 _。
通过调用 orm 包下的 ClassWriter 类的 ClassWriter(SqoopOptions opts, ConnManager connMgr, String table, CompilationManager compMgr) 方法，和 generate() 方法来生成一个 .java 文件，路径保存在 orm 包下的 CompilationManager 类的对象中，再经过 compile() 和 jar() 方法来打包生成 表名.jar 文件。这个jar文件和其他选项会构造出一个ImportJobContext对象。

如果是增量模式，initIncrementalConstraints(options, context)会把IncrementalTestColumn的最大值保存在options.incrementalLastValue属性中，作为下一次增量的起点。
manager利用ImportJobContext对象中的信息完成表数据的导入。
manager完成importTable或importQuery后，程序再根据命令行参数选择将新数据追加到老数据、将新老数据合并或者将新数据导入hive。如果是增量任务，整个ImportTool对象会被保存到metastore。
进入importTable方法，该方法有三个实现：
1. DummyManager——主要用于单元测试
2. MainFrameManager——连接主机，目前只支持通过FTP协议
3. SqlManager——连接各种支持JDBC连接的数据库

SqlManager查询数据库主要有两种方式：本地模式和分布式模式
本地模式即直接在当前JVM中查询，比如查询表的结构。
分布式模式下进行数据导入导出的查询，如表的导入导出。importTable()方法是一个典型的例子。
org.apache.sqoop.manager.SqlManager类
```
  public void importTable(com.cloudera.sqoop.manager.ImportJobContext context)
      throws IOException, ImportException {
    String tableName = context.getTableName();
    String jarFile = context.getJarFile();
    SqoopOptions opts = context.getOptions();

    context.setConnManager(this);

    ImportJobBase importer;
    if (opts.getHBaseTable() != null) {
      // Import to HBase.
      if (!HBaseUtil.isHBaseJarPresent()) {
        throw new ImportException("HBase jars are not present in "
            + "classpath, cannot import to HBase!");
      }
      if (!opts.isBulkLoadEnabled()){
        importer = new HBaseImportJob(opts, context);
      } else {
        importer = new HBaseBulkImportJob(opts, context);
      }
    } else if (opts.getAccumuloTable() != null) {
       // Import to Accumulo.
       if (!AccumuloUtil.isAccumuloJarPresent()) {
         throw new ImportException("Accumulo jars are not present in "
             + "classpath, cannot import to Accumulo!");
       }
       importer = new AccumuloImportJob(opts, context);
    } else {
      // Import to HDFS.
      importer = new DataDrivenImportJob(opts, context.getInputFormat(),
              context);
    }

    checkTableImportOptions(context);

    String splitCol = getSplitColumn(opts, tableName);
    importer.runImport(tableName, jarFile, splitCol, opts.getConf());
  }
```


根据命令行参数的选项，数据将被导入HBase、Accumulo或者HDFS。
在DataDrivenImportJob的runImport方法中，可以看到MapReduce Job的构造和提交过程。
Job的InputFormat的默认类型是DataDrivenDBInputFormat。OutputFormat默认为null，使用hadoop默认的FileOutputFormat。MapperClass根据输出文件格式的不同而不同。可能的文件格式有纯文本、avro、parquet等。
HBaseImportJob、AccumuloImportJob是DataDrivenImportJob的子类。为了将数据导入HBase 和Accumulo，它们实现了不同的MapperClass和OutputFormat。


完成后返回0，程序正常结束。


# 二、源码修改
在源码的pom.xml文件中指定了所需的仓库，我们在maven中需要引入该仓库，该仓库中的包可以通过https://repository.cloudera.com/ui/ 进行搜索。
将maven的settings.xml文件中的仓库设置如下
```
    <mirrors>
        <mirror>
            <id>alimaven</id>
            <name>aliyun maven</name>
            <url>https://maven.aliyun.com/repository/public</url>
            <mirrorOf>central</mirrorOf>
        </mirror>
        <mirror>
            <id>maven</id>
            <name>sqoop dependencies maven</name>
            <url>https://repository.cloudera.com/artifactory/libs-release-local</url>
            <mirrorOf>*</mirrorOf>
        </mirror>
    </mirrors>
```



<br>
<br>
Sqlmanager 类下在获取到参数后，会先尝试连接一下数据库，执行一个 select t.* from XX as t limit 1 的语句。
mysql 和 hadoop 连接的时候使用的是 SqlManager 类，如果是 import 调用的是 importTable 方法，如果是 export 调用的是 exportTable 方法。根据生成的 ExportJobContext 上下文实例，执行 runExport() 方法，调用的是 mapreduce 包下的 ExportJobBase 类的方法。

配置好 job 相关信息，执行 runJob(job) 方法。
在 hive export to mysql 时，如果字段还有特殊字符，可能会出现因为切分数据而导致数据错位导致推数失败的情况。如果要对 hive 表中的数据进行处理的话，需要在 mapreduce 包下找到对应的 mapper 类（根据 hive 表类型划分为 TextExportMapper、ParquetMapper、SequenceFileMapper 等）
具体解析参数是在 SqoopParser 类下的 processArgs(Option opt, ListIterator iter) 方法
sqoopTool：sqoop具体的工具类

Hive 用增量
采集、建模需要固定的时间段，昨天9点到今天9点，限制住时间，或者要先获取到上次执行时间，再算上这次的执行时间。建模无法获取上次的执行时间，如果固定时间间隔，如果报错后续处理，比如垮天了，或者白天执行作业的时候就会很麻烦。
Hive不支持删除数据，对于不要的数据只能全量执行，不管是采集还是建模。
如果业务那边有一个base_table，每天的一个增量表，可以做成拉链表。燃气设备是做成了拉链表，是在源头做的，不是在hive

kpi 是增量插入一天一条，但是如果存在回补历史数据或者修正历史数据，比如某一天的数据就很麻烦。





<br>
<br>
<br>
<br>
<br>
<br>
sqoop
```
#!/bin/bash
#
# Copyright 2011 The Apache Software Foundation
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


follow_one() {
  # Resolve symlinks and relative path components along a path.  This requires
  # its argument to be an absolute path.  This does not recursively re-resolve
  # symlinks; if that is required, use the 'follow' method.

  target=$1
  OIFS=$IFS
  IFS='/'

  # Taking each dir component along the way, build up a new target directory,
  # resolving '.', '..', and symlinks.
  newtarget=''
  for part in ${target}; do
    if [ -z "${part}" ]; then
      continue # Empty dir part. 'foo//bar'
    elif [ "." == "${part}" ]; then
      continue # Nothing special to do for '.'
    elif  [ ".." == "${part}" ]; then
      IFS=$OIFS
      newtarget=`dirname ${newtarget}` # pop a component.
    elif [ -h "${newtarget}/${part}" ]; then
      IFS=$OIFS
      link=`readlink ${newtarget}/${part}`
      # links can be relative or absolute. Relative ones get appended to
      # newtarget; absolute ones replace it.
      if [ "${link:0:1}" != "/"  ]; then
        newtarget="${newtarget}/${link}" # relative
      else
        newtarget="${link}" # absolute
      fi
    else # Regular file component.
      newtarget="${newtarget}/${part}"
    fi
    IFS='/'
  done

  IFS=$OIFS
  echo $newtarget
}

follow() {
  # Portable 'readlink -f' function to follow a file's links to the final
  # target.  Calls follow_one recursively til we're finished tracing symlinks.

  target=$1
  depth=$2

  if [ -z "$depth" ]; then
    depth=0
  elif [ "$depth" == "1000" ]; then
    # Don't recurse indefinitely; we've probably hit a symlink cycle.
    # Just bail out here.
    echo $target
    return 1
  fi

  # Canonicalize the target to be an absolute path.
  targetdir=`dirname ${target}`
  targetdir=`cd ${targetdir} && pwd`
  target=${targetdir}/`basename ${target}`

  # Use follow_one to resolve links. Test that we get the same result twice,
  # to terminate iteration.
  first=`follow_one ${target}`
  second=`follow_one ${first}`
  if [ "${first}" == "${second}" ]; then
    # We're done.
    echo "${second}"
  else
    # Need to continue resolving links.
    echo `follow ${second} $(( $depth + 1 ))`
  fi
}

prgm=`follow $0`
bin=`dirname ${prgm}`
bin=`cd ${bin} && pwd`

source ${bin}/configure-sqoop "${bin}"
exec ${HADOOP_COMMON_HOME}/bin/hadoop org.apache.sqoop.Sqoop "$@"
```

java
```
// ORM class for table 'ca_sales'
// WARNING: This class is AUTO-GENERATED. Modify at your own risk.
//
// Debug information:
// Generated date: Wed Sep 01 15:47:37 CST 2021
// For connector: org.apache.sqoop.manager.MySQLManager
import org.apache.hadoop.io.BytesWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.Writable;
import org.apache.hadoop.mapred.lib.db.DBWritable;
import com.cloudera.sqoop.lib.JdbcWritableBridge;
import com.cloudera.sqoop.lib.DelimiterSet;
import com.cloudera.sqoop.lib.FieldFormatter;
import com.cloudera.sqoop.lib.RecordParser;
import com.cloudera.sqoop.lib.BooleanParser;
import com.cloudera.sqoop.lib.BlobRef;
import com.cloudera.sqoop.lib.ClobRef;
import com.cloudera.sqoop.lib.LargeObjectLoader;
import com.cloudera.sqoop.lib.SqoopRecord;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.sql.Date;
import java.sql.Time;
import java.sql.Timestamp;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

public class ca_sales extends SqoopRecord  implements DBWritable, Writable {
  private final int PROTOCOL_VERSION = 3;
  public int getClassFormatVersion() { return PROTOCOL_VERSION; }
  protected ResultSet __cur_result_set;
  private Integer type;
  public Integer get_type() {
    return type;
  }
  public void set_type(Integer type) {
    this.type = type;
  }
  public ca_sales with_type(Integer type) {
    this.type = type;
    return this;
  }
  private String device_code;
  public String get_device_code() {
    return device_code;
  }
  public void set_device_code(String device_code) {
    this.device_code = device_code;
  }
  public ca_sales with_device_code(String device_code) {
    this.device_code = device_code;
    return this;
  }
  private java.sql.Date sales_date;
  public java.sql.Date get_sales_date() {
    return sales_date;
  }
  public void set_sales_date(java.sql.Date sales_date) {
    this.sales_date = sales_date;
  }
  public ca_sales with_sales_date(java.sql.Date sales_date) {
    this.sales_date = sales_date;
    return this;
  }
  private Integer sales_num;
  public Integer get_sales_num() {
    return sales_num;
  }
  public void set_sales_num(Integer sales_num) {
    this.sales_num = sales_num;
  }
  public ca_sales with_sales_num(Integer sales_num) {
    this.sales_num = sales_num;
    return this;
  }
  private Float sales_money;
  public Float get_sales_money() {
    return sales_money;
  }
  public void set_sales_money(Float sales_money) {
    this.sales_money = sales_money;
  }
  public ca_sales with_sales_money(Float sales_money) {
    this.sales_money = sales_money;
    return this;
  }
  private Integer send_num;
  public Integer get_send_num() {
    return send_num;
  }
  public void set_send_num(Integer send_num) {
    this.send_num = send_num;
  }
  public ca_sales with_send_num(Integer send_num) {
    this.send_num = send_num;
    return this;
  }
  private java.sql.Timestamp create_time;
  public java.sql.Timestamp get_create_time() {
    return create_time;
  }
  public void set_create_time(java.sql.Timestamp create_time) {
    this.create_time = create_time;
  }
  public ca_sales with_create_time(java.sql.Timestamp create_time) {
    this.create_time = create_time;
    return this;
  }
  private java.sql.Timestamp update_time;
  public java.sql.Timestamp get_update_time() {
    return update_time;
  }
  public void set_update_time(java.sql.Timestamp update_time) {
    this.update_time = update_time;
  }
  public ca_sales with_update_time(java.sql.Timestamp update_time) {
    this.update_time = update_time;
    return this;
  }
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (!(o instanceof ca_sales)) {
      return false;
    }
    ca_sales that = (ca_sales) o;
    boolean equal = true;
    equal = equal && (this.type == null ? that.type == null : this.type.equals(that.type));
    equal = equal && (this.device_code == null ? that.device_code == null : this.device_code.equals(that.device_code));
    equal = equal && (this.sales_date == null ? that.sales_date == null : this.sales_date.equals(that.sales_date));
    equal = equal && (this.sales_num == null ? that.sales_num == null : this.sales_num.equals(that.sales_num));
    equal = equal && (this.sales_money == null ? that.sales_money == null : this.sales_money.equals(that.sales_money));
    equal = equal && (this.send_num == null ? that.send_num == null : this.send_num.equals(that.send_num));
    equal = equal && (this.create_time == null ? that.create_time == null : this.create_time.equals(that.create_time));
    equal = equal && (this.update_time == null ? that.update_time == null : this.update_time.equals(that.update_time));
    return equal;
  }
  public boolean equals0(Object o) {
    if (this == o) {
      return true;
    }
    if (!(o instanceof ca_sales)) {
      return false;
    }
    ca_sales that = (ca_sales) o;
    boolean equal = true;
    equal = equal && (this.type == null ? that.type == null : this.type.equals(that.type));
    equal = equal && (this.device_code == null ? that.device_code == null : this.device_code.equals(that.device_code));
    equal = equal && (this.sales_date == null ? that.sales_date == null : this.sales_date.equals(that.sales_date));
    equal = equal && (this.sales_num == null ? that.sales_num == null : this.sales_num.equals(that.sales_num));
    equal = equal && (this.sales_money == null ? that.sales_money == null : this.sales_money.equals(that.sales_money));
    equal = equal && (this.send_num == null ? that.send_num == null : this.send_num.equals(that.send_num));
    equal = equal && (this.create_time == null ? that.create_time == null : this.create_time.equals(that.create_time));
    equal = equal && (this.update_time == null ? that.update_time == null : this.update_time.equals(that.update_time));
    return equal;
  }
  public void readFields(ResultSet __dbResults) throws SQLException {
    this.__cur_result_set = __dbResults;
    this.type = JdbcWritableBridge.readInteger(1, __dbResults);
    this.device_code = JdbcWritableBridge.readString(2, __dbResults);
    this.sales_date = JdbcWritableBridge.readDate(3, __dbResults);
    this.sales_num = JdbcWritableBridge.readInteger(4, __dbResults);
    this.sales_money = JdbcWritableBridge.readFloat(5, __dbResults);
    this.send_num = JdbcWritableBridge.readInteger(6, __dbResults);
    this.create_time = JdbcWritableBridge.readTimestamp(7, __dbResults);
    this.update_time = JdbcWritableBridge.readTimestamp(8, __dbResults);
  }
  public void readFields0(ResultSet __dbResults) throws SQLException {
    this.type = JdbcWritableBridge.readInteger(1, __dbResults);
    this.device_code = JdbcWritableBridge.readString(2, __dbResults);
    this.sales_date = JdbcWritableBridge.readDate(3, __dbResults);
    this.sales_num = JdbcWritableBridge.readInteger(4, __dbResults);
    this.sales_money = JdbcWritableBridge.readFloat(5, __dbResults);
    this.send_num = JdbcWritableBridge.readInteger(6, __dbResults);
    this.create_time = JdbcWritableBridge.readTimestamp(7, __dbResults);
    this.update_time = JdbcWritableBridge.readTimestamp(8, __dbResults);
  }
  public void loadLargeObjects(LargeObjectLoader __loader)
      throws SQLException, IOException, InterruptedException {
  }
  public void loadLargeObjects0(LargeObjectLoader __loader)
      throws SQLException, IOException, InterruptedException {
  }
  public void write(PreparedStatement __dbStmt) throws SQLException {
    write(__dbStmt, 0);
  }

  public int write(PreparedStatement __dbStmt, int __off) throws SQLException {
    JdbcWritableBridge.writeInteger(type, 1 + __off, 4, __dbStmt);
    JdbcWritableBridge.writeString(device_code, 2 + __off, 12, __dbStmt);
    JdbcWritableBridge.writeDate(sales_date, 3 + __off, 91, __dbStmt);
    JdbcWritableBridge.writeInteger(sales_num, 4 + __off, 4, __dbStmt);
    JdbcWritableBridge.writeFloat(sales_money, 5 + __off, 7, __dbStmt);
    JdbcWritableBridge.writeInteger(send_num, 6 + __off, 4, __dbStmt);
    JdbcWritableBridge.writeTimestamp(create_time, 7 + __off, 93, __dbStmt);
    JdbcWritableBridge.writeTimestamp(update_time, 8 + __off, 93, __dbStmt);
    return 8;
  }
  public void write0(PreparedStatement __dbStmt, int __off) throws SQLException {
    JdbcWritableBridge.writeInteger(type, 1 + __off, 4, __dbStmt);
    JdbcWritableBridge.writeString(device_code, 2 + __off, 12, __dbStmt);
    JdbcWritableBridge.writeDate(sales_date, 3 + __off, 91, __dbStmt);
    JdbcWritableBridge.writeInteger(sales_num, 4 + __off, 4, __dbStmt);
    JdbcWritableBridge.writeFloat(sales_money, 5 + __off, 7, __dbStmt);
    JdbcWritableBridge.writeInteger(send_num, 6 + __off, 4, __dbStmt);
    JdbcWritableBridge.writeTimestamp(create_time, 7 + __off, 93, __dbStmt);
    JdbcWritableBridge.writeTimestamp(update_time, 8 + __off, 93, __dbStmt);
  }
  public void readFields(DataInput __dataIn) throws IOException {
this.readFields0(__dataIn);  }
  public void readFields0(DataInput __dataIn) throws IOException {
    if (__dataIn.readBoolean()) { 
        this.type = null;
    } else {
    this.type = Integer.valueOf(__dataIn.readInt());
    }
    if (__dataIn.readBoolean()) { 
        this.device_code = null;
    } else {
    this.device_code = Text.readString(__dataIn);
    }
    if (__dataIn.readBoolean()) { 
        this.sales_date = null;
    } else {
    this.sales_date = new Date(__dataIn.readLong());
    }
    if (__dataIn.readBoolean()) { 
        this.sales_num = null;
    } else {
    this.sales_num = Integer.valueOf(__dataIn.readInt());
    }
    if (__dataIn.readBoolean()) { 
        this.sales_money = null;
    } else {
    this.sales_money = Float.valueOf(__dataIn.readFloat());
    }
    if (__dataIn.readBoolean()) { 
        this.send_num = null;
    } else {
    this.send_num = Integer.valueOf(__dataIn.readInt());
    }
    if (__dataIn.readBoolean()) { 
        this.create_time = null;
    } else {
    this.create_time = new Timestamp(__dataIn.readLong());
    this.create_time.setNanos(__dataIn.readInt());
    }
    if (__dataIn.readBoolean()) { 
        this.update_time = null;
    } else {
    this.update_time = new Timestamp(__dataIn.readLong());
    this.update_time.setNanos(__dataIn.readInt());
    }
  }
  public void write(DataOutput __dataOut) throws IOException {
    if (null == this.type) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeInt(this.type);
    }
    if (null == this.device_code) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    Text.writeString(__dataOut, device_code);
    }
    if (null == this.sales_date) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeLong(this.sales_date.getTime());
    }
    if (null == this.sales_num) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeInt(this.sales_num);
    }
    if (null == this.sales_money) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeFloat(this.sales_money);
    }
    if (null == this.send_num) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeInt(this.send_num);
    }
    if (null == this.create_time) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeLong(this.create_time.getTime());
    __dataOut.writeInt(this.create_time.getNanos());
    }
    if (null == this.update_time) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeLong(this.update_time.getTime());
    __dataOut.writeInt(this.update_time.getNanos());
    }
  }
  public void write0(DataOutput __dataOut) throws IOException {
    if (null == this.type) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeInt(this.type);
    }
    if (null == this.device_code) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    Text.writeString(__dataOut, device_code);
    }
    if (null == this.sales_date) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeLong(this.sales_date.getTime());
    }
    if (null == this.sales_num) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeInt(this.sales_num);
    }
    if (null == this.sales_money) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeFloat(this.sales_money);
    }
    if (null == this.send_num) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeInt(this.send_num);
    }
    if (null == this.create_time) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeLong(this.create_time.getTime());
    __dataOut.writeInt(this.create_time.getNanos());
    }
    if (null == this.update_time) { 
        __dataOut.writeBoolean(true);
    } else {
        __dataOut.writeBoolean(false);
    __dataOut.writeLong(this.update_time.getTime());
    __dataOut.writeInt(this.update_time.getNanos());
    }
  }
  private static final DelimiterSet __outputDelimiters = new DelimiterSet((char) 44, (char) 10, (char) 0, (char) 0, false);
  public String toString() {
    return toString(__outputDelimiters, true);
  }
  public String toString(DelimiterSet delimiters) {
    return toString(delimiters, true);
  }
  public String toString(boolean useRecordDelim) {
    return toString(__outputDelimiters, useRecordDelim);
  }
  public String toString(DelimiterSet delimiters, boolean useRecordDelim) {
    StringBuilder __sb = new StringBuilder();
    char fieldDelim = delimiters.getFieldsTerminatedBy();
    __sb.append(FieldFormatter.escapeAndEnclose(type==null?"null":"" + type, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(device_code==null?"null":device_code, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(sales_date==null?"null":"" + sales_date, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(sales_num==null?"null":"" + sales_num, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(sales_money==null?"null":"" + sales_money, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(send_num==null?"null":"" + send_num, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(create_time==null?"null":"" + create_time, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(update_time==null?"null":"" + update_time, delimiters));
    if (useRecordDelim) {
      __sb.append(delimiters.getLinesTerminatedBy());
    }
    return __sb.toString();
  }
  public void toString0(DelimiterSet delimiters, StringBuilder __sb, char fieldDelim) {
    __sb.append(FieldFormatter.escapeAndEnclose(type==null?"null":"" + type, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(device_code==null?"null":device_code, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(sales_date==null?"null":"" + sales_date, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(sales_num==null?"null":"" + sales_num, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(sales_money==null?"null":"" + sales_money, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(send_num==null?"null":"" + send_num, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(create_time==null?"null":"" + create_time, delimiters));
    __sb.append(fieldDelim);
    __sb.append(FieldFormatter.escapeAndEnclose(update_time==null?"null":"" + update_time, delimiters));
  }
  private static final DelimiterSet __inputDelimiters = new DelimiterSet((char) 9, (char) 10, (char) 0, (char) 0, false);
  private RecordParser __parser;
  public void parse(Text __record) throws RecordParser.ParseError {
    if (null == this.__parser) {
      this.__parser = new RecordParser(__inputDelimiters);
    }
    List<String> __fields = this.__parser.parseRecord(__record);
    __loadFromFields(__fields);
  }

  public void parse(CharSequence __record) throws RecordParser.ParseError {
    if (null == this.__parser) {
      this.__parser = new RecordParser(__inputDelimiters);
    }
    List<String> __fields = this.__parser.parseRecord(__record);
    __loadFromFields(__fields);
  }

  public void parse(byte [] __record) throws RecordParser.ParseError {
    if (null == this.__parser) {
      this.__parser = new RecordParser(__inputDelimiters);
    }
    List<String> __fields = this.__parser.parseRecord(__record);
    __loadFromFields(__fields);
  }

  public void parse(char [] __record) throws RecordParser.ParseError {
    if (null == this.__parser) {
      this.__parser = new RecordParser(__inputDelimiters);
    }
    List<String> __fields = this.__parser.parseRecord(__record);
    __loadFromFields(__fields);
  }

  public void parse(ByteBuffer __record) throws RecordParser.ParseError {
    if (null == this.__parser) {
      this.__parser = new RecordParser(__inputDelimiters);
    }
    List<String> __fields = this.__parser.parseRecord(__record);
    __loadFromFields(__fields);
  }

  public void parse(CharBuffer __record) throws RecordParser.ParseError {
    if (null == this.__parser) {
      this.__parser = new RecordParser(__inputDelimiters);
    }
    List<String> __fields = this.__parser.parseRecord(__record);
    __loadFromFields(__fields);
  }

  private void __loadFromFields(List<String> fields) {
    Iterator<String> __it = fields.listIterator();
    String __cur_str = null;
    try {
    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.type = null; } else {
      this.type = Integer.valueOf(__cur_str);
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N")) { this.device_code = null; } else {
      this.device_code = __cur_str;
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.sales_date = null; } else {
      this.sales_date = java.sql.Date.valueOf(__cur_str);
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.sales_num = null; } else {
      this.sales_num = Integer.valueOf(__cur_str);
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.sales_money = null; } else {
      this.sales_money = Float.valueOf(__cur_str);
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.send_num = null; } else {
      this.send_num = Integer.valueOf(__cur_str);
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.create_time = null; } else {
      this.create_time = java.sql.Timestamp.valueOf(__cur_str);
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.update_time = null; } else {
      this.update_time = java.sql.Timestamp.valueOf(__cur_str);
    }

    } catch (RuntimeException e) {    throw new RuntimeException("Can't parse input data: '" + __cur_str + "'", e);    }  }

  private void __loadFromFields0(Iterator<String> __it) {
    String __cur_str = null;
    try {
    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.type = null; } else {
      this.type = Integer.valueOf(__cur_str);
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N")) { this.device_code = null; } else {
      this.device_code = __cur_str;
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.sales_date = null; } else {
      this.sales_date = java.sql.Date.valueOf(__cur_str);
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.sales_num = null; } else {
      this.sales_num = Integer.valueOf(__cur_str);
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.sales_money = null; } else {
      this.sales_money = Float.valueOf(__cur_str);
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.send_num = null; } else {
      this.send_num = Integer.valueOf(__cur_str);
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.create_time = null; } else {
      this.create_time = java.sql.Timestamp.valueOf(__cur_str);
    }

    __cur_str = __it.next();
    if (__cur_str.equals("\N") || __cur_str.length() == 0) { this.update_time = null; } else {
      this.update_time = java.sql.Timestamp.valueOf(__cur_str);
    }

    } catch (RuntimeException e) {    throw new RuntimeException("Can't parse input data: '" + __cur_str + "'", e);    }  }

  public Object clone() throws CloneNotSupportedException {
    ca_sales o = (ca_sales) super.clone();
    o.sales_date = (o.sales_date != null) ? (java.sql.Date) o.sales_date.clone() : null;
    o.create_time = (o.create_time != null) ? (java.sql.Timestamp) o.create_time.clone() : null;
    o.update_time = (o.update_time != null) ? (java.sql.Timestamp) o.update_time.clone() : null;
    return o;
  }

  public void clone0(ca_sales o) throws CloneNotSupportedException {
    o.sales_date = (o.sales_date != null) ? (java.sql.Date) o.sales_date.clone() : null;
    o.create_time = (o.create_time != null) ? (java.sql.Timestamp) o.create_time.clone() : null;
    o.update_time = (o.update_time != null) ? (java.sql.Timestamp) o.update_time.clone() : null;
  }

  public Map<String, Object> getFieldMap() {
    Map<String, Object> __sqoop$field_map = new TreeMap<String, Object>();
    __sqoop$field_map.put("type", this.type);
    __sqoop$field_map.put("device_code", this.device_code);
    __sqoop$field_map.put("sales_date", this.sales_date);
    __sqoop$field_map.put("sales_num", this.sales_num);
    __sqoop$field_map.put("sales_money", this.sales_money);
    __sqoop$field_map.put("send_num", this.send_num);
    __sqoop$field_map.put("create_time", this.create_time);
    __sqoop$field_map.put("update_time", this.update_time);
    return __sqoop$field_map;
  }

  public void getFieldMap0(Map<String, Object> __sqoop$field_map) {
    __sqoop$field_map.put("type", this.type);
    __sqoop$field_map.put("device_code", this.device_code);
    __sqoop$field_map.put("sales_date", this.sales_date);
    __sqoop$field_map.put("sales_num", this.sales_num);
    __sqoop$field_map.put("sales_money", this.sales_money);
    __sqoop$field_map.put("send_num", this.send_num);
    __sqoop$field_map.put("create_time", this.create_time);
    __sqoop$field_map.put("update_time", this.update_time);
  }

  public void setField(String __fieldName, Object __fieldVal) {
    if ("type".equals(__fieldName)) {
      this.type = (Integer) __fieldVal;
    }
    else    if ("device_code".equals(__fieldName)) {
      this.device_code = (String) __fieldVal;
    }
    else    if ("sales_date".equals(__fieldName)) {
      this.sales_date = (java.sql.Date) __fieldVal;
    }
    else    if ("sales_num".equals(__fieldName)) {
      this.sales_num = (Integer) __fieldVal;
    }
    else    if ("sales_money".equals(__fieldName)) {
      this.sales_money = (Float) __fieldVal;
    }
    else    if ("send_num".equals(__fieldName)) {
      this.send_num = (Integer) __fieldVal;
    }
    else    if ("create_time".equals(__fieldName)) {
      this.create_time = (java.sql.Timestamp) __fieldVal;
    }
    else    if ("update_time".equals(__fieldName)) {
      this.update_time = (java.sql.Timestamp) __fieldVal;
    }
    else {
      throw new RuntimeException("No such field: " + __fieldName);
    }
  }
  public boolean setField0(String __fieldName, Object __fieldVal) {
    if ("type".equals(__fieldName)) {
      this.type = (Integer) __fieldVal;
      return true;
    }
    else    if ("device_code".equals(__fieldName)) {
      this.device_code = (String) __fieldVal;
      return true;
    }
    else    if ("sales_date".equals(__fieldName)) {
      this.sales_date = (java.sql.Date) __fieldVal;
      return true;
    }
    else    if ("sales_num".equals(__fieldName)) {
      this.sales_num = (Integer) __fieldVal;
      return true;
    }
    else    if ("sales_money".equals(__fieldName)) {
      this.sales_money = (Float) __fieldVal;
      return true;
    }
    else    if ("send_num".equals(__fieldName)) {
      this.send_num = (Integer) __fieldVal;
      return true;
    }
    else    if ("create_time".equals(__fieldName)) {
      this.create_time = (java.sql.Timestamp) __fieldVal;
      return true;
    }
    else    if ("update_time".equals(__fieldName)) {
      this.update_time = (java.sql.Timestamp) __fieldVal;
      return true;
    }
    else {
      return false;    }
  }
}
```

hadoop
```
#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The name of the script being executed.
HADOOP_SHELL_EXECNAME="hadoop"
MYNAME="${BASH_SOURCE-$0}"

## @description  build up the hadoop command's usage text.
## @audience     public
## @stability    stable
## @replaceable  no
function hadoop_usage
{
  hadoop_add_option "buildpaths" "attempt to add class files from build tree"
  hadoop_add_option "hostnames list[,of,host,names]" "hosts to use in slave mode"
  hadoop_add_option "loglevel level" "set the log4j level for this command"
  hadoop_add_option "hosts filename" "list of hosts to use in slave mode"
  hadoop_add_option "workers" "turn on worker mode"

  hadoop_add_subcommand "checknative" client "check native Hadoop and compression libraries availability"
  hadoop_add_subcommand "classpath" client "prints the class path needed to get the Hadoop jar and the required libraries"
  hadoop_add_subcommand "conftest" client "validate configuration XML files"
  hadoop_add_subcommand "credential" client "interact with credential providers"
  hadoop_add_subcommand "daemonlog" admin "get/set the log level for each daemon"
  hadoop_add_subcommand "dtutil" client "operations related to delegation tokens"
  hadoop_add_subcommand "envvars" client "display computed Hadoop environment variables"
  hadoop_add_subcommand "fs" client "run a generic filesystem user client"
  hadoop_add_subcommand "jar <jar>" client "run a jar file. NOTE: please use \"yarn jar\" to launch YARN applications, not this command."
  hadoop_add_subcommand "jnipath" client "prints the java.library.path"
  hadoop_add_subcommand "kerbname" client "show auth_to_local principal conversion"
  hadoop_add_subcommand "key" client "manage keys via the KeyProvider"
  hadoop_add_subcommand "trace" client "view and modify Hadoop tracing settings"
  hadoop_add_subcommand "version" client "print the version"
  hadoop_add_subcommand "kdiag" client "Diagnose Kerberos Problems"
  hadoop_generate_usage "${HADOOP_SHELL_EXECNAME}" true
}

## @description  Default command handler for hadoop command
## @audience     public
## @stability    stable
## @replaceable  no
## @param        CLI arguments
function hadoopcmd_case
{
  subcmd=$1
  shift

  case ${subcmd} in
    balancer|datanode|dfs|dfsadmin|dfsgroups|  \
    namenode|secondarynamenode|fsck|fetchdt|oiv| \
    portmap|nfs3)
      hadoop_error "WARNING: Use of this script to execute ${subcmd} is deprecated."
      subcmd=${subcmd/dfsgroups/groups}
      hadoop_error "WARNING: Attempting to execute replacement \"hdfs ${subcmd}\" instead."
      hadoop_error ""
      #try to locate hdfs and if present, delegate to it.
      if [[ -f "${HADOOP_HDFS_HOME}/bin/hdfs" ]]; then
        exec "${HADOOP_HDFS_HOME}/bin/hdfs" \
          --config "${HADOOP_CONF_DIR}" "${subcmd}"  "$@"
      elif [[ -f "${HADOOP_HOME}/bin/hdfs" ]]; then
        exec "${HADOOP_HOME}/bin/hdfs" \
          --config "${HADOOP_CONF_DIR}" "${subcmd}" "$@"
      else
        hadoop_error "HADOOP_HDFS_HOME not found!"
        exit 1
      fi
    ;;

    #mapred commands for backwards compatibility
    pipes|job|queue|mrgroups|mradmin|jobtracker|tasktracker)
      hadoop_error "WARNING: Use of this script to execute ${subcmd} is deprecated."
      subcmd=${subcmd/mrgroups/groups}
      hadoop_error "WARNING: Attempting to execute replacement \"mapred ${subcmd}\" instead."
      hadoop_error ""
      #try to locate mapred and if present, delegate to it.
      if [[ -f "${HADOOP_MAPRED_HOME}/bin/mapred" ]]; then
        exec "${HADOOP_MAPRED_HOME}/bin/mapred" \
        --config "${HADOOP_CONF_DIR}" "${subcmd}" "$@"
      elif [[ -f "${HADOOP_HOME}/bin/mapred" ]]; then
        exec "${HADOOP_HOME}/bin/mapred" \
        --config "${HADOOP_CONF_DIR}" "${subcmd}" "$@"
      else
        hadoop_error "HADOOP_MAPRED_HOME not found!"
        exit 1
      fi
    ;;
    checknative)
      HADOOP_CLASSNAME=org.apache.hadoop.util.NativeLibraryChecker
    ;;
    classpath)
      hadoop_do_classpath_subcommand HADOOP_CLASSNAME "$@"
    ;;
    conftest)
      HADOOP_CLASSNAME=org.apache.hadoop.util.ConfTest
    ;;
    credential)
      HADOOP_CLASSNAME=org.apache.hadoop.security.alias.CredentialShell
    ;;
    daemonlog)
      HADOOP_CLASSNAME=org.apache.hadoop.log.LogLevel
    ;;
    dtutil)
      HADOOP_CLASSNAME=org.apache.hadoop.security.token.DtUtilShell
    ;;
    envvars)
      echo "JAVA_HOME='${JAVA_HOME}'"
      echo "HADOOP_COMMON_HOME='${HADOOP_COMMON_HOME}'"
      echo "HADOOP_COMMON_DIR='${HADOOP_COMMON_DIR}'"
      echo "HADOOP_COMMON_LIB_JARS_DIR='${HADOOP_COMMON_LIB_JARS_DIR}'"
      echo "HADOOP_COMMON_LIB_NATIVE_DIR='${HADOOP_COMMON_LIB_NATIVE_DIR}'"
      echo "HADOOP_CONF_DIR='${HADOOP_CONF_DIR}'"
      echo "HADOOP_TOOLS_HOME='${HADOOP_TOOLS_HOME}'"
      echo "HADOOP_TOOLS_DIR='${HADOOP_TOOLS_DIR}'"
      echo "HADOOP_TOOLS_LIB_JARS_DIR='${HADOOP_TOOLS_LIB_JARS_DIR}'"
      if [[ -n "${QATESTMODE}" ]]; then
        echo "MYNAME=${MYNAME}"
        echo "HADOOP_SHELL_EXECNAME=${HADOOP_SHELL_EXECNAME}"
      fi
      exit 0
    ;;
    fs)
      HADOOP_CLASSNAME=org.apache.hadoop.fs.FsShell
    ;;
    jar)
      if [[ -n "${YARN_OPTS}" ]] || [[ -n "${YARN_CLIENT_OPTS}" ]]; then
        hadoop_error "WARNING: Use \"yarn jar\" to launch YARN applications."
      fi
      if [[ -z $1 || $1 = "--help" ]]; then
        echo "Usage: hadoop jar <jar> [mainClass] args..."
        exit 0
      fi
      HADOOP_CLASSNAME=org.apache.hadoop.util.RunJar
    ;;
    jnipath)
      hadoop_finalize
      echo "${JAVA_LIBRARY_PATH}"
      exit 0
    ;;
    kerbname)
      HADOOP_CLASSNAME=org.apache.hadoop.security.HadoopKerberosName
    ;;
    kdiag)
      HADOOP_CLASSNAME=org.apache.hadoop.security.KDiag
    ;;
    key)
      HADOOP_CLASSNAME=org.apache.hadoop.crypto.key.KeyShell
    ;;
    trace)
      HADOOP_CLASSNAME=org.apache.hadoop.tracing.TraceAdmin
    ;;
    version)
      HADOOP_CLASSNAME=org.apache.hadoop.util.VersionInfo
    ;;
    *)
      HADOOP_CLASSNAME="${subcmd}"
      if ! hadoop_validate_classname "${HADOOP_CLASSNAME}"; then
        hadoop_exit_with_usage 1
      fi
    ;;
  esac
}

# This script runs the hadoop core commands.

# let's locate libexec...
if [[ -n "${HADOOP_HOME}" ]]; then
  HADOOP_DEFAULT_LIBEXEC_DIR="${HADOOP_HOME}/libexec"
else
  bin=$(cd -P -- "$(dirname -- "${MYNAME}")" >/dev/null && pwd -P)
  HADOOP_DEFAULT_LIBEXEC_DIR="${bin}/../libexec"
fi

HADOOP_LIBEXEC_DIR="${HADOOP_LIBEXEC_DIR:-$HADOOP_DEFAULT_LIBEXEC_DIR}"
HADOOP_NEW_CONFIG=true
if [[ -f "${HADOOP_LIBEXEC_DIR}/hadoop-config.sh" ]]; then
  # shellcheck source=./hadoop-common-project/hadoop-common/src/main/bin/hadoop-config.sh
  . "${HADOOP_LIBEXEC_DIR}/hadoop-config.sh"
else
  echo "ERROR: Cannot execute ${HADOOP_LIBEXEC_DIR}/hadoop-config.sh." 2>&1
  exit 1
fi

# now that we have support code, let's abs MYNAME so we can use it later
MYNAME=$(hadoop_abs "${MYNAME}")

if [[ $# = 0 ]]; then
  hadoop_exit_with_usage 1
fi

HADOOP_SUBCMD=$1
shift

if hadoop_need_reexec hadoop "${HADOOP_SUBCMD}"; then
  hadoop_uservar_su hadoop "${HADOOP_SUBCMD}" \
    "${MYNAME}" \
    "--reexec" \
    "${HADOOP_USER_PARAMS[@]}"
  exit $?
fi

hadoop_verify_user_perm "${HADOOP_SHELL_EXECNAME}" "${HADOOP_SUBCMD}"

HADOOP_SUBCMD_ARGS=("$@")

if declare -f hadoop_subcommand_"${HADOOP_SUBCMD}" >/dev/null 2>&1; then
  hadoop_debug "Calling dynamically: hadoop_subcommand_${HADOOP_SUBCMD} ${HADOOP_SUBCMD_ARGS[*]}"
  "hadoop_subcommand_${HADOOP_SUBCMD}" "${HADOOP_SUBCMD_ARGS[@]}"
else
  hadoopcmd_case "${HADOOP_SUBCMD}" "${HADOOP_SUBCMD_ARGS[@]}"
fi

hadoop_add_client_opts

if [[ ${HADOOP_WORKER_MODE} = true ]]; then
  hadoop_common_worker_mode_execute "${HADOOP_COMMON_HOME}/bin/hadoop" "${HADOOP_USER_PARAMS[@]}"
  exit $?
fi

hadoop_subcommand_opts "${HADOOP_SHELL_EXECNAME}" "${HADOOP_SUBCMD}"

# everything is in globals at this point, so call the generic handler
hadoop_generic_java_subcmd_handler
```

<br>
<br>
<br>
# 3.   编译和打包
[https://www.cnblogs.com/simplestupid/p/6444332.html](https://www.cnblogs.com/simplestupid/p/6444332.html)


在ubuntu下使用ant编译和打包。参考sqoop的README，我安装的是jdk1.8.0_121和ant1.10.1。

== Compiling Sqoop

 

Compiling Sqoop requires the following tools:

 

* Apache ant (1.7.1)

* Java JDK 1.6

 

Additionally, building the documentation requires these tools:

 

* asciidoc

* make

* python 2.5+

* xmlto

* tar

* gzip

 

To compile Sqoop, run **ant package**. There will be a fully self-hosted build

provided in the +build/sqoop-(version)/+ directory.

执行ant package命令即可。

![brimage.png](Sqoop源码.assets\699ed5465cac4eb5bd0af5affb2c64c0.png)

在build下得到构建产物。

![image.png](Sqoop源码.assets\6a510fe341fd40f480b7b7a1e1e60691.png)


BTW：这里我指定了hadoop版本是2.6.1，只要在build.xml中修改版本号即可。

![image.png](Sqoop源码.assets\24116939664048a1865388000023517a.png)
