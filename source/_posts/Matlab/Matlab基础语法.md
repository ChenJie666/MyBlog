---
title: Matlab基础语法
categories:
- Matlab
---
% matlab中ctrl + r可以对整行进行注释，ctrl + t可以取消注释

%% clear清除工作区的变量，clc清空命令行窗口

% 向量表示，可以用逗号或空格进行分隔
a = [1,2,3]
b = [1 2 3]

%% 矩阵表示，可以写在一行，或写成多行
% 矩阵在matlab中是以列向量形式存储的
A = [1,2,3;2,3,4;3,4,5]

B = [1,2,3;
    2,3,4;
    3,4,5]

%% 输入和输出函数
% input
A = input('输入函数为=')
% disp
disp('打印到控制台')

%% 字符串合并
% strcat
strcat('字符串1','字符串2')
% [str1,str2, ... ,strn] 或 [str1 str2 ... strn]
['字符串1','字符串2']

%% 将数字转换为字符串
c = 100;
num2str(c)

%% sum函数
clear;clc
E1 = [1,2,3]
E2 = [1;2;3]
A = [1,2,3;2,3,4;3,4,5]
% 如果是向量，所有元素求和(输出值)
sum(E1)
sum(E2)
% 如果是矩阵，分为行求和和列求和(输出向量)
sum(A) % 默认为列求和
sum(A,1) % dim为1表示列求和
sum(A,2) % dim为2表示行求和
% 对整个矩阵元素求和
sum(sum(A))
sum(A(:))   % A(:)将矩阵中所有的元素都保存为列向量，在进行列向量求和

%% matlab中提取矩阵中的元素
clear;clc
A = [1,2,3;2,3,4;3,4,5]
% （1）指定行和列(输出值)
A(2,3)
A(4) % 因为matlab中矩阵是以列向量进行存储的，可以通过列向量的索引进行查询
% （2）指定某一行或列(输出向量)
A(2,:)
A(:,1)
% （3）指某些行或列(输出矩阵)
A([1,3],:) % 取第1和第3行的所有元素
A(1:3,:) % 取1到3行的所有元素
A(1:2:3,:) % 取第1和第3行的所有元素
A(2:end,:) % 取第2行到最后1行的所有元素
A(1:end-1,:) % 取第1行到最后第2行的所有元素
% （4）取矩阵的所有元素(按列拼接，输出列向量)
A(:)

%% size函数
clear;clc
A = [1,2,3;3,1,2];
B = [1,2,3,4,5,6];
% size(A)函数计算矩阵的行数和列数
size(A)
size(B)
% 可以用向量接收结果
[r,c] = size(A)
% 只返回行数或列数
r = size(A,1) % 只返回行数
c = size(A,2) % 只返回列数

%% repmat函数
clear;clc
A = [1,2,3]
% 将矩阵A复制m×n块
repmat(A,3,1)
repmat(A,3,2)

%% Matlab中矩阵的运算
A = [1,2;3,4];
B = [1,0;1,1];
% MATLAB在矩阵的运算中，“*”和“/”表示矩阵之间的乘法和除法（A/B = A*inv(B)）
A * B
inv(B) % B矩阵求逆
B * inv(B)
A * inv(B)
A / B

% 两个形状相同的矩阵的对应的元素进行运算需要使用“.*”和“./”
A .* B
A ./ B

% 矩阵的指数运算“^”，“.^”
A ^ 2 %同 A*A
A .^ 2 %A矩阵中的每个元素进行平方

%% matlab中求特征值和特征向量
clear;clc
A = [1,2,3;3,1,2;3,2,1]
% （1）E=eig(A): 求矩阵A的全部特征值，构成向量E
E = eig(A)
% （2）[V,D]=eig(B): 求矩阵A的全部特征值构成对角阵D，并求A的特征向量构成V的列向量。
[V,D]=eig(A)

%% find函数
% 向量
clear;clc
X = [1 0 4 -3 0 0 0 8 6]
ind = find(X) % 返回向量中不为0的元素的位置索引(输出行向量)
ind = find(X,2) % 返回前两个不为0的元素的位置索引

% 矩阵
clear;clc
X = [1,2,3;3,1,2;3,2,1];
ind = find(X) % 返回矩阵中不为0的元素的位置索引(输出列向量)
ind = find(X,2) % 返回前两个不为0的元素的位置索引

[r,c] = find(X) % 通过向量进行接收,r和c输出为列向量
[r,c] = find(X,1) % 只查找第一个非零元素

%% 矩阵大小判断
clear;clc
A = [1,2,3;3,1,2;3,2,1]
% 共有三种运算符，大于>、小于<和等于== 
A > 2 % 矩阵中符合条件的元素为1，不符合的元素为0

%% if判断
a = 66;
if a > 80
    disp('优秀')
elseif a >=60 , a < 80
    disp('良好')
else a < 60
    disp('不合格')
end

%% for循环
n = 5;
sum = 0;
for i = 1:n
    sum = sum + i;
end
disp(['1到',num2str(n),'求和结果为',num2str(sum)]);
    
%% 错误处理
clear;clc
a=1;
b=1;
try
    c=a(1,2)+b % 索引会越界
catch
    c=a(1,1)+b
end

%% 自定义函数(需要将函数写到单独的.m文件中)
% 无参无返回值
function mysum()
    s = 0;
    for i = 1 : 5
        s = s + i;
    end
    disp(s);
end
% 有参无返回值
function mysum(n)
    s = 0;
    for i = 1 : n
        s = s + i;
    end
    disp(s);
end
% 有参有返回值
function result = mysum(n)
    s = 0;
    for i = 1 : n
        s = s + i;
    end
    result = s;
end
