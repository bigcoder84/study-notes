# Lambda表达式

## 一. 初识Lambda

在平时的工作中，我们常常会用到匿名内部类，例如下面代码：

```java
public class LambdaTest {
	@Test
	public void testOld1() {
		new Thread(new Runnable() {
			@Override
			public void run() {
				System.out.println("xxx");
			}
			
		}).start();
	}
}
```

但是在Java8之后，如果还这么写或许就显得臃肿了，应该里面大部分代码是无用的，下面就是Lambda表达式的写法：

```java
public class LambdaTest {
	@Test
	public void testOld1() {
		new Thread(()->{System.out.println("xxx");}).start();
	}
}
```

可以看到原来五行的代码现在只需要一行，嘻嘻嘻。

## 二. Lambda表达式语法

```java
语法：(参数列表)->{函数体}；
```

注：Lambda表达式省略了匿名内部类的接口名、和方法名，目的就是让我们专注于接口方法的实现部分。

(1）参数列表规则

1. 如果没有参数，直接用“()”表示。()不能省略。
2. 如果只有一个参数，并且参数写了类型，则一定要加()。例如：`(Person p)->{xxx}`
3. 如果只写了一个参数，并且参数不写类型，那么这个参数外面不用加“()”。例如：`m->{xxx}`
4. 如果有两个或多个参数，则“()”必须写，参数的类型可以省略。

(2）函数体规则

1. 如果函数体只有一行，那么可以省略“{}”。
2. 如果函数体有多行，则“{}”不能省略。
3. 如果函数体有多行，并且该函数有返回值，则不能省略“return”关键字。
4. 如果函数体是一行，并且函数有返回值，则必须省略“return”关键字（由编译器自己推导返回类型）

## 三. Lambda表达式的原理是啥？

### 3.1 为什么可以省略接口名

因为在Lambda表达式外面有new Thread()。而我们根据多线程的学习知道，Thread类的构造器如果只传入一个参数，那必定是Runnable接口实现类的实例。

```java
public Thread(Runnable target)
```

所以编译器在编译的时候，是可以推断出来我们后面匿名内部类实现的接口是什么（Lambada表达式就是匿名内部类的精简写法），因此Lambda表达式将接口名省略。

### 3.2 为什么可以省略接口中的方法名

通过上面我们知道了，编译器可以推导匿名内部类实现的接口名。那Runnable接口中只有一个抽象方法，因此编译器同样可以推导出实现类中的方法名。

## 四. 函数接口

在Java中我们将**只声明有一个方法的接口称为函数式接口**，就比如上文中的Runnable接口，它只声明了一个`run（）`方法，所以它也是一个函数式接口，而Lambda就是为了匿名内部类实现函数式接口的复杂写法而精简的语法。

而Java8为函数式接口提供了一个`@FunctionalInterface`注解，它用于标注接口为函数接口，标注该注解的接口会在编译时检查是否符合函数式接口规范，如果不符合编译则无法通过。在Java8项目中建议给函数式接口标注该注解。

JDK8也为用户提供了一些函数式接口，例如：`Function`、`Predicate`等，它们都位于`java.util.function`包下：

| 接口（系列） | 描述                                   |
| ------------ | -------------------------------------- |
| Supplier     | 无参数返回一个结果                     |
| Function     | 接受一个输入参数，返回一个结果         |
| Consumer     | 接受一个输入参数，无返回结果           |
| Predicate    | 接受一个输入参数，返回一个布尔类型结果 |

以上面的接口为基础，还扩展处理其他指定类型的接口。例如`Function`接口扩展出了`IntFunciton`、`LongFunction`、`DoubleFunction`、`ToIntFunction`（返回值为基本数据类型int）、`BiFunction`（输入参数为两个）等。具体可去`java.util.function`包下寻找。

## 五. 函数式接口的运用

假如我们需要实现一个方法，用于清除List中所有大于100的元素，我们可能会这样做：

```java
public static void clearElement(List<Integer> list) {
    Iterator<Integer> iterator = list.iterator();
    while (iterator.hasNext()) {
        Integer value = iterator.next();
        if (value > 100) {
            iterator.remove();
        }
    }
}
```

如果我们还需要清除小于等于0的元素，我们还可以写一个方法：

```java
public static void clearElement2(List<Integer> list) {
    Iterator<Integer> iterator = list.iterator();
    while (iterator.hasNext()) {
        Integer value = iterator.next();
        if (value <= 0) {
            iterator.remove();
        }
    }
}
```

但是如果需求越来越多，而方法也会越来越多，这样显然非常不优雅，而我们可以使用`函数式接口`结合`策略模式`优雅的实现上述功能：

```java
public static void clearElement(List<Integer> list, Predicate<Integer> predicate) {
    Iterator<Integer> iterator = list.iterator();
    while (iterator.hasNext()) {
        Integer value = iterator.next();
        if (predicate.test(value)) {
            iterator.remove();
        }
    }
}
```

测试：

```java
public void test1() {
    List list = new ArrayList();
    list.add("1");
    list.add("2");
    list.add("3");
    list.add("4");

    //清除所有大于2的元素
    clearElement(list, i -> i > 100);
    //清除所有小于等于零的元素
    clearElement(list, i -> i <= 0);
}
```



