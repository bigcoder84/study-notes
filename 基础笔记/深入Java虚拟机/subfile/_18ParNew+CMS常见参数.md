# ParNew+CMS 常用参数解析

以下参数解析都建立在使用 CMS GC 策略基础上，这里使用 CMS GC 表示老年代垃圾回收，Young GC 表示新生代垃圾回收。

- `-Xmx`, `-Xms`, `-Xmn`：`-Xmx`、`-Xms` 分别表示 JVM 堆的最大值，初始化大小。`-Xmx` 等价于`-XX:MaxHeapSize`，`-Xms` 等价于`-XX:InitialHeapSize`。
- `-Xss`：表示线程栈的大小，等价于`-XX:ThreadStackSize`，默认1M，一般使用不了这么多，建议值256k。
- `-XX:SurvivorRatio`：新生代中 Eden 区与 Survivor 区的比值，默认8，建议调小，使得短寿对象在Young区可以被充分回收，减少年轻代晋升至老年代对象的数量，降低老年代GC的压力。
- `-XX:+UseParNewGC`，`-XX:+UseConcMarkSweepGC`：分别表示使用并行收集器 ParNew 对新生代进行垃圾回收，使用并发标记清除收集器 CMS 对老年代进行垃圾回收。
- `-XX:ParallelGCThreads`，`-XX:ParallelCMSThreads`：别表示 Young GC 与 CMS GC 工作时的并行线程数，建议根据处理器数量进行合理设置。
- `-XX:MaxTenuringThreshold`：对象从新生代晋升到老年代的年龄阈值（每次 Young GC 留下来的对象年龄加一），默认值15，表示对象要经过15次 GC 才能从新生代晋升到老年代。设置太小会导致过早晋升，增加老年代GC次数，建议默认值即可。
- `-XX:+UseCMSCompactAtFullCollection`：由于 CMS 是标记整理清除算法，会产生内存碎片，因此 使用 CMS 垃圾回收器避免不了 Full GC。这个参数表示开启 Full GC 时的压缩功能，减少内存碎片。
- `-XX:CMSInitiatingOccupancyFraction`：表示触发 CMS GC 的老年代使用阈值，推荐设置为 70~80（百分比），默认为 -1。如果`CMSInitiatingOccupancyFraction`在0~100之间，那么由`CMSInitiatingOccupancyFraction`决定。 否则由按 `((100 - MinHeapFreeRatio) + (double)( CMSTriggerRatio * MinHeapFreeRatio) / 100.0) / 100.0` 决定即最终当老年代达到 `((100 - 40) + (double) 80 * 40 / 100 ) / 100 = 92 %` 时，会触发CMS回收。设置太小会增加 CMS GC 发现的频率，设置太大可能会导致并发模式失败或晋升失败。
- `-XX:+UseCMSInitiatingOccupancyOnly`：指定用设定的回收阈值(`-XX:CMSInitiatingOccupancyFraction`参数的值)，如果不指定，JVM仅在第一次使用设定值，后续则会根据运行时采集的数据做自动调整，如果指定了该参数，那么每次JVM都会在到达规定设定值时才进行GC。不过大多数情况下，JVM都能够作出更好的垃圾收集决策，所以如果不是很有信心的话，不建议使用该参数，放心的把决定权交给JVM。
- `-XX:+CMSClassUnloadingEnabled`：表示开启 CMS 对永久代的垃圾回收（或元空间），避免由于永久代空间耗尽带来 Full GC。