# CORS跨域资源共享

> 本文参考转载至：[一文了解 CORS 跨域 - 徐靖峰|个人博客 (cnkirito.moe)](https://www.cnkirito.moe/scg-cors/)

作为一个 Web 开发，一定不会对下面的跨域报错陌生。

![](../images/17.png)

当一个资源从与该资源本身所在的服务器不同的域或端口请求一个资源时，资源会发起一个跨域 HTTP 请求。例如站点 http://www.aliyun.com 的某 HTML 页面请求 http://www.alibaba.com/image.jpg。

出于安全原因，浏览器限制从页面脚本内发起的跨域请求，有些浏览器不会限制跨域请求的发起，但是会将结果拦截。 这意味着使用这些 API 的 Web 应用只能加载同一个域下的资源，除非使用 CORS 机制（Cross-Origin Resource Sharing 跨源资源共享）获取目标服务器的授权来解决这个问题。

这也是本文将要探讨的主要问题，需要额外强调的是，跨域问题产生的主体是“浏览器”，这也是为什么，当我们使用 curl、postman、各种语言的 HTTP 客户端等工具时，从来没有被跨域问题困扰过。

## 一. 什么是跨域

http://www.aliyun.com 站点访问 http://www.alibaba.com/image.jpg 很容易被判断为一个跨域请求，因为域名不一样，同源策略详细描述如下：

- 协议相同
- 域名相同
- 端口相同

以下是跨域与同源的一些示例

| 站点                  | 资源访问                        | 跨域 or 同源                                   |
| :-------------------- | :------------------------------ | :--------------------------------------------- |
| http://www.aliyun.com | http://www.aliyun.com/hello     | 同源                                           |
| http://www.aliyun.com | http://aliyun.com/hello         | 跨域（域名不同，子域名和父域名也属于不同域名） |
| http://www.aliyun.com | https://www.aliyun.com/hello    | 跨域（协议不同）                               |
| http://www.aliyun.com | https://www.aliyun.com:81/hello | 跨域（端口不同）                               |

同源策略存在的原因是为了保护用户的安全和隐私，防止恶意网站对其他网站进行攻击或滥用。如果没有同源机制，以下一些常见的跨域攻击方式将会让网站维护者不堪其扰：

1. CSRF（Cross-Site Request Forgery）：攻击者在恶意网站中放置一个含有恶意请求的页面，并诱使用户访问该页面。当用户在其他网站登录时，恶意请求会自动发送给目标网站，以伪装成用户的操作。这样，攻击者可以利用用户已经登录的凭证进行恶意操作，如修改密码、发起交易等。
2. XSS（Cross-Site Scripting）：攻击者在合法网站的输入框或评论中注入恶意脚本代码。当用户访问包含恶意脚本的页面时，脚本会在用户的浏览器中执行。攻击者可以利用这种方式窃取用户的登录凭证、敏感信息或执行其他恶意操作。
3. Clickjacking：攻击者通过在一个网页上覆盖一个透明的、恶意的图层，来欺骗用户点击看似无害的内容，实际上是触发了恶意操作，如转账或进行其他敏感操作。

解决跨域问题，常见的方案有：

1. CORS（跨域资源共享）：在服务器端设置响应头部，允许指定的域名访问资源。
2. JSONP（JSON with Padding）：通过在页面中动态添加 `<script>` 元素，利用 script 标签的跨域特性来获取数据。
3. 代理服务器：在服务器端设置一个代理服务器，将请求代理转发到目标服务器，绕过浏览器的同源策略。

本文将会主要介绍 CORS 跨域资源共享方案。

## 二. CORS 跨域资源共享介绍

CORS 被定义在 w3c 规范中：https://fetch.spec.whatwg.org/#http-cors-protocol，这里包含了最详细也最官方的描述。它并不是一个框架或者工具，而是一种机制、契约，当浏览器和后端服务同时遵守 CORS 规范时，跨域访问便成了可能。根据使用经验，我们将 CORS 的机制分成了两种模式：简单请求模式和预检请求模式。

同时符合以下条件，就属于简单请求模式：

1. 使用以下 HTTP 方法之一：GET、POST、HEAD
2. 除了简单请求头之外(例如 content-type)，不能包含自定义请求头(例如通过 XMLHttpRequest.setRequestHeader 设置的请求头)
3. Content-Type 为 application/x-www-form-urlencoded、multipart/form-data 或 text/plain 之一 (application/x-www-form-urlencoded 由于是表单格式，属于简单请求，而 application/json 的请求体需要拆包，不属于简单请求)

对于不符合简单请求模式的请求，浏览器将会启用预检请求模式。

### 2.1 简单请求模式

浏览器在出现跨域请求时，会自动给请求携带 Origin 请求头，以下图为例，是 http://edasnext.aliyun.com 发往 http://edas.aliyun.com 的一个跨域请求

![](../images/18.png)

服务端如果要正常支持跨域请求，在判断当前请求为跨域请求时，需要在响应中携带 Access-Control-Allow-Origin、Access-Control-Allow-Methods 等相关的响应头。如果 edasnext.aliyun.com 该来源不在服务端的跨域配置列表中，则返回 403 拒绝该请求。浏览器会检查 Access 相关的响应头，如果没有携带，则会出现文章最开始的跨域报错。

Access to XMLHttpRequest at 'http://edas.aliyun.com/testCors' from origin 'http://edasnext.aliyun.com' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.

### 2.2 简单请求模式-快速开始

为了更加直观理解 CORS 的简单请求模式，本节快速开始给出了一个由 springboot 构建的 demo，它和大多数业务应用的项目结构类似。

**编写 RestController**

```java
@RestController
public class IndexController {

    @RequestMapping("/testCors")
    public String testCors(HttpServletResponse response) {
        System.out.println("hello cors");
        return "hello cors";
    }

}
```

并配置启动端口为 80。

**编写跨域请求前端**

```html
<div id="test"></div>
<input type="button" value="简单请求" onclick="simpleRequest()"/>
</body>
<script>

    function simpleRequest() {
        $.ajax({
            url:'http://edas.aliyun.com/testCors',
            type:'get',
            success:function (msg) {
                $("#test").html(msg);
            }
        })
    }
</script>
```

**配置 hosts**

```properties
127.0.0.1 edas.aliyun.com
127.0.0.1 edasnext.aliyun.com
```

为了方便在本地复现跨域问题，使用同一个后端，配置了两个域名解析，`edasnext.aliyun.com`作为前端访问的入口，`edas.aliyun.com`则作为后端接口的入口，由此构建一个跨域场景。

**跨域测试**

![](../images/19.png)

可以看到，由于当前的 springboot 应用没有进行跨域配置，所以请求失败了。

而如果通过 postman 重放这次请求，请求成功：

![](../images/20.png)

这个实验得出了两个结论：

- 浏览器提示跨域请求失败，服务端可能已经处理完毕，但是由于没有携带 Access 相关响应头，在到达浏览器时，被拒绝了
- 跨域问题的主体是浏览器，服务端是配合的角色

### 2.3 服务端跨域配置

如果仅仅是应对简单请求模式，完全可以直接给响应添加 `Access-Control-Allow-Origin`响应头，但实际的跨域全场景，流程比较复杂，springboot 提供了专门的跨域配置解决该问题：

```java
@Configuration
public class CorsConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/testCors")
        .allowedOrigins("http://edasnext.aliyun.com")
        .allowedMethods("*")
        .allowedHeaders("*")
        .allowCredentials(true)
        .maxAge(3600);
    }
}
```

关于上述 Configuration 中的 CorsRegistry 跨域配置的最佳实践，将会在下文中进行详细介绍。

再次发起跨域请求测试成功。

![](../images/21.png)

至此简单请求模式介绍完毕。

### 2.4 预检请求模式

![](../images/22.png)

预检请求模式相比简单请求模式会多出一个 OPTIONS 请求的流程，这个行为也是浏览器自主产生的。预检请求的必要性主要在于更加安全，方便服务端针对复杂跨域请求进行自主的校验，并且减少了不必要的非正常跨域请求，缺点自然是加大了 CORS 的复杂度。

预检请求成功时，浏览器会接受到预检响应中的信息，该信息包含了是否允许携带 cookie 以及预检的缓存时间，这两个参数都是极其有意义的，前者会在下文继续补充，而后者决定了在一段时间内，针对复杂请求是否仍要发送预检请求。

### 2.5 预检请求模式-快速入门

编写跨域前端

```html
<div id="test"></div>
<input type="button" value="非简单请求" onclick="preflightedRequest()"/>
</body>
<script>

    function preflightedRequest() {
        $.ajax({
            url:'http://edas.aliyun.com/testCors',
            type: 'post',
            data: JSON.stringify({}),
            contentType: 'application/json',
            success:function (msg) {
                $("#test").html(msg);
            }
        })
    }
</script>
```

测试非简单请求

![](../images/23.png)

由于服务端已经配置过跨域了，能够配合浏览器正常处理预检，可以看到浏览器先发送了一次预检请求，后发送了实际请求。

## 三. CORS 跨域配置的最佳实践

以 springboot 提供的 CorsRegistry 跨域配置为例，服务端在处理 CORS 跨域时一般有以下配置：

```java
corsRegistry.addMapping("/**")
            .allowedOrigins("http://edasnext.aliyun.com")
            .allowedMethods("*")
            .allowedHeaders("*")
            .allowCredentials(true)
            .maxAge(3600);
```

其中 allowedOrigins 和 allowCredentials 字段需要格外关注

- allowedOrigins 表明允许哪些跨域来源允许访问该服务端，与 HTTP 请求中的 Origin 请求头对应
- allowCredentials 表明跨域请求是否可以携带 cookie

一个跨域配置的误区是配置 allowedOrigins=* 同时配置 allowCredentials=true

```java
// 错误的示例
corsRegistry.addMapping("/**")
            .allowedOrigins("*")
            .allowedMethods("*")
            .allowedHeaders("*")
            .allowCredentials(true)
            .maxAge(3600);
```

这表明允许任何来源可以进行跨域请求，并且允许携带 cookie。

浏览器的同源策略是基于安全考虑而设置的约束，避免了 CSRF、XSS 等常见的低成本的攻击手段，所以并不能简单认为跨域请求不被浏览器拦截就完事大吉了，需要做的是在没有安全漏洞的前提下保证正常跨域请求能够访问成功。

在 springboot 框架下，允许进行上述的配置，但是实际处理请求时，服务端会出现报错：

java.lang.IllegalArgumentException: When allowCredentials is true, allowedOrigins cannot contain the special value "*" since that cannot be set on the "Access-Control-Allow-Origin" response header. To allow credentials to a set of origins, list them explicitly or consider using "allowedOriginPatterns" instead.] with root cause

这也不见得是一个最佳实践，更加建议在配置时就给出 ERROR 或者 WARN 配置提示，而不是延迟到运行时报错。

服务端跨域的行为并没有明确地被 w3c 规范规定，这导致每个框架都有自己的配置格式以及表现，也有框架默许这样的错误配置。或许这些框架在正常情况下，跨域请求不会被拦截，这种暴风雨前的宁静让框架使用者感到舒心，但遭遇 CSRF、XSS 等攻击时，没有人会感谢这样的“方便”。

一些跨域配置的最佳实践如下：

1. 允许所有来源进行跨域请求时，不允许携带 cookie：

```java
corsRegistry.addMapping("/**")
            .allowedOrigins("*")
            .allowedMethods("*")
            .allowedHeaders("*")
            .allowCredentials(false)
            .maxAge(3600);
```

2. 允许指定来源进行跨域请求时，携带 cookie：

```java
corsRegistry.addMapping("/**")
            .allowedOrigins("http://edasnext.aliyun.com")
            .allowedMethods("*")
            .allowedHeaders("*")
            .allowCredentials(true)
            .maxAge(3600);
```

3. 允许泛域名匹配时携带 cookie：

```java
corsRegistry.addMapping("/**")
            .allowedOriginPatterns("http://*.aliyun.com")
            .allowedMethods("*")
            .allowedHeaders("*")
            .allowCredentials(true)
            .maxAge(3600);
```

当子域名无法枚举时，可以使用这种匹配方式，但不要配置为 `http://*.com`或者 `*`

4. 针对指定的服务端路径进行精细化的跨域配置

```java
corsRegistry.addMapping("/testCors")
            .allowedOrigins("http://edasnext.aliyun.com")
            .allowedMethods("*")
            .allowedHeaders("*")
            .allowCredentials(true)
            .maxAge(3600);
```

## 四. 网关中的跨域配置

在稍微复杂的系统架构中，往往会引入网关组件，跨域配置也是非常适合转移到网关的一项配置，可以将跨域的复杂度和安全性保障，收敛到网关这一个单一组件中。

网关处理跨域问题，请求链路为：浏览器 -> 网关 -> 服务端，根据前面的结论，同源策略只存在于浏览器发起的请求，所以网关向服务端的请求时不存在跨域问题，只需要考虑浏览器 -> 网关这一跳。

以 Spring Cloud Gateway 为例，其提供了开箱即用的跨域能力：

```yml
spring:
  cloud:
    gateway:
      fail-on-route-definition-error: false
      routes:
      - id: r-cors
        predicates:
          - Path=/testCors
        uri: http://edas.aliyun.com
        order: 1000
      globalcors:
        cors-configurations:
          '[/**]':
            allowedOrigins: 'http://edasnext.aliyun.com'
            allowCredentials: true
            allowedMethods:
              - '*'
            allowedHeaders:
              - '*'
            maxAge: 3600
        add-to-simple-url-handler-mapping: true
```

在上述示例中，我们配置了一个 r-cors 路由，转发到本地的后端服务，并且配置了全局的跨域策略，和服务端的配置格式类似。

`add-to-simple-url-handler-mapping`的含义是：如果路由没有配置 OPTIONS 匹配，可以打开此开关，让预检请求成功返回，不会因为跨域的预检而导致路由访问不通。推荐打开此配置，这样在配置路由时，可以只需要关注业务真正的请求方法，而不需要考虑跨域问题。

在网关配置跨域后，后端服务就可以不用处理跨域问题了，去除服务端的 corsRegistry 配置，并且增加请求 Spring Cloud Gateway 网关的测试用例（本地将网关启动在 8080 端口）：

```html
<div id="test"></div>
<input type="button" value="简单请求-网关" onclick="simpleRequestPassbyGateway()"/>
<input type="button" value="非简单请求-网关" onclick="preflightedRequestPassbyGateway()"/>
</body>
<script>

  function simpleRequestPassbyGateway() {
    $.ajax({
      url:'http://127.0.0.1:8080/testCors',
      type:'get',
      data:{},
      success:function (msg) {
        $("#test").html(msg);
      }
    })
  }


  function preflightedRequestPassbyGateway() {
    $.ajax({
      url:'http://127.0.0.1:8080/testCors',
      type: 'post',
      data: JSON.stringify({ }),
      contentType: 'application/json',
      success:function (msg) {
        $("#test").html(msg);
      }
    })
  }
</script>
```

simpleRequestPassbyGateway，preflightedRequestPassbyGateway 会经过网关路由转发至后端服务，根据同源策略 origin=127.0.0.1:8080，而前端域名为 http://edasnext.aliyun.com，这同样是一个跨域请求。

![](../images/24.png)

至此，只需要在网关进行统一配置跨域，后端服务就不用关注跨域问题了。所以，跨域的支持也是主流网关的常用功能之一。

## 五. 网关跨域和服务端跨域共存的问题

试想一下，如果服务端配置了跨域，同时网关配置跨域，表现会如何呢？这种场景一定不会少，例如一个原本配置了跨域的应用，需要接入到网关，一定会存在两份跨域配置共存的时机。还是延续上述的跨域用例，打开服务端的 CorsRegistry 配置，再发送跨域请求至网关，会得到如下报错：

Access to XMLHttpRequest at 'http://127.0.0.1:8080/testCors' from origin 'http://edasnext.aliyun.com' has been blocked by CORS policy: The 'Access-Control-Allow-Origin' header contains multiple values 'http://edasnext.aliyun.com, http://edasnext.aliyun.com', but only one is allowed.

这是因为网关和服务端都会给响应追加跨域请求头，导致浏览器无法识别。

![](../images/25.png)

一个比较简单的开源解决方案是在网关上配置一个过滤器：

```yml
spring:
  cloud:
    gateway:
   default-filters:
        - DedupeResponseHeader=Access-Control-Allow-Credentials Access-Control-Allow-Origin
```

此方案可以去除重复的跨域响应头。

在共存阶段后完成流量迁移，最后建议还是去除服务端的配置。
