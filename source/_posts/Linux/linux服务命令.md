---
title: linux服务命令
categories:
- Linux
---
启动一个服务：systemctl start postfix.service
关闭一个服务：systemctl stop postfix.service
重启一个服务：systemctl restart postfix.service
显示一个服务的状态：systemctl status postfix.service

在开机时启用一个服务：systemctl enable postfix.service
在开机时禁用一个服务：systemctl disable postfix.service
判断一个服务是否开机自启：systemctl is-enabled postfix.service
在enable的时候会打印出来该启动文件的位置

**类似systemctl，用于操作native service**
添加脚本为服务(需要指定启动级别和优先级)：chkconfig --add 脚本
删除服务：chkconfig --del 脚本
单独查看某一服务是否开机启动的命令 ：chkconfig --list 服务名
单独开启某一服务的命令 ;chkconfig 服务名 on 
单独关闭某一服务的命令；chkconfig 服务名 off
查看某一服务的状态：/etc/intd.d/服务名 status

列出所有已经安装的服务及状态：
systemctl list-units
systemctl list-unit-files 
查看服务列表状态:
systemctl list-units --type=service 

查看服务是否开机启动： systemctl is-enabled postfix.service
查看已启动的服务列表： systemctl list-unit-files | grep enabled
查看启动失败的服务列表： systemctl --failed

查看服务日志：`journalctl -u [service_name] -n 10 -f`

启用服务就是在当前“runlevel”的配置文件目录  /etc/systemd/system/multi-user.target.wants里，建立 /usr/lib/systemd/system 里面对应服务配置文件的软链接；禁用服务就是删除此软链接，添加服务就是添加软连接。
