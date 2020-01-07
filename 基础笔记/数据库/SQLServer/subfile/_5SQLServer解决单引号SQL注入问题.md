# SQL Server解决单引号SQL注入问题

在SQL Server中如果插入的字符串中如果包含单引号，会导致SQL注入，我们可以通过转义（两个单引号）的方式来插入单引号

```sql
insert into xxx values(123,'x''xxx')  -- 我们想插入 x'xxx
```

