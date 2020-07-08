# SpringBoot整合Dubbo

## 一. 服务提供者

### 第一步：引入依赖

```xml
<dependency>
	<groupId>org.apache.dubbo</groupId>
	<artifactId>dubbo-spring-boot-starter</artifactId>
	<version>2.7.7</version>
</dependency>
<dependency>
	<groupId>org.apache.curator</groupId>
	<artifactId>curator-framework</artifactId>
	<version>2.12.0</version>
</dependency>
<dependency>
    <groupId>org.apache.curator</groupId>
    <artifactId>curator-recipes</artifactId>
    <version>2.12.0</version>
</dependency>
```

### 第二步：配置Dubbo

```properties
dubbo.application.name=springboot-dubbo-service

dubbo.registry.address=192.168.2.112:2181,192.168.2.113:2181,192.168.2.114:2181
dubbo.registry.protocol=zookeeper

dubbo.protocol.name=dubbo
dubbo.protocol.port=20880
```

### 第三步：开启Dubbo自动配置

在Spring启动类上加入`@EnableDubbo`注解：

```java
@SpringBootApplication
@EnableDubbo(scanBasePackages = "cn.tjd.service.impl")
public class SpringbootDubboServiceApplication {
	public static void main(String[] args) {
		SpringApplication.run(SpringbootDubboServiceApplication.class, args);
	}
}
```

### 第四步：发布服务

在需要发布的服务类上加上`@org.apache.dubbo.config.annotation.Service`注解（从2.7.7版本开始由`@DubboService`注解代替）：

```java
@DubboService
public class UserServiceImpl implements UserService {}
```

### 第五步：启动SpringBoot

启动SpringBoot服务及会自动注册。

## 二. 服务消费者

### 第一步：引入依赖

与服务提供方引入相同的依赖

### 第二步：配置Dubbo

```properties
dubbo.application.name=springboot-dubbo-web

dubbo.registry.address=192.168.2.112:2181,192.168.2.113:2181,192.168.2.114:2181
dubbo.registry.protocol=zookeeper
```

### 第三步：开启Dubbo自动配置

在Spring启动类上加入`@EnableDubbo`注解：

```java
@SpringBootApplication
@EnableDubbo(scanBasePackages = "cn.tjd.controller")
public class SpringbootDubboWebApplication {
	public static void main(String[] args) {
		SpringApplication.run(SpringbootDubboWebApplication.class, args);
	}
}
```

### 第四步：注入Dubbo服务代理对象

在需要发布的服务类上加上`@org.apache.dubbo.config.annotation.Reference`注解（从2.7.7版本开始由`@DubboReference`注解代替）：

```java
@RestController
public class UserController {

    @DubboReference
    private UserService userService;
}
```



