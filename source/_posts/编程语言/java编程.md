---
title: java编程
categories:
- 编程语言
---
\u开头的是一个Unicode码的字符，每一个' '代表的应该是NULL,输出控制台是一个空格，32以下的都是空格。ASCII码是unicode码的子集。

1 简单。Java语言的语法与C语言和C++语言很接近，使得大多数程序员很容易学习和使用Java。

2 面向对象。Java语言提供类、接口和继承等原语，为了简单起见，只支持类之间的单继承，但支持接口之间的多继承，并支持类与接口之间的实现机制（关键字为implements）。

3 分布式。Java语言支持Internet应用的开发，在基本的Java应用编程接口中有一个网络应用编程接口（java net），它提供了用于网络应用编程的类库，包括URL、URLConnection、Socket、ServerSocket等。Java的RMI（远程方法激活）机制也是开发分布式应用的重要手段。

4 健壮。Java的强类型机制、异常处理、垃圾的自动收集等是Java程序健壮性的重要保证。对指针的包装是Java的明智选择。
引用 -> 安全的指针
5 安全。Java通常被用在网络环境中，为此，Java提供了一个安全机制以防恶意代码的攻击。如：安全防范机制（类ClassLoader），如分配不同的名字空间以防替代本地的同名类、字节代码检查。

6 跨平台。Java程序（后缀为java的文件）在Java平台上被编译为体系结构中立的字节码格式（后缀为class的文件），然后可以在实现这个Java平台的任何系统中运行。


7 性能好。与那些解释型的高级脚本语言相比，Java的性能还是较优的。

8 多线程。在Java语言中，线程是一种特殊的对象，它必须由Thread类或其子（孙）类来创建,目的就是最大化利用CPU。

Overload是方法重载，指的是在同一个类中，方法名称相同，形参列表不同的两个或者多个方法，和返回值类型无关。
Override是方法的重写，指的是子类在继承父类时，当父类的方法体不适用于子类时，子类可重写父类的方法。重写必须遵守方法名和形参列表与父类的被重写的方法相同，而返回值类型可以小于等于父类被重写的方法（如果是基本数据类型和void必须相同），权限修饰符可以大于等于父类被重写的方法，抛出的异常列表可以小于等于父类被重写的方法。



    ~6 = -7的理解：	（1）（~6+1）是-6的补码，
		（2）因为直接存在计算机中，且是负数，所以计算机认为这个是补码，输出时取（-6的补码）的补码得到要输出的数的原码
		（3）于是输出的原码的值为-6，于是（~6+1）=-6，则~6=-7

把字符串转为整数的方法是：String a = “43”; int i = Integer.parseInt(a);
把命令行字符串转为整数的方法是：int n = Integer.parseInt(args[0]);
接收命令行参数的字符方法是：char ch = args[0].charAt(0);
Main(String[] args)获取命令行的字符串存在args的数组中，args数组中存储字符串，args.length代表字符串数组的长度 。输入时用空格分隔。


while(a)等价于while（a！=0）


switch(表达式)中表达式的返回值必须是下述几种类型之一：byte，short，char，int，String, 枚举；


**Char ch 接收常量不用强转，接收变量要强转
**double d = 111111111111错误，因为常数是int型超范围。改为double d = 111111111111L
**十六进制忠实反应二进制（补码）的值，十六进制没有负数


System.out.println('*' + '	' +'*');
System.out.println("*" + '	' +'*');


Int n = 10；  
n = n++;
过程：先把n值取出来放在一边，n自加1，再将原n值赋给n。赋值号优先级低，最后运算；
先用后加，先把值取出备用，最后再用这个值。
++i不用开辟临时空间，效率比i++高；

用最有效率的方法算出2乘以8等於几
答：2 << 3   8<<2


short s1 = 1; s1 = s1 + 1;有什么错? short s1 = 1; s1 += 1;有什么区别；
答：short s1 = 1; s1 = s1 + 1; （s1+1运算结果是int型，需要强制转换类型）
short s1 = 1; s1 += 1;（可以正确编译）

Int i = 10;
i = i++;
System.out.println(i);
输出10.

Int型常量可以赋给short型变量（不超范围）
但是Int型变量不可以赋给short型变量
Return返回值是变量
float型float f=3.4是否正确?
答:不正确。精度不准确,应该用强制类型转换，如下所示：float f=(float)3.4

break语句出现在多层嵌套的语句块中时，可以通过标签指明要终止的是哪一层语句块 
	label1: 	{   ……        
	label2:	         {   ……
	label3:			{   ……
				           break label2;
				           ……
					}
			          }
			 } 





Break 是直接跳出循环和switch。可用标签跳出大括号｛｝
![image.png](java编程.assets\555ee669543143288da2be55369dadb6.png)
![image.png](java编程.assets\64241707df67440eaf4f7d82be89c9bf.png)




class Demo1{
	//交换两数的不同方法（三种）
	public static void main(String[] args){
		
		int m = 1;
		int n = 9;
		
		//第一种（最常规简单）
	/*	int temp = n;
		n = m;
		m = temp;	*/
		
		//第二种（加减法）
	/*	n = n+m;
		m = n-m;
		n = n-m;	*/
		
		//第三种（异或法）最巧妙
		m = m^n;//m中保存两数差异数
		n = m^n;//差异数与n作异或运算得到m的值赋给n
		m = m^n;//n中保存的m的值，差异数与m作异或运算得到n的值赋给m
				//理解的核心是m^n^m = n;
				
		System.out.println(m+"  "+n);
		
	}

写出结果。(关于参数传递)
public class Test      
{ 
	public static void leftshift(int i, int j)
	{ 
   		i+=j; 
	} 
	public static void main(String args[])
	{ 
		int i = 4, j = 2; 
		leftshift(i, j); 
		System.out.println(i); 
	} 
} 
//4  和leftShift函数没关系。
![image.png](java编程.assets\8a046f32d7ee4ad19ece89728a92aae2.png)



第三章  面向对象编程

![image.png](java编程.assets\2400a33025fa48e598cc6b3dae5a29b9.png)



构造器最大的用处就是在创建对象时执行初始化，当创建一个对象时，系统会为这个对象的实例进行默认的初始化。如果想改变这种默认的初始化，就可以通过自定义构造器来实现。


静态成员：静态类中的成员加入static修饰符，即是静态成员.可以直接使用"类名.静态成员名"访问此静态成员，因为静态成员存在于内存，非静态成员需要实例化才会分配内存，所以静态成员函数不能访问非静态的成员..因为静态成员存在于内存，所以非静态成员函数可以直接访问类中静态的成员.
非静态成员：所有没有加Static的成员都是非静态成员，当类被实例化之后，可以通过实例化的类名进行访问..非静态成员的生存期决定于该类的生存期..而静态成员则不存在生存期的概念，因为静态成员始终驻留在内存中..
![image.png](java编程.assets