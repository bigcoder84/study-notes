# Java中双括号初始化是个什么操作

最近在阅读Mybatis源码的时候，看到了一种原来很少见到的语法：

```java
public class RichType {
                                        
  ...
                        
  private List richList = new ArrayList() {
    {
      add("bar");
    }
  };
                                        
}
```

查了一下资料，补足了自己的一个知识盲区，嘻嘻。

## 一. 什么是Java双大括号初始化？

通常情况下，初始化Java集合并向其中添加几个元素的步骤如下：

```java
public class RichType {
                                        
  ...
                        
  private List richList;

  public RichType(){
  	richList = new ArrayList();
  	richList.add("bar");
  }
                                        
}
```

或者我们可以在静态初始化块中向作为静态变量的集合添加元素：

```java
public class RichType {
                                        
  ...
                        
  private static List richList = new ArrayList();

  static{
  	richList.add("bar");
  }
                                        
}
```

从语法上来看，这样的初始化方法虽然格式清晰明了，但语法上略显冗余。事实上，Java允许一种精简的双大括号初始化方法：

```java
List richList = new ArrayList() {
    {
      add("bar");
    }
};
```

## 二. 语法解读

实际上上述语法可以拆为两个部分，第一部分是创建了一个继承于`ArrayList`的匿名内部类：

```java
List richList = new ArrayList() {

};
```

第二部分，是在匿名内部类中指定了一个`初始化块`，并在初始化块中调用对象本身的add方法添加元素：

```java
List richList = new ArrayList() {
    {
      add("bar");
    }
};
```

这里需要回顾一下类的初始化方式，在Java中一个类和实例的初始化可以有三种方式：

- 静态初始化块：静态初始化块只在类加载时执行一次，同时静态初始化块只能给静态变量赋值，不能初始化普通的成员变量。
- 初始化块：非静态初始化块在每次初始化实例对象的时候都执行一次，可以给任意变量赋值。
- 构造方法：在每次初始化实例对象时调用。

### 初始化块的顺序

1. 在加载类时执行一次静态初始化块（之后不再调用）。
2. 在每次初始化实例对象时：先执行非静态初始化块，
3. 再执行构造方法。



## 三. 效率问题和产生的`.class`文件结构

利用双大括号初始化集合从效率上来说可能不如标准的集合初始化步骤。原因在于使用双大括号初始化会导致内部类文件的产生，而这个新的`.class`文件产生就会导致需要再次进行类加载的操作，会影响最终效率。





