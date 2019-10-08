# Java中原子操作类

java.util.concurrent.atomic包下面包含JDK中的原子操作类：

- 更新基本类型类：AtomicBoolean，AtomicInteger，AtomicLong，AtomicReference

- 更新数组类：AtomicIntegerArray，AtomicLongArray，AtomicReferenceArray

- 更新引用类型：AtomicReference，**AtomicMarkableReference**，**AtomicStampedReference**

- 原子更新字段类： AtomicReferenceFieldUpdater，AtomicIntegerFieldUpdater，AtomicLongFieldUpdater

**AtomicMarkableReference**，**AtomicStampedReference**可以用来解决CAS操作中ABA问题。

```java
public class AtomicIntegerTest {
    public static void main(String[] args) {
        AtomicInteger i=new AtomicInteger();
        for (int j = 0; j < 10; j++) {
            new Thread(()->{
                for (int k = 0; k < 100; k++) {
                    int t = i.incrementAndGet();
                    System.out.println(t);
                }
            }).start();
        }
    }
}
```

