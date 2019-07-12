## Redis常用数据类型

- 字符串

  ```shell
  set key "value"  #增
  get key          #查
  del key          #删
  incr key         #自增1（increment）将指定的key的value原子性的递增1.如果该key不存在，其初始值为0，在incr之后其值为1。如果value的值不能转成整型，如hello，该操作将执行失败并返回相应的错误信息。
  incrby key n     #自增N
  decr key         #自减1
  decrby key n     #自减N
  ```

- hash

  ```shell
  hset key filed value #添加元素
  hget key filed       #获取元素
  hdel key filed1 [filed2...]  #删除元素
  del key   #删除整个Hash表
  ```

- 列表（List）

  ```shell
  lpush key value1 value2... #在指定的key所关联的list的头部插入所有的values，如果该key不存在，该命令在插入的之前创建一个与该key关联的空链表，之后再向该链表的头部（左边）插入数据。插入成功，返回元素的个数。
  rpush key value1、value2…  #在尾部添加元素
  
  ```

- 集合（Set）

- 有序集合（Sorted Set）