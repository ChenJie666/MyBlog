---
title: Tensorflow安装
categories:
- 人工智能
---
###概述
**需要安装**
- Anocanda：工具包，包含了python基础环境，默认安装了很多实用的python包，有一个很强大的命令行管理工具conda，以及一个界面的应用管理平台；
- Jupyter notebook：科学计算的notebook工具；
- Pycharm：python开发的IDE；

###1. 首先下载Anaconda
[https://mirrors.tuna.tsinghua.edu.cn/anaconda/archive/](https://mirrors.tuna.tsinghua.edu.cn/anaconda/archive/)
从清华镜像源下载后安装。

打开anaconda的命令框Anaconda Prompt，输入python可以看到python的版本。

python -m pip install --upgrade pip 更新pip版本。
conda list  查看库中的所有包

###2. 安装Visual C++
下载安装vc_redis.x64.exe

###3. 安装tensorflow2.4的CPU版本
`pip3 install tensorflow-cpu==2.4.0 -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com`
如果不写-cpu，会根据是否有显卡自动安装对应的版本。

输入import tensorflow，没有报错说明安装完成。输入exit()退出。

###4. 在jupyter notebook中运行
1. 打开jupyter
`jupyter notebook`
2. 创建新的笔记
new -> python3
3. 导入tensorflow并给一个别名
`import tensorflow as tf`
4. 打印tensorflow的版本
`tf.__version__`

****
<br>
**以上是使用Anaconda安装，以下是使用conda的简易版本Miniconda进行安装**

**需要先将Anaconda卸载干净**
1. conda install anaconda-clean
2. anaconda-clean --yes
3. 运行Uninstall-Anaconda3.exe

**设置Miniconda**
1. 安装Miniconda
2. 设置conda使用国内源：

在当前用户下创建文件 .
```
channels:
    - defaults
show_channel_urls: true
default_channels:
    - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
    - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
custom_channels:
    conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
    msys2: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
    bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
    menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
    pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
```

**新增镜像源**
```
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
```
`conda config --set show_channel_urls yes`

**删除镜像源**
`conda config --remove channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/`

**查看配置的镜像源**
`conda config --show-sources`

**安装jupyter notebook**
安装 
`pip install jupyter -i https://pypi.tuna.tsinghua.edu.cn/simple/`
启动 
`jupyter notebook`

注：如果启动报错_ssl导入失败，需要将\Libraryin下的libssl-1_1-x64.dll和libcrypto-1_1-x64.dll文件复制到\DLLs文件夹下。

**安装tensorflow相关的库**
pip install numpy pandas matplotlib sklearn -i https://pypi.tuna.tsinghua.edu.cn/simple/

<br>
****

### 5. 安装tensorflow2.4的GPU版本
CUDA(通用并行计算架构，10.0版本)和cudnn(神经网络加速库，版本号不小于7.4.1)是GPU的两个依赖库，不需要手动安装。
1. 首先检查显卡驱动版本是否大于410.x 
`navidia-smi`
2. 安装基于GPU计算的tensorflow 2.4.0
`pip3 install tensorflow-gpu==2.4.0 -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com`
3. 测试是否安装成功
`import tensorflow as tf`
`tf.__version__`
`tf.config.list_physical_devices('GPU')` (旧版`tf.test.is_gpu_available()`)
返回True表示安装完成

### 6. 部署GPT-2模型
[GPT-2 开源模型本地搭建 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/620698265)

环境安装
```
pip3 install flask -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com
pip3 install numpy==1.19.4                 -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com
pip3 install regex==2020.11.13             -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com
pip3 install tensorflow-addons==0.12.1     -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com
pip3 install tensorflow-estimator==2.4.0   -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com
pip3 install tensorflow-hub==0.11.0        -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com
pip3 install tensorflow-io-gcs-filesystem==0.20.0 -i http://pypi.douban.com/simple/ --trusted-host pypi.douban.com
pip3 install tensorflow-text==2.4.3        -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com
pip3 install typing-extensions==3.10.0.0   -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com
pip3 install --upgrade Tokenizers          -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com
pip3 install transformers==4.0.0           -i http://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com
pip3 install ctypes                        -i http://pypi.douban.com/simple/ --trusted-host pypi.douban.com
```
模型下载代码，文件可以保存为 download.py
```
from transformers import GPT2Tokenizer, TFGPT2LMHeadModel

model_name = 'gpt2'  # 模型名称，可以是 gpt2, gpt2-medium, gpt2-large, gpt2-xl 中的任意一个
tokenizer = GPT2Tokenizer.from_pretrained(model_name)
model = TFGPT2LMHeadModel.from_pretrained(model_name)
model.save_pretrained(f"./{model_name}")  # 将模型保存到本地
tokenizer.save_pretrained(f"./{model_name}")  # 将 tokenizer 保存到本地
```
模型调用代码
```
import tensorflow as tf
import datetime
from transformers import GPT2Tokenizer, TFGPT2LMHeadModel
from flask import Flask, jsonify, request, render_template

model_dir = "C:/01.project/chatgpt/gpt-2/models/gpt2"
# 加载 GPT-2 tokenizer
tokenizer = GPT2Tokenizer.from_pretrained(model_dir)
# 加载 GPT-2 模型
model = TFGPT2LMHeadModel.from_pretrained(model_dir)

# 创建 Flask 实例
app = Flask(__name__)

# 定义 API 接口
@app.route('/generate', methods=['POST'])
def generate_text():
    # 从请求中获取文本
    input_text = request.get_json()['text']
    # 使用 tokenizer 对文本进行编码
    input_ids = tokenizer.encode(input_text, return_tensors='tf')
    # 使用模型生成文本
    output_ids = model.generate(input_ids, max_length=100, num_return_sequences=1)
    # 使用 tokenizer 对生成的文本进行解码
    output_text = tokenizer.decode(output_ids[0], skip_special_tokens=True)
    # 返回生成的文本
    return jsonify({'generated_text': output_text})

# 启动应用
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
```

模型测试效果
`curl -X POST http://localhost:5000/generate -H "Content-Type: application/json" -d "{\"text\":\"what day is it today\"}"`
