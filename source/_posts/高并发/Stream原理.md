---
title: Stream原理
categories:
- 高并发
---
参考 [https://zhuanlan.zhihu.com/p/31220388](https://zhuanlan.zhihu.com/p/31220388)

<br>
# 一、原理
## 1.1 概念
①**算子的完整的操作：** <数据来源，操作，回调函数>构成的三元组。
②**Stage：** Stream中使用Stage的概念来描述一个完整的操作，并用某种实例化后的PipelineHelper来代表Stage，将具有先后顺序的各个Stage连到一起，就构成了整个流水线。跟Stream相关类和接口的继承关系图示。
③**中间操作和结束操作：** Stream操作分为`中间操作`和`结束操作`。中间操作只是一种标记，只有结束操作才会触发实际计算。
④**有状态和无状态：** 中间操作可以分为`有状态`和`无状态`。无状态中间操作是指元素的处理不受前面元素的影响；有状态的中间操作必须等到所有元素处理之后才知道最终结果，比如排序是有状态操作。
⑤**短路操作和非短路操作：** 结束操作又可以分为`短路操作`和`非短路操作`。短路操作是指不用处理全部元素就可以返回结果，比如找到第一个满足条件的元素。之所以要进行如此精细的划分，是因为底层对每一种情况的处理方式不同。

| Stream操作分类                    |                             |                                                              |
| --------------------------------- | --------------------------- | ------------------------------------------------------------ |
| 中间操作(Intermediate operations) | ①无状态(Stateless)          | unordered() filter() map() mapToInt() mapToLong() mapToDouble() flatMap() flatMapToInt() flatMapToLong() flatMapToDouble() peek() |
|                                   | ②有状态(Stateful)           | distinct() sorted() sorted() limit() skip()                  |
| 结束操作(Terminal operations)     | ①非短路操作                 | forEach() forEachOrdered() toArray() reduce() collect() max() min() count() |
|                                   | ②短路操作(short-circuiting) | anyMatch() allMatch() noneMatch() findFirst() findAny()      |





## 1.2 流程
![流程图](Stream原理.assets