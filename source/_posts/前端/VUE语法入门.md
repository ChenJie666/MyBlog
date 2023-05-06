---
title: VUE语法入门
categories:
- 前端
---
# 一、HelloWorld
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
</head>
<body>
    <!--将数据渲染到页面上-->
    <div id="app">
        <p>{{title}}</p>
        {{fn1()}}
        {{age}}
        <p>{{age>18?'成年':'未成年'}}</p>
       
        <button v-on:click="fn3()">按钮</button>
    </div>
    
    <!--引入js  "https://cdn.jsdelivr.net/npm/vue/dist/vue.js"-->
<script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
<script>
    var vm = new Vue({
        el:'#app',
        data: {
            title:'helloworld',
            age:15
        },
        methods:{
            fn1:function(){
                console.log("方法调用成功");
            },
            fn2:function(){
                console.log(this)
            },
            fn3:function(){
                this.age=20
            }
        }
    })

    console.log(vm.title)
    console.log(vm.$data.title)
    console.log(vm)
    vm.fn1()
    vm.fn2()
</script>

</body>
</html>
```

<br>
# 二、阻止表单提交
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <form  action="save" v-on:submit.prevent="fn1()">
            <input type="text" id="username" v-model="user.username"></input>
            <button type="submit">保存</button>
        </form>
        {{user}}
    </div>
    <script src="vue.js"></script>
    <!-- <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script> -->
    <script>
        // 创建一个vue对象
        new Vue({
            el: '#app',
            data: {
                user: {username:"CJ",age:28}
            },
            methods:{
                fn1(){
                    if (!this.user.username){
                        alert("请输入用户名")
                    }else{
                        console.log(this.user.username)
                    }
                }
            }
        })
    </script>
</body>
</html>

<!-- 事件修饰符包括 .stop .prevent .capture .self .once .passive -->
```


<br>
# 三、v-test和v-html
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=<device-width>, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <!--都可以替换标签的全部内容，区别是v-test不能识别字符串中的标签，v-html可以识别字符串中的标签-->
        <p v-text="alert">123</p>
        <p v-html="alert">321</p>
    </div>
<script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
<script>
    var vm = new Vue({
        el: "#app",
        data: {
            title: "替换后的数",
            str: "<span style='color:blue'>替换后的数</span>",
            alert: '<span onclick="alert(1)">span标签</sapn>'
        }

    })
</script>

</body>
</html>
```

<br>
# 四、v-if和v-show
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=<device-width>, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <!-- 通过v-if判断条件是否符合，符合则展示标签中的内容 -->
        <p v-if="type ==='A'">{{str1}}</p>
        <p v-else-if="type ==='B'">{{str2}}</p>
        <p v-else>{{str3}}</p>
        <p>{{type}}</p>
        <button @click="fn1()">buttonA</button>
        <button v-on:click="fn2()">buttonB</button>
        <!-- v-show和v-if类似，判断是否符合条件，通过切换标签display属性来展示或隐藏标签 -->
    </div>

    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        var vm = new Vue({
            el: '#app',
            data: {
                str1:"type是A",
                str2:"type是B",
                str3:"type不是AB",
                type:"A"
            },
            methods:{
                fn1(){
                    this.type="B"
                },
                fn2(){
                    this.type="C"
                }
            }
        })
    </script>
</body>
</html>
```

<br>
# 五、v-on和$event
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
</head>
<body>
    
    <div id="app">
        <!-- $event代表当前事件 -->
        <button @click="fn1($event)">控制台打印事件</button>
        <br>
        <br>
        <!-- @事件名.修饰符="methods中的方法"  once和prevent最常用-->
        <button @click.once="fn2('once,只能调用一次')">打印文本</button>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        var vm = new Vue({
            el:'#app',
            data:{

            },
            methods:{
                fn1(e){
                    console.log(e)
                },
                fn2(s){
                    console.log(s)
                }
            }
        })
    </script>

</body>
</html>
```

<br>
# 六、v-for
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <ul>
            <li v-for="item in list">{{item}}</li>
            <br>
            <!-- list类型数组，可以取到每个元素的值和下标 -->
            <li v-for="(item,index) in list">{{item}}---{{index}}</li>
            <br>
            <!-- per类型键值对数据，其结构为value、(value,key)和(value,key,index) -->
            <li v-for="(v,k,i) in per">{{k}}--{{v}}--{{i}}</li>
        </ul>
        <!--除了表格遍历，也可以用<p>标签-->
        <br>
        <p v-for="(v,k,i) in per">{{k}}--{{v}}--{{i}}</p>
        <br>
        <url>
            <!-- key标签中的值是唯一的，作用是：vue渲染页面的时，根据key的标识找到每个元素，效率更高 -->
            <li v-for="(v,k,i) in per" :key="i">{{v}}</li>
        </url>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        var vm = new Vue({
            el: '#app',
            data:{
                list:['查找','增加','修改','删除'],
                per:{
                    id:1,
                    name:'zhangsan',
                    age:'29',
                    gender:'male'
                }
            }
        })
    </script>
</body>
</html>
```

<br>
# 七、v-bind
## 7.1 v-bind.html
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
</head>
<body>
    <!-- v-bind
    作用：绑定标签的任何属性
    场景：当标签的属性值是不确定的，可以修改
    语法：v-bind：要绑定的属性名="data中的数据"
    简写：去掉v-bind，直接 :src 即可
    -->
    <div id="app">
        <p v-bind:id="ID">内容</p>
        <img :src="SRC" alt="蒸虾">

        <!-- 特殊情况是class和style属性，可以有多个值 -->
        <!-- 绑定class方式一：如果为类名为true则生效，类名为false则失效 -->
        <p :class="{name1:a,name2:b}">判断类名是否有效</p>
        <!-- 绑定class方式二：通过给类名变量赋值，传入类名 -->
        <p :class="[n1,n2]">为类名变量赋值</p>
        <!-- 绑定class方式三：整合上两种方式，给类名变量赋值，参数类型为tuple，为true则生效，为false则失效 -->
        <p :class="[nObj1,nObj2]"></p>

        <!-- 绑定style方式一 通过变量为syle属性赋值 -->
        <p :style="{fontSize:f,color:c}">style方式一</p>
        <!-- 绑定style方式二  -->
        <p :style="[d,e]">style方式二</p>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        var vm = new Vue({
            el: "#app",
            data:{
                ID:'newID',
                SRC:"http://116.62.148.11:81/menulist/zhengxia/zhengxia.png",
                a:true,
                b:false,
                n1:"name1",
                n2:"name2",
                nObj1:{
                    name1:false
                },
                nObj2:{
                    name2:true
                },

                f:'30px',
                c:'red',
                d:{
                    fontSize:'30px'
                },
                e:{
                    color:'pink'
                }
            }
        })
    </script>
</body>
</html>
```
## 7.2 v-bind_exam
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
</head>
<style>
    .name{
        color:tomato
    }
</style>
<body>
    <div id="app">
        <p :class="{name:a}">内容</p>
        <button v-on:click="reverseBool()">按钮</button>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        new Vue({
            el:'#app',
            data:{
                a:true
            },
            methods:{
                reverseBool(){
                    this.a = !this.a
                }
            }
        })
    </script>

</body>
</html>

<!--
    动态切换class名:
    1.通过v-bind指令给标签绑定类名，在data中指定变量类型。
    2.设置按钮绑定事件，如果点击按钮会改变类名
    3.如果类名匹配上style中的类名，字体颜色发生改变。

    技巧：可以直接用@click="a=!a" 在指令中设置取反，而不用再写函数。
-->
```

<br>
# 八、v-model
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
</head>
<body>
    <!-- v-model用于表单元素的绑定,表单中元素变化会导致v-model绑定的变量变化 -->
<div id="app">
    {{name}}:
    <input type="text" v-model="name">
    <br>
    <!-- 其他表单元素，多行、单选、复选、下拉等等 -->
    <!-- 多行表单 -->
    {{msg}}
    <textarea v-model="msg"></textarea>
    <br>
    <!-- 单个复选框，绑定bool值 -->
    {{check}}
    <input type="checkbox" v-model="check">
    <br>
    <!-- 多个复选框，绑定数组，数组中会放入选中框的value值 -->
    {{checklist}}
    <input type="checkbox" value="male" v-model="checklist">M
    <input type="checkbox" value="female" v-model="checklist">F
    <input type="checkbox" value="other" v-model="checklist">O
    <br>
    <!-- 单选框,绑定字符串，字符串会被赋值选定的框的value值 -->
    {{picked}}
    <input type="radio" value="查找" v-model="picked">A
    <input type="radio" value="删除" v-model="picked">B
    <br>
    <!-- 下拉框,绑定字符串，字符串会被赋值选定的框的value值 -->
    {{select}}
    <select v-model="select">
        <!-- disabled表示无法选中，select和value为一样都为空，则显示该标签的内容 -->
        <option disabled value="">请选择</option>
        <option value="北京">北京</option>
        <option value="上海">上海</option>
        <option value="杭州">杭州</option>
    </select>

</div>

<script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
<script>
    var vm = new Vue({
        el: "#app",
        data:{
            name: 'name',
            msg: '多行输入框',
            check: true,
            checklist: ["female"],
            picked:'',
            select:''
        }
    })
</script>

</body>
</html>
```

<br>
# 九、v-cloak和v-once
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
    <style>
        [v-cloak]{
            display: none;
        }
    </style>
</head>
<body>
    <div id="app">
        <!-- 解决插值表达式{{}}页面闪烁的问题 
        1.给闪烁的标签设置v-clock
        2.在style样式中指定display为none
        备注：可以直接给div标签添加v-clock属性，即<div id="app" v-cloak>，标签的内容都不会闪烁
        -->
        <p v-cloak>{{msg}}</p>

        <!-- 标签只需要渲染一次，添加v-once指令。那么msg值改变也不会重新渲染 -->
        <p v-once>{{msg}}</p>
        <input type="text" v-model="msg">

    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        new Vue({
            el:"#app",
            data:{
                msg:'解决插值表达式{{}}页面闪烁的问题'
            }
        })
    </script>
</body>
</html>
```

<br>
# 十、example
## 10.1 example.html
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale">
    <!-- border-collapse有两个属性separate/collapse,决定表格的边框是分开的还是合并的 -->
    <style>
        #app {
            width: 600xp;
            margin: 10px auto;
        }

        .tb {
            border-collapse: collapse;
            width: 100%;
        }

        .tb th {
            background-color: #0094ff;
            color: white;
        }

        .tb td,
        .tb th {
            padding: 5px;
            border: 1px solid black;
            text-align: center;
        }

        .add {
            padding: 5px;
            border: 1px solid black;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <!-- <div id="app"> -->
        <div class="add">
            品牌名称：
            <input type="text">
            <input type="button" value="添加">
        </div>

        <div class="add">
            品牌名称：
            <!-- placeholder是占位符 -->
            <input type="text" placeholder="请输入搜索条件">
        </div>

        <div>
            <table class="tb">
                <tr>
                    <!-- th标签会将文本加粗显示 -->
                    <th>编号</th>
                    <th>品牌名称</th>
                    <th>创立时间</th>
                    <th>操作</th>
                </tr>
                <tr>
                    <td>1</td>
                    <td>LV</td>
                    <td>2020-1-1</td>
                    <td>
                        <!-- href是超链接属性,#是无意义的,但是会将文本以超链接的形式展示 -->
                        <a href="#">删除</a>
                    </td>
                </tr>
                <tr>
                    <!-- colspan合并四个单元格 -->
                    <td colspan="4">没有品牌数据</td>
                </tr>
            </table>
        </div>

  <!--  </div>
     <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>

    </script> -->

</body>
</html>
```

## 10.2 example_with_vue.html
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale">
    <!-- border-collapse有两个属性separate/collapse,决定表格的边框是分开的还是合并的 -->
    <style>
        #app {
            width: 600xp;
            margin: 10px auto;
        }

        .tb {
            border-collapse: collapse;
            width: 100%;
        }

        .tb th {
            background-color: #0094ff;
            color: white;
        }

        .tb td,
        .tb th {
            padding: 5px;
            border: 1px solid black;
            text-align: center;
        }

        .add {
            padding: 5px;
            border: 1px solid black;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div id="app">
        <div class="add">
            品牌名称：
            <input type="text" v-model="itemname">
            <input type="button" value="添加" v-on:click="addItem()">
        </div>

        <div class="add">
            品牌名称：
            <!-- placeholder是占位符 -->
            <input type="text" placeholder="请输入搜索条件" v-model="keyword">
        </div>

        <div>
            <table class="tb">
                <tr>
                    <!-- th标签会将文本加粗显示 -->
                    <th>编号</th>
                    <th>品牌名称</th>
                    <th>创立时间</th>
                    <th>操作</th>
                </tr>
                <tr v-for="(item,index) in newlist">
                    <td>{{index+1}}</td>
                    <td>{{item.name}}</td>
                    <td>{{item.date}}</td>
                    <td>
                        <!-- href是超链接属性,#是无意义的,但是会将文本以超链接的形式展示 -->
                        <a href="#" v-on:click.prevent="deleteItem(index)">删除</a>
                    </td>
                </tr>
                <tr v-if="list.length === 0">
                    <!-- colspan合并四个单元格 -->
                    <td colspan="4">没有品牌数据</td>
                </tr>
            </table>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        //模拟ajax返回的数据
        var list = [
            {
                name:'TCL',date:new Date()
            },{
                name:'huawei',date:new Date()
            },{
                name:'xiaomi',date:new Date()
            }
            ]

        var vm = new Vue({
            el: "#app",
            data: {
                list,
                itemname:'',
                keyword:''
            },
            methods:{
                addItem(){
                    //向数组中添加数据
                    this.list.unshift({
                        name:this.itemname,
                        date:new Date()
                        })
                },
                deleteItem(index){
                    if(confirm("确认删除？")){
                        //从数组中删除数据，传参为(索引，长度)
                        this.list.splice(index,1)
                    }
                }
            },
            computed:{
                newlist(){
                    return this.list.filter(item => {
                        return item.name.startsWith(this.keyword)
                    })
                }
            }
        })
    </script>

</body>
</html>

<!--
    整合vue步骤：
    1.在视图中添加div#app
    2.引入vue.js
    3.new Vue({})
    4.Vue实例的选项：el data
    5.在视图中 通过{{}}使用data中的数据
-->
<!--
    渲染步骤：
    1.在data中定义数据
    2.通过v-for指令插入到表格中
    3.在视图中通过插值表达式{{}}使用数据
    4.通过v-if指令判断数据是否存在，如果不存在则显示没有品牌数据
-->
<!--
    添加商品功能：
    1.找到输入框标签，添加v-model="itemname"指令，绑定data中的itemname变量
    2.找到添加按钮 绑定事件 @click="addItem()"，在methods中提供addItem方法，
    向list添加接收到的数据
-->
<!--
    商品删除功能：
    1.找到商品删除标签，添加绑定事件@click.prevent="deleteItem()",
    prevent组织默认行为，此处为跳转连接，仅执行click绑定的方法;
    在methods中提供deleteItem()方法，从list中删除指定的数据，
    可以调用confirm方法弹出确认框。
-->
<!--
    商品搜索功能(输入一个搜索词直接响应结果)：
    1.定义变量通过v-model指令接受输入的搜索词
    2.设置计算属性，通过filter()方法对原数组的元素进行筛选，返回筛选后的数组
    3.通过v-for指令遍历数据渲染到页面
-->
```

## 10.3 example_with_axios.html
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>Document</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale">
    <!-- border-collapse有两个属性separate/collapse,决定表格的边框是分开的还是合并的 -->
    <style>
        #app {
            width: 600xp;
            margin: 10px auto;
        }

        .tb {
            border-collapse: collapse;
            width: 100%;
        }

        .tb th {
            background-color: #0094ff;
            color: white;
        }

        .tb td,
        .tb th {
            padding: 5px;
            border: 1px solid black;
            text-align: center;
        }

        .add {
            padding: 5px;
            border: 1px solid black;
            margin-bottom: 20px;
        }

        [v-cloak]{
            display: none;
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <div class="add">
            品牌名称：
            <input type="text" v-model="itemname">
            <input type="button" value="添加" v-on:click="addItem()">
            <br>
            {{itemname}}
        </div>

        <div class="add">
            品牌名称：
            <!-- placeholder是占位符 -->
            <input type="text" placeholder="请输入搜索条件" v-model="keyword">
        </div>

        <div>
            <table class="tb">
                <tr>
                    <!-- th标签会将文本加粗显示 -->
                    <th>id</th>
                    <th>view_url</th>
                    <th>view_link</th>
                    <th>sequence</th>
                    <th>publish_status</th>
                    <th>create_time</th>
                    <th>update_time</th>
                </tr>
                <tr v-for="(item,index) in newlist">
                    <td>{{item.id}}</td>
                    <td>{{item.viewUrl}}</td>
                    <td>{{item.viewLink}}</td>
                    <td>{{item.sequence}}</td>
                    <td>{{item.publishStatus}}</td>
                    <td>{{item.createTime}}</td>
                    <td>{{item.updateTime}}</td>
                    <td>
                        <!-- href是超链接属性,#是无意义的,但是会将文本以超链接的形式展示 -->
                        <a href="#" v-on:click.prevent="deleteItem(item.id)">删除</a>
                    </td>
                </tr>
                <tr v-if="newlist.length === 0">
                    <!-- colspan合并四个单元格 -->
                    <td colspan="8">没有品牌数据</td>
                </tr>
            </table>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script src="https://unpkg.com/axios/dist/axios.min.js"></script>
    <script>
        var vm = new Vue({
            el: "#app",
            data: {
                list:[],
                itemname:'',
                keyword:'',
                viewpager:[]
            },
            methods:{
                addItem(){
                    //发送添加数据请求
                    axios.post("http://192.168.32.223:8002/menu/addViewPager/",this.itemname)
                        .then((res)=>{
                            const{status,data} = res
                            if(status === 200){
                                alert(this.itemname+"---添加成功")
                                this.findAllViewPager()
                            }
                        })
                        .catch((err)=>{

                        })                    
                },
                deleteItem(id){
                    if(confirm("确认删除？")){
                        //发送删除数据请求，传参为(索引，长度)，并重新获取数据
                        axios.delete("http://192.168.32.223:8002/menu/deleteViewPager?viewPagerId="+id)
                        .then((res)=>{
                            const{status,data} = res
                            if(status === 200){
                                alert("删除成功")
                                this.findAllViewPager()
                            }
                        })
                        .catch((err)=>{

                        })
                    }
                },
                //通过axios获取后台数据
                findAllViewPager(){
                    axios.get("http://192.168.32.223:8002/menu/findAllViewPager")
                        .then((res)=>{
                            const{status,data} = res
                            console.log(data)
                            if(status === 200){
                                this.viewpager=data.data
                            }
                        })
                        .catch((err)=>{
                            console.log(err)
                        })
                }
            },
            computed:{
                newlist(){
                    return this.viewpager.filter(item => {
                        return item.viewLink.startsWith(this.keyword)
                    })
                }
            },
            created(){
            // mounted(){
                this.findAllViewPager()
            }
        })
    </script>

</body>
</html>

<!--
    整合vue步骤：
    1.在视图中添加div#app
    2.引入vue.js
    3.new Vue({})
    4.Vue实例的选项：el data
    5.在视图中 通过{{}}使用data中的数据
-->
<!--
    渲染步骤：
    1.在data中定义数据
    2.通过v-for指令插入到表格中
    3.在视图中通过插值表达式{{}}使用数据
    4.通过v-if指令判断数据是否存在，如果不存在则显示没有品牌数据
-->
<!--
    添加商品功能：
    1.找到输入框标签，添加v-model="itemname"指令，绑定data中的itemname变量
    2.找到添加按钮 绑定事件 @click="addItem()"，在methods中提供addItem方法，
    向list添加接收到的数据
-->
<!--
    商品删除功能：
    1.找到商品删除标签，添加绑定事件@click.prevent="deleteItem()",
    prevent组织默认行为，此处为跳转连接，仅执行click绑定的方法;
    在methods中提供deleteItem()方法，从list中删除指定的数据，
    可以调用confirm方法弹出确认框。
-->
<!--
    商品搜索功能(输入一个搜索词直接响应结果)：
    1.定义变量通过v-model指令接受输入的搜索词
    2.设置计算属性，通过filter()方法对原数组的元素进行筛选，返回筛选后的数组
    3.通过v-for指令遍历数据渲染到页面
-->
<!-- 
    通过axios对viewpager进行增删改查操作：
    ①查:创建axios请求方法，将结果赋值给变量，通过mounted调用该方法，将结果进行遍历
    ②增：
 -->
```

<br>
# 十一、mounted自动获取焦点
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <!-- 需要给dom元素设置ref属性，mounted方法可以更加ref属性拿到对应的dom -->
        <input type="text" ref="foc">        
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        new Vue({
            el: "#app",
            data:{

            },
            methods:{

            },
            //该方法会在页面渲染完成后调用，取到对应名字的dom，调用focus方法完成自动聚焦
            mounted(){
                console.log(this.$refs.foc)
                this.$refs.foc.focus()
            }
        })
    </script>
</body>
</html>
```

<br>
# 十二、插件
## 12.1 自定义插件
**定义插件**
```
(function (window)){
  const MyPlugin = {}
  MyPlugin.install = function(Vue) {
    //1.定义一个全局方法
    Vue.myGlobalMethod = function(){
      console.log('全局的方法')
    }
    //2.定义一个指令
    Vue.directive('upper',function(el,binding){
      console.log('哈哈')
    })
    //3.定义一个实例方法
    Vue.prototype.$myMethod = function(){
      console.log('我是一个实例方法')
    }
  }

  //暴露出
  window.MyPlugin = MyPlugin
}(window)
```

**使用插件**
```
<body>
  <div id="app">
    <p v-upper="msg"></p>
  </div>

  <script src="./vue-myPlugin.js"></script>
  <script type="text/javascript">
    //Vue.use 内部会安装插件，内部调用install
    Vue.use(MyPlugin)
    //可以调用全局的方法
    Vue.myGlobalMethod()
    //局部方法的调用
    const vm = new Vue({
      el: "#app",
      data: {
        msg: ''
      }
    })
    vm.$myMethod()
  </script>
```

## 12.2 directives自定义focus指令_全局
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <input type="text" v-focus>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        //全局自定义指令(设置自定义聚焦指令v-focus)
        //1.在new Vue之前，Vue.directive('指令名',{inserted(el){}})
        //2.inserted(el){自定义指令具体功能}
        //使用该指令的dom元素被插入到页面汇中时，会自动触发inserted
        //3.在视图中v-指令名
        //获取焦点
        Vue.directive('focus',{
                inserted(el){
                    console.log(el)
                    el.focus()
                }
        })
        new Vue({
            el: "#app"
        })
    </script>
</body>
</html>
```

## 12.3 directives自定义focus指令_局部
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <input type="text" v-focus>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        new Vue({
            el:"#app",
            data:{

            },
            directives:{
                focus:{
                    inserted(el){
                        console.log(el)
                        el.focus()
                    }
                }
            }
        })
    </script>
</body>
</html>

<!-- 局部指令只能在绑定的DOM中使用，全局指令可以在任何DOM中使用 -->
```


<br>
# 十三、过滤器
## 13.1 过滤器_全局
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <style>
        [v-cloak]{
            display: none;
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <p>{{msg | toUpper}}</p>
        <p>{{date | fmtDate("日期：")}}</p>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script src="https://unpkg.com/moment"></script>
    <script>
        //全局过滤器,可以使用在插值{{}}和v-bind中
        //需要定义在new Vue之前
        Vue.filter('toUpper',(v)=>{
            return v.toUpperCase()
        })
        Vue.filter('fmtDate',(v,k)=>{
            return k + moment(v).format('YYYY-MM-DD hh:mm:ss')
            // return dateFormat("YYYY-MM-DD hh:mm:ss",this.date)
        })

        new Vue({
            el:"#app",
            data:{
                msg:"abc",
                date:new Date()
            }
        })
    </script>
</body>
</html>
```

## 13.2 过滤器_局部
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <style>
        [v-cloak]{
            display: none;
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <p>{{date | fmtDate("date：")}}</p>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script src="https://unpkg.com/moment"></script>
    <script>
        new Vue({
            el:"#app",
            data:{
                date:new Date()
            },
            filters:{
                //第一个参数是传入的值，后续是自定义参数
                fmtDate(v,k){
                    return k + moment(v).format('YYYY-MM-DD hh:mm:ss')
                }
            }
        })
    </script>
</body>
</html>
```

<br>
# 十四、计算属性和watch监视
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <!-- 调用计算属性 -->
        <p>{{reverseMessage}}</p>
        <input type="text" placeholder="显示计算后的结果" v-model="reverseMessage"></input>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        new Vue({
            el:"#app",
            data:{
                msg:"hello world !",
                reverseMessage1,
                reverseMessage2
            },
            //如果没有依赖data中的数据，第一次使用计算属性时，会把第一次的结果进行缓存。
            computed:{
                //定义计算方法
                reverseMessage(){
                    //this是指当前的vue对象，此处表示计算属性的get方法
                    return this.msg.split(' ').reverse().join(' ')
                },
                reverseMessage1(){
                    //计算属性包括get和set方法
                    get(){
                        return this.msg.split(' ').reverse().join(' ') 
                    },
                    set(val){
                        //val就是传入的reverseMessage1的值,当改变计算属性的值时，会调用该方法处理逻辑。
                        const m=val.split(' ')
                        this.msg=m.reverse().join(' ')
                    }
                }
            },
            //监视：监视msg,如果msg改变，则调用该方法处理逻辑
            watch: {
              msg(val){
                  this.reverseMessage1=val.split(' ').reverse().join(' ')
              }
            }
        })
        //通过vm实例对象来调用watch方法进行监视。$watch是vue的一个实例属性，vue有许多实例属性和实例方法。如果没有$符号，说明是全局属性方法。
        vm.$watch('msg',function(val){
            this.reverseMessage2=val.split(' ').reverse().join(' ')
        })
    </script>

</body>
</html>
<!-- 计算属性：当某个属性的值改变，何其相关联的属性的值也会自动发生改变 -->
<!-- 使用Object.defineProperty(obj, prop, descriptor)可以为已经定义的对象类添加计算属性，设置set和get方法，当属性发生变化时， -->
<!-- 搜索MDN网站可以查询到所有的前端方法的使用 -->
<!-- 计算属性和监视都可以实现某属性发生改变，另一个属性也发生变化的情况。 -->
```

<br>
# 十五、axios
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">

    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script src="https://unpkg.com/axios/dist/axios.min.js"></script>
    <script>
        //get请求
        axios.get("http://192.168.32.223:8002/menu/findViewPager")
            .then((res)=>{
                //console.log(res)
                const{status,data} = res
                if(status===200){
                    console.log(data)
                }
            })
            .catch((err)=>{})
        // post请求
        // axios.post("http://192.168.32.223:8002/menu/addViewPager/",{
        //             "viewUrl": "https://192.168.32.223/hxr.png",
        //             "viewLink": "https://www.marssenger.com/welcome.html",
        //             "sequence": "7",
        //             "publishStatus": "1"
        //         })
        //         .then((res)=>{
        //             const{status,data} = res
        //             if(status===200){
        //                 console.log("添加成功")
        //             }
        //         })
        //         .catch((err)=>{
                    
        //         })
        
        //delete请求
        // axios.delete("http://192.168.32.223:8002/menu/deleteViewPager?viewPagerId=74")
        //         .then((res)=>{
        //             const{status,data} = res
        //             if(status === 200){
        //                 console.log("删除成功")
        //             }
        //         })
        //         .catch((err)=>{

        //         })

        new Vue({
            el: "#app",
            data:{

            }
        })
    </script>

</body>
</html>
```

<br>
# 十六、异步操作和watch
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <input type="text" v-model="msg">
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        new Vue({ 
            el: "#app",
            data: {
                msg: ''
            },
            //watch可以监测已经存在的属性，记录新值和旧值
            //使用场景：当需要在数据变化时执行异步或开销比较大的操作时使用（如进行关键字搜索时，就需要watch监控输入的关键字变化，检测到关键字变化就通过关键字发送请求）
            watch: {
                msg(newVal,oldVal){
                    console.log(newVal,oldVal);
                }
            }
        })
    </script>
</body>
</html>

<!--
    异步操作包括1.ajax 2.定时器 3.click事件 4.数据库操作
-->
```

<br>
# 十七、component组件
## 17.1 component组件_全局
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <span-btn></span-btn>
        <span-btn></span-btn>
        <span-btn></span-btn>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        //全局组件：1.在newVue之前定义 2.命名规范：xxx-xx 3.全局组件可以用在局部组件中
        //将共同的结构提取出来创建组件，组件可以复用，组件之间相互独立
        //组件可以让我们复用已有的html、css、js
        Vue.component('span-btn',{
            template:
                //要求有一个根元素
                `
                <div>
                <span>{{count}}</span> 
                <button v-on:click="changeCount">按钮</button>
                <br>
                </div>
                `
                ,
            //data数据必须是一个函数且只有一个返回值，这样每个组件的数据都有自己的作用域
            data(){
                return{
                    count:0
                }
            },
            methods:{
                changeCount(){
                    this.count++
                }
            }
        });

        new Vue({
            el:"#app"
        })
    </script>
</body>
</html>
```

## 17.2 component组件_局部
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <span-btn></span-btn>
        <span-btn></span-btn>
        <span-btn></span-btn>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
    
        new Vue({
            el:"#app",
            data:{

            },
            components:{
                //局部组件：1.在newVue之内定义 2.命名规范：xxx-xx 3.可以在局部组件中调用全局组件
                //将共同的结构提取出来创建组件，组件可以复用，组件之间相互独立
                //组件可以让我们复用已有的html、css、js
                'span-btn':{
                    template:
                        //要求有一个根元素
                        `
                        <div>
                            <span>{{count}}</span> 
                            <button v-on:click="changeCount">button</button>
                            <br>
                        </div>
                        `
                        ,
                    //data数据必须是一个函数且只有一个返回值，这样每个组件的数据都有自己的作用域
                    data(){
                        return{
                            count:0
                        }
                    },
                    methods:{
                        changeCount(){
                            this.count++
                        }
                    }
                }
            }
        })
    </script>
</body>
</html>
```

<br>
# 十八、父子组件数据传递
## 18.1 父子组件数据传递_全局
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <child-a v-bind:a="msg"></child-a>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        //情况一：父组件传值给子组件,自组价为全局组件
        Vue.component("child-a",{
            template:
            `
                <div>我是childa子组件--{{a}}</div>
            `,
            //通过data函数定义的值的作用域在自己对象中
            //props选项设置标签的属性，可以在标签中传值
            //props中的属性可以在组件中使用
            props:['a']
        })

        //Vue相当于所有组件的父组件
        new Vue({
            el:"#app",
            data:{
                msg:"父组件传值给全局子组件成功"
            }
        })
    </script>    
</body>
</html>

<!--
    在子组件中使用父组件的值：
    1.在自组件中定义props属性，为组件标签设置属性变量。在组件内就可以使用这个变量。
    2.在父组件中定义变量的值，通过v-bind指令将值赋值给属性。
-->
```

## 18.2 父子组件数据传递_局部
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <child-a v-bind:a="msg"></child-a>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        //Vue相当于所有组件的父组件
        new Vue({
            el:"#app",
            data:{
                msg:"父组件传值给局部子组件成功"
            },
            //情况二：父组件传值给子组件，子组件为局部组件
            components:{
                "child-a":{
                    template:
                    `
                    <div>我是child-a子组件--{{a}}</div>
                    `
                    ,
                    props:['a']
                }
            }

        })
    </script>    
</body>
</html>

<!--
    在子组件中使用父组件的值：
    1.在自组件中定义props属性，为组件标签设置属性变量。在组件内就可以使用这个变量。
    2.在父组件中定义变量的值，通过v-bind指令将值赋值给属性。
-->
```

<br>
# 十九、动态路由
## 19.1 动态路由
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <router-link to="/basketball">篮球</router-link>
        <router-link to="/football">足球</router-link>
        <router-link to="/tennis">网球</router-link>

        <router-view></router-view>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script src="https://unpkg.com/vue-router/dist/vue-router.js"></script>
    <script>
        var Ball = {
            template: `<div>球类运动:{{$route.params.content}}</div>`
        }

        var router = new VueRouter({
            routes:[
                {
                    //动态路由，匹配/:前面的路径并将传参到/:后面的变量
                    path:'/:content',
                    component: Ball
                }
            ]
        })

        new Vue({
            el:"#app",
            router:router
        })
    </script>
    
</body>
</html>

<!-- 
    动态路由使用场景：如"/:id"，id处是传入的参数，所有id都会加载同一个组件，
    但是会根据id不同展示不同的内容。如知乎页面中点击不同的详情页，组件相同，
    但是展示不同的内容。
    1.通过<router-link to="/aaa">AAA</router-link>绑定跳转
    2.<router-view></router-view>即是组件的位置
    3.路由实例化，将哈希路径和自定义的组件绑定在一起，一旦哈希变化，就会渲染为哈希对应的组件
    4.在vue中挂载创建的路由对象
-->
```

## 19.2 路由vue-router-to属性
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <!-- 通过不同的to属性写法匹配组件 -->
        <!-- 写死路径进行匹配 -->
        <router-link to="/aaa">AAA</router-link>
        <!-- 通过v-bind传入参数 -->
        <router-link :to="user">BBB</router-link>
        <!-- 传入对象,通过path匹配可以省略#和/ -->
        <router-link :to="{path:'ccc'}">CCC</router-link>
        <!-- 传入对象，通过name进行匹配(#和/不能省略) -->
        <router-link :to="{name:'xxx'}">DDD</router-link>

        <router-view></router-view>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script src="https://unpkg.com/vue-router/dist/vue-router.js"></script>
    <script>
        var comA = {
            template:`<div>AAAAA</div>`
        }
        var comB = {
            template:`<div>BBBBB</div>`
        }
        var comC = {
            template:`<div>CCCCC</div>`
        }
        var comD = {
            template:`<div>DDDDD</div>`
        }

        var router = new VueRouter({
            routes:[
                {
                    path: '/aaa',
                    component: comA                
                },
                {
                    path: '/bbb',
                    component: comB
                },
                {
                    path: '/ccc',
                    component: comC
                },
                {
                    name: 'xxx',
                    path: '/dd',
                    component: comD
                }
            ]
        })

        new Vue({
            el:"#app",
            router:router,
            data:{
                user:'bbb'
            }
        })

    </script>
    
</body>
</html>
```

## 19.3 路由-view-router
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
    <!-- <ul>
        <li><a href="#/aaa">AAA</a></li>
        <li><a href="#/bbb">BBB</a></li>
        <li><a href="#/ccc">CCC</a></li>
    </ul>
    <div id="container"> -->
        <!-- 通过router提供的标签实现路由 -->
        <router-link to="/aaa">AAA</router-link>
        <router-link to="/bbb">BBB</router-link>
        <router-link to="/ccc">CCC</router-link>

        <!-- <div id="container">
        </div> -->
        <!-- 通过router提供的标签设置组件容器 -->
        <router-view></router-view>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script src="https://unpkg.com/vue-router/dist/vue-router.js"></script>
    <script>
        //提供组件(也可以直接写到router中)
        var comA = {
            template: `<div>AAAAA</div>`
        }
        var comB = {
            template: `<div>BBBBB</div>`
        }
        var comC = {
            template: `<div>CCCCC</div>`
        }
        //路由的实例化
        var router = new VueRouter({
            routes:[
                {
                    //配置路由,根据路径配置不同的路由
                    path:'/aaa',
                    component:comA
                },
                {
                    //配置路由
                    path:'/bbb',
                    component:comB
                },
                {
                    //配置路由
                    path:'/ccc',
                    component:comC
                }
            ]
        })
        //在vue对象中挂载路由
        new Vue({
            el:"#app",
            router:router
        })

    </script>
</body>
</html>

<!--
    通过vue-router.js模块提供的标签实现路由(引入vue-router的CDN路径)：
    1.通过<router-link to="/aaa">AAA</router-link>绑定跳转
    2.<router-view></router-view>即是组件的位置
    3.路由实例化，将哈希路径和自定义的组件绑定在一起，一旦哈希变化，就会渲染为哈希对应的组件
    4.在vue中挂载创建的路由对象
-->
```

## 19.4 原生命令实现前端路由
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <ul>
            <!-- #aaa表示location中的哈希路由，会在原路径下添加#aaa -->
            <li><a href="#/aaa">AAA</a></li>
            <li><a href="#/bbb">BBB</a></li>
            <li><a href="#/ccc">CCC</a></li>
        </ul>
        <div id="container">
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        //获取标签元素
        var div = document.getElementById('container')
        //监听窗口的hash值是否改变，如果发生改变，会触发方法
        window.onhashchange = function(){
            var hash = location.hash
            console.log(hash)

            hash = hash.replace("#","")
            console.info(hash)
            switch(hash){
                case '/aaa':
                    div.innerText = "AAAAA"
                    break;
                case '/bbb':
                    div.innerText = "BBBBB"
                    break;
                case '/ccc':
                    div.innerText = "CCCCC"
                    break;
                default:
                    break;
            }
        }

      
    </script>

</body>
</html>

<!--
    过程：
    1.点击超链接后改变url的标识 
    2.通过window.onhashchange监听标识变化，发生变化则回调函数进行处理
    3.函数中根据location.hash获取hash值，渲染对应的组件或内容
-->
```

<br>
# 二十、路由
## 20.1 路由vue-router-重定向
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        <router-link to="/aaa">首页</router-link>
        <router-link to="/bbb">热点</router-link>
        <router-link to="/ccc">简讯</router-link>
        <br>
        <router-view></router-view>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script src="https://unpkg.com/vue-router/dist/vue-router.js"></script>
    <script>
        var comA = {
            template:`<dev>comA</dev>`
        }
        var comB = {
            template:`<dev>comB</dev>`
        }
        var comC = {
            template:`<dev>comC</dev>`
        }

        var router = new VueRouter({
            routes:[
                //对请求路径的哈希为'/'的所有请求都重定向到'/aaa'
                //通过path属性进行绑定
                {
                    path:'/',
                    redirect:{
                        path:'/aaa'
                    }
                },
                //通过name属性进行绑定
                {
                    path:'/aaa',
                    redirect:{
                        name:'bbb'
                    }
                },

                {
                    path: '/aaa',
                    component: comA
                },
                {
                    name: 'bbb',
                    path: '/bbb',
                    component: comB,
                    //redirect也可以写在这里
                    redirect:{
                        path: '/ccc'
                    }
                },
                {
                    path: '/ccc',
                    component: comC
                },
                //如果用户输入的路由有误，那么直接重定向到主页
                //需要注意放置的顺序，从上到下进行匹配,重定向后重新走一遍匹配规则
                {
                    path: '*',
                    redirect: {
                        path: '/aaa'
                    }
                }
            ]
        })

        new Vue({
            el: "#app",
            router:router
        })
    </script>
</body>
</html>

<!-- 
    重定向：强制修改url标识，重新发起请求
    1.在路由的实例化中将需要重定向的路径redirect到目标路径
-->
```

## 20.2 不通过router-link改变标识
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <!-- 为选中的标签添加样式 -->
    <style>
        .router-link-exact-active.router-link-active{
            color:blue;
        }
    </style>
</head>
<body>
    <div id="app">
        <!-- 将最终的默认的标签<a></a>改为<span></span> -->
        <router-link to="/aaa" tag="span">AAA</router-link>
        <router-link to="/bbb">BBB</router-link>
        <button @click="changeUrl()">音乐</button>
        <br>
        <router-view></router-view>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script src="https://unpkg.com/vue-router/dist/vue-router.js"></script>
    <script>
        var comA = {
            template: `<div>comA组件</div>`
        }
        var comB = {
            template: `<div>comB组件</div>`
        }
        var comC = {
            template: `<div>comC组件</div>`
        }

        var router = new VueRouter({
            routes:[
                {
                    path:"/aaa",
                    component:comA
                },
                {
                    path:"/bbb",
                    component:comB
                },
                {
                    path:"/ccc",
                    component:comC
                }
            ]
        })

        new Vue({
            el: "#app",
            router:router,
            methods:{
                changeUrl(){
                    //获取路由对象，改变路由的标识，并渲染对应的组件
                    this.$router.push("/ccc")
                }
            }
        })
    </script>
    
</body>
</html>

<!--
    1.可以通过设置事件调用this.$router.push("")方法，改变路由的标识，并渲染对应的组件。
    2.<router-link to=""><router-link>标签在前端页面中最终会变成<a></a>标签，
    可以设置tag属性<router-link to="/aaa" tag="span">AAA</router-link>改为<span></span>标签，
    如果选中了标签，会自动设置类名，变成<a href="#/aaa" class="router-link-exact-active router-link-active"></a>
    可以通过类名来锁定点击的标签，通过style样式进行渲染。   
-->
``` 

<br>
# 二十一、路由的嵌套_二级路由
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <style>
        .router-link-exact-active.router-link-active{
            color: crimson;
        }
        /*float: left标签显示在一行；list-style: none去掉文字前的圆点*/
        li{
            float: left;
            list-style: none;
        }
        /*text-decoration: none去掉下划线*/
        a{
            text-decoration: none;
        }
        .container{
            height: 100px;
            border: 1px solid black;
        }
        /*clear: both清除前面设置的float:left*/
        .container-sub{
            clear: both;
            height: 50px;
            border: 1px solid green
        }
        *{
            padding: 0;
            margin: 0;
        }
    </style>
</head>
<body>
    <div id="app">
        <ul>
            <router-link to="/home" tag="li"><a>首页</a></router-link>
            <router-link to="/hot" tag="li"><a>热点</a></router-link>
            <router-link to="/music" tag="li"><a>音乐</a></router-link>
        </ul>
        <br>
        <!--给组件设置样式-->
        <router-view class="container"></router-view>


    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script src="https://unpkg.com/vue-router/dist/vue-router.js"></script>
    <script>
        //一级组件的渲染
        var home = {
            template: `<div>首页首页</div>`
        }
        var hot = {
            template: `<div>热点热点</div>`
        }
        var music = {
            template: 
            `<div>
                <router-link to="/music/classic" tag="li"><a>古典</a></router-link>
                <router-link to="/music/pop" tag="li"><a>流行</a></router-link>
                <router-link to="/music/jazz" tag="li"><a>爵士</a></router-link> 
                <br>
                <router-view class="container-sub"></router-view>
            </div>`
        }
        //二级组件的渲染
        var musicsub = {
            template:
            `
            <div>musicsub:{{this.$route.params.id}}</div>
            `
        }

        var router = new VueRouter({
            routes:[
                {
                    name:'home',
                    path:'/home',
                    component:home
                },
                {
                    name:'hot',
                    path:'/hot',
                    component:hot
                },
                {
                    name:'music',
                    path:'/music',
                    component:music,
                    //children用法和routes是一样的
                    children:[
                        {
                            path:'/music/:id',
                            component:musicsub
                        }
                    ]
                }
            ]
        })


        new Vue({
            el: "#app",
            router:router
        })
    </script>
</body>
</html>

<!--
    将一级路由中的组件中再添加一个组件。
    在路由对象中添加children属性，绑定二级路由的路径和组件。
-->
```

<br>
# 二十二、动画
## 22.1 过渡和动画
**transition是Vue的内置组件**
```
<head>
  <title></titile>
  <link rel"stylesheet" href="">
  <script type="text/javascript" src="../js/vue.js"></script>
  <style type="text/css">
     /*淡入淡出效果*/
    .fade-enter-active,.fade-leave-active{
      transition: opacity .5s;
    }
    .fade-enter,.fade-leave-to{
      opaicty: .5s;
    }
  </style>
</head>

<div id="app">
  <button @click="isOk=!isOk">切换效果</button>
  <transition name="fade">
    <p v-show="isOk">过渡效果演示</p>
  </transition>
</div>

<script type="text/javascript">
  const vm = new Vue({
    el: "#app",
    data: {
      isOk: false  
    }
  })
</script>
```
>**从无到有：**本身是隐藏的，点击按钮显示出来
.fade-enter  一开始进入的状态
.fade-enter-active   从无到有的时候的效果
.fade-enter-to  从无到有的结束的效果
>
>.fade-leave  最开始有的时候的状态
.fade-leave-active  从有到无的过渡的效果
.fade-leave-to  没有的时候的效果

![image.png](https://upload-images.jianshu.io/upload_images/21580557-04d0c1bd9419b195.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

```
/*平移效果*/
p {
  background-color: green;
  width: 100px;
  text-align: center;
}
.myFade-enter-active{
  transition: all 2s;
}
.myFade-leave-active{
  transition: all 3s;
}
.myFade-enter,.myFade-leave-to{
  transform: translateX(20px)
}

/*动画效果*/
p {
  background-color: green;
  width: 100px;
  text-align: center;
}
/*显示状态效果*/
.bound-enter-active{
  animation: bounce-in .5s
}
/*隐藏状态效果*/
.bounce-leave-active{
  animation: bounce-in .5s reverse;
}
/*动画,scale表示缩放倍数*/
@keyframe bounce-in{
  0%{
    transform: scale(0)
  }
  50%{
    transform: scale(2)
  }
  100%{
    transform: scale(1)
  }
}
```

## 22.2 过渡动画
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <!--<link rel="stylesheet" href="https://unpkg.com/animate.css@3.5.2/animate.min.css">
    -->   <style>
        /*设置从右侧模糊进入和从右侧模糊退出的动画*/
        * {
            padding: 0;
            margin: 0;
        }
        .test{
            width: 100px;
            height: 100px;
            background-color: coral;
            position: absolute;
            left: 0;
        }
        .v-enter,.v-leave-to{
            opacity:0;
            left:300px;
        }
        .v-enter-to,.v-leave{
            opacity:1;
            left:0px;
        }
        .v-enter-active,.v-leave-active{
            transition: all 1s;
        }
    </style>
</head>
<body>
    <div id="app">
        <button @click="isShow = !isShow">按钮</button>
        <!-- 给需要过渡效果的元素(插入或移除的元素)外层包裹组件 transition -->
        <transition>
            <div class="test" v-if="isShow">content</div>
        </transition>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <!--<script src="https://unpkg.com/animate.css@3.5.2/animate.min.css"></script>-->
    <script>
        new Vue({
            el: "#app",
            data: {
                isShow:false
            },
            methods:{

            }
        })
    </script>
</body>
</html>
```

## 22.3 第三库的过度动画
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <!-- 引入第三方库Animate -->
    <link rel="stylesheet" href="https://unpkg.com/animate.css@3.5.2/animate.min.css">
    <style>
        * {
            margin: 15px;
            padding: 0px;
        }
    </style>
</head>
<body>
    <div id="app">
        <button @click="isShow = !isShow">按钮</button>
        <!-- 给需要过渡效果的元素(插入或移除的元素)外层包裹组件 transition -->
        <transition
            enter-active-class="animated tada"
            leave-active-class="animated bounceOutRight"
        >
            <div class="test" v-if="isShow">content</div>
        </transition>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        new Vue({
            el: "#app",
            data: {
                isShow:false
            },
            methods:{

            }
        })
    </script>
</body>
</html>
```

<br>
#二十三、钩子函数
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    <div id="app">
        
    </div>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script>
        var vm = new Vue({
            el: "#app",
            data: {
                message: "vue的生命周期",
            },
            beforeCreate: function(){
                console.group('--beforeCreate创建前的状态---');
                console.log("%c%s","color:red","el  :"+this.$el);//el未定义
                console.log("%c%s","color:red","data:"+this.$data);//data未定义
                console.log("%c%s","color:red","message:"+this.message);
            },
            created: function(){
                console.group('--create创建后的状态---');
                console.log("%c%s","color:red","el  :"+this.$el);//el未定义
                console.log("%c%s","color:red","data:"+this.$data);//data未定义
                console.log("%c%s","color:red","message:"+this.message);
            },
            beforeMount: function(){
                console.group('--beforeMount挂载前的状态---');
                console.log("%c%s","color:red","el  :"+this.$el);//el未定义
                console.log("%c%s","color:red","data:"+this.$data);//data未定义
                console.log("%c%s","color:red","message:"+this.message);
            },
            mounted: function(){
                console.group('--mounted挂载后的状态---');
                console.log("%c%s","color:red","el  :"+this.$el);//el未定义
                console.log("%c%s","color:red","data:"+this.$data);//data未定义
                console.log("%c%s","color:red","message:"+this.message);
            },
            beforeUpdate: function(){
                console.group('--beforeUpdate更新前的状态---');
                console.log("%c%s","color:red","el  :"+this.$el);//el未定义
                console.log("%c%s","color:red","data:"+this.$data);//data未定义
                console.log("%c%s","color:red","message:"+this.message);
            },
            updated: function(){
                console.group('--updated更新后的状态---');
                console.log("%c%s","color:red","el  :"+this.$el);//el未定义
                console.log("%c%s","color:red","data:"+this.$data);//data未定义
                console.log("%c%s","color:red","message:"+this.message);
            },
            beforeDestroy: function(){
                console.group('--beforeDestroy销毁前的状态---');
                console.log("%c%s","color:red","el  :"+this.$el);//el未定义
                console.log("%c%s","color:red","data:"+this.$data);//data未定义
                console.log("%c%s","color:red","message:"+this.message);
            },
            destroyed: function(){
                console.group('--destroyed销毁后的状态---');
                console.log("%c%s","color:red","el  :"+this.$el);//el未定义
                console.log("%c%s","color:red","data:"+this.$data);//data未定义
                console.log("%c%s","color:red","message:"+this.message);
            }
        })
    </script>
    
</body>
</html>
```

![image.png](https://upload-images.jianshu.io/upload_images/21580557-b80837b36f728204.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

**分为四个阶段：开始、结束、界面加载、数据更新**
**created之后vue对象初始化完成，mounted之前在虚拟dom中完成对展示页面的内容解析替换，mounted之后完成虚拟dom放入真实标签页中。**

<br>
# 二十四、 按键修饰符
```
<div id="app">
  <input type="text" value="" v-model="msg" @keyup="handle1">
  <input type="text" value="" v-model="msg" @keyup.enter="handle2">
  <input type="text" value="" v-model="msg" @keyup.13="handle3">
</div>

const vm = new Vue({
  el: '#app',
  data: {
    msg: '请输入'
  },
  methods: {
    handle1(e) {
      if (e.keyCode === 13) {
        console.log('按下回车了')
      }
    },
    handle2(e) {
      console.log('按下回车了')
    },
    handle3(e) {
      console.log('按下回车了')
    },
  }
})

<!-- 按键修饰符用于判断用户输入的按键  .enter   .tab   .delete(捕获删除和退格键)   .esc   .space   .up   .down   .left   .right -->
```

<br>
# 二十五、定时器
```
const vm = new Vue({
  el: '#app',
  data: {
    isOk: false
  }
  //界面加载后有定时器,，操作isOk的状态值，定时为1s
  mounted(){
    setInterval(()=>{
      this.isOk = !this.isOk
    },1000);  
  },
  //销毁实例对象之前调用
  beforeDestroy(){
    //销毁定时器
    clearInterval(this.timeId)
  }
  methods: {
    clear(){
      //销毁实例对象
      this.$destroy()
    }  
  }
})
```

**定时器是window中的方法，与vm实例无关。
所以需要在销毁实例之前将定时器清除，在beforeDestroy()生命周期函数中调用clearInterval()方法。**

**vm.$destroy()
完全销毁一个实例。清理它与其它实例的连接，解绑它的全部指令及事件监听器。**

[https://cn.vuejs.org/v2/api/](https://cn.vuejs.org/v2/api/)
