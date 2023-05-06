---
title: 原生Echarts示例
categories:
- 数据可视化
---
<!DOCTYPE html>
<html lang="en" dir="ltr">
    <head>
        <meta charset="utf-8">
        <title></title>
        <style media="screen">
            #app {width:400px;height:300px;border:1px solid black;}
        </style>
    </head>
    <body>
        <div id="app">

        </div>
        <script src="echarts.min.js" charset="utf-8"></script>
        <script>
            //1.初始化
            let app = document.querySelector('#app')
            let echart1 = echarts.init(app)

            //2.参数
            let options = {
                xAxis: {
                    type: 'category',
                    data: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                },
                yAxis: {
                    type: 'value'
                },
                series: [{
                    data: [820, 932, 901, 934, 1290, 1330, 1320],
                    type: 'line'
                },{
                    data: [820, 932, 901, 934, 1290, 1330, 1320],
                    type: 'bar'
                }]
            }

            //3.设置参数
            echart1.setOption(options)

        </script>
    </body>
</html>

<!-- lang="en" 表示使用英文  dir="ltr"表示布局是从左到右，rtl是从右到左 -->
<!-- id选择器使用'#'，class选择器使用'.' -->
<!-- option是echarts中图形的属性，可以多种不同类型的图形叠加 -->
