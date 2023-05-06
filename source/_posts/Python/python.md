---
title: python
categories:
- Python
---
```python
# -*- coding: utf-8 -*-

'''print("hello world")

import keyword
print(len(keyword.kwlist))
print(keyword.kwlist)'''

"""if True:
	print("true")
elif False:
	print("false")

sentence='''这是一个句子
换行'''
print(sentence)

input()
"""
"""
x = 'runoob';print(x+"
",end="")

a,b,c,d=1,2.0,True,1+2j
print(type(a),type(b),type(c),type(d))

del a,b,c,d

print(isinstance(a,int))"""
'''

'''
'''
a,b=1,1.0
print((type(a())==b))
print(isinstance(a,b))
'''
'''
x,y=1,2
print((x>y) + (x<y))
print((x>y))
print(False+True + "
")
'''
'''
import math
print(abs(-1))
print(math.fabs(-2))
print(math.modf(1.23))
print(math.exp(1))
print(pow(2,3))
print(round(1.234,2))
print(math.sqrt(9))
'''
'''
import random,math
print(random.choice(range(3)))
print(random.randrange(1,5,2))
print(random.random())
#print(random.seed(1)
print(random.shuffle([1,2,3,4,5]))
print(random.uniform(1,3))

print(math.acos(1))
print(math.asin(1))
print(math.atan(1))
print(math.atan2(1,1))
print(math.cos(3.14))
print(math.hypot(3,4))
print(math.sin(3.14))
print(math.tan(1.57))
print(math.degrees(math.pi/2))
print(math.radians(90))
'''
'''
str="hello python"
l=str[0:5:2]
print(l)
'''
'''
print('Ru
oob')
print(r'Ru
oob')
str="hello python"
print(str[-1])
'''
'''
list=[1,2.0,True,"hello"]
print(list[2])
list[3]="python"
print(list)
print(len(list))
print(list[0:2:2])
list[0:4:2]=[False,1]
print(list)
'''
'''
list=["a","b"]
t1=(0,1,2,list)
t2=(4,)
print((t1+t2)*2)
'''
'''
#s1=set(1) 错误
s1=set("abacab1")
print(s1)
s2={1,2,'a',2,'a'}
print(s2)

print(set("abv")-set("abs"))
print(set("abv")|set("abs"))
print(set("abv")&set("abs"))
print(set("abv")^set("abs"))
'''
'''
d={x:x**2 for x in (2,4,6)}
print(d)
d=dict(Google=3,Runoob=2,TaoBao=1)
print(d)
print(d['Google'])
print(d.keys())
print(d.values())
'''
'''
x=12
a=int('12',8)
print(a)
b=int('16',16)
print(b)
c=float(x)
print(c)
d=complex(x,x)
print(d)
e=str(x)
print(type(e))
f=repr([1,2,3])
print(type(f))
str="[1,2,3]"
f=eval(str)
print(type(f))

g=tuple([1,2,2,"list"])
print(type(g))
h=list(g)
print(type(h))
i=set(g)
print(i)
'''
'''
j=chr(97)
print(j)
k=ord('A')
print(k)
l=hex(14)
print(l)
m=oct(15)
print(m)
'''
'''
/**
 * [a description]
 * @type {[type]}
 */
a = input()
print(a)
'''
''''
s = 'ᚡ'
print(s)
a = 'Hello %10.5s ,hello %s'%('Python','World')
print(a)
'''
'''
a = True
print(id(a))
a = 1 and 2
print(a)
'''
'''
a = 50
b = 20 
c = 30
max = a if a>b and a>c else b if b>c else c
print(max)
'''
'''
my_list = []
my_list.append(1)
print(len(my_list))
str = []
str.append('c')
print(str)
'''
'''
r = range(-1,-5,-1)
for i in r:
    print(i)

for i in range(5,0,-1):
    print(i)
'''
'''
a = [['name','lisi'],('age',18),['gender','male']]
#a = [('name','lisi'),('age',18)]
d = dict(a)
print(d,type(d)) 
p = a.pop()
print(p)

keys = d.keys()
print(keys)
print(d.values())
for key in keys:
    print(key)
    print(key,d[key])
print(d.items())
'''
'''
def fn(a,b,c):
    
    文档字符串
    对三个参数求和

    print(a+b+c)

help(fn)
'''
'''
/**
 * 判断是否为回文
 */
def hui_wen(s):
    i,j = 0,len(s)-1 
    return judge(s,i,j)


def judge(s,i,j):
    if(i >= j):
        return True
    if(s[i] == s[j]):
        return judge(s,i+1,j-1)
    else:
        return False

print(hui_wen('b'))
'''
'''
s = input("请输入字符串：")

def hui_wen(s):
    length = len(s)
    if(length<=1):
        return True
    if s[0] == s[length - 1]:
        return hui_wen(s[1:-1])
    else:
        return False

print(hui_wen(s))
'''
'''
def hui_wen(s):
    if(len(s) <= 1):
        return True
    return s[0] == s[-1] and hui_wen(s[1:-1])

s = 'abcb'
print(hui_wen(s))
'''
'''
def fn(a):
    return a%2 == 0

l = [1,2,3,4,5]
print(list(filter(fn,l)))

print((lambda a,b : a+b)(1,2))
'''
'''
l = [1,2,3,4,5,6,7]
print(lambda i : i % 3 == 0)(2)
print(list(filter(lambda i : i%3 == 0,l)))
'''
'''
l = ['aaa','bb','cccc']
l.sort()
'''
'''
class MyClass:
    name = 'zhangsan'

    def __init__(self):
        print("hello")

    print("什么时候执行")

    def __init__(self):
        print("hello2")

    def myName(self):
        print("my name is : %s"%self.name)

my1 = MyClass()
my1.name = 'lisi'
del my1.name
print(my1.name)
my1.myName()

my2 = MyClass()
my2.name = 'wangwu'
print(my2.name)
my2.myName()
'''
# python -version
'''
class Dog():

    def __init__(self,name,gender,age):
        self.name = name
        self.age = age
        self.gender = gender

    def bark(self):
        print(f'{self.name} is barking')

    def run(self):
        print("%s is running"%self.name)

dog1 = Dog("大黄",5,'male')
dog2 = Dog("小黄",3,'female')

dog1.bark()
dog2.bark()
dog1.run()
dog2.run()

dog1.length = 100
print(dog1.length)
dog1.bite():
    print(f"{dog1.length}")
'''
'''
class Person():

    def __init__(self,name,age):
        self.__name = name
        self.__age = age

    def get_name(self):
        return self.__name

    def set_name(self,name):
        self.__name = name

    def get_age(self):
        return self.__age

    def set_age(self,age):
        self.__age = age

p1 = Person("zhangsan",18)

p1.set_name("lisi")
print(p1.get_name(),p1.get_age())
'''
'''
class People:

    def __init__(self,name,age):
        self._name = name
        self._age = age

    @property
    def name(self):
        return self._name

    @name.setter
    def name(self,name):
        self._name = name

    @property
    def age(self):
        return self._age

    @age.setter
    def age(self,age):
       self._age = age


people = People("zhangsan",10)

print(people.name,people.age)


people.name = "lisi"
people.age = 20
print(people.name,people.age)
'''
'''
class Person():

    def __init__(self,name,age):
        self.__name = name
        self.__age = age

    @property
    def namef(self):
        return self.__name

    @_Person__name.setter
    def namef(self,name)
        self.__name = name

    @property
    def agef(self):
        return self.__age

    # @agef.setter
    # def agef(self,age):
    #     self.__age = age

p = Person("zhangsan",20)
print(p.namef,p.agef)
p.namef = "lisi"
print(p.namef,p.agef)
'''
'''
class Animal:
    def run(self):
        print("running...")

    def eat(self):
        print("eating")

class Dog(Animal):

    def __init__(self,name):
        self._name = name

    def bark(self):
        print("barking")

    def run(self):
        print(f"{self._name} is running")

d = Dog("小黄")
d.eat()
d.bark()
d.run()
'''
'''
class A():
    def a(self):
        print("this is a")

class B(A):
    def b(self):
        print("this is b")

class C(A):
    def c(self):
        print("this is c")

class D(B,A):
    def d(self):
        print("this is d")

print(D.__bases__)

c = C()
print(isinstance(c,A))
'''
'''
class A():

    catagory = "character"

    def __del__(self):
        print("对象被删除了",self)

    def objmethod(self):
        print("this is objmethod")

    @classmethod
    def clsmethod(cls):
        print("this is clsmethod")
        cls.catagory = "aaaaaa"


a = A()
print(a.catagory)
a.catagory = "ccccc"
print(a.catagory)
print(A.catagory)

a.objmethod()
print(A.catagory)
a.clsmethod()
print(A.catagory)

input("回车键退出。。。")
'''
```
