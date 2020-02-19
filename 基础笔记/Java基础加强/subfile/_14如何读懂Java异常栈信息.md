# 如何读懂Java异常栈信息

## 一. 基本的异常打印

```java
public class Test {

    public static void main(String[] args) {
        fun1();//第4行
    }

    public static void fun1() {
        fun2();//第8行
    }

    public static void fun2() {
        fun3();
    }

    public static void fun3() {
        fun4();
    }
}
```
上述代码打印的异常栈信息是这样的：

```java
java.lang.RuntimeException: fun4
	at _27异常栈.Test.fun4(Test.java:32)
	at _27异常栈.Test.fun3(Test.java:24)
	at _27异常栈.Test.fun2(Test.java:19)
	at _27异常栈.Test.fun1(Test.java:15)
	at _27异常栈.Test.main(Test.java:11)
```

首先需要明确的是，在方法的调用链条中，当执行到fun4方法时，虚拟机栈的状态是这样的：

![](../images/74.png)

因为程序的方法入口是main，所以虚拟机创建main方法对应的栈帧（栈帧中保存着局部变量表、操作数栈、动态链接等），然后将main栈帧压栈，在执行到第四行的时候，发现调用了fun1方法，则将又创建fun1方法的栈帧并入栈，当执行到第8行调用fun3.......      

直到进入fun4方法，虚拟机栈的样子就如上图所示。现在虚拟机栈的栈顶是fun4方法，所以执行的是fun4方法，但是在fun4方法中抛出了异常，`那么虚拟机生成Exception实例中就会保存整个调用链的虚拟机栈信息`，异常对象生成后fun4方法就会提前结束，Exception对象会一直沿着调用链的反方向移动，直到进入main方法后，被虚拟机捕获，此时才打印出Exception对象中的栈信息。**打印的顺序同样是按照出栈顺序打印的**。

## 二. 构建带原因的异常栈

```java
public class Test {
                                        
    public static void fun1() {
        fun2();
    }

    public static void fun2() {
        fun3();
    }

    public static void fun3() {
        try {
            fun4();
        } catch (Exception e) {
            throw new RuntimeException("fun3",e);
        }
    }

    public static void fun4() {
        throw new RuntimeException("fun4");
    }

    public static void main(String[] args) {
        fun1();
    }
}

```

打印出来的异常信息如下：

![](../images/75.png)

我们可以通过`Exception(String message, Throwable cause)`构造器来**指定抛出异常的原因**，在上面的异常栈信息中，第一部分的`java.lang.RuntimeException`是在fun3中抛出的，所以第一部分打印的是从fun3到main的栈信息，但是fun3中抛出的异常中传入了一个`cause`，用于设置抛出该异常的原因。

所以就有了第二部分的`Caused by`，这个打印的是fun3中捕获的异常的栈信息。而fun4中抛出的异常的栈信息前半部分与第一部分异常栈重合，所以printStackTrace()方法省略了这部分的打印。

### 2.1 异常栈的流程分析

![](../images/76.png)

## 三. 项目异常实践

理论上来说，异常栈信息最终都能追踪到`main`方法或者`Thread.run`方法。

```java
org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'endpoint' defined in class path resource [cn/uni/app/config/CxfConfig.class]: Bean instantiation via factory method failed; nested exception is org.springframework.beans.BeanInstantiationException: Failed to instantiate [javax.xml.ws.Endpoint]: Factory method 'endpoint' threw exception; nested exception is java.lang.NoSuchFieldError: REFLECTION
	at org.springframework.beans.factory.support.ConstructorResolver.instantiateUsingFactoryMethod(ConstructorResolver.java:599) ~[ConstructorResolver.class:4.3.6.RELEASE]
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.instantiateUsingFactoryMethod(AbstractAutowireCapableBeanFactory.java:1173) ~[AbstractAutowireCapableBeanFactory.class:4.3.6.RELEASE]
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBeanInstance(AbstractAutowireCapableBeanFactory.java:1067) ~[AbstractAutowireCapableBeanFactory.class:4.3.6.RELEASE]
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.doCreateBean(AbstractAutowireCapableBeanFactory.java:513) ~[AbstractAutowireCapableBeanFactory.class:4.3.6.RELEASE]
	at org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory.createBean(AbstractAutowireCapableBeanFactory.java:483) ~[AbstractAutowireCapableBeanFactory.class:4.3.6.RELEASE]
	at org.springframework.beans.factory.support.AbstractBeanFactory$1.getObject(AbstractBeanFactory.java:306) ~[AbstractBeanFactory$1.class:4.3.6.RELEASE]
	at org.springframework.beans.factory.support.DefaultSingletonBeanRegistry.getSingleton(DefaultSingletonBeanRegistry.java:230) ~[DefaultSingletonBeanRegistry.class:4.3.6.RELEASE]
	at org.springframework.beans.factory.support.AbstractBeanFactory.doGetBean(AbstractBeanFactory.java:302) ~[AbstractBeanFactory.class:4.3.6.RELEASE]
	at org.springframework.beans.factory.support.AbstractBeanFactory.getBean(AbstractBeanFactory.java:197) ~[AbstractBeanFactory.class:4.3.6.RELEASE]
	at org.springframework.beans.factory.support.DefaultListableBeanFactory.preInstantiateSingletons(DefaultListableBeanFactory.java:761) ~[DefaultListableBeanFactory.class:4.3.6.RELEASE]
	at org.springframework.context.support.AbstractApplicationContext.finishBeanFactoryInitialization(AbstractApplicationContext.java:866) ~[AbstractApplicationContext.class:4.3.6.RELEASE]
	at org.springframework.context.support.AbstractApplicationContext.refresh(AbstractApplicationContext.java:542) ~[AbstractApplicationContext.class:4.3.6.RELEASE]
	at org.springframework.boot.context.embedded.EmbeddedWebApplicationContext.refresh(EmbeddedWebApplicationContext.java:122) ~[EmbeddedWebApplicationContext.class:1.5.1.RELEASE]
	at org.springframework.boot.SpringApplication.refresh(SpringApplication.java:737) ~[SpringApplication.class:1.5.1.RELEASE]
	at org.springframework.boot.SpringApplication.refreshContext(SpringApplication.java:370) ~[SpringApplication.class:1.5.1.RELEASE]
	at org.springframework.boot.SpringApplication.run(SpringApplication.java:314) ~[SpringApplication.class:1.5.1.RELEASE]
	at org.springframework.boot.web.support.SpringBootServletInitializer.run(SpringBootServletInitializer.java:152) [SpringBootServletInitializer.class:1.5.1.RELEASE]
	at org.springframework.boot.web.support.SpringBootServletInitializer.createRootApplicationContext(SpringBootServletInitializer.java:132) [SpringBootServletInitializer.class:1.5.1.RELEASE]
	at org.springframework.boot.web.support.SpringBootServletInitializer.onStartup(SpringBootServletInitializer.java:87) [SpringBootServletInitializer.class:1.5.1.RELEASE]
	at org.springframework.web.SpringServletContainerInitializer.onStartup(SpringServletContainerInitializer.java:169) [SpringServletContainerInitializer.class:4.3.6.RELEASE]
	at org.apache.catalina.core.StandardContext.startInternal(StandardContext.java:5173) [catalina.jar:8.0.9]
	at org.apache.catalina.util.LifecycleBase.start(LifecycleBase.java:150) [catalina.jar:8.0.9]
	at org.apache.catalina.core.ContainerBase.addChildInternal(ContainerBase.java:724) [catalina.jar:8.0.9]
	at org.apache.catalina.core.ContainerBase.addChild(ContainerBase.java:700) [catalina.jar:8.0.9]
	at org.apache.catalina.core.StandardHost.addChild(StandardHost.java:714) [catalina.jar:8.0.9]
	at org.apache.catalina.startup.HostConfig.deployWAR(HostConfig.java:919) [catalina.jar:8.0.9]
	at org.apache.catalina.startup.HostConfig$DeployWar.run(HostConfig.java:1704) [catalina.jar:8.0.9]
	at java.util.concurrent.Executors$RunnableAdapter.call(Unknown Source) [na:1.8.0_211]
	at java.util.concurrent.FutureTask.run(Unknown Source) [na:1.8.0_211]
	at java.util.concurrent.ThreadPoolExecutor.runWorker(Unknown Source) [na:1.8.0_211]
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(Unknown Source) [na:1.8.0_211]
	at java.lang.Thread.run(Unknown Source) [na:1.8.0_211]
Caused by: org.springframework.beans.BeanInstantiationException: Failed to instantiate [javax.xml.ws.Endpoint]: Factory method 'endpoint' threw exception; nested exception is java.lang.NoSuchFieldError: REFLECTION
	at org.springframework.beans.factory.support.SimpleInstantiationStrategy.instantiate(SimpleInstantiationStrategy.java:189) ~[SimpleInstantiationStrategy.class:4.3.6.RELEASE]
	at org.springframework.beans.factory.support.ConstructorResolver.instantiateUsingFactoryMethod(ConstructorResolver.java:588) ~[ConstructorResolver.class:4.3.6.RELEASE]
	... 31 common frames omitted
Caused by: java.lang.NoSuchFieldError: REFLECTION
	at com.sun.xml.bind.v2.model.impl.RuntimeModelBuilder.<init>(RuntimeModelBuilder.java:87) ~[RuntimeModelBuilder.class:2.1.6]
	at com.sun.xml.bind.v2.runtime.JAXBContextImpl.getTypeInfoSet(JAXBContextImpl.java:422) ~[JAXBContextImpl.class:2.1.6]
	at com.sun.xml.bind.v2.runtime.JAXBContextImpl.<init>(JAXBContextImpl.java:286) ~[JAXBContextImpl.class:2.1.6]
	at com.sun.xml.bind.v2.ContextFactory.createContext(ContextFactory.java:139) ~[ContextFactory.class:2.1.6]
	at com.sun.xml.bind.v2.ContextFactory.createContext(ContextFactory.java:117) ~[ContextFactory.class:2.1.6]
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method) ~[na:1.8.0_211]
	at sun.reflect.NativeMethodAccessorImpl.invoke(Unknown Source) ~[na:1.8.0_211]
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source) ~[na:1.8.0_211]
	at java.lang.reflect.Method.invoke(Unknown Source) ~[na:1.8.0_211]
	at javax.xml.bind.ContextFinder.newInstance(Unknown Source) ~[na:1.8.0_211]
	at javax.xml.bind.ContextFinder.newInstance(Unknown Source) ~[na:1.8.0_211]
	at javax.xml.bind.ContextFinder.find(Unknown Source) ~[na:1.8.0_211]
	at javax.xml.bind.JAXBContext.newInstance(Unknown Source) ~[na:1.8.0_211]
	at org.apache.cxf.common.jaxb.JAXBContextCache$2.run(JAXBContextCache.java:348) ~[JAXBContextCache$2.class:3.1.6]
	at org.apache.cxf.common.jaxb.JAXBContextCache$2.run(JAXBContextCache.java:346) ~[JAXBContextCache$2.class:3.1.6]
	at java.security.AccessController.doPrivileged(Native Method) ~[na:1.8.0_211]
	at org.apache.cxf.common.jaxb.JAXBContextCache.createContext(JAXBContextCache.java:346) ~[JAXBContextCache.class:3.1.6]
	at org.apache.cxf.common.jaxb.JAXBContextCache.getCachedContextAndSchemas(JAXBContextCache.java:247) ~[JAXBContextCache.class:3.1.6]
	at org.apache.cxf.jaxb.JAXBDataBinding.createJAXBContextAndSchemas(JAXBDataBinding.java:472) ~[JAXBDataBinding.class:3.1.6]
	at org.apache.cxf.jaxb.JAXBDataBinding.initialize(JAXBDataBinding.java:327) ~[JAXBDataBinding.class:3.1.6]
	at org.apache.cxf.service.factory.AbstractServiceFactoryBean.initializeDataBindings(AbstractServiceFactoryBean.java:86) ~[AbstractServiceFactoryBean.class:3.1.6]
	at org.apache.cxf.wsdl.service.factory.ReflectionServiceFactoryBean.buildServiceFromClass(ReflectionServiceFactoryBean.java:467) ~[ReflectionServiceFactoryBean.class:3.1.6]
	at org.apache.cxf.jaxws.support.JaxWsServiceFactoryBean.buildServiceFromClass(JaxWsServiceFactoryBean.java:696) ~[JaxWsServiceFactoryBean.class:3.1.6]
	at org.apache.cxf.wsdl.service.factory.ReflectionServiceFactoryBean.initializeServiceModel(ReflectionServiceFactoryBean.java:527) ~[ReflectionServiceFactoryBean.class:3.1.6]
	at org.apache.cxf.wsdl.service.factory.ReflectionServiceFactoryBean.create(ReflectionServiceFactoryBean.java:261) ~[ReflectionServiceFactoryBean.class:3.1.6]
	at org.apache.cxf.jaxws.support.JaxWsServiceFactoryBean.create(JaxWsServiceFactoryBean.java:199) ~[JaxWsServiceFactoryBean.class:3.1.6]
	at org.apache.cxf.frontend.AbstractWSDLBasedEndpointFactory.createEndpoint(AbstractWSDLBasedEndpointFactory.java:102) ~[AbstractWSDLBasedEndpointFactory.class:3.1.6]
	at org.apache.cxf.frontend.ServerFactoryBean.create(ServerFactoryBean.java:168) ~[ServerFactoryBean.class:3.1.6]
	at org.apache.cxf.jaxws.JaxWsServerFactoryBean.create(JaxWsServerFactoryBean.java:211) ~[JaxWsServerFactoryBean.class:3.1.6]
	at org.apache.cxf.jaxws.EndpointImpl.getServer(EndpointImpl.java:460) ~[EndpointImpl.class:3.1.6]
	at org.apache.cxf.jaxws.EndpointImpl.doPublish(EndpointImpl.java:338) ~[EndpointImpl.class:3.1.6]
	at org.apache.cxf.jaxws.EndpointImpl.publish(EndpointImpl.java:255) ~[EndpointImpl.class:3.1.6]
	at cn.uni.app.config.CxfConfig.endpoint(CxfConfig.java:40) ~[CxfConfig.class:na]
	at cn.uni.app.config.CxfConfig$$EnhancerBySpringCGLIB$$6777d22.CGLIB$endpoint$3(<generated>) ~[CxfConfig.class:na]
	at cn.uni.app.config.CxfConfig$$EnhancerBySpringCGLIB$$6777d22$$FastClassBySpringCGLIB$$8922793f.invoke(<generated>) ~[CxfConfig.class:na]
	at org.springframework.cglib.proxy.MethodProxy.invokeSuper(MethodProxy.java:228) ~[MethodProxy.class:4.3.6.RELEASE]
	at org.springframework.context.annotation.ConfigurationClassEnhancer$BeanMethodInterceptor.intercept(ConfigurationClassEnhancer.java:356) ~[ConfigurationClassEnhancer$BeanMethodInterceptor.class:4.3.6.RELEASE]
	at cn.uni.app.config.CxfConfig$$EnhancerBySpringCGLIB$$6777d22.endpoint(<generated>) ~[CxfConfig.class:na]
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method) ~[na:1.8.0_211]
	at sun.reflect.NativeMethodAccessorImpl.invoke(Unknown Source) ~[na:1.8.0_211]
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(Unknown Source) ~[na:1.8.0_211]
	at java.lang.reflect.Method.invoke(Unknown Source) ~[na:1.8.0_211]
	at org.springframework.beans.factory.support.SimpleInstantiationStrategy.instantiate(SimpleInstantiationStrategy.java:162) ~[SimpleInstantiationStrategy.class:4.3.6.RELEASE]
	... 32 common frames omitted
```

该异常是SpringBoot项目整合WebService启动时的错误，因为Spring框架抛出了`BeanCreationException`导致项目启动失败，而抛出这个异常是因为在`ConstructorResolver.instantiateUsingFactoryMethod(ConstructorResolver.java:599) `中捕获到了`BeanInstantiationException`异常，而`BeanInstantiationException`异常的抛出又是因为在`SimpleInstantiationStrategy.instantiate(SimpleInstantiationStrategy.java:189)
	`捕获到了`NoSuchFieldError`

## 四. 总结

- 异常栈信息的第一行就是抛出这个异常的最原始的位置。
- 异常栈信息的最后一行就是最开始调用的地方。
- 如果异常栈信息后面跟着`Cause by`，就证明抛出当前异常的原因是捕获到了下面的异常。