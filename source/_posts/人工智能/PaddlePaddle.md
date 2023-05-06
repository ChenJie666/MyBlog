---
title: PaddlePaddle
categories:
- 人工智能
---
# 一、搭建
[Windows下的Conda安装-使用文档-PaddlePaddle深度学习平台](https://www.paddlepaddle.org.cn/documentation/docs/zh/install/conda/windows-conda.html#anchor-0)

**安装PaddleDection开发套件**
下载PaddleDection包，下载requirement中的模块 `pip install -r .equirements.txt`
>如果cython_bbox安装失败，使用如下命令安装
`python -m pip install git+https://github.com/yanfengliu/cython_bbox.git`


# 二、使用
## 2.1 官方demo(识别图片上的数字)
[10分钟快速上手飞桨-使用文档-PaddlePaddle深度学习平台](https://www.paddlepaddle.org.cn/documentation/docs/zh/guides/beginner/quick_start_cn.html)

```py
import paddle
import numpy as np
from paddle.vision.transforms import Normalize

transform = Normalize(mean=[127.5], std=[127.5], data_format='CHW')
# 下载数据集并初始化 DataSet
train_dataset = paddle.vision.datasets.MNIST(mode='train', transform=transform)
test_dataset = paddle.vision.datasets.MNIST(mode='test', transform=transform)

# 模型组网并初始化网络
lenet = paddle.vision.models.LeNet(num_classes=10)
model = paddle.Model(lenet)

# 模型训练的配置准备，准备损失函数，优化器和评价指标
model.prepare(paddle.optimizer.Adam(parameters=model.parameters()),
              paddle.nn.CrossEntropyLoss(),
              paddle.metric.Accuracy())

# 模型训练
model.fit(train_dataset, epochs=5, batch_size=64, verbose=1)
# 模型评估
model.evaluate(test_dataset, batch_size=64, verbose=1)

# 保存模型
model.save('./output/mnist')
# 加载模型
model.load('output/mnist')

# 从测试集中取出一张图片
img, label = test_dataset[0]
# 将图片shape从1*28*28变为1*1*28*28，增加一个batch维度，以匹配模型输入格式要求
img_batch = np.expand_dims(img.astype('float32'), axis=0)

# 执行推理并打印结果，此处predict_batch返回的是一个list，取出其中数据获得预测结果
out = model.predict_batch(img_batch)[0]
pred_label = out.argmax()
print('true label: {}, pred label: {}'.format(label[0], pred_label))
# 可视化图片
from matplotlib import pyplot as plt
plt.imshow(img[0])
plt.show()
```

<br>
## 2.2 求解线性模型
```
# 现在面临这样一个任务：
# 乘坐出租车，起步价为10元，每行驶1公里，需要在支付每公里2元
# 当一个乘客坐完出租车后，车上的计价器需要算出来该乘客需要支付的乘车费用

def calculate_fee(distance_travelled):
    return 10 + 2 * distance_travelled


for x in [1, 3, 5, 9, 10, 20]:
    print(calculate_fee(x))

# 结果为
# 12
# 16
# 20
# 28
# 30
# 50

# 接下来，把问题稍微变换一下，现在知道乘客每次出行的公里数和支付的总费用
# 需要求解乘车的起步价和每公里的费用
import paddle

x_data = paddle.to_tensor([[1.0], [3.0], [5.0], [9.0], [10.0], [20.0]])
y_data = paddle.to_tensor([[12.0], [16.0], [20.0], [28.0], [30.0], [50.0]])

linear = paddle.nn.Linear(in_features=1, out_features=1)
w_before_opt = linear.weight.numpy().item()
b_before_opt = linear.bias.numpy().item()
print(w_before_opt, b_before_opt)  # 随机初始化的值

mse_loss = paddle.nn.MSELoss()
sgd_optimizer = paddle.optimizer.SGD(learning_rate=0.001, parameters=linear.parameters())

total_epoch = 5000
for i in range(total_epoch):
    y_predict = linear(x_data)
    loss = mse_loss(y_predict, y_data)
    loss.backward()
    sgd_optimizer.step()
    sgd_optimizer.clear_gradients()

    if i % 1000 == 0:
        print(i, loss.numpy())

print("finish training, loss = {}".format(loss.numpy()))

w_after_opt = linear.weight.numpy().item()
b_after_opt = linear.bias.numpy().item()
print(w_after_opt, b_after_opt)  # 最终的拟合值
```

<br>
## 2.3 预测波士顿房价
```
import paddle
import numpy as np


# 1. 准备数据
def load_data():
    ## 1.1 从文件导入数据
    datafile = '../dataset/housing.data'
    data = np.fromfile(datafile, sep=' ', dtype=np.float32)
    print(len(data))

    ## 1.2 数据转换
    # 每条数据包括14项，其中前面13项是影响因素，第14项是相应的房屋价格中位数
    feature_names = ['CRIM', 'ZN', 'INDUS', 'CHAS', 'NOX', 'RM', 'AGE',
                     'DIS', 'RAD', 'TAX', 'PTRATIO', 'B', 'LSTAT', 'MEDV']
    feature_num = len(feature_names)

    # 将原始数据进行reshape，变成[N, 14]形状
    data = data.reshape([data.shape[0] // feature_num, feature_num])

    # 将原数据拆分成训练集和测试集
    # 这里使用80%的数据做训练，20%的数据做测试
    # 测试集和训练集必须是没有交集的
    ratio = 0.8
    offset = int(data.shape[0] * ratio)

    training_data = data[:offset]

    # 计算train数据集的最大值，最小值，平均值
    maximums, minimums, avgs = training_data.max(axis=0), training_data.min(axis=0), training_data.sum(axis=0) / \
                               training_data.shape[0]

    # 记录数据的归一化参数，在预测时对数据做归一化
    global max_values
    global min_values
    global avg_values
    max_values = maximums
    min_values = minimums
    avg_values = avgs

    # 对数据进行归一化处理
    for i in range(feature_num):
        data[:, i] = (data[:, i] - avgs[i]) / (maximums[i] - minimums[i])

    ## 1.3 训练集和测试集的划分
    training_data = data[:offset]
    test_data = data[offset:]
    return training_data, test_data


# 2. 模型组网
class Regressor(paddle.nn.Layer):
    # self代表类的实例自身
    def __init__(self):
        super(Regressor, self).__init__()
        self.linear = paddle.nn.Linear(in_features=13, out_features=1)

    # 网络前向计算
    def forward(self, inputs):
        x = self.linear(inputs)
        return x


# 声明定义好的线性回归模型
model = Regressor()

# 3. 数据训练
# 开启模型训练模式
model.train()
# 加载数据
training_data, test_data = load_data()

# 定义优化算法,使用随机梯度下降SGD，学习率设置为0.01
opt = paddle.optimizer.SGD(learning_rate=0.01, parameters=model.parameters())

EPOCH_NUM = 10  # 设置外层循环次数
BATCH_SIZE = 10  # 设置batch大小

# 定义外层循环
for epoch_id in range(EPOCH_NUM):
    # 在每轮迭代开始之前，将训练数据的顺序随机的打乱
    np.random.shuffle(training_data)
    # 将训练数据进行拆分，每个batch包含10条数据
    mini_batches = [training_data[k:k + BATCH_SIZE] for k in range(0, len(training_data), BATCH_SIZE)]
    # 定义内层循环
    for iter_id, mini_batch in enumerate(mini_batches):
        x = np.array(mini_batch[:, :-1])  # 获得当前批次训练数据
        y = np.array(mini_batch[:, -1:])  # 获得当前批次训练标签（真实房价）
        # 将numpy数据转为paddle tensor形式
        house_features = paddle.to_tensor(x)
        prices = paddle.to_tensor(y)

        # 前向计算
        predicts = model(house_features)

        # 计算损失
        loss = paddle.nn.functional.square_error_cost(input=predicts, label=prices)
        mse = paddle.mean(loss)
        if iter_id % 20 == 0:
            print("epoch: {}, iter: {}, loss is: {}".format(epoch_id, iter_id, mse.numpy()))

        # 反向传播
        mse.backward()
        # 最小化loss，更新参数
        opt.step()
        # 清除梯度
        opt.clear_grad()

# 4. 保存模型参数到字典中，将字典落盘为LR_model.pdparams文件
paddle.save(model.state_dict(), 'LR_model.pdparams')

# 读取模型，参数为保存模型参数的文件地址
model_dict = paddle.load('LR_model.pdparams')
model.load_dict(model_dict)

# 将该模型及其所有子层设置为预测模式
model.eval()


# 5. 预测数据
def load_one_example():
    # 从上边已加载的测试集中，随机选择一条作为测试数据
    idx = np.random.randint(0, test_data.shape[0])
    idx = -10
    one_data, label = test_data[idx, :-1], test_data[idx, -1]
    # 修改该条数据shape为[1,13]
    one_data = one_data.reshape([1, -1])

    return one_data, label


# 将数据转为动态图的variable格式
one_data, label = load_one_example()
one_data = paddle.to_tensor(one_data)
predict = model(one_data)

# 对结果做反归一化处理
predict = predict * (max_values[-1] - min_values[-1]) + avg_values[-1]
# 对label数据做反归一化处理
label = label * (max_values[-1] - min_values[-1]) + avg_values[-1]

print("Inference result is {}, the corresponding label is {}".format(predict.numpy(), label))

# 打印结果为
epoch: 0, iter: 0, loss is: [0.2190369]
epoch: 0, iter: 20, loss is: [0.26175416]
epoch: 0, iter: 40, loss is: [0.18272282]
epoch: 1, iter: 0, loss is: [0.20169991]
epoch: 1, iter: 20, loss is: [0.25468302]
epoch: 1, iter: 40, loss is: [0.12643944]
epoch: 2, iter: 0, loss is: [0.07170647]
epoch: 2, iter: 20, loss is: [0.27606457]
epoch: 2, iter: 40, loss is: [0.0587504]
epoch: 3, iter: 0, loss is: [0.08177032]
epoch: 3, iter: 20, loss is: [0.17796104]
epoch: 3, iter: 40, loss is: [0.01438468]
epoch: 4, iter: 0, loss is: [0.14358227]
epoch: 4, iter: 20, loss is: [0.04590528]
epoch: 4, iter: 40, loss is: [0.11086401]
epoch: 5, iter: 0, loss is: [0.0784346]
epoch: 5, iter: 20, loss is: [0.06981862]
epoch: 5, iter: 40, loss is: [0.02968376]
epoch: 6, iter: 0, loss is: [0.05453171]
epoch: 6, iter: 20, loss is: [0.0677472]
epoch: 6, iter: 40, loss is: [0.00175112]
epoch: 7, iter: 0, loss is: [0.01291312]
epoch: 7, iter: 20, loss is: [0.06383369]
epoch: 7, iter: 40, loss is: [0.04227459]
epoch: 8, iter: 0, loss is: [0.01342294]
epoch: 8, iter: 20, loss is: [0.01199431]
epoch: 8, iter: 40, loss is: [0.03285793]
epoch: 9, iter: 0, loss is: [0.02604165]
epoch: 9, iter: 20, loss is: [0.037579]
epoch: 9, iter: 40, loss is: [0.01411492]
Inference result is [[19.120472]], the corresponding label is 19.700000762939453
```

<br>
## 2.4 预测病理性近视
通过对训练集进行训练得到模型参数。这里使用训练集进行测试，所以准确率仅供参考。
```
import paddle
import cv2
import numpy as np
import os
import random


# 对读入的图像数据进行预处理
def transform_img(img):
    # 将图片尺寸缩放到 224x224
    img = cv2.resize(img, (224, 224))
    # 读入的图像数据格式是[H, W, C]
    # 使用转置操作将其变成[C, H ,W]
    img = np.transpose(img, (2, 0, 1))
    img = img.astype('float32')
    # 将数据范围调整到[-1.0, 1.0]之间
    img = img / 255.
    img = img * 2.0 - 1.0
    return img


# 定义训练集数据读取器
def data_loader(datadir, batch_size=10, mode='train'):
    # 将datadir目录下的文件列出来，每条文件都要读入
    filenames = os.listdir(datadir)

    def reader():
        if mode == 'train':
            # 训练时随机打乱数据顺序
            random.shuffle(filenames)
        batch_imgs = []
        batch_labels = []

        for name in filenames:
            img_path = os.path.join(datadir, name)
            img = cv2.imread(img_path)
            img = transform_img(img)
            if name[0] == 'H' or name[0] == 'N':
                # H开头的文件名表示高度近视，N开头的文件名表示正常视力
                # 高度近视和正常视力的样本，都不是病理性的，属于负样本，标签为0
                label = 0
            elif name[0] == 'P':
                label = 1
            else:
                raise ('NOT EXCEPTED FILE NAME')
            # 每读取一个样本的数据，就将其放入数据列表中
            batch_imgs.append(img)
            batch_labels.append(label)
            if len(batch_imgs) == batch_size:
                # 当数据列表的长度等于batch_size的时候，
                # 把这些数据当作一个mini-batch，并作为数据生成器的一个输出
                imgs_array = np.array(batch_imgs).astype('float32')
                labels_array = np.array(batch_labels).astype('float32').reshape(-1, 1)
                yield imgs_array, labels_array
                batch_imgs = []
                batch_labels = []

        if len(batch_imgs) > 0:
            # 剩余样本数不足一个batch_size的数据，一起打包成一个mini-batch
            imgs_array = np.array(batch_imgs).astype('float32')
            labels_array = np.array(batch_labels).astype('float32').reshape(-1, 1)
            yield imgs_array, labels_array

    return reader


# 定义训练过程
def train_pm(model, optimizer):
    use_gpu = True
    paddle.device.set_device('gpu:0') if use_gpu else paddle.device.set_device('cpu')

    print('start training ... ')
    # 定义数据读取器，训练数据读取器和验证数据读取器
    train_loader = data_loader(DATADIR, batch_size=10, mode='train')
    for epoch in range(EPOCH_NUM):
        model.train()
        for batch_id, data in enumerate(train_loader()):
            x_data, y_data = data
            imgs = paddle.to_tensor(x_data)
            labels = paddle.to_tensor(y_data)
            # 运行模型前向计算，得到预测值
            predicts = model(imgs)
            loss = paddle.nn.functional.binary_cross_entropy_with_logits(predicts, labels)
            avg_loss = paddle.mean(loss)

            if batch_id % 20 == 0:
                print('epoch: {}, batch_id: {}, loss is: {:.4f}'.format(epoch, batch_id, float(avg_loss.numpy())))
            avg_loss.backward()
            optimizer.step()
            optimizer.clear_grad()

        # 计算准确率
        model.eval()
        accuracies = []
        losses = []
        eval_loader = data_loader(DATADIR, batch_size=10, mode='eval')
        for batch_id, data in enumerate(eval_loader()):
            x_data, y_data = data
            imgs = paddle.to_tensor(x_data)
            labels = paddle.to_tensor(y_data)
            # 进行模型前向计算，得到预测值
            logits = model(imgs)
            # 计算sigmoid后的预测概率，进行loss计算
            loss = paddle.nn.functional.binary_cross_entropy_with_logits(logits, labels)
            # 二分类，sigmoid计算后的结果以0.5为阈值分两个类别
            predicts2 = paddle.nn.functional.sigmoid(logits)
            predicts3 = predicts2 * (-1.0) + 1.0
            pred = paddle.concat([predicts2, predicts3], axis=1)
            acc = paddle.metric.accuracy(pred, paddle.cast(labels, dtype='int64'))

            accuracies.append(acc.numpy())
            losses.append(loss.numpy())
        print('[validation] accuracy/loss: {:.4f}/{:.4f}'.format(np.mean(accuracies), np.mean(losses)))

        paddle.save(model.state_dict(), '../output/pathologic_myopia/lenet/palm.pdparams')
        paddle.save(optimizer.state_dict(), '../output/pathologic_myopia/lenet/palm.pdopt')


# 定义评估过程
def evaluation(model, params_file_path):
    # 开启0号GPU预估
    use_gpu = True
    paddle.device.set_device('gpu:0') if use_gpu else paddle.device.set_device('cpu')

    print('start evaluation ......')

    # 加载参数模型
    model_state_dict = paddle.load(params_file_path)
    model.load_dict(model_state_dict)

    # 开启评估
    model.eval()
    eval_loader = data_loader(DATADIR, batch_size=10, mode='eval')

    acc_set = []
    avg_loss_set = []
    for batch_id, data in enumerate(eval_loader()):
        x_data, y_data = data
        img = paddle.to_tensor(x_data)
        label = paddle.to_tensor(y_data)
        label_64 = paddle.to_tensor(y_data.astype(np.int64))
        # 计算预测和精度(label_64作用???)
        prediction, acc = model(img, label_64)
        # 计算损失函数值
        loss = paddle.nn.functional.binary_cross_entropy_with_logits(prediction, label)
        avg_loss = paddle.mean(loss)
        acc_set.append(float(acc.numpy()))
        avg_loss_set.append(float(avg_loss.numpy()))

    # 求平均精度
    acc_val_mean = np.array(acc_set).mean()
    avg_loss_val_mean = np.array(avg_loss_set).mean()

    print('loss={:.4f}, acc={:.4f}'.format(avg_loss_val_mean, acc_val_mean))


# 定义模型
class MyLeNet(paddle.nn.Layer):
    def __init__(self, num_classes=1):
        super(MyLeNet, self).__init__()

        # 创建卷积和池化层块，每个卷积层使用Sigmoid激活函数，后面跟着一个2x2池化层
        self.conv1 = paddle.nn.Conv2D(in_channels=3, out_channels=6, kernel_size=5)
        self.max_pool1 = paddle.nn.MaxPool2D(kernel_size=2, stride=2)
        self.conv2 = paddle.nn.Conv2D(in_channels=6, out_channels=16, kernel_size=5)
        self.max_pool2 = paddle.nn.MaxPool2D(kernel_size=2, stride=2)
        # 创建第三个卷积层
        self.conv3 = paddle.nn.Conv2D(in_channels=16, out_channels=120, kernel_size=4)
        # 创建全连接层，第一个全连接层的输出神经元个数为64
        features_num = pow(((224 - 4) // 2 - 4) // 2 - 3, 2) * 120
        self.fc1 = paddle.nn.Linear(in_features=features_num, out_features=64)
        self.fc2 = paddle.nn.Linear(in_features=64, out_features=num_classes)

    # 网络前向计算过程
    def forward(self, x, label=None):
        x = self.conv1(x)
        x = paddle.nn.functional.sigmoid(x)
        x = self.max_pool1(x)
        x = self.conv2(x)
        x = paddle.nn.functional.sigmoid(x)
        x = self.max_pool2(x)
        x = self.conv3(x)
        x = paddle.nn.functional.sigmoid(x)
        x = paddle.reshape(x, [x.shape[0], -1])
        x = self.fc1(x)
        x = paddle.nn.functional.sigmoid(x)
        x = self.fc2(x)
        # 如果输入了Label，那么计算acc
        if label is not None:
            acc = paddle.metric.accuracy(input=x, label=label)
            return x, acc
        else:
            return x


# 查看数据形状
DATADIR = '../dataset/pathologic_myopia'
# 设置迭代轮数
EPOCH_NUM = 5
# 创建模型
model = MyLeNet(num_classes=1)
# 启动训练过程
opt = paddle.optimizer.Momentum(learning_rate=0.001, momentum=0.9, parameters=model.parameters())
train_pm(model=model, optimizer=opt)
evaluation(model, params_file_path='../output/pathologic_myopia/lenet/palm.pdparams')


# 打印结果
W1206 14:31:11.494339 42040 gpu_resources.cc:61] Please NOTE: device: 0, GPU Compute Capability: 6.1, Driver API Version: 11.7, Runtime API Version: 11.6
W1206 14:31:11.496333 42040 gpu_resources.cc:91] device: 0, cuDNN Version: 8.4.
start training ... 
epoch: 0, batch_id: 0, loss is: 0.7955
epoch: 0, batch_id: 20, loss is: 0.6390
[validation] accuracy/loss: 0.5325/0.6913
epoch: 1, batch_id: 0, loss is: 0.6940
epoch: 1, batch_id: 20, loss is: 0.6598
[validation] accuracy/loss: 0.5325/0.6912
epoch: 2, batch_id: 0, loss is: 0.6852
epoch: 2, batch_id: 20, loss is: 0.6860
[validation] accuracy/loss: 0.5325/0.6915
epoch: 3, batch_id: 0, loss is: 0.6784
epoch: 3, batch_id: 20, loss is: 0.6789
[validation] accuracy/loss: 0.5325/0.6911
epoch: 4, batch_id: 0, loss is: 0.6837
epoch: 4, batch_id: 20, loss is: 0.6994
[validation] accuracy/loss: 0.5325/0.6911
start evaluation ......
loss=0.6911, acc=0.4675
```
可见改模型的准确率并不高

以下分别对 **AlexNet/GoogLeNet/残差块** 网络进行测试

使用 AlexNet 网络进行测试
```
# 优化模型
class MyAlexNet(paddle.nn.Layer):
    def __init__(self, num_classes=1):
        super(MyAlexNet, self).__init__()
        self.conv1 = paddle.nn.Conv2D(in_channels=3, out_channels=96, kernel_size=11, stride=4, padding=5)
        self.max_pool1 = paddle.nn.MaxPool2D(kernel_size=2, stride=2)
        self.conv2 = paddle.nn.Conv2D(in_channels=96, out_channels=256, kernel_size=5, stride=1, padding=2)
        self.max_pool2 = paddle.nn.MaxPool2D(kernel_size=2, stride=2)
        self.conv3 = paddle.nn.Conv2D(in_channels=256, out_channels=384, kernel_size=3, stride=1, padding=1)
        self.conv4 = paddle.nn.Conv2D(in_channels=384, out_channels=384, kernel_size=3, stride=1, padding=1)
        self.conv5 = paddle.nn.Conv2D(in_channels=384, out_channels=256, kernel_size=3, stride=1, padding=1)
        self.max_pool5 = paddle.nn.MaxPool2D(kernel_size=2, stride=2)

        self.fc1 = paddle.nn.Linear(in_features=12544, out_features=4096)
        self.drop_ratio1 = 0.5
        self.drop1 = paddle.nn.Dropout(self.drop_ratio1)
        self.fc2 = paddle.nn.Linear(in_features=4096, out_features=4096)
        self.drop_ratio2 = 0.5
        self.drop2 = paddle.nn.Dropout(self.drop_ratio2)
        self.fc3 = paddle.nn.Linear(in_features=4096, out_features=num_classes)

    def forward(self, x, label=None):
        x = self.conv1(x)
        x = paddle.nn.functional.relu(x)
        x = self.max_pool1(x)
        x = self.conv2(x)
        x = paddle.nn.functional.relu(x)
        x = self.max_pool2(x)
        x = self.conv3(x)
        x = paddle.nn.functional.relu(x)
        x = self.conv4(x)
        x = paddle.nn.functional.relu(x)
        x = self.conv5(x)
        x = paddle.nn.functional.relu(x)
        x = self.max_pool5(x)
        # 全连接层
        x = paddle.reshape(x, [x.shape[0], -1])
        x = self.fc1(x)
        x = paddle.nn.functional.relu(x)
        # 在全连接之后使用dropout抑制过拟合
        x = self.drop1(x)
        x = self.fc2(x)
        x = paddle.nn.functional.relu(x)
        x = self.drop2(x)
        x = self.fc3(x)

        # 如果输入了Label，那么计算acc
        if label is not None:
            acc = paddle.metric.accuracy(input=x, label=label)
            return x, acc
        else:
            return x

# 打印结果
W1206 17:07:48.886270 34060 gpu_resources.cc:61] Please NOTE: device: 0, GPU Compute Capability: 6.1, Driver API Version: 11.7, Runtime API Version: 11.6
W1206 17:07:48.889235 34060 gpu_resources.cc:91] device: 0, cuDNN Version: 8.4.
start training ... 
epoch: 0, batch_id: 0, loss is: 0.7389
epoch: 0, batch_id: 20, loss is: 0.4360
[validation] accuracy/loss: 0.8875/0.3465
epoch: 1, batch_id: 0, loss is: 0.4918
epoch: 1, batch_id: 20, loss is: 0.1599
[validation] accuracy/loss: 0.9100/0.2533
epoch: 2, batch_id: 0, loss is: 0.1056
epoch: 2, batch_id: 20, loss is: 0.0493
[validation] accuracy/loss: 0.8950/0.2766
epoch: 3, batch_id: 0, loss is: 0.1250
epoch: 3, batch_id: 20, loss is: 0.0829
[validation] accuracy/loss: 0.9300/0.1978
epoch: 4, batch_id: 0, loss is: 0.1520
epoch: 4, batch_id: 20, loss is: 0.3377
[validation] accuracy/loss: 0.9300/0.1779
start evaluation ......
loss=0.1779, acc=0.4675
```

使用 vgg模型 进行测试
```
# 优化模型
class VGG(paddle.nn.Layer):
    def __init__(self, num_classes=None):
        super(VGG, self).__init__()

        in_channels = [3, 64, 128, 256, 512, 512]
        # 定义第一个block，包含两个卷积
        self.conv1_1 = paddle.nn.Conv2D(in_channels=in_channels[0], out_channels=in_channels[1], kernel_size=3,
                                        padding=1, stride=1)
        self.conv1_2 = paddle.nn.Conv2D(in_channels=in_channels[1], out_channels=in_channels[1], kernel_size=3,
                                        padding=1, stride=1)
        # 定义第二个block，包含两个卷积
        self.conv2_1 = paddle.nn.Conv2D(in_channels=in_channels[1], out_channels=in_channels[2], kernel_size=3,
                                        padding=1, stride=1)
        self.conv2_2 = paddle.nn.Conv2D(in_channels=in_channels[2], out_channels=in_channels[2], kernel_size=3,
                                        padding=1, stride=1)
        # 定义第三个block，包含三个卷积
        self.conv3_1 = paddle.nn.Conv2D(in_channels=in_channels[2], out_channels=in_channels[3], kernel_size=3,
                                        padding=1, stride=1)
        self.conv3_2 = paddle.nn.Conv2D(in_channels=in_channels[3], out_channels=in_channels[3], kernel_size=3,
                                        padding=1, stride=1)
        self.conv3_3 = paddle.nn.Conv2D(in_channels=in_channels[3], out_channels=in_channels[3], kernel_size=3,
                                        padding=1, stride=1)
        # 定义第四个block，包含三个卷积
        self.conv4_1 = paddle.nn.Conv2D(in_channels=in_channels[3], out_channels=in_channels[4], kernel_size=3,
                                        padding=1, stride=1)
        self.conv4_2 = paddle.nn.Conv2D(in_channels=in_channels[4], out_channels=in_channels[4], kernel_size=3,
                                        padding=1, stride=1)
        self.conv4_3 = paddle.nn.Conv2D(in_channels=in_channels[4], out_channels=in_channels[4], kernel_size=3,
                                        padding=1, stride=1)
        # 定义第五个block，包含三个卷积
        self.conv5_1 = paddle.nn.Conv2D(in_channels=in_channels[4], out_channels=in_channels[5], kernel_size=3,
                                        padding=1, stride=1)
        self.conv5_2 = paddle.nn.Conv2D(in_channels=in_channels[5], out_channels=in_channels[5], kernel_size=3,
                                        padding=1, stride=1)
        self.conv5_3 = paddle.nn.Conv2D(in_channels=in_channels[5], out_channels=in_channels[5], kernel_size=3,
                                        padding=1, stride=1)

        # 使用Sequential 将全连接层和relu组成一个线性结构 (fc + relu)
        # 当输入为244x244时，经过五个卷积块和池化层后，特征维度变为[512x7x7]
        self.fc1 = paddle.nn.Sequential(paddle.nn.Linear(512 * 7 * 7, 4096), paddle.nn.ReLU())
        self.drop1_ratio = 0.5
        self.dropout1 = paddle.nn.Dropout(self.drop1_ratio, mode='upscale_in_train')
        # 使用Sequential将全连接层和relu组成一个线性结构(fc + relu)
        self.fc2 = paddle.nn.Sequential(paddle.nn.Linear(4096, 4096), paddle.nn.ReLU())
        self.drop2_ratio = 0.5
        self.dropout2 = paddle.nn.Dropout(self.drop2_ratio, mode='upscale_in_train')
        self.fc3 = paddle.nn.Linear(4096, 1)

        self.relu = paddle.nn.ReLU()
        self.pool = paddle.nn.MaxPool2D(stride=2, kernel_size=2)

    def forward(self, x, label=None):
        x = self.relu(self.conv1_1(x))
        x = self.relu(self.conv1_2(x))
        x = self.pool(x)

        x = self.relu(self.conv2_1(x))
        x = self.relu(self.conv2_2(x))
        x = self.pool(x)

        x = self.relu(self.conv3_1(x))
        x = self.relu(self.conv3_2(x))
        x = self.relu(self.conv3_3(x))
        x = self.pool(x)

        x = self.relu(self.conv4_1(x))
        x = self.relu(self.conv4_2(x))
        x = self.relu(self.conv4_3(x))
        x = self.pool(x)

        x = self.relu(self.conv5_1(x))
        x = self.relu(self.conv5_2(x))
        x = self.relu(self.conv5_3(x))
        x = self.pool(x)

        x = paddle.flatten(x, 1, -1)
        x = self.dropout1(self.relu(self.fc1(x)))
        x = self.dropout2(self.relu(self.fc2(x)))
        x = self.fc3(x)

        # 如果输入了Label，那么计算acc
        if label is not None:
            acc = paddle.metric.accuracy(input=x, label=label)
            return x, acc
        else:
            return x

# 打印结果为
W1206 17:31:48.611086 37108 gpu_resources.cc:61] Please NOTE: device: 0, GPU Compute Capability: 6.1, Driver API Version: 11.7, Runtime API Version: 11.6
W1206 17:31:48.650003 37108 gpu_resources.cc:91] device: 0, cuDNN Version: 8.4.
start training ... 
epoch: 0, batch_id: 0, loss is: 0.8150
epoch: 0, batch_id: 20, loss is: 0.8149
[validation] accuracy/loss: 0.8775/0.3243
epoch: 1, batch_id: 0, loss is: 0.1642
epoch: 1, batch_id: 20, loss is: 0.2195
[validation] accuracy/loss: 0.9000/0.2934
epoch: 2, batch_id: 0, loss is: 0.2956
epoch: 2, batch_id: 20, loss is: 0.8894
[validation] accuracy/loss: 0.8975/0.2357
epoch: 3, batch_id: 0, loss is: 0.3631
epoch: 3, batch_id: 20, loss is: 0.1797
[validation] accuracy/loss: 0.9125/0.2169
epoch: 4, batch_id: 0, loss is: 0.5968
epoch: 4, batch_id: 20, loss is: 0.0280
[validation] accuracy/loss: 0.9200/0.1935
start evaluation ......
loss=0.1935, acc=0.4675
```

使用 GoogLeNet模型 测试
```
# 优化模型
# 定义Inception块
class Inception(paddle.nn.Layer):
    def __init__(self, c0, c1, c2, c3, c4, **kwargs):
        '''
        Inception模块的实现代码
        :param c0:
        :param c1:图(b)中第一条支路1x1卷积的输出通道数,数据类型是整数
        :param c2:图(b)中第二条支路卷积的输出通道数,数据类型是tuple或list,其中c2[0]是1x1卷积的输出通道数,c2[1]是3x3
        :param c3:图(b)中第三条支路卷积的输出通道数,数据类型是tuple或list,其中c3[0]是1x1卷积的输出通道数,c3[1]是3x3
        :param c4:图(b)中第一条支路1x1卷积的输出通道数,数据类型是整数
        :param kwargs:
        '''
        super(Inception, self).__init__()
        # 依次创建Inception块每条支路上使用到的操作
        self.p1_1 = paddle.nn.Conv2D(in_channels=c0, out_channels=c1, kernel_size=1, stride=1)

        self.p2_1 = paddle.nn.Conv2D(in_channels=c0, out_channels=c2[0], kernel_size=1, stride=1)
        self.p2_2 = paddle.nn.Conv2D(in_channels=c2[0], out_channels=c2[1], kernel_size=3, padding=1, stride=1)

        self.p3_1 = paddle.nn.Conv2D(in_channels=c0, out_channels=c3[0], kernel_size=1, stride=1)
        self.p3_2 = paddle.nn.Conv2D(in_channels=c3[0], out_channels=c3[1], kernel_size=5, padding=2, stride=1)

        self.p4_1 = paddle.nn.MaxPool2D(kernel_size=3, stride=1, padding=1)
        self.p4_2 = paddle.nn.Conv2D(in_channels=c0, out_channels=c4, kernel_size=1, stride=1)

        # # 新加一层batchnorm稳定收敛
        # self.batchnorm = paddle.nn.BatchNorm2D(c1+c2[1]+c3[1]+c4)

    def forward(self, x):
        # 支路1只包含一个 1x1卷积
        p1 = paddle.nn.functional.relu(self.p1_1(x))
        # 支路2包含 1x1卷积 + 3x3卷积
        p2 = paddle.nn.functional.relu(self.p2_2(paddle.nn.functional.relu(self.p2_1(x))))
        # 支路3包含 1x1卷积 + 5x5卷积
        p3 = paddle.nn.functional.relu(self.p3_2(paddle.nn.functional.relu(self.p3_1(x))))
        # 支路4包含 最大池化 + 1x1卷积
        p4 = paddle.nn.functional.relu(self.p4_2(paddle.nn.functional.relu(self.p4_1(x))))
        # 将每个支路的输出特征图拼接在一起作为最终的输出结果
        return paddle.concat([p1, p2, p3, p4], axis=1)
        # return self.batchnorm()


class GoogleNet(paddle.nn.Layer):
    def __init__(self, num_classes=None):
        super(GoogleNet, self).__init__()
        # GoogleLeNet包含5个模块，每个模块后面紧跟一个池化层
        # 第一个模块包含1个卷积层
        self.conv1 = paddle.nn.Conv2D(in_channels=3, out_channels=64, kernel_size=7, padding=3, stride=1)
        # 3x3最大池化
        self.max_pool1 = paddle.nn.MaxPool2D(kernel_size=3, stride=2, padding=1)
        # 第二个模块包含2个卷积层
        self.conv2_1 = paddle.nn.Conv2D(in_channels=64, out_channels=64, kernel_size=1, stride=1)
        self.conv2_2 = paddle.nn.Conv2D(in_channels=64, out_channels=192, kernel_size=3, padding=1, stride=1)
        # 3x3最大池化
        self.max_pool2 = paddle.nn.MaxPool2D(kernel_size=3, stride=2, padding=1)
        # 第三个模块包含2个Inception块
        self.block3_1 = Inception(192, 64, (96, 128), (16, 32), 32)
        self.block3_2 = Inception(256, 128, (128, 192), (32, 96), 64)
        # 3x3最大池化
        self.max_pool3 = paddle.nn.MaxPool2D(kernel_size=3, stride=2, padding=1)
        # 第四个模块包含5个Inception块
        self.block4_1 = Inception(480, 192, (96, 208), (16, 48), 64)
        self.block4_2 = Inception(512, 160, (112, 224), (24, 64), 64)
        self.block4_3 = Inception(512, 128, (128, 256), (24, 64), 64)
        self.block4_4 = Inception(512, 112, (144, 288), (32, 64), 64)
        self.block4_5 = Inception(528, 256, (160, 320), (32, 128), 128)
        # 3x3 最大池化
        self.max_pool4 = paddle.nn.MaxPool2D(kernel_size=3, stride=2, padding=1)
        # 第五个模块包含2个Inception块
        self.block5_1 = Inception(832, 256, (160, 320), (32, 128), 128)
        self.block5_2 = Inception(832, 384, (192, 384), (48, 128), 128)
        # 全局池化，用的是global_pooling，不需要pool_stride
        self.pool5 = paddle.nn.AdaptiveAvgPool2D(output_size=1)
        self.fc = paddle.nn.Linear(in_features=1024, out_features=1)

    def forward(self, x, label=None):
        x = self.max_pool1(paddle.nn.functional.relu(self.conv1(x)))
        x = self.max_pool2(paddle.nn.functional.relu(self.conv2_2(paddle.nn.functional.relu(self.conv2_1(x)))))
        x = self.max_pool3(self.block3_2(self.block3_1(x)))
        x = self.block4_3(self.block4_2(self.block4_1(x)))
        x = self.max_pool4(self.block4_5(self.block4_4(x)))
        x = self.pool5(self.block5_2(self.block5_1(x)))
        x = paddle.reshape(x, [x.shape[0], -1])
        x = self.fc(x)

        # 如果输入了Label，那么计算acc
        if label is not None:
            acc = paddle.metric.accuracy(input=x, label=label)
            return x, acc
        else:
            return x

# 打印结果为
W1206 19:02:25.166755 16624 gpu_resources.cc:61] Please NOTE: device: 0, GPU Compute Capability: 6.1, Driver API Version: 11.7, Runtime API Version: 11.6
W1206 19:02:25.169747 16624 gpu_resources.cc:91] device: 0, cuDNN Version: 8.4.
start training ... 
epoch: 0, batch_id: 0, loss is: 1.1343
epoch: 0, batch_id: 20, loss is: 0.6439
[validation] accuracy/loss: 0.5325/0.6300
epoch: 1, batch_id: 0, loss is: 0.5812
epoch: 1, batch_id: 20, loss is: 0.5121
[validation] accuracy/loss: 0.8350/0.5007
epoch: 2, batch_id: 0, loss is: 0.5198
epoch: 2, batch_id: 20, loss is: 0.5148
[validation] accuracy/loss: 0.8975/0.4222
epoch: 3, batch_id: 0, loss is: 0.4430
epoch: 3, batch_id: 20, loss is: 0.3156
[validation] accuracy/loss: 0.9200/0.2925
epoch: 4, batch_id: 0, loss is: 0.2119
epoch: 4, batch_id: 20, loss is: 0.6766
[validation] accuracy/loss: 0.9300/0.2280
start evaluation ......
loss=0.2280, acc=0.4675
```

使用 残差块网络 进行测试
```
# ResNet中使用了BatchNorm层，在卷积层的后面加上BatchNorm以提升数值稳定性
# 定义卷积批归一体化
class ConvBNLayer(paddle.nn.Layer):
    def __init__(self, num_channels, num_filters, filter_size, stride=1, groups=1, act=None):
        '''
        :param num_channels:卷积层的输入通道数
        :param num_filters: 卷积层的输出通道数
        :param filter_size:
        :param stride: 卷积层的步幅
        :param groups: 分组卷积的数组，默认groups=1不使用分组卷积
        :param act:
        '''
        super(ConvBNLayer, self).__init__()

        # 创建卷积层
        self._conv = paddle.nn.Conv2D(in_channels=num_channels, out_channels=num_filters, kernel_size=filter_size,
                                      stride=stride, padding=(filter_size - 1) // 2, groups=groups, bias_attr=False)

        # 创建BatchNorm层
        self._batch_norm = paddle.nn.BatchNorm2D(num_filters)

        self.act = act

    def forward(self, inputs):
        y = self._conv(inputs)
        y = self._batch_norm(y)
        if self.act == 'leaky':
            y = paddle.nn.functional.leaky_relu(x=y, negative_slope=0.1)
        elif self.act == 'relu':
            y = paddle.nn.functional.relu(x=y)

        return y


# 定义残差块
# 每个残差块会对输入图片做三次卷积，然后跟输入图片进行短接
# 如果残差块中第三次卷积输出特征图的形状与输入不一致，则对输入图片做1x1卷积，将其输出形状调整成一致
class BottleneckBlock(paddle.nn.Layer):
    def __init__(self, num_channels, num_filters, stride, shortcut=True):
        super(BottleneckBlock, self).__init__()
        # 创建第一个卷积层 1x1
        self.conv0 = ConvBNLayer(num_channels=num_channels, num_filters=num_filters, filter_size=1, act='relu')
        # 创建第二个卷积层 3x3
        self.conv1 = ConvBNLayer(num_channels=num_filters, num_filters=num_filters, filter_size=3, stride=stride,
                                 act='relu')
        # 创建第三个卷积1x1，但是输出通道数乘以4
        self.conv2 = ConvBNLayer(num_channels=num_filters, num_filters=num_filters * 4, filter_size=1, act=None)

        # 如果conv2的输出跟此残差块的输入数据形状一致，则shortcut=True
        # 否则shortcut = False，添加1x1的卷积作用在输入数据上，使其形状变成跟conv2一致
        if not shortcut:
            self.short = ConvBNLayer(num_channels=num_channels, num_filters=num_filters * 4, filter_size=1,
                                     stride=stride)

        self.shortcut = shortcut
        self._num_channels_out = num_filters * 4

    def forward(self, inputs):
        y = self.conv0(inputs)
        conv1 = self.conv1(y)
        conv2 = self.conv2(conv1)

        # 如果shortcut=True，直接将inputs跟conv2的输出相加
        # 否则需要对inputs进行一次卷积，将形状调整成跟conv2输出一致
        if self.shortcut:
            short = inputs
        else:
            short = self.short(inputs)

        y = paddle.add(x=short, y=conv2)
        y = paddle.nn.functional.relu(y)

        return y


# 定义ResNet模型
class ResNet(paddle.nn.Layer):
    def __init__(self, layers=50, class_dim=1):
        '''

        :param layers:网络层数，可以是50,101或者152
        :param class_dim: 分类标签的类别数
        '''
        super(ResNet, self).__init__()
        self.layers = layers
        supported_layers = [50, 101, 152]
        assert layers in supported_layers, 'supporrted layers are {} but input layer is {}'.format(supported_layers,
                                                                                                   layers)

        if layers == 50:
            # ResNet50包含多个模块，其中第2到第5个模块分别包含3、4、6、3个残差块
            depth = [3, 4, 6, 3]
        elif layers == 101:
            # ResNet101包含多个模块，其中第2到第5个模块分别包含3、4、23、3个残差块
            depth = [3, 4, 23, 3]
        elif layers == 152:
            # ResNET152包含多个模块，其中第2到第5个模块分别包含3、8、36、3
            depth = [3, 8, 36, 3]

        # 残差块中使用到的卷积的输出通道
        num_filters = [64, 128, 256, 512]

        # ResNet的第一个模块，包含1个7x7卷积，后面跟着1个最大池化层
        self.conv = ConvBNLayer(num_channels=3, num_filters=64, filter_size=7, stride=2, act='relu')
        self.max_pool = paddle.nn.MaxPool2D(kernel_size=3, stride=2, padding=1)

        # ResNet的第二个到第五个模块c2、c3、c4、c5
        self.bottleneck_block_list = []
        num_channels = 64
        for block in range(len(depth)):
            shortcut = False
            for i in range(depth[block]):
                bottleneck_block = self.add_sublayer(
                    'bb_%d_%d' % (block, i),
                    BottleneckBlock(num_channels=num_channels,
                                    num_filters=num_filters[
                                        block],
                                    stride=2 if i == 0 and block != 0 else 1,
                                    shortcut=shortcut)
                )
                num_channels = bottleneck_block._num_channels_out
                self.bottleneck_block_list.append(bottleneck_block)
                shortcut = True

        # 在c5的输出特征图上使用全局池化
        self.pool2d_avg = paddle.nn.AdaptiveAvgPool2D(output_size=1)

        # stdv用来作为全连接层随机初始化参数的方差
        import math
        stdv = 1.0 / math.sqrt(2048 * 1.0)

        # 创建全连接层，输出大小为类别数目，经过残差网络的卷积和全局池化后，卷积特征的维度是[B, 2048, 1, 1]，故最后一层全连接的输入维度是2048
        self.out = paddle.nn.Linear(in_features=2048,
                                    out_features=class_dim,
                                    weight_attr=paddle.ParamAttr(
                                        initializer=paddle.nn.initializer.Uniform(-stdv, stdv))
                                    )

    def forward(self, inputs, label=None):
        y = self.conv(inputs)
        y = self.max_pool(y)
        for bottleneck_block in self.bottleneck_block_list:
            y = bottleneck_block(y)
        y = self.pool2d_avg(y)
        y = paddle.reshape(y, [y.shape[0], -1])
        y = self.out(y)

        # 如果输入了Label，那么计算acc
        if label is not None:
            acc = paddle.metric.accuracy(input=inputs, label=label)
            return y, acc
        else:
            return y

# 打印结果为
W1206 19:58:02.451362 12844 gpu_resources.cc:61] Please NOTE: device: 0, GPU Compute Capability: 6.1, Driver API Version: 11.7, Runtime API Version: 11.6
W1206 19:58:02.453357 12844 gpu_resources.cc:91] device: 0, cuDNN Version: 8.4.
start training ... 
F:\miniconda3nvs\paddle23\lib\site-packages\paddle
n\layer
orm.py:654: UserWarning: When training, we now always track global mean and variance.
  "When training, we now always track global mean and variance.")
epoch: 0, batch_id: 0, loss is: 0.6839
epoch: 0, batch_id: 20, loss is: 0.9671
[validation] accuracy/loss: 0.5575/1.0465
epoch: 1, batch_id: 0, loss is: 0.5888
epoch: 1, batch_id: 20, loss is: 0.3879
[validation] accuracy/loss: 0.6675/0.8323
epoch: 2, batch_id: 0, loss is: 1.0331
epoch: 2, batch_id: 20, loss is: 0.1507
[validation] accuracy/loss: 0.9125/0.3006
epoch: 3, batch_id: 0, loss is: 0.7395
epoch: 3, batch_id: 20, loss is: 0.1936
[validation] accuracy/loss: 0.9200/0.2864
epoch: 4, batch_id: 0, loss is: 0.0622
epoch: 4, batch_id: 20, loss is: 0.1062
[validation] accuracy/loss: 0.8925/0.2969
start evaluation ......
loss=0.2969, acc=0.0000
```

也可以直接通过`from paddle.vision.models import resnet50, vgg16, LeNet`来使用封装好的网络模型
```
from paddle.vision.models import resnet50, vgg16, LeNet
......
model = resnet50(pretrained=False, num_classes=1)
```

<br>
## 2.5 PCB电路板缺陷检测(PaddleDetection)
使用PaddlePaddle的[PaddleDetection](https://github.com/PaddlePaddle/PaddleDetection)来完成。
需要下载项目中。

**安装PaddleDection开发套件**
下载PaddleDection包，下载requirement中的模块 `pip install -r .equirements.txt`
>如果cython_bbox安装失败，使用如下命令安装
`python -m pip install git+https://github.com/yanfengliu/cython_bbox.git`

在项目目录下创建work目录，放置开发脚本。

<br>
**数据集中的json文件标签含义**
COCO数据集标注中的annotation标签各个属性含义
```
{
    "area":4012,
    "iscrowd":0,
    "bbox":[492, 500, 59, 68],
    "category_id":3,
    "ignore":0,
    "segmentation":[],
    "image_id":0,
    "id":1
}
```
>id字段：指的是这个annotation的一个id
>image_id：等同于前面image字段里面的id。
>category_id：类别id
>segmentation：
>area：标注区域面积
>bbox：标注框，依次为标注框左上角横纵坐标，宽和高 (即492和500为标注框的左上角坐标，59是width，68是height)
>iscrowd：决定是RLE格式还是polygon格式。

首先需要检查样本信息，包括 ①样本中标注的种类数量是否相近 ②锚框宽高比 ③锚框占整个图片的比例
```
import json
import collections
from matplotlib import pyplot as plt

'''
首先需要检查样本信息，包括 ①样本中标注的种类数量是否相近 ②锚框宽高比 ③锚框占整个图片的比例
'''

# 加载解析json文件
with open('./PCB_DATASET/Annotations/train.json') as f:
    data = json.load(f)

# 保存图片信息
imgs = {}
for img in data['images']:
    imgs[img['id']] = {
        'height': img['height'],
        'width': img['width'],
        'area': img['height'] * img['width']
    }

# 计算标注信息
hw_ratios = []
area_ratios = []
cate_count = collections.defaultdict(int)
for anno in data['annotations']:
    hw_ratios.append(anno['bbox'][3] / anno['bbox'][2])
    area_ratios.append(anno['area'] / imgs[anno['image_id']]['area'])
    cate_count[anno['category_id']] += 1

print(cate_count, len(data['annotations'])/len(data['images']))

plt.hist(hw_ratios, bins=100, range=[0, 2])
plt.show()

plt.hist(area_ratios, bins=100, range=[0, 0.005])
plt.show()
```
编辑配置文件
```
metric: COCO    # Label评价指标，coco IoU:0.5:0.95
num_classes: 7  # 类别数量：coco类别比实际类别(voc类别) +1

# 数据集的位置等信息
TrainDataset:
  !COCODataSet
    image_dir: images
    anno_path: Annotations/train.json
    dataset_dir: D:\ML\Dataset\PCB_DATASET
    data_fields: ['image','gt_bbox','gt_class'] # '输入图片，得到输出框和类别'

EvalDataset:
  !COCODataSet
    image_dir: images
    anno_path: Annotations/val.json
    dataset_dir: D:\ML\Dataset\PCB_DATASET

TestDataset:
  !ImageFolder
    anno_path: Annotations/val.json


use_gpu: False        # 是否开启GPU
log_iter: 10          # 日志窗口的尺度
save_dir: output/     # 输出结果罗盘位置
snapshot_epoch: 1     # 生成快照的频率，即每1个周期生成一次

epoch: 24             ### 训练周期：24

LearningRate:         ### 学习率：阶段学习
  base_lr: 0.0025     # 起始学习率：0.0025
  schedulers:
  - !PiecewiseDecay   ## 阶段学习率
    gamma: 0.1        # 每次学习率变化为原来的1/10
    milestones: [16, 22] # 总共进行两次学习率的降低，分别在第16轮和22轮开始时
  - !LinearWarmup     ## 慢启动，共执行200次迭代，学习率为初始学习率的0.1
    start_factor: 0.1
    steps: 200

OptimizerBuilder:     ### 定义优化器
  optimizer:          ## 基于动量的SGD优化器
    momentum: 0.9
    type: Momentum
  regularizer:        ## 定义正则项
    factor: 0.0001
    type: L2

architecture: FasterRCNN  # 总框架类型

# 预训练模型：基于已有的模型进行训练
# pretrain_weights: https://paddledet.bj.bcebos.com/models/pretrained/ResNet50_cos_pretrained.pdparams
pretrain_weights: D:\ML\Project\PaddleDetection-release-2.3\work\output\Resnet50_cos_pretrained.pdparams

## 检测模型的体系结构，包含骨干、支路、区域建设、BBox头和BBox后处理
FasterRCNN:
  backbone: ResNet          # 主干网络：ResNet
  neck: FPN                 # 特征融合：特征金字塔网络
  rpn_head: RPNHead         # 区域建议头：基于FPN的RPNHead
  bbox_head: BBoxHead       # BBox头：BBoxHead
  # post process
  bbox_post_process: BBoxPostProcess  # BBox后处理器

## 对定义的RestNet进行详细描述
ResNet:
  depth: 50                 # 深度50，即ResNet50
  norm_type: bn             # 正则化类BN，基本上是唯一选择
  freeze_at: 0              # 冻结部分，ResNet的前两层，不调整参数
  return_idx: [0,1,2,3]     # 提取特征的位置，即用于FPN的特征，其实index为0
  num_stages: 4             # 总共4个阶段

## 对定义的FPN进行详细描述
FPN:
  out_channel: 256          ## FPN通道数：256

### 对定义的RPNHead进行描述
RPNHead:
  anchor_generator:                             ## Anchor生成器
    aspect_ratios: [0.5,1.0,2.0]                # Anchor的比例1:2,1:1,2:1
    anchor_sizes: [[32],[64],[128],[256],[512]] # Anchor的尺度比例
    strides: [4,8,16,32,64]                     # Anchor的步长
  rpn_target_assign:                            ## RPN设置
    batch_size_per_im: 256                      # RPN采样数量：256
    fg_fraction: 0.5                            # 正则样本数量：256*0.5=128
    negative_overlap: 0.3                       # 负样本IoU<0.3
    positive_overlap: 0.7                       # 正样本IoU>0.7
    use_random: True
  train_proposal:                               ## 训练建议框设置
    min_size: 0.0
    nms_thresh: 0.7                             # 训练阶段nms阈值
    pre_nms_top_n: 2000                         # 第一阶段nms数量
    post_nms_top_n: 1000                        # 第二阶段nms数量
    topk_after_collect: True
  test_proposal:                                ## 测试建议框设置
    min_size: 0.0
    nms_thresh: 0.7                             # 测试阶段nms阈值
    pre_nms_top_n: 1000                         # 第一阶段nms数量
    post_nms_top_n: 1000                        # 第二阶段nms数量

## 对定义的BBoxHead进行详细描述
BBoxHead:
  head: TwoFCHead                 ## 两个FC头
  roi_extractor:
    resolution: 7                 # RoIPooling特征层的尺度7x7
    sampling_ratio: 0
    aligned: True                 # 启用RoIAlign
  bbox_assigner: BBoxAssigner

## 对BBoxHead中定义的BBoxAssigner和TwoFCHead进行详细描述
BBoxAssigner:
  batch_size_per_im: 512    # batch数量：512
  bg_thresh: 0.5            # 背景阈值<0.5
  fg_thresh: 0.5            # 前景阈值>0.5
  fg_fraction: 0.25
  use_random: True

TwoFCHead:
  out_channel: 1024         # 全连接层特征维度(后面紧跟分类和回归层):1024

## 对定义的BBoxPostProcess进行详细描述
BBoxPostProcess:
  decode: RCNNBox
  nms:
    name: MultiClassNMS
    keep_top_k: 100
    score_threshold: 0.05
    nms_threshold: 0.5

## 定义工作并行度
worker_num: 2


## 数据读取和预处理(数据增强等)
TrainReader:
  sample_transforms:    # 数据预处理
  - Decode: {}
  - RandomResize: {target_size: [[640,1333],[672,1333],[704,1333],[736,1333],[768,1333],[800,1333]],interp: 2,keep_ratio: True} # 图片随机放大
  - RandomFlip: {prob: 0.5}   # 图片随机翻转
  - NormalizeImage: {is_scale: true, mean: [0.485,0.456,0.406],std: [0.229,0.224,0.225]}  # 图片归一化
  - Permute: {}
  batch_transforms:
  - PadBatch: {pad_to_stride: 32}
  batch_size: 1         # 每批大尺度
  shuffle: true         # 是否打乱顺序
  drop_last: true       # 最后一个batch不是batch_sizes时，是否将多余数据进行丢弃

EvalReader:
  sample_transforms:
  - Decode: {}
  - Resize: {interp: 2,target_size:[800,1333],keep_ratio: True}
  - NormalizeImage: {is_scale: true,mean: [0.485,0.456,0.406],std:[0.229,0.224,0.225]}
  - Permute: {}
  batch_transforms:
  - PadBatch: {pad_to_stride: 32}
  batch_size: 1
  shuffle: false
  drop_last: false
  drop_empty: false

TestReader:
  sample_transforms:
  - Decode: {}
  - Resize: {interp: 2,target_size:[800,1333],keep_ratio: True}
  - NormalizeImage: {is_scale: true,mean:[0.485,0.456,0.406],std:[0.229,0.224,0.225]}
  - Permute: {}
  batch_transforms:
  - PadBatch: {pad_to_stride: 32}
  batch_size: 1
  shuffle: false
  drop_last: false


```

<br>
**训练模型**
`python -u .	ools	rain.py -c .\work\PCB_faster_rcnn_r50_fpn_3x_coco.yml --eval use_gpu=True`
```
loading annotations into memory...
Done (t=0.02s)
creating index...
index created!
[12/08 17:36:56] ppdet.utils.checkpoint INFO: Finish loading model weights: D:\ML\Project\PaddleDetection-release-2.3\output\PCB_faster_rcnn_r50_fpn_3x_coco .pdparams
[12/08 17:37:05] ppdet.engine INFO: Epoch: [0] [  0/593] learning_rate: 0.000250 loss_rpn_cls: 0.077478 loss_rpn_reg: 0.048770 loss_bbox_cls: 0.151260 loss_bbox_reg: 0.053664 loss: 0.331172 eta: 1 day, 10:05:31 batch_cost: 8.6236 data_cost: 0.0000 ips: 0.1160 images/s
[12/08 17:38:47] ppdet.engine INFO: Epoch: [0] [ 10/593] learning_rate: 0.000363 loss_rpn_cls: 0.087272 loss_rpn_reg: 0.061770 loss_bbox_cls: 0.217608 loss_bbox_reg: 0.207371 loss: 0.706757 eta: 1 day, 15:42:19 batch_cost: 10.1933 data_cost: 0.0002 ips: 0.0981 images/s
[12/08 17:40:51] ppdet.engine INFO: Epoch: [0] [ 20/593] learning_rate: 0.000475 loss_rpn_cls: 0.084982 loss_rpn_reg: 0.087303 loss_bbox_cls: 0.147528 loss_bbox_reg: 0.072444 loss: 0.408839 eta: 1 day, 20:04:12 batch_cost: 12.3873 data_cost: 0.0000 ips: 0.0807 images/s
[12/08 17:42:28] ppdet.engine INFO: Epoch: [0] [ 30/593] learning_rate: 0.000588 loss_rpn_cls: 0.097606 loss_rpn_reg: 0.065509 loss_bbox_cls: 0.215224 loss_bbox_reg: 0.134091 loss: 0.556537 eta: 1 day, 18:10:50 batch_cost: 9.7029 data_cost: 0.0002 ips: 0.1031 images/s
```
**对模型进行评估**
`python -u .	oolsval.py -c .\work\PCB_faster_rcnn_r50_fpn_3x_coco.yml -o weights=.\output\PCB_faster_rcnn_r50_fpn_3x_cocoest_model.pdparams use_gpu=True`
```
[12/08 17:58:43] ppdet.metrics.coco_utils INFO: Start evaluate...
Loading and preparing results...
DONE (t=0.00s)
creating index...
index created!
Running per image evaluation...
Evaluate annotation type *bbox*
DONE (t=0.07s).
Accumulating evaluation results...
DONE (t=0.04s).
 Average Precision  (AP) @[ IoU=0.50:0.95 | area=   all | maxDets=100 ] = 0.024
 Average Precision  (AP) @[ IoU=0.50      | area=   all | maxDets=100 ] = 0.085
 Average Precision  (AP) @[ IoU=0.75      | area=   all | maxDets=100 ] = 0.000
 Average Precision  (AP) @[ IoU=0.50:0.95 | area= small | maxDets=100 ] = -1.000
 Average Precision  (AP) @[ IoU=0.50:0.95 | area=medium | maxDets=100 ] = 0.024
 Average Precision  (AP) @[ IoU=0.50:0.95 | area= large | maxDets=100 ] = 0.000
 Average Recall     (AR) @[ IoU=0.50:0.95 | area=   all | maxDets=  1 ] = 0.023
 Average Recall     (AR) @[ IoU=0.50:0.95 | area=   all | maxDets= 10 ] = 0.107
 Average Recall     (AR) @[ IoU=0.50:0.95 | area=   all | maxDets=100 ] = 0.115
 Average Recall     (AR) @[ IoU=0.50:0.95 | area= small | maxDets=100 ] = -1.000
 Average Recall     (AR) @[ IoU=0.50:0.95 | area=medium | maxDets=100 ] = 0.115
 Average Recall     (AR) @[ IoU=0.50:0.95 | area= large | maxDets=100 ] = 0.000
[12/08 17:58:44] ppdet.engine INFO: Total sample number: 10, averge FPS: 0.15968471430523315
```
**使用模型进行推测**
`python -u .	ools\infer.py -c .\work\PCB_faster_rcnn_r50_fpn_3x_coco.yml --infer_img=.\work\PCB_DATASET\images_missing_hole_10.jpg -o weights=.\work\output\PCB_faster_rcnn_r50_fpn_3x_cocoest_model.pdparams use_gpu=True`
查看预测后的图片
```
import matplotlib.pyplot as plt
import cv2

infer_img = cv2.imread("D:/ML/Project/PaddleDetection-release-2.3/output/04_missing_hole_10.jpg")
plt.figure(figsize=(15, 10))
plt.imshow(cv2.cvtColor(infer_img, cv2.COLOR_BGR2RGB))
plt.show()
```

<br>
## 2.6 车牌识别(PaddleOCR)
使用PaddlePaddle的[PaddleOCR开发套件](https://github.com/PaddlePaddle/PaddleOCR)来完成。

**安装PaddleOCR开发套件**
下载PaddleOCR包，下载requirements中的模块 `pip install -r .equirements.txt`


**对数据集进行处理**
```
import os
import cv2

ads = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
       'N', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
       '0', '1', '2', '3', '4', '5', '6', '7', '8,', '9', 'O']

provinces = ["皖", "沪", "津", "渝", "冀", "晋", "蒙", "辽", "吉", "黑", "苏",
             "浙", "京", "闽", "赣", "鲁", "豫", "鄂", "湘", "粤", "桂", "琼",
             "川", "贵", "云", "藏", "陕", "甘", "青", "宁", "新", "警", "学"]

if not os.path.exists('./img'):
    os.mkdir('./img')
## 分为车牌检测和车牌识别
# 转换检测数据
train_det = open('./train_det.txt', 'w', encoding='UTF-8')
dev_det = open('./dev_det.txt', 'w', encoding='UTF-8')

# 转换识别数据
train_rec = open('./train_rec.txt', 'w', encoding='UTF-8')
dev_rec = open('./dev_rec.txt', 'w', encoding='UTF-8')

# 总样本数
total_num = len(os.listdir('D:\ML\Dataset\CCPD2019