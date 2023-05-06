---
title: IOS-安装
categories:
- 工具
---
1. 安装Vmware；
2. 关闭所有vm相关服务和进程，以管理员权限运行unlock文件夹中的win-install.cmd，完成后自动关闭运行窗口；
3. 启动Vmware，安装程序光盘文件选择下载的cdr文件，下一步后选择对应的IOS版本；
4. 进入虚拟机后出现[不可恢复错误]，进入安装的cdr系统所在目录，打开 macOS 10.14.vmx 文件，在最后一行加上
```
smc.version= "0"
```

**注：**
1. 如果unlock后没有出现IOS系统选项，可能是Vmware版本高于unlock，可以[下载最新的unlock](https://github.com/paolo-projects/unlocker/)

2. Mac OS 版本过高，可能导致Vmware Tools版本不兼容，需要[下载高版本的Vmware Tools](https://customerconnect.vmware.com/en/downloads/info/slug/datacenter_cloud_infrastructure/vmware_tools/11_x) [或](http://softwareupdate.vmware.com/cds/vmw-desktop/fusion)，然后手动安装(推出桌面上的DVD盘，然后右键右下角的光盘，选择最新的 VmwareTools.iso，连接后安装即可；如果遇到安全问题，需要进 [系统偏好设置–>安全性与隐私–>通用–>设置为appstore与被认可的开发者] )。

3. 文件共享
①VMware tools安装完成后，在VMware的设置中启用共享文件夹；
②进入Mac虚拟机，打开顶部的Finder访答，选择偏好设置。在finder偏好设置窗口选在边栏，在“设备”中单击选中“xx的Mac”；
③？？？

4. 修改分辨率？？？
