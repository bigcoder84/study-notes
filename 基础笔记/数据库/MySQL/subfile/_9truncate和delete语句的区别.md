# truncate和delete语句的区别

使用delete语句删除数据的一般语法格式：

```sql
delete from table_name [where condition]
```

使用truncate删除表中数据：

```sql
truncate table table_name
```

- truncate语句将删除表中的所有数据，且无法恢复，因此使用时必须十分小心。
- delete语句是DML,这个操作会放到rollback segement中,事务提交之后才生效;如果有相应的trigger,执行的时候将被触发。truncate是DDL, 操作立即生效,原数据不放到rollback segment中,不能回滚. 操作不触发trigger. 

- delete语句不影响表所占用的extent, 高水线(high watermark)保持原位置不动，显然drop语句将表所占用的空间全部释放 。

  