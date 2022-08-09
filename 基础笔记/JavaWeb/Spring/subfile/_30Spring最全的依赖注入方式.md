# Spring 依赖注入方式

> 本文转载至：[最全的 Spring 依赖注入方式，你都会了吗？ (qq.com)](https://mp.weixin.qq.com/s/UKm4RfaqscEgEsbKwW1esg)

## 一. 属性注入

通过属性注入的方式非常常用，这个应该是大家比较熟悉的一种方式：

```java
@Service
public class UserService {
    @Autowired
    private Wolf1Bean wolf1Bean;//通过属性注入
}
```

## 二. setter方法注入

除了通过属性注入，通过 setter 方法也可以实现注入：

```java
@Service
public class UserService {
    private Wolf3Bean wolf3Bean;
    
    @Autowired  //通过setter方法实现注入
    public void setWolf3Bean(Wolf3Bean wolf3Bean) {
        this.wolf3Bean = wolf3Bean;
    }
}
```

## 三. 构造器注入

当两个类属于强关联时，我们也可以通过构造器的方式来实现注入：

```java
@Service
public class UserService {
  private Wolf2Bean wolf2Bean;
    
     @Autowired //通过构造器注入
    public UserService(Wolf2Bean wolf2Bean) {
        this.wolf2Bean = wolf2Bean;
    }
}
```

## 四. 接口注入

在上面的三种常规注入方式中，假如我们想要注入一个接口，而当前接口又有多个实现类，那么这时候就会报错，因为 Spring 无法知道到底应该注入哪一个实现类。

比如我们上面的三个类全部实现同一个接口 IWolf，那么这时候直接使用常规的，不带任何注解元数据的注入方式来注入接口 IWolf。

```java
@Autowired
private IWolf iWolf;
```

此时启动服务就会报错。这个就是说本来应该注入一个类，但是 Spring 找到了三个，所以没法确认到底应该用哪一个。这个问题如何解决呢？

### 4.1 通过配置文件和 @ConditionalOnProperty 注解实现

通过` @ConditionalOnProperty` 注解可以结合配置文件来实现唯一注入。下面示例就是说如果配置文件中配置了` lonely.wolf=test1`，那么就会将 Wolf1Bean 初始化到容器，此时因为其他实现类不满足条件，所以不会被初始化到 IOC 容器，所以就可以正常注入接口：

```java
@Component
@ConditionalOnProperty(name = "lonely.wolf",havingValue = "test1")
public class Wolf1Bean implements IWolf{
}
```

当然，这种配置方式，编译器可能还是会提示有多个 Bean，但是只要我们确保每个实现类的条件不一致，就可以正常使用。

### 4.2 通过其他 @Condition 条件注解

除了上面的配置文件条件，还可以通过其他类似的条件注解，如：

- @ConditionalOnBean：当存在某一个 Bean 时，初始化此类到容器。
- @ConditionalOnClass：当存在某一个类时，初始化此类的容器。
- @ConditionalOnMissingBean：当不存在某一个 Bean 时，初始化此类到容器。
- @ConditionalOnMissingClass：当不存在某一个类时，初始化此类到容器。
- …

类似这种实现方式也可以非常灵活的实现动态化配置。

不过上面介绍的这些方法似乎每次都只能固定注入一个实现类，那么如果我们就是想多个类同时注入，不同的场景可以动态切换而又不需要重启或者修改配置文件，又该如何实现呢？

### 4.3 通过 @Resource 注解动态获取

如果不想手动获取，我们也可以通过` @Resource` 注解的形式动态指定 BeanName 来获取：

```java
@Component
public class InterfaceInject {
    @Resource(name = "wolf1Bean")
    private IWolf iWolf;
}
```

如上所示则只会注入 BeanName 为 wolf1Bean 的实现类。

### 4.4 通过集合获取

除了指定 Bean 的方式注入，我们也可以通过集合的方式一次性注入接口的所有实现类：

```java
@Component
public class InterfaceInject {
    @Autowired
    List<IWolf> list;

    @Autowired
    private Map<String,IWolf> map;
}
```

上面的两种形式都会将 IWolf 中所有的实现类注入集合中。如果使用的是 List 集合，那么我们可以取出来再通过 instanceof 关键字来判定类型；而通过 Map 集合注入的话，Spring 会将 Bean 的名称（默认类名首字母小写）作为 key 来存储，这样我们就可以在需要的时候动态获取自己想要的实现类。

### 4.4 @Primary 注解实现默认注入

除了上面的几种方式，我们还可以在其中某一个实现类上加上` @Primary` 注解来表示当有多个 Bean 满足条件时，优先注入当前带有` @Primary` 注解的 Bean：

```java
@Component
@Primary
public class Wolf1Bean implements IWolf{
}
```

通过这种方式，Spring 就会默认注入 wolf1Bean，而同时我们仍然可以通过上下文手动获取其他实现类，因为其他实现类也存在容器中。

## 五. 手动获取 Bean 的几种方式

在 Spring 项目中，手动获取 Bean 需要通过 `ApplicationContext` 对象，这时候可以通过以下 5 种方式进行获取：

### 5.1 直接注入

最简单的一种方法就是通过直接注入的方式获取 `ApplicationContext` 对象，然后就可以通过 `ApplicationContext` 对象获取 Bean ：

```java
@Component
public class InterfaceInject {
    @Autowired
    private ApplicationContext applicationContext;//注入

    public Object getBean(){
        return applicationContext.getBean("wolf1Bean");//获取bean
    }
}
```

### 5.2 通过 ApplicationContextAware 接口获取

通过实现 `ApplicationContextAware` 接口来获取 `ApplicationContext` 对象，从而获取 Bean。需要注意的是，实现 `ApplicationContextAware` 接口的类也需要加上注解，以便交给 Spring 统一管理（这种方式也是项目中使用比较多的一种方式）：

```java
@Component
public class SpringContextUtil implements ApplicationContextAware {
    private static ApplicationContext applicationContext = null;

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        this.applicationContext = applicationContext;
    }

    /**
     * 通过名称获取bean
     */
    public static <T>T getBeanByName(String beanName){
        return (T) applicationContext.getBean(beanName);
    }

    /**
     * 通过类型获取bean
     */
    public static <T>T getBeanByType(Class<T> clazz){
        return (T) applicationContext.getBean(clazz);
    }
}
```

封装之后，我们就可以直接调用对应的方法获取 Bean 了：

```java
Wolf2Bean wolf2Bean = SpringContextUtil.getBeanByName("wolf2Bean");
Wolf3Bean wolf3Bean = SpringContextUtil.getBeanByType(Wolf3Bean.class);
```

### 5.3 通过 ApplicationObjectSupport 和 WebApplicationObjectSupport 获取

这两个对象中，`WebApplicationObjectSupport` 继承了 `ApplicationObjectSupport`，所以并无实质的区别。

同样的，下面这个工具类也需要增加注解，以便交由 Spring 进行统一管理：

```java

@Component
public class SpringUtil extends /*WebApplicationObjectSupport*/ ApplicationObjectSupport {
    private static ApplicationContext applicationContext = null;

    public static <T>T getBean(String beanName){
        return (T) applicationContext.getBean(beanName);
    }

    @PostConstruct
    public void init(){
        applicationContext = super.getApplicationContext();
    }
}
```

有了工具类，在方法中就可以直接调用了：

```java
@RestController
@RequestMapping("/hello")
@Qualifier
public class HelloController {
    @GetMapping("/bean3")
    public Object getBean3(){
        Wolf1Bean wolf1Bean = SpringUtil.getBean("wolf1Bean");
        return wolf1Bean.toString();
    }
}
```

### 5.4 通过 HttpServletRequest 获取

通过 `HttpServletRequest` 对象，再结合 Spring 自身提供的工具类 `WebApplicationContextUtils` 也可以获取到 `ApplicationContext` 对象，而 `HttpServletRequest` 对象可以主动获取（如下 getBean2 方法），也可以被动获取（如下 getBean1 方法）：

```java
@RestController
@RequestMapping("/hello")
@Qualifier
public class HelloController {

    @GetMapping("/bean1")
    public Object getBean1(HttpServletRequest request){
        //直接通过方法中的HttpServletRequest对象
        ApplicationContext applicationContext = WebApplicationContextUtils.getRequiredWebApplicationContext(request.getServletContext());
        Wolf1Bean wolf1Bean = (Wolf1Bean)applicationContext.getBean("wolf1Bean");

        return wolf1Bean.toString();
    }

    @GetMapping("/bean2")
    public Object getBean2(){
        HttpServletRequest request = ((ServletRequestAttributes) RequestContextHolder.getRequestAttributes()).getRequest();//手动获取request对象
        ApplicationContext applicationContext = WebApplicationContextUtils.getRequiredWebApplicationContext(request.getServletContext());

        Wolf2Bean wolf2Bean = (Wolf2Bean)applicationContext.getBean("wolf2Bean");
        return wolf2Bean.toString();
    }
}
```

## 六. 谈谈 @Autowrite 和 @Resource 以及 @Qualifier 注解的区别

上面我们看到了，注入一个 Bean 可以通过` @Autowrite`，也可以通过 `@Resource` 注解来注入，这两个注解有什么区别呢？

- `@Autowrite`：通过类型去注入，可以用于构造器和参数注入。当我们注入接口时，其所有的实现类都属于同一个类型，所以就没办法知道选择哪一个实现类来注入。
- `@Resource`：默认通过名字注入，不能用于构造器和参数注入。如果通过名字找不到唯一的 Bean，则会通过类型去查找。如下可以通过指定 name 或者 type 来确定唯一的实现：

```java
@Resource(name = "wolf2Bean",type = Wolf2Bean.class)
private IWolf iWolf;
```

而` @Qualifier` 注解是用来标识合格者，当` @Autowrite` 和` @Qualifier` 一起使用时，就相当于是通过名字来确定唯一：

```java
@Qualifier("wolf1Bean")
@Autowired
private IWolf iWolf;
```

那可能有人就会说，我直接用` @Resource` 就好了，何必用两个注解结合那么麻烦，这么一说似乎显得 @Qualifier 注解有点多余？

我们先看下面声明 Bean 的场景，这里通过一个方法来声明一个` Bean (MyElement)`，而且方法中的参数又有 Wolf1Bean 对象，那么这时候 Spring 会帮我们自动注入 Wolf1Bean：

```java
@Component
public class InterfaceInject2 {
    @Bean
    public MyElement test(Wolf1Bean wolf1Bean){
        return new MyElement();
    }
}
```

然而如果说我们把上面的代码稍微改一下，把参数改成一个接口，而接口又有多个实现类，这时候就会报错了：

```java
@Component
public class InterfaceInject2 {
    @Bean
    public MyElement test(IWolf iWolf){//此时因为IWolf接口有多个实现类，会报错
        return new MyElement();
    }
}
```

而` @Resource` 注解又是不能用在参数中，所以这时候就需要使用` @Qualifier` 注解来确认唯一实现了（比如在配置多数据源的时候就经常使用` @Qualifier` 注解来实现）：

```java
@Component
public class InterfaceInject2 {
    @Bean
    public MyElement test(@Qualifier("wolf1Bean") IWolf iWolf){
        return new MyElement();
    }
}
```

