---
title: 切面编程AOP
categories:
- SpringBoot
---
# 一、基本概念：
使用场景：实现一些事务和日志处理，**如redisson分布式锁，使用@Around配合自定义注解代理需要上锁的代码**。
## 1.1 注解
| 注解           | 解释                                                         |
| -------------- | ------------------------------------------------------------ |
| @Aspect        | 切面声明，标注在类、接口（包括注解类型）或枚举上。           |
| @Pointcut      | 切入点声明，即切入到哪些目标类的目标方法。value 属性指定切入点表达式，默认为 ""，用于被通知注解引用，这样通知注解只需要关联此切入点声明即可，无需再重复写切入点表达式。 |
| @Before        | 前置通知, 在目标方法(切入点)执行之前执行。value 属性绑定通知的切入点表达式，可以关联切入点声明，也可以直接设置切入点表达式。注意：如果在此回调方法中抛出异常，则目标方法不会再执行，会继续执行后置通知 -> 异常通知。 |
| @After         | 后置通知, 在目标方法(切入点)执行之后执行                     |
| @AfterRunning  | 返回通知, 在目标方法(切入点)返回结果之后执行，在 @After 的后面执行，pointcut 属性绑定通知的切入点表达式，优先级高于 value，默认为 "" |
| @AfterThrowing | 异常通知, 在方法抛出异常之后执行, 意味着跳过返回通知，pointcut 属性绑定通知的切入点表达式，优先级高于 value，默认为 "" |
| @Around        | 环绕通知：目标方法执行前后分别执行一些代码，发生异常的时候执行另外一些代码 |

## 1.2 指定切入点
使用&&、||、!、三种运算符来组合切点表达式，表示与或非的关系；
### 1.2.1 execution 切点表达式
| 表达式                                                       | 解释                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| execution(* com.wmx.aspect.EmpServiceImpl.findEmpById(Integer)) | 匹配 com.wmx.aspect.EmpService 类中的 findEmpById 方法，且带有一个 Integer 类型参数。 |
| execution(* com.wmx.aspect.EmpServiceImpl.findEmpById(*))    | 匹配 com.wmx.aspect.EmpService 类中的 findEmpById 方法，且带有一个任意类型参数。 |
| execution(* com.wmx.aspect.EmpServiceImpl.findEmpById(..))   | 匹配 com.wmx.aspect.EmpService 类中的 findEmpById 方法，参数不限。 |
| execution(* grp.basic3.se.service.SEBasAgencyService3.editAgencyInfo(..)) \|\| execution(* grp.basic3.se.service.SEBasAgencyService3.adjustAgencyInfo(..)) | 匹配 editAgencyInfo 方法或者 adjustAgencyInfo 方法           |
| execution(* com.wmx.aspect.EmpService.*(..))                 | 匹配 com.wmx.aspect.EmpService 类中的任意方法                |
| execution(* com.wmx.aspect.*.*(..))                          | 匹配 com.wmx.aspect 包(不含子包)下任意类中的任意方法         |
| execution(* com.wmx.aspect..*.*(..))                         | 匹配 com.wmx.aspect 包及其子包下任意类中的任意方法           |

### 1.2.2 @annotation(annotationType) 匹配指定注解为切入点的方法；
```
@Documented
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface SerialMethod{
}
```
```
@Aspect
@Service
public class SerialMethodAop {

    @Value("${spring.application.name}")
    private String applicationName;

    private static final String LOCK_KEY_PREFIX = "SerialMethod:";
    /**
     * 等待180秒
     */
    private static final long MAX_WAIT_TIME = 180;

    private RedissonClient client;

    public SerialMethodAop(RedissonClient client) {
        this.client = client;
    }

    @Around("@annotation(com.iotmars.annotation.SerialMethod)")
    public Object around(ProceedingJoinPoint pjp) throws Throwable {
        Signature signature = pjp.getSignature();

        //锁整个方法
        String key = LOCK_KEY_PREFIX + applicationName + ":" + DigestUtils.md5DigestAsHex(signature.toString().getBytes());
        RLock lock = client.getLock(key);

        boolean locked = lock.tryLock(MAX_WAIT_TIME, TimeUnit.SECONDS);
        try {
            if (locked) {
                return pjp.proceed();
            } else {
                throw new IllegalArgumentException("服务器忙，请稍后再试！");
            }

        } finally {
            if (locked) {
                lock.unlock();
            }

        }
    }
}
```

## 1.3 快速入门
>1）在类上使用 @Aspect 注解使之成为切面类
>2）切面类需要交由 Sprign 容器管理，所以类上还需要有 @Service、@Repository、@Controller、@Component  等注解
>3）在切面类中自定义方法接收通知

```
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
    <version>2.2.5.RELEASE</version>
</dependency>
```
```
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.Signature;
import org.aspectj.lang.annotation.*;
import org.aspectj.lang.reflect.SourceLocation;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
 
import java.util.Arrays;
 
/**
 * 切面注解 Aspect 使用入门
 * 1、@Aspect：声明本类为切面类
 * 2、@Component：将本类交由 Spring 容器管理
 * 3、@Order：指定切入执行顺序，数值越小，切面执行顺序越靠前，默认为 Integer.MAX_VALUE
 */
@Aspect
@Order(value = 999)
@Component
public class AspectHelloWorld {
 
    /**
     * @Pointcut ：切入点声明，即切入到哪些目标方法。value 属性指定切入点表达式，默认为 ""。
     * 用于被下面的通知注解引用，这样通知注解只需要关联此切入点声明即可，无需再重复写切入点表达式
     * <p>
     * 切入点表达式常用格式举例如下：
     * - * com.wmx.aspect.EmpService.*(..))：第一个*表示匹配任意的方法返回值，第二个*表示 com.wmx.aspect.EmpService 类中的任意方法，(..)表示任意参数
     * - * com.wmx.aspect.*.*(..))：表示 com.wmx.aspect 包(不含子包)下任意类中的任意方法
     * - * com.wmx.aspect..*.*(..))：表示 com.wmx.aspect 包及其子包下任意类中的任意方法
     * </p>
     */
    @Pointcut(value = "execution(* com.wmx.aspect.EmpServiceImpl.*(..)) || @annotation(com.hxr.annotation.HelloWorld)")
    private void aspectPointcut() {
 
    }
 
    /**
     * 前置通知：目标方法执行之前执行以下方法体的内容。
     * value：绑定通知的切入点表达式。可以关联切入点声明，也可以直接设置切入点表达式
     * <br/>
     *
     * @param joinPoint：提供对连接点处可用状态和有关它的静态信息的反射访问<br/> <p>
     *                Object[] getArgs()：返回此连接点处（目标方法）的参数
     *                Signature getSignature()：返回连接点处的签名。
     *                Object getTarget()：返回目标对象
     *                Object getThis()：返回当前正在执行的对象
     *                StaticPart getStaticPart()：返回一个封装此连接点的静态部分的对象。
     *                SourceLocation getSourceLocation()：返回与连接点对应的源位置
     *                String toLongString()：返回连接点的扩展字符串表示形式。
     *                String toShortString()：返回连接点的缩写字符串表示形式。
     *                String getKind()：返回表示连接点类型的字符串
     *                </p>
     */
    @Before(value = "aspectPointcut()")
    public void aspectBefore(JoinPoint joinPoint) {
        Object[] args = joinPoint.getArgs();
        Signature signature = joinPoint.getSignature();
        Object target = joinPoint.getTarget();
        Object aThis = joinPoint.getThis();
        JoinPoint.StaticPart staticPart = joinPoint.getStaticPart();
        SourceLocation sourceLocation = joinPoint.getSourceLocation();
        String longString = joinPoint.toLongString();
        String shortString = joinPoint.toShortString();
 
        System.out.println("【前置通知】");
        System.out.println("	args=" + Arrays.asList(args));
        System.out.println("	signature=" + signature);
        System.out.println("	target=" + target);
        System.out.println("	aThis=" + aThis);
        System.out.println("	staticPart=" + staticPart);
        System.out.println("	sourceLocation=" + sourceLocation);
        System.out.println("	longString=" + longString);
        System.out.println("	shortString=" + shortString);
    }
 
    /**
     * 后置通知：目标方法执行之后执行以下方法体的内容，不管目标方法是否发生异常。
     * value：绑定通知的切入点表达式。可以关联切入点声明，也可以直接设置切入点表达式
     */
    @After(value = "aspectPointcut()")
    public void aspectAfter(JoinPoint joinPoint) {
        System.out.println("【后置通知】");
        System.out.println("	kind=" + joinPoint.getKind());
    }
 
    /**
     * 返回通知：目标方法返回后执行以下代码
     * value 属性：绑定通知的切入点表达式。可以关联切入点声明，也可以直接设置切入点表达式
     * pointcut 属性：绑定通知的切入点表达式，优先级高于 value，默认为 ""
     * returning 属性：通知签名中要将返回值绑定到的参数的名称，默认为 ""
     *
     * @param joinPoint ：提供对连接点处可用状态和有关它的静态信息的反射访问
     * @param result    ：目标方法返回的值，参数名称与 returning 属性值一致。无返回值时，这里 result 会为 null.
     */
    @AfterReturning(pointcut = "aspectPointcut()", returning = "result")
    public void aspectAfterReturning(JoinPoint joinPoint, Object result) {
        System.out.println("【返回通知】");
        System.out.println("	目标方法返回值=" + result);
    }
 
    /**
     * 异常通知：目标方法发生异常的时候执行以下代码，此时返回通知不会再触发
     * value 属性：绑定通知的切入点表达式。可以关联切入点声明，也可以直接设置切入点表达式
     * pointcut 属性：绑定通知的切入点表达式，优先级高于 value，默认为 ""
     * throwing 属性：与方法中的异常参数名称一致，
     *
     * @param ex：捕获的异常对象，名称与 throwing 属性值一致
     */
    @AfterThrowing(pointcut = "aspectPointcut()", throwing = "ex")
    public void aspectAfterThrowing(JoinPoint jp, Exception ex) {
        String methodName = jp.getSignature().getName();
        System.out.println("【异常通知】");
        if (ex instanceof ArithmeticException) {
            System.out.println("	【" + methodName + "】方法算术异常（ArithmeticException）：" + ex.getMessage());
        } else {
            System.out.println("	【" + methodName + "】方法异常：" + ex.getMessage());
        }
    }

    @Around(value = "aspectPointcut() && args(arg)")
    public Object around(ProceedingJoinPoint pjp, String arg) throws Throwable {

        System.out.println("name:" + arg);
        System.out.println("方法环绕start...around");
        Object proceed = pjp.proceed();

        System.out.println("aop String");

        System.out.println("方法环绕end...around");
        return proceed;
    }
}
```
>当方法符合切点规则并且符合环绕通知的规则时候，执行的顺序如下
`@Around→@Before→@Around→@After执行 ProceedingJoinPoint.proceed() 之后的操作→@AfterRunning(如果有异常→@AfterThrowing)`
