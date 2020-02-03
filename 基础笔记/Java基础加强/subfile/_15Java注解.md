# Java注解

## 一. 注解的声明

声明一个注解，其实和创建一个类差不多，只不过声明一个类是用关键字`class`，声明一个接口是用关键字`@interface`：

```shell
public @interface MyAn{
    int a() default 1;
    String b() default "java";
}
```

简单吧，但是里面有一点需要和类、接口的声明有点不同。**注解是没有方法的，只有成员变量。而且我们可以自己定义默认值**。但是**形式上和方法一样**。



## 二. 元注解

元注解用于标识自定义注解的属性，例如自定义注解能加到什么类型上面？

- @Retention ：标识这个注解怎么保存，是只在代码中，还是编入class文件中，或者是在运行时可以通过反射访问。

  - SOURCE：注释将由编译器丢弃。
  - CLASS：注释由编译器记录在类文件中，但是在运行时不需要由VM保留。（默认）
  - RUNTIME：注释由编译器记录在类文件中，并由VM在运行时保留，因此反射时可以获取到该注解。

  注：自定义注解，如果想要在运行时通过反射获取，那么一定要将该注解设置为`@Retention(RetentionPolicy.RUNTIME)`。

- @Documented： 标记这些注解是否包含在用户文档中。

- @Target：标记这个注解应该是哪种 Java 成员。

  - ElementType.TYPE：用于标识该注可以放在类、接口（包括注释类型）或枚举声明。

  - ElementType.FIELD：用于标识该注可以放在字段声明（包括枚举常量）。

  - ElementType.METHOD：用于标识该注可以放在方法声明。

  - ElementType.PARAMETER：用于标识该注可以放在参数声明。

  - ElementType.CONSTRUCTOR：用于标识该注可以放在构造方法声明。

  - ElementType.LOCAL_VARIABLE：用于标识该注可以放在局部变量声明。

  - ElementType.ANNOTATION_TYPE：用于标识该注可以放在注解类型声明上。

  - ElementType.PACKAGE：包声明。

- @Inherited ：标记这个注解是继承于哪个注解类(默认 注解并没有继承于任何子类)。



## 三. 自定义注解

```java
@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
public @interface PassToken {
}
```

