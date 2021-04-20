# Spring Cloud Ribbon

Spring Cloud Ribbon是基于Netflix Ribbon实现的一套客户端负载均衡器；

Ribbon是Netflix公司发布的开源项目，主要功能是提供客户端的负载均衡算法，它会从eureka中获取一个可用的服务端清单，通过心跳检测来剔除故障的服务端节点以保证清单中都是可以正常访问的服务端节点。

当客户端发送请求，则Ribbon负载均衡器按某种算法（比如轮询、权重、 最小连接数等）从维护的可用服务端清单中取出一台服务端的地址，然后进行请求；

Spring Cloud 对 Ribbon 做了二次封装，可以让我们使用 RestTemplate 的服务请求，自动转换成客户端负载均衡的服务调用。Ribbon 支持多种负载均衡算法，还支持自定义的负载均衡算法。

## 一. 传统的Rest服务调用

假设现在我们有两个服务`admin-web`、`admin-dl`，









第一步：引入依赖

```xml

```

