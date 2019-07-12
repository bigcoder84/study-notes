# **cglib代理**

​	在此之前，我们学习了JDK动态代理，而JDK动态代理有一定的局限性，因为使用JDK动态代理时，被代理类必须实现接口，然后动态代理生成的代理类同时实现该接口实现代理模式，但在特定情况下没办法让被代理类实现接口，那么此时我们就需要使用cglib代理。

## **代理模式的三要素**

- 两个成员：被代理对象、执行者（类似于Spring中切面的概念）
- 使用场景：当某件事情不方便自己做，但是必须要做时使用代理模式。
- 代理对象持有被代理对象的引用。

​	在第一点中，执行者指的是代理对象的执行模板，例如在JDK动态代理中，实现`InvocationHandler`接口的类就是代理类中方法的执行模板。而在cglib代理中执行模板需要实现`MethodInterceptor`。



## **使用cglib需要做的准备**

JDK动态代理由于是JDK自带的，所以我们不需要在项目中引入第三方jar，但是cglib需要引入两个jar包：

![](../images/26.png)

## **cglib代理具体实例**

### **创建被代理类**

```java
package _6代理模式.CGlib代理;

public class UserService  {

    public void addUser(){
        System.out.println("添加用户");
    }

    public void deleteUser() {
        System.out.println("删除用户");
    }

}

```

### **创建执行者**

```java
package _6代理模式.CGlib代理;

import net.sf.cglib.proxy.MethodInterceptor;
import net.sf.cglib.proxy.MethodProxy;

import java.lang.reflect.Method;

/**
 * 执行者
 */
public class Executent implements MethodInterceptor {
    /**
     *
     * @param o 代表代理对象本身，可以它调用代理对象的其他方法
     * @param method   代理对象对应方法的字节码对象
     * @param objects 传入用户调用“代理对象”对应方法的参数数组
     * @param methodProxy  被代理对象方法的引用（通过它调用父类方法，从而达到代理的效果）
     * @return
     * @throws Throwable
     */
    @Override
    public Object intercept(Object o, Method method, Object[] objects, MethodProxy methodProxy) throws Throwable {
        System.out.println("开启事务");
        Object result= null;
        try {
            result = methodProxy.invokeSuper(o,objects);
        } catch (Throwable throwable) {
            throwable.printStackTrace();
            System.out.println("回滚事务");
        }
        System.out.println("提交事务");
        return result;
    }
}
```

### **通过cglib生成代理对象**

```java
public class TestCglib {
    public static void main(String[] args) {
       	Enhancer enhancer = new Enhancer();
        //设置父类
        enhancer.setSuperclass(UserService.class);
        //设置执行者
        enhancer.setCallback(new Executent());
        //创建代理对象
        UserService userService = (UserService) enhancer.create();
        userService.addUser();
    }
}
```

**执行结果：**

![](../images/27.png)