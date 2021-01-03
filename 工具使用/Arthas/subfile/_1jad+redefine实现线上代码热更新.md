# jad+redefine实现线上代码热更新

> 本文转载至：https://www.cnkirito.moe/arthas-redefine/#more

本文是我介绍 Arthas 系列文章的第一篇。

一般线上问题比开发环境的问题更难解决，一个主要的原因便在于开发态可以任意 debug 断点调试，而线上环境一般不允许远程调试，所以在实践中，我一般习惯用 Arthas 来定位线上的问题。

> Arthas 是阿里巴巴开源的 Java 应用诊断利器

[Arthas](https://alibaba.github.io/arthas/) 可以完成很多骚操作，今天给大家介绍的 Arthas 诊断技巧便是 – 热更新线上代码。在生产环境热更新代码，并不是很好的行为，可能会引发一些问题

- 黑屏化的操作可能会导致误操作
- 不符合安全生产的规范，不满足可监控、可回滚、可降级

但有时候也有一些场景可以考虑使用 Arthas 来热更，例如开发环境无法复现的问题、找到修复思路后临时验证等。

本文以 Arthas 3.1.7 版本为例，主要使用到 `jad`/`mc`/`redefine` 三个指令。

## 示例

在 arthas-demo 示例中，一共有两个类，一个 HelloService 类，sayHello 方法负责不断的打印 `hello world`：

```java
public class HelloService {

    public void sayHello() {
        System.out.println("hello world");
    }

}
```

HelloService 用于模拟我们日常开发的一些业务 Service，另外还有一个 Main 函数，负责启动进程，并循环调用

```java
public class Main {

    public static void main(String[] args) throws InterruptedException {
        HelloService helloService = new HelloService();
        while (true) {
            Thread.sleep(1000);
            helloService.sayHello();
        }
    }
}
```

## 需求

假设这段代码运行在线上，我们希望通过 Arthas 将 `hello world` 的输出更改为 `hello arthas`。

Arthas 修改热更的逻辑主要分为三步：

- jad 命令反编译出内存中的字节码，生成 class 文件
- 修改代码，使用 mc 命令内存编译新的 class 文件
- redefine 重新加载新的 class 文件

从而达到热更新的效果

## jad 反编译

当挂载上 Arthas 之后，执行

```shell
$ jad --source-only moe.cnkirito.arthas.demo.HelloService > /tmp/HelloService.java
```

将字节码文件输出到指定的位置，查看其内容，与示例中的源码内容一致：

```java
/*
 * Decompiled with CFR.
 */
package moe.cnkirito.arthas.demo;

import java.io.PrintStream;

public class HelloService {
    public void sayHello() {
        System.out.println("hello world");
    }
}
```

命令中 `--source-only` 的含义为，只输出源码部分，如果不加这个参数，在反编译出的内容头部会携带类加载器的信息：

```shell
ClassLoader:
+-sun.misc.Launcher$AppClassLoader@18b4aac2
  +-sun.misc.Launcher$ExtClassLoader@20d5ad12

Location:
/Users/xujingfeng/IdeaProjects/arthas-demo/target/classes/
```

在服务器上可以直接使用 vi 等编辑器对源码进行编辑。将 `hello world` 改为 `hello arthas`，为下一步做准备。

## sc 查找类加载器

mc 命令编译文件需要传入该类对应类加载器的 hash 值，需要先使用 sc 命令查看 HelloService 的累加器信息

```shell
$ sc -d moe.cnkirito.arthas.demo.HelloService
```

输出：

```shell
class-info        moe.cnkirito.arthas.demo.HelloService
 code-source       /Users/xujingfeng/IdeaProjects/arthas-demo/target/classes/
 name              moe.cnkirito.arthas.demo.HelloService
 isInterface       false
 isAnnotation      false
 isEnum            false
 isAnonymousClass  false
 isArray           false
 isLocalClass      false
 isMemberClass     false
 isPrimitive       false
 isSynthetic       false
 simple-name       HelloService
 modifier          public
 annotation
 interfaces
 super-class       +-java.lang.Object
 class-loader      +-sun.misc.Launcher$AppClassLoader@18b4aac2
                     +-sun.misc.Launcher$ExtClassLoader@20d5ad12
 classLoaderHash   18b4aac2
```

最后一行 `classLoaderHash` 即为 HelloService 的类加载器 hash 值。

> Arthas 支持 grep，你也可以简化该操作为：
>
> sc -d moe.cnkirito.arthas.demo.HelloService | grep classLoaderHash

## mc 内存编译

```shell
$ mc -c 18b4aac2 /tmp/HelloService.java -d /tmp
Memory compiler output:
/tmp/moe/cnkirito/arthas/demo/HelloService.class
```

使用 `-c` 指定类加载器的 hash 值。编译完成后，/tmp 目录下会生成对应的 class 字节码文件

## redefine 热更新代码

```shell
$ redefine /tmp/moe/cnkirito/arthas/demo/HelloService.class
```

## 检查结果

```
hello world
hello world
hello world
hello world
hello arthas
hello arthas
hello arthas
hello arthas
```

热更新成功

## 常见问题

### redefine 使用限制

- 不允许新增或者删除 field/method

  会出现类似下面的提示

  ```shell
  redefine error! java.lang.UnsupportedOperationException: class redefinition failed: attempted to change the schema (add/remove fields)
  ```

- 运行中的方法不会立刻生效，会在下一次进入该方法时才能生效。

  很好理解，并发问题

- JDK版本不一致导致，Lambda表达式编译后生成不同名称的方法导致redefine失败，参考：https://www.cnkirito.moe/arthas-lambda-redefine/

### mc 常见问题

- mc 命令有可能失败

  因为运行时环境和编译时环境的 JDK 可能有版本差异，mc 可能会失败。如果编译失败可以在本地编译好 `.class` 文件，再上传到服务器

- 当存在内部类时，一次会生成多个 class 文件

  ```java
  public class HelloService {
      public void sayHello() {
          Inner.test();
      }
  
      public static class Inner {
          public static void test() {
              System.out.println("hello inner");
          }
      }
  
  }
  ```

  执行 mc

  ```shell
  $ mc -c 18b4aac2 /tmp/HelloService.java -d /tmp
  Memory compiler output:
  /tmp/moe/cnkirito/arthas/demo/HelloService$Inner.class
  /tmp/moe/cnkirito/arthas/demo/HelloService.class
  ```

  注意 redefine 时也可以同时传入多个入参

  ```shell
  $ redefine /tmp/moe/cnkirito/arthas/demo/HelloService$Inner.class /tmp/moe/cnkirito/arthas/demo/HelloService.class
  redefine success, size: 2
  ```

