## Object类中的clone方法

#### clone()方法的作用

- 克隆方法用于创建对象的拷贝，**为了使用clone方法，类必须实现java.lang.Cloneable接口**，如果没有实现Clonebale接口，调用父类的clone()方法时会抛出CloneNotSupportedException，Cloneable接口只是一个标识，和`Serializable`接口类似，接口中没有任何方法。

  **源码类似于下面这样：**

  ```java
   protected Object clone() throws CloneNotSupportedException {
          if (!(this instanceof Cloneable)) {
              throw new CloneNotSupportedException("Class doesn't implement Cloneable");
          }
          return internalClone((Cloneable) this);
      }
  ```

- Object中的clone方法是`protected`，也就是说这个方法只能在子类内部调用，所以我们需要在子类中写一个public方法，调用Object的clone()，使这个方法暴露出来。

- 在克隆java对象的时候不会调用构造器。

- java提供一种叫浅拷贝（shallow copy）的默认方式实现clone，创建好对象的副本后然后通过赋值拷贝内容，意味着如果你的类包含引用类型，那么原始对象和克隆都将指向相同的引用内容，这是很危险的，因为发生在可变的字段上任何改变将反应到他们所引用的共同内容上。为了避免这种情况，需要对引用的内容进行深度克隆。

#### 浅拷贝

```java
public class User implements Cloneable{
    private String name;
    private int age;
    private int[] arr=new int[10];
    
    public Object clone() throws CloneNotSupportedException {
        return super.clone();
    }
    //省略Getter和Setter...
}
```

```java
public class TestClone {
    @Test
    public void testClone(){
        User user = new User();
        user.setName("zhangsan");
        user.setAge(18);
        user.getArr()[0]=12;
        try {
            User clone = (User) user.clone();
            System.out.println(clone.getArr()==user.getArr());//返回true，表示两个引用都指向同一个数组
        } catch (CloneNotSupportedException e) {
            e.printStackTrace();
        }
    }
}
```

#### 深拷贝

```java
public class User implements Cloneable{
    private String name;
    private int age;
    private int[] arr=new int[10];

    public Object clone() throws CloneNotSupportedException {
        User clone = (User) super.clone();
        clone.setName(new String(this.name));
        clone.setArr(Arrays.copyOf(this.arr,this.arr.length));
        return clone;
    }
	//省略Getter和Setter...
}

```

```java
public class TestClone {
    @Test
    public void testClone(){
        User user = new User();
        user.setName("zhangsan");
        user.setAge(18);
        user.getArr()[0]=12;
        try {
            User clone = (User) user.clone();
            System.out.println(clone.getArr()==user.getArr());//返回false，表示两个引用分别指向两个不同的数组
        } catch (CloneNotSupportedException e) {
            e.printStackTrace();
        }

    }
}
```

