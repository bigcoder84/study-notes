# String类为什么用final修饰

```java
public final class String implements java.io.Serializable, Comparable<String>, 	 		CharSequence {
    /** The value is used for character storage. */
    private final char value[];

    /** Cache the hash code for the string */
    private int hash; // Default to 0
    .....
}
```

​	上述代码是String类的声明，但为什么JDK的实现中，String类设置成`final`修饰的类，包括String类中大多数字段和方法都设置为`final`，这其中的原因值得我们探讨一下。至于`final`修饰类、字段、方法有哪些含义不在本文的叙述范畴...

​	String中类、字段、方法基本上都用final修饰了，这也是String类是一个不可变对象的原因，**final修饰的char[]代表了被存储的数据不可更改性**。但是：虽然final代表了不可变，但仅仅是引用地址不可变，并不代表了数组本身不会变，这个问题在 [《String s=new String(“abc”)到底创建了几个对象?》](./_5String细节一.md) 的最后进行了描述。

​	**一个对象的不可变可以理解为**：如果一个对象，在它创建完成之后，不能再改变它的状态，那么这个对象就是不可变的。不能改变状态的意思是，不能改变对象内的成员变量（这里不考虑反射），包括基本数据类型的值不能改变，引用类型的变量不能指向其他的对象，引用类型指向的对象的状态也不能改变。

​	从我的理解中，String类使用`final`修饰出于下面几个考虑：

- **只有当字符串是不可变的，字符串池才有可能实现**

  字符串池的实现可以在运行时节约很多heap空间，因为不同的字符串变量都指向池中的同一个字符串。但如果字符串是可变的（例如像StringBuilder那样可以直接改变字符串中的内容），那么字符串常量池将不能实现，因为这样的话，如果变量改变了它的值，那么其它指向这个值的变量的值也会一起改变，但是其它引用它的变量并不一定希望看到这种改变。

- **因为字符串是不可变的，所以是多线程安全的**

  同一个字符串实例可以被多个线程共享。这样便不用因为线程安全问题而使用同步。字符串自己便是线程安全的。

- **类加载器要用到字符串，不可变性提供了安全性,以便正确的类被加载**

  譬如你想加载java.sql.Connection类，而这个值被改成了myhacked.Connection，那么会对你的数据库造成不可知的破坏。

- **作为Map的key，提高了访问效率**

  因为字符串是不可变的，所以在它创建的时候hashcode就被缓存了，不需要重新计算。这就使得字符串很适合作为Map中的键，字符串的处理速度要快过其它的键对象。这就是HashMap中的键往往都使用字符串。因为Map使用得也是非常之多，所以一举两得。