# MySQL InnoDB Online DDL

> 本文转载至：
>
> [MySQL InnoDB Online DDL学习 - H_Johnny - 博客园 (cnblogs.com)](https://www.cnblogs.com/dbabd/p/10381942.html#_label02)
>
> [MySQL ：： MySQL 5.7 参考手册 ：： 14.13 InnoDB 和在线 DDL](https://dev.mysql.com/doc/refman/5.7/en/innodb-online-ddl.html)

MySQL Online DDL这个新特性是在**MySQL5.6.7**开始支持的，更早期版本的MySQL进行DDL对于DBA来说是非常痛苦的。现在主流版本都集中在5.6与5.7，为了更好的理解Online DDL的工作原理与机制，本文就对Online DDL的实现方式进行总结。

本文使用的MySQL版本为官方社区版 `5.7.24`。

```
(root@localhost) [test] > select version();
+------------+
| version()  |
+------------+
| 5.7.24-log |
+------------+
1 row in set (0.00 sec)
```

## 一. 主要说明

Online DDL这个新特性解决了早期版本MySQL进行DDL操作同时带来锁表的问题，在DDL执行的过程当中依然可以保证读写状态，不影响数据库对外提供服务，大大提高了数据库和表维护的效率。

- **早期实现方式(MySQL5.6.7之前版本)**

早期版本MySQL执行DDL语句时主要通过以下方式进行：

**COPY方式：**

这是InnoDB最早期支持的方式，主要实现步骤：

1. 创建与原表结构定义一致的临时表；
2. 对原表加锁，不允许执行DML，但允许查询；
3. 在临时表上执行DDL语句；
4. 逐行拷贝原表数据到临时表；
5. 原表与临时表进行RENAME操作，此时会升级原表上的锁，不允许读写，直至完成DDL操作；

**INPLACE方式：**

INPLACE方式也称为InnoDB fast index creation，是MySQL5.5及之后版本为了提高创建二级索引效率的方式，所以INPLACE方式仅限于二级索引的创建跟删除，关于fast index creation可以参考官方文档：[**InnoDB fast index creation**](https://dev.mysql.com/doc/refman/5.5/en/innodb-create-index.html)，主要实现步骤：

1. 创建临时的frm文件；
2. 对原表加锁，不允许执行DML，但允许查询；
3. 根据聚集索引的顺序，构造新的索引项，按照顺序插入新索引页；
4. 升级原表上的锁，不允许读写操作；
5. 进行RENAME操作，替换原表的frm文件，完成DDL操作。

相对于COPY方式，INPLACE方式在原表上进行，不会生成临时表，也不会拷贝原表数据，减少了很多系统I/O资源占用，但还是无法进行DML操作，也只适用于索引的创建与删除，并不适用于其他类型的DDL语句。

- **当前实现方式(MySQL5.6.7及之后版本)**

在MySQL5.6.7及之后版本中推出了新的特性：

**Online DDL方式：**
Online DDL特性是基于MySQL5.5的*InnoDB fast index creation*上改进增强的。Online DDL同样包含两种方式：

> 1. COPY方式；
> 2. INPLACE方式。

其中，某些DDL语句不支持Online DDL的就采用COPY方式，支持Online DDL的则采用INPLACE方式，因为Online DDL是对早期INPLACE方式的增加，所以INPLACE方式根据是否涉及到记录格式的修改又分为如下两种情形：

> 1. Rebuilds Table；
> 2. No-Rebuilds Table。

Rebuilds Table操作是因为DDL有涉及到行记录格格式的修改，如字段的增、删、类型修改等；

No-Rebuilds Table则不涉及行记录格式的修改，如索引删除、字段名修改等。

## 二. Online DDL选项

- **ALGORITHM={COPY|INPLACE}**
  指定DDL执行时对表的操作方式。首选是INPLACE，但并非所有的语句都支持INPLACE，需要根据DDL语句类型决定。
- **LOCK={NONE|SHARED|DEFAULT|EXCLUSIVE}**
  指定DDL执行时对表锁定方式。默认情况下MySQL在表执行DDL时会尽量使用最少的锁定，LOCK选项可以为DDL语句指定执行更为严格的锁定方式，一旦指定的锁级别低于DDL语句执行所需的锁级别，则DDL语句会执行失败。
  - NONE：允许并发查询和DML操作；
  - SHARED：允许并发查询，但不允许DML操作；
  - DEFAULT：允许尽可能多的并发查询或DML操作(或两者都允许)，没指定LOCK选项默认就为DEFAULT；
  - EXCLUSIVE：不允许并发查询和DML操作。

## 三. Online DDL类型

根据官方文档[**Online DDL Operations**](https://dev.mysql.com/doc/refman/5.7/en/innodb-online-ddl-operations.html)的描述，结合常见的表DDL执行语句，MySQL5.7支持的Online DDL操作类型主要有以下种类：

> 1. 索引操作
> 2. 字段操作
> 3. 组合字段操作
> 4. 主键操作
> 5. 外键操作
> 6. 表操作
> 7. 表分区操作
> 8. 表空间操作

### 3.1 索引操作

Online DDL 对索引操作的支持情况如下表所示：

| 操作(Operation)  | 原表操作(In Place) | 重建表操作(Rebuilds Table) | 允许并发DML操作(Permits Concurrent DML) | 仅修改元数据(Only Modifies Metadata) |
| :--------------: | :----------------: | -------------------------- | --------------------------------------- | ------------------------------------ |
| 创建添加二级索引 |        YES         | NO                         | YES                                     | NO                                   |
|    重命名索引    |        YES         | NO                         | YES                                     | YES                                  |
|     删除索引     |        YES         | NO                         | YES                                     | YES                                  |
|   创建全文索引   |        YES         | NO                         | NO                                      | NO                                   |
|   创建空间索引   |        YES         | NO                         | NO                                      | NO                                   |
|   修改索引类别   |        YES         | NO                         | YES                                     | YES                                  |

由以上表格可以看出涉及索引的DDL操作都可以使用INPLACE方式来完成，除了创建全文索引与空间索引之外都允许DML操作，并不会锁表。

```sql
-- 创建添加二级索引
create index index_name on table_name (column[,column]..);
或
alter table table_name add index index_name (column[,column]..);

-- 删除索引
drop index index_name on table_name;
或
alter table table_name drop index index_name;

-- 重命名索引
alter table table_name rename index old_index_name to new_index_name, algorithm=inplace, lock=none;

-- 创建全文索引
create fulltext index index_name on table_name(column[,column]..);

-- 创建空间索引
create table geom (g geometry not null);
alter table geom add spatial index(g), algorithm=inplace, lock=none;

-- 修改索引类型
alter table table_name drop index index_name, add index index_name(column[,column]..) using btree, algorithm=inplace;
```

### 3.2 字段操作

Online DDL 对字段操作支持情况如下表所示：

|       操作(Operation)       | 原表操作(In Place) | 重建表操作(Rebuilds Table) | 允许并发DML操作(Permits Concurrent DML) | 仅修改元数据(Only Modifies Metadata) |
| :-------------------------: | :----------------: | -------------------------- | --------------------------------------- | ------------------------------------ |
|          添加字段           |        YES         | YES                        | YES                                     | NO                                   |
|          删除字段           |        YES         | YES                        | YES                                     | NO                                   |
|         重命名字段          |        YES         | NO                         | YES                                     | YES                                  |
|         重排序字段          |        YES         | YES                        | YES                                     | NO                                   |
|       字段指定默认值        |        YES         | NO                         | YES                                     | YES                                  |
|        字段修改类型         |         NO         | YES                        | NO                                      | NO                                   |
|     扩展VARCHAR字段大小     |        YES         | NO                         | YES                                     | YES                                  |
|       删除字段默认值        |        YES         | NO                         | YES                                     | YES                                  |
|         修改自增值          |        YES         | NO                         | YES                                     | NO                                   |
|        字段指定NULL         |        YES         | YES                        | YES                                     | NO                                   |
|      字段指定NOT NULL       |        YES         | YES                        | YES                                     | NO                                   |
| 修改枚举(ENUM OR SET)定义值 |        YES         | NO                         | YES                                     | YES                                  |

从以上表格可以看出，除了修改字段类型的DDL语句无法使用INPLACE方式和需要锁表外，其他都可以使用到INPLACE方式执行DDL语句，并且在DDL执行过程中依然可以执行DML。

```sql
-- 添加字段，如果添加的是自增列，还是不允许DML操作
alter table table_name add column column_name column_definition, algorithm=inplace, lock=none;

-- 删除字段
alter table table_name drop column column_name, algorithm=inplace, lock=none;

-- 重命名字段
/*
为了允许并发DML操作，需保持重命名后字段类型一致，只修改字段名；
如果重命名的字段在外键定义中，外键定义也会自动更新为新字段名。
*/
alter table table_name change old_column_name new_column_name data_type, algorithm=inplace, lock=none;

-- 重排序字段，使用first或after
after table table_name modify column column_name column_definition first, algorithm=inplace, lock=none;

-- 字段修改类型，只支持COPY方式
alter table table_name change column column column_definition, algorithm=copy;

-- 扩展VARCHAR字段大小
/*
当varchar字节长度为0~255时，需要额外一个字节进行编码；
当varchar字节长度大于255时，则需要额外两个字节进行编码；
当varchar字节长度在0~255之间时，并且需从小变大的情况，支持INPLACE方式；
当varchar字节长度字节编码数从1变为2或者从2变为1时，则需要用COPY方式。
*/
alter table table_name change column column column_definition, algorithm=inplace, lock=none;
-- 例表：
t(c1 varchar(20))
alter table t change c1 c1 varchar(85), algorithm=inplace, lock=none;
alter table t change c1 c1 varchar(10), algorithm=copy;
alter table t change c1 c1 varchar(100), algorithm=copy;

-- 字段指定默认值
alter table table_name alter column column_name set default literal, algorithm=inplace, lock=none;

-- 删除字段默认值
alter table table_name alter column column_name drop default, algorithm=inplace, lock=none;

-- 修改自增列值
alter table table_name auto_increment=next_value, algorithm=inplace, lock=none;

-- 字段指定NULL
alter table table_name modify column column_name data_type NULL, algorithm=inplace, lock=none;

-- 字段指定NOT NULL
-- sql_mode中需包含选项STRICT_TRANS_TABLES和STRICT_ALL_TABLES才能使用INPLACE，否则需使用COPY
alter table table_name modify column column_name data_type NOT NULL, algorithm=inplace, lock=none;

-- 修改枚举(ENUM OR SET)定义值
-- 例表：
t (c2 enum('a','b','c'))
alter table t modify column c2 enum('a','b','c','d'), algorithm=inplace, lock=none;

```

### 3.3 组合字段操作

组合字段操作类型如下表所示：

|        操作(Operation)        | 原表操作(In Place) | 重建表操作(Rebuilds Table) | 允许并发DML操作(Permits Concurrent DML) | 仅修改元数据(Only Modifies Metadata) |
| :---------------------------: | :----------------: | -------------------------- | --------------------------------------- | ------------------------------------ |
|   添加存储(STORED)组合字段    |         NO         | YES                        | NO                                      | NO                                   |
|   删除存储(STORED)组合字段    |        YES         | YES                        | YES                                     | NO                                   |
| 修改存储(STORED)组合字段顺序  |         NO         | YES                        | NO                                      | NO                                   |
|   添加虚拟(VIRTUAL)组合字段   |        YES         | NO                         | YES                                     | YES                                  |
|   删除虚拟(VIRTUAL)组合字段   |        YES         | NO                         | YES                                     | YES                                  |
| 修改虚拟(VIRTUAL)组合字段顺序 |         NO         | YES                        | NO                                      | NO                                   |

```sql
-- 例表：
t (c1 int,c2 varchar(20))
-- 添加存储组合字段
alter table t add column (c3 int generated always as (c1 + 2) stored), algorithm=copy;

-- 删除存储组合字段
alter table t drop column c3, algorithm=inplace, lock=none;

-- 修改存储组合字段顺序
alter table t modify column c3 int generated always as (c1 + 1) stored first, algorithm=copy;

-- 添加虚拟组合字段
-- 对于非分区表才可以使用INPLACE方式，不能与其他的alter table语句合并使用
alter table t add column (c3 int generated always as (c1 + 1) virtual), algorithm=inplace, lock=none;

-- 删除虚拟组合字段
-- 对于非分区表才可以使用INPLACE方式，不能与其他的alter table语句合并使用
alter table t drop column c3, algorithm=inplace, lock=none;

-- 修改虚拟组合字段顺序
alter table t modify column c3 int generated always as (c1 + 1) virtual first, algorithm=copy;

```

### 3.4 主键操作

主键操作类型如下表所示：

|   操作(Operation)    | 原表操作(In Place) | 重建表操作(Rebuilds Table) | 允许并发DML操作(Permits Concurrent DML) | 仅修改元数据(Only Modifies Metadata) |
| :------------------: | :----------------: | -------------------------- | --------------------------------------- | ------------------------------------ |
|       添加主键       |        YES         | YES                        | YES                                     | NO                                   |
|       删除主键       |         NO         | YES                        | NO                                      | NO                                   |
| 删除主键并添加新主键 |        YES         | YES                        | YES                                     | NO                                   |

```sql
-- 例表：
t (c1 int,c2 varchar(20))
-- 添加主键
alter table t add primray key (c1),algorithm=inplace, lock=none;

采用INPLACE方式进行表数据重构，如果添加主键涉及字段没有NOT NULL属性时，则无法使用INPLACE方式，只能使用COPY方式。InnoDB表为索引组织表，当涉及到聚集索引的重新构建时需要对表中数据进行拷贝，为了减少性能开销，最好在建表时就指定主键。

因为InnoDB表的特殊性，DDL操作主键一定会涉及到表行数据的拷贝操作，但通过INPLACE方式添加比COPY方式添加主要有如下优势：
1.不需要记录undo和redo日志，记录日志会提升性能开销；
2.二级索引数据行是预先排序的，可以按顺序加载；
3.无需使用到change buffer，因为没有随机数据插入二级索引当中。

-- 删除主键
alter table t drop primary key,algorithm=copy;

-- 删除主键并添加新主键
alter table t drop primary key,add primary key(c1,c2), algorithm=inplace, lock=none;
```

### 3.5 外键操作

外键操作类型如下表所示：

| 操作(Operation) | 原表操作(In Place) | 重建表操作(Rebuilds Table) | 允许并发DML操作(Permits Concurrent DML) | 仅修改元数据(Only Modifies Metadata) |
| :-------------: | :----------------: | -------------------------- | --------------------------------------- | ------------------------------------ |
|    添加外键     |        YES         | NO                         | YES                                     | YES                                  |
|    删除外键     |         NO         | NO                         | YES                                     | YES                                  |

```sql
-- 添加外键
当系统参数foreign_key_checks = 0时，可以使用INPLACE方式，否则，只能使用COPY方式。
alter table t1 add constraint fk_name foreign key index(col1) references t2(col2) referential_actions;

-- 删除外键
alter table t drop foreign key fk_name;
```

### 3.6 表操作

表操作类型如下表所示：

|   操作(Operation)   | 原表操作(In Place) | 重建表操作(Rebuilds Table) | 允许并发DML操作(Permits Concurrent DML) | 仅修改元数据(Only Modifies Metadata) |
| :-----------------: | :----------------: | -------------------------- | --------------------------------------- | ------------------------------------ |
|     修改行格式      |        YES         | YES                        | YES                                     | NO                                   |
|  修改索引键块大小   |        YES         | YES                        | YES                                     | NO                                   |
| 设置永久表统计信息  |        YES         | NO                         | YES                                     | YES                                  |
|     指定字符集      |        YES         | YES                        | NO                                      | NO                                   |
|     转换字符集      |         NO         | YES                        | NO                                      | NO                                   |
|      优化表格       |        YES         | YES                        | YES                                     | NO                                   |
| 使用FORCE选项重建表 |        YES         | YES                        | YES                                     | NO                                   |
|   使用NULL重建表    |        YES         | YES                        | YES                                     | NO                                   |
|      重命名表       |        YES         | NO                         | YES                                     | YES                                  |

```sql
-- 修改行格式
alter table table_name row_format = format, algorithm=inplace, lock=none;

-- 修改索引键块大小
alter table table_name key_block_size = value, algorithm=inplace, lock=none;

-- 设置永久表统计信息选项
alter table table_name stats_persistent = 0, stats_sample_pages = 20, stats_auto_recalc = 1, algorithm=inplace, lock=none;

-- 优化表
-- 如果表中有全文索引，则不能使用INPLACE方式，不能使用algorithm和lock子句。
optimize table table_name;

-- 使用FORCE选项重建表
-- 如果表中有全文索引，则不能使用INPLACE方式。
alter table table_name force, algorithm=inplace, lock=none;

-- 使用NULL重建表
-- 如果表中有全文索引，则不能使用INPLACE方式。
alter table table_name engine = InnoDB, algorithm=inplace, lock=none;

-- 重命名表
alter table table_name rename to new_table_name, algorithm=inplace, lock=none;
```

### 3.7 表分区操作

表分区操作类型如下表所示：

| 分区子句(Partitioning Clause) | 原表操作(In Place) | 允许DML操作(Permits DML) |                         说明(Notes)                          |
| :---------------------------: | :----------------: | :----------------------: | :----------------------------------------------------------: |
|         PARTITION BY          |         NO         |            NO            |              只允许algorithm=copy,lock={default              |
|         ADD PARTITION         |         NO         |            NO            | 只允许algorithm=default,lock=default 执行期间对于已采用RANGE或LIST分区的数据不进行拷贝，对于已采用HASH或LIST分区的数据允许并发查询。在需要拷贝数据时持有共享锁。 |
|        DROP PARTITION         |         NO         |            NO            | 只允许algorithm=default,lock=default 只允许algorithm=default,lock=default 只允许algorithm=default,lock=default 执行期间对于已采用RANGE或LIST分区的数据不进行拷贝。 |
|       DISCARD PARTITION       |         NO         |            NO            |             只允许algorithm=default,lock=default             |
|       IMPORT PARTITION        |         NO         |            NO            |             只允许algorithm=default,lock=default             |
|      TRUNCATE PARTITION       |        YES         |           YES            | 不会对表中现有数据进行拷贝，仅仅删除分区数据行，不会改会表和表分区的定义。 |
|      COALESCE PARTITION       |         NO         |            NO            | 只允许algorithm=default,lock=default 对于已采用HASH或LIST分区的数据允许并发查询。在需要拷贝数据时持有共享锁。 |
|     REORGANIZE PARTITION      |         NO         |            NO            | 只允许algorithm=default,lock=default 对于已采用LINEAR HASH或LIST分区的数据允许并发查询。在从受影响分区拷贝数据时持有MDL锁。 |
|      EXCHANGE PARTITION       |        YES         |           YES            |                                                              |
|       ANALYZE PARTITION       |        YES         |           YES            |                                                              |
|        CHECK PARTITION        |        YES         |           YES            |                                                              |
|      OPTIMIZE PARTITION       |         NO         |            NO            |                 algorithm和lock子句被忽略。                  |
|       REBUILD PARTITION       |         NO         |            NO            | 只允许algorithm=default,lock=default 对于已采用LINEAR HASH或LIST分区的数据允许并发查询。在从受影响分区拷贝数据时持有MDL锁。 |
|       REPAIR PARTITION        |        YES         |           YES            |                                                              |
|      REMOVE PARTITIONING      |         NO         |            NO            |              只允许algorithm=copy,lock={default              |

### 3.8 表空间操作

表空间操作类型如下表所示：

|     操作(Operation)      | 原表操作(In Place) | 重建表操作(Rebuilds Table) | 允许并发DML操作(Permits Concurrent DML) | 仅修改元数据(Only Modifies Metadata) |
| :----------------------: | :----------------: | -------------------------- | --------------------------------------- | ------------------------------------ |
| 开启或禁止独立表空间加密 |         NO         | YES                        | NO                                      | NO                                   |

主要涉及独立表空间加密的Online DDL操作：

```sql
alter table table_name encryption='Y', algorithm=copy;
```

## 四. Online DDL过程

Online DDL主要有PREPARE(准备)、EXECUTE(执行)和COMMIT(提交)三个阶段，如下：

- **PREPARE：**
  - 创建新的临时frm文件；
  - 持有EXCLUSIVE-MDL锁，禁止读写操作；
  - 根据ALTER类型，确定执行方式(copy,Online-Rebuilds,Online-No-Rebuilds)；
  - 更新数据字典的内存对象；
  - 分配row_log对象记录增量(Rebuilds需要)；
  - 生成新的临时ibd文件(Rebuilds需要)。
- **EXECUTE：**
  - 降级EXCLUSIVE-MDL锁，允许读写；
  - 记录执行期间产生的DML增量到row_log中(Rebuilds需要)；
  - 扫描old_table的聚集索引中每一条记录record；
  - 遍历新表的聚集索引和二级索引，逐一处理；
  - 根据record构造对应的索引项；
  - 将构造的索引项插入sort_buffer块中；
  - 将sort_buffer块插入到新的索引中；
  - 将row_log中的记录应用到新临时表中，应用到最后一个block；
- **COMMIT：**
  - 升级到EXECLUSIVE-MDL锁，禁止读写；
  - 重做row_log中最后一部分的增量；
  - 更新InnoDB的数据字典表；
  - 提交事务，写InnoDB redo日志；
  - 修改统计信息；
  - RENAME临时的ibd和frm文件；
  - 执行变更完成。

row_log记录了DDL执行期间产生的DML操作，这保证了变更期间表的并发性，通过以上过程可以看出在EXECUTE(执行)阶段表允许读写操作，操作记录在row_log中，在最后阶段应用到新表当中，保证了数据的完整性。

## 五. Online DDL涉及参数

- **old_alter_table**

|         属性(Property)          |     值(Value)     |
| :-----------------------------: | :---------------: |
| 命令行格式(Command-Line Format) | --old-alter-table |
|  系统变量格式(System Variable)  |  old_alter_table  |
|         作用范围(Scope)         |    全局、会话     |
|        动态参数(Dynamic)        |        是         |
|           类型(Type)            |      布尔型       |
|      默认值(Default Value)      |        OFF        |

指定是否使用早期版本的DDL方式，默认为OFF，为动态参数，可以全局和会话级别修改。指定表DDL的执行过程当中采用COPY方式生成临时表复制数据。

- **innodb_online_alter_log_max_size**

|         属性(Property)          |              值(Value)               |
| :-----------------------------: | :----------------------------------: |
| 命令行格式(Command-Line Format) | --innodb-online-alter-log-max-size=# |
|  系统变量格式(System Variable)  |   innodb_online_alter_log_max_size   |
|         作用范围(Scope)         |                 全局                 |
|        动态参数(Dynamic)        |                  是                  |
|           类型(Type)            |                数值型                |
|      默认值(Default Value)      |              134217728               |
|      最小值(Minimum Value)      |                65536                 |
|      最大值(Maximum Value)      |               2**64-1                |

指定Online DDL执行期间产生临时日志文件的最大大小，单位字节，默认大小为128MB。日志文件记录的是表在DDL期间的数据插入、更新和删除信息(DML操作)，一旦日志文件超过该参数指定值时，DDL执行就会失败并回滚所有未提交的当前DML操作，所以，当执行DDL期间有大量DML操作时可以提高该参数值，但同时也会增加DDL执行完成时应用日志时锁定表的时间。

## 六. Online DDL注意事项

对于线上环境的MySQL来说，任何类型的DDL都要十分谨慎，最好在语句执行之前可以分析下语句所使用的方式以及预估判断下影响的时长，尽量选择在业务访问的低峰期进行操作，主要有以下几点需要注意：

- 空间需求

  - 临时日志文件大小(innodb_online_alter_log_max_size)：当DDL执行过程当中允许并发执行DML操作时的日志大小需求。
  - 临时排序文件大小(tmpdir)：当DDL执行过程中表需要rebuild时临时排序文件是放在tmpdir指定的路径下的，需要保证该路径下的磁盘空间充足。临时排序文件都足够容纳所有二级索引以及聚簇索引的主键列，最终合并到新表或索引后，临时排序文件会被删除。在MySQL5.7.11及之后版本当中新增系统参数**innodb_tmpdir**专门用来指定Online DDL产生排序文件的路径。
  - 临时中间表文件大小：当有些DDL执行过程中表需要rebuild时会在当前表所在路径下产生临时中间表文件，临时中间表文件大小可能需要与原表大小一致，在DDL执行过程当中产生。

- 合并拆分同表的DDL操作

  早期不支持Online DDL时通常将同一张表中的多个DDL合并一起执行，以便减少多次rebuild表带来的性能消耗；
  现在Online DDL特性出现之后，可以通过COPY方式和INPLACE方式来进行分类并合并分组。其中INPLACE方式又可以根据是否rebuild表来进行分组合并，尽量减少DDL对系统的CPU、I/O资源的影响。

- 对于一些大表进行Online DDL并需要重建表的操作

  - 现在还没有机制可以做到暂停Online DDL的操作或者限制Online DDL对服务器CPU、I/O资源的使用；
  - 如果Online DDL执行失败，则回滚有可能会是一项昂贵的操作；
  - 执行时间过长的Online DDL可能会导致主从复制的延迟。因为主库在执行DDL时可能允许DML并发操作，而在从库只能在执行完DDL语句之后再进行应用DML语句操作。