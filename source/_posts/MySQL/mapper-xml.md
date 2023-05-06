---
title: mapper-xml
categories:
- MySQL
---
#一、增删改查
```xml
<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">

<mapper namespace="com.hxr.springcloud.dao.RequestDao">
    <resultMap id="BaseResultMapper" type="com.hxr.springcloud.entities.Wine">
        <id column="id" property="id" jdbcType="INTEGER"/>
        <result column="product_date" property="productDate" jdbcType="VARCHAR"/>
        <result column="product_area" property="productArea" jdbcType="VARCHAR"/>
        <result column="guarantee_period" property="guaranteePeriod" jdbcType="VARCHAR"/>
        <result column="bottling_date" property="bottlingDate" jdbcType="DATE"/>
        <result column="storage_method" property="storageMethod" jdbcType="VARCHAR"/>
        <result column="wine_variety" property="wineVariety" jdbcType="VARCHAR"/>
        <result column="grape_variety" property="grapeVariety" jdbcType="VARCHAR"/>
        <result column="product_country" property="productCountry" jdbcType="VARCHAR"/>
        <result column="manufacturer" property="manufacturer" jdbcType="VARCHAR"/>
        <result column="abroad_agent" property="abroadAgent" jdbcType="VARCHAR"/>
        <result column="domestic_agent" property="domesticAgent" jdbcType="VARCHAR"/>
        <result column="address" property="address" jdbcType="VARCHAR"/>
        <result column="phone" property="phone" jdbcType="VARCHAR"/>
        <result column="alcohol" property="alcohol" jdbcType="VARCHAR"/>
        <result column="net_quantity" property="netQuantity" jdbcType="VARCHAR"/>
        <result column="bottle_shape" property="bottleShape" jdbcType="INTEGER"/>
    </resultMap>

    <!-- 插入记录 -->
    <insert id="insert" parameterType="com.hxr.springcloud.entities.Wine" useGeneratedKeys="true" keyProperty="id">
        insert into
            wine(id,product_date,product_area,
            guarantee_period,bottling_date,storage_method,
            wine_variety,grape_variety,product_country,
            manufacturer,abroad_agent,domestic_agent,
            address,phone,alcohol,net_quantity,bottle_shape)
            values(null,#{productDate},#{productArea},
            #{guaranteePeriod},#{bottlingDate},#{storageMethod},
            #{wineVariety},#{grapeVariety},#{productCountry},
            #{manufacturer},#{abroadAgent},#{domesticAgent},
            #{address},#{phone},#{alcohol},
            #{netQuantity},#{bottleShape});
    </insert>

    <!-- 更新记录 -->
    <update id="update" parameterType="com.hxr.springcloud.entities.Wine">
        update wine
            set
                product_date = #{productDate},
                product_area = #{productArea},
                guarantee_period = #{guaranteePeriod},
                bottling_date = #{bottlingDate},
                storage_method = #{storageMethod},
                wine_variety = #{wineVariety},
                grape_variety = #{grapeVariety},
                product_country = #{productCountry},
                manufacturer = #{manufacturer},
                abroad_agent = #{abroadAgent},
                domestic_agent = #{domesticAgent},
                address = #{address},
                phone = #{phone},
                alcohol = #{alcohol},
                net_quantity = #{netQuantity},
                bottle_shape = #{bottleShape}
            where id = #{id}
    </update>

    <!-- 删除记录 -->
    <delete id="delete" parameterType="java.lang.Integer">
        delete from wine
        where id = #{id,jdbcType=INTEGER}
    </delete>

    <!-- 检索记录 -->
    <select id="retrieve" parameterType="java.lang.Integer" resultMap="BaseResultMapper">
        select id,product_date,product_area,
            guarantee_period,bottling_date,storage_method,
            wine_variety,grape_variety,product_country,
            manufacturer,abroad_agent,domestic_agent,
            address,phone,alcohol,net_quantity,bottle_shape
        from wine
        where id = #{id,jdbcType=INTEGER}
    </select>

    <!-- 检索部分记录 -->
    <select id="findSome" resultMap="BaseResultMapper">
        select id,product_date,product_area,
            guarantee_period,bottling_date,storage_method,
            wine_variety,grape_variety,product_country,
            manufacturer,abroad_agent,domestic_agent,
            address,phone,alcohol,net_quantity,bottle_shape
        from wine
        where id in
        <foreach collection="ids" index="index" item="item" open="(" separator="," close=")">
            #{item,jdbcType=INTEGER}
        </foreach>
    </select>

    <!-- 检索所有记录 -->
    <select id="findAll" parameterType="java.lang.Integer" resultMap="BaseResultMapper">
        select id,product_date,product_area,
        guarantee_period,bottling_date,storage_method,
        wine_variety,grape_variety,product_country,
        manufacturer,abroad_agent,domestic_agent,
        address,phone,alcohol,net_quantity,bottle_shape
        from wine
    </select>

</mapper>
```

#二、使用mybatis分页查询并统计总数
![image](https://upload-images.jianshu.io/upload_images/23972791-1b81a88909862e4f.png?imageMogr2/auto-orient/strip|imageView2/2/w/693/format/webp)

① resultMap="trainResultMap,count"注意： resultMap里有两个函数，第一个为多表关联的映射map的Id，第二个则是id为count的resultMap查询总记录数方法[图片上传中...(image-13fac2-1618998474716)]


② 这里使用了两条sql语句。首页通过默认条件查询数据并分页，并且提供模糊查询功能，且查询总记录数方法是在前一条sql语句基础上执行而成

![image](https://upload-images.jianshu.io/upload_images/23972791-c3990bac4a2a7389.png?imageMogr2/auto-orient/strip|imageView2/2/w/709/format/webp)

① baseMapper.queryPageByStuId用于调用dao方法

② (List) list.get(0)用于取返回的函数map集合的第一个函数List集合

③ ((List) list.get(1)).get(0)用于取返回函数map集合的第二个函数count数据总数

**注意：**
1. 允许多条执行，在数据库配置中添加allowMultiQueries=true

#三、resultMapper可以复用
创建CommonMapper.xml，CommonMapper.java可以不用创建。
```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">

<mapper namespace="com.iotmars.ingredient.mapper.CommonMapper">

    <resultMap id="countMapper" type="java.lang.Long">
        <result column="total"/>
    </resultMap>

</mapper>
```
在其他xxxMapper.xml文件中引用，只需要CommonMapper的namespace加上resultMapper的id就可以。
```
    <select id="listCookingMode" resultMap="cookingModeVOMapper,com.iotmars.ingredient.mapper.CommonMapper.countMapper">
        SELECT parameter.name AS cooking_method_parameter_name,cmm.cooking_mode_name,cmm.min_cooking_time,
        cmm.max_cooking_time,cmm.min_cooking_temperature,cmm.max_cooking_temperature,
        cmm.min_cooking_power,cmm.max_cooking_power,cmm.gmt_create,cmm.gmt_modified
        FROM (SELECT * FROM cooking_mode
        <where>
            <if test="code != null and code != ''">
                cooking_method_parameter_code = #{code,jdbcType=VARCHAR}
            </if>
            <if test="value != null and code != ''">
                and cooking_method_parameter_value = #{value,jdbcType=VARCHAR}
            </if>
        </where>
        ) AS cmm
        LEFT JOIN parameter
        ON parameter.code = cmm.cooking_method_parameter_code AND parameter.value = cmm.cooking_method_parameter_value;

        SELECT count(*) AS total FROM cooking_mode;
    </select>
```

# 四、例
## 4.1 根据对象查询且中还有一个列表
Mapper.java
```
@Component
public interface CaSalesTotalMapper {
    List<CaSalesTotal> getSalesTotal(@Param("salesTotalReqVo") SalesTotalReqVo salesTotalReqVo);
}
```
mapper.xml
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.iotmars.basic.mapper.CaSalesTotalMapper">
    <resultMap id="CaSalesTotal" type="com.iotmars.basic.domain.CaSalesTotal">
        <result column="type" property="type" jdbcType="VARCHAR"/>
        <result column="device_code" property="deviceCode" jdbcType="VARCHAR"/>
        <result column="time" property="time" jdbcType="VARCHAR"/>
        <result column="sales_num" property="salesNum" jdbcType="VARCHAR"/>
        <result column="sales_money" property="salesMoney" jdbcType="VARCHAR"/>
        <result column="send_num" property="sendNum" jdbcType="VARCHAR"/>
        <result column="create_time" property="createTime" jdbcType="TIMESTAMP"/>
        <result column="update_time" property="updateTime" jdbcType="TIMESTAMP"/>
    </resultMap>

    <select id="getSalesTotal" parameterType="com.iotmars.basic.domain.vo.SalesTotalReqVo" resultMap="CaSalesTotal">
        select * from ca_sales_total
        <where>
            <if test="salesTotalReqVo.type != null and salesTotalReqVo.type != ''">
                and type = #{salesTotalReqVo.type,jdbcType=VARCHAR}
            </if>
            <if test="salesTotalReqVo.timeType != null and salesTotalReqVo.timeType != ''">
                and time_type = #{salesTotalReqVo.timeType}
            </if>
            and device_code in
            <foreach collection="salesTotalReqVo.deviceCodes" index="index" item="deviceCode" open="(" separator="," close=")">
                #{deviceCode, jdbcType=VARCHAR}
            </foreach>
        </where>
    </select>

</mapper>
```

## 4.2 查询多层嵌套的对象
查询对象列表，这个对象中有一个属性是列表，列表中的对象的属性中还有一个列表。
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.iotmars.basic.mapper.CaSalesTotalMapper">
    <resultMap id="catagories" type="com.iotmars.basic.domain.test.Catagory">
        <result column="ccode" property="cataCode" jdbcType="VARCHAR"/>
        <result column="cname" property="cataName" jdbcType="VARCHAR"/>
        <collection property="seriesList" ofType="com.iotmars.basic.domain.test.Series">
            <result column="scode" property="serCode" jdbcType="VARCHAR"/>
            <result column="sname" property="serName" jdbcType="VARCHAR"/>
            <collection property="typeList" ofType="com.iotmars.basic.domain.test.Type">
                <result column="tcode" property="typeCode" jdbcType="VARCHAR"/>
                <result column="tname" property="typeName" jdbcType="VARCHAR"/>
            </collection>
        </collection>
    </resultMap>

    <select id="getCatagories" resultMap="catagories">
        select
            c.code as ccode,
            c.name as cname,
            s.code as scode,
            s.name as sname,
            t.code as tcode,
            t.name as tname
        from ba_device_category as c
        left join ba_device_series as s on c.code = s.device_category_code
        left join ba_device_type as t on s.code = t.device_series_code;
    </select>
</mapper>
```
结果如下
```
{
    "msg": "操作成功",
    "code": 200,
    "data": [
        {
            "cataCode": "2",
            "cataName": "集成灶",
            "seriesList": [
                {
                    "serCode": "X5",
                    "serName": "X5系列",
                    "typeList": [
                        {
                            "typeCode": "X5.001",
                            "typeName": "X5第一号机型"
                        },
                        {
                            "typeCode": "X5.002",
                            "typeName": "X5第2号机型"
                        }
                    ]
                }
            ]
        },
        {
            "cataCode": "集成灶",
            "cataName": "集成灶",
            "seriesList": [
                {
                    "serCode": "x6",
                    "serName": "x6",
                    "typeList": [
                        {
                            "typeCode": "x612",
                            "typeName": "x612"
                        },
                        {
                            "typeCode": "x613",
                            "typeName": "x613"
                        }
                    ]
                },
                {
                    "serCode": "x7",
                    "serName": "x7",
                    "typeList": [
                        {
                            "typeCode": "x701",
                            "typeName": "x701"
                        },
                        {
                            "typeCode": "x702",
                            "typeName": "x702"
                        }
                    ]
                },
                {
                    "serCode": "x8",
                    "serName": "x8",
                    "typeList": []
                }
            ]
        },
        {
            "cataCode": "嵌电",
            "cataName": "嵌电",
            "seriesList": []
        }
    ]
}
```
