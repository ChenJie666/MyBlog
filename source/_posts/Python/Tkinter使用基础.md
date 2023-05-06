---
title: Tkinter使用基础
categories:
- Python
---
# 一、简介
Tkinter包编写一些图形用户界面程序。Tkinter是Python的一个标准包，因此我们并不需要安装它。我们将从创建一个窗口开始，然后我们在其之上加入一些小组件，比如按钮，复选框等，并使用它们的一些属性。

<br>
# 二、基本组件使用(Python3.x)
**基本组件**
| 控件 | 描述 |
| --- | --- |
| Button | 按钮控件；在程序中显示按钮。 |
| Canvas | 画布控件；显示图形元素如线条或文本 |
| Checkbutton | 多选框控件；用于在程序中提供多项选择框 |
| Entry | 输入控件；用于显示简单的文本内容 |
| Frame | 框架控件；在屏幕上显示一个矩形区域，多用来作为容器 |
| Label | 标签控件；可以显示文本和位图 |
| Listbox | 列表框控件；在Listbox窗口小部件是用来显示一个字符串列表给用户 |
| Menubutton | 菜单按钮控件，用于显示菜单项。 |
| Menu | 菜单控件；显示菜单栏,下拉菜单和弹出菜单 |
| Message | 消息控件；用来显示多行文本，与label比较类似 |
| Radiobutton | 单选按钮控件；显示一个单选的按钮状态 |
| Scale | 范围控件；显示一个数值刻度，为输出限定范围的数字区间 |
| Scrollbar | 滚动条控件，当内容超过可视化区域时使用，如列表框。. |
| Text | 文本控件；用于显示多行文本 |
| Toplevel | 容器控件；用来提供一个单独的对话框，和Frame比较类似 |
| Spinbox | 输入控件；与Entry类似，但是可以指定输入范围值 |
| PanedWindow | PanedWindow是一个窗口布局管理的插件，可以包含一个或者多个子控件。 |
| LabelFrame | labelframe 是一个简单的容器控件。常用与复杂的窗口布局。 |
| tkMessageBox | 用于显示你应用程序的消息框。 |

<br>
**标准属性: 所有控件的共同属性**
| 属性      | 描述       |
| --------- | ---------- |
| Dimension | 控件大小； |
| Color     | 控件颜色； |
| Font      | 控件字体； |
| Anchor    | 锚点；     |
| Relief    | 控件样式； |
| Bitmap    | 位图；     |
| Cursor    | 光标；     |

其中Font属性可以设置为元组 (family, size, options)，也可以赋值为Font对象
```
import tkinter as tk
import tkinter.font as font

window = tk.Tk()
window.geometry("400x300")
window['background'] = "black"

fconfig = font.Font(size=20,family="黑体")
label = tk.Label(window, text="选择值: ", fg="white", bg='blue',font=fconfig)
label.pack(fill="x",padx=50,pady=60)

window.mainloop()
```


| 属性或方法                              | 说明                                                         |
| --------------------------------------- | ------------------------------------------------------------ |
| name                                    | 唯一的字体名                                                 |
| exists                                  | 指向现有命名字体                                             |
| family                                  | 例如 Courier，Times                                          |
| size                                    | 字体大小                                                     |
| weight                                  | 字体强调 (普通-NORMAL， 加粗-BOLD)                           |
| slant                                   | 正体-ROMAN，斜体ITALIC                                       |
| underline                               | 字体下划线（0 - 无下划线，1 - 有下划线）                     |
| overstrike                              | 字体删除线（0 - 无删除线，1 - 有删除线）                     |
| actual(*option=None*, *displayof=None*) | 返回字体的属性                                               |
| cget(*option*)                          | 检索字体的某一个属性值                                       |
| config(options)                         | 修改字体的某一个属性值                                       |
| copy()                                  | 返回当前字体的新实例                                         |
| measure(*text*, *displayof=None*)       | 返回以当前字体格式化时文本将在指定显示上占用的空间量。如果未指定显示，则假定为主应用程序窗口。 |
| metrics(options, kw)                    | 返回特定字体的数据。                                         |

<br>
常见的"family"名字对照表
| 字体中文名 | 字体英文名  |
| --- | --- |
| 宋体 |  SimSun（浏览器默认） |
| 黑体 | SimHei |
| 微软雅黑 | Microsoft Yahei |
| 微软正黑体 | Microsoft JhengHei |
| 楷体 | KaiTi |
| 新宋体 | NSimSun |
| 仿宋 | FangSong |


<br>
**导入图片**
```
import tkinter as tk

window = tk.Tk()
window.title("登陆界面")
window.geometry("300x200+200+200")

pic = tk.PhotoImage(width=50, height=50, file="C:/Users/CJ/Desktop/Snipaste_2021-12-14_23-14-21.gif")
btnReset = tk.Button(text='重置', width=10, borderwidth=4, command=click_reset, image=pic)
btnReset.grid(column=2, row=2)

window.mainloop()
```


<br>
## 2.1 基础弹窗
```
import tkinter

window = tkinter.Tk()
window.title("Hello world")
# 进入消息循环
window.mainloop()
```

**tk属性**
| 属性或方法             | 说明                                                         |
| ---------------- | ------------------------------------------------------------ |
| window.title('标题名')  | 修改框体的名字,也可在创建时使用className参数来命名； |
|  window.resizable(0,0) | 框体大小可调性，分别表示x,y方向的可变性； |
|  window.geometry('250x150 + 1000 + 500')  | 指定主框体大小；+1000和+500表示框体所在的位置(可以使用+-1000+-1000的方式使框体移动到屏幕外来隐藏框体) |
| window.quit()    | 退出； |
| window.withdraw() | 隐藏框体 |
| window.deiconify() | 显示框体 |
| window.update_idletasks() / root.update()  | 刷新页面； |       　　　　　
| window['background'] = "black" | 框体的背景色  |
| tk.Toplevel(window) | 因为tk是一个循环结构，使用单线程并想在一个窗口基础下创建新的窗口的时候，需要使用该函数 |


<br>
## 2.2 带有文本信息的弹窗
```
window = tkinter.Tk()
window.title("Hello World")
lbl = tkinter.Label(window, text="content")
lbl.grid(column=0, row=0)
window.mainloop()
```
**设置窗口大小**
```
window.geometry("500x200")
```

**Label属性**

**设置文本样式**
```
lbl = tkinter.Label(window, text="content", font=("Arial Bold", 100))
```

| 属性             | 说明                                                         |
| ---------------- | ------------------------------------------------------------ |
| **anchor**       | 文本或图像在背景内容区的位置，默认为 center，可选值为（n,s,w,e,ne,nw,sw,se,center）eswn 是东南西北英文的首字母，表示：上北下南左西右东。 |
| **bg**           | 标签文字背景颜色，dg='背景颜色'                                                |
| **bd**           | 标签文字边框宽度，bd=‘边框宽度’。边框宽度显示需要配合边框样式才能凸显。                                  |
| **bitmap**       | 指定标签上的位图，如果指定了图片，则该选项忽略               |
| **cursor**       | 鼠标移动到标签时，光标的形状，可以设置为 arrow, circle, cross, plus 等。 |
| **compound** | 图片位于文字的方向，可选值有 left right top bottom center |
| **font**         | 标签文字字体设置，font=('字体', 字号, 'bold/italic/underline/overstrike')                                               |
| **fg**           | 标签文字前景色，fg='前景颜色'                                                 |
| **height**       | 标签的高度，默认值是 0。和relief结合使用才会凸显效果。                                     |
| **image**        | 设置标签图像。                                               |
| **justify**      | 定义对齐方式，可选值有：LEFT,RIGHT,CENTER，默认为 CENTER。   |
| **padx**         | x 轴间距，以像素计，默认 1。                                 |
| **pady**         | y 轴间距，以像素计，默认 1。                                 |
| **relief**       | 边框样式，可选的有：FLAT、SUNKEN、RAISED、GROOVE、RIDGE。默认为 FLAT。 |
| **text**         | 设置文本，可以包含换行符(
)。                               |
| **textvariable** | 标签显示 Tkinter 变量，StringVar。如果变量被修改，标签文本将自动更新。tkinter.StringVar() |
| **underline**    | 设置下划线，默认 -1；为 0 时，第一个字符带下划线，设置为 1，则是从第二个字符开始画下划线 |
| **width**        | 设置标签宽度，默认值是 0，自动计算，单位以像素计。和relief结合使用才会凸显效果。           |
| **wraplength**   | 标签达到限制的屏幕单元后，文本为多少行显示，默认为 0。                         |



<br>
## 2.3 输入文本框

![image.png](Tkinter使用基础.assets\69ed19d613304330a61b153a13dab15a.png)

```
import tkinter

window = tkinter.Tk()
window.title("Hello world")
window.geometry("500x300")

text = tkinter.Text(window)
text.grid(column=0, row=0)

window.mainloop()
```

| 属性 | 说明 |
| ------------------ | ------------------------------------------------------------ |
| height             | 设置文本框的高度，高度值每加1则加一行                        |
| width              | 设置文本框的宽度，宽度值每加1则加一个字节                    |
| insert             | 文本框插入数据，可以指定插入数据的位置                       |
| delete             | 删除文本框中的数据，可以通过数据位置，指定删除的数据         |
| get                | 获取文本框中的数据，可以通过数据位置，指定获取的数据         |
| relief             | 文本框样式，设置控件显示效果，可选的有：FLAT、SUNKEN、RAISED、GROOVE、RIDGE。 |
| bd                 | 设置文本框的边框大小，值越大边框越宽                         |
| bg                 | 设置文本框默认背景色                                         |
| fg                 | 设置文本框默认前景色，即字体颜色                             |
| font               | 文本字体，文字字号，文字字形。字形有overstrike/italic/bold/underline |
| state              | 文本框状态选项，状态有DISABLED/NORMAL，DISABLED状态文本框无法输入，NORMAL状态可以正常输入 |
| highlightcolor     | 设置文本框点击后的边框颜色                                   |
| highlightthickness | 设置文本框点击后的边框大小                                   |


<br>
## 2.4 输入文本框

![image.png](Tkinter使用基础.assets e0d6bc45754477c9afbbb88e2d76834.png)

```
import tkinter

window = tkinter.Tk()
window.title("Hello World")
window.geometry("600x200")
lbl = tkinter.Label(window, text="content")
lbl.grid(column=0, row=0)

# 接受输入的文本内容
txt = tkinter.Entry(width=10) # 设置输入框的宽度
txt.grid(column=1, row=0)

# 点击事件为修改文本内容为输入框的内容
def clicked():
    lbl.configure(text=txt.get())

btn = tkinter.Button(window, text="Click Me", command=clicked)
btn.grid(column=2, row=0)

window.mainloop()
```
设置输入焦点，当我们运行代码后，会发现可以直接在文本框中输入信息而不需要点击文本框。
```
txt.focus()
```

|  属性或方法  |     说明                                          |
| ------------------ | ------------------------------------------------------------ |
| width              | 设置文本框的宽度，宽度值每加1则加一个字节                    |
| insert             | 文本框插入数据，可以指定插入数据的位置                       |
| delete             | 删除文本框中的数据，可以通过数据位置，指定删除的数据         |
| get                | 获取文本框中的数据，可以通过数据位置，指定获取的数据         |
| relief             | 文本框样式，设置控件显示效果，可选的有：FLAT、SUNKEN、RAISED、GROOVE、RIDGE。 |
| bd                 | 设置文本框的边框大小，值越大边框越宽                         |
| bg                 | 设置文本框默认背景色                                         |
| fg                 | 设置文本框默认前景色，即字体颜色                             |
| font               | 文本字体，文字字号，文字字形。字形有overstrike/italic/bold/underline |
| state              | 文本框状态选项，状态有DISABLED/NORMAL，DISABLED状态文本框无法输入，NORMAL状态可以正常输入 |
| highlightcolor     | 设置文本框点击后的边框颜色                                   |
| highlightthickness | 设置文本框点击后的边框大小                                   |
| selectbackground   | 选中文字的背景颜色                                           |
| selectborderwidth  | 选中文字的背景边框宽度                                       |
| selectforeground   | 选中文字的颜色                                               |
| show               | 指定文本框内容显示的字符                                     |



<br>
## 2.5 按钮组件
```
import tkinter

window = tkinter.Tk()
window.title("Hello World")
lbl = tkinter.Label(window, text="content", font=("Arial Bold", 100))
window.geometry("600x200")
lbl.grid(column=0, row=0)

btn = tkinter.Button(window, text="Click Me")
# column和row 决定了每个组件的相对位置
btn.grid(column=0, row=1)

window.mainloop()
```
更改按钮前景和背景颜色
```
btn = tkinter.Button(window, text="Click Me", font=("Arial Bold", 10), bg="green", fg="orange")
```
处理按钮点击事件
```
def clicked():
    lbl.configure(text="Button was clicked!")

# 绑定点击函数，点击后修改lbl中的text内容
btn = tkinter.Button(window, text="Click Me", command=clicked)
btn.grid(column=0, row=1)
```

<br>
**Button属性**
| 属性 | 说明 |
| ---------- | ------------------------------------------------------------ |
| state            | 按钮状态选项，状态有DISABLED/NORMAL/ACTIVE                   |
| activebackground | 当鼠标放上去时，按钮的背景色                                 |
| activeforeground | 当鼠标放上去时，按钮的前景色                                 |
| bd               | 按钮边框的大小，默认为 2 个像素                              |
| bg               | 按钮的背景色                                                 |
| fg               | 按钮的前景色（按钮文本的颜色）                               |
| font             | 文本字体，文字字号，文字字形。字形有overstrike/italic/bold/underline |
| height           | 按钮的高度，如未设置此项，其大小以适应按钮的内容（文本或图片的大小） |
| width            | 按钮的宽度，如未设置此项，其大小以适应按钮的内容（文本或图片的大小） |
| image            | 按钮上要显示的图片，图片必须以变量的形式赋值给image，图片必须是gif格式。 |
| justify          | 显示多行文本的时候,设置不同行之间的对齐方式，可选项包括LEFT, RIGHT, CENTER |
| padx             | 按钮在x轴方向上的内边距(padding)，是指按钮的内容与按钮边缘的距离 |
| pady             | 按钮在y轴方向上的内边距(padding)                             |
| relief           | 边框样式，设置控件显示效果，可选的有：FLAT、SUNKEN、RAISED、GROOVE、RIDGE。 |
| wraplength       | 限制按钮每行显示的字符的数量，超出限制数量后则换行显示       |
| underline        | 限制按钮每行显示的字符的数量，超出限制数量后则换行显示       |
| underline        | 下划线。默认上的文本都不带下划线。取值就是带下划线的字符串索引，为 0 时，第一个字符带下划线，为 1 时，第两个字符带下划线，以此类推 |
| text             | 按钮的文本内容                                               |
| command          | 按钮关联的函数，当按钮被点击时，执行该函数                   |




<br>
## 2.6 添加一个下拉框

![image.png](Tkinter使用基础.assetsffe7a89fded48b195415dc6dad350f8.png)

```
import tkinter.ttk

window = tkinter.Tk()
window.title("Hello World")
window.geometry("600x200")

combo = tkinter.ttk.Combobox(window)
combo['values'] = (1, 2, 3, 4, 5, "Text")
combo.current(2) # 下标为2的文本为默认选择
combo.grid(column=0, row=0)

window.mainloop()
```
|  属性或方法  |     说明                                          |
| ---------------- | ------------------------------------------------- |
| value            | 插入下拉选项                                 |
| .current()       | 默认显示的下拉选项框                         |
| .get()           | 获取下拉选项框中的值                         |
| .insert()        | 下拉框中插入文本                             |
| .delete()        | 删除下拉框中的文本                           |
| state            | 下拉框的状态，分别包含DISABLED/NORMAL/ACTIVE |
| width            | 下拉框高度                                   |
| foreground       | 前景色                                       |
| selectbackground | 选择后的背景颜色                             |
| fieldbackground  | 下拉框颜色                                   |
| background       | 下拉按钮颜色                                 |


<br>
我们可以通过get函数获取到被选中的选项。
如下，通过点击按钮将文本修改为选择框中的内容
```
import tkinter.ttk

window = tkinter.Tk()
window.title("Hello World")
window.geometry("600x200")

lbl = tkinter.Label(window, text="content")
lbl.grid(column=0, row=0)

combo = tkinter.ttk.Combobox(window)
combo['values'] = (1, 2, 3, 4, 5, "Text")
combo.current(2)
combo.grid(column=1, row=0)


def clicked():
    lbl.configure(text=combo.get())


btn = tkinter.Button(window, text='Click me', command=clicked)
btn.grid(column=2, row=0)

window.mainloop()
```

<br>
## 2.7 单选框

![image.png](Tkinter使用基础.assets\27d2cbcda7c74b44a3e669c9fa11752c.png)

```
import tkinter

window = tkinter.Tk()
window.title("Hello World")
window.geometry("600x200")

lbl = tkinter.Label(window)
lbl.grid(column=0, row=1)

def clicked():
    lbl.configure(text=selected.get())

selected = tkinter.IntVar()
# 单选框中的第一个选项绑定一个方法，点击该选项时触发方法
rad1 = tkinter.Radiobutton(window, text="First", value=0, command=clicked, variable=selected)
rad2 = tkinter.Radiobutton(window, text="Second", value=1, command=clicked, variable=selected)
rad3 = tkinter.Radiobutton(window, text="Third", value=2, command=clicked, variable=selected)
rad1.grid(column=0, row=0)
rad2.grid(column=1, row=0)
rad3.grid(column=2, row=0)

window.mainloop()
```

| 参数或方法  | 说明                                                                 |
| ---------------- | ------------------------------------------------------------ |
| text             | 单选框文本显示                                               |
| variable         | 关联单选框执行的函数                                         |
| value            | 用于多个单选框值的区别                                       |
| .set(value)      | 默认选中指定的单选框                                         |
| relief           | 单选框的边框样式显示，可选项包括FLAT/SUNKEN/RAISED/GROOVE/RIDGE |
| height           | 单选框的高度，需要结合单选框的边框样式才能展示出效果         |
| width            | 单选框的宽度，需要结合单选框的边框样式才能展示出效果         |
| bd               | 单选框边框样式的宽度，需要结合单选框的边框样式才能展示出效果 |
| activebackground | 鼠标点击单选框时显示的前景色                                 |
| activeforeground | 鼠标点击单选框时显示的背景色                                 |
| bg               | 单选框显示的前景色                                           |
| fg               | 单选框显示的背景色                                           |
| font             | 单选框的文字字体、字号、字形，字形可选项包括bold/italic/underline/overstrike |
| image            | 单选框显示图片，图片必须是gif格式，并且图片需要用PhotoImage赋值给变量，然后变量赋值给image |
| justify          | 单选框文字对齐方式，可选项包括LEFT, RIGHT, CENTER            |
| wraplength       | 限制每行的文字，单选框文字达到限制的字符后，自动换行         |
| underline        | 下划线。取值就是带下划线的字符串索引，为 0 时，第一个字符带下划线，为 1 时，第两个字符带下划线，以此类推 |
| .config(state=)  | 单选框的状态，状态可选项有DISABLED/NORMAL/ACTIVE             |


<br>
## 2.8 复选框

![image.png](Tkinter使用基础.assets\8acca8eb5edb4f049e19de39f21d2c19.png)

```
import tkinter

window = tkinter.Tk()
window.title("Hello World")
window.geometry("600x200")

chk_state = tkinter.BooleanVar()
chk_state.set(True)
chk = tkinter.Checkbutton(window, text="Choose", var=chk_state)
chk.grid(column=1, row=0)

window.mainloop()
```
也可以使用IntVar变量进行设置，结果和用BooleanVar一样。
```
import tkinter

window = tkinter.Tk()
window.title("Hello World")
window.geometry("600x200")

chk_state = tkinter.IntVar()
chk_state.set(1) # Check
# chk_state.set(0) # Uncheck
chk = tkinter.Checkbutton(window, text="Choose", var=chk_state)
chk.grid(column=1, row=0)

window.mainloop()
```


<br>
## 2.9 文本区

![image.png](Tkinter使用基础.assets\7aaf645c2fa74cb2b30335029a21793c.png)

```
import tkinter
from tkinter import scrolledtext

window = tkinter.Tk()
window.title("Hello world")
window.geometry("350x200")

txt = tkinter.scrolledtext.ScrolledText(window, width=40, height=10)
txt.grid(column=0, row=0)

window.mainloop()
```
用以下方法可以在文本区中插入文本：
```
txt.insert(tkinter.INSERT, "TEXT GOES HERE")
txt.insert(tkinter.INSERT, "
Next Line")
```
用以下方法可以将文本区中的文本删除：
```
# 表示删除第一行及其之后的内容
txt.delete(1.0, END)
```

<br>
## 2.10 消息框

![image.png](Tkinter使用基础.assets0c010acc51748bf9b3b6cf823a65eb6.png)

```
import tkinter
import tkinter.messagebox

window = tkinter.Tk()
window.title("Hello world")
window.geometry("350x100")

def clicked():
    tkinter.messagebox.showinfo("Messge title", "Operation down")

btn = tkinter.Button(window, text="Click here", command=clicked)
btn.grid(column=0, row=0)

window.mainloop()
```

<br>
## 2.11 Spinbox
Spinbox是输入控件；与Entry类似，但是可以指定输入范围值。

![image.png](Tkinter使用基础.assets\9badfc84b8be4a4cb2e39d83618d0071.png)

```
import tkinter

window = tkinter.Tk()
window.title("Hello world")
window.geometry("350x150")

spin = tkinter.Spinbox(window, from_=0, to=100, width=5)
spin.grid(column=0, row=0)

window.mainloop()
```

如上代码指定了值的可变范围为0到100，也可以指定某些特定的值
```
tkinter.Spinbox(window, values=(3,8,11), width=5)
```
这样，Spinbox控件就只会显示3个数字即3，8，11。

给Spinbox控件设置默认值
```
var = tkinter.IntVar()
var.set(88)
spin = tkinter.Spinbox(window, from_=0, to=100, width=5, textvariable=var)
spin.grid(column=0, row=0)
```


<br>
## 2.12 进度条

![image.png](Tkinter使用基础.assets7f88238916f4df48b7705c3e0be8863.png)

```
from tkinter.ttk import Progressbar
import tkinter

window = tkinter.Tk()
window.title("Hello world")
window.geometry("350x200")

style = tkinter.ttk.Style()
style.theme_use('default')
style.configure("black.Horizontal.TProgressbar", background="black")
bar = Progressbar(window, length=200, style="black.Horizontal.TProgressbar")
bar['value'] = 70
bar.grid(column=0, row=0)

window.mainloop()
```

<br>
## 2.13 文件对话框

![image.png](Tkinter使用基础.assets\721cbd7f31bb47efa3e8874ebd65c882.png)

选择单个文件
```
import tkinter
from tkinter import filedialog
import os

window = tkinter.Tk()
window.title("Hello world")
window.geometry("350x200")


def clicked():
    file = filedialog.askopenfilename(initialdir=os.path.dirname(__file__)) # 默认打开当前程序所在目录
    print(file)


button = tkinter.Button(window, text="添加文件", command=clicked)
button.grid(column=0, row=0)

window.mainloop()
```

选择多个文件
```
file = filedialog.askopenfilename(initialdir=os.path.dirname(__file__))
```

选择一个目录
```
file = filedialog.askdirectory(initialdir=os.path.dirname(__file__))
```

<br>
## 2.14 滑块

![image.png](Tkinter使用基础.assetsab3be6ea1b462baa25abfba64c8b9e.png)

```
import tkinter as tk

window = tk.Tk()
window.geometry("400x200")


def clicked(value):
    print(value)
    label.config(text="选择值: " + value)

scl = tk.Scale(window, orient=tk.HORIZONTAL, length=300, label="音量", from_=10, to=100, tickinterval=10, resolution=10,
               command=clicked)
scl.pack()

label = tk.Label(window, text="选择值: ")
label.pack(anchor="w")

window.mainloop()
```

| 属性                | 说明                                                         | 默认值                                                       |
| ------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| activebackground    | 指定当鼠标在上方飘过的时候滑块的背景颜色                     | 默认值由系统指定                                             |
| background/bg       | 滚动槽外部的背景颜色                                         | 默认值由系统指定                                             |
| bigincrement        | 设置增长量的大小                                             | 默认值是 0，为范围的 1/10                                    |
| borderwidth/bd      | 指定边框宽度                                                 | 默认值是 2                                                   |
| command             | 当滑块变化时的回调函数，以滑块最新值为参数                   |                                                              |
| cursor              | 指定当鼠标在上方飘过的时候的鼠标样式                         | 默认值由系统指定                                             |
| digits              | 设置最多显示多少位数字，例如设置 from 选项为 0，to 选项为 20，digits 选项设置为 5，那么滑块的范围就是在 0.000 ~ 20.000 之间滑动) | 默认值是 0                                                   |
| foreground/fg       | 指定滑块左侧的 Label 和刻度的文字颜色                        | 默认值由系统指定                                             |
| font                | 指定滑块左侧的 Label 和刻度的文字字体                        | 默认值由系统指定                                             |
| from                | 设置滑块最顶（左）端的位置                                   | 默认值是 0                                                   |
| highlightbackground | 指定当 Scale 没有获得焦点的时候高亮边框的颜色                | 默认值由系统指定                                             |
| highlightcolor      | 指定当 Scale 获得焦点的时候高亮边框的颜色                    | 默认值由系统指定                                             |
| highlightthickness  | 指定高亮边框的宽度                                           | 默认值是 0（不带高亮边框）                                   |
| label               | 在垂直的 Scale 组件的顶端右侧（水平的话是左端上方）显示一个文本标签 | 默认不显示标签                                               |
| length              | Scale 组件的长度                                             | 默认值是 100 像素                                            |
| orient              | 设置该 Scale 组件是水平放置（HORIZONTAL）还是垂直放置（VERTICAL） | 默认是垂直放置 VERTICAL                                      |
| relief              | 指定边框样式 ，可以选择SUNKEN，FLAT，RAISED，GROOVE 和 RIDGE | 默认值是 SUNKEN                                              |
| repeatdelay         | 该选项指定鼠标左键点击滚动条凹槽的响应时间                   | 默认值是 300（毫秒）                                         |
| repeatinterval      | 该选项指定鼠标左键拖动滚动条凹槽时的响应间隔                 | 默认值是 100（毫秒）                                         |
| resolution          | 指定 Scale 组件的分辨率（步长，即在凹槽点击一下鼠标左键它移动的数量），例如设置 from 选项为 0，to 选项为 20，resolution 选项设置为 0.1 的话，那么每点击一下鼠标就是在 0.0 ~ 20.0 之间以 0.1 的步长移动 | 默认值是 1                                                   |
| showvalue           | 设置是否显示滑块旁边的数字                                   | 默认值为 True                                                |
| sliderlength        | 设置滑块的长度                                               | 默认值是 30 像素                                             |
| sliderrelief        | 设置滑块的样式，可选RAISED，FLAT，SUNKEN，GROOVE 和 RIDGE    | 默认值是 RAISED                                              |
| state               | 默认情况下 Scale 组件支持鼠标事件和键盘事件，可以通过设置该选项为 DISABLED 来禁用此功能 | 默认值是 NORMAL                                              |
| takefocus           | 指定使用 Tab 键是否可以将焦点移动到该 Scale 组件上           | 默认是开启的，可以通过将该选项设置为 False 避免焦点落在此组件上 |
| tickinterval        | 设置显示的刻度，如果设置一个值，那么就会按照该值的倍数显示刻度 | 默认值是不显示刻度                                           |
| to                  | 设置滑块最底（右）端的位置                                   | 默认值是 100                                                 |
| troughcolor         | 设置凹槽的颜色                                               | 默认值由系统指定                                             |
| variable            | Scale组件所在位置对应的值                                    |                                                              |
| width               | 指定 Scale 组件的宽度                                        | 默认值是 15 像素                                             |

| 方法               | 说明                                                         |
| ------------------ | ------------------------------------------------------------ |
| coords(value=None) | 获得当前滑块的位置对应 Scale 组件左上角的相对坐标，如果设置 value 参数，则返回当滑块所在该位置时的相对坐标 |
| get()              | 获得Scale组件的值（滑块的位置）                              |
| identify(x, y)     | 返回一个字符串表示指定位置下（如果有的话）的 Scale 部件，返回值可以是："slider"（滑块），"trough1"（左侧或上侧的凹槽），"trough2"（右侧或下侧的凹槽）或 ""（啥都没有） |
| set(value)         | 设置 Scale 组件的值（滑块的位置）                            |

<br>
## 2.15 图片
**直接显示**
```
import tkinter
root = tkinter.Tk()
img_gif = tkinter.PhotoImage(file = '1dpmw.gif')
label_img = tkinter.Label(root, image = img_gif)
label_img.pack()
root.mainloop()
```
但是上面的有一个问题，就是对于png这类图片显示不成功，会发现是空白，所以不推荐使用，因为只支持.gif一种形式。

**用PIL加载显示**
```
import tkinter
from PIL import Image, ImageTk
root = tkinter.Tk()
img_open = Image.open("2021-02-06_105510.png")
img_png = ImageTk.PhotoImage(img_open)
label_img = tkinter.Label(root, image = img_png)
label_img.pack()
root.mainloop()
```
注意和上面的区别，其实就是图片加载的方式由原来的
img_gif = tkinter.PhotoImage(file = '1dpmw.gif') 
变为现在的：
img_open = Image.open("2021-02-06_105510.png")
img_png = ImageTk.PhotoImage(img_open)

因为Image里面可以帮你解码，所以可以直接显示png。
上面显示是通过把图片放在label上面实现的，你也可以放到button或者canvas上面都是可以的。

**图片显示空白**
但你可能发现你在使用的时候，你的显示是空白，这里是因为你在开发的时候上面的一段话会写在一个函数里面封装起来，这个时候导致img_open是局部的，所以函数运行结束就被回收了，所以显示的是空白，解决方案也很简单，将这个变量声明为全局即可。
```
import tkinter
from PIL import Image, ImageTk
root = tkinter.Tk()
img_png =None
def func():
	img_open = Image.open("2021-02-06_105510.png")
	global img_png
	img_png = ImageTk.PhotoImage(img_open)
	label_img = tkinter.Label(root, image = img_png)
	label_img.pack()
func()
root.mainloop()
```

<br>
# 三、进度条进阶使用
## 3.1 设计进度条
Progressbar(父对象, options, ...)

- 第一个参数：父对象，表示这个进度条将建立在哪一个窗口内
- 第二个参数：options，参数如下

| 参数 | 含义 |
| --- | --- |
| length | 进度条的长度，默认是100像素 |
| mode | 可以有两种模式，下面作介绍 |
| maximum | 进度条的最大值，默认是100像素 |
| name | 进度条的名称，供程序参考引用 |
| orient | 进度条的方向，可以是HORIZONTAL(默认) 或者是VERTICAL |
| value | 进度条的目前值 |
| variable |	记录进度条目前的进度值 |

**mode参数:**
- determinate：一个指针会从起点移至终点，通常当我们知道所需工作时间时，可以使用此模式，这是默认模式

![image.png](Tkinter使用基础.assets\4a6d5d413aec4f3eacfae8bc63c42df3.png)

- indeterminate：一个指针会在起点和终点间来回移动，通常当我们不知道工作所需时间时，可以使用此模式

![image.png](Tkinter使用基础.assets\3e2e8b5d5d7a4cc48273edb54e19d434.png)

## 3.2 添加进度条动画
可以通过改变value的值并使用update方法刷新进度条的方式来使进度条动态改变。

```
import tkinter.ttk
import time

window = tkinter.Tk()
window.title("Hello world")
window.geometry("350x200")

progressbar = tkinter.ttk.Progressbar(window, length=200, mode="determinate", maximum=100, name="run bar", orient=tkinter.HORIZONTAL, value=0)

progressbar.pack(pady=20)


def run():
    for i in range(100):
        progressbar["value"] = i + 1
        window.update()
        time.sleep(0.03)


btn = tkinter.Button(window, text="run", command=run)
btn.pack(pady=5)

window.mainloop()
```

<br>
## 3.3 Progressbar 的方法 start()/step()/stop()
- start(interval)：每隔interval时间移动一次指针。interval的默认值是50ms，每次移动指针调用一次step(amount)。在step()方法内的amount参数意义就是增值量
- step(amount)：每次增加一次amount，默认值是1.0，在determinate模式下，指针不会超过maximum参数。在indeterminate模式下，当指针达到maximum参数值的前一格时，指针会回到起点
- stop()：停止start()运行

```
import tkinter.ttk

window = tkinter.Tk()
window.title("Hello world")
window.geometry("350x200")

progressbar = tkinter.ttk.Progressbar(window, length=200, mode="determinate", orient=tkinter.HORIZONTAL)
progressbar["maximum"] = 200
progressbar["value"] = 0
progressbar.pack(padx=5, pady=20)


def run():
    progressbar.start()
    progressbar.step(5)
    print(progressbar.cget("value"))


def stop():
    position = progressbar.cget("value")
    progressbar.stop()
    progressbar["value"] = position


btnr = tkinter.Button(window, text="Run", command=run)
btnr.pack(padx=10, pady=5, side=tkinter.LEFT)

btns = tkinter.Button(window, text="Stop", command=stop)
btns.pack(padx=10, pady=5, side=tkinter.RIGHT)

window.mainloop()
```

<br>
# 四、布局
可以使用一下三种方式进行布局，但是不能同时使用多种布局方式。
## 4.1 pack()
pack适合于少量的组件排序，所以在使用上是相当简单，一般添加组件后直接使用.pack()方法即可。但是如果想要对复杂的组件进行布局，那就要使用grid()或者Frame框架。


| 属性  |      说明                                                     |
| ------ | ------------------------------------------------------------ |
| side   | left: 左<br/>top: 上<br/>right: 右<br/>botton: 下         |
| fill   | x:水平方向填充<br/>y:竖直方向填充<br/>both:水平和竖直方向填充<br/>none:不填充 |
| expand | True:随主窗体的大小变化<br/>False:不随主窗体的大小变化      |
| anchor | N:北  下<br/>E:东  右<br/>S:南 下<br/>W:西 左<br/>CENTER:中间 |
| padx   | x方向的外边距                                                |
| pady   | y方向的外边距                                                |
| ipadx  | x方向的内边距                                                |
| ipady  | y方向的内边距                                                |

<br>
**例1:**
```
import tkinter as tk
import tkinter.font as font

window = tk.Tk()
window.geometry("400x300")
window['background'] = "black"

fconfig = font.Font(size=20, family="FangSong")
label = tk.Label(window, text="图床下载并替换", fg="white", bg='blue', font=fconfig)
label.pack(fill="x",padx=50,pady=60)

label = tk.Label(window, text="author by: CJ", fg="white", bg='orange', font=fconfig)
label.pack(padx=50,ipadx=30,ipady=20)

window.mainloop()
```
![image.png](Tkinter使用基础.assets7b7da618907434c83908fa652c0416f.png)

**例2：**
```
import tkinter as tk

window = tk.Tk()
window.title("pack布局")
window.geometry("500x300+300+300")

label1 = tk.Label(window, text="讲台", bg='gray', fg='white')
label1.pack(fill='x', padx=5, pady=10, ipady=10, side='top')

label2 = tk.Label(window, text="后黑板", bg='black', fg='white')
label2.pack(fill='x', padx=5, pady=10, ipady=10, side='bottom')

label3 = tk.Label(window, text="组1", bg='pink', fg='white')
label3.pack(fill='y', padx=5, ipadx=20, side='left')

label4 = tk.Label(window, text="组2", bg='pink', fg='white')
label4.pack(fill='y', ipadx=20, side='left')

label5 = tk.Label(window, text="组3", bg='pink', fg='white')
label5.pack(fill='y', padx=5, ipadx=20, side='left')

window.mainloop()
```
![image.png](Tkinter使用基础.assets\deec9dcf648e4077a13ddaaeac2f0e50.png)



<br>
## 4.2 grid()
grid 管理器是 Tkinter 这三个布局管理器中最灵活多变的，推荐使用。布局结构类似Excel，存在一个个单元格，每个单元格只能放一个组件，单元格之间可以合并。

| 属性  |      说明                                                     |
| ---------- | ------------------------------------------------------------ |
| row        | 插件放置的行数值                                             |
| rowspan    | 正常情况下一个插件只占一个单元。但是可以通过rowspan来合并一列中的多个邻近单元，并用此单元放置本插件。比如 w.grid(row=3, column=2, rowspan=4, columnspan=3)，这会把插件w布置在3-6行。 |
| column     | 插件放置的列数值，默认值为0。                                |
| columnspan | 正常情况下一个插件只占一个单元。但是可以通过columnspan来合并一行中的多个邻近单元，并用此单元放置本插件。比如 w.grid(row=0, column=2, columnspan=3)，这会把插件w布置在将第0行的2,3,4列合并后的单元中。 |
| in_        | 用in_=w2可以将w登记为w2的child插件。w2必须是w创建时指定的parent插件的child插件。 |
| padx       | x方向的外边距，(10,20)表示左边距10，右边距20 |
| pady       | y方向的外边距                                                |
| ipadx      | x方向的内边距                                                |
| ipady      | y方向的内边距                                                |
| sticky     | 这个参数用来确定，在插件正常尺寸下，如何分配单元中多余的空间 |

**sticky设置位置：**
1. 如果没有声明sticky属性，默认将插件居中于单元中；
2. 通过设置sticky=tk.N（靠上方），sticky=tk.S（靠下方），sticky=tk.W（靠左方），sticky=tk.E（靠右方），可以将插件布置在单元的某个角落；
3. 通过设置sticky=tk.NE（靠右上方），sticky=tk.SE（靠右下方），sticky=tk.SW（靠左下方），sticky=tk.SE（靠左上方），可以将插件布置在单元的某个角落；
4. 通过设置sticky=tk.N+tk.S，在垂直方向上延伸插件，并保持水平居中；设置sticky=tk.E+tk.W，在水平方向上延伸插件，并保持垂直居中；
5. 通过设置sticky=tk.N+tk.S+tk.S+tk.W，在垂直方向上延伸插件，并靠左放置；
6. 通过设置sticky=tk.N+tk.S+tk.W+tk.E，在水平和垂直方向上延伸插件，填满单元。

<br>
**例：**
```
import tkinter as tk
import tkinter.messagebox as tkmsg

window = tk.Tk()
window.title("登陆界面")
window.geometry("300x200+200+200")

# 创建账号密码输入框
nameVar = tk.StringVar()
passVar = tk.StringVar()

label = tk.Label(window, text="账号:", font=("Arial Bold", 15))
label.grid(column=0, row=0, pady=15)
entryName = tk.Entry(window, width=30, textvariable=nameVar)
entryName.grid(column=1, row=0, columnspan=2)

label = tk.Label(window, text="密码:", font=("Arial Bold", 15))
label.grid(column=0, row=1, pady=10)
entryPass = tk.Entry(window, show='*', width=30, textvariable=passVar)
entryPass.grid(column=1, row=1, columnspan=2)


def click_enter():
    if nameVar.get() == 'CJ' and passVar.get() == 'abc123':
        subWin = tk.Tk()
        subWin.geometry('400x300+200+200')
        subWin.title('首页')
    else:
        tkmsg.showinfo("警告", "用户名或密码错误")


def click_reset():
    nameVar.set('')
    passVar.set('')


btnEnter = tk.Button(text='登陆', width=10, borderwidth=4, command=click_enter)
btnEnter.grid(column=1, row=2)
btnReset = tk.Button(text='重置', width=10, borderwidth=4, command=click_reset)
btnReset.grid(column=2, row=2)

window.mainloop()
```

![image.png](Tkinter使用基础.assets\61685719ed44408e83ee353c4e6b63e2.png)


<br>
## 4.3 place()
Place 布局管理可以显式的指定控件的绝对位置或相对于其他控件的位置。但是需要计算控件的实际位置，可能会覆盖原有控件，没有边距和填充的概念。更改比较麻烦，这种方法的布局是最不建议使用的。

| 属性  |      说明                                                     |
| ---------- | ------------------------------------------------------------ |
| anchor | 此选项定义控件在窗体或窗口内的方位，可以是N、NE、E、SE、S、SW、W、NW或 CENTER。默认值是 NW，表示在左上角方位。 |
| bordermode | 此选项定义控件的坐标是否要考虑边界的宽度。此选项可以是 OUTSIDE 或 INSIDE，默认值是 INSIDE。 |
| height | 此选项定义控件的高度，单位是像素。 |
| width | 此选项定义控件的宽度，单位是像素。 |
| in(in_) | 此选项定义控件相对于参考控件的位置。若使用在键值，则必须使用 in_。 |
| relheight | 此选项定义控件相对于参考控件（使用 in_选项）的高度。 |
| relwidth | 此选项定义控件相对于参考控件（使用 in_选项）的宽度。 |
| relx | 此选项定义控件相对于参考控件（使用 in_选项）的水平位移。若没有设置 in_选项，则是相对于父控件。 |
| rely | 此选项定义控件相对于参考控件（使用 in_选项）的垂直位移。若没有设置 in_选项，则是相对于父控件。 |
| x | 此选项定义控件的绝对水平位置，默认值是 0。 |
| y | 此选项定义控件的绝对垂直位置，默认值是 0。 |

<br>
**例**
```
import tkinter as tk

window = tk.Tk()
window.title("place布局")
window.geometry("500x300+300+300")

label1 = tk.Label(window, text="讲台", bg='gray', fg='white')
label1.place(x=10,y=5,width=480,height=20)

label2 = tk.Label(window, text="后黑板", bg='black', fg='white')
label2.place(x=10,y=275,width=480,height=20)

label3 = tk.Label(window, text="组1", bg='pink', fg='white')
label3.place(x=10,y=30,width=40,height=240)

label4 = tk.Label(window, text="组2", bg='pink', fg='white')
label4.place(x=55,y=30,width=40,height=240)

label5 = tk.Label(window, text="组3", bg='pink', fg='white')
label5.place(x=100,y=30,width=40,height=240)

window.mainloop()
```
![image.png](Tkinter使用基础.assets\42690caf79b649d587a10487efb5def8.png)




<br>
# 五、滚动条
## 5.1 滚动条Scrollbar绑定Listbox
列表框(Listbox)是一个显示一系列选项的Widget控件，用户可以进行单项或多项的选择。使用滚动条Scrollbar查看全部文本信息。

![image.png](Tkinter使用基础.assets9f3f7768fb14a2ca06bc48d6cec5990.png)

```
import tkinter as tk

window = tk.Tk()
window.geometry('500x300+500+300')

scrollH = tk.Scrollbar(window, orient=tk.HORIZONTAL)
scrollH.pack(side=tk.BOTTOM, fill=tk.X)
scrollV = tk.Scrollbar(window, orient=tk.VERTICAL)
scrollV.pack(side=tk.RIGHT, fill=tk.Y)

mylist = tk.Listbox(window, xscrollcommand=scrollH.set, yscrollcommand=scrollV.set)
for i in range(50):
    mylist.insert(tk.END, '鲜衣怒马少年时,一日看尽长安花' + str(i))
mylist.pack(fill=tk.BOTH, expand=tk.TRUE)

scrollH.config(command=mylist.xview)
scrollV.config(command=mylist.yview)

window.mainloop()
```

<br>
## 5.2 滚动条Scrollbar绑定Canvas
```
from tkinter import *


def data():
    for i in range(50):
        Label(frame, text=i).grid(row=i, column=0)
        Label(frame, text="my text" + str(i)).grid(row=i, column=1)
        Label(frame, text="..........").grid(row=i, column=2)


# 少了这个就滚动不了
def myfunction(event):
    canvas.configure(scrollregion=canvas.bbox("all"), width=200, height=200)


root = Tk()
sizex = 800
sizey = 600
posx = 100
posy = 100
root.wm_geometry("%dx%d+%d+%d" % (sizex, sizey, posx, posy))

myframe = Frame(root, relief=GROOVE, width=50, height=100, bd=1)
myframe.place(x=10, y=10)

canvas = Canvas(myframe)
frame = Frame(canvas)
myscrollbar = Scrollbar(myframe, orient="vertical", command=canvas.yview)
canvas.configure(yscrollcommand=myscrollbar.set)

myscrollbar.pack(side="right", fill="y")
canvas.pack(side="left")
canvas.create_window((0, 0), window=frame, anchor='nw')
frame.bind("<Configure>", myfunction)
data()
root.mainloop()
```


<br>
# 五、参考
[Python tkinter（一） 按钮（Button）组件的属性说明及示例_沉默的鹏先生-CSDN博客](https://blog.csdn.net/ever_peng/article/details/102546009)
