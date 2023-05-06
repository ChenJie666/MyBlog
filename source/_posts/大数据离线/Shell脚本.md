---
title: Shell脚本
categories:
- 大数据离线
---
xsync.sh
```sh
#!/bin/bash
#传输多个文件
if [ $# -lt 1 ]
then
	echo "PARAMETER IS NULL!!!"
	exit
fi

for file in $@
do
	if [ -e $file ]
	then	
		DIRNAME=$(cd -P $(dirname $file);pwd)
		FILENAME=$(basename $file)
		user=$(whoami)
		for host in {103..104}
		do
			echo ---$DIRNAME/$FILENAME  $user  hadoop$host---
			rsync -av $DIRNAME/$FILENAME $user@hadoop$host:$DIRNAME
		done
	else
		echo $file IS NOT EXISTS!!!
	fi
done
```

jps-server.sh
```sh
#!/bin/bash
#jps脚本
for host in bigdata1 bigdata2 bigdata3
do
        echo ----- ${host} -----
        ssh ${host} "jps"
done
```

zk-server.sh
```sh
case $1 in
start)
    for host in hadoop102 hadoop103 hadoop104
    do
        ssh $host "source /etc/profile;/opt/module/zookeeper-3.4.10/bin/zkServer.sh start"
    done
;;
stop)
    for host in hadoop102 hadoop103 hadoop104
    do
        ssh $host "source /etc/profile;/opt/module/zookeeper-3.4.10/bin/zkServer.sh stop"
    done
;;
status)
    for host in hadoop102 hadoop103 hadoop104
    do
        ssh $host "source /etc/profile;/opt/module/zookeeper-3.4.10/bin/zkServer.sh status"
    done
;;
esac
```

kafka-server.sh (-deamon 效果同 nohup xxx 1>/dev/null 2>1 &)
```sh
case $1 in
start)
    for host in hadoop102 hadoop103 hadoop104
    do
        echo "====== Start kafka ======"
        ssh $host "source /etc/profile; export JMX_PORT=9988 ; /opt/module/kafka_2.11-0.11.0.2/bin/kafka-server-start.sh -daemon /opt/module/kafka_2.11/config/server.properties"
        if [ $? -eq 0 ]
        then
                echo "Start Success"
        fi
    done
;;
stop)
    for host in hadoop102 hadoop103 hadoop104
    do
        echo "====== Stop kafka ======"
        ssh $host "source /etc/profile;/opt/module/kafka_2.11-0.11.0.2/bin/kafka-server-stop.sh"
        if [ $? -eq 0 ]
        then
                echo "Stop Success"
        fi
    done
;;
esac
```


flume-server.sh
```sh
case $1 in
start)
    for host in hadoop102 hadoop103
    do
        ssh $host "source /etc/profile ; nohup /opt/module/flume-1.7.0/bin/flume-ng agent -n a1 -c /opt/module/flume-1.7.0/conf -f /opt/module/flume-1.7.0/job/file-kafka.conf >/dev/null 2>&1 &"
        if [ $? -eq 0 ]
        then
                echo "Start Success"
        fi
    done
;;
stop)
    for host in hadoop102 hadoop103
    do
        ssh $host "source /etc/profile ; ps -ef | awk '/file-kafka.conf/ && !/awk/{print \$2}' | xargs kill"
        if [ $? -eq 0 ]
        then
                echo "Stop Success"
        fi
    done
;;
esac
```
