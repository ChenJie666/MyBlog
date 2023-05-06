---
title: Conda创建Python虚拟环境
categories:
- Python
---
# 前言
如果在一台电脑上, 想开发多个不同的项目, 需要用到同一个包的不同版本, 如果使用上面的命令, 在同一个目录下安装或者更新, 新版本会覆盖以前的版本, 其它的项目就无法运行了。

**解决方案 :** 虚拟环境 

**作用 :** 虚拟环境可以搭建独立的python运行环境, 使得单个项目的运行环境与其它项目互不影响.

# 一、安装Anaconda
## 1.1 安装
**linux环境**
```
bash Anaconda3-2019.07-Linux-x86_64.sh
```
**window环境**
直接双击安装exe文件，然后根据安装向导进行安装

## 1.2 环境变量设置
安装conda后，需要设置环境变量
```
E:\miniconda3\Libraryin;E:\miniconda3;E:\miniconda3\Scripts;
```

## 1.3 Conda下载镜像设置
**通过修改配置文件实现**
在当前用户路径下的.condarc文件中可以指定使用conda下载时所使用的镜像地址：
```
channels:
  - http://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
  - http://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
  - http://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/msys2/
show_channel_urls: true
offline: true
```
>如果指定了镜像，可能会导致创建虚拟环境时，无法下载指定的python版本。

<br>
**通过修改命令实现**
- 显示目前conda的数据源有哪些
conda config --show channels
- 删除默认的channel安装源
conda config --remove channels defaults
或删除特定的channel
conda config --remove channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
- 添加国内镜像源
```
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
conda config --set ssl_verify true
conda config --set show_channel_urls yes
```
根本上还是通过.condarc来实现。

## 1.4 目录结构
- DLLs子目录：Python的*.pyd(Python动态模块)文件与几个Windows的*.dll(动态链接库)文件。
- Doc子目录：在Windows平台上，只有一个python2715.chm文件，里面集成了Python的所有文档，双击即可打开阅读，非常方便。
- include子目录：Python的C语言接口头文件，当在C程序中集成Python时，会用到这个目录下的头文件。
- Lib子目录：Python自己的标准库，包，测试套件等，非常多的内容。其中dist-packages文件夹中是系统自带的module，site-packages文件夹中是自己安装的module。
- libs子目录：这个目录是Python的C语言接口库文件。
- Scripts子目录：pip可执行文件的所在目录，通过pip可以安装各种各样的Python扩展包。这也是为什么这个目录也需要添加到PATH环境变量中的原因。
- tcl子目录：Python与TCL的结合。
- Tools子目录：工具，有的子目录下有README.txt文件，可以查看具体的工具用途。


<br>
# 二、升级Anaconda
**查看配置**
conda config --show
**检查conda版本**
conda --version

**检查更新当前conda**
conda update conda 
**检查更新anaconda**
conda update anaconda
**update最新版本的anaconda-navigator**
conda update anaconda-navigator    

<br>
# 三、Conda基本命令
在 `%CONDA_HOME%/condabin`目录下启动cmd命令窗口，执行`conda activate`命令，可以进入base环境的命令窗口。
## 3.1 环境命令
**update虚拟环境为最新版本的conda**
conda update -n [env_name] conda 

**关闭自动激活状态**
conda config --set auto_activate_base false  
**关闭自动激活状态**
conda config --set auto_activate_base true  

**显示所有的虚拟环境**         
conda env list    或     conda info --envs        

**创建python3.5的xxxx虚拟环境**
conda create -n [your_env_name] python=3.5 
**复制虚拟环境(必须在base环境下进行以上操作)**
conda create -n [new_env_name] --clone [env_name]
**删除虚拟环境(必须在base环境下进行以上操作)**
conda remove -n [your_env_name] --all  
**重命名虚拟环境**
直接修改环境所在路径的文件夹名即可

**切换虚拟环境**
conda activate xxxx         
**关闭当前虚拟环境**
conda deactivate     

## 3.2 安装命令
**查看已安装模块**
conda list

**查看指定包可安装版本信息命令**
conda search tensorflow

**安装模块 (作用同pip)**
conda install [package]
**虚拟环境中安装额外的包**
conda install -n [your_env_name] [package]
**更新模块**
conda update [package]
**删除环境中的某个模块**
conda remove -n [your_env_name]  [package]  

**conda 安装本地包**
conda install --use-local  ~/Downloads/a.tar.bz2

**删除没有用的包**
conda clean -p     
**删除tar包**
conda clean -t   
**删除所有的安装包及cache**
conda clean -y --all 


<br>
# 四、Pip基本命令
**重新安装**
python -m ensurepip
**升级pip**
python -m pip install --upgrade pip
如果报错不存在pip模块，那么重新安装pip  `python -m ensurepip`

**列出当前缓存的包**
pip list 
**展示指定的已安装的包**
pip show [package] 
**检查包的依赖是否合适**
pip check [package]

**清除缓存**
pip purge
**删除对应的缓存**
pip remove 

**安装包**
pip install [package]
**pip安装本地包**
pip install   ～/Downloads/a.whl
**删除包**
pip uninstall [package] 



<br>
**pip安装时指定镜像源**
pip install requests -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com

如果报错Fatal error in launcher: Unable to create process using '"e:\miniconda3\python.exe"  "F:\miniconda3\Scripts\pip.exe" ': ???????????，则使用命令 `python.exe -m pip install --upgrade pip`

| 源 | 地址 |
| -- | -- |
|阿里云     |               http://mirrors.aliyun.com/pypi/simple/ |
|中国科技大学     |    https://pypi.mirrors.ustc.edu.cn/simple/ |
|豆瓣(douban)    |     http://pypi.douban.com/simple/ |
|清华大学         |       https://pypi.tuna.tsinghua.edu.cn/simple/ |
|中国科学技术大学 |  http://pypi.mirrors.ustc.edu.cn/simple/ |
