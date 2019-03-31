## String对象的split()常见用法

#### 一. 多个分隔符分割字符串

​	给定字符串：`"abc de fgh ijk.lmnopqrst uvw xyz"`

​	我们需要使用空格和英文句号分割字符串：

```java
public class Demo {
	public static void main(String[] args) {
		String str="abc de fgh ijk.lmnopqrst uvw xyz";
		String[] split = str.split("\\.| ");
		System.out.println(Arrays.toString(split));
	}
}
```

**注意一：**"."和"|"这两个符号都是有特殊作用的，在正则表达式中如果需要使用，就必须转义，正常情况下我们使用"\\."或"\\\|"即可达到效果，但是在字符串中"\\"也有特殊意义，所以我们需要使用"\\\"来表示"\"。

```java
public class Demo {
	public static void main(String[] args) {
		String str="abc|def|ghi";
		String[] split = str.split("\\|");
		System.out.println(Arrays.toString(split));
	}
}
```



**注意二：**在正则表达式中"|"表示或，使用它我们就可以实现采用过个分隔符分割字符串的效果。

