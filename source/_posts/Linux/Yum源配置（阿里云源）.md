---
title: Yum源配置（阿里云源）
categories:
- Linux
---
1) 安装wget
yum install -y wget
2) 备份/etc/yum.repos.d/CentOS-Base.repo文件
cd /etc/yum.repos.d/
mv CentOS-Base.repo CentOS-Base.repo.back
3) 下载阿里云的Centos-7.repo文件
wget -O CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
4) 重新加载yum
yum clean all
yum makecache
