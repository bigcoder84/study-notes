# Dubbo消费者无法捕获自定义异常

> 本文转载至：[dubbo 服务提供方抛出自定义异常消费方方无法捕获 - 小李_同志的个人空间 - OSCHINA - 中文开源技术交流社区](https://my.oschina.net/u/4213839/blog/4698249)

我们在业务系统中，经常自定义异常，而自定义异常通常要 继承 RuntimeException 。

在使用dubbo时，如果服务提供者 抛出了自定义的业务异常，这时就会遇到 服务消费者捕获不到这个异常。直接被全局异常处理中的 Exception 处理了，给我们使用自定义异常非常不方便。

答案在dubbo的源码中 ，我们看一下dubbo的异常过滤的源码，异常过滤器在 org.apache.dubbo.rpc.filter.ExceptionFilter

```java
@Override
public void onResponse(Result appResponse, Invoker<?> invoker, Invocation invocation) {
    // 实现GengricService 直接抛出
    if (appResponse.hasException() && GenericService.class != invoker.getInterface()) {
        try {
            Throwable exception = appResponse.getException();

            // CheckedException 异常直接抛出
            // directly throw if it's checked exception
            if (!(exception instanceof RuntimeException) && (exception instanceof Exception)) {
                return;
            }
            // 在方法签名上声明异常，直接抛出
            // directly throw if the exception appears in the signature
            try {
                Method method = invoker.getInterface().getMethod(invocation.getMethodName(), invocation.getParameterTypes());
                Class<?>[] exceptionClassses = method.getExceptionTypes();
                for (Class<?> exceptionClass : exceptionClassses) {
                    if (exception.getClass().equals(exceptionClass)) {
                        return;
                    }
                }
            } catch (NoSuchMethodException e) {
                return;
            }

            // 在方法声明上没有异常，在服务端打 ERROR 日志
            // for the exception not found in method's signature, print ERROR message in server's log.
            logger.error("Got unchecked and undeclared exception which called by " + RpcContext.getContext().getRemoteHost() + ". service: " + invoker.getInterface().getName() + ", method: " + invocation.getMethodName() + ", exception: " + exception.getClass().getName() + ": " + exception.getMessage(), exception);

            // 异常类和接口类在一个jar包中，直接抛出
            // directly throw if exception class and interface class are in the same jar file.
            String serviceFile = ReflectUtils.getCodeBase(invoker.getInterface());
            String exceptionFile = ReflectUtils.getCodeBase(exception.getClass());
            if (serviceFile == null || exceptionFile == null || serviceFile.equals(exceptionFile)) {
                return;
            }
            // JDK自带的异常，java 和 javax 包下的异常直接抛出
            // directly throw if it's JDK exception
            String className = exception.getClass().getName();
            if (className.startsWith("java.") || className.startsWith("javax.")) {
                return;
            }
            // dubbo自己的异常，直接抛出
            // directly throw if it's dubbo exception
            if (exception instanceof RpcException) {
                return;
            }

                        //  其他异常，包装成  RuntimeException 后，抛出
            // otherwise, wrap with RuntimeException and throw back to the client
            appResponse.setException(new RuntimeException(StringUtils.toString(exception)));
            return;
        } catch (Throwable e) {
            logger.warn("Fail to ExceptionFilter when called by " + RpcContext.getContext().getRemoteHost() + ". service: " + invoker.getInterface().getName() + ", method: " + invocation.getMethodName() + ", exception: " + e.getClass().getName() + ": " + e.getMessage(), e);
            return;
        }
    }
}
```

从源码中，我们可以分析出几种解决方案，

- 实现 GengricService，这个接口类主要两个作用，一是泛化服务，简化提供方的操作；二是泛化消费，简化消费方的操作。具体使用办法，再述。
- 继承 Check Exception，个人不习惯自定义异常为CheckException。
- 在方法签名上声明抛出的异常，个人认为这是最简单的一种方式，直接 throws 一下就ok了。
- 将接口类和异常类放置在一个jar中，在dubbo中，项目结构一般是分jar的，如果在不同的jar中，要整合成一个jar，不推荐这样做。