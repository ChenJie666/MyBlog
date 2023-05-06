---
title: 将List转为树状结构
categories:
- 编程语言
---
###代码
通过一个sql查询查出来所有数据，得到一个 Zone集合，然后就回到了主题，如何用java把list转tree。我第一想法是递归。递归的话，需要考虑几个因素，1.终止条件；2.处理逻辑，3.参数（数据参数，当前层级），4.返回值，然后套入这个问题，分析如下：

中断条件：当前节点，无子节点，终止退出
处理逻辑：根据parentId查找节点，设置到parent的children属性中
参数：数据就是list集合，当前层级参数是parent节点


```java
public class Zone {
    String id;
    String name;
    String parentId;
    List<Test.Zone> children;

    public Zone(String id, String name, String parentId) {
        this.id = id;
        this.name = name;
        this.parentId = parentId;
    }
    public void addChildren(Zone zone){
        if(children == null) {
            children = new ArrayList<>();
        }
        children.add(zone);
    }
}
```

#####第一种方法：递归
```java
public static List<Zone> buildTree1(List<Zone> zoneList) {
    List<Zone> result = new ArrayList<>();
    for (Zone zone:zoneList) {
        if (zone.parentId.equals("0")) {
            result.add(zone);
            setChildren(zoneList, zone);
        }
    }
    return result;
}

public static void setChildren(List<Zone> list, Zone parent) {
    for (Zone zone: list) {
        if(parent.id.equals(zone.parentId)){
            parent.children.add(zone);
        }
    }
    if (parent.children.isEmpty()) {
        return;
    }
    for (Zone zone: parent.children) {
        setChildren(list, zone);
    }
}
```

#####第二种方法：两层循环
```java
public static List<Zone> buildTree2(List<Zone> zoneList) {
    List<Zone> result = new ArrayList<>();
    for (Zone zone : zoneList) {
        if (zone.parentId.equals("0")) {
            result.add(zone);
        }
        for (Zone child : zoneList) {
            if (child.parentId.equals(zone.id)) {
                zone.addChildren(child);
            }
        }
    }
    return result;
}
```

#####第三种方法：两次遍历
```java
public static List<Zone> buildTree3(List<Zone> zoneList) {
    Map<String, List<Zone>> zoneByParentIdMap = new HashMap<>();
    zoneList.forEach(zone -> {
        List<Zone> children = zoneByParentIdMap.getOrDefault(zone.parentId, new ArrayList<>());
        children.add(zone);
        zoneByParentIdMap.put(zone.parentId, children);
    });
    zoneList.forEach(zone->zone.children = zoneByParentIdMap.get(zone.id));
    return zoneList.stream()
            .filter(v -> v.parentId.equals("0"))
            .collect(Collectors.toList());
}
```
用java8的stream，三行代码实现。
```java
public static List<Zone> buildTree3(List<Zone> zoneList) {
    Map<String, List<Zone>> zoneByParentIdMap = zoneList.stream().collect(Collectors.groupingBy(Zone::getParentId));
    zoneList.forEach(zone->zone.children = zoneByParentIdMap.get(zone.id));
    return zoneList.stream().filter(v -> v.parentId.equals("0")).collect(Collectors.toList());
}
```

###三种方法对比
前两种方法的时间复杂度都和叶子节点的个数相关，我们假设叶子节点个数为m
方法一: 用递归的方法，时间复杂度等于：O(n +（n-m）* n)，根据初始算法那篇文章的计算时间复杂度的方法，可以得到最终时间复杂度是O(n2)
方法二: 用两层嵌套循环的方法，时间复杂度等于：O(n +（n-m）* n)，和方法一的时间复杂度是一样的，最终时间复杂度是O(n2)
方法三: 用两次遍历的方法，时间复杂度等于：O(3n)，根据初始算法那篇文章的计算时间复杂度的方法，可以得到最终时间复杂度是O(n)，但它的空间复杂度比前两种方法稍微大了一点，但是也是线性阶的，所以影响不是特别大。所以第三种方法是个人觉得比较优的一种方法

| -     | 代码执行次数     | 时间复杂度   | 代码复杂程度 |
| ----- | ---------------- | ------------ | ------------ |
| 方法1 | O(n +（n-m）* n) | 平方阶,O(n2) | 一般         |
| 方法2 | O(n +（n-m）* n) | 平方阶,O(n2) | 良好         |
| 方法3 | O(3n)            | 线性阶,O(n   | 复杂         |
