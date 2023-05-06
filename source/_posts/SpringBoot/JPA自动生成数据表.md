---
title: JPA自动生成数据表
categories:
- SpringBoot
---
# 一、配置
**依赖**
```    
       <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
```

**配置文件**
数据库版本需要与database-platform对应，我这里使用的数据库是mysql5.7。
```yml
spring:
  datasource:
    url: jdbc:mysql://127.0.0.1:3306/springboot_test
    username: root
    password: abc123
    driver-class-name: com.mysql.cj.jdbc.Driver
  jpa:
    #配置数据库类型
    database: MYSQL
    #指定数据库的引擎
    database-platform: org.hibernate.dialect.MySQL57Dialect
    #配置是否打印sql
    show-sql: true
    #Hibernate相关配置
    hibernate:
      #配置级联等级
      #      ddl-auto: create
      ddl-auto: update
    open-in-view: false
#  jackson:
#    property-naming-strategy: CAMEL_CASE_TO_LOWER_CASE_WITH_UNDERSCORES
```
>**可选参数**
>- create 启动时删数据库中的表，然后创建，退出时不删除数据表 
>- create-drop 启动时删数据库中的表，然后创建，退出时删除数据表 如果表不存在报错 
>- update 每次运行程序，没有表格会新建表格，表内有数据不会清空，只会更新 
>- validate 项目启动表结构进行校验 如果不一致则报错

<br>

**实体类**
```java
@Entity
@Table(name = "person") //自动创建的表的表名 @TableName是mybatisplus的注解
public class Person {
    @Id   //@TableId是mybatisplus的注解
    @GeneratedValue(strategy = GenerationType.IDENTITY) //主键id需要添加该注解
    private  Long id;

    @Column(length =50,name = "name")
    private  String  name;

    private  String email;

    private  String  gender;

    private  String  address;
}
```

<!-- 
**创建表**(泛型1是需要创建的类，泛型2是主键的类型)
```java
@Repository
public interface ClockRepository extends JpaRepository<Clock, Integer> {
}
```

启动项目发现表已经自动创建。
-->


<br>

>**@Entity**
@Entity 注解和 @Table 注解都是 Java Persistence API 中定义的一种注解
@Entity默认的ORM映射关系为：类名与数据库中的表名相映射
如果没有 @javax.persistence.Entity 和 @javax.persistence.Id 这两个注解的话，它完全就是一个典型的 POJO 的 Java 类，现在加上这两个注解之后，就可以作为一个实体类与数据库中的表相对应。他在数据库中的对应的表为：
>
>**@Table**
如果同时使用了 @Entity(name=“student”) 和 @Table(name=“students”)，最终的对应的表名必须是哪个？答案是 students，这说明优先级：@Table > @Entity。
>
>**@column**
@Column来改变class中字段名与db中表的字段名的映射规则


<br>

# 二、使生成的表字段有序
由于JPA源码中的PropertyContainer表中使用TreeMap保存字段，因此实际生成的表字段是升序排列的。我们只需要将TreeMap改为LinkedHashMap即可（在项目中创建相同的包，将org.hibernate.hibernate-core依赖中的org.hibernate.cfg.PropertyContainer包下的PropertyContainer类复制到自己创建的包下，将TreeMap修改为LinkedHashMap即可，运行时会使用我们创建的类）。

**具体步骤**
1. 创建包org.hibernate.cfg
2. 在包下创建类PropertyContainer
```
package org.hibernate.cfg;

import java.util.*;
import javax.persistence.Access;
import javax.persistence.ManyToMany;
import javax.persistence.ManyToOne;
import javax.persistence.OneToMany;
import javax.persistence.OneToOne;
import javax.persistence.Transient;

import org.hibernate.AnnotationException;
import org.hibernate.annotations.Any;
import org.hibernate.annotations.ManyToAny;
import org.hibernate.annotations.Target;
import org.hibernate.annotations.Type;
import org.hibernate.annotations.common.reflection.XClass;
import org.hibernate.annotations.common.reflection.XProperty;
import org.hibernate.boot.MappingException;
import org.hibernate.boot.jaxb.Origin;
import org.hibernate.boot.jaxb.SourceType;
import org.hibernate.cfg.annotations.HCANNHelper;
import org.hibernate.internal.CoreMessageLogger;
import org.hibernate.internal.util.StringHelper;
import org.jboss.logging.Logger;

/**
 * @author CJ
 * @date: 2021/4/14 9:34
 */
public class PropertyContainer {

    private static final CoreMessageLogger LOG = (CoreMessageLogger) Logger.getMessageLogger(CoreMessageLogger.class, org.hibernate.cfg.PropertyContainer.class.getName());
    private final XClass xClass;
    private final XClass entityAtStake;
    private final AccessType classLevelAccessType;
    private final LinkedHashMap<String, XProperty> persistentAttributeMap;

    PropertyContainer(XClass clazz, XClass entityAtStake, AccessType defaultClassLevelAccessType) {
        this.xClass = clazz;
        this.entityAtStake = entityAtStake;
        if (defaultClassLevelAccessType == AccessType.DEFAULT) {
            defaultClassLevelAccessType = AccessType.PROPERTY;
        }

        AccessType localClassLevelAccessType = this.determineLocalClassDefinedAccessStrategy();

        assert localClassLevelAccessType != null;

        this.classLevelAccessType = localClassLevelAccessType != AccessType.DEFAULT ? localClassLevelAccessType : defaultClassLevelAccessType;

        assert this.classLevelAccessType == AccessType.FIELD || this.classLevelAccessType == AccessType.PROPERTY;

        this.persistentAttributeMap = new LinkedHashMap();
        List<XProperty> fields = this.xClass.getDeclaredProperties(AccessType.FIELD.getType());
        List<XProperty> getters = this.xClass.getDeclaredProperties(AccessType.PROPERTY.getType());
        this.preFilter(fields, getters);
        Map<String, XProperty> persistentAttributesFromGetters = new LinkedHashMap();
        this.collectPersistentAttributesUsingLocalAccessType(this.persistentAttributeMap, persistentAttributesFromGetters, fields, getters);
        this.collectPersistentAttributesUsingClassLevelAccessType(this.persistentAttributeMap, persistentAttributesFromGetters, fields, getters);
    }

    private void preFilter(List<XProperty> fields, List<XProperty> getters) {
        Iterator propertyIterator = fields.iterator();

        XProperty property;
        while (propertyIterator.hasNext()) {
            property = (XProperty) propertyIterator.next();
            if (mustBeSkipped(property)) {
                propertyIterator.remove();
            }
        }

        propertyIterator = getters.iterator();

        while (propertyIterator.hasNext()) {
            property = (XProperty) propertyIterator.next();
            if (mustBeSkipped(property)) {
                propertyIterator.remove();
            }
        }

    }

    private void collectPersistentAttributesUsingLocalAccessType(LinkedHashMap<String, XProperty> persistentAttributeMap, Map<String, XProperty> persistentAttributesFromGetters, List<XProperty> fields, List<XProperty> getters) {
        Iterator propertyIterator = fields.iterator();

        XProperty xProperty;
        Access localAccessAnnotation;
        while (propertyIterator.hasNext()) {
            xProperty = (XProperty) propertyIterator.next();
            localAccessAnnotation = (Access) xProperty.getAnnotation(Access.class);
            if (localAccessAnnotation != null && localAccessAnnotation.value() == javax.persistence.AccessType.FIELD) {
                propertyIterator.remove();
                persistentAttributeMap.put(xProperty.getName(), xProperty);
            }
        }

        propertyIterator = getters.iterator();

        while (propertyIterator.hasNext()) {
            xProperty = (XProperty) propertyIterator.next();
            localAccessAnnotation = (Access) xProperty.getAnnotation(Access.class);
            if (localAccessAnnotation != null && localAccessAnnotation.value() == javax.persistence.AccessType.PROPERTY) {
                propertyIterator.remove();
                String name = xProperty.getName();
                XProperty previous = (XProperty) persistentAttributesFromGetters.get(name);
                if (previous != null) {
                    throw new MappingException(LOG.ambiguousPropertyMethods(this.xClass.getName(), HCANNHelper.annotatedElementSignature(previous), HCANNHelper.annotatedElementSignature(xProperty)), new Origin(SourceType.ANNOTATION, this.xClass.getName()));
                }

                persistentAttributeMap.put(name, xProperty);
                persistentAttributesFromGetters.put(name, xProperty);
            }
        }

    }

    private void collectPersistentAttributesUsingClassLevelAccessType(LinkedHashMap<String, XProperty> persistentAttributeMap, Map<String, XProperty> persistentAttributesFromGetters, List<XProperty> fields, List<XProperty> getters) {
        Iterator var5;
        XProperty getter;
        if (this.classLevelAccessType == AccessType.FIELD) {
            var5 = fields.iterator();

            while (var5.hasNext()) {
                getter = (XProperty) var5.next();
                if (!persistentAttributeMap.containsKey(getter.getName())) {
                    persistentAttributeMap.put(getter.getName(), getter);
                }
            }
        } else {
            var5 = getters.iterator();

            while (var5.hasNext()) {
                getter = (XProperty) var5.next();
                String name = getter.getName();
                XProperty previous = (XProperty) persistentAttributesFromGetters.get(name);
                if (previous != null) {
                    throw new MappingException(LOG.ambiguousPropertyMethods(this.xClass.getName(), HCANNHelper.annotatedElementSignature(previous), HCANNHelper.annotatedElementSignature(getter)), new Origin(SourceType.ANNOTATION, this.xClass.getName()));
                }

                if (!persistentAttributeMap.containsKey(name)) {
                    persistentAttributeMap.put(getter.getName(), getter);
                    persistentAttributesFromGetters.put(name, getter);
                }
            }
        }

    }

    public XClass getEntityAtStake() {
        return this.entityAtStake;
    }

    public XClass getDeclaringClass() {
        return this.xClass;
    }

    public AccessType getClassLevelAccessType() {
        return this.classLevelAccessType;
    }

    public Collection<XProperty> getProperties() {
        this.assertTypesAreResolvable();
        return Collections.unmodifiableCollection(this.persistentAttributeMap.values());
    }

    private void assertTypesAreResolvable() {
        Iterator var1 = this.persistentAttributeMap.values().iterator();

        XProperty xProperty;
        do {
            if (!var1.hasNext()) {
                return;
            }

            xProperty = (XProperty) var1.next();
        } while (xProperty.isTypeResolved() || discoverTypeWithoutReflection(xProperty));

        String msg = "Property " + StringHelper.qualify(this.xClass.getName(), xProperty.getName()) + " has an unbound type and no explicit target entity. Resolve this Generic usage issue or set an explicit target attribute (eg @OneToMany(target=) or use an explicit @Type";
        throw new AnnotationException(msg);
    }

    private AccessType determineLocalClassDefinedAccessStrategy() {
        AccessType hibernateDefinedAccessType = AccessType.DEFAULT;
        AccessType jpaDefinedAccessType = AccessType.DEFAULT;
        org.hibernate.annotations.AccessType accessType = (org.hibernate.annotations.AccessType) this.xClass.getAnnotation(org.hibernate.annotations.AccessType.class);
        if (accessType != null) {
            hibernateDefinedAccessType = AccessType.getAccessStrategy(accessType.value());
        }

        Access access = (Access) this.xClass.getAnnotation(Access.class);
        if (access != null) {
            jpaDefinedAccessType = AccessType.getAccessStrategy(access.value());
        }

        if (hibernateDefinedAccessType != AccessType.DEFAULT && jpaDefinedAccessType != AccessType.DEFAULT && hibernateDefinedAccessType != jpaDefinedAccessType) {
            throw new org.hibernate.MappingException("@AccessType and @Access specified with contradicting values. Use of @Access only is recommended. ");
        } else {
            AccessType classDefinedAccessType;
            if (hibernateDefinedAccessType != AccessType.DEFAULT) {
                classDefinedAccessType = hibernateDefinedAccessType;
            } else {
                classDefinedAccessType = jpaDefinedAccessType;
            }

            return classDefinedAccessType;
        }
    }

    private static boolean discoverTypeWithoutReflection(XProperty p) {
        if (p.isAnnotationPresent(OneToOne.class) && !((OneToOne) p.getAnnotation(OneToOne.class)).targetEntity().equals(Void.TYPE)) {
            return true;
        } else if (p.isAnnotationPresent(OneToMany.class) && !((OneToMany) p.getAnnotation(OneToMany.class)).targetEntity().equals(Void.TYPE)) {
            return true;
        } else if (p.isAnnotationPresent(ManyToOne.class) && !((ManyToOne) p.getAnnotation(ManyToOne.class)).targetEntity().equals(Void.TYPE)) {
            return true;
        } else if (p.isAnnotationPresent(ManyToMany.class) && !((ManyToMany) p.getAnnotation(ManyToMany.class)).targetEntity().equals(Void.TYPE)) {
            return true;
        } else if (p.isAnnotationPresent(Any.class)) {
            return true;
        } else if (p.isAnnotationPresent(ManyToAny.class)) {
            if (!p.isCollection() && !p.isArray()) {
                throw new AnnotationException("@ManyToAny used on a non collection non array property: " + p.getName());
            } else {
                return true;
            }
        } else if (p.isAnnotationPresent(Type.class)) {
            return true;
        } else {
            return p.isAnnotationPresent(Target.class);
        }
    }

    private static boolean mustBeSkipped(XProperty property) {
        return property.isAnnotationPresent(Transient.class) || "net.sf.cglib.transform.impl.InterceptFieldCallback".equals(property.getType().getName()) || "org.hibernate.bytecode.internal.javassist.FieldHandler".equals(property.getType().getName());
    }


}
```

<br>
# 三、常用注解和索引创建
@Entity 标注用于实体类声明语句之前，指出该Java类为实体类，将映射到指定的数据库表。

@Table(name = "xxx") 当实体类与其映射的数据库表名不同名时使用@Table标注说明

@Id 声明一个实体类的属性映射为数据库的主键列。

@GeneratedValue 标注主键的生成策略
- IDENTITY：采用数据库ID自增长的方式来自增主键字段，Oracle不支持这种方式（oracle12g后，应该支持了。）；
- AUTO：JPA自动选择合适的策略，是默认选项；
- SEQUENCE：通过序列产生主键，通过@SequenceGenerator(strategy=GenerationType.AUTO) 注解指定序列名，MySql不支持这种方式。
- TABLE 通过表产生键，框架借助由表模拟序列产生主键，使用该策略可以使应用更易于数据库移植。

@Column(name="xxx",nullable=false,length=64,unique=false,) 当实体的属性与其映射的数据库表的列不同名时使用。@Column标注也可以置于属性的getter方法之前。

@Basic(fetch="",optional="") 表示一个简单的属性到数据库表的字段的映射，对于没有任何标注的getXxx()方法，默认即为Basic。fetch表示该属性的读取策略，有EAGER和LAZY两种，分别表示主支抓取和延迟加载，默认为EAGER。optional表示该属性是否允许为null,默认为true。

@Transient 表示该属性并非一个到数据库表的字段的映射，ORM框架将忽略该属性。类似@TableField(exist = false)。

@Temporal(TemporalType.TIMESTAMP)  使用@Temporal注解来调整Date精度


#索引
**1.创建联合唯一索引**
```
@Table(uniqueConstraints = {@UniqueConstraint(columnNames={"category_name", "sec_category_name"})})
```
>**注意：**还需要再对应的字段上添加@Column(name = "category_name")  ,  @Column(name = "sec_category_name") 

**2.添加唯一索引约束**
```
@Table(name = "UserOrgUnit",uniqueConstraints = @UniqueConstraint(name = "uni_resmodule", columnNames = {"resModule"}) )
```
**3.添加普通索引**
```
@Table(name = "order", indexes = {@Index(columnList = "applyMemberId"), @Index(columnList = "orgUnitId")})
```
```
@Table(name = "cooked_nutrition_detail",indexes = {@Index(name = "idx_cooked_parameter_id",columnList = "cooked_parameter_id"), @Index(name = "idx_ingredient_id",columnList = "ingredient_id")})
```
复合索引配置，注意 name 相同就可以了。 
复合索引字段顺序就是 @Index中字段的顺序，注意 最佳左前缀特性。
