---
title: shell编程
categories:
- 编程语言
---
系统变量：/etc/profile
用户变量：~/.bash_profile | ~/.bash_login | ~/.profile /etc/profile.d/*
login 和 non-login shell
login方式加载顺序：etc/profile -> ~/.bash_profile | ~/.bash_login | ~/.profile(加载时，按照上述顺序进行加载，只要加载到一个文件就停止加载)
non-login方式加载顺序：不会加载 etc/profile，会加载~/.bashrc和profile.d文件夹下的脚本。

# **常用的正则表达式语法**
\   转义
^   一行的开头      例：^R------表示以R开头的行
\$   匹配一行的结束        例：R\$表示以R结尾的行
\*  表示上一个子式匹配0次或多次，贪心匹配
.   匹配一个任意的字符（除了换行符）
.*匹配任意字符串
[]  表示匹配某个范围内的字符    例：[a-z]------匹配一个a-z之间的字符**   [a-z]*-----匹配任意字母字符串**
/^$/ 正则表达式代表空行

将字符串按空格分割转为数组：  `arr=($str)`

# **小知识：**

①Linux引用系统变量前加%

Wind用于系统变量前后都加%

②Shell中语句以；或换行为结束 if [] ; then  或 if[] /n  then

③程序执行后会返回执行状态码：0表示正常执行，1表示没有执行完。$？返回上一次执行状态。

也可以判断上条语句的判断是是否是true（true返回0），false（false返回1）。

④Shell中的case语言每个分支以；；结尾，不会像java一样不写break有雪崩。

⑤条件非空即为true，[ hxr]返回true，[] 返回false。

条件非空即为true，[ ！hxr]返回false，[！] 返回true。

⑥Sed  -e    只有一个指令可以省略，多个就要加。

⑦；Awk：

Pattern可以是BEGIN和END，BEGIN｛｝  END｛｝ 在流入前和流入后执行

Print是awk中的语句，不是shell语言    视频15：30

⑧-v 可以指定一个用户变量   -v sum=0

⑨
```
cat  <<EOF  >  test.sh
DEVICE=eth0
TYPE=Ethernet
EOF
```
向test.sh文件中写入EOF之前的内容。

⑩复制命令：

①cp（copy）：只能在本机中复制

cp  -r  test  /root

②scp（secure copy）：可以复制文件给远程主机

scp  -r  test.sh  hxr@bigdata2:/root

③rsync（remote sync）：功能与scp相同，但是不会改文件属性

rsync  -av  test.sh  hxr@bigdata2:/root

<br>
# 第1章 Shell概述

![image.png](shell编程.assets\d1f367f615be413c85afa3f597b6aa1a.png)

Shell是命令行解释器，用来逐句解释并执行shell语句，调用操作系统的内核。

<br>
# 第2章Shell解析器

1./etc/shells  中存储着shell语言标准。

[hxr@bigdata2 bin]\$ cat  /etc/shells

/bin/sh

/bin/bash

/sbin/nologin

/bin/dash

/bin/tcsh

/bin/csh

2. sh是bash的一个软连接

[hxr@bigdata2 bin]\$ ll | grep bash

-rwxr-xr-x. 1 root root 941880 5月  11 2016 bash

lrwxrwxrwx. 1 root root      4 5月  27 2017 sh -> bash

Cent os通过软链接/bin/sh来调用/bin/bash解释器，是红帽系下的一个系统分支。/sbin/nologin是未登录情况下的解释器，用于远程控制未登录的账户，ssh hadoop103 ‘ls’

3.Centos默认的解析器是bash

[hxr@bigdata2 bin]\$ echo $SHELL
/bin/bash

<br>
# 第3章 Shell脚本入门

解释性语言可以用脚本执行，逐行解释执行。

**编写脚本：**

\#！/bin/bash  指定脚本解释器

echo Helloworld  执行语句

**执行脚本：**

bash <文件名>   用bash解释器解释执行该文件

执行脚本的三种方法：

①采用输入脚本的绝对路径或相对路径执行脚本（必须具有可执行权限+x）

②采用bash或sh+脚本的相对路径或绝对路径（不用赋予脚本+x权限）

③放到bash和sh所在的文件夹（/bin)下，则在别处可以直接运行脚本。/home/hxr/bin目录下实现全局使用，将xsync移动到/usr/local/bin也可以。

例：xsync脚本放到/bin文件夹下，在任何路径下输入xsync jdk.1.8都可以运行（也是因此需要发送文件的实际物理路径。见hadoop笔记中的集群环境配置）。

如果在执行时指定，那么脚本内的指定脚本解释器语句会变成注释。脚本中最好写上解释器，这样可以自执行。

执行时调用bash解释器执行方法，本质是bash解析器帮你执行脚本，所以脚本本身不需要执行权限。第二种自执行方法，本质是脚本需要自己执行，所以需要执行权限。

**脚本执行方式和shell的子进程和变量的作用范围**
注意：
①  ./*.sh  sh ./*.sh 或 bash ./*.sh 三种执行脚本的方式都是重启一个子shell，在子shell中执行此脚本，每个脚本在各自的子进程中执行。
②  source  ./*.sh 和 . ./*.sh的执行方式是等价的，两种执行方式都是在当前shell进程中执行，而不是重启子shell进程。
Shell语句只有一种变量：字符串,作用域为当前的shell下，每个shell终端下就是不同的shell域，一个shell就是一个进程。

单敲bash就创建一个子shell，再敲exit返回原shell。可以通过ps -ef查看子shell的父shell进程。

export  a   会将a的作用域递归扩展到其子shell中。

<br>
# 第4章 Shell中的变量

Shell语句只有一种变量：字符串

## 4.1 系统变量

常用系统变量 \$HOME、\$PWD、\$SHELL、\$USER

set  显示当前Shell中所有变量

## 4.2 自定义变量

1．基本语法

（1）定义变量：变量=值 

（2）撤销变量：unset 变量

（3）声明静态变量：readonly变量，注意：不能修改，不能unset

2．变量定义规则

（1）变量名称可以由字母、数字和下划线组成，但是不能以数字开头，环境变量名建  议大写。

（2）等号两侧不能有空格

（3）在bash中，变量默认类型都是字符串类型，无法直接进行数值运算。

（4）变量的值如果有空格，需要使用双引号或单引号括起来。

3.变量提升为全局环境变量

export  a   会将a的作用域递归扩展到其子shell中。

或直接export  A=值  直接将A定义为全局变量

## 4.3 特殊变量：$n

\$n  （功能描述：n为数字，\$0代表该脚本名称，\$1-\$9代表第一到第九个参数，，十以上的参数需要用大括号包含，如\${10}）

## 4.4 特殊变量：\$#

\$#  （功能描述：获取所有输入参数个数，常用于循环）

## 4.5 特殊变量：\$*、\$@

\$*  （功能描述：这个变量代表命令行中所有的参数，$*把所有的参数看成一个整体）

\$@  （功能描述：这个变量也代表命令行中所有的参数，不过$@把每个参数区分对待）

代表命令行中所有的参数。可用于for循环遍历命令行参数，\$*和\$@都表示传递给函数或脚本的所有参数，不被双引号" "包含时，都以\$1 \$2 …\$n的形式输出所有参数。都被双引号包含时，\$\*代表一个整体，遍历就输出一个字符串。\$@把参数区分对待，遍历可以输出每个命令行参数。

## 4.6 特殊变量：$？

$？  （功能描述：最后一次执行的命令的返回状态。变量的值为0，证明上一个命令正确执行；变量的值为非0（具体是哪个数，由命令自己来决定），则证明上一个命令执行不正确了。）

## 4.7 \$()，\` \`，\${}，\$[]，\$(())，[ ] (( )) [[ ]] 作用与区别
-  \$()和\` \`都是用来做命令替换，$()并不是所有shell都支持
- \${}用做变量替换
- \$[]和\$(())都是进行数学运算的。但是注意，bash只能作整数运算，对于浮点数是当作字符串处理的。
- [ ]即为test命令的另一种形式。但要注意许多：
1.你必须在左括号的右侧和右括号的左侧各加一个空格，否则会报错。
2.test命令使用标准的数学比较符号来表示字符串的比较，而用文本符号来表示数值的比较。很多人会记反了。使用反了，shell可能得不到正确的结果。
3.大于符号或小于符号必须要转义，否则会被理解成重定向。
- (( ))和[[ ]]分别是[ ]的针对数学比较表达式和字符串表达式的加强版。
其中(( ))，不需要再将表达式里面的大小于符号转义，除了可以使用标准的数学运算符外，还增加了以下符号：![image.png](shell编程.assets10ab34b9977425c8731ea1dbd3535a7.png)

<br>
## 4.8 字符串切分
在shell中没有类似split方法，可以通过其他方法实现，如通过逗号切分字符串"177,178"
```
#!/bin/bash
str=177,178
array=(${str//,/ })
for host in ${array[@]}
do
 echo $host
done
```


<br>
# 第5章 运算符

1．基本语法

（1）“$((运算式))”或“$[运算式]”  最常用$[ 运算式 ]

例：S=$[(2+3)*4]    通过echo S 打印得到20

（2）expr  + , - , \*,  /,  %    加，减，乘，除，取余

注意：expr运算符间要有空格 

例1：expr  3  \*  2   打印得到6

例2：expr `expr 2 + 3` \* 4  打印得到20


<br>
# 第6章条件判断

1．基本语法

[ condition ]（注意condition前后要有空格）

注意：条件非空即为true，[ hxr ]返回true，[] 返回false。

2\. 常用判断条件

-z判断字符串是否为空串

取反  if !(test -z $files )

（1）两个整数之间比较

= 字符串比较

-lt 小于（less than）  -le 小于等于（less equal）

-eq 等于（equal）  -gt 大于（greater than）

-ge 大于等于（greater equal）  -ne 不等于（Not equal）

（2）按照文件权限进行判断

-r 有读的权限（read）  -w 有写的权限（write）

-x 有执行的权限（execute）

（3）按照文件类型进行判断

-f 文件存在并且是一个常规的文件（file）

-e 文件存在（existence）  -d 文件存在并是一个目录（directory）

-n  “$1” 判断字符串是否为空

或直接if [ $1 ] 如果未传参，则为false。

3.多条件判断

[ condition ] && [ condition ] 与

[ condition ] || [ condition ]  或


**例：**
```
#!/bin/bash
if [[ ! 1 -eq 2 ]] && [[ 2 -eq 2 ]];then
 echo true
fi
```

<br>
# 第7章 流程控制（重点）

## **7.1 if 判断**
```sh
if [ 条件判断 ]
then
  程序
elif [ 条件判断 ]
  程序
else
  程序
fi
```
注意事项：
（1）[ 条件判断式 ]，中括号和条件判断式之间必须有空格
（2）if后要有空格

## **7.2 case 语句**
```sh
case $1 in
"字符串")
程序
;;
"字符串")
程序
;;
"*")
程序
;;
esac
```

## **7.3 for 循环**

1．基本语法1
```sh
for (( 初始值;循环控制条件;变量变化 ))
do
  程序
Done
```

1．基本语法2（遍历，类似java中的增强for）
｛109...100｝表示109到100的所有数
```sh
for 变量 in 值1 值2 值3…
do
   程序
done
```

**for循环遍历命令行参数**
\$\* 和 \$@ 都表示传递给函数或脚本的所有参数，不被双引号“”包含时，都以$1 $2 …$n的形式输出所有参数。都被双引号包含时，$*代表一个整体，遍历就输出一个字符串。$@把参数区分对待，可以输出每个命令行参数。

## **7.4 while 循环**
```sh
while [ 条件判断式 ]
do
  程序
done
```

<br>
**退出脚本**
```
#!/bin/bash
exit 1
```
可以使用exit命令来退出脚本任务；exit 1 表示任务失败，exit 0 表示任务成功。

<br>
## 7.4 并行执行
使用 `&` 表示启动另一个线程执行，不阻塞主线程。`wait`表示等待之前的所有线程完成。
```
start-exec(){
    for host in cos-bigdata-test-hadoop-01 cos-bigdata-test-hadoop-02 cos-bigdata-test-hadoop-03;do
        (ssh ${host} "sudo -i -u azkaban bash -c 'cd /opt/module/azkaban-3.84.4/exec/;bin/start-exec.sh'")&
    done
    wait
}
```

<br>
# 第8章 参数
## 8.1 从read读取
1．基本语法

read(选项)(参数)

选项：

-p：指定读取值时的提示符；

-t：指定读取值时等待的时间（秒）。

参数

变量：指定读取值的变量名

当执行到这句话时，系统就会等待用户输入参数的值，并将用户输入的值赋给参数。

## 8.2 getopts 读取参数
除了使用$n来按顺序获取脚本参数，还可以使用getopts来指定参数的值。

例
```
#!/bin/bash

while getopts 'n:a:s:' arg;do
  case $arg in
  "s")
    score=$OPTARG
  ;;
  "a")
    age=$OPTARG
  ;;
  "n")
    name=$OPTARG
  ;;
  esac
done

echo $name $age $score
```
调用脚本
```
sh test.sh -a 18 -n cj -s 99
```
得到结果
```
cj 18 99
```

<br>
# 第9章 函数

## 9.1 系统函数

**basename**
basename [string / pathname] [suffix]   得到最后一个/后面的字符串，如果指定了suffix且字符串以suffix结尾，会将suffix的内容从结果中去掉。
例：`basename  asdfs/sadfs/gsdfd123a  123a`   得到结果 gsdfd

**dirname**
dirname [string / pathname]  得到最后一个/前面的字符串

## **9.2 自定义函数**
```sh
function 函数名（）｛
函数体
return  $num
｝
```
函数名    来调用该函数。

①括号可以省略，但一定要换行。
②return可以省略，如果不省略那么最好放到函数体的最后，return后面的语句不会执行。return可以返回一个数字，若返回的数字是负数，则return语句时效；若返回的是整数，则$?得到的是此数关于256的余数；若返回的是字符串，则$?得到的是255。return不适合返回计算结果，一般用来返回语句的执行状态。

# 第10章 Shell工具（重点）

## 10.1 cut（将多行内容根据分隔符分成多个域（-d），并输出指定的域（-f）；或者直接根据字符位置截取并输出（-c））

cut [选项参数]  filename      可以处理文件和管道符倒过来的流

说明：默认分隔符是制表符

    |选项参数 |功能
    |————————|—————————————————————————
    |-f      |列号，提取第几列
    |2，3    |表示2和3列；2-4表示2到4列；2-表示2列之后全是；
    |-5      |表示第五行和之前的行
    |-d      |分隔符，按照指定分隔符分割列
    |-c      |指定具体的字符 
    |2，5    |表示第2和第5个字符；2-5表示第2到第5个字符；2-表示第二个及以后的字符；-5表示第五个和之前的字符
--complement 	选项提取指定字段之外的列

例1： ifconfig | grep "inet[6]* addr" | grep "Bcast" | cut -f 2 -d : | cut -f 1 -d " "

获取ip地址

例2：ifconfig | grep "inet[6]* addr" | grep "Bcast" | cut -c 21-32

根据其所在的字符位置获取ip地址，但是不灵活，ip地址长度改变截取的内容不准确。

## 10.2 sed（根据筛选条件对文本进行增删改，但只能输出整行）

sed [选项参数]  [command]  [filename]     可以处理文件和管道符倒过来的流

|选项参数 | 功能 |
|--|--|
| -e  |直接在指令列模式上进行sed的动作编辑 |
| -i   |直接编辑源文件。如果不加-i，则不对源文件进行修改 |
| -n  |-n “2p” 直接输出第二行; sed -n "2,4p" 输出2到4行 |

|命令 | 功能描述 |
|--|--|
|a    | 新增，a的后面可以接字串，在下一行出现 |
|d    | 删除 |
|s    | 查找并替换 ，加上g表示全局替换 |

### 10.2.1 过滤行
`ifconfig |  sed  '2,3aXXX'`   表示在2行到3行下新建行插入XXX

`Ifconfig | sed  '2,5d' `   表示删除2到5行，注意2,5表示2到5行

`Ifconfig | sed  '2,3s/1/x/' ` 表示分别查找2行到3行中的第一个1，然后替换成x

`Ifconfig | sed  '2,3s/1/\*/g' ` 表示分别查找2行到3行中的全部1，然后替换成, *前最好加上转义符号。注意最后加上g（global）表示全局替换

`ifconfig | sed '2,3s/inet[6]* addr/Ip Address/' `正则表达式的应用，将2行到3行中的inet addr和inet6 addr替换成Ip  Address

`sed '/inet/d' sed.txt`  删除sed.txt文件中所有包含wo的行

`ifconfig | sed '/^e/,/^ *U/s/[0-9]/\*/g'` 从e开始的行到许多空格和U开始的行之间的全部行的数字都替换成*

`ifconfig | sed '2,3s/inet\([0-9]*\) addr/Ip\1 addr/' `将inet addr替换为Ip addr ，如果inet后有数字则保留。将要保留的部分括号括起来（括号要加转义字符），\1表示第一个要保留的字符保留到什么位置，最多保留9个。

`sed -i -e '2a/xxx' -e '2,3s/\(i\)net\([0-9]*\) addr/\1p\2/ ' b.txt`  对文件进行修改。

删除文件中最后三行，执行如下两行：
`nu=$(sed -n '$=' tls-ca-bundle.pem)` 获取总行数
`sed $(($A-2)),${A}d tls-ca-bundle.pem` 删除最后三行 



注意：单引号中的变量会被当作字符串。如果把单引号换成双引号，双引号中的变量是变量值。

## 10.3 awk（筛选并分隔行，通过awk语言来实现某些功能。可以进行计算和输出某个域的值）

awk [选项参数] ‘pattern1{action1}  pattern2{action2}...’ filename

- pattern：表示AWK在数据中查找的内容，就是匹配模式
- action：在找到匹配内容时所执行的一系列命令

| 选项参数  | 功能 |
|---|---|
| -F       |指定输入文件折分隔符   |
| -v       |赋值一个用户定义变量   |  


BEGIN｛｝和END｛｝是特殊的函数，

BEGIN｛｝会在数据处理之前执行，END｛｝会在数据处理之后执行。

注意： \$0表示该行整行内容；\$1...表示域的内容


|awk的内置变量      | 说明 |
|---|---|
|FILENAME  |  文件名 |
|NR        | 已读的记录数，所处理的行号 |
|NF        | 浏览记录的域的个数（切割后，列的个数）|


`awk -F : 'BEGIN{sum=0} {sum+=$3;print $3" "sum } END{sum}' passwd `   
将passwd文件的所有行以：为分隔符分隔，再将第三个域累加。

`awk -F : -v sum=0 '{sum+=$3;print $3" "sum} END{print sum}' passwd `   
-v可以指定一个变量，替代BEGIN中的定义变量。

`awk -F :  'BEGIN{sum=0}  /^a/{sum+=$4;print $4" "sum} END{print sum}'  passwd `  
筛选以a开头的行，以：为分隔符划分，将第四个域的值累加起来输出。

`awk -F : 'BEGIN{sum=0;print FILENAME} /^a/{sum+=$3;print NR" "$3" "sum} END{print sum" "NF}' passwd`
NR表示所处理的行号（BEGIN行号为0，END行号为所有行数加一），NF表示分割出来的域的个数。FILENAME是当前文件名。

`awk -F : '/inet[0-9]* addr/{print $2}' | awk -F " " 'NR==1,NR==2{print $1}'`  
可以通过NR来筛选出固定行号。

## 10.4 sort

sort(选项)(参数)

|选项	|说明|
|---|---|
|-n   |依照数值的大小排序，不加-n按字符串大小排序|
|-r	  |以相反的顺序来排序|
|-t	  |设置排序时所用的分隔字符|
|-k   |指定需要排序的列|
|-u   |去重|

参数：指定待排序的文件列表

 例：`cat passwd | grep ^a | sort -t : -k 3 -n -r `  将passwd中以a开头的行，以：为分隔符，取第三个域，按数值大小顺序倒序排序。

## 10.5 grep（按名称查找）

grep [选项] [查找内容] [源文件]

|选项	|功能 |
|---|--- |
|-n, --line-number |显示匹配行及行号 |
|-r, --recursion |递归查找当前目录及其子目录 |
|-i, --ignore-case |不区分大小写 |
|-c, --count |统计匹配的行数 |
|-v, --revert-match |  显示不包含匹配文本的所有行 |
| -E | 满足任意条件 grep -E "word1| word2|word3" file.txt |

`grep -r "hello" xx`  在xx文件中查找有hello的行
`grep -r "shen" /home`  在home目录及其子目录下查找有shen的行

**flume启停脚本**
```
#!/bin/bash

case $1 in
"start")
	for host in bigdata1
	do
		ssh bigdata2 "source /etc/profile ; nohup /opt/module/flume-1.7.0/bin/flume-ng agent -n a2 -c /opt/module/flume-1.7.0/conf -f /opt/module/flume-1.7.0/job/kafka-hdfs.conf 1>/dev/null 2>&1 &"
		if [ $? -eq 0 ]
		then
			echo ----- ${host} flume启动成功 -----
		fi
	done
;;
"stop")
	for host in bigdata1 #bigdata2
	do
		ssh ${host} "source /etc/profile ; ps -ef | awk -F \" \" '/kafka-hdfs.conf/ && !/awk/{print \$2}' | xargs kill "
		if [ $? -eq 0 ]
		then
			echo ----- ${host} flume关闭成功 -----
		fi
	done
;;
esac
```

**也可以通过pgrep命令快速查找进程号而不用awk截取进程号**
```
#!/bin/bash
case $1 in
"start"){
  echo '----- 启动 prometheus -----'
  nohup /opt/module/prometheus-2.26.0/prometheus --web.enable-admin-api --config.file=/opt/module/prometheus-2.26.0/prometheus.yml > /opt/module/prometheus-2.26.0/prometheus.log 2>&1 &
  echo '----- 启动 pushgateway -----'
  nohup /opt/module/pushgateway-1.4.0/pushgateway --web.listen-address :9091 > /opt/module/pushgateway-1.4.0/pushgateway.log 2>&1 &
  echo '----- 启动 grafana -----'
  nohup /opt/module/grafana-7.5.2/bin/grafana-server --homepath /opt/module/grafana-7.5.2 web > /opt/module/grafana-7.5.2/grafana.log 2>&1 &
};;
"stop"){
  echo '----- 停止 grafana -----'
  pgrep -f grafana | xargs kill
  echo '----- 停止 pushgateway -----'
  pgrep -f pushgateway | xargs kill
  echo '----- 停止 prometheus -----'
  pgrep -f prometheus | xargs kill
};;
esac
```

<br>
pgrep 是通过程序的名字来查询进程的工具
- pgrep 参数 程序

|选项 |功能 |
|---|---|
| -f | 显示完整程序，包括当前进程和子进程 | 
| -l | 显示源代码 | 
| -n | 显示新程序 | 
| -o | 显示旧程序 | 
| -v | 与条件不符合的程序 | 

<br>
# 十一、数组
Shell数组的定义:
Shell中用括号()来表示数组，数组元素之间用空格来分隔，由此，定义数组的一般形式为:  Array_name=(ele1 ele2 ele3 …… elen)
>注意，赋值号=两边不能由空格，必须紧挨着数组名和数组元素


- 显示数组长度
   ```
   arr=(a b c)
   echo ${#arr[@]}
   ```

- 取数组中所有值
   ```
   arr=(a b c)
   echo ${arr[*]}
   # 或
   arr=(a b c)
   echo ${arr[@]}
   ```

- 取下标对应的值(第一个元素的下标为0，同java)
   ```
   arr=(a b c)
   echo ${arr[0]}
   ```

- 通过seq创建等差数组
   ```
   $(seq 0 1 ${#array[@]})
   ```

- 例：将字符串转为数组，通过下标遍历数组中元素
   ```
   str=177,178
   array=(`echo $str | sed 's/,/ /g'`)
   echo ${array[@]}
   for i in $(seq 0 1 ${#array[@]})
   do
    echo ${array[i]}
   done
   ```


<br>
# 十二、企业真实面试题
## 11.1 京东
#### 问题1：使用Linux命令查询file1中空行所在的行号
执行命令如下
```
[hxr@bigdata2 bin]\$ awk '/^$/{print NR}' sed.txt
```
输出
```
5
```

#### 问题2：有文件chengji.txt内容如下:
```
张三 40
李四 50
王五 60
```
使用Linux命令计算第二列的和并输出
```
[hxr@bigdata2 bin]\$ cat chengji.txt | awk -F " " '{sum+=$2} END{print sum}'
```
输出
```
150
```

<br>
## 11.2 搜狐&和讯网
#### 问题1：Shell脚本里如何检查一个文件是否存在？如果不存在该如何处理？

执行命令如下
```
#!/bin/bash
if [ -f file.txt ]; then
   echo "文件存在!"
else
   echo "文件不存在!"
fi
```

<br>
## 11.3 新浪
#### 问题1：用shell写一个脚本，对文本中无序的一列数字排序

```
[root@CentOS6-2 ~]# cat test.txt
9
8
7
6
5
4
3
2
10
1
```

执行命令如下
```
[root@CentOS6-2 ~]# sort -n test.txt|awk '{a+=$0;print $0}END{print "SUM="a}'
```
输出
```
1
2
3
4
5
6
7
8
9
10
SUM=55
```

<br>
## 11.3 金和网络
#### 问题1：请用shell脚本写出查找当前文件夹（/home）下所有的文本文件内容中包含有字符”shen”的文件名称
```
[hxr@bigdata2 bin]\$ grep -r "shen" /home | cut -d ":" -f 1
```


<br>
## 获取周末和月末的日期
```
# 遍历日期然后获取时间节点
judge_date=`date -d "$end_date +1 day" +%F`
while [[ "$judge_date" != "$start_date" ]];do
  judge_date=`date -d "$judge_date -1 day" +%F`;
  week=`date -d "$judge_date" +%a`
  if [ "$week" == '日' ];then
#    target_dates="$target_dates $judge_date"
    target_dates="$judge_date $target_dates"
    continue
  fi

# 这里取下个月的命令有bug，注意规避
  current_month=`date -d "$judge_date" +%y-%m`
  next_month=`date -d "$current_month-01 +1 month" +%y-%m`
  month_head="$next_month-01"
  month_tail=`date -d "$month_head -1 day" +%F`
  if [ "$judge_date" == "$month_tail" ];then
#    target_dates="$target_dates $judge_date"
    target_dates="$judge_date $target_dates"
    continue
  fi
```
