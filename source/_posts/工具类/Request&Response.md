---
title: Request&Response
categories:
- 工具类
---
response.getWriter()返回的是PrintWriter，这是一个打印输出流

print
response.getWriter().print(),不仅可以打印输出文本格式的（包括html标签），还可以将一个对象以默认的编码方式转换为二进制字节输出

writer
response.getWriter().writer(),只能打印输出文本格式的（包括html标签），不可以打印对象
