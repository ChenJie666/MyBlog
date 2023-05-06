---
title: VSCode、JS、Vue简单语法
categories:
- 前端
---
Vue框架编写基本的操作流程：在src/api中定义接口的方法 —》在src/router中写路由—》在src/views中调用方法渲染页面。
Vue框架中ES6的语法支持js间的方法调用，axios进行了封装

###VSCode操作
安装插件chinese（中文简体）、live server（类似tomcat服务器）、vetur（vue工具）、vue-helper（vue脚手架）

1.本地创建空文件夹
2.通过vscode在文件夹中创建工作区
3.可以通过live server启动服务器，访问127.0.0.1:5500访问所有的命名空间。

VSCode的debug模式，在需要加断点的地方插入debugger，就会在该行停止。
![image.png](VSCode、JS、Vue简单语法.assetsdc06e112fef4c8a80a8f38ddbfa05d8.png)



###JS的基本语法
ES6是一套标准，JS是这套标准的实现。
1.定义变量
```js
<script type="text/javascript">
    {
        /*
            可以使用var和let定义变量
            区别一:作用范围不同，let定义局部变量，var定义全局变量
            区别二:let只能定义一次 ，var可以相同定义多次           
        */
        var a = 10;
        var a = 1;  //可以重复定义
        let b = 10;
    }
    //在代码块外输出代码
    console.log(a) //输出10
    console.log(b) //Uncaught ReferenceError: b is not defined
</script>
```
2.定义常量
```js
<script>
    const AA  //定义常量必须初始化
    const PI = "3.1415926"
    PI = 3  //常量一旦定义不能改变
</script>
```
3.结构赋值
```js
<script>
    //传统写法
    let a=1,b=2,c=3
    console.log(a,b,c)

    //es6写法
    let [x,y,z] = [1,2,3]
    console.log(x,y,z)
</script>
```
4.对象解构
```js
<script>
    //定义对象
    let user = {"name":"lucy","age":20}

    //传统写法
    let name1 = user.name
    let age1 = user.age
    console.log(name1+"=="+age1)

    //es6写法,和数组用[]不同的是，对象用{},且变量名与属性名一致
    let {age,name} = user
    console.log(name+"=="+age)

</script>
```
5.模板字符串
```js
<script>
    //1.使用`符号能实现换行
    let str1 = `hello,
    es6 demo up!`
    
    console.log(str1)

    //2.字符串插入变量和表达式。变量名写在${}中，${}中可以放入JavaScript表达式
    let name = "Lucy"
    let age = 19
    
    let str2 = `hello,${name}'age is ${age + 1}`
    console.log(str2) //输出 hello,Lucy'age is 20

    //3.调用方法
    function f(){
        return "have fun!!!"
    }

    let str3 = `Game start,${f()}`
    console.log(str3) //输出 Game start,have fun!!!

</script>
```
6.对象声明
```js
<script>
    const name = "lucy"
    const age = 20

    //传统方式定义对象
    const p1 = {name:name,age:age}
    console.log(p1)

    //es6定义对象
    const p2 = {name,age}
    console.log(p2)

</script>
```
7.方法声明
```js
<script>
    //传统方式定义方法
    const person1 = {
        sayHi:function(){
            console.log("Hi")
        },
        eat:function(){
            console.log("eat")
        }
    }

    person1.sayHi()  //方法调用
    person1.eat()   //方法调用

    //es6方式定义方法,可以省略function
    const person2 = {
        sayHi(){
            console.log("Hi")
        },
        eat(){
            console.log("eat")
        }
    }

    person2.sayHi()
    person2.eat()

</script>
```
8.对象拓展运算符
```java
<script>
    //1.对象复制
    let person1 = {"name":"lucy","age":20}
    let person2 = {...person1}

    console.log(person2)

    //2.合并对象
    let name = {name:"mary"}
    let age = {age:15}
    
    let p2 = {...name,...age}

    console.log(p2)
</script>
```
9.箭头函数
```java
<script>
    //传统定义函数写法
    var f1 = function(a){
        return a
    }
    console.log(f1(1))

    var f2 = function(a,b){
        return a+b
    }
    console.log(f2(1,2))

    //ES6定义函数写法（类似lambda表达式）
    var f3 = a => a
    console.log(f3(1))

    var f4 = (a,b) => a+b
    console.log(f2(1,2))

</script>
```


#VUE
***标签***
- v-on（@）：事件绑定
  - v-on:submit.prevent修饰符告诉v-on指令对于触发的事件调用js的event.preventDefault()，即阻止表单提交的默认行为；
  - v-on:click.once修饰符表示只能调用一次
- v-bind（：）：变量绑定
- v-model：变量双向绑定
- v-if、v-else-if、v-else：条件渲染，惰性的，如果条件为false，则不渲染。
- v-show：效果同v-if，会渲染全部的元素。
- v-for：列表渲染

- el：view名称定义
- data：变量定义
- method：方法定义
- compute：计算方法定义
- components：组件定义
- beforeCreate 
- **created**：在页面渲染之前执行
- beforeMount
- **mounted**：在页面渲染之后执行
- beforeUpdate
- updated 
- beforeDestroy
- destroyed

- <input type="text" v-model="name"> 文本框
- <textarea v-model="msg"></textarea> 多行文本框
- <input type="checkbox" v-model="check"> 单个复选框
- {{checklist}} 多个复选框
    <input type="checkbox" value="male" v-model="checklist">M
    <input type="checkbox" value="female" v-model="checklist">F
    <input type="checkbox" value="other" v-model="checklist">O
- {{picked}} 单选框
    <input type="radio" value="查找" v-model="picked">A
    <input type="radio" value="删除" v-model="picked">B
- {{select}} 下拉框
    <select v-model="select">
        <!-- disabled表示无法选中，select和value为一样都为空，则显示该标签的内容 -->
        <option disabled value="">请选择</option>
        <option value="北京">北京</option>
        <option value="上海">上海</option>
        <option value="杭州">杭州</option>
    </select>

###axios
axios是独立的项目，经常和axios一起使用，实现ajax操作。

###element-ui组件库
是饿了么前端开源的基于Vue.js的后台组件库，方便程序员进行页面的快速布局和构建。

###node.js
1.node.js是JS的运行环境，用于执行JS代码环境，不需要浏览器。
2.模拟服务器，直接使用node.js运行JS代码。
node -v  //检查版本
node js文件路径   //可以直接运行js文件

###npm
NPM(Node Package Manager)是Node.js包管理工具，相当于前端的Maven，管理前端js依赖，比如jquery。安装node.js时会自动安装npm，npm -v查看版本。
1.npm项目初始化操作
npm init [-y]
完成后会生成package.json文件，类似于pom.xml文件

2.npm下载js依赖
//设置为淘宝镜像
npm config set registry https://registry.npm.taobao.org
//查看镜像源
npm config list

3.1下载依赖
npm install 依赖名称@版本

![项目目录](VSCode、JS、Vue简单语法.assets14ced6c8e0641b2b02794387b957881.png)
下载完成后会生成package-lock.json文件和modules模块：
① package-lock.json记录了依赖的版本并锁定，只能使用记录的版本的依赖
② modules存储了
③ 根据package.json下载依赖

3.2根据目录下的package.json下载指定版本的依赖
npm install

###babel
babel是转码器，把es6代码转换成es5的代码，提高兼容性。
1.安装babel
npm install --global babel-cli
babel --version
2.在项目根目录下新建配置文件.babelrc
{
    "presets":["es2015"]
}
3.安装转码器
npm install --save-dev babel-preset-es2015
4.创建用es6语法编写的js文件
```js
//定义数组
let input = [1,2,3]
//将数组每个元素加一
input = input.map(item => item + 1)

console.log(input)
```
5.进行转码
①根据文件转码babel src/example.js -o dist/compiled.js
②根据文件夹转码babel src -d dist
转码会将es6的语法转换为es5的语法

###模块化
前端js与js之间的互相调用叫做前端的模块化。
创建01.js
```js
//定义方法
const sum = function(a,b){
    return parseInt(a) + parseInt(b)
}

const subtract = function(a,b){
    return parseInt(a) - parseInt(b)
}

//设置哪些方法可以被其他js调用
module.exports = {
    sum,
    subtract
}
```
创建02.js，并在02.js中调用01.js的方法
```js
//引入01.js文件
const m = require('./01.js')

const sum = m.sum(1,2)
const sub = m.subtract(1,2)

console.log(sum)
console.log(sub)
```
注意：如果使用es6写法实现模块化操作，在node.js环境中是不能直接运行的，需要用babel将es6转换为es5语法。
如下：
创建03.js
```js
//写法一
// export function sum(){
//     console.log('sum...')
// }

// export function subtract(){
//     console.log('subtract...')
// }

//写法二
export default{
    sum(){
        console.log('sum...')
    },
    subtract(){
        console.log('subtract...')
    }
}

```
创建04.js，并引入03.js方法
```js
//引入js
import m from './03.js'

m.sum()
m.subtract()
```

###webpack
webpack是前端资源的加载/打包工具，可以将js、css、less等文件打包为一个文件，减少页面的请求次数，提高访问效率。

***打包js文件***
1.全局安装
npm install -g webpack webpack-cli
webpack -v 查看版本
2.创建用于打包的js文件
创建三个js文件
![image.png](VSCode、JS、Vue简单语法.assets21df5e8b9ce49e18b626275e0d87ada.png)
common.js
```js
exports.info = function(str){
    document.write(str);  //在浏览器上输出
}
```
utils.js
```js
exports.add = function(a,b){
    return parseInt(a) + parseInt(b)
}
```
main.js
```js
const common = require('./common.js')
const utils = require('./utils.js')

common.info("result:" + utils.add(1,2))
```
3.在webpack目录下创建配置文件webpack.config.js
创建webpack配置文件，配置打包信息
```js
const path = require("path"); //Node.js内置模块
module.exports = {
    entry: './src/main.js', //配置入口文件
    output: {
        path: path.resolve(__dirname,'./dist'),//输出路径，_dirname：当前文件所在的路径
        filename: 'bundle.js' //输出文件
    }
}
```

4.执行打包操作
webpack [--mode=development/production]

验证需要编写html文件将打包后的js引入，通过浏览器打开
```js
<script src="./dist/bundle.js"></script>
```

***打包css文件***
1.安装css加载工具
npm install --save-dev style-loader css-loader
2.创建css文件
style.css
```css
body {
    background-color: red
}
```
3.在main.js中引入css文件
```js
//引入js文件
const common = require('./common.js')
const utils = require('./utils.js')
//引入css文件
require('./style.css')

common.info("result:" + utils.add(1,2))
```
4.在webpack.config.js文件中添加css的配置模块module
```js
const path = require("path"); //Node.js内置模块
module.exports = {
    entry: './src/main.js', //配置入口文件
    output: {
        path: path.resolve(__dirname,'./dist'),//输出路径，_dirname：当前文件所在的路径
        filename: 'bundle.js' //输出文件
    },
    module: {
        rules: [
            {
                test: /\.css$/,  //打包规则应用到以css结尾的文件上
                use: ['style-loader','css-loader']
            }
        ]
    }
}
```
