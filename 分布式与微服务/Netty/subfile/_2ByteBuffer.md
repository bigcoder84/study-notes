# ByteBuffer

## 一. 基本示例

1. 向 buffer 写入数据，例如调用 channel.read(buffer)
2. 调用 flip() 切换至**读模式**
3. 从 buffer 读取数据，例如调用 buffer.get()
4. 调用 clear() 或 compact() 切换至**写模式**
5. 重复 1~4 步骤

```java
@Slf4j
public class ByteBufferTest {
    public static void main(String[] args) {
        try (FileChannel channel = new FileInputStream("a.txt").getChannel()) {
            // 分配10个字节的缓冲区
            ByteBuffer byteBuffer = ByteBuffer.allocate(10);
            while (true) {
                int len = channel.read(byteBuffer);
                log.debug("读到字节数：{}", len);
                if (len < 0) {
                    return;
                }
                // 切换读模式
                byteBuffer.flip();
                // 是否还有剩余未读数据
                while (byteBuffer.hasRemaining()) {
                    char b = (char) byteBuffer.get();
                    log.info(String.valueOf(b));
                }
                //清空缓存，切换为写模式.也可以使用compact方法
                byteBuffer.clear();
            }
        } catch (Exception exception) {
            log.error(exception.getMessage());
        }
    }
}
```

输出：

```log
14:18:37.201 [main] DEBUG cn.bigcoder.qa.netty.ByteBufferTest - 读到字节数：10
14:18:37.205 [main] INFO cn.bigcoder.qa.netty.ByteBufferTest - a
14:18:37.205 [main] INFO cn.bigcoder.qa.netty.ByteBufferTest - b
14:18:37.205 [main] INFO cn.bigcoder.qa.netty.ByteBufferTest - c
14:18:37.205 [main] INFO cn.bigcoder.qa.netty.ByteBufferTest - d
14:18:37.205 [main] INFO cn.bigcoder.qa.netty.ByteBufferTest - f
14:18:37.205 [main] INFO cn.bigcoder.qa.netty.ByteBufferTest - d
14:18:37.205 [main] INFO cn.bigcoder.qa.netty.ByteBufferTest - a
14:18:37.205 [main] INFO cn.bigcoder.qa.netty.ByteBufferTest - s
14:18:37.205 [main] INFO cn.bigcoder.qa.netty.ByteBufferTest - d
14:18:37.205 [main] INFO cn.bigcoder.qa.netty.ByteBufferTest - 1
14:18:37.205 [main] DEBUG cn.bigcoder.qa.netty.ByteBufferTest - 读到字节数：2
14:18:37.205 [main] INFO cn.bigcoder.qa.netty.ByteBufferTest - 2
14:18:37.205 [main] INFO cn.bigcoder.qa.netty.ByteBufferTest - 3
14:18:37.205 [main] DEBUG cn.bigcoder.qa.netty.ByteBufferTest - 读到字节数：-1
```

## 二. ByteBuffer结构

ByteBuffer 有以下重要属性

* capacity：容量
* position：读取、写入位置
* limit：读取、写入限制

初始化时：

![](../images/2.png)

写模式下，position 是写入位置，limit 等于容量，下图表示写入了 4 个字节后的状态：

![](../images/3.png)

flip 动作发生后，position 切换为读取位置，limit 切换为读取限制：

![](../images/4.png)

读取 4 个字节后，状态:

![](../images/5.png)

clear 动作发生后，状态:

![](../images/2.png)

compact 方法，是把未读完的部分向前压缩，然后切换至写模式

![](../images/6.png)

## 三. ByteBuffer常用方法

### 3.1 分配空间

可以使用 allocate 方法为 ByteBuffer 分配空间，其它 buffer 类也有该方法

```java
Bytebuffer buf = ByteBuffer.allocate(16); //class java.nio.HeapByteBuffer
Bytebuffer buf = ByteBuffer.allocateDirect(16); //class java.nio.DirectByteBuffer
```

java.nio.HeapByteBuffer：Java堆内存，读写效率相对较低，分配效率高（JVM直接分配，不需要调用系统内核），会受到GC影响

java.nio.DirectByteBuffer：直接内存，读写效率高（少一次拷贝），分配效率低，不会受GC影响

### 3.2 向Buffer写入数据

有两种办法

* 调用 channel 的 read 方法

```java
int readBytes = channel.read(buf);
```

* 调用 buffer 自己的 put 方法

```java
buf.put((byte)127);
```

### 3.2 从Buffer读取数据

同样有两种办法

* 调用 channel 的 write 方法

```java
int writeBytes = channel.write(buf); //将buffer中数据写入channel中
```

* 调用 buffer 自己的 get 方法

```java
byte b = buf.get();
```

`get()`方法会让 position 读指针向后走，如果想重复读取数据

* 可以调用` rewind` 方法将 position 重新置为 `0`
* 或者调用` get(int i)` 方法获取索引` i `的内容，它不会移动读指针

### 3.3 mark 与reset

mark 是在读取时，做一个标记，即使 position 改变，只要调用 reset 就能回到 mark 的位置

> **注意**
>
> rewind 和 flip 都会清除 mark 位置

### 3.4 字符串与Buffer互转

#### 3.4.1 字符串转Buffer

```java
String str = "你好";

//方式一：
ByteBuffer buffer1 = ByteBuffer.allocate(str.getBytes().length);
buffer1.put(str.getBytes());
buffer1.flip(); //切换为读模式

//方式二：生成的buffer2默认就是读模式
ByteBuffer buffer2 = StandardCharsets.UTF_8.encode(str);

//方式三：
ByteBuffer buffer3 = ByteBuffer.wrap(str.getBytes());
```

上述三种字符串转Buffer效果完全一样

#### 3.4.2 Buffer转字符串

```java
String str = "你好";
ByteBuffer buffer3 = ByteBuffer.wrap(str.getBytes());
System.out.println(StandardCharsets.UTF_8.decode(buffer3));
```

### 3.5 分散读

前面我们读取都使用一个Channel对应一个Buffer，我们可以在读取时指定多个Buffer，这样会将Channel中的数据按顺序写入给定的Buffer列表中：

假如`a.txt`文件中有下列数据：`abcdef`

```java
ByteBuffer buffer1 = ByteBuffer.allocate(2);//ab
ByteBuffer buffer2 = ByteBuffer.allocate(2);//cd
ByteBuffer buffer3 = ByteBuffer.allocate(2);//ef
channel.read(new ByteBuffer[]{buffer1, buffer2, buffer3});
```

### 3.6 集中写

```java
ByteBuffer byteBuffer1 = StandardCharsets.UTF_8.encode("你好");
ByteBuffer byteBuffer2 = StandardCharsets.UTF_8.encode("世界");
try (FileChannel channel = new RandomAccessFile("word.txt", "rw").getChannel()) {
    channel.write(new ByteBuffer[]{byteBuffer1, byteBuffer2});
} catch (IOException e) {
}
```

