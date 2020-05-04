# MyBatis动态代理调用过程源码分析

MyBatis提供了一种动态代理实现SQL调用的功能，使用者只需要在映射文件中配置SQL语句与映射规则即可完成SQL调用和结果集封装。下面代码展示了动态代理调用的基本步骤：

```java
public void testMyBatisBuild() throws IOException {
    InputStream input = Resources.getResourceAsStream("SqlSessionConfig.xml");
    SqlSessionFactory sessionFactory = new SqlSessionFactoryBuilder().build(input);
    SqlSession sqlSession = sessionFactory.openSession();
    TestMapper mapper = sqlSession.getMapper(TestMapper.class);
    Student student = mapper.getStudentByIdToResultType("00000b373502481baa1a5f5229507cf8");
    System.out.println(student);
}
```

而我们通过`getMapper`方法只是传入了一个接口，在整个项目中我们没有一个`TestMapper`的实现类，那MyBatis是如何帮我们生成实现类的，这一点就需要我们去分析源码了。

## 一. DefaultSqlSessionFactory

```java
SqlSessionFactory sessionFactory = new SqlSessionFactoryBuilder().build(input);
```

`build`方法用于解析配置文件并生成`SqlSessionFactory`，我们通过跟踪`build`方法的源码，我们可以发现，`build`方法实际上返回的是`DefaultSqlSessionFactory`的实例。`DefaultSqlSessionFactory`就是`SqlSessionFactory`接口的唯一实现类。

```java
public SqlSessionFactory build(InputStream inputStream, String environment) {
    return build(inputStream, environment, null);
 }
public SqlSessionFactory build(InputStream inputStream, String environment, Properties properties) {
    try {
      //创建XMLConfigBuilder，用于解析配置文件
      XMLConfigBuilder parser = new XMLConfigBuilder(inputStream, environment, properties);
      return build(parser.parse());
    } catch (Exception e) {
      throw ExceptionFactory.wrapException("Error building SqlSession.", e);
    } finally {
      ErrorContext.instance().reset();
      try {
        inputStream.close();
      } catch (IOException e) {
        // Intentionally ignore. Prefer previous error.
      }
    }
  }
public SqlSessionFactory build(Configuration config) {
  return new DefaultSqlSessionFactory(config);
}
```

`

## 二. DefaultSqlSession

### 2.1 openSession()

```java
SqlSession sqlSession = sessionFactory.openSession();
```

上面代码是通过`SqlSessionFactory`获取`SqlSession`的代码，我们进入`DefaultSqlSessionFactory::openSession`方法一探究竟，看看它底层到底做了什么。

可以看到`DefaultSqlSessionFactory::openSession`方法最终生成了一个`DefaultSqlSession`实例，它就是Mybatis核心接口`SqlSession`的实现类。

```java
public SqlSession openSession() {
  //从数据源中获取连接，然后创建SqlSessionFactory
  return openSessionFromDataSource(configuration.getDefaultExecutorType(), null, false);
}
private SqlSession openSessionFromDataSource(ExecutorType execType, TransactionIsolationLevel level, boolean autoCommit) {
  Transaction tx = null;
  try {
    //获取mybatis-config.xml中的enviroment对象
    final Environment environment = configuration.getEnvironment();
    //从Enviroment获取TranslationFactory
    final TransactionFactory transactionFactory = getTransactionFactoryFromEnvironment(environment);
    //从数据源中获取数据库连接，然后创建Transaction对象
    tx = transactionFactory.newTransaction(environment.getDataSource(), level, autoCommit);
    //重点：根据配置创建Executor，该方法内部会根据用户是否配置二级缓存去决定是否创建二级缓存的装饰器去装饰Executor，这也是二级缓存是否生效的关键
    final Executor executor = configuration.newExecutor(tx, execType);
    //创建DefaultSqlSession
    return new DefaultSqlSession(configuration, executor, autoCommit);
  } catch (Exception e) {
    closeTransaction(tx); // may have fetched a connection so lets call close()
    throw ExceptionFactory.wrapException("Error opening session.  Cause: " + e, e);
  } finally {
    ErrorContext.instance().reset();
  }
}
```

### 2.2 getMapper()获取动态代理实例

```java
TestMapper mapper = sqlSession.getMapper(TestMapper.class);
```

走到这里我们就来到今天主题的核心，我们现在就来抽丝剥茧般的看看MyBatis是如何帮我们生成动态代理实现类的。

首先我们进入`DefaultSqlSession::getMapper`方法，可以看到实际上它是调用的`Configuration::getMapper`方法获取的代理实例：

```java
@Override
public <T> T getMapper(Class<T> type) {
  return configuration.getMapper(type, this);
}
```

而`Configuration`是MyBatis初始化后全局唯一的配置对象，它内部保存着配置文件解析过程中所有的配置信息。进入`Configuration::getMapper`我们可以发现它实际上调用的是`MapperRegistry::getMapper`方法：

```java
public <T> T getMapper(Class<T> type, SqlSession sqlSession) {
  //调用mapper注册中心的getMapper方法获取Mapper动态代理实现类
  return mapperRegistry.getMapper(type, sqlSession);
}
```

`MapperRegistry`是Mapper接口动态代理工厂类的注册中心，我们继续进入`MapperRegistry::getMapper`方法，可以看到它实际上调用的是`MapperProxyFactory::newInstance`方法。

```java
public <T> T getMapper(Class<T> type, SqlSession sqlSession) {
  final MapperProxyFactory<T> mapperProxyFactory = (MapperProxyFactory<T>) knownMappers.get(type);
  if (mapperProxyFactory == null) {
    throw new BindingException("Type " + type + " is not known to the MapperRegistry.");
  }
  try {
  	//使用Mapper代理工厂创建动态代理实例
    return mapperProxyFactory.newInstance(sqlSession);
  } catch (Exception e) {
    throw new BindingException("Error getting mapper instance. Cause: " + e, e);
  }
}
```

`MapperProxyFactory`是生成动态代理对象的工厂类，走到这里，我有一种预感，我们离真相越来越近了。我们进入`MapperProxyFactory::newInstance`一探究竟：

```java
public T newInstance(SqlSession sqlSession) {
    //MapperProxy实现了InvocationHandler接口。它是Mapper动态代理的核心类
    final MapperProxy<T> mapperProxy = new MapperProxy<>(sqlSession, mapperInterface, methodCache);
    //创建动态代理实例
	return newInstance(mapperProxy);
  }
```

我们先暂时略过`MapperProxy`内部的处理流程，我们先看看`newInstance`方法内部是如何创建动态代理实例的。

```java
protected T newInstance(MapperProxy<T> mapperProxy) {
   return (T) Proxy.newProxyInstance(mapperInterface.getClassLoader(), new Class[] { mapperInterface }, mapperProxy);
}
```

看到上面的代码是不是有一种恍然大悟的感觉，它是JDK动态代理的核心API，也就是说Mybatis底层是调用JDK的`Proxy`类来创建代理实例。对JDK动态代理不熟悉的小伙伴可以看看博主的另一篇文章:[JDK动态代理的深入理解](https://blog.csdn.net/tianjindong0804/article/details/84072096)。



## 三. 动态实例是如何执行的

代理实例如何创建的过程我们已经清楚了，现在我们需要了解代理类内部是如何实现SQL语句的执行的。我们进入`MapperProxy::invoke`方法：

```java
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
  try {
    if (Object.class.equals(method.getDeclaringClass())) {
      //如果是Object方法，则调用方法本身
      return method.invoke(this, args);
    } else {
      //根据被调用接口方法的Method对象，从缓存中获取MapperMethodInvoker对象，如果没有则创建一个并放入缓存，然后调用invoke。
      //换句话说，Mapper接口中的每一个方法都对应一个MapperMethodInvoker对象，而MapperMethodInvoker对象里面的MapperMethod保存着对应的SQL信息和返回类型以完成SQL调用
      return cachedInvoker(method).invoke(proxy, method, args, sqlSession);
    }
  } catch (Throwable t) {
    throw ExceptionUtil.unwrapThrowable(t);
  }
}
```

看了看`invoke`方法内部，似乎并没有看出真实的调用逻辑，那我们就先进入`cacheInvoker`方法中看看吧：

```java
/**
  * 获取缓存中MapperMethodInvoker，如果没有则创建一个，而MapperMethodInvoker内部封装这一个MethodHandler
  * @param method
  * @return
  * @throws Throwable
  */
 private MapperMethodInvoker cachedInvoker(Method method) throws Throwable {
   try {
     return methodCache.computeIfAbsent(method, m -> {
       if (m.isDefault()) {
         //如果调用接口的是默认方法（JDK8新增接口默认方法的概念）
         try {
           if (privateLookupInMethod == null) {
             return new DefaultMethodInvoker(getMethodHandleJava8(method));
           } else {
             return new DefaultMethodInvoker(getMethodHandleJava9(method));
           }
         } catch (IllegalAccessException | InstantiationException | InvocationTargetException
             | NoSuchMethodException e) {
           throw new RuntimeException(e);
         }
       } else {
         //如果调用的普通方法（非default方法），则创建一个PlainMethodInvoker并放入缓存，其中MapperMethod保存对应接口方法的SQL以及入参和出参的数据类型等信息
         return new PlainMethodInvoker(new MapperMethod(mapperInterface, method, sqlSession.getConfiguration()));
       }
     });
   } catch (RuntimeException re) {
     Throwable cause = re.getCause();
     throw cause == null ? re : cause;
   }
 }
```

可以看到进入`cacheInvoker`方法后首先会判断用户当前调用的是否是接口的`default`方法，如果不是就会创建一个`PlainMethodInvoker`对象并返回。

**PlainMethodInvoker**：类是Mapper接口普通方法的调用类，它实现了`MethodInvoker`接口。其内部封装了`MapperMethod`实例。

**MapperMethod**：封装了Mapper接口中对应方法的信息，以及对应的SQL语句的信息；它是mapper接口与映射配置文件中SQL语句的桥梁。

此时我们跳出`cachedInvoker`方法回到`MapperProxy::invoke`方法中。

```java
 return cachedInvoker(method).invoke(proxy, method, args, sqlSession);
```

我们可以看到当`cacheInvoker`返回了`PalinMethodInvoker`实例之后，紧接着调用了这个实例的`PlainMethodInvoker::invoke`方法。进入`PlainMethodInvoker::invoke`方法我们发现它底层调用的是`MapperMethod::execute`方法：

```java
@Override
public Object invoke(Object proxy, Method method, Object[] args, SqlSession sqlSession) throws Throwable {
  //Mybatis如何帮助用户实现动态代理的玄机就在里面
  return mapperMethod.execute(sqlSession, args);
}
```

进入`MapperMethod::invoke`方法我们会发现眼前一亮，这就是MyBatis底层动态代理的逻辑，可以看到动态代理最后还是使用SqlSession操作数据库的：

```java
  */
  public Object execute(SqlSession sqlSession, Object[] args) {
    Object result;
    switch (command.getType()) {
      case INSERT: {
        // 将args进行解析，如果是多个参数则，则根据@Param注解指定名称将参数转换为Map，如果是封装实体则不转换
        Object param = method.convertArgsToSqlCommandParam(args);
        result = rowCountResult(sqlSession.insert(command.getName(), param));
        break;
      }
      case UPDATE: {
        Object param = method.convertArgsToSqlCommandParam(args);
        result = rowCountResult(sqlSession.update(command.getName(), param));
        break;
      }
      case DELETE: {
        Object param = method.convertArgsToSqlCommandParam(args);
        result = rowCountResult(sqlSession.delete(command.getName(), param));
        break;
      }
      case SELECT:
        //查询操作
        if (method.returnsVoid() && method.hasResultHandler()) {
          executeWithResultHandler(sqlSession, args);
          result = null;
        } else if (method.returnsMany()) {
          result = executeForMany(sqlSession, args);
        } else if (method.returnsMap()) {
          result = executeForMap(sqlSession, args);
        } else if (method.returnsCursor()) {
          result = executeForCursor(sqlSession, args);
        } else {
          //解析参数，因为SqlSession::selectOne方法参数只能传入一个，但是我们Mapper中可能传入多个参数，
          //有可能是通过@Param注解指定参数名，所以这里需要将Mapper接口方法中的多个参数转化为一个ParamMap,
          //也就是说如果是传入的单个封装实体，那么直接返回出来；如果传入的是多个参数，实际上都转换成了Map
          Object param = method.convertArgsToSqlCommandParam(args);
          //可以看到动态代理最后还是使用SqlSession操作数据库的
          result = sqlSession.selectOne(command.getName(), param);
          if (method.returnsOptional()
              && (result == null || !method.getReturnType().equals(result.getClass()))) {
            result = Optional.ofNullable(result);
          }
        }
        break;
      case FLUSH:
        result = sqlSession.flushStatements();
        break;
      default:
        throw new BindingException("Unknown execution method for: " + command.getName());
    }
    if (result == null && method.getReturnType().isPrimitive() && !method.returnsVoid()) {
      throw new BindingException("Mapper method '" + command.getName()
          + " attempted to return null from a method with a primitive return type (" + method.getReturnType() + ").");
    }
    return result;
  }
```



## 四. 动态代理调用过程时序图

![](../images/41.png)

由于图片版幅较大，网页显示字体会看不清，这里给出下载链接：[MyBatis核心调用流程时序图-GitHub](https://github.com/tianjindong/StudyNotes/tree/master/%E5%9F%BA%E7%A1%80%E7%AC%94%E8%AE%B0/JavaWeb/MyBatis/subfile/MyBatis%E6%BA%90%E7%A0%81%E6%97%B6%E5%BA%8F%E5%9B%BE)；[MyBatis核心调用流程时序图-Gitee](https://gitee.com/tianjindong/StudyNotes/tree/master/%E5%9F%BA%E7%A1%80%E7%AC%94%E8%AE%B0/JavaWeb/MyBatis/subfile/MyBatis%E6%BA%90%E7%A0%81%E6%97%B6%E5%BA%8F%E5%9B%BE)



## 五. 总结

Mapper动态代理是通过MyBatis生成接口的实现类，然后调用SqlSession中的方法执行数据库操作。上文只是对MyBatis这个过程源码的简单分析，希望读者在读后能够明白Mapper动态代理的几个核心问题：

- MyBatis如何生成动态代理实例的?
- MyBatis如何根据不同的情况将Mapper接口“翻译”成`SqlSession`调用的
  - 如何确定调用`SqlSession`中的那个方法？
  - 如何确定命名空间和调用的`statementId`？
  - 如何传递参数给`SqlSession`？
- 从源码的角度看Mapper代理实例和`SqlSession`是一对一的关系，而`SqlSession`是线程不安全的，那么在Spring和MyBatis集成的时候，项目的整个生命周期中Mapper接口是单例的（通常情况），那么MyBatis是如何解决`SqlSession`线程安全问题的？（这个问题在这个部分的源码分析中暂时得不到解决）

**最后，博主自己对MyBatis源码进行了详细注释，如有需要，请移步至：**[GitHub](https://github.com/tianjindong/mybatis-source-annotation)或[Gitee](https://gitee.com/tianjindong/mybatis-source-annotation)

**本文阐述了自己对MyBatis源码的一些理解，如有不足，欢迎大佬指点，感谢感谢！！**