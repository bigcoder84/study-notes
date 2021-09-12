# API的理解和使用

- [API的理解和使用](#api的理解和使用)
  - [一. 键管理](#一-键管理)
    - [1.1 检查键是否存在](#11-检查键是否存在)
    - [1.2 删除键](#12-删除键)
    - [1.3 键重命名](#13-键重命名)
    - [1.4 键总数](#14-键总数)
    - [1.5 键过期](#15-键过期)
      - [1.5.1 设置键过期时间](#151-设置键过期时间)
      - [1.5.2 查看键过期时间](#152-查看键过期时间)
    - [1.6 遍历键](#16-遍历键)
      - [1.6.1 全量遍历键](#161-全量遍历键)
      - [1.6.2 渐进式遍历](#162-渐进式遍历)
    - [1.7 键的数据结构](#17-键的数据结构)
  - [二. 数据结构和内部编码](#二-数据结构和内部编码)
  - [三. 字符串](#三-字符串)
    - [3.1 设置值](#31-设置值)
    - [3.2 获取值](#32-获取值)
    - [3.3 批量设置值](#33-批量设置值)
    - [3.4 批量获取值](#34-批量获取值)
    - [3.5 计数](#35-计数)
    - [3.6 追加值](#36-追加值)
    - [3.7 字符串长度](#37-字符串长度)
    - [3.8 设置并返回原值](#38-设置并返回原值)
    - [3.9 设置指定位置的字符串](#39-设置指定位置的字符串)
    - [3.10 获取部分字符串](#310-获取部分字符串)
    - [3.11 内部编码](#311-内部编码)
  - [四. 哈希](#四-哈希)
    - [4.1 设置值](#41-设置值)
    - [4.2 获取值](#42-获取值)
    - [4.3 删除field](#43-删除field)
    - [4.4 计算field的个数](#44-计算field的个数)
    - [4.5 批量设置或获取field-value](#45-批量设置或获取field-value)
    - [4.6 判断field是否存在](#46-判断field是否存在)
    - [4.7 获取所有field](#47-获取所有field)
    - [4.8 获取所有value](#48-获取所有value)
    - [4.9 获取所有field-value](#49-获取所有field-value)
    - [4.10 计算value的字符串长度（需要Redis 3.2以上）](#410-计算value的字符串长度需要redis-32以上)
    - [4.11 自增](#411-自增)
    - [4.12 内部编码](#412-内部编码)
  - [五. 列表](#五-列表)
    - [5.1 添加操作](#51-添加操作)
    - [5.2 查找操作](#52-查找操作)
    - [5.3 删除操作](#53-删除操作)
    - [5.4 修改操作](#54-修改操作)
    - [5.5 阻塞操作](#55-阻塞操作)
    - [5.6 内部编码](#56-内部编码)
  - [六. 集合](#六-集合)
    - [6.1 集合内操作](#61-集合内操作)
    - [6.2 集合间的操作](#62-集合间的操作)
    - [6.3 内部编码](#63-内部编码)
  - [七. 有序集合](#七-有序集合)
    - [7.1 集合内操作](#71-集合内操作)
    - [7.2 集合间的操作](#72-集合间的操作)
    - [7.3 内部编码](#73-内部编码)
  - [八. Bitmaps](#八-bitmaps)
    - [8.1 设置值](#81-设置值)
    - [8.2 获取值](#82-获取值)
    - [8.3 获取Bitmaps指定范围值为1的个数](#83-获取bitmaps指定范围值为1的个数)
    - [8.4 Bitmaps间的运算](#84-bitmaps间的运算)
    - [8.5 计算Bitmaps中第一个值为targetBit的偏移量](#85-计算bitmaps中第一个值为targetbit的偏移量)
  - [九. GEO（地理位置信息）](#九-geo地理位置信息)
    - [9.1 增加地理位置信息](#91-增加地理位置信息)
    - [9.2 删除地理位置信息](#92-删除地理位置信息)
    - [9.3 获取地理位置](#93-获取地理位置)
    - [9.4 获取两个地理位置的距离](#94-获取两个地理位置的距离)
    - [9.5 获取指定位置范围的地理信息位置集合](#95-获取指定位置范围的地理信息位置集合)


## 一. 键管理

### 1.1 检查键是否存在

```shell
exists key
```

如果键存在则返回1，如果不存在则返回0。

### 1.2 删除键

```shell
#删除单个键
del key
#删除多个键
del key1 key2 ...
```

del是一个通用命令，不管是什么数据类型，del都能将其删除。

返回结果为成功删除的键的个数，如果删除一个不存在的键，就会返回0。

### 1.3 键重命名

```shell
rename key newkey
renamenx key newkey
```

如果在rename之前，键”newkey“已经存在，那么它的值也将被覆盖。为了防止被强行rename，Redis提供了renamenx命令，确保只有在newkey不存在时才会被重命名。

由于重命名期间会执行del命令删除旧的键，如果键对应的值比较大，会存在阻塞Redis的可能性，这点不要忽视。

**随机返回一个键**

```shell
randomkey
```

### 1.4 键总数

```shell
dbsize
```

dbsize命令会返回当前数据库中键的总数。该命令不会遍历所有键，而是直接获取Redis内置的键总数遍历，所以dbsize的时间复杂度是O(1)。

### 1.5 键过期

#### 1.5.1 设置键过期时间

```shell
expire key seconds #键在seconds秒后过期
expireat key timestamp #键在秒级时间戳timestamp后过期
pexpire key milliseconds #键在milliseconds毫秒后过期
pexpireat key milliseconds-timestamp #键在毫秒级时间戳timestamp后过期 

persist key #将键的过期时间清除
```

使用键过期命令时需要注意以下几点：

- 无论使用过期时间还是时间戳，秒级还是毫秒级，在Redis内部最终使用的都是pexpireat
- 对于字符串类型键，执行set命令会去掉过期时间
- Redis不支持二级数据结构内部元素的过期功能
- setex命令作为set+expire的组合，不但是原子执行，同时减少了一次网络通讯时间。

#### 1.5.2 查看键过期时间

```shell
ttl key #查看秒级剩余过期时间
pttl key #查看毫秒级剩余过期时间
```

ttl命令会返回键的剩余过期时间，它会有三种返回值：

- 大于等于0的整数：键剩余的过期时间
- -1：键没设置过期时间
- -2：键不存在

### 1.6 遍历键

#### 1.6.1 全量遍历键

```shell
keys pattern
```

pattern可以使用通配符进行匹配：

- `*`代表匹配N个任意字符
- `?`代表匹配一个任意字符
- `[]`代表匹配部分字符，例如：[1,3]代表匹配1、3；[1-10]代表匹配1到10的任意数字。
- `\x`用来做转义，例如要匹配`*`、`?`需要进行转义

例如，如果我们要匹配j、r开头，紧跟edis字符串的所有键：

```shell
keys [j,r]edis
```

当需要遍历所有键时（例如检测过期或闲置时间、寻找大对象等），keys是一个很有帮助的命令，例如想删除所有以video字符串开头的键，可以执行一下操作：

```shell
redis-cli keys video* | xargs redis-cli del
```

但是如果考虑到Redis是单线程架构就不那么美妙了，如果Redis包含了大量的键，执行keys命令很可能会造成Redis阻塞，所以一般建议不要在生产环境下使用keys命令。

#### 1.6.2 渐进式遍历

keys不建议在生产环境上使用，那如果我们真的有遍历所有键的需求该如何解决呢？

Redis从2.8版本后，提供了一个新命令scan，它能有效的解决keys命令存在的问题。和keys命令执行时会遍历所有键不同的是，scan采用渐进式遍历的方式来解决keys命令可能带来的阻塞问题，每次scan命令的时间复杂度是O(1)，但是要真正实现keys功能，需要执行多次scan。每次执行scan，可以想象成只扫描一个字典中的一部分键，直到将字典中的所有键遍历完毕。

```shell
scan cursor [match pattern] [count number]
```

- cursor是必需参数，实际上cursor是一个游标，第一次遍历从0开始，每次scan遍历完都会返回当前游标的值，直到游标值为0，表示遍历结束。
- match pattern是可选参数，它的作用是做模式匹配，这点和keys的模式匹配很像。
- count number是可选参数，它的作用是表明每次要遍历的键个数，默认值是10，此参数可以适当增大。

现在有14个键，我们使用scan命令遍历所有键：

```shell
127.0.0.1:7002> keys *
 1) "set_1_2"
 2) "nxkey"
 3) "redis"
 4) "zset:2"
 5) "user:ranking"
 6) "list"
 7) "views"
 8) "user:1"
 9) "key"
10) "zset_inter_1_2"
11) "set1"
12) "zset:1"
13) "put"
14) "set2"
127.0.0.1:7002> scan 0 count 5
1) "10"
2) 1) "set_1_2"
   2) "nxkey"
   3) "views"
   4) "user:1"
   5) "redis"
127.0.0.1:7002> scan 10 count 5
1) "3"
2) 1) "user:ranking"
   2) "zset:1"
   3) "put"
   4) "zset:2"
   5) "zset_inter_1_2"
   6) "set1"
127.0.0.1:7002> scan 3 count 5
1) "0"
2) 1) "key"
   2) "list"
   3) "set2"
```

除了scan以外，Redis提供了面向hash类型、集合类型、有序集合的扫描遍历命令，解决诸如hgetall、smembers、zrange可能产生的阻塞问题，对应的命令分别是hscan、sscan、zscan，它们的用法和scan基本类似。

渐进式遍历可以有效解决keys命令可能产生阻塞的问题，但是scan并非完美无瑕，如果scan的过程中如果有键的变化（增加、删除、重命名），那么遍历就会出现如下问题：新增的键没有被遍历到，遍历出现重复元素的情况，也就是说**scan并不能保证完整的遍历出来所有的键**，这些是我们在开发时需要考虑的。

### 1.7 键的数据结构

```shell
type key
```

type命令会返回key对应value的数据结构类型，如果key不存在则返回`none`。

type命令的返回值有：

- string（字符串）
- hash（哈希）
- list（列表）
- set（集合）
- zset（有序集合）

## 二. 数据结构和内部编码

type命令可以查看Key的数据结构，但是这些都是Redis对外的数据结构，实际上每种数据结构都有自己底层的内部编码实现，而且是多种实现，这样Redis会在合适的场景选择合适的内部编码。

![](../images/1.png)

可以看到每种数据结构都有两种以上的内部实现，例如list数据结构包含了linkedlist和ziplist两种内部编码。同时有些内部编码，例如ziplist，可以作为多种外部数据结构的内部实现，可以通过下列命令，查看一个key的底层编码是什么：

```shell
object encoding key
```

Redis这样设计有两个好处：

第一，可以改进内部编码，而对外的数据结构和命令没有影响，这样一旦开发出更优秀的内部编码，无修改动外部数据结构和命令。例如Redis 3.2提供了quicklist，结合了ziplist和linkedlist两者的优势，为列表提供了更为优秀的内部编码实现，而对外部用户来说基本感知不到。

第二，多种内部编码实现可以在不同场景下发挥各自的优势，例如ziplist比较节省内存，但是在列表元素比较多的情况下，性能会有所下降，这时候Redis会根据配置选项将列表类型的内部实现由ziplist转换为linkedlist。

## 三. 字符串

### 3.1 设置值

```shell
set key value [ex seconds] [px milliseconds] [nx|xx]
```

选项：

- ex seconds：为键设置秒级过期时间
- px milliseconds：为键设置毫秒级过期时间
- nx：键必须不存在才能设置成功
- xx：键必须存在才能设置成功

nx插入模式可以作为分布式锁的一种实现方案，Redis还提供了setex和setnx两个命令，它们的作用与ex和nx选项是一样的。

```shell
127.0.0.1:7002> exists nxkey
(integer) 0 #nxkey不存在
127.0.0.1:7002> setnx nxkey nxvalue
(integer) 1 #设置成功
127.0.0.1:7002> exists nxkey
(integer) 1 #nxkey存在
127.0.0.1:7002> setnx nxkey nxvalue
(integer) 0 #设置不成功
```

### 3.2 获取值

```shell
get key
```

### 3.3 批量设置值

```shell
mset key value [key value ...]
```

### 3.4 批量获取值

```shell
mget key [key ...]
```

### 3.5 计数

```shell
incr key	
```

incr命令用于对值做自增操作，返回结果分为三种情况：

- 值不是整数，返回错误
- 值是整数，返回自增后的结果
- 键不存在，按照值为0进行自增，返回结果为1

除了incr命令，Redis还提供了decr（自减）、incrby（自增指定数字）、decrby（自减指定数字）、incrbyfloat（自增浮点数）命令：

```shell
decr key
incrby key increment
decrby key decrement
incrbyfloat key increment
```

很多存储系统和编程语言内部使用CAS机制实现计数器功能，会有一定的CPU开销，但在Redis中完全不存在这个问题，因为Redis是单线程架构，任何命令到了Redis服务端都要顺序执行。

### 3.6 追加值

```shell
append key value
```

append可以向字符串尾部追加值，例如：

```shell
127.0.0.1:7002> get key
"test"
127.0.0.1:7002> append key 123
(integer) 7
127.0.0.1:7002> get key
"test123"
```

### 3.7 字符串长度

```shell
strlen key
```

注意该命令返回的是字节数，如果是中文，则每个字符占3个字节。

### 3.8 设置并返回原值

```shell
getset key value
```

getset命令和set一样会设置值，但是不同的是，它同时会返回键原来的值。

```shell
127.0.0.1:7002> getset hello world
(nil)
127.0.0.1:7002> getset hello redis
"world"
```

### 3.9 设置指定位置的字符串

```shell
setrange key offeset value
```

下面操作将pest编程best：

```shell
127.0.0.1:7002> set redis pest
OK
127.0.0.1:7002> setrange redis 0 b
(integer) 4
127.0.0.1:7002> get redis
"best"
127.0.0.1:7002> setrange redis 0 qwe
(integer) 4
127.0.0.1:7002> get redis
"qwet"
```

### 3.10 获取部分字符串

```shell
getrange key start end
```

start和end分别是开始和结束的偏移量，偏移量从0开始计算

### 3.11 内部编码

字符串类型的内部编码有3种：

- int：8个字节的长整型
- embstr：小于定于39个字节的字符串
- raw：大于39个字节的字符串

Redis会根据当前值的类型和长度决定使用哪种内部编码实现。

```shell
127.0.0.1:7002> set key 123456
OK
127.0.0.1:7002> object encoding key
"int"
127.0.0.1:7002> set key a12345678912345678901234567890123456789
OK
127.0.0.1:7002> object encoding key
"embstr" 
```

## 四. 哈希

### 4.1 设置值

```shell
hset key field value
```

### 4.2 获取值

```shell
hget key field
```

如果field不存在，返回nil：

### 4.3 删除field

```shell
hdel key field [field ...]
```

hdel会删除一个或多个field，返回结果为成功删除field的个数

### 4.4 计算field的个数

```shell
hlen key
```

### 4.5 批量设置或获取field-value

```shell
hmset key field value [field value ...]
hmget key field [field ...]
```

### 4.6 判断field是否存在

```shell
hexists key field
```

### 4.7 获取所有field

```shell
hkeys key
```

### 4.8 获取所有value

```shell
hvals key
```

### 4.9 获取所有field-value

```shell
hgetall key
```

例如：

```shell
127.0.0.1:7002> hset user:1 name tianjindong
(integer) 1
127.0.0.1:7002> hgetall user:1
1) "name"
2) "tianjindong"
```

在使用hgetall时，如果hash元素个数比较多，会存在阻塞Redis的可能。如果开发人员只需要获取部分field，可以使用hmget，如果一定要获取全部field-value，可以使用hscan命令，该命令会渐进式遍历哈希类型。

### 4.10 计算value的字符串长度（需要Redis 3.2以上）

```shell
hstrlen key field
```

### 4.11 自增

```shell
hincrby key field increment
hincrbyfloat key field
```

例如：

```shell
127.0.0.1:7002> hincrby user:1 age 2
(integer) 2
127.0.0.1:7002> hget user:1 name
"tianjindong"
127.0.0.1:7002> hget user:1 age
"2"
127.0.0.1:7002> hget user:1 age
"2"
127.0.0.1:7002> hincrbyfloat user:1 age 1.5
"3.5"
127.0.0.1:7002> hget user:1 age
"3.5"
```

### 4.12 内部编码

哈希类型的内部编码有两种：

- ziplist（压缩列表）：当哈希类型元素个数小于hash-max-ziplist-entries配置（默认512个），同时所有值都小于hash-max-ziplist-value配置（默认是64）字节时，Redis会使用ziplist作为hash内部实现，ziplist使用了更加紧凑的结构实现多个元素的连续存储，所以在节省内存方面比hashtable更加优秀。
- hashtable（哈希表）：当哈希类型无法满足ziplist的条件时，Redis会使用hashtable作为哈希的内部实现，因为此时ziplist的读写效率会下降，而hashtable的读写时间复杂度为O(1)

## 五. 列表

列表（list）类型用来存储多个有序字符串，列表中的每个字符串成为元素（element），一个列表最多可以存储2^32-1个元素。在Redis中，可以对列表两端插入（push）和弹出（pop），还可以获得指定范围的元素列表、获取指定索引下标的元素等。



![](../images/2.png)

### 5.1 添加操作

```shell
rpush key value [value ...] #从右边插入元素
lpush key value [value ..] #从左边插入元素
linsert key before|after pivot value #linsert命令会从列表中找到等于pivot的元素，在其前(before)或者后(after)插入一个新元素value 
```

例如下面这个示例：

```shell
127.0.0.1:7002> rpush list a b 
(integer) 2
127.0.0.1:7002> lrange list 0 -1
1) "a"
2) "b"
127.0.0.1:7002> lpush list c d
(integer) 4
127.0.0.1:7002> lrange list 0 -1
1) "d"
2) "c"
3) "a"
4) "b"
127.0.0.1:7002> linsert list before b c
(integer) 6
127.0.0.1:7002> lrange list 0 -1
1) "d"
2) "c"
3) "a"
4) "c"
5) "b"
127.0.0.1:7002> linsert list before c 1
(integer) 7
127.0.0.1:7002> lrange list 0 -1
1) "d"
2) "1"
3) "c"
4) "a"
5) "c"
6) "b"
```

### 5.2 查找操作

**获取指定范围内的元素列表**

```shell
lrange key start end 
```

lrange操作会获取列表指定范围所有元素。索引下标有两个特点：

- 索引下标从左到右分别是0到N-1，但是从右到左分别是-1到-N。
- lrange中的end选项包含自身，这和很多编程语言不包含end不太相同。

**获取列表指定索引下标的元素**

```shell
lindex key index
```

**获取列表长度**

```shell
llen key
```

### 5.3 删除操作

**弹出列表左端元素**

```shell
lpop key
```

**弹出列表右端元素**

```shell
rpop key
```

**删除指定元素**

```shell
lrem key count value 
```

lrem命令从列表中找到等于value的元素进行删除，根据count的不同分为三种情况：

- count>0，从左到右，删除最多count个元素。
- count<0，从右到左，删除最多个count绝对值个元素。
- count=0，删除所有元素

**按照索引范围修剪列表**

```shell
ltrim key start end
```

ltrim命令将只保留start-end范围内的元素，其它元素全部删除。

### 5.4 修改操作

```shell
lset key index value
```

修改指定下标的元素

### 5.5 阻塞操作

```shell
blpop key [key ...] timeout
brpop key [key ...] timeout
```

blpop和brpop是lpop和rpop的阻塞版本，timeout用于指定阻塞时间（单位：秒）。

- 如果指定了多个键，那么brpop会从左至右遍历键，一旦有一个键能弹出元素，客户端立即返回
- 如果客户端对同一个键执行brpop并阻塞了，那么先执行brpop命令的客户端可以优先获取到其它客户端新放入列表中的值

### 5.6 内部编码

ziplist（压缩列表）：当列表元素小于list-max-ziplist-entries配置（默认512个），同时列表中每个元素的值都小于list-max-ziplist-value配置时（默认64字节），Redis会选用ziplist来作为列表的内部实现来减少内存的使用。

linkedlist：当列表类型无法满足ziplist的条件时，Redis会使用linkedlist作为列表的内部实现。

> Redis 3.2版本提供了quicklist内部编码，简单地说它是以一个ziplist为节点linkedlist，它结合了ziplist和linkedlist两者的优势，为列表类型提供了一种更为优秀的内部编码实现。

## 六. 集合

集合与列表类型不一样的是，集合中不允许有重复元素，并且集合中的元素是无序的，不能通过索引访问元素。一个集合最多可以存储2^32-1个元素。Redis除了支持集合内的增删查改，同时还支持多个集合取交集、并集、差集，合理的使用好集合能在开发中解决很多问题。

### 6.1 集合内操作

**添加元素**

```shell
sadd key element [element ...]
```

返回为添加成功的元素个数

**删除元素**

```shell
srem key element [element ...]
```

**计算元素个数**

```shell
scard key
```

scard时间复杂度为O(1)，它不会遍历集合元素，而是使用Redis内部的变量。

**判断元素是否在集合中**

```shell
sismember key element
```

如果给定元素在集合中，返回1，反之返回0。

**随机从集合中返回指定个数元素**

```shell
srandmember key [count]
```

count是可选参数，如果不写则默认为1

**从集合中随机弹出元素**

```shell
spop key
```

需要注意的是，Redis从3.2版本开始，spop也支持count参数。srandmember和spop都是随机从集合中选取元素，两者不同的是spop命令执行后，元素会从集合中删除，而srandmember不会。

**获取所有元素**

```shell
smembers key
```

### 6.2 集合间的操作

**求多个集合的交集**

```shell
sinter key [key ...]
```

**求多个集合的并集**

```shell
sunion key [key ...]
```

**求多个集合的差集**

```shell
sdiff key [key ...]
```

示例：

```shell
127.0.0.1:7002> smembers set1
1) "c"
2) "b"
3) "a"
127.0.0.1:7002> smembers set2
1) "d"
2) "c"
3) "b"

#交集
127.0.0.1:7002> sinter set1 set2
1) "c"
2) "b"
#并集
127.0.0.1:7002> sunion set1 set2
1) "c"
2) "b"
3) "a"
4) "d"
#差集
127.0.0.1:7002> sdiff set1 set2
1) "a"
127.0.0.1:7002> sdiff set2 set1
1) "d"
```

**将交集、并集、差集结果保存**

```shell
sinterstore destination key [key ...]
sunionstore destination key [key ...]
sdiffstore destination key [key ...]
```

集合间运算在元素较多的情况下会比较耗时，所以Redis提供了上面三个命令（原名令+store）将集合间交集、并集、差集的结果保存在destination key中。

例如，将set1和set2取交集结果存入set_1_2中：

```shell
127.0.0.1:7002> sinterstore set_1_2 set1 set2
(integer) 2
127.0.0.1:7002> smembers set_1_2
1) "b"
2) "c"
```

### 6.3 内部编码

集合类型的内部编码有两种：

- intset（整数集合）：当集合中的元素都是整数且元素个数小于set-max-intset-entries配置（默认是512个）时，Redis会选用intset来作为集合的内部实现，从而减少内存的使用。
- hashtable（哈希表）：当集合中的元素无法满足intset的条件时，Redis会使用hashtable作为集合的内部实现。

## 七. 有序集合

有序集合保留了集合不能有重复元素的特性，但不同的是，有序集合中的元素可以排序。但是它和列表使用索引下标作为排序依据不同的是，它给每个元素设置一个分数（score）作为排序的依据。

### 7.1 集合内操作

**添加成员**

```shell
zadd key score member [score member ...]
```

下面操作向有序集合user:ranking添加用户tom和他的分数251：

```shell
127.0.0.1:7002> zadd user:ranking 251 tom
(integer) 1
```

返回结果代表成功添加的个数。

> Redis 3.2为zadd命令添加了nx、xx、ch、incr四个选项：
>
> - nx：member必须不存在，才可以设置成功。
> - xx：member必须存在，才可以设置成功
> - ch：返回此次操作后，有序集合元素和分数发生变化的个数
> - incr：对score做增加，相当于后面介绍的zincrby

有序集合相比集合提供了排序字段，但是也产生了代价，zadd的时间复杂度为O(log(n))，sadd的时间复杂度为O(1)。

**计算成员个数**

```shell
zcard key
```

**获取某个成员的分数**

```shell
zscore key member
```

如果member不存在则返回nil。

**计算成员排名**

```shell
zrank key member
zrevrank key member
```

zrank是从分数从低到高返回排名，zrevrank反之，第一名返回0，依次类推。

**删除成员**

```shell
zrem key member [member ...]
```

**增加成员分数**

```shell
zincrby key increment member
```

给tom加9分变成160分：

```shell
127.0.0.1:7002> zscore user:ranking tom
"251"
127.0.0.1:7002> zincrby user:ranking 9 tom
"260"
```

**返回指定排名范围的成员**

```shell
zrange key start end [withscores]
zrevrange key start end [withscores]
```

有序集合是按照分值排名的，zrange是从低到高返回，zrevrange反之。withscores参数表名返回时带上成员的分数。

**返回指定分数范围的成员**

```shell
zrangebyscore key min max [withscores] [limit offset count]
zrevrangebyscore key min max [withscores] [limit offset count]
```

其中zrangebyscore按照分数从低到高返回，zrevrangebyscore反之。withscores参数会同时返回每个成员的分数。limit offset count参数可以限制输出的起始位和个数（类似于MySQL中的limit）。

同时min和max还支持开区间（小括号）和闭区间（中括号），-inf和+inf分别代表无限小和无限大：

```shell
127.0.0.1:7002> zrangebyscore user:ranking 260 +inf limit 0 1
1) "tom"
127.0.0.1:7002> zrangebyscore user:ranking (260 +inf limit 0 1
(empty array)
```

**返回指定分数范围的成员个数**

```shell
zcount key min max
```

**删除指定排名内的升序元素**

```shell
zremrangebyrank key start end
```

**删除指定分数范围的成员**

```shell
zremrangebyscore key min max
```

下面是将分数250分以上的成员全部删除：

```shell
zremrangebyscore user:ranking (250 +inf
```

### 7.2 集合间的操作

**交集**

```shell
zinterstore destination numkeys key [key ...] [weights weight [weight ...]] [aggregate sum|min|max]
```

- destination：交集计算结果保存至这个键
- numkeys：需要做交集计算键的个数
- key [key …]：需要做交集计算的键
- weights weight [weight …]：每个键的权重，在做交集计算时，每个键中的每个member会将自己的分数乘以这个权重，每个键的权重默认是1。
- aggregate sum|min|max：计算成员交集后，分值可以按照sum（和）、min（最小值）、max（最大值）做汇总，默认值是sum。

```shell
# 测试数据
127.0.0.1:7002> zadd zset:1 1 a 2 b 3 c
(integer) 3
127.0.0.1:7002> zadd zset:2 1 b 4 c 5 e
(integer) 3
127.0.0.1:7002> zinterstore zset_inter_1_2 2 zset:1 zset:2 weights 1 2
(integer) 2
127.0.0.1:7002> zrange zset_inter_1_2 0 -1 WITHSCORES
1) "b"
2) "4"
3) "c"
4) "11"
```

**并集**

```shell
zunionstore destination numkeys key [key ...] [weights weight [weight ...]] [aggregate sum|min|max]
```

zunionstore和zinterstore参数保持一致

### 7.3 内部编码

有序集合类型的内部编码有两种：

- ziplist（压缩列表）：当有序集合元素个数小于zset-max-ziplist-entries配置（默认是128个），同时每个元素的值都小于zset-max-ziplist-value配置（默认64字节）时，Redis会使用ziplist来作为有序集合的内部实现，ziplist可以有效减少内存的使用。
- skiplist（跳跃表）：当ziplist条件不满足时，有序集合会使用skiplist作为内部实现，因为此时ziplist的读写效率会下降。



## 八. Bitmaps

许多开发语言提供了操作位的功能，合理的使用位能够有效地提高内存使用率和开发效率。Redis提供了Bitmaps这个“数据结构”可以实现对位的操作。把数据结构加上引号是因为：

- Bitmaps本身不是一种数据结构，实际上它就是字符串，但是它可以对字符串的位进行操作。
- Bitmaps单独提供一套命令，所以在Redis中使用Bitmaps和使用字符串的方法不太相同。可以把Bitmaps想象成一个以位为单位的数组，数组的每个单元只能存储1和0，数组的下标在Bitmaps中叫做偏移量。

### 8.1 设置值

```shell
$ setbit key offest value
```

> 可用版本： >= 2.2.0
>
> 时间复杂度: O(1)

对 `key` 所储存的字符串值，设置或清除指定偏移量上的位(bit)。位的设置或清除取决于 `value` 参数，可以是 `0` 也可以是 `1` 。当 `key` 不存在时，自动生成一个新的字符串值。

字符串会进行伸展(grown)以确保它可以将 `value` 保存在指定的偏移量上。当字符串值进行伸展时，空白位置以 `0` 填充。

`offset` 参数必须大于或等于 `0` ，小于 2^32 (bit 映射被限制在 512 MB 之内)。

```shell
$ setbit bitmaps-test 0 1
0
$ type bitmaps-test
string
```

在第一次初始化Bitmaps时，假如偏移量非常大，那么整个初始化过程执行会比较慢，可能会造成redis堵塞。

### 8.2 获取值

```shell
$ getbit key offest
```

> 可用版本： >= 2.2.0
>
> 时间复杂度： O(1)

对 `key` 所储存的字符串值，获取指定偏移量上的位(bit)。

当 `offset` 比字符串值的长度大，或者 `key` 不存在时，返回 `0` 。

### 8.3 获取Bitmaps指定范围值为1的个数

```shell
$ bitcount key [start end]
```

> 可用版本： >= 2.6.0
>
> 时间复杂度： O(N)

计算给定字符串中，被设置为 `1` 的比特位的数量。

一般情况下，给定的整个字符串都会被进行计数，通过指定额外的 `start` 或 `end` 参数，可以让计数只在特定的位上进行。

`start` 和 `end` 参数的设置和 [GETRANGE key start end](../string/getrange.html#getrange) 命令类似，都可以使用负数值： 比如 `-1` 表示最后一个字节， `-2` 表示倒数第二个字节，以此类推。

不存在的 `key` 被当成是空字符串来处理，因此对一个不存在的 `key` 进行 `BITCOUNT` 操作，结果为 `0` 。

下面操作计算2016-04-05这天的独立访问用户数：

```shell
$ bitcount unique:users:20160405 
```

### 8.4 Bitmaps间的运算

```shell
$ bitop op destket key [key ...]
```

bitop是一个符合操作，他可以做多个Bitmaps的and(交集)、or（并集）、not（非）、xor（异或）操作，并将结果保存到destkey中。

例如我们想计算2021-09-12、2021-09-13两天都访问网站的用户数量：

```shell
$ bitop and unique:users:and:20210912-13 unique:users:and:20210912 unique:users:and:20210913
2
$ bitcount unique:users:and:20210912-13
```

### 8.5 计算Bitmaps中第一个值为targetBit的偏移量

```shell
$ bitpos key targetBit [start] [end]
```

> 可用版本： >= 2.8.7
>
> 时间复杂度： O(N)，其中 N 为位图包含的二进制位数量

返回位图中第一个值为 `bit` 的二进制位的位置。

在默认情况下， 命令将检测整个位图， 但用户也可以通过可选的 `start` 参数和 `end` 参数指定要检测的范围。

例如我们要计算2021-09-12当前访问网站的最小的用户ID：

```shell
bitpos unique:users:and:20210912 1
```

## 九. GEO（地理位置信息）

Redis 3.2版本提供了GEO（地理位置）功能，支持存储地理位置信息用来实现诸如附近位置、摇一摇这类依赖于地理位置信息的功能，对于需要实现这些功能的开发者来说是一大福音。

### 9.1 增加地理位置信息

```shell
$ geoadd key longitude latitude member [longitude latitude member ...]
```

longitude、latitude、member分别是该地理位置的经度、维度、成员，返回结果代表添加成功的个数，如果已经包含member，则视为更新操作，返回值记为0。

### 9.2 删除地理位置信息

```shell
$ zrem key memeber
```

GEO没有提供删除成员的命令，但是因为GEO的底层实现是ZSET，所以可以借鉴 zrem 命令实现对地理位置的删除。

### 9.3 获取地理位置

```shell
$ geopos key member [member ...]
```

> 可用版本： >= 3.2.0
>
> 时间复杂度： 获取每个位置元素的复杂度为 O(log(N)) ， 其中 N 为键里面包含的位置元素数量。

从键里面返回所有给定位置元素的位置（经度和纬度）。

因为 `GEOPOS` 命令接受可变数量的位置元素作为输入， 所以即使用户只给定了一个位置元素， 命令也会返回数组。

```shell
redis> GEOPOS Sicily Palermo Catania NonExisting
1) 1) "13.361389338970184"
   2) "38.115556395496299"
2) 1) "15.087267458438873"
   2) "37.50266842333162"
3) (nil)
```

### 9.4 获取两个地理位置的距离

```shell
$ geodist key member1 member2 [unit]
```

> 可用版本： >= 3.2.0
>
> 复杂度： O(log(N))

返回两个给定位置之间的距离。

如果两个位置之间的其中一个不存在， 那么命令返回空值。

指定单位的参数 `unit` 必须是以下单位的其中一个：

- `m` 表示单位为米。
- `km` 表示单位为千米。
- `mi` 表示单位为英里。
- `ft` 表示单位为英尺。

如果用户没有显式地指定单位参数， 那么 `GEODIST` 默认使用米作为单位。

`GEODIST` 命令在计算距离时会假设地球为完美的球形， 在极限情况下， 这一假设最大会造成 0.5% 的误差。

### 9.5 获取指定位置范围的地理信息位置集合

```shell
$ georadius key longitude latitude radiusm|km|ft|mi [withcoord] [withdist] [withhash] [COUTN count] [asc|desc] [store key] [storedist key]
$ georadiusbymember key member radiusm|km|ft|mi [withcoord] [withdist] [withhash] [COUTN count] [asc|desc] [store key] [storedist key]
```

georadius和georadiusbymember 两个命令的作用是一样的，都是以一个地理位置为中心算出指定半径内的其他地理信息位置，不同的是georadius给出的是具体的经纬度，georadiusbymember 只需要给出成员即可。

其中`radiusm|km|ft|mi`是必须参数，指定了半径（带单位），这两个命令有很多可选参数，如下所示：

- withcoord：返回结果中包含经纬度
- withdist：返回结果中包含离中心节点位置的距离
- withhash：返回结果中包含geohash
- COUNT count：指定返回结果的数量
- asc|desc：返回结果按照离中心节点的距离做升序或降序。
- store key：将返回结果的地理位置信息保存到指定键
- storedist key：将返回结果里中心节点的距离保存到指定键

