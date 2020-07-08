# Dubbo生产者和消费者的基本配置

## 一. 生产者

### 第一步：引入依赖

```xml
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>dubbo</artifactId>
    <version>2.6.2</version>
</dependency>
<dependency>
    <groupId>org.apache.curator</groupId>
    <artifactId>curator-framework</artifactId>
    <version>2.12.0</version>
</dependency>
```

需要注意的是：2.6之前的版本使用的zkClient客户端，从2.6开始Dubbo改用curator客户端。

### 第二步：配置生产者

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans        http://www.springframework.org/schema/beans/spring-beans-4.3.xsd        http://dubbo.apache.org/schema/dubbo        http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

    <!-- 应用名称，用于计算依赖关系 -->
    <dubbo:application name="dubbo-service"  />

    <!-- 配置Zookeeper注册中心地址，也可以使用其它配置中心，详见参考手册 -->
    <!--clinet属性用于指定Dubbo使用的Zookeeper的客户端的类型-->
    <dubbo:registry protocol="zookeeper" address="192.168.2.112:2181,192.168.2.113:2181,192.168.2.114:2181" client="curator" />

    <!-- 用dubbo协议在20880端口暴露服务 -->
    <dubbo:protocol name="dubbo" port="20880" />

    <!-- 声明需要暴露的服务接口 -->
    <dubbo:service interface="cn.tjd.service.UserService" ref="userService" protocol="dubbo" />

    <!-- 和本地bean一样实现服务 -->
    <bean id="userService" class="cn.tjd.service.impl.UserServiceImpl" />
</beans>
```

### 第三步：启动Spring容器

```java
package cn.tjd;

import org.springframework.context.support.ClassPathXmlApplicationContext;

/**
 * @Auther: TJD
 * @Date: 2020-07-08
 * @DESCRIPTION:
 **/
public class Provider {
    public static void main(String[] args) throws Exception {
        ClassPathXmlApplicationContext context = new ClassPathXmlApplicationContext(new String[] {"classpath:applicationContext-dubbo.xml"});
        context.start();
        System.in.read(); // 按任意键退出
    }
}

```

## 二. 消费者

### 第一步：引入依赖

```xml
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>dubbo</artifactId>
    <version>2.6.2</version>
</dependency>
<dependency>
    <groupId>org.apache.curator</groupId>
    <artifactId>curator-framework</artifactId>
    <version>2.12.0</version>
</dependency>
```

需要注意的是：2.6之前的版本使用的zkClient客户端，从2.6开始Dubbo改用curator客户端。

### 第二步：配置消费者

消费者大多是一个web项目，可能会有多个spring配置文件，需要注意在加载Spring配置文件时把这个配置文件加载进去。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans        http://www.springframework.org/schema/beans/spring-beans-4.3.xsd        http://dubbo.apache.org/schema/dubbo        http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

    <!-- 消费方应用名，用于计算依赖关系，不是匹配条件，不要与提供方一样 -->
    <dubbo:application name="dubbo-web"  />

    <!-- 使用multicast广播注册中心暴露发现服务地址 -->
    <dubbo:registry protocol="zookeeper" address="192.168.2.112:2181,192.168.2.113:2181,192.168.2.114:2181" client="curator" />

    <!-- 生成远程服务代理 -->
    <dubbo:reference id="userService" interface="cn.tjd.service.UserService" protocol="dubbo" />
</beans>
```

### 第三步：在Controller中引入依赖

如果我们在`dubbo`配置文件中通过`dubbo:reference`标签生成了远程服务的代理，那么Spring启动时`UserService`的代理对象就已经在Spring容器中了，我们只需要通过`@Autowired`注入依赖即可：

```java
package cn.tjd.controller;

import cn.tjd.service.UserService;
import com.alibaba.dubbo.config.annotation.Reference;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @Auther: TJD
 * @Date: 2020-06-29
 * @DESCRIPTION:
 **/
@RestController
public class UserController {

    @Autowired
    private UserService userService;

    @RequestMapping("/login")
    public String login(String username,String password){
        return userService.login(username,password);
    }
}
```

