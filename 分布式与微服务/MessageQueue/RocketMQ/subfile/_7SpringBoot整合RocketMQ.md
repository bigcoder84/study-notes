# SpringBoot整合RocketMQ

> 本文参考至：[发送消息 · apache/rocketmq-spring Wiki (github.com)](https://github.com/apache/rocketmq-spring/wiki/发送消息)

## 一. 依赖

```xml
<!--在pom.xml中添加依赖-->
<dependency>
    <groupId>org.apache.rocketmq</groupId>
    <artifactId>rocketmq-spring-boot-starter</artifactId>
    <version>${RELEASE.VERSION}</version>
</dependency>
```

## 二. 生产者

### 2.1 配置

```yaml
rocketmq:
  name-server: 192.168.0.10:9876 #RocketMQ的NameServer地址与端口
  producer:
    group: rocket-mq-producer-demo
```

### 2.2 发送消息

```java
@RestController
public class MessageController {

    @Autowired
    private RocketMQTemplate rabbitTemplate;

    @RequestMapping("/send")
    public String sendMessage(String msg) {
        String messageId = String.valueOf(UUID.randomUUID());
        String createTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        Map<String, Object> map = new HashMap<>();
        map.put("messageId", messageId);
        map.put("createTime", createTime);
        map.put("msg", msg);
        rabbitTemplate.convertAndSend("rocket-mq-queue", map);
        return messageId;
    }
}

```

发送消息的API比较多：

```java
    public void run(String... args) throws Exception {
      	//同步发送
        rocketMQTemplate.convertAndSend("test-topic-1", "Hello, World!");
      	//send spring message
        rocketMQTemplate.send("test-topic-1", MessageBuilder.withPayload("Hello, World! I'm from spring message").build());
        //异步发送
      	rocketMQTemplate.asyncSend("test-topic-2", new OrderPaidEvent("T_001", new BigDecimal("88.00")), new SendCallback() {
            @Override
            public void onSuccess(SendResult var1) {
                System.out.printf("async onSucess SendResult=%s %n", var1);
            }

            @Override
            public void onException(Throwable var1) {
                System.out.printf("async onException Throwable=%s %n", var1);
            }

        });
      	//发送顺序消息
      	rocketMQTemplate.syncSendOrderly("orderly_topic",MessageBuilder.withPayload("Hello, World").build(),"hashkey")
    }
    
    @Data
    @AllArgsConstructor
    public class OrderPaidEvent implements Serializable{
        private String orderId;
        
        private BigDecimal paidMoney;
    }
```

## 三. 消费者

### 3.1 配置

```yaml
rocketmq:
  name-server: 192.168.0.10:9876 #RocketMQ的NameServer地址与端口
  producer:
    group: rocket-mq-consumer-demo
```

### 3.2 push模式

```java
@SpringBootApplication
public class ConsumerApplication{
    
    public static void main(String[] args){
        SpringApplication.run(ConsumerApplication.class, args);
    }
    
    @Slf4j
    @Service
    @RocketMQMessageListener(topic = "test-topic-1", consumerGroup = "my-consumer_test-topic-1")
    public class MyConsumer1 implements RocketMQListener<String>{
        public void onMessage(String message) {
            log.info("received message: {}", message);
        }
    }
    
    @Slf4j
    @Service
    @RocketMQMessageListener(topic = "test-topic-2", consumerGroup = "my-consumer_test-topic-2")
    public class MyConsumer2 implements RocketMQListener<OrderPaidEvent>{
        public void onMessage(OrderPaidEvent orderPaidEvent) {
            log.info("received orderPaidEvent: {}", orderPaidEvent);
        }
    }
}
```

### 3.3 pull模式

从`RocketMQ Spring 2.2.0`开始，RocketMQ Srping支持Pull模式消费

修改application.properties

```yml
rocketmq.name-server=127.0.0.1:9876
rocketmq.consumer.group=my-group1
rocketmq.consumer.topic=test
```

编写代码

```java
@SpringBootApplication
public class ConsumerApplication implements CommandLineRunner {

    @Resource
    private RocketMQTemplate rocketMQTemplate;

    @Resource(name = "extRocketMQTemplate")
    private RocketMQTemplate extRocketMQTemplate;

    public static void main(String[] args) {
        SpringApplication.run(ConsumerApplication.class, args);
    }

    @Override
    public void run(String... args) throws Exception {
        //This is an example of pull consumer using rocketMQTemplate.
        List<String> messages = rocketMQTemplate.receive(String.class);
        System.out.printf("receive from rocketMQTemplate, messages=%s %n", messages);

        //This is an example of pull consumer using extRocketMQTemplate.
        messages = extRocketMQTemplate.receive(String.class);
        System.out.printf("receive from extRocketMQTemplate, messages=%s %n", messages);
    }
}
```

