# truncate和delete语句的区别

使用delete语句删除数据的一般语法格式：

```sql
delete from table_name [where condition]
```

使用truncate删除表中数据：

```sql
truncate table table_name
```

- truncate是DDL语句，delete是DML语句。truncate在事务中不能回滚，而delete可以。

- truncate会清空表的自增ID属性（从1开始），而delete不会清空。

  