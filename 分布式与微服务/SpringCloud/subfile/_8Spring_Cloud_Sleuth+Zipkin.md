# Spring Cloud Sleuth + Zipkin

> 本文参考：[使用Spring Cloud Sleuth跟踪微服务 | MrBird](https://mrbird.cc/Spring-Cloud-sleuth.html)

在微服务数量较多的系统架构中，一个完整的HTTP请求可能需要经过好几个微服务。如果想要跟踪一条完整的HTTP请求链路所产生的日志，我们需要到各个微服务上去查看日志并检索出我们需要的信息。随着业务发展，微服务的数量也会越来越多，这个过程也变得愈发困难。不过不用担心，[Spring Cloud Sleuth](https://github.com/spring-cloud/spring-cloud-sleuth)为我们提供了分布式服务跟踪的解决方案。为了演示如何使用Spring Cloud Sleuth，我们需要构建一个小型的微服务系统。

