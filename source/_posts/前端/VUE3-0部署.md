---
title: VUE3-0部署
categories:
- 前端
---
根目录新建vue.config.js文件
```html
module.exports = {
    devServer: {
        disableHostCheck: false,
        port: 8080,
        https: false,
        open: false,
        proxy: {
            "/api": {
                target: "http://api.wecook.iotmars.com:10010",// 要访问的接口域名
                // target: "http://localhost:10010",// 要访问的接口域名
                changeOrigin: true, //开启代理：在本地会创建一个虚拟服务端，然后发送请求的数据，并同时接收请求的数据，这样服务端和服务端进行数据的交互就不会有跨域问题
                pathRewrite: {
                    '^/api': '' //这里理解成用'/api'代替target里面的地址,比如我要调用'http://40.00.100.100:3002/user/add'，直接写'/api/user/add'即可
                }
            },
            "/cloud": {
                target: "http://192.168.32.128:8002",
                changeOrigin: true,
                pathRewrite: {
                    '^/cloud': ''
                }
            },
        }
    },
    // 打包静态文件
    publicPath: process.env.NODE_ENV === 'production' ? './' : '/'
};
```
npm run build，将dist文件夹放到nginx资源路径上，然后通过nginx代理到目标后台服务器上。


devServer是
