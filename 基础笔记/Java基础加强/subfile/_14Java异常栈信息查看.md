# Java异常栈信息查看

```java
public class Test {

    public static void main(String[] args) {
        fun1();
    }

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
            e.printStackTrace();
            throw new RuntimeException("fun3");
        }
    }

    public static void fun4() {
        throw new RuntimeException("fun4");
    }
}
```

异常栈信息：


```shell
java.lang.RuntimeException: fun4
	at _27异常栈.Test.fun4(Test.java:32)
	at _27异常栈.Test.fun3(Test.java:24)
	at _27异常栈.Test.fun2(Test.java:19)
	at _27异常栈.Test.fun1(Test.java:15)
	at _27异常栈.Test.main(Test.java:11)
Exception in thread "main" java.lang.RuntimeException: fun3
	at _27异常栈.Test.fun3(Test.java:27)
	at _27异常栈.Test.fun2(Test.java:19)
	at _27异常栈.Test.fun1(Test.java:15)
	at _27异常栈.Test.main(Test.java:11)
```

在执行链中，执行到fun3方法时，里面调用fun4会捕获fun4抛出的异常，然后`e.printStackTrace()`会打印fun4抛出的异常栈信息。

```java
java.lang.RuntimeException: fun3
	at _27异常栈.Test.fun4(Test.java:32)
	at _27异常栈.Test.fun3(Test.java:24)
	at _27异常栈.Test.fun2(Test.java:19)
	at _27异常栈.Test.fun1(Test.java:15)
	at _27异常栈.Test.main(Test.java:11)
```

异常栈信息**按照调用的反序排列**。

像`java.lang.RuntimeException: fun3`这样开头的栈信息都是通过`e.printStackTrace()`方法打印出来。

像`Exception in thread "main" java.lang.RuntimeException: fun3`是因为这个线程没有处理异常，被JVM捕获到后，打印出来的异常。