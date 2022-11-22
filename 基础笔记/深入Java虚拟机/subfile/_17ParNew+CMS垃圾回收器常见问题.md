# ParNew+CMS垃圾回收器常见问题

## 一. 新生代GC触发条件是什么？

应用程序在Eden区生成新对象，一旦Eden区满了之后就会触发新生代GC，新生代GC算法使用复制算法。复制算法对Eden区以及S0区的对象进行标记，标记出活跃对象，然后将活跃对象复制到S1区。复制算法不会产生内存碎片。对于标记算法中如何判断一个对象是活跃的还是不活跃的（垃圾对象），现在一般使用可达性分析算法。

## 二. 哪些对象会从新生代晋升到老年代

1. 躲过15次新生代GC后晋升到老年代（15是默认情况）。
2. 大对象直接进入老年代。
3. 动态对象年龄判断机制：假如当Survivor区中，相同年龄的对象总大小大于这Survivor区域总大小的50%，那么大于等于这批对象年龄的对象，在下次YGC后就会晋升到老年代。
4. YGC后存活对象太多超过Survivor区大小，通过分配担保机制晋升到老年代。（空间担保机制）

## 三. 老**年**代GC触发条件是什么

老年代使用内存占老年代实际大小比例超过一定阈值（可以通过参数`-XX:CMSInitiatingOccupancyFraction`配置）之后会触发老年代GC。老年代GC使用并发标记清理算法，算法分为初始标记、并发标记、预清理、可中断的预清理、再标记、并发清理以及并发重置状态等7个步骤，其中初始标记、再标记以及并发清理3个阶段是STW。下面是一段完整老年代GC的日志片段：

![](../images/58.png)

## 四. FGC触发条件是什么

CMS垃圾回收器中FGC一旦发生，就会暂停所有应用线程，并退化成单线程进行垃圾回收，整个暂停耗时非常之长。CMS垃圾回收器一般有两种FGC触发条件。

### 4.1 promotion failed

从字面意思来看是晋升失败，是一次新生代GC之后部分对象要晋升到老年代，但是老年代没有足够内存容纳这些对象导致FGC。通常来说，是因为老年代存在大量的内存碎片导致这种模式的FGC。

下面是一个promotion failed的一条gc日志：

```txt
106.641: [GC 106.641: [ParNew (promotion failed): 14784K->14784K(14784K), 0.0370328 secs]106.678: [CMS106.715: [CMS-concurrent-mark: 0.065/0.103 secs] [Times: user=0.17 sys=0.00, real=0.11 secs]
(concurrent mode failure): 41568K->27787K(49152K), 0.2128504 secs] 52402K->27787K(63936K), [CMS Perm : 2086K->2086K(12288K)], 0.2499776 secs] [Times: user=0.28 sys=0.00, real=0.25 secs]
```

### 4.2 concurrent mode failure

上文我们讲过老年代使用内存占总堆大小超过阈值`-XX:CMSInitiatingOccupancyFraction`的话就会触发老年代GC。老年代GC的”并发标记”阶段是应用线程和标记线程一起工作的，假如在并发标记的过程中，不断有对象晋升到老年代最终导致老年代内存放不下这些对象的话，就会触发Concurrent Mode Failure模式FGC。根据字面意思也可以猜到这种FGC和并发执行有关系。

下面是一个concurrent mode failure的一条gc日志：

```txt
0.195: [GC 0.195: [ParNew: 2986K->2986K(8128K), 0.0000083 secs]0.195: [CMS0.212: [CMS-concurrent-preclean: 0.011/0.031 secs] [Times: user=0.03 sys=0.02, real=0.03 secs]
(concurrent mode failure): 56046K->138K(57344K), 0.0271519 secs] 59032K->138K(65472K), [CMS Perm : 2079K->2078K(12288K)], 0.0273119 secs] [Times: user=0.03 sys=0.00, real=0.03 secs]
```



>[【大内存服务GC实践】- 一文看懂”ParNew+CMS”垃圾回收器 – 有态度的HBase/Spark/BigData (hbasefly.com)](http://hbasefly.com/2021/12/31/parnewcms1/)
>
>[CMS之promotion failed&concurrent mode failure - 简书 (jianshu.com)](https://www.jianshu.com/p/ca1b0d4107c5)

