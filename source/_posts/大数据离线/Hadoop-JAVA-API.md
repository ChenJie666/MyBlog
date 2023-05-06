---
title: Hadoop-JAVA-API
categories:
- 大数据离线
---
[官网]([FileSystem (Apache Hadoop Main 3.3.1 API)](https://hadoop.apache.org/docs/stable/api/index.html)
)


```
    <dependencies>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-hdfs</artifactId>
            <version>${hadoop.version}</version>
        </dependency>

        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-common</artifactId>
            <version>${hadoop.version}</version>
            <exclusions>
                <exclusion>
                    <groupId>org.slf4j</groupId>
                    <artifactId>slf4j-log4j12</artifactId>
                </exclusion>
                <exclusion>
                    <groupId>org.slf4j</groupId>
                    <artifactId>slf4j-api</artifactId>
                </exclusion>
            </exclusions>
        </dependency>

        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-yarn-common</artifactId>
            <version>${hadoop.version}</version>
            <exclusions>
                <exclusion>
                    <groupId>org.slf4j</groupId>
                    <artifactId>slf4j-log4j12</artifactId>
                </exclusion>
                <exclusion>
                    <groupId>log4j</groupId>
                    <artifactId>log4j</artifactId>
                </exclusion>
            </exclusions>
        </dependency>
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-mapreduce-client-core</artifactId>
            <version>${hadoop.version}</version>
            <exclusions>
                <exclusion>
                    <groupId>org.slf4j</groupId>
                    <artifactId>slf4j-log4j12</artifactId>
                </exclusion>
                <exclusion>
                    <groupId>org.slf4j</groupId>
                    <artifactId>slf4j-api</artifactId>
                </exclusion>
            </exclusions>
        </dependency>

        <dependency>
            <groupId>org.anarres.lzo</groupId>
            <artifactId>lzo-hadoop</artifactId>
            <version>1.0.5</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <source>1.8</source>
                    <target>1.8</target>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-assembly-plugin</artifactId>
                <version>3.3.0</version>
                <configuration>
                    <descriptorRefs>
                        <descriptorRef>jar-with-dependencies</descriptorRef>
                    </descriptorRefs>
                    <archive>
                        <manifest>
                            <mainClass>com.cj.hdfs.WriteHdfsMain</mainClass>
                        </manifest>
                    </archive>
                </configuration>
                <executions>
                    <execution>
                        <id>make-assembly</id>
                        <phase>package</phase>
                        <goals>
                            <goal>single</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
```


```
package com.cj.hdfs;

import com.cj.hdfs.common.HdfsConstant;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.NullWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.io.compress.LzopCodec;
import org.apache.hadoop.mapred.*;
import org.apache.hadoop.security.UserGroupInformation;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * @author CJ
 * @date: 2021/11/18 10:23
 */
public class WriteHdfsMain {

    public Logger logger =  LoggerFactory.getLogger(this.getClass().getName());

    public FileSystem fs = null;
    public Configuration hadoopConf = null;
    public JobConf conf = null;

    public static void main(String[] args) throws InterruptedException, IOException, URISyntaxException {
        WriteHdfsMain main = new WriteHdfsMain();
        main.getFileSystem();
//        main.mkdirs();
//        main.createFile();
        main.write();
        main.close();
    }

    public void getFileSystem() throws IOException, URISyntaxException, InterruptedException {
        String keytabPath = Thread.currentThread().getContextClassLoader().getResource("hive.keytab").getPath();
        String confPath = Thread.currentThread().getContextClassLoader().getResource("krb5.ini").getPath();

        System.setProperty("hadoop.home.dir", "C:\Users\CJ\Desktop\GC\hadoop-common-2.6.0-bin-master");
        System.setProperty("java.security.krb5.conf", confPath);
//        System.setProperty("java.security.krb5.conf", "classpath:/krb5.ini");
        hadoopConf = new Configuration();
        hadoopConf.set("defaultFS", HdfsConstant.DEFAULT_FS);

        // 添加kerberos认证
        hadoopConf.set("dfs.data.transfer.protection", "authentication");
        hadoopConf.set("hadoop.security.authentication", "kerberos");
        UserGroupInformation.setConfiguration(hadoopConf);
        UserGroupInformation.loginUserFromKeytab(HdfsConstant.KERBEROS_PRINCIPAL, keytabPath);

        conf = new JobConf(hadoopConf);

        fs = FileSystem.get(new URI(HdfsConstant.DEFAULT_FS), conf);
        logger.info("getFileSystem完成");
    }

    public void close() throws IOException {
        fs.close();
        logger.info("close完成");
    }


    public void mkdirs() throws IOException {
        boolean mkdirs = fs.mkdirs(new Path("/tmp/test"));

        logger.info("mkdirs完成");
    }

    public void createFile() throws IOException {
        Path path = new Path("/tmp/test.txt");
        fs.create(path);
        logger.info("createFile完成");
    }

    public void write() throws IOException {
        Path outputPath = new Path("/tmp/test.txt");

        SimpleDateFormat dateFormat = new SimpleDateFormat("yyyyMMddHHmm");
        String attempt = "attempt_" + dateFormat.format(new Date()) + "_0001_m_000000_0";
        conf.set("mapreduce.task.attempt.id", attempt);

        FileOutputFormat textOutputFormat = new TextOutputFormat();
        textOutputFormat.setOutputPath(conf, outputPath);
        textOutputFormat.setWorkOutputPath(conf, outputPath);
        Class<LzopCodec> lzopCodecClass = LzopCodec.class;
        textOutputFormat.setOutputCompressorClass(conf, lzopCodecClass);

        RecordWriter writer = textOutputFormat.getRecordWriter(fs, conf, outputPath.toString(), Reporter.NULL);

        Text text1 = new Text("hello world");
        Text text2 = new Text("你好");

        writer.write(NullWritable.get(), text1);
        writer.write(NullWritable.get(), text2);
        writer.write(NullWritable.get(), text2);
        writer.write(NullWritable.get(), text2);
        writer.write(NullWritable.get(), text2);

        writer.close(Reporter.NULL);

        logger.info("write完成");
    }

}
```


# 二、可能会出现的异常情况
## 2.1 踩坑一
- 现象：在使用window系统调试hadoop程序时，会报错
```
21:12:01.556 [main] DEBUG org.apache.hadoop.security.authentication.util.KerberosName - Kerberos krb5 configuration not found, setting default realm to empty
[ERROR][2021-11-18 21:12:01 571][org.apache.hadoop.util.Shell]-[Failed to locate the winutils binary in the hadoop binary path]
java.io.IOException: Could not locate executable nullin\winutils.exe in the Hadoop binaries.
Exception in thread "main" java.lang.NullPointerException
	at java.lang.ProcessBuilder.start(ProcessBuilder.java:1012)
```
- 原因：原因是缺少winutils.exe程序，winutils.exe是在Windows系统上需要的hadoop调试环境工具，里面包含一些在Windows系统下调试hadoop、spark所需要的基本的工具类，另外在使用eclipse调试hadoop程序是，也需要winutils.exe。需要下载相应的包进行解决。
- 解决：
（1）下载winutils，注意需要与hadoop的版本相对应。
----hadoop2.2版本可以在这里下载https://github.com/srccodes/hadoop-common-2.2.0-bin
----hadoop2.6版本可以在这里下载https://github.com/amihalik/hadoop-common-2.6.0-bin
（2） 解压到你需要的目录，然后记住这个目录
（3）在执行代码开头，加上这句代码：
----System.setProperty(“hadoop.home.dir”, “E:\hadoop-common-2.2.0-bin-master”)


## 2.2 踩坑二
- 现象：write到hdfs时，出现异常`hadoop No FileSystem for scheme: file`；或写入时程序没有报错，但是在hdfs上找不到写入的文本。
- 原因：缺少hadoop的一些配置。
- 解决：复制配置文件core-site.xml和hdfs-site.xml文件到resources目录下。

## 2.3 踩坑三
- 现象：win上安装Kerberos后，会添加bin目录路径到环境变量中，此时使用kinit命令会出现异常**PortUnreachableException: ICMP Port Unreachable**
- 原因：JDK的环境变量在Kerberos环境变量之前，因为JDK中也有kinit、klist等命令，所以会优先使用JDK的命令。
- 解决：将Kerberos的环境变量挪到JDK环境变量之前。

## 2.4 踩坑四
- 现象：通过Kerberos进行认证是报错如下
```
10:59:59.722 [main] DEBUG org.apache.hadoop.security.authentication.util.KerberosName - Kerberos krb5 configuration not found, setting default realm to empty
Exception in thread "main" java.lang.IllegalArgumentException: Can't get Kerberos realm
```
- 原因：找不到配置文件krb5.ini
- 解决：添加环境变量
```
System.setProperty("java.security.krb5.conf", "C:\ProgramData\MIT\Kerberos5\krb5.ini");
```

## 2.5 踩坑
- 现象：经过Kerberos后，可以成功进行创建文件夹操作，但是使用RecoreWrite的write方法写入数据却报错
```
org.apache.hadoop.hdfs.server.datanode.DataNode: 
Failed to read expected SASL data transfer protection handshake from client at /192.168.32.56:57645. 
Perhaps the client is running an older version of Hadoop which does not support SASL data transfer protection
org.apache.hadoop.hdfs.protocol.datatransfer.sasl.InvalidMagicNumberException: Received 1c50c9 instead of deadbeef from client.
```
- 原因：
- 解决：在代码中添加配置`hadoopConf.set("dfs.data.transfer.protection", "authentication");`；或在hdfs-site.xml配置文件中添加配置
```
    <property>
      <name>dfs.data.transfer.protection</name>
      <value>authentication</value>
    </property>
```
>官网解释：A comma-separated list of SASL protection values used for secured connections to the DataNode when reading or writing block data. Possible values are authentication, integrity and privacy. authentication means authentication only and no integrity or privacy; integrity implies authentication and integrity are enabled; and privacy implies all of authentication, integrity and privacy are enabled. If dfs.encrypt.data.transfer is set to true, then it supersedes the setting for dfs.data.transfer.protection and enforces that all connections must use a specialized encrypted SASL handshake. This property is ignored for connections to a DataNode listening on a privileged port. In this case, it is assumed that the use of a privileged port establishes sufficient trust.
