---
title: Matlab实现层次分析法示例
categories:
- Matlab
---
**预备知识点**
1. Matlab基本小常识：分号的作用、、注释的快捷键、clc和clear、disp和input；
2. sum函数；
3. Matlab中如何提取矩阵中指定位置的元素；
4.  size函数；
5. repmat函数；
6. Matlab中矩阵的运算（加点和不加点）；
7. Matlab中求特征值和特征向量；
8. find函数；
9. 矩阵与常数的大小判断运算
10. 判断和循环语句

#一、简介
1. **正互反矩阵的定义：**矩阵A=(aij)mxn满足以下特征
(1) aij>0
(2)aij=1/aji
则称矩阵A 为正互反矩阵。

2. **判断矩阵：**正互反矩阵中aii=1

3. **一致矩阵：**矩阵A=(aij)mxn满足以下特征
(1) aij>0
(2) a11=a22=···=ann=1
(3) [ai1,ai2,···,ain] = ki[a11,a12,···,a1n]，即aij*ajk = aik
 一致矩阵可以得出如下结论：各行列成比例，秩为1，特征值为tr(A)=n，特征向量w=[1/a11，1/a12，···，1/a1n]T (k!=0)

#####层次分析法的原理：
层次分析法AHP（Analytic Hierarchy Process）根据问题的性质和要达到的总目标，将问题分解为不同的组成因素，并按照因素间的相互关联影响以及隶属关系将因素按不同的层次聚集组合，形成一个多层次的分析结构模型，从而最终使问题归结为最低层(供决策的方案、措施等)相对于最高层(总目标)的相对重要权值的确定或相对优劣次序的排定。

#####计算逻辑：
将评价问题分为三个层次，目标层、准则层和方案层。通过判断矩阵得到准则层的各评价因素的比重，同理得到方案层的每个方案的各评价因素的比重。评价比重和方案比重相乘后得到每个方案的评分。

#####层次分析法的步骤：
运用层次分析法构造系统模型时，大体可以分为以下四个步骤：
1.建立层次结构模型；
2.构造判断(成对比较)矩阵；
3.层次单排序及其一致性检验；
4.层次总排序及其一致性检验；


最高层(目标层)：决策的目的、要解决的问题；
中间层(准则层或指标层)：考虑的因素、决策的准则；
最低层(方案层)：决策时的备选方案；


![image.png](Matlab实现层次分析法示例.assets\99dba6cab30c4551b0ce02f48e1eed26.png)

<br>
# 二、计算步骤
## 2.1 构造判断(成对比较)矩阵
构造判断(成对比较)矩阵时，为了避免直接确定各层次元素之间的比重，采用一致矩阵法，即两两对比确定相对重要性。
![image.png](Matlab实现层次分析法示例.assets\78d78571b5354b95a54da3317f9adc1c.png)
得到最终判断矩阵如下：
![image.png](Matlab实现层次分析法示例.assets\82fd9ab3a1f040ad8313580d3d4c1df7.png)

## 2.2 层次单排序及一致性检验
计算分为三种方法：算数平均数法、几何平均数法和特征值法(常用)

###算数平均数法：
计算得到的特征向量可以作为判断矩阵的权重向量。一致矩阵的特征向量就是任意列向量，简化后的一致性较好的判断矩阵的特征向量求法是可以取列向量的算数平均。
![算数平均数法.png](Matlab实现层次分析法示例.assets22016af7cef4b2daa12944497fc1fdc.png)

![算数平均数法.png](Matlab实现层次分析法示例.assets038e2c7621643ca934575622f700fd9.png)

###几何平均数法：
![几何平均数法.png](Matlab实现层次分析法示例.assets\4ad9cea04c184de592705d98bb349367.png)

###特征值法：
根据最大特征值求出特征向量
![特征值法](Matlab实现层次分析法示例.assets\3664ba7578074a1f99c8457a37b32fdf.png)


计算得到矩阵的特征值和特征向量，通过特征值计算一致性指标
![计算一致性指标.png](Matlab实现层次分析法示例.assetsd310ec76538419099b2f02b134e8d24.png)

当矩阵为一致矩阵时，特征值n最小，矩阵越不一致，最大特征值与n相差越大，通过差值判断一致程度。
![判断原理.png](Matlab实现层次分析法示例.assets\90d960a71eba49f9b5589016d23a73fb.png)

为了衡量CI的大小，引入随机一致性指标RI
![image.png](Matlab实现层次分析法示例.assets\3182938c745143d793bf8c986f768285.png)
随机一致性指标可以通过查表获取，也可以通过matlab进行计算
```matlab
n = 5;
p = [1,2,3,4,5,6,7,8,9,1/2,1/3,1/4,1/5,1/6,1/7,1/8,1/9];
L = length(p);
A = ones(n,n);
number = 8192;
R = 0;
for kp = 1:number
for i = 1:n-1
for j = i+1:n
k = floor(1+L*rand(1));
A(i,j) = p(k);
A(j,i) = 1/p(k);
end
end
lambda = max(eig(A));
CI = (lambda - n)/(n-1);
R = R+CI;
end
RI = R/number;
sprintf('n=%2d,RI=%6.2f',n,RI)
```
最终得到
![image.png](Matlab实现层次分析法示例.assets\891b895161b14bf083169f3acecaeb36.png)
为什么要构造CI以及为什么要以0.1为划分依据？这是作者通过多次蒙特卡洛模拟得到的最佳的方案。

## 2.3 层次总排序及其一致性检验；
![image.png](Matlab实现层次分析法示例.assets00635af44a045f7b8622ac661705ba4.png)

![image.png](Matlab实现层次分析法示例.assets\5d1f9dbe25324073a3a380891d0be318.png)

#三、代码
```
%% 输入判断矩阵
disp('请输入判断矩阵')
A = input('判断矩阵=')

%% 判断矩阵是否是正互反矩阵
[m,n] = size(A);

if m~=n
    disp('error(判断矩阵必须为方阵)')
end

for i = 1:1:n
    for j = i:1:n
        if A(i,j)*A(j,i) ~= 1
            disp('error(判断矩阵不为正互反矩阵)')
        end
    end
end

%% 方法一：算数平均数法求权重向量
Rep_A = repmat(sum(A),m,1);
Weight_Vector = sum(A./Rep_A,2)/n;
Max_eig = max(max(A*Weight_Vector/Weight_Vector));
disp('最大特征值为:')
disp(Max_eig)
disp('权重向量为:')
disp(Weight_Vector)

%% 方法二：几何平均数法求权重向量
Prod_A = prod(A,2);
Prod_n_A = Prod_A .^ (1/n);
Weight_Vector = Prod_n_A/sum(Prod_n_A);
Max_eig = max(max(A*Weight_Vector/Weight_Vector));
disp('最大特征值为:')
disp(Max_eig)
disp('权重向量为:')
disp(Weight_Vector)

%% 方法三：特征值法求权重向量
[V,D] = eig(A);
Max_eig = max(max(eig(D)));
[r,c] = find(D == Max_eig,1);
Weight_Vector = V(:,c)/sum(V(:,c));
disp('最大特征值为:')
disp(Max_eig)
disp('权重向量为:')
disp(Weight_Vector)

%% 一致性检验
RI = [0,0,0.52,0.89,1.12,1.26,1.36,1.41,1.46,1.49,1.52,1.54,1.56,1.58,1.59];
CI = (Max_eig-n)/(n-1);
CR = CI/RI(n);
disp(['CI=',CI])
disp(['CR=',CR])
if CR < 0.10
    disp('一致性检验通过')
else 
    disp('一致性检验未通过')
end
```
