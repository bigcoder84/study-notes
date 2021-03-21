# Dubbo使用Nacos做注册中心

[Nacos](https://github.com/alibaba/nacos) 致力于帮助您发现、配置和管理微服务。Nacos 提供了一组简单易用的特性集，帮助您快速实现动态服务发现、服务配置、服务元数据及流量管理。Nacos 帮助您更敏捷和容易地构建、交付和管理微服务平台。Nacos 是构建以“服务”为中心的现代应用架构 (例如微服务范式、云原生范式) 的服务基础设施。

在接下里的教程中，将使用 Nacos 作为微服务架构中的注册中心，替代 ZooKeeper 传统方案。

### 第一步：引入Nacos客户端

```xml
<dependency>
    <groupId>com.alibaba.nacos</groupId>
    <artifactId>nacos-client</artifactId>
    <version>${nacos.version}</version>
</dependency>
```

### 第二步：配置注册中心

```yml
dubbo:
  protocol:
    name: dubbo
    threads: 10
  application:
    name: multi-tenant-user-dl
  registry:
    address: nacos://192.168.0.10:7008
  config-center: 
    address: nacos://192.168.0.10:7008
  metadata-report: 
    address: nacos://192.168.0.10:7008
```

