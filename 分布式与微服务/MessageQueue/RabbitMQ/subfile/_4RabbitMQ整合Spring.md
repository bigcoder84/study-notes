# RabbitMQ整合Spring

**spring-amqp**是对AMQP的一些概念的一些抽象，**spring-rabbit**是对RabbitMQ操作的封装实现。

主要有几个核心类 RabbitAdmin、RabbitTemplate、SimpleMessageListenerContainer等 

RabbitAdmin类完成对Exchange，Queue，Binding的操作，在容器中管理了RabbitAdmin类的时候，可以对Exchange，Queue，Binding进行自动声明。

RabbitTemplate类是发送和接收消息的工具类。

SimpleMessageListenerContainer是消费消息的容器。

目前比较新的一些项目都会选择基于注解方式，而比较老的一些项目可能还是基于配置文件的。

## 一. 基于配置文件

### 1.1 添加rabbit-mq依赖

```xml
<dependency>
    <groupId>org.springframework.amqp</groupId>
    <artifactId>spring-rabbit</artifactId>
    <version>2.2.7.RELEASE</version>
</dependency>
```

### 1.2 生产者

#### 1.2.1 配置

```xml
<?xml version="1.0" encoding="utf-8"?>

<beans xmlns="http://www.springframework.org/schema/beans" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rabbit="http://www.springframework.org/schema/rabbit" xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/rabbit http://www.springframework.org/schema/rabbit/spring-rabbit.xsd">  
  <rabbit:connection-factory id="connectionFactory" host="node1" virtual-host="/" username="root" password="123456" port="5672"/>  
  <!--创建一个rabbit的 template对象 (org.springframework.amqp.rabbit.core.RabbitTemplate)， 以便于访问broker-->  
  <rabbit:template id="amqpTemplate" connection-factory="connectionFactory"/>  
  <!-- 自动查找类型是Queue、Exchange、Binding的bean，并为用户向 RabbitMQ声明 -->  
  <!-- 因此，我们不需要显式地在java中声明 -->  
  <rabbit:admin id="rabbitAdmin" connection-factory="connectionFactory"/>  
    
  <!-- 为消费者创建一个队列，如果broker中存在，则使用同名存在的队列，否则创 建一个新的。 -->  
  <rabbit:queue id="q1" name="queue.q1" durable="false" exclusive="false" auto-delete="false" />
    
  <rabbit:direct-exchange name="direct.biz.ex" auto-declare="true" auto-delete="false" durable="false"> 
    <rabbit:bindings> 
      <!--exchange：其他绑定到该交换器的交换器名称-->  
      <!--queue：绑定到该交换器的queue的bean名称-->  
      <!--key：显式声明的路由key-->  
      <rabbit:binding queue="q1" key="dir.ex"></rabbit:binding> 
    </rabbit:bindings> 
  </rabbit:direct-exchange> 
</beans>
```

#### 1.2.2 发送消息

```java
import jdk.jfr.ContentType;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.core.MessageBuilder;
import org.springframework.amqp.core.MessageProperties;
import org.springframework.amqp.core.MessagePropertiesBuilder;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.context.support.AbstractApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

import java.io.UnsupportedEncodingException;

public class ProducerApp {
    public static void main(String[] args) throws UnsupportedEncodingException {
        AbstractApplicationContext context
                = new ClassPathXmlApplicationContext("spring-rabbit.xml");

        RabbitTemplate template = context.getBean(RabbitTemplate.class);

        

        final MessagePropertiesBuilder builder = MessagePropertiesBuilder.newInstance();
        builder.setContentEncoding("gbk");
        builder.setContentType(MessageProperties.CONTENT_TYPE_TEXT_PLAIN);

//      Message msg = MessageBuilder.withBody("你好，世界".getBytes("gbk"))
//                .andProperties(builder.build())
//                .build();
//
//        template.send("ex.direct", "routing.q1", msg);

        for (int i = 0; i < 1000; i++) {
            Message msg = MessageBuilder.withBody(("你好，世界" + i).getBytes("gbk"))
                    .andProperties(builder.build())
                    .build();

            template.send("ex.direct", "routing.q1", msg);
        }

        context.close();
    }
}
```



### 1.3 消费者

#### 1.3.1 配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:rabbit="http://www.springframework.org/schema/rabbit"
       xsi:schemaLocation="http://www.springframework.org/schema/beans
        http://www.springframework.org/schema/beans/spring-beans.xsd
        http://www.springframework.org/schema/rabbit
        http://www.springframework.org/schema/rabbit/spring-rabbit.xsd">

    <rabbit:connection-factory id="connectionFactory" host="node1" virtual-host="/" username="root" password="123456" port="5672" />

    <rabbit:admin id="rabbitAdmin" connection-factory="connectionFactory"/>

    <rabbit:template id="rabbitTemplate" connection-factory="connectionFactory" />

    <!--声明一个消息队列-->
    <rabbit:queue id="q1" name="queue.q1" durable="false" exclusive="false" auto-delete="false" />

    <rabbit:listener-container connection-factory="connectionFactory">
        <rabbit:listener ref="messageListener" queues="q1" />
    </rabbit:listener-container>

    <bean id="messageListener" class="cn.bigcoder.rabbitmq.demo.MyMessageListener"/>

</beans>
```

#### 1.3.2 监听消息

监听队列的消息，我们可以实现`org.springframework.amqp.core.MessageListener`接口：

```java
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.core.MessageListener;

/**
 * 消息处理基类，处理json的反序列化
 */
public class MyMessageListener implements MessageListener {

  protected final Logger LOG = LoggerFactory.getLogger(getClass());

  @Override
  public void onMessage(Message message) {
    String msg = null;
    try {
      msg = new String(message.getBody(), "UTF-8");
      LOG.info("received a new message: {}.", msg);
      if (StringUtils.isBlank(msg)) {
        throw new IllegalArgumentException("empty message!");
      } else {
        handleMessage(msg);
      }
    } catch (Exception e) {
      LOG.error("handle message: {} failed.", msg, e);
    }
  }

}
```

我们也可以实现`org.springframework.amqp.rabbit.core.ChannelAwareMessageListener`。

```java
public interface ChannelAwareMessageListener {

	/**
	 * Callback for processing a received Rabbit message.
	 * <p>Implementors are supposed to process the given Message,
	 * typically sending reply messages through the given Session.
	 * @param message the received AMQP message (never <code>null</code>)
	 * @param channel the underlying Rabbit Channel (never <code>null</code>)
	 * @throws Exception Any.
	 */
	void onMessage(Message message, Channel channel) throws Exception;

}
```

ChannelAwareMessageListener是SpringAMQP的接口，而MessageListener是amqp-core的接口，前者相对于后者，在handle方法上多了Channel参数，方便我们进行其它操作。

## 二. 基于注解

### 2.1 添加rabbit-mq依赖

```xml
<dependency>
    <groupId>org.springframework.amqp</groupId>
    <artifactId>spring-rabbit</artifactId>
    <version>2.2.7.RELEASE</version>
</dependency>
```

### 2.2 生产者

#### 2.2.1 配置

```java
import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.connection.CachingConnectionFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitAdmin;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.net.URI;

@Configuration
public class RabbitConfig {

    // 连接工厂
    @Bean
    public ConnectionFactory connectionFactory() {
        ConnectionFactory factory
                = new CachingConnectionFactory(URI.create("amqp://root:123456@node1:5672/%2f"));
        return factory;
    }

    // RabbitTemplate
    @Bean
    @Autowired
    public RabbitTemplate rabbitTemplate(ConnectionFactory factory) {

        RabbitTemplate rabbitTemplate = new RabbitTemplate(factory);

        return rabbitTemplate;
    }

    // RabbitAdmin
    @Bean
    @Autowired
    public RabbitAdmin rabbitAdmin(ConnectionFactory factory) {
        RabbitAdmin rabbitAdmin = new RabbitAdmin(factory);
        return rabbitAdmin;
    }

    // Queue
    @Bean
    public Queue queue() {
        final Queue queue = QueueBuilder.nonDurable("queue.anno").build();
        return queue;
    }

    // Exchange
    @Bean
    public Exchange exchange() {
        final FanoutExchange fanoutExchange = new FanoutExchange("ex.anno.fanout", false, false, null);
        return fanoutExchange;
    }

    // Binding
    @Bean
    @Autowired
    public Binding binding(Queue queue, Exchange exchange) {
        // 创建一个绑定，不指定绑定的参数
        final Binding binding = BindingBuilder.bind(queue).to(exchange).with("key.anno").noargs();
        return binding;
    }
}
```

#### 2.2.2 发送消息

```java
import org.springframework.amqp.core.Message;
import org.springframework.amqp.core.MessageBuilder;
import org.springframework.amqp.core.MessageProperties;
import org.springframework.amqp.core.MessagePropertiesBuilder;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.context.support.AbstractApplicationContext;

import java.io.UnsupportedEncodingException;

public class ProducerApp {

    public static void main(String[] args) throws UnsupportedEncodingException {
        AbstractApplicationContext context = new AnnotationConfigApplicationContext(RabbitConfig.class);

        final RabbitTemplate template = context.getBean(RabbitTemplate.class);

        final MessageProperties messageProperties = MessagePropertiesBuilder
                .newInstance()
                .setContentType(MessageProperties.CONTENT_TYPE_TEXT_PLAIN)
                .setContentEncoding("gbk")
                .setHeader("myKey", "myValue")
                .build();

//        final Message message = MessageBuilder
//                .withBody("你好，世界".getBytes("gbk"))
//                .andProperties(messageProperties)
//                .build();
//        template.send("ex.anno.fanout", "key.anno", message);

        for (int i = 0; i < 1000; i++) {
            final Message message = MessageBuilder
                    .withBody(("你好，世界" + i).getBytes("gbk"))
                    .andProperties(messageProperties)
                    .build();
            template.send("ex.anno.fanout", "key.anno", message);
        }

        context.close();
    }

}
```

### 2.3 消费者

#### 2.3.1 配置

```java
import org.springframework.amqp.core.AcknowledgeMode;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.amqp.rabbit.annotation.EnableRabbit;
import org.springframework.amqp.rabbit.config.SimpleRabbitListenerContainerFactory;
import org.springframework.amqp.rabbit.connection.CachingConnectionFactory;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitAdmin;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

import java.net.URI;

@ComponentScan("com.lagou.rabbitmq.demo")
@Configuration
//启用@RabbitListener注解，也可以在xml使用<rabbit:annotation-driven /> 
@EnableRabbit  
public class RabbitConfig {

    @Bean
    public ConnectionFactory connectionFactory() {
        return new CachingConnectionFactory(URI.create("amqp://root:123456@node1:5672/%2f"));
    }

    @Bean
    @Autowired
    public RabbitAdmin rabbitAdmin(ConnectionFactory factory) {
        return new RabbitAdmin(factory);
    }

    @Bean
    @Autowired
    public RabbitTemplate rabbitTemplate(ConnectionFactory factory) {
        return new RabbitTemplate(factory);
    }

    @Bean
    public Queue queue() {
        return QueueBuilder.nonDurable("queue.anno").build();
    }


    @Bean("rabbitListenerContainerFactory")
    @Autowired
    public SimpleRabbitListenerContainerFactory simpleRabbitListenerContainerFactory(ConnectionFactory connectionFactory) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        factory.setConnectionFactory(connectionFactory);
        //确认消息的模式
        factory.setAcknowledgeMode(AcknowledgeMode.AUTO);
        //factory.setAcknowledgeMode(AcknowledgeMode.MANUAL);
        //factory.setAcknowledgeMode(AcknowledgeMode.NONE);
        //最少多少个消费者并发消费消息
        factory.setConcurrentConsumers(10);
        //最多多少个消费者并发消费消息
        factory.setMaxConcurrentConsumers(15);
        //按照批次消费消息
        factory.setBatchSize(10);

        return factory;
    }
}

```

#### 2.3.2 监听消息

```java
package com.lagou.rabbitmq.demo;

import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Component;

import java.io.UnsupportedEncodingException;

@Component
public class MyMessageListener {

    /**
     * com.rabbitmq.client.Channel channel对象
     * org.springframework.amqp.core.Message message对象 可以直接操作原生的AMQP消息
     * org.springframework.messaging.Message to use the messaging abstraction counterpart
     * @Payload 注解方法参数，改参数的值就是消息体
     * @Header 注解方法参数，访问指定的消息头字段的值
     * @Headers 该注解的方法参数获取该消息的消息头的所有字段，参数类型对应于map集合。
     * MessageHeaders 参数类型，访问所有消息头字段
     * MessageHeaderAccessor or AmqpMessageHeaderAccessor 访问所有消息头字段
     */
//    @RabbitListener(queues = "queue.anno")
//    public void whenMessageCome(Message message) throws UnsupportedEncodingException {
//        System.out.println(new String(message.getBody(), message.getMessageProperties().getContentEncoding()));
//    }

    @RabbitListener(queues = "queue.anno")
    public void whenMessageCome(@Payload String messageStr) {
        System.out.println(messageStr);
    }

}

```



## 三. SpringBoot整合RabbitMQ

### 3.1 添加依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

### 3.2 连接配置

```properties
spring.application.name=springboot_rabbitmq 
spring.rabbitmq.host=node1 
spring.rabbitmq.virtual-host=/ 
spring.rabbitmq.username=root 
spring.rabbitmq.password=123456 
spring.rabbitmq.port=5672
```

### 3.2 RabbitConfig.java

```java
import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.DirectExchange;
import org.springframework.amqp.core.Exchange;
import org.springframework.amqp.core.Queue;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {
    @Bean
    public Queue myQueue() {
        return new Queue("myqueue");
    }

    @Bean
    public Exchange myExchange() {
        // return new TopicExchange("topic.biz.ex", false, false, null);
        // return new DirectExchange("direct.biz.ex", false, false, null);
        // return new FanoutExchange("fanout.biz.ex", false, false, null);
        //return new CustomExchange("custom.biz.ex", ExchangeTypes.DIRECT, false, false, null);
        return new DirectExchange("myex", false, false, null);
    }

    @Bean
    public Binding myBinding() {
        //1. 目的地名称（队列名称 or 交换机名称），2.绑定的类型：到交换器还是到队列，3.交换器名称，路由key，4.绑定的属性
        //new Binding("", Binding.DestinationType.EXCHANGE, "", "", null);
        //new Binding("", Binding.DestinationType.QUEUE, "", "", null);
        //绑定了交换器direct.biz.ex到队列myqueue，路由key是 direct.biz.ex
        return new Binding("myqueue", Binding.DestinationType.QUEUE, "myex", "direct.biz.ex", null);
    }
}
```



