## Spring的全注解配置

​	传统开发中我们通常使用xml配置和注解配置相结合的方式，但是Spring4.x开始实现注解配置时，就可以实现全注解配置了。也就是说整个spring项目可以不使用一个xml。

#### 传统XML与注解相结合的方式

​	下面给出的是

```xml
<beans>
    <!--配置包扫描器-->
    <context:component-scan base-package="cn.tjd.spring_annotation"></context:component-scan>
    
    <!--加载配置文件-->
    <context:property-placeholder location="config/db.properties"></context:property-placeholder>

    <!--配置QueryRunner-->
    <bean id="runner" class="org.apache.commons.dbutils.QueryRunner" scope="prototype">
        <!--注入数据源-->
        <constructor-arg name="ds" ref="dataSource"></constructor-arg>
    </bean>

    <!-- 配置数据源 -->
    <bean id="dataSource" class="com.mchange.v2.c3p0.ComboPooledDataSource">
        <!--连接数据库的必备信息-->
        <property name="driverClass" value="${jdbc.driver}"></property>
        <property name="jdbcUrl" value="${jdbc.url}"></property>
        <property name="user" value="${jdbc.username}"></property>
        <property name="password" value="${jdbc.password}"></property>
    </bean>
</beans>
```

​	可以看到，在传统方式中，我们需要通过xml配置数据源，包扫描器，加载配置文件等。这些都可以用注解来代替。

**自定义类**

```java
@Service
public class TestServiceImpl implements TestService {
    public void sayHello() {
        System.out.println("Hello");
    }
}
```

**测试类**

```java
public class TestSpring {
    @Test
    public void test(){
        ApplicationContext ac=new ClassPathXmlApplicationContext("classpath:spring/applicationContext.xml");
        TestService testService = ac.getBean(TestService.class);
        testService.sayHello();
    }
}
```

#### 全注解**配置**

**@Configuration注解**

- 作用：用Configuration注解标注的类就是配置类.

- 细节：当配置类作为AnnotationConfigApplicationContext对象创建的参数时，不用写这个标签，因为spring已经知道这个类是配置类了。只有当config包下面有多个配置类，并且这些配置类没有被一个配置类使用Import注解引用，并且采用包扫描器扫描config包时，才需要使用`Configuration`来标识这个包下的某几个类是配置类

```java
@Configuration
public class SpringConfiguration {
    
}
```

​	既然现在用全注解进行配置，那么我们就不能使用`ClassPathXmlApplicationContext`读取配置文件,而需要使用ApplicationContex的另一个实现类：`AnnotationConfigApplicationContext`来读取“配置类”。

​	**此时测试类需要这样加载“配置文件”：**

```java
public class TestSpring {
    @Test
    public void test(){
        ApplicationContext ac=new AnnotationConfigApplicationContext(SpringConfiguration.class);
    }
}
```



**@ComponentScan注解——>`<component-scan>`**

- 作用：用于通过注解指定spring在创建容器时要扫描的包，相当于：`<context:component-scan base-package="xxx"/>`

 *      属性：
         *      value：它和basePackages的作用是一样的，都是用于指定创建容器时要扫描的包。
         *      basePackages：它和value属性用途一模一样（看注解源码，实际上他们两个属性分别是对方的别名）

```java
@Configuration
@ComponentScan("cn.tjd")
public class SpringConfiguration {

}
```



**@PropertySource注解——>` <property-placeholder>`**

- 作用：用于加载properties文件，与` <context:property-placeholder>`作用相同

 * 属性：

    *      value：用于指定需要加载的配置文件的位置

   ```java
   @Configuration
   @ComponentScan("cn.tjd")
   @PropertySource("classpath:config/db.properties")
   public class SpringConfiguration {
   
   }
   ```

   

**@Import注解**

- 作用：用于导入其他的配置类

 *      属性：
         *      value：用于指定其他配置类的字节码（当我们使用Import的注解之后，有Import注解的类就父配置类，而导入的都是子配置类，也就是我们常说的分模块配置）。

```java
@Configuration
@ComponentScan("cn.tjd")
@PropertySource("classpath:config/db.properties")
@Import(DBConfiguration.class)
public class SpringConfiguration {

}


public class DBConfiguration {

}
```



**@Bean注解**

- 作用：用于把。在很多第三方类（例如上面xml文件中的QueryRunner），我们我无法在第三方类中加入@Autowired注入数据源，此时我们就需要使用@Bean注解，它作用在方法上，**表示将当前方法的返回值作为bean对象存入spring的IOC容器中。这个注解作用实际上就是实现第三方类的属性注入和构造器注入功能**
- **属性:**
   *          name：用于指定bean的id。当不写时，默认值是当前方法的名称
   *          value：与name属性用途完全相同（看Bean的源码可知）
   *          **当我们使用注解配置方法时，如果方法有参数，spring框架会去IOC容器中查找有没有可用的bean对象。查找的方式和Autowired注解的作用是一样的。**

```java
@Configuration
@ComponentScan("cn.tjd")
@PropertySource("classpath:config/db.properties")
@Import(DBConfiguration.class)
public class SpringConfiguration {
	
}


public class DBConfiguration {
    @Value("${jdbc.driver}")
    private String driver;

    @Value("${jdbc.url}")
    private String url;

    @Value("${jdbc.username}")
    private String username;

    @Value("${jdbc.password}")
    private String password;
    
	 /**
     * 用于创建一个QueryRunner对象
     * @param dataSource
     * @return
     */
    @Bean(name="runner")
    @Scope("prototype")
    public QueryRunner createQueryRunner(@Qualifier("dataSource") DataSource dataSource){
        return new QueryRunner(dataSource);
    }

    /**
     * 创建数据源对象
     * @return
     */
    @Bean(name="dataSource")
    public DataSource createDataSource(){
        try {
            ComboPooledDataSource ds = new ComboPooledDataSource();
            ds.setDriverClass(driver);
            ds.setJdbcUrl(url);
            ds.setUser(username);
            ds.setPassword(password);
            return ds;
        }catch (Exception e){
            throw new RuntimeException(e);
        }
    }
}
```

**测试**

```java
public class TestSpring {
    @Test
    public void test(){
        ApplicationContext ac=new AnnotationConfigApplicationContext(SpringConfiguration.class);
        TestService testService = ac.getBean(TestService.class);
        QueryRunner bean = ac.getBean(QueryRunner.class);
        testService.sayHello();
    }
}
```

