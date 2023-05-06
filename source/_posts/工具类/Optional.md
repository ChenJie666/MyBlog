---
title: Optional
categories:
- 工具类
---
如果连续调用方法，但是中间有个方法的返回值可能为null，那么可以使用如下方法，在返回值为null时，指定返回默认值。
```
System.out.println(Optional.ofNullable(newData.getJSONObject("CookbookID")).map(j -> j.getString("value")).orElse(""));
```
