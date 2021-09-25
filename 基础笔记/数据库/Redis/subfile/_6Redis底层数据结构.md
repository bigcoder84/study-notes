# Redis底层数据结构

## 一. RedisDB结构

Redis中存在“数据库”的概念，该结构由redis.h中的redisDb定义。当redis服务器初始化时，会预先分配16个数据库所有数据库保存到结构 redisServer的一个成员 redisServer.db 数组中

redisClient中存在一个名叫db的指针指向当前使用的数据库

RedisDB结构体源码：

```c
/* Redis数据库结构体 */
typedef struct redisDb {
    // 数据库ID标识
    int id;
    // 数据库内所有键的平均TTL（生存时间）
    long long avg_ttl;  
    // 数据库键空间，存放着所有的键值对（键为key，值为相应的类型对象）
    dict *dict;                 
    // 键的过期时间
    dict *expires;              
    // 处于阻塞状态的键和相应的client（主要用于List类型的阻塞操作）
    dict *blocking_keys;       
    // 准备好数据可以解除阻塞状态的键和相应的client
    dict *ready_keys;           
    // 被watch命令监控的key和相应client
    dict *watched_keys;                
} redisDb;
```

- id：数据库序号，为0-15（默认Redis有16个数据库）
- dict：存储数据库所有的key-value，value是具体的Redis-Object
- expires：存储key的过期时间，后面要详细讲解

## 二. RedisObject

redisObject是Redis类型系统的核心，数据库中的每个键、值，以及Redis本身处理的参数，都表示为这种数据类型。

```c
/*
 * Redis 对象
 */
typedef struct redisObject {
    // 类型
    unsigned type:4;
    // 对齐位
    unsigned notused:2;
    // 编码方式
    unsigned encoding:4;
    // LRU 时间（相对于 server.lruclock）
    unsigned lru:22;
    // 引用计数
    int refcount;
    // 指向对象的值
    void *ptr;
} robj;
```

### 2.1 type

type 字段表示对象的类型，占 4 位。它记录了对象所保存的值的类型，它的值可能是以下常量的其中一个（定义位于 redis.h）：

```c
/*
 * 对象类型
 */
#define REDIS_STRING 0  // 字符串
#define REDIS_LIST 1    // 列表
#define REDIS_SET 2     // 集合
#define REDIS_ZSET 3    // 有序集
#define REDIS_HASH 4    // 哈希表
```

当我们执行 type 命令时，便是通过读取 RedisObject 的 type 字段获得对象的类型：

```shell
127.0.0.1:6379> type a1 
string
```

### 2.2 encoding 

encoding记录了对象所保存的值的编码，占4位。每个对象有不同的实现编码，Redis可以根据不同的使用场景来为对象设置不同的编码，大大提高了 Redis的灵活性和效率。

它的值可能是以下常量的其中一个（定义位于 redis.h）：

```c
/*
 * 对象编码
 */
#define REDIS_ENCODING_RAW 0            // 编码为字符串
#define REDIS_ENCODING_INT 1            // 编码为整数
#define REDIS_ENCODING_HT 2             // 编码为哈希表
#define REDIS_ENCODING_ZIPMAP 3         // 编码为 zipmap
#define REDIS_ENCODING_LINKEDLIST 4     // 编码为双端链表
#define REDIS_ENCODING_ZIPLIST 5        // 编码为压缩列表
#define REDIS_ENCODING_INTSET 6         // 编码为整数集合
#define REDIS_ENCODING_SKIPLIST 7       // 编码为跳跃表
```

通过 object encoding 命令，可以查看对象采用的编码方式：

```shell
127.0.0.1:6379> object encoding a1
"int"
```

### 2.3 lru

lru 记录的是对象最后一次被命令程序访问的时间，（ 4.0 版本占 24 位，2.6 版本占 22 位）。

高16位存储一个分钟数级别的时间戳，低8位存储访问计数（lfu ： 最近访问次数）

lru----> 高16位: 最后被访问的时间

lfu----->低8位：最近访问次数

### 2.4 refcount

refcount 记录的是该对象被引用的次数，类型为整型。

有一些对象在 Redis 中非常常见， 比如命令的返回值 OK 、 ERROR 、 WRONGTYPE 等字符， 另外，一些小范围的整数，比如个位、十位、百位的整数都非常常见。

为了利用这种常见情况， Redis 在内部使用了一个 Flyweight 模式 ： 通过预分配一些常见的值对象， 并在多个数据结构之间共享这些对象， 程序避免了重复分配的麻烦， 也节约了一些 CPU 时间。

Redis 预分配的值对象有如下这些：

- 各种命令的返回值，比如执行成功时返回的 OK ，执行错误时返回的 ERROR ，类型错误时返回的 WRONGTYPE ，命令入队事务时返回的 QUEUED ，等等。
- 包括 0 在内，小于 redis.h/REDIS_SHARED_INTEGERS 的所有整数（REDIS_SHARED_INTEGERS 的默认值为 10000） 包括 0 在内，小于 redis.h/REDIS_SHARED_INTEGERS 的所有整数（REDIS_SHARED_INTEGERS 的默认值为 10000）
- 因为命令的回复值直接返回给客户端，所以它们的值无须进行共享；另一方面，如果某个命令的输入值是一个小于 REDIS_SHARED_INTEGERS的整数对象，那么当这个对象要被保存进数据库时，Redis就会释放原来的值，并将值的指针指向共享对象。

作为例子，下图展示了三个列表，它们都带有指向共享对象数组中某个值对象的指针：

![](../images/9.png)

三个列表的值分别为：

```shell
列表 A ： [20130101, 300, 10086] ，
列表 B ： [81, 12345678910, 999] ，
列表 C ： [100, 0, -25, 123] 。
```

当将 redisObject 用作数据库的键或者值，而不是用来储存参数时，对象的生命期是非常长的，因为C语言本身没有自动释放内存的相关机制，如果只依靠程序员的记忆来对对象进行追踪和销毁，基本是不太可能的。

另一方面，正如前面提到的，一个共享对象可能被多个数据结构所引用，这时像是“这个对象被引用了多少次？”之类的问题就会出现。

为了解决以上两个问题，Redis的对象系统使用了引用计数技术来负责维持和销毁对象，它的运作机制如下：

每个 redisObject 结构都带有一个 refcount 属性，指示这个对象被引用了多少次。

- 当新创建一个对象时，它的 refcount 属性被设置为 1 。 
- 当对一个对象进行共享时，Redis 将这个对象的 refcount 增一。 
- 当使用完一个对象之后，或者取消对共享对象的引用之后，程序将对象的 refcount 减一。 
- 当对象的 refcount 降至 0 时，这个 redisObject 结构，以及它所引用的数据结构的内存，都会被释放。

### 2.5 ptr

ptr 是一个指针，指向实际保存值的数据结构，这个数据结构由 type 属性和 encoding 属性决定。

举个例子，如果一个 redisObject 的 type 属性为 REDIS_LIST ， encoding 属性为 REDIS_ENCODING_LINKEDLIST ，那么这个对象就是一个 Redis 列表，它的值保存在一个双端链表内，而 ptr 指针就指向这个双端链表；

另一方面，如果一个 redisObject 的 type 属性为 REDIS_HASH ， encoding 属性为 REDIS_ENCODING_ZIPMAP ，那么这个对象就是一个 Redis 哈希表，它的值保存在一个 zipmap 里，而 ptr 指针就指向这个 zipmap ；诸如此类。

下图展示了 redisObject 、Redis 所有数据类型、以及 Redis 所有编码方式（底层实现）三者之间的关系：

![](../images/10.png)

命令的类型检查和多态

有了redisObject结构的存在，在执行处理数据类型的命令时，进行类型检查和对编码进行多态操作就简单得多了。

当执行一个处理数据类型的命令时， Redis 执行以下步骤：

- 根据给定 key ，在数据库字典中查找和它相对应的redisObject，如果没找到，就返回 NULL 。
- 检查 redisObject 的 type 属性和执行命令所需的类型是否相符，如果不相符，返回类型错误。
- 根据 redisObject 的 encoding 属性所指定的编码，选择合适的操作函数来处理底层的数据结构。
- 返回数据结构的操作结果作为命令的返回值。

作为例子，以下展示了对键 key 执行 LPOP 命令的完整过程：

![](../images/11.png)

## 三. SDS（Simple Dynamic String）

SDS （Simple Dynamic String，简单动态字符串）是 Redis 底层所使用的字符串表示， 几乎所有的 Redis 模块中都用了 sds。

SDS 在 Redis 中的主要作用有以下两个：

1. 实现字符串对象（StringObject）；
2. 在 Redis 程序内部用作 `char*` 类型的替代品；

### 3.1 Redis中的字符串

在 C 语言中，字符串可以用一个 `\0` 结尾的 `char` 数组来表示。

比如说， `hello world` 在 C 语言中就可以表示为 `"hello world\0"` 。

这种简单的字符串表示，在大多数情况下都能满足要求，但是，它并不能高效地支持长度计算和追加（append）这两种操作：

- **每次计算字符串长度（`strlen(s)`）的复杂度为 θ(N)**。
- **对字符串进行 N 次追加，必定需要对字符串进行 N 次内存重分配（`realloc`）**。

在 Redis 内部， 字符串的追加和长度计算很常见， 而 [APPEND](http://redis.readthedocs.org/en/latest/string/append.html#append) 和 [STRLEN](http://redis.readthedocs.org/en/latest/string/strlen.html#strlen) 更是这两种操作，在 Redis 命令中的直接映射， 这两个简单的操作不应该成为性能的瓶颈。

另外， Redis 除了处理 C 字符串之外， 还需要处理单纯的字节数组， 以及服务器协议等内容， 所以为了方便起见， **Redis 的字符串表示还应该是**[二进制安全的](http://en.wikipedia.org/wiki/Binary-safe)： 程序不应对字符串里面保存的数据做任何假设， 数据可以是以 `\0` 结尾的 C 字符串， 也可以是单纯的字节数组，或者其他格式的数据。

考虑到这两个原因， Redis 使用 SDS 类型替换了 C 语言的默认字符串表示： SDS 既可高效地实现追加和长度计算， 同时是二进制安全的。

### 3.2 SDS实现

在前面的内容中， 我们一直将 sds 作为一种抽象数据结构来说明， 实际上它由以下两部分组成：

```c
typedef char *sds;


struct sdshdr {
    // buf 已占用长度
    int len;
    // buf 剩余可用长度
    int free;
    // 实际保存字符串数据的地方
    char buf[];
};
```

其中，类型 `sds` 是 `char *` 的别名（alias），而结构 `sdshdr` 则保存了 `len` 、 `free` 和 `buf` 三个属性。

作为例子，以下是新创建的，同样保存 `hello world` 字符串的 `sdshdr` 结构：

```shell
struct sdshdr {
    len = 11;
    free = 0;
    buf = "hello world\0";  // buf 的实际长度为 len + 1
};
```

通过 `len` 属性， `sdshdr` 可以实现复杂度为 θ(1)θ(1) 的长度计算操作。

另一方面， 通过对 `buf` 分配一些额外的空间， 并使用 `free` 记录未使用空间的大小， `sdshdr` 可以让执行追加操作所需的内存重分配次数大大减少， 下一节我们就会来详细讨论这一点。

当然， sds 也对操作的正确实现提出了要求 —— 所有处理 `sdshdr` 的函数，都必须正确地更新 `len` 和 `free` 属性，否则就会造成 bug 。

### 3.3 优化追加效果

在前面说到过，利用 `sdshdr` 结构，除了可以用 θ(1) 复杂度获取字符串的长度之外，还可以减少追加（append）操作所需的内存重分配次数，以下就来详细解释这个优化的原理。

为了易于理解，我们用一个 Redis 执行实例作为例子，解释一下，当执行以下代码时， Redis 内部发生了什么：

```shell
redis> SET msg "hello world"
OK

redis> APPEND msg " again!"
(integer) 18

redis> GET msg
"hello world again!"
```

首先， `SET` 命令创建并保存 `hello world` 到一个 `sdshdr` 中，这个 `sdshdr` 的值如下：

```c
struct sdshdr {
    len = 11;
    free = 0;
    buf = "hello world\0";
}
```

当执行 [APPEND](http://redis.readthedocs.org/en/latest/string/append.html#append) 命令时，相应的 `sdshdr` 被更新，字符串 `" again!"` 会被追加到原来的 `"hello world"` 之后：

```c
struct sdshdr {
    len = 18;
    free = 18;
    buf = "hello world again!\0                  ";     // 空白的地方为预分配空间，共 18 + 18 + 1 个字节
}
```

注意， 当调用 `SET` 命令创建 `sdshdr` 时， `sdshdr` 的 `free` 属性为 `0` ， Redis 也没有为 `buf` 创建额外的空间 —— 而在执行 [APPEND](http://redis.readthedocs.org/en/latest/string/append.html#append) 之后， Redis 为 `buf` 创建了多于所需空间一倍的大小。

在这个例子中， 保存 `"hello world again!"` 共需要 `18 + 1` 个字节， 但程序却为我们分配了 `18 + 18 + 1 = 37` 个字节 —— 这样一来， 如果将来再次对同一个 `sdshdr` 进行追加操作， 只要追加内容的长度不超过 `free` 属性的值， 那么就不需要对 `buf` 进行内存重分配。

比如说， 执行以下命令并不会引起 `buf` 的内存重分配， 因为新追加的字符串长度小于 `18` ：

再次执行 [APPEND](http://redis.readthedocs.org/en/latest/string/append.html#append) 命令之后， `msg` 的值所对应的 `sdshdr` 结构可以表示如下：

```c
struct sdshdr {
    len = 25;
    free = 11;
    buf = "hello world again! again!\0           ";     // 空白的地方为预分配空间，共 18 + 18 + 1 个字节
}
```

`sds.c/sdsMakeRoomFor` 函数描述了 `sdshdr` 的这种内存预分配优化策略， 以下是这个函数的伪代码版本：

```c
def sdsMakeRoomFor(sdshdr, required_len):

    # 预分配空间足够，无须再进行空间分配
    if (sdshdr.free >= required_len):
        return sdshdr

    # 计算新字符串的总长度
    newlen = sdshdr.len + required_len

    # 如果新字符串的总长度小于 SDS_MAX_PREALLOC
    # 那么为字符串分配 2 倍于所需长度的空间
    # 否则就分配所需长度加上 SDS_MAX_PREALLOC 数量的空间
    if newlen < SDS_MAX_PREALLOC:
        newlen *= 2
    else:
        newlen += SDS_MAX_PREALLOC

    # 分配内存
    newsh = zrelloc(sdshdr, sizeof(struct sdshdr)+newlen+1)

    # 更新 free 属性
    newsh.free = newlen - sdshdr.len

    # 返回
    return newsh
```

在目前版本的 Redis 中， `SDS_MAX_PREALLOC` 的值为 `1024 * 1024` ， 也就是说， 当大小小于 `1MB` 的字符串执行追加操作时， `sdsMakeRoomFor` 就为它们分配多于所需大小一倍的空间； 当字符串的大小大于 `1MB` ， 那么 `sdsMakeRoomFor` 就为它们额外多分配 `1MB` 的空间。

> 这种分配策略会浪费内存吗？
>
> 执行过 [APPEND](http://redis.readthedocs.org/en/latest/string/append.html#append) 命令的字符串会带有额外的预分配空间， 这些预分配空间不会被释放， 除非该字符串所对应的键被删除， 或者等到关闭 Redis 之后， 再次启动时重新载入的字符串对象将不会有预分配空间。
>
> 因为执行 [APPEND](http://redis.readthedocs.org/en/latest/string/append.html#append) 命令的字符串键数量通常并不多， 占用内存的体积通常也不大， 所以这一般并不算什么问题。
>
> 另一方面， 如果执行 [APPEND](http://redis.readthedocs.org/en/latest/string/append.html#append) 操作的键很多， 而字符串的体积又很大的话， 那可能就需要修改 Redis 服务器， 让它定时释放一些字符串键的预分配空间， 从而更有效地使用内存。

### 3.4 SDS模块的API

sds 模块基于 `sds` 类型和 `sdshdr` 结构提供了以下 API ：

| 函数                 | 作用                                                         | 算法复杂度 |
| :------------------- | :----------------------------------------------------------- | :--------- |
| `sdsnewlen`          | 创建一个指定长度的 `sds` ，接受一个 C 字符串作为初始化值     | O(N)       |
| `sdsempty`           | 创建一个只包含空白字符串 `""` 的 `sds`                       | O(1)       |
| `sdsnew`             | 根据给定 C 字符串，创建一个相应的 `sds`                      | O(N)       |
| `sdsdup`             | 复制给定 `sds`                                               | O(N)       |
| `sdsfree`            | 释放给定 `sds`                                               | O(N)       |
| `sdsupdatelen`       | 更新给定 `sds` 所对应 `sdshdr` 结构的 `free` 和 `len`        | O(N)       |
| `sdsclear`           | 清除给定 `sds` 的内容，将它初始化为 `""`                     | O(1)       |
| `sdsMakeRoomFor`     | 对 `sds` 所对应 `sdshdr` 结构的 `buf` 进行扩展               | O(N)       |
| `sdsRemoveFreeSpace` | 在不改动 `buf` 的情况下，将 `buf` 内多余的空间释放出去       | O(N)       |
| `sdsAllocSize`       | 计算给定 `sds` 的 `buf` 所占用的内存总数                     | O(1)       |
| `sdsIncrLen`         | 对 `sds` 的 `buf` 的右端进行扩展（expand）或修剪（trim）     | O(1)       |
| `sdsgrowzero`        | 将给定 `sds` 的 `buf` 扩展至指定长度，无内容的部分用 `\0` 来填充 | O(N)       |
| `sdscatlen`          | 按给定长度对 `sds` 进行扩展，并将一个 C 字符串追加到 `sds` 的末尾 | O(N)       |
| `sdscat`             | 将一个 C 字符串追加到 `sds` 末尾                             | O(N)       |
| `sdscatsds`          | 将一个 `sds` 追加到另一个 `sds` 末尾                         | O(N)       |
| `sdscpylen`          | 将一个 C 字符串的部分内容复制到另一个 `sds` 中，需要时对 `sds` 进行扩展 | O(N)       |
| `sdscpy`             | 将一个 C 字符串复制到 `sds`                                  | O(N)       |

`sds` 还有另一部分功能性函数， 比如 `sdstolower` 、 `sdstrim` 、 `sdscmp` ， 等等， 基本都是标准 C 字符串库函数的 `sds` 版本， 这里不一一列举了。

### 3.5 SDS相对于原生C语言字符串优势

1. 每次计算字符串长度（`strlen(s)`）的复杂度为 θ(N)。
2. 对字符串进行 N 次追加，必定需要对字符串进行 N 次内存重分配（`realloc`）。
3. SDS是二进制安全的，可以直接存储二进制数据，在存储二进制数据时通过`len`来判断数据结尾的位置，而不需要通过在末尾插入`\0`来作为结尾符。

## 四. 跳跃表

跳跃表是有序集合（zset）的底层实现，效率高，实现简单。

跳跃表（[skiplist](http://en.wikipedia.org/wiki/Skip_list)）是一种随机化的数据， 由 William Pugh 在论文[《Skip lists: a probabilistic alternative to balanced trees》](http://www.cl.cam.ac.uk/teaching/0506/Algorithms/skiplists.pdf)中提出， 跳跃表以有序的方式在层次化的链表中保存元素， 效率和平衡树媲美 —— 查找、删除、添加等操作都可以在对数期望时间下完成， 并且比起平衡树来说， 跳跃表的实现要简单直观得多。

以下是个典型的跳跃表例子（图片来自[维基百科](http://en.wikipedia.org/wiki/File:Skip_list.svg)）：

![](../images/12.png)

从图中可以看到， 跳跃表主要由以下部分构成：

- 表头（head）：负责维护跳跃表的节点指针。
- 跳跃表节点：保存着元素值，以及多个层。
- 层：保存着指向其他元素的指针。高层的指针越过的元素数量大于等于低层的指针，为了提高查找的效率，程序总是从高层先开始访问，然后随着元素值范围的缩小，慢慢降低层次。
- 表尾：全部由 `NULL` 组成，表示跳跃表的末尾。

因为跳跃表的定义可以在任何一本算法或数据结构的书中找到， 所以本章不介绍跳跃表的具体实现方式或者具体的算法， 而只介绍跳跃表在 Redis 的应用、核心数据结构和 API 。

### 4.1 跳跃表的实现

Redis 的跳跃表由 `redis.h/zskiplistNode` 和 `redis.h/zskiplist` 两个结构定义， 其中 `zskiplistNode` 结构用于表示跳跃表节点， 而 `zskiplist` 结构则用于保存跳跃表节点的相关信息， 比如节点的数量， 以及指向表头节点和表尾节点的指针， 等等。

![](../images/14.png)

上图展示了一个跳跃表示例，位于图片最左边的示 zskiplist 结构，该结构包含以下属性：

- `header` ：指向跳跃表的表头节点。
- `tail` ：指向跳跃表的表尾节点。
- `level` ：记录目前跳跃表内，层数最大的那个节点的层数（表头节点的层数不计算在内）。
- `length` ：记录跳跃表的长度，也即是，跳跃表目前包含节点的数量（表头节点不计算在内）。

位于 `zskiplist` 结构右方的是四个 `zskiplistNode` 结构， 该结构包含以下属性：

- 层（level）：节点中用 `L1` 、 `L2` 、 `L3` 等字样标记节点的各个层， `L1` 代表第一层， `L2` 代表第二层，以此类推。每个层都带有两个属性：前进指针和跨度。前进指针用于访问位于表尾方向的其他节点，而跨度则记录了前进指针所指向节点和当前节点的距离。在上面的图片中，连线上带有数字的箭头就代表前进指针，而那个数字就是跨度。当程序从表头向表尾进行遍历时，访问会沿着层的前进指针进行。
- 后退（backward）指针：节点中用 `BW` 字样标记节点的后退指针，它指向位于当前节点的前一个节点。后退指针在程序从表尾向表头遍历时使用。
- 分值（score）：各个节点中的 `1.0` 、 `2.0` 和 `3.0` 是节点所保存的分值。在跳跃表中，节点按各自所保存的分值从小到大排列。
- 成员对象（obj）：各个节点中的 `o1` 、 `o2` 和 `o3` 是节点所保存的成员对象。

**注意**：表头节点和其他节点的构造是一样的： 表头节点也有后退指针、分值和成员对象， 不过表头节点的这些属性都不会被用到， 所以图中省略了这些部分， 只显示了表头节点的各个层。

#### 4.1.2 跳跃表

跳跃表由 `redis.h/zskiplist` 结构定义：

```c
typedef struct zskiplist {
    // 头节点，尾节点
    struct zskiplistNode *header, *tail;
    // 节点数量
    unsigned long length;
    // 目前表内节点的最大层数
    int level;
} zskiplist;
```

#### 4.1.2 跳跃表节点

跳跃表节点的实现由 `redis.h/zskiplistNode` 结构定义：

```c
typedef struct zskiplistNode {
    // 后退指针
    struct zskiplistNode *backward;
    // 分值
    double score;
    // 成员对象
    robj *obj;
    // 层
    struct zskiplistLevel {
        // 前进指针
        struct zskiplistNode *forward;
        // 跨度
        unsigned int span;
    } level[];
} zskiplistNode;
```

#### 4.1.3 层

跳跃表节点的 level 数组可以包含多个元素，每个元素都包含一个指向其他节点的指针，程序可以通过这些层来加快访问其他节点的速度，一般来说，层的数量越多，访问其他节点的速度就越快。

每次创建一个新跳跃表节点的时候， 程序都根据幂次定律 （[power law](https://link.juejin.cn?target=http%3A%2F%2Fen.wikipedia.org%2Fwiki%2FPower_law)，越大的数出现的概率越小） 随机生成一个介于 `1` 和 `32` 之间的值作为 `level` 数组的大小， 这个大小就是层的“高度”。

下图分别展示了三个高度为 `1` 层、 `3` 层和 `5` 层的节点， 因为 C 语言的数组索引总是从 `0` 开始的， 所以节点的第一层是 `level[0]` ， 而第二层是 `level[1]` ， 以此类推。

![](../images/15.png)



以下是操作这两个数据结构的 API ，API 的用途与相应的算法复杂度：

| 函数                    | 作用                                                      | 复杂度                 |
| :---------------------- | :-------------------------------------------------------- | :--------------------- |
| `zslCreateNode`         | 创建并返回一个新的跳跃表节点                              | 最坏 O(1)              |
| `zslFreeNode`           | 释放给定的跳跃表节点                                      | 最坏 O(1)              |
| `zslCreate`             | 创建并初始化一个新的跳跃表                                | 最坏 O(1)              |
| `zslFree`               | 释放给定的跳跃表                                          | 最坏 O(N)              |
| `zslInsert`             | 将一个包含给定 `score` 和 `member` 的新节点添加到跳跃表中 | 最坏 O(N) 平均 O(logN) |
| `zslDeleteNode`         | 删除给定的跳跃表节点                                      | 最坏 O(N)              |
| `zslDelete`             | 删除匹配给定 `member` 和 `score` 的元素                   | 最坏 O(N) 平均 O(logN) |
| `zslFirstInRange`       | 找到跳跃表中第一个符合给定范围的元素                      | 最坏 O(N) 平均 O(logN) |
| `zslLastInRange`        | 找到跳跃表中最后一个符合给定范围的元素                    | 最坏 O(N) 平均 O(logN) |
| `zslDeleteRangeByScore` | 删除 `score` 值在给定范围内的所有节点                     | 最坏 O(N^2)            |
| `zslDeleteRangeByRank`  | 删除给定排序范围内的所有节点                              | 最坏 O(N^2)            |
| `zslGetRank`            | 返回目标元素在有序集中的排位                              | 最坏 O(N)平均 O(logN)  |
| `zslGetElementByRank`   | 根据给定排位，返回该排位上的元素节点                      | 最坏 O(N)平均 O(logN)  |

### 4.2 跳跃表的应用

和字典、链表或者字符串这几种在 Redis 中大量使用的数据结构不同， 跳跃表在 Redis 的唯一作用， 就是实现有序集数据类型。

跳跃表将指向有序集的 `score` 值和 `member` 域的指针作为元素， 并以 `score` 值为索引， 对有序集元素进行排序。

举个例子， 以下代码创建了一个带有 3 个元素的有序集：

```shell
redis> ZADD s 6 x 10 y 15 z
(integer) 3

redis> ZRANGE s 0 -1 WITHSCORES
1) "x"
2) "6"
3) "y"
4) "10"
5) "z"
6) "15"
```

在底层实现中， Redis 为 `x` 、 `y` 和 `z` 三个 `member` 分别创建了三个字符串， 值分别为 `double` 类型的 `6` 、 `10` 和 `15` ， 然后用跳跃表将这些指针有序地保存起来， 形成这样一个跳跃表：

![](../images/13.png)

为了方便展示， 在图片中我们直接将 `member` 和 `score` 值包含在表节点中， 但是在实际的定义中， 因为跳跃表要和另一个实现有序集的结构（字典）分享 `member` 和 `score` 值， 所以跳跃表只保存指向 `member` 和 `score` 的指针。 更详细的信息，请参考《[有序集](https://redisbook.readthedocs.io/en/latest/datatype/sorted_set.html#sorted-set-chapter)》章节

### 4.3 为啥 redis 使用跳表(skiplist)而不是使用红黑树

skiplist的复杂度和红黑树一样，而且实现起来更简单。

在并发环境下skiplist有另外一个优势，红黑树在插入和删除的时候可能需要做一些rebalance的操作，这样的操作可能会涉及到整个树的其他部分，而skiplist的操作显然更加局部性一些，锁需要盯住的节点更少，因此在这样的情况下性能好一些。









> 本文参考：
>
> [Redis 设计与实现: redisObject 数据结构，以及 Redis 的数据类型 - 云+社区 - 腾讯云 (tencent.com)](https://cloud.tencent.com/developer/article/1608410)
>
> [简单动态字符串 — Redis 设计与实现 (redisbook.readthedocs.io)](https://redisbook.readthedocs.io/en/latest/internal-datastruct/sds.html)
>
> [深入理解Redis跳跃表的基本实现和特性 - 掘金 (juejin.cn)](https://juejin.cn/post/6893072817206591496)

