# Sentinel 整合 Nacos 实现配置持久化

## 一. 概述

Sentinel客户端默认情况下接收到 Dashboard 推送的规则配置后，可以实时生效。但是有一个致命缺陷，Dashboard和业务服务并没有持久化这些配置，当业务服务重启后，这些规则配置将全部丢失。

Sentinel 提供两种方式修改规则：

- 通过 API 直接修改 (`loadRules`)
- 通过 `DataSource` 适配不同数据源修改

通过 API 修改比较直观，可以通过以下几个 API 修改不同的规则：

```java
FlowRuleManager.loadRules(List<FlowRule> rules); // 修改流控规则
DegradeRuleManager.loadRules(List<DegradeRule> rules); // 修改降级规则
```

手动修改规则（硬编码方式）一般仅用于测试和演示，生产上一般通过动态规则源的方式来动态管理规则。

上述 `loadRules()` 方法只接受内存态的规则对象，但更多时候规则存储在文件、数据库或者配置中心当中。`DataSource` 接口给我们提供了对接任意配置源的能力。相比直接通过 API 修改规则，实现 `DataSource` 接口是更加可靠的做法。

我们推荐**通过控制台设置规则后将规则推送到统一的规则中心，客户端实现** `ReadableDataSource` **接口端监听规则中心实时获取变更**，流程如下：

![](../images/7.png)

`DataSource` 扩展常见的实现方式有:

- **拉模式**：客户端主动向某个规则管理中心定期轮询拉取规则，这个规则中心可以是 RDBMS、文件，甚至是 VCS 等。这样做的方式是简单，缺点是无法及时获取变更；
- **推模式**：规则中心统一推送，客户端通过注册监听器的方式时刻监听变化，比如使用 [Nacos](https://github.com/alibaba/nacos)、Zookeeper 等配置中心。这种方式有更好的实时性和一致性保证。

Sentinel 目前支持以下数据源扩展：

- Pull-based: 动态文件数据源、[Consul](https://github.com/alibaba/Sentinel/tree/master/sentinel-extension/sentinel-datasource-consul), [Eureka](https://github.com/alibaba/Sentinel/tree/master/sentinel-extension/sentinel-datasource-eureka)
- Push-based: [ZooKeeper](https://github.com/alibaba/Sentinel/tree/master/sentinel-extension/sentinel-datasource-zookeeper), [Redis](https://github.com/alibaba/Sentinel/tree/master/sentinel-extension/sentinel-datasource-redis), [Nacos](https://github.com/alibaba/Sentinel/tree/master/sentinel-extension/sentinel-datasource-nacos), [Apollo](https://github.com/alibaba/Sentinel/tree/master/sentinel-extension/sentinel-datasource-apollo), [etcd](https://github.com/alibaba/Sentinel/tree/master/sentinel-extension/sentinel-datasource-etcd)

## 二. 从 Nacos 加载规则配置

第一步：引入依赖

```xml
<dependency>
    <groupId>com.alibaba.csp</groupId>
    <artifactId>sentinel-datasource-nacos</artifactId>
    <version>1.8.6</version>
</dependency>
```

第二步：配置规则自动加载

```java
package cn.bigcoder.demo.sentinel.sentineldemo.demos.config;

import com.alibaba.csp.sentinel.datasource.ReadableDataSource;
import com.alibaba.csp.sentinel.datasource.nacos.NacosDataSource;
import com.alibaba.csp.sentinel.slots.block.flow.FlowRule;
import com.alibaba.csp.sentinel.slots.block.flow.FlowRuleManager;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.TypeReference;
import com.alibaba.nacos.api.PropertyKeyConst;
import java.util.List;
import java.util.Properties;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.stereotype.Component;

@Component
public class SentinelRuleConfiguration implements ApplicationListener<ContextRefreshedEvent> {

    private static final String remoteAddress = "10.10.10.12:8848";
    // nacos group
    private static final String groupId = "sentinel-config";
    // nacos dataId
    private static final String dataId = "sentinel-demo";

//    private static final String NACOS_NAMESPACE_ID = "sentinel-config";

    @Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
        Properties properties = new Properties();
        properties.put(PropertyKeyConst.SERVER_ADDR, remoteAddress);
//        properties.put(PropertyKeyConst.NAMESPACE, NACOS_NAMESPACE_ID);

        ReadableDataSource<String, List<FlowRule>> flowRuleDataSource = new NacosDataSource<>(properties, groupId,
                dataId,
                source -> JSON.parseObject(source, new TypeReference<List<FlowRule>>() {
                }));
        FlowRuleManager.register2Property(flowRuleDataSource.getProperty());
    }
}
```

第三步：往Nacos中写入配置

```java
import com.alibaba.nacos.api.NacosFactory;
import com.alibaba.nacos.api.config.ConfigService;

/**
 * Nacos config sender for demo.
 *
 * @author Eric Zhao
 */
public class NacosConfigSender {

    public static void main(String[] args) throws Exception {
        // nacos地址
        final String remoteAddress = "10.10.10.12:8848";
        final String groupId = "sentinel-config";
        final String dataId = "sentinel-demo";
        final String rule = "[\n"
            + "  {\n"
            + "    \"resource\": \"GET:/user/getById\",\n"
            + "    \"controlBehavior\": 0,\n"
            + "    \"count\": 1,\n"
            + "    \"grade\": 1,\n"
            + "    \"limitApp\": \"default\",\n"
            + "    \"strategy\": 0\n"
            + "  }\n"
            + "]";
        ConfigService configService = NacosFactory.createConfigService(remoteAddress);
        System.out.println(configService.publishConfig(dataId, groupId, rule));
    }
}
```

执行完后，Nacos中就会出现对应的配置：

![](../images/8.png)

第四步：启动项目，验证规则配置是否生效

访问 [http://127.0.0.1:8719/getParamRules?type=flow](http://127.0.0.1:8719/getParamRules?type=flow) 即可看到业务服务内存中加载到的规则配置

![](../images/9.png)

并发执行 `/user/getById` 接口，可以发现接口被成功限流，1s内的10次请求，只有一次成功。

![](../images/10.png)

## 三. 问题

使用此方案虽然解决了配置规则配置持久化的问题，但是在Dashboard上修改配置仍然是通过业务服务暴露的接口进行的配置同步。业务服务既可以接收 Nacos 配置变更，又可以接收Dashboard的配置变更，控制台的变更的配置并没有同步到Nacos，应用重启后Sentinel控制台修改的配置仍然会全部丢失：

![](../images/11.png)

一个理想的情况是Sentinel控制台规则配置读取至 Nacos 而不是内存，在控制台修改/新增的配置写入Nacos，当Nacos配置发生变更时，配置进而自动同步至业务服务：

![](../images/7.png)

当然存储媒介可以根据情况选用别的组件：[ZooKeeper](https://github.com/alibaba/Sentinel/tree/master/sentinel-extension/sentinel-datasource-zookeeper), [Redis](https://github.com/alibaba/Sentinel/tree/master/sentinel-extension/sentinel-datasource-redis), [Apollo](https://github.com/alibaba/Sentinel/tree/master/sentinel-extension/sentinel-datasource-apollo), [etcd](https://github.com/alibaba/Sentinel/tree/master/sentinel-extension/sentinel-datasource-etcd)

很可惜的是，阿里官方开源的Sentinel控制台并没有实现将规则配置写入其他中间件的能力。它默认只支持将配置实时推送至业务服务，所以我们在生产环境中想要使用 Sentinel Dashboard 需要自行修改其源码，将其配置同步逻辑改为写入我们所需要的中间件中。