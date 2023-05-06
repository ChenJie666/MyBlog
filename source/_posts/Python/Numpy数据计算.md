---
title: Numpy数据计算
categories:
- Python
---
###安装
pip install numpy pandas -i https://pypi.tuna.tsinghua.edu.cn/simple/

###引入
import numpy as np
import pandas as pd

###创建矩阵
>#####array方法创建矩阵
>**代码**
array = np.array([[1, 2, 3], [5, 6, 7]], dtype=np.int64)
print(array)
print('array的元素类型为: {}'.format(array.dtype))
print('number of dim: {}'.format(array.ndim))  # 获取矩阵的维度
print('shape:', array.shape)  # 获取矩阵的行列数
print('size:', array.size)  # 获取矩阵的大小
**结果**
[[1 2 3]
 [5 6 7]]
array的元素类型为: int64
number of dim: 2
shape: (2, 3)
size: 6

>#####zeros/ones/empty方法创建矩阵
>**代码**
array1 = np.zeros((2, 3))  # 构建指定行列数元素全为0的矩阵(还有np.ones、np.empty等)
print('a的元素类型为: {}'.format(array1.dtype))  # 默认类型为float64
**结果**
array1：
[[0. 0. 0.]
 [0. 0. 0.]]

>#####arange规定数组范围和步长，reshape规定矩阵行列数
>**代码**
array2 = np.arange(10, 20, 2)  # 定义范围为10到20步长为2的数组
array3 = np.arange(1, 13, 1).reshape(3, 4)  # 创建一个范围为1到13步长为1的行列数为3和4的矩阵
**结果**
array2： [10 12 14 16 18]
array3：
[[ 1  2  3  4]
 [ 5  6  7  8]
 [ 9 10 11 12]]
>
>#####linspace规定数组范围和个数，reshape规定矩阵行列数
>**代码**
array4 = np.linspace(0,10,6)  # 创建一个范围为1到10分为5段的数组
array5 = np.linspace(0,10,6).reshape(2,3)  # 创建一个范围为1到10分为5段的行列数为2好3的矩阵
**结果**
array4 ：[ 0.  2.  4.  6.  8. 10.]
array5：
[[ 0.  2.  4.]
 [ 6.  8. 10.]]

>#####随机生成矩阵
>**代码**
array6 = np.random.random((2, 4))  # 生成2行4列的矩阵，元素大小随机
**结果**
array6：
[[0.77692473 0.28440388 0.85873634 0.63594363]
 [0.2773047  0.36780031 0.06101272 0.69213009]]

<br>

###矩阵运算
a1 = np.array([[1, 2, 3], [4, 5, 6]])
a2 = np.array([[7, 8, 9], [10, 11, 12]])

>#####矩阵转置
>**代码**
tr1 = np.transpose(a1)
tr2 = a1.T
**结果**
tr1：[[1 4]
 [2 5]
 [3 6]]
tr2：[[1 4]
 [2 5]
 [3 6]]

>#####加减运算
>**代码**
sum = a1 + a2
sub = a2 - a1
>**结果**
sum ：
[[ 8 10 12]
 [14 16 18]]
sub ：
[[6 6 6]
 [6 6 6]]

>#####指数运算
>**代码**
exp = a1 ** 3  #将每个元素都进行三次方
**结果**
exp：
[[  1   8  27]
 [ 64 125 216]]

>#####三角函数运算
>**代码**
sin = 10 * np.sin(a1)  # 对a1中的每个元素求sin，然后每个元素乘以10
**结果**
sin：
[[ 8.41470985  9.09297427  1.41120008]
 [-7.56802495 -9.58924275 -2.79415498]]

>#####元素乘法运算
>**代码**
ep = a1 * a2  # 对应元素相乘
**结果**
[[ 7 16 27]
 [40 55 72]]

>#####矩阵乘法运算
>**代码**
mp = np.dot(a1, a2.T)   # 矩阵相乘，同mp = a1.dot(a2)
>**结果**
[[ 50  68]
 [122 167]]

>#####比较运算
>**代码**
lt = a1 < 3
>**结果**
lt：
>[[ True  True False]
 [False False False]]

>#####sum/max/min运算，axis指定轴(0表示列，1表示行)
>**代码**
max1 = np.max(a1) # 取矩阵所有元素的最大值
max2 = np.max(a1, axis=0) # 取矩阵每列的最大值
min1 = np.min(a1) # 取矩阵所有元素的最小值
min2 = np.min(a1, axis=1) # 取矩阵每行的最大值
>sum1 = np.sum(a1) # 取矩阵所有元素的求和
sum2 = np.sum(a1, axis=1) # 矩阵矩阵每行求和
>**结果**
>max1：6
max2：[4 5 6]
min1：1
min2：[1 4]
sum1：21
sum2：[ 6 15]

>#####运算
>**代码**
argmax1 = np.argmax(a1) # 取矩阵最大值的索引
argmin1 = np.argmin(a1) # 取矩阵最小值的索引
mean1 = np.mean(a1)  # 计算矩阵的平均值,同a1.mean()
mean2 = np.mean(a1, axis=1)  # 计算矩阵每行的平均值
average1 = np.average(a1)  # 计算矩阵的平均值
median1 = np.median(a1)  # 计算矩阵的中位数
cumsum1 = np.cumsum(a1)  # 第n项的值等于前n项原始值求和(数组)，类似斐波那契数列但是不同。
diff1 = np.diff(a1)  # 每行第n项的值等于第n项减去第n-1项(矩阵列数减一)
>nonzero1 = np.nonzero(a1)  # 将非零元素的行列索引放到两个数组中
sort1 = np.sort(np.arange(7, 1, -1).reshape(2, 3))  # 矩阵每行进行正序排列
clip1 = np.clip(a1, 2, 4)  # 保留矩阵中在2和4之间的数，小于2的数取2，大于4的数取4
>**结果**
>argmax1：5
argmin1：0
mean1：3.5
mean2：[2. 5.]
average1：3.5
>median1：3.5
cumsum1：[ 1  3  6 10 15 21]
diff1：
[[1 1]
 [1 1]]
nonzero1：(array([0, 0, 0, 1, 1, 1], dtype=int64), array([0, 1, 2, 0, 1, 2], dtype=int64))
sort1：
[[5 6 7]
 [2 3 4]]
clip1：
[[2 2 3]
 [4 4 4]]

<br>

###numpy的索引
a = np.arange(3, 15).reshape(3, 4)

>#####取矩阵中的所有元素
>print(a[:, :])  # 索引到矩阵的所有数
**结果：**
[[ 3  4  5  6]
 [ 7  8  9 10]
> [11 12 13 14]]

>#####取某行或某列的所有元素
>print(a[2])  # 索引到矩阵第3行的所有元素的值
**结果：**[11 12 13 14]
>print(a.T[2])  # 索引到矩阵第3列的所有元素的值
**结果：**[ 5  9 13]

>#####取指定索引的元素
>print(a[2, 1])  # 索引到矩阵第3行第2列的元素的值
print(a[2][1])  # 同上
**结果：**12

>#####取指定行和列范围内的所有元素
>print(a[1:3, 2:])  # 取第2行到第4行，第3列到最后一列的元素
**结果：**
[[ 9 10]
 [13 14]]

>#####遍历所有的行
>for row in a:
&nbsp;&nbsp;    print("row:", row)  # 遍历矩阵中所有的行
**结果：**
row: [3 4 5 6]
row: [ 7  8  9 10]
row: [11 12 13 14]

>#####遍历所有的列
>for column in a.T:
&nbsp;    print("column:", column)  # 遍历矩阵中所有的列
**结果：**
column: [ 3  7 11]
column: [ 4  8 12]
column: [ 5  9 13]
column: [ 6 10 14]

>#####遍历所有的列
>print(a.flatten())  # 将矩阵转化为数组
**结果：**[ 3  4  5  6  7  8  9 10 11 12 13 14]
for item in a.flat:  # 将矩阵a转化为遍历器进行遍历
&nbsp;    print("item:", item)  # 打印矩阵中的所有元素
**结果：**
item: 3
item: 4
item: 5
item: 6
item: 7
item: 8
item: 9
item: 10
item: 11
item: 12
item: 13
item: 14

<br>

###array合并
a = np.array([1,2,3])
b = np.array([4,5,6])

>#####上下合并(纵向合并)
>vstack1 = np.vstack((A, B))  # vertical,矩阵上下合并(纵向合并)
**结果：**
vstack1 ：
[[1 2 3]
 [4 5 6]]

>#####左右合并(水平合并)
>hstack1 = np.hstack((A, B))  # horizontal,矩阵左右合并(水平合并)
**结果：**
hstack1：[1 2 3 4 5 6]

>#####将数组转为矩阵（reshape，np.newaxis）
>AT1 = A.reshape(1, 3).T  # 通过重构矩阵将数组转化为矩阵，然后转置
AT2 = A[np.newaxis, :].T  # 添加纵轴，效果同上
AT3 = A[:, np.newaxis]  # 添加横轴，效果同上
**结果：**
AT1:
[[1]
 [2]
> [3]]

>#####多个矩阵进行合并（concatenate）
>C = np.array([1, 1, 1])[:, np.newaxis]
D = np.array([2, 2, 2])[:, np.newaxis]
C:
 [[1]
> [1]
 [1]]
>D: 
[[2]
 [2]
 [2]]
>
>con1 = np.concatenate((A, B, B, A), axis=0)  # 上下合并(纵向合并)
con2 = np.concatenate((A, B, B, A), axis=1)  # 左右合并(水平合并)
con3 = np.concatenate((C, D, D, C), axis=0)  # 上下合并(纵向合并)
con4 = np.concatenate((C, D, D, C), axis=1)  # 左右合并(水平合并)
**结果：**
con1：
[1 2 3 4 5 6 4 5 6 1 2 3]
con2：报错
con3：
[[1]
 [1]
 [1]
 [2]
 [2]
 [2]
 [2]
 [2]
 [2]
 [1]
 [1]
 [1]]
con4：
[[1 2 2 1]
 [1 2 2 1]
 [1 2 2 1]]

<br>
###array的分割
A = np.arange(12).reshape((3, 4))

>#####纵向/横向等分分割
>vsplit1 = np.vsplit(A,3)  # 上下等量分割为指定数量的(纵向分割)，不能等量分割会报错
hsplit1 = np.hsplit(A,2)  # 左右等量分割为指定数量(水平分割)，不能等量分割会报错 
split1 = np.split(A, 3, axis=0)  # 上下等量分割为指定数量的(纵向分割)，不能等量分割会报错
split2 = np.split(A, 2, axis=1)  # 左右等量分割为指定数量(水平分割)，不能等量分割会报错
split3 = np.array_split(A, 2, axis=0)  # 上下等量分割为指定数量的(纵向分割)，会尽量保证等量不会报错
split4 = np.array_split(A, 2, axis=1)  # 左右等量分割为指定数量(水平分割)，会尽量保证等量不会报错
split5 = np.split(A, [1, 2, 3], axis=0)  # 多个索引上下分割(纵向分割)
>split6 = np.split(A, [1, 2, 3], axis=1)  # 多个索引左右分割(水平分割)
**结果：**
vsplit1：
[array([[0, 1, 2, 3]]), array([[4, 5, 6, 7]]), array([[ 8,  9, 10, 11]])]
hsplit1：
>[array([[0, 1],
       [4, 5],
       [8, 9]]), array([[ 2,  3],
       [ 6,  7],
       [10, 11]])]
split1：
[array([[0, 1, 2, 3]]), array([[4, 5, 6, 7]]), array([[ 8,  9, 10, 11]])]
split2：
[array([[0, 1],
       [4, 5],
       [8, 9]]), array([[ 2,  3],
       [ 6,  7],
       [10, 11]])]
split3: 
[array([[0, 1, 2, 3],
>       [4, 5, 6, 7]]), array([[ 8,  9, 10, 11]])]
split4: 
[array([[0, 1],
       [4, 5],
       [8, 9]]), array([[ 2,  3],
       [ 6,  7],
       [10, 11]])]
split5：
[array([[0, 1, 2, 3]]), array([[4, 5, 6, 7]]), array([[ 8,  9, 10, 11]]), array([], shape=(0, 4), dtype=int32)]
split6：
[array([[0],
       [4],
       [8]]), array([[1],
       [5],
       [9]]), array([[ 2],
       [ 6],
       [10]]), array([[ 3],
       [ 7],
       [11]])]


<br>

###copy浅复制&deep copy
>#####浅复制
>a = np.arange(4)
b = a
c = a
d = b # 直接赋值不开辟新的内存空间，指向同一个内存地址
>
>a[0] = -1
d[1:3] = [-2, -3]
print(d is a)  # 判断a和d是否指向同一个内存地址
**结果：**
a,b,c,d都是：[-1 -2 -3  3]
d is a：True

>#####深复制
>a = np.arange(4)
b = a.copy()  # 深复制，开辟新的内存空间
print(b is a)  # 判断a和d是否指向同一个内存地址
**结果：**
a：[-1  1  2  3]
b：[0 1 2 3]
b is a：False

>#####特殊情况（复制后值会变但是不是同一个变量）
>a = np.arange(4)
b = a[:]  # 深复制，开辟新的内存空间
a[0] = -1
print(b is a)
**结果：**
a：[-1  1  2  3]
b：[-1 1 2 3]
b is a：False
