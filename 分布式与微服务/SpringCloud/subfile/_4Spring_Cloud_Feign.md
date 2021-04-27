# Spring Cloud Feign

Feign 是 Netflix 公司开发的一个声明式的 REST 调用客户端。 Spring Cloud Feign 对 Ribbon 负载均衡进行了简化，在其基础上进行了进一步的封装，它是一种声明式的调用方式，它的使用方法是定义一个接口，然后在接口上添加注解，使其支持了Spring MVC标准注解和HttpMessageConverters，Feign可以与Eureka和Ribbon组合使用以支持负载均衡。

Spring Cloud Feign 对 Ribbon 负载均衡进行了简化，在其基础上进行了进一步的封装，在配置上大大简化了开发工作，它是一种声明式的调用方式，它的使用方法是定义一个接口，然后在接口上添加注解，使其支持了Spring MVC标准注解和HttpMessageConverters，Feign可以与Eureka和Ribbon组合使用以支持负载均衡。

## 一. 服务提供者



## 二. 使用Feign实现服务的消费

**第一步：添加依赖**

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
```

**第二步：声明服务**

新增一个接口，用于约束远程调用的入参和返回参数。

```java
import cn.bigcoder.springcloud.qa.admin.dto.ArticleDTO;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.RequestMapping;

@FeignClient("admin-dl")
public interface IArticleService {

    @RequestMapping("/article/getById")
    ArticleDTO getById(Integer id);
}
```

使用`@FeignClient`注解来指定服务名称，进行服务绑定，使用`@RequestMapping`指定接口方法与服务提供者的那个服务进行绑定。

**第三步：开启`Feign`功能**

在启动类上加上`@EnableFeignClients `注解。

```java
package cn.bigcoder.springcloud.qa.admin.web.adminweb;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.openfeign.EnableFeignClients;

@SpringBootApplication
@EnableFeignClients("cn.bigcoder.springcloud.qa.admin")
public class AdminWebApplication {

    public static void main(String[] args) {
        SpringApplication.run(AdminWebApplication.class, args);
    }

}
```

需要注意的是`@EnableFeignClients`需要指定接口扫描包路径，不然会出现如下错误：

```shell
Field articleService in cn.bigcoder.springcloud.qa.admin.web.adminweb.controller.AdminController required a bean of type 'cn.bigcoder.springcloud.qa.admin.service.IArticleService' that could not be found.
```

**第四步：注入接口实现，消费服务**

```java
import cn.bigcoder.springcloud.qa.admin.dto.ArticleDTO;
import cn.bigcoder.springcloud.qa.admin.service.IArticleService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * @author: Jindong.Tian
 * @date: 2021-04-20
 **/
@RestController
@RequestMapping("/admin")
@Slf4j
public class AdminController {

    @Autowired
    private IArticleService articleService;

    @RequestMapping("/getArticleById")
    public ArticleDTO getArticleById(Integer id) {
        ArticleDTO articleDTO = articleService.getById(id);
        return articleDTO;
    }
}
```

这样我们只需要注入我们定义的接口，SpringCloud会帮我们创建代理对象，我们只需要实现调用dialing对象实例，即可完成远程调用。