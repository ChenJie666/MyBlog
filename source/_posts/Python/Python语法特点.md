---
title: Python语法特点
categories:
- Python
---
print(x)   会自动换行
print(x,end="")   不换行输出

**为多对象指定多变量，一次性为多个变量赋值**
a,b,c = 1,2,"runnob"
**变量交换**
a,b = b,a

##标准数据类型
a:不可变数组（3个）：Number（数字）、String（字符串）、Tuple（元组）
b:可变数组（3个）：List（列表）、Set（集合）、Dictionary（字典）
###Number
int、float、bool、complex（复数）

##除法
python中除法得到的值都是浮点型的，如果需要得到整型，使用//符号进行除法，即在除法的基础上在调用floor函数。

##函数
type(a)  判断数据类型
isinstance(a,int)   判断数据是否属于某类型
del var1,var2   手动GC
bin(a) / oct(a) / hex(a)  转成其他进制

abs(x)   绝对值
ceil(x)   上整数
floor(x)   下整数
(x>y) - (x<y)   如果x<y返回-1，如果x=y返回0，如果x>y返回1
exp(x)   返回e的x次幂
fabs(x)   绝对值
log(x)   log运算
log10(x)   
pow(x,y)   x**y的值
modf(x)   返回x的整数部分与小数部分
round(x,[,n])   保留n位小数
sqrt(x)   返回数字x的平方根
max
min


### global关键字
![image.png](Python语法特点.assetsa137b0743f54796968a0041f77db74a.png)

在这个例子中设置的 x=5 属于全局变量,而在函数内部中没有对 x 的定义。

根据 Python 访问局部变量和全局变量的规则：当搜索一个变量的时候，Python 先从局部作用域开始搜索，如果在局部作用域没有找到那个变量，那样 Python 就会像上面的案例中介绍的作用域范围逐层寻找。

最终在全局变量中找这个变量，如果找不到则抛出 UnboundLocalError 异常。

但你会想，明明已经在全局变量中找到同名变量了，怎么还是报错？

因为内部函数有引用外部函数的同名变量或者全局变量，并且对这个变量有修改的时候，此时 Python 会认为它是一个局部变量，而函数中并没有 x 的定义和赋值，所以报错。

global 关键字为解决此问题而生，在函数 func_c中，显示地告诉解释器 x 为全局变量，然后会在函数外面寻找 x 的定义，执行完 x = x + 1 后，x 依然是全局变量。

<br>
### lambda
使用到lambda表达式和*p表示参数
```
def download_pics(url, file):
    pass

if __name__ == '__main__':
    files_list=[xx,xxx,xxxx]
    with ThreadPoolExecutor(8) as executor:
        for file in files_list:
            with open(file, encoding='utf-8') as f:
                md_content = f.read()

            args = {md_content, file}
            task = executor.submit(lambda p: get_pics_list(*p), args)
```
此处向线程池executor提交任务，参数为方法get_pics_list和方法参数args。但是只能传一个参数，所以将参数保存为数组，然后在方法中将参数数组解析为一个个参数。
