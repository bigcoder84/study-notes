# 解决IDEA抽风报错

在一次项目中编写，项目代码突然报错，检查了代码后发现确实正确，执行`mvn compile`以及运行项目都没有问题，但是IDEA还是报错。

猜想这个问题是因为 intellij 的代码查错会利用缓存，至于编译运行为了保证每次都独立所以不过缓存，因此没有问题。

解决方法：点击File-> Invalidate Caches and Restart

![](../images/75.png)