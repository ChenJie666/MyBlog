---
title: 关于final的使用
categories:
- 编程语言
---
###final 变量
final 限制的变量可以是基础数据类型和引用数据类型
基本数据类型：内容不可变
引用数据类型：引用的指向不可变，执行的对象的值可以改变。例如
```
public static void main(String[] args) {
		final List<String> list = new LinkedList<>();
		list.add("test");//ok
		list = new LinkList<>();// can`t be compiled
}
```

###final 方法
final 标注的方法都是不能被继承、更改的，所以对于 final 方法使用的第一个原因就是方法锁定，以防止任何子类来对它的修改
```
public class Student {
		private Stirng name;
		public final void printName() {
			System.out.print(this.name);
		}
}

public class StudentExtend extends Student {
		@Override   //can`t be compiled
		public final void printName() {
				System.out.print(this.name);
		}
}
```

###final 类
final 修饰的类，表明该类是最终类，它不希望也不允许其他来继承它
```
public class Student {
		private Stirng name;
		public final void printName() {
			System.out.print(this.name);
		}
}

public class StudentExtend extends Student { can`t be compiled
}
```

###在Stream等lambda表达式中变量会自动添加final

这是由Java对lambda表达式的实现决定的，在Java中lambda表达式是匿名类语法上的进一步简化，其本质还是调用对象的方法。 
在Java中方法调用是值传递的，所以在lambda表达式中对变量的操作都是基于原变量的副本，不会影响到原变量的值。

综上，假定没有要求lambda表达式外部变量为final修饰，那么开发者会误以为外部变量的值能够在lambda表达式中被改变，而这实际是不可能的，所以要求外部变量为final是在编译期以强制手段确保用户不会在lambda表达式中做修改原变量值的操作。

另外，对lambda表达式的支持是拥抱函数式编程，而函数式编程本身不应为函数引入状态，从这个角度看，外部变量为final也一定程度迎合了这一特点。
