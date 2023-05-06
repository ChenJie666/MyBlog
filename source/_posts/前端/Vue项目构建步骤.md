---
title: Vue项目构建步骤
categories:
- 前端
---
在build中的webpack.base.conf.js中的module.exports中指定启动的src目录。
在config的index.js中autoOpenBrowser属性指定是否自动打开浏览器，useEslint属性指定是否进行语法检查。

**创建新vue项目**
安装vue-cli
>npm install -g vue-cli 
通过webpack脚手架创建Vue项目
>vue init webpack my-project (如果失败，可以下载webpack到本地，用webpack的绝对路径)
启动本地测试模式
>npm run dev(或npm start)
打包，生成dist目录
>npm run build
打包后运行项目
>serve dist


###登录过程：
api下的login.js提供了异步请求的login和getInfo方法，在config下的dev.env.js中定义了路径变量。
在utils下的request.js中封装了axios实例，并定义了拦截器，成功响应码为20000。
在store/modules下的user.js中调用了login和getInfo方法获取用户信息，写入到常量中。
在views下的index.vue中调用utils下的validate.js的isvalidUsername方法对用户名进行合法校验。

###添加页面过程：
1.添加路由：在router下的index.js中添加路由，在路由中导入在views中完成的页面
```js
  {
    path: '/bookkeep',
    component: Layout,
    redirect: '/example/table',
    name: '账单管理',
    meta: { title: '账单管理', icon: 'example' },
    children: [
      {
        path: 'table',
        name: '账单列表',
        component: () => import('@/views/bookkeep/list'),
        meta: { title: '账单列表', icon: 'table' }
      },
      {
        path: 'add',
        name: '添加账单',
        component: () => import('@/views/bookkeep/add'),
        meta: { title: '添加账单', icon: 'tree' }
      }
    ]
  },
```
2.添加请求后台的接口
```js`
import request from '@/utils/request'

export default{
    add(bookkeep){
        return request({
            url: '/bookkeep/add',
            method: 'post',
            //data表示把对象转换成json传递到接口中
            data: { bookkeep }
        })
    }
}
```
3.在views中完成页码的请求和显示，可以参考element-ui官网查找代码。

注意：
1. new Vue在main.js中已经完成。
2. ==比较值是否相同，===比较值和类型是否相同。如1=='1'为true，1==='1'为false。

views中用到了
①Table表格
②Pagination分页
③MessageBox弹窗
④Form表单，用于筛选框
⑤Button按钮
⑥路由跳转  this.$router.push({path:'/teacher/table'})
⑦隐藏路由：通过路由跳转进入数据回显页面，在路由index页面添加路由
**路由跳转**
<router-link :to="'/bookkeep/update/'+scope.row.id">
        <el-button type="primary" icon="el-icon-edit"></el-button>
</router-link>
**添加路由**
{
        path: 'add/:id',
        name: '编辑账单',
        component: () => import('@/views/edu/teacher/form'),
        meta: { title: '编辑账单',noCache:true},
        hidden: true
}
**根据路由值判断是更新还是添加**
created(){
      console.log("created")
      if(this.$route.params && this.$route.params.id){
          console.log("created")
          const id = this.$route.params.id
          this.findById(id)
      }
}
⑧easyexcel：java解析excel工具
