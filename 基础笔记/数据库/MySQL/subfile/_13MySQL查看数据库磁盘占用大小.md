# MySQL查看数据库磁盘占用大小

```sql
SELECT table_schema as `Database`, table_name AS `Table`, round(((data_length + index_length) / 1024 / 1024 / 1024), 2) `Size in GB` FROM information_schema.TABLES where table_schema = 'test_order' ORDER BY (data_length + index_length) DESC ;
```

