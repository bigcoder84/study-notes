# CompletableFuture

> 本文转载至：[https://blog.csdn.net/zhilaizhe/article/details/92427274](https://blog.csdn.net/zhilaizhe/article/details/92427274)
>
> <https://blog.csdn.net/TreeShu321/article/details/100107962>

## 一. CompletableFuture解决的问题

1. 解决Future模式的缺点：
   - 为了解决Future虽然可以实现异步获取线程的执行结果，但是Future没有提供通知机制，调用方无法得知Future什么时候执行完的问题。 
   - 要么使用阻塞， 在future.get()的地方等待future返回结果，这时会变成同步操作。如果使用isDone()方法进行循环判断，就会消耗cpu资源。
2. CompletableFuture能够将回调放到与任务不同的线程中执行，也能将回调作为继续执行的同步函数，在于任务相同的线程中执行。他避免了传统回调的最大问题，就是能够将控制流分离到不同的事件处理器中。

## 二. CompletableFuture的静态工厂方法

### 2.1 runAsync()

`runAsync()`方法使用了`ForkJoinPool.commonPool()` 作为线程池，并进行异步执行：

```java
 CompletableFuture<Void> future = CompletableFuture.runAsync(()->{
            System.out.println("hello world");
 });

 try {
     future.get();
 } catch (InterruptedException e) {
     e.printStackTrace();
 } catch (ExecutionException e) {
     e.printStackTrace();
 }

 System.out.println("completableFuture end!");
```

```java
CompletableFuture<String> future = CompletableFuture.supplyAsync(new Supplier<String>() {
    @Override
    public String get() {
        return "Hello";
    }
});

try {
    System.out.println(future.get());
} catch (InterruptedException e) {
    e.printStackTrace();
} catch (ExecutionException e) {
    e.printStackTrace();
}
System.out.println("completableFuture end!");
```

`runAsync`传入的是一个Runnable对象，所以不会有返回值；`supplyAsync`传入一个人`Supplier`，执行完成后有返回值。

