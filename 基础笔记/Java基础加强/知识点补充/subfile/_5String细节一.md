## **String s=new String(“abc”)创建了几个对象?** 

​	在探讨上述问题结论之前，我们需要了解常量池这个概念。

#### 常量池

​	由于字符串在Java中被大量使用，为了避免每次都创建相同的字符串对象（这样就意味着占据更多内存），JVM对字符串对象做了一定的优化，有一块专门的区域来存储字符串常量，该区域就是字符串常量池。**常量池(constant pool)指的是在编译期被确定，并被保存在已编译的.class文件中的一些数据**。它包括了关于类、方法、接口等中的常量，也包括字符串常量。 

​	需要注意的是：

- 在JDK1.6即以前，常量池位于JVM的方法区中。

- 在JDK7即以后，常量池放在堆中。

  **官网说明：**

  > Synopsis: In JDK 7, interned strings are no longer allocated in the permanent generation of the Java heap, but are instead allocated in the main part of the Java heap (known as the young and old generations), along with the other objects created by the application. This change will result in more data residing in the main Java heap, and less data in the permanent generation, and thus may require heap sizes to be adjusted. Most applications will see only relatively small differences in heap usage due to this change, but larger applications that load many classes or make heavy use of the String.intern() method will see more significant differences. 

理解字符串常量池的概念后，我们来看一下代码：

```java
public class StringDemo {
	public static void main(String[] args) {
		String str1 = "abc";
		String str2 = "abc";
		String str3 = new String("abc");
        
		System.out.println(str1==str2); //第七行
		System.out.println(str2==str3);//第八行
	}
}
```

​	你看到上述代码，预测一下控制台输出！

​	第7行输出true，第8行输出false。

​	**执行过程：**

 1. 执行String str1 = "abc";`时，JVM常量池中并没有`"abc"这个字符串，此时会在常量池中创建这个对象，然后将引用赋给`str1`。

 2. 执行`String str2 = "abc";`时，JVM在常量池中找到`"abc"`这个字符串了，所以直接将应用附给它。

 3. 执行`String str3 = new String("abc");`时，JVM会在堆中创建一个String对象，然后将传进去的常量池String对象中保存的char[]数组，赋给堆中的String。

    ```java
    /**
    	String类的部分源代码
    **/
    /** The value is used for character storage. */
    private final char value[]; 
    
    /** Cache the hash code for the string */
    private int hash; // Default to 0
    
    public String(String original) {//String的构造器
            this.value = original.value;
            this.hash = original.hash;
     }
    ```

    

#### 回到最初的问题，`String s=new String(“abc”)`到底创建了几个对象？

​	如果在执行`String s=new String(“abc”)`这句话之前，常量池中并没有`"abc"`，那么在创建new String()时会先在常量池中 创建字符串常量，然后通过这个字符串常量，在堆中创建一个新的字符串，**但是这两个字符串对象（常量池中的"abc"和堆中的"abc"）底层保存字符的数组都是一个**。

​	如果在执行之前就有了`"abc"`这个字符串常量了（例如上面的代码），在执行`String s=new String(“abc”)`这句话时，也就只在堆中创建一个对象了。



#### 验证常量池中的"abc"和堆中的"abc"底层保存字符的数组都是一个

​	前面我们查看String的构造器后得出结论，采用new关键字在堆中创建的`"abc"`和常量池中`"abc"`虽然对象不是一个，但是它们两个对象底层指向的数组是一个，那我们就通过代码验证这个结论。

​	整体思路是这样的：我们通过反射，修改常量词中字符串对象底层数组的值，看堆中的String对象的值是否跟着改变：

```java
@Test
public void test() throws Exception {
	//在常量池中创建一个"abc"
	String str = "abc";
	//通过常量词中的"abc"在堆中创建一个String对象
	String str2 = new String("abc");
	
	//获取String类中的value字段
	Field field = String.class.getDeclaredField("value");
	//将字段设置为可访问的
	field.setAccessible(true);
	
	//获取str对象上的value属性的值
	char[] arr = (char[]) field.get(str);
	arr[2]='1';
        
	System.out.println(str);//输出：ab1
	System.out.println(str2);//输出：ab1
}
```

