# Java类更改常量后编译不生效

```java
public class Constant {
	public static final String NAME="name1";
}
```

```java
public class Hello {
	public static void main(String[] args){
		System.out.println(Constant.NAME);
	}
}
```

## **问题描述**：

在`Constant`类中有一个常量`NAME`，在第一次编译后，运行Hello.main，会打印"name1"。如果此时项目需要对常量进行改变将NAME改为"name2"，然后对Constant.java重新进行编译，然后替换原先的Constant.class文件，再次运行Hello.main，我们发现打印的仍然是"name2"。

这种情况经常出现在线上项目，很多小伙伴会发现，对常量所在类进行重新编译后，然后复制到源码目录中，会发现更改不生效。

## **问题原因**：

在Java文件中，指向编译时static final的静态常量， 会被在运行时解析为一个局部的常量值（也就是说静态常量在编译后，成为了常量，而不是原先的代码）。这对所有的基础数据类型（就像int ，float等）和java.lang.String都适用。

静态常量(即用 static final 修饰的变量)是编译时常量，当一个class文件编译完毕，它内部使用到的所有常量的具体值就已经确定了，不能想当然地以为它在运行时并连接常量管理类之后才会以引用方式使用常量。

静态常量，我们使用时一定要慎重。一旦有修改就需要将整个项目重新编译替换。