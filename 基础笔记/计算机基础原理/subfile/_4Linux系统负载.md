# 理解Linux系统负载

> 本文转载至：[理解Linux系统负荷 - 阮一峰的网络日志 (ruanyifeng.com)](https://www.ruanyifeng.com/blog/2011/07/linux_load_average_explained.html)

## 一. 查看系统负载

如果你的电脑很慢，你或许想查看一下，它的工作量是否太大了。

在Linux系统中，我们一般使用uptime命令查看（w命令和top命令也行）。（另外，它们在苹果公司的Mac电脑上也适用。）

你在终端窗口键入uptime，系统会返回一行信息。

![](../images/14.png)

这行信息的后半部分，显示"load average"，它的意思是"系统的平均负荷"，里面有三个数字，我们可以从中判断系统负荷是大还是小。

![](../images/15.png)

为什么会有三个数字呢？你从手册中查到，它们的意思分别是1分钟、5分钟、15分钟内系统的平均负荷。

如果你继续看手册，它还会告诉你，当CPU完全空闲的时候，平均负荷为0；当CPU工作量饱和的时候，平均负荷为1。

那么很显然，"load average"的值越低，比如等于0.2或0.3，就说明电脑的工作量越小，系统负荷比较轻。

但是，什么时候能看出系统负荷比较重呢？等于1的时候，还是等于0.5或等于1.5的时候？如果1分钟、5分钟、15分钟三个值不一样，怎么办？

## 二. 一个类比

判断系统负荷是否过重，必须理解load average的真正含义。下面，我根据"[Understanding Linux CPU Load](http://blog.scoutapp.com/articles/2009/07/31/understanding-load-averages)"这篇文章，尝试用最通俗的语言，解释这个问题。

首先，假设最简单的情况，你的电脑只有一个CPU，所有的运算都必须由这个CPU来完成。

那么，我们不妨把这个CPU想象成一座大桥，桥上只有一根车道，所有车辆都必须从这根车道上通过。（很显然，这座桥只能单向通行。）

系统负荷为0，意味着大桥上一辆车也没有。

![](../images/16.png)

系统负荷为0.5，意味着大桥一半的路段有车。

![](../images/17.png)

系统负荷为1.0，意味着大桥的所有路段都有车，也就是说大桥已经"满"了。但是必须注意的是，直到此时大桥还是能顺畅通行的。

![](../images/18.png)

系统负荷为1.7，意味着车辆太多了，大桥已经被占满了（100%），后面等着上桥的车辆为桥面车辆的70%。以此类推，系统负荷2.0，意味着等待上桥的车辆与桥面的车辆一样多；系统负荷3.0，意味着等待上桥的车辆是桥面车辆的2倍。总之，当系统负荷大于1，后面的车辆就必须等待了；系统负荷越大，过桥就必须等得越久。

![](../images/19.png)

CPU的系统负荷，基本上等同于上面的类比。大桥的通行能力，就是CPU的最大工作量；桥梁上的车辆，就是一个个等待CPU处理的进程（process）。

如果CPU每分钟最多处理100个进程，那么系统负荷0.2，意味着CPU在这1分钟里只处理20个进程；系统负荷1.0，意味着CPU在这1分钟里正好处理100个进程；系统负荷1.7，意味着除了CPU正在处理的100个进程以外，还有70个进程正排队等着CPU处理。

为了电脑顺畅运行，系统负荷最好不要超过1.0，这样就没有进程需要等待了，所有进程都能第一时间得到处理。很显然，1.0是一个关键值，超过这个值，系统就不在最佳状态了，你要动手干预了。

## 三. 系统负荷的经验法则

1.0是系统负荷的理想值吗？

不一定，系统管理员往往会留一点余地，当这个值达到0.7，就应当引起注意了。经验法则是这样的：

当系统负荷持续大于0.7，你必须开始调查了，问题出在哪里，防止情况恶化。

当系统负荷持续大于1.0，你必须动手寻找解决办法，把这个值降下来。

当系统负荷达到5.0，就表明你的系统有很严重的问题，长时间没有响应，或者接近死机了。你不应该让系统达到这个值。

## 四. 多处理器

上面，我们假设你的电脑只有1个CPU。如果你的电脑装了2个CPU，会发生什么情况呢？

2个CPU，意味着电脑的处理能力翻了一倍，能够同时处理的进程数量也翻了一倍。

还是用大桥来类比，两个CPU就意味着大桥有两根车道了，通车能力翻倍了。

![](../images/20.png)

所以，2个CPU表明系统负荷可以达到2.0，此时每个CPU都达到100%的工作量。推广开来，n个CPU的电脑，可接受的系统负荷最大为n.0。

## 五. 多核处理器

芯片厂商往往在一个CPU内部，包含多个CPU核心，这被称为多核CPU。

在系统负荷方面，多核CPU与多CPU效果类似，所以考虑系统负荷的时候，必须考虑这台电脑有几个CPU、每个CPU有几个核心。然后，把系统负荷除以总的核心数，只要每个核心的负荷不超过1.0，就表明电脑正常运行。

怎么知道电脑有多少个CPU核心呢？

`cat /proc/cpuinfo` 命令，可以查看CPU信息。`grep -c 'model name' /proc/cpuinfo`命令，直接返回CPU的总核心数。

## 六. 最佳观测时长

最后一个问题，"load average"一共返回三个平均值----1分钟系统负荷、5分钟系统负荷，15分钟系统负荷，----应该参考哪个值？

如果只有1分钟的系统负荷大于1.0，其他两个时间段都小于1.0，这表明只是暂时现象，问题不大。

如果15分钟内，平均系统负荷大于1.0（调整CPU核心数之后），表明问题持续存在，不是暂时现象。所以，你应该主要观察"15分钟系统负荷"，将它作为电脑正常运行的指标。