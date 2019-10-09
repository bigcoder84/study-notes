# ReentranReadWriteLock

前面我们介绍了ReentrantLock锁，它是一个独占锁（排它锁），当一个线程拿到锁其他线程是无法再次获取锁的，如果业务需求中多数操作都是读的话，使用独占锁会大大降低系统的吞吐率。

## 1. ReadWriteLock和ReentranReadWriteLock

### 1.1 ReadWriteLock接口

ReadWriteLock和Lock一样是一个接口，它规范着读写锁的API。

```java
public interface ReadWriteLock {
    
    Lock readLock();//获取读锁

    Lock writeLock();//获取写锁
}
```

### 1.2 ReentranReadWriteLock

ReentranReadWriteLock是ReentranReadWrite接口的实现类，它内部有两个锁的实现类，分别`ReentrantReadWriteLock.WriteLock`和`ReentrantReadWriteLock.ReadLock`，读写锁都实现了Lock接口，但是**对于ReadLock来说，调用它的newCondition方法不会返回Condition实例，而是抛出UnsupportedOperationException异常**。



### 1.3 读锁和写锁之间的互斥关系

读锁可以在没有写锁的时候被多个线程同时持有（共享锁）；写锁是独占的(排他的)， 每次只能有一个写线程，如果有线程拥有写锁，那么其他线程则不会拿到写锁和读锁。简单总结一下：

- 读-读能共存，
- 读-写不能共存，
- 写-写不能共存。



## 2. 读写锁的基本使用

```java
public class ReentrantReadWriteLockTest {
    private static class SharedResource {
        private String name = "A";

        private ReadWriteLock readWriteLock = new ReentrantReadWriteLock();
        private Lock readLock = readWriteLock.readLock();//获取读锁
        private Lock writeLock = readWriteLock.writeLock();//获取写锁

        public String getName() {
            readLock.lock();//读操作用读锁
            try {
                System.out.println(Thread.currentThread().getName()+"读取："+this.name);
                return this.name;
            } finally {
                readLock.unlock();
            }
        }

        public void changeName() {
            writeLock.lock();//写操作用写锁
            try {
                this.name = name+"A";
                System.out.println(Thread.currentThread().getName()+" 将值修改为："+name);
            } finally {
                writeLock.unlock();
            }
        }
    }

    public static void main(String[] args) {
        final SharedResource sharedResource = new SharedResource();//创建共享资源
        final CyclicBarrier cyclicBarrier=new CyclicBarrier(15);//15个线程全部开启完毕后一起执行
        for (int i = 0; i < 10; i++) {//10个读线程
            new Thread(()->{
                try {
                    cyclicBarrier.await();
                } catch (InterruptedException|BrokenBarrierException  e) {
                    e.printStackTrace();
                }
                for (int j = 0; j < 10; j++) {//读一百次
                    String name = sharedResource.getName();
                }
            },"读线程"+i).start();
        }
        for (int i = 0; i < 5; i++) {//5个写线程
            new Thread(()->{
                try {
                    cyclicBarrier.await();
                } catch (InterruptedException|BrokenBarrierException  e) {
                    e.printStackTrace();
                }
                sharedResource.changeName();
            },"写线程"+i).start();
        }
    }
}

```

**参考文章**：

[多线程并发之读写锁(ReentranReadWriteLock&ReadWriteLock)使用详解](https://blog.csdn.net/j080624/article/details/82790372)

