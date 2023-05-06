---
title: Vue项目目录结构
categories:
- 前端
---
Vue是怎么理解的？
渐进式的框架，（React也是一个框架），具有灵活、易用、高效等特点
渐进式：Vue本身实现的功能是有限的，但是相关插件非常多，安装后可以实现更多的功能
1）借鉴angular的模板和数据绑定技术
2）借鉴react的组件化好虚拟DOM技术
模板：
数据绑定
组件化
虚拟DOM
强制数据绑定
双向数据绑定
相关的指令
插件：router，anxios，。。。
2.插值： {{表达式}} ------React中不一样的地方
3.双向数据绑定： v-model
  强制数据绑定： v-bind  简写为：
4.事件指令  v-on  简写为：@
指令：v-if，v-else，v-else-if，v-show，v-for
计算属性和监视
computed：  A数据变化，B数据也自动变化，可以使用计算属性
watch：属性变化后，要实时做相关操作，可以在实例化Vue对象的配置中书写，也可以通过Vue的实例对象.$watch进行配置
5.Vue中目前操作元素的样式：
:class=""
:style=""
都可以使用[]的方式和{}的方式操作样式
class的方式使用的是{}  使用键值对，并且值是boolean类型
style的方式使用的是[]   使用键值对，属性和值的关系（style样式中的属性和值的关系）

**基本配置**
在build中的webpack.base.conf.js中的module.exports中指定启动的src目录。
在config的index.js中autoOpenBrowser属性指定是否自动打开浏览器，useEslint属性指定是否进行语法检查。

目录结构：

├── build/               # 框架的编译工具的脚本文件，不常用
├── dist/                # build 生成的生产环境下的项目，不常用
├── config/               # Vue基本配置文件，可以设置监听端口，打包输出等
├── node_modules/                # 依赖包
├── src/                 # 源码目录（开发的项目文件都在此文件中写）
│   ├── api/            # 定义调用方法
│   ├── assets/            # 放置需要经由 Webpack 处理的静态文件，通常为组件文件和样式类文件，如css，sass以及一些外部的js
│   ├── components/        # 公共组件，每个组件由html模板(模板中只能有一个根标签)、js代码和css样式(scoped是范围，如果父级组件和子级组件中)组成
│   ├── icons/        # 项目使用到的图标
│   ├── filters/           # 过滤器，不常用
│   ├── store/    　　　　 # 状态管理，不常用
│   ├── styles/    　　　　 # 样式文件
│   ├── routes/            # 路由，此处配置项目路由
│   ├── services/          # 服务（统一管理 XHR 请求），不常用
│   ├── utils/             # 工具类 
│   ├── views/             # 路由页面组件
│   ├── App.vue             # 整个项目的根组件
│   ├── main.js             # 入口文件
├── index.html         # 主页，打开网页后最先访问的页面
├── static/              # 放置无需经由 Webpack 处理的静态文件，通常放置图片类资源
├── .babelrc             # Babel 转码配置，部分浏览器不支持ES6，就会自动转为ES3
├── .editorconfig        # 代码格式和配置，如charset=utf-8
├── .eslintignore        # （配置）ESLint 检查中需忽略的文件（夹），不需要框架进行管理
├── .eslintrc            # ESLint 配置
├── .gitignore           # （配置）在上传中需被 Git 忽略的文件（夹）
├── package.json         # 本项目的配置信息，启动方式
├── package-lock.json    # 记录当前状态下实际安装的各个npm package的具体来源和版本号；在不同环境下会自动下载对应的包。
├── README.md         # 项目说明（很重要，便于其他人看懂）
├── webpack.config.js    # 处理项目资源，如处理.vue格式的组件文件，通过vue-loader处理成为浏览器可以识别的文件
.vue结尾的是template/script/style文件
