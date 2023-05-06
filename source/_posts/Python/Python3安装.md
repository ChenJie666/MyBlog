---
title: Python3安装
categories:
- Python
---
# 1. 安装依赖环境

输入命令：yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel

# 2. 下载Python3
下载Python3.7.1压缩包到本地：wget https://www.python.org/ftp/python/3.7.1/Python-3.7.1.tgz
解压到目录下 tar -zxvf Python-3.7.1.tgz -C /opt/module/

# 3. 编译安装
## 安装gcc    
`yum install gcc`

## 3.7版本之后需要一个新的包libffi-devel
yum install libffi-devel -y

## 进入python文件夹，生成编译脚本(指定安装目录)
./configure --prefix=/usr/local/python3  

## 编译
make

## 编译成功后，编译安装
make install

<br>
# 4. 建立Python3和pip3的软链
ln -s /usr/local/python3/bin/python3 /usr/bin/python3
ln -s /usr/local/python3/bin/pip3 /usr/bin/pip3

# 5. 并将/usr/local/python3/bin加入PATH
```
# vim ~/.bash_profile

# .bash_profile

# Get the aliases and functions

if [ -f ~/.bashrc ]; then

. ~/.bashrc

fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin:/usr/local/python3/bin

export PATH
```
