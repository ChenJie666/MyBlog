---
title: ModelAndView
categories:
- SpringBoot
---
使用ModelAndView类用来存储处理完后的结果数据，以及显示该数据的视图。从名字上看ModelAndView中的Model代表模型，View代表视图，这个名字就很好地解释了该类的作用。业务处理器调用模型层处理完用户请求后，把结果数据存储在该类的model属性中，把要返回的视图信息存储在该类的view属性中，然后让该ModelAndView返回该Spring MVC框架。框架通过调用配置文件中定义的视图解析器，对该对象进行解析，最后把结果数据显示在指定的页面上。 

具体作用：

1、返回指定页面

ModelAndView构造方法可以指定返回的页面名称，

也可以通过setViewName()方法跳转到指定的页面 ,

2、返回所需数值

使用addObject()设置需要返回的值，addObject()有几个不同参数的方法，可以默认和指定返回对象的名字。

***

 在源码中有7个构造函数，如何用？是一个重点。

构造ModelAndView对象当控制器处理完请求时，通常会将包含视图名称或视图对象以及一些模型属性的ModelAndView对象返回到DispatcherServlet。

因此，经常需要在控制器中构造ModelAndView对象。

ModelAndView类提供了几个重载的构造器和一些方便的方法，让你可以根据自己的喜好来构造ModelAndView对象。这些构造器和方法以类似的方式支持视图名称和视图对象。

通过ModelAndView构造方法可以指定返回的页面名称，也可以通过setViewName()方法跳转到指定的页面 , 使用addObject()设置需要返回的值，addObject()有几个不同参数的方法，可以默认和指定返回对象的名字。

**（1）当你只有一个模型属性要返回时，可以在构造器中指定该属性来构造ModelAndView对象：**

**（2）如果有不止一个属性要返回，可以先将它们传递到一个Map中再来构造ModelAndView对象。**
 
