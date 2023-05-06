---
title: tmp文件删除规则
categories:
- Linux
---
    我们知道，在Linux系统中/tmp文件夹里面的文件会被清空，至于多长时间被清空，如何清空的，可能大家知识的就不多了，所以，今天我们就来剖析一个这两个问题。

      在RHEL\CentOS\Fedora\系统中(本次实验是在RHEL6中进行的)
     先来看看tmpwatch这个命令，他的作用就是删除一段时间内不使用的文件（removes files which haven’t been accessed for a period of time）。具体的用法就不多说了，有兴趣的自行研究。我们主要看看和这个命令相关的计划任务文件。 


他就是/etc/cron.daily/tmpwatch，我们可以看一下这个文件里面的内容 
```
#! /bin/sh
flags=-umc
/usr/sbin/tmpwatch "$flags" -x /tmp/.X11-unix -x /tmp/.XIM-unix \
        -x /tmp/.font-unix -x /tmp/.ICE-unix -x /tmp/.Test-unix \
        -X '/tmp/hsperfdata_*' 10d /tmp
/usr/sbin/tmpwatch "$flags" 30d /var/tmp
for d in /var/{cache/man,catman}/{cat?,X11R6/cat?,local/cat?}; do
    if [ -d "$d" ]; then
        /usr/sbin/tmpwatch "$flags" -f 30d "$d"
    fi
done
```

这个脚本大家仔细分析一下就明白了，第一行相当于一个标记（参数），第二行就是针对/tmp目录里面排除的目录，第三行，这是对这个/tmp目录的清理，下面的是针对其他目录的清理，就不说了。

我们就来看/usr/sbin/tmpwatch "$flags" 30d /var/tmp这一行，关键的是这个30d，就是30天的意思，这个就决定了30天清理/tmp下不访问的文件。如果说，你想一天一清理的话，就把这个30d改成1d。这个你懂的……哈哈！

但有个问题需要注意，如果你设置更短的时间来清理的话，比如说是30分钟、10秒等等，你可以在这个文件中设置，但你会发现重新电脑，他不清理/tmp文件夹里面的内容，这是为什么呢？这就是tmpwatch他所在的位置决定的，他的上层目录是/etc/cron.daily/，而这个目录是第天执行一次计划任务，所以说，你设置了比一天更短的时间，他就不起作用了。
