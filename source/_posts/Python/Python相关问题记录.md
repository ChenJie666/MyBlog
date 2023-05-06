---
title: Python相关问题记录
categories:
- Python
---
### 问题一
- 现象：pip安装模块时报错
```
WARNING: pip is configured with locations that require TLS/SSL, however the ssl module in Python is not available.
WARNING: Retrying (Retry(total=4, connect=None, read=None, redirect=None, status =None)) after connection broken by 'SSLError("Can't connect to HTTPS URL because the SSL module is not available.")': /simple/misaka/
WARNING: Retrying (Retry(total=3, connect=None, read=None, redirect=None, status=None)) after connection broken by SSLError("Can't connect to HTTPS URL because the SSL module is not available.")': /simple/misaka/
WARNING: Retrying (Retry(total=2, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError("Can't connect to HTTPS URL because the SSL module is not available.")': /simple/misaka/WARNING: Retrying (Retry(total=1, connect=None, read=None, redirect=None, status=None)) after connection broken by 'SSLError("Can't connect to HTTPS URL because the SSL module is not available.")': /simple/misaka/
```

同时，如果使用pycharm连接该python环境(python环境是conda的的虚拟环境)，控制台打印错误如下
```
E:\miniconda3nvs\spider\python.exe "E:\PyCharm 2020.1\plugins\python\helpers\pydev\pydevconsole.py" --mode=client --port=7368
.....
  File "E:\miniconda3nvs\spider\lib\ssl.py", line 98, in <module>
    import _ssl             # if we can't import it, let the error propagate
ImportError: DLL load failed: 找不到指定的程序。
```
- 原因：
   - 可能原因一：环境变量设置问题。
进入settings -> Console -> Python Console，点击Environment variables框右侧的Browse按键，可以查看环境变量。发现环境变量没有问题。
   - 可能原因二：进入python环境，然后导入ssl模块 import ssl，发现报错。那么就是无法到如ssl模块的问题了。
解决：网上查看解决方法，需要重新编译python3，那么对于conda，就只好删除然后重新创建该环境了 conda create -n spider python=3.7.7 。


<br>
### 问题二
- 现象：使用命令conda craete -n python=2.7 创建虚拟环境时，报错找不到phthon2.7模块。
- 原因：因为在用户目录下的.condarc配置中指定了清华镜像源导致无法安装对应的python版本。
- 解决：删除掉.condarc文件即可。


<br>
### 问题三：
- 现象：`pip install misaka==2.1.1`命令安装模块misaka时一直报错缺少Visual组件
```
rror: Microsoft Visual C++ 14.0 is required. Get it with "Build Tools for Visual Studio": https://visualstudio.microsoft.com/downloads/
```
- 原因：缺少Microsoft Visual C++ 14.0

- 解决：
   - 尝试一：直接通过whl预编译的文件安装就不需要C++环境，在[python的whl库](https://www.lfd.uci.edu/~gohlke/pythonlibs/)上查找misaka包，但是没有找到。尝试失败了。
   - 尝试二：在[misaka官网](https://pypi.org/project/misaka/#files)上下载了misaka-2.1.1.tar.gz文件，解压后通过python setup.py install 进行安装，可是还是需要Microsoft Visual C++ 14.0环境。尝试又失败了。
   - 尝试三：通过在[微软官网](https://visualstudio.microsoft.com/downloads/)下载了几个版本的Build Tools来安装环境，最后应该时通过下载Visual Studio 2019安装包，通过安装其中的环境包后进行重启，再次安装misaka就成功了。
![image.png](Python相关问题记录.assets\212ad93797de493181901a6e63050746.png)


<br>
### 问题四：
- 现象：在pycharm中，创建了一个文件Thread，此时弹出提示需要指定文件格式，发现没有加文件后缀，加上该后缀后同时指定了文件格式。这样会导致该文件无法被pycharm正确识别，即是重命名文件，或者删除后再次创建，都会无法识别。
- 解决：在settings -> Editor -> File Types中的Registered patterns中添加该文件并应用，然后在Registered patterns中再删除文件并应用。就可以发现该文件已经被正常识别了。
