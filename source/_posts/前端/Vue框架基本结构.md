---
title: Vue框架基本结构
categories:
- 前端
---
Node.js：nodejs是js运行时，运行环境，类比java中jvm。
Npm：node.js一起安装的包管理工具。
Yarn:Yet Another Resource Negotiator，是一个快速、可靠、安全的依赖管理工具，一款新的JavaScript包管理工具。


1.在commons中定义每个组件
2.appVue中设置routerview容器
3.router.js 导入vue和vue-router并且Vue.use(VueRouter)
4.router.js 导入要渲染的组件 bar.vue list.vue foo.vue
5.router.js 配置路由 routes
6.router.js 实例化路由 newVueRouter()
7.router.js 导出router对象
8.main.js 导入router.js
9.main.js newVue对象中挂载router路由
