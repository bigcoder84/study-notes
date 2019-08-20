# 详解MySQL中日期的查询

假如我们有一张User表，它有如下三个字段：

![](../images/9.png)

我们先使用SQL语句插入数据：

```mysql
insert into user values(1,'A','1998-12-5');
insert into user values(2,'B','1988-6-5 13:5:5');
insert into user values(3,'C','1998-12-23 15:32:01');
insert into user values(4,'D','1991-4-25');
insert into user values(5,'E','1998-12-5 08:59:36');
```

## 查找具体时间

如果我们需要查找一个具体时间点的数据可以这样做：

```sql
select * from date_test where birthday = '1998-12-5 08:59:36'
```

## 查找某一天的数据

如果我们需要查找一个具体时间的记录可以这样：

```sql
select * from date_test where birthsday = '1998-12-5'
```

但事实这样查询只能查询到'1998-12-5 00:00:00'日期的记录，如果我们需要查询那一天的日期怎么进行呢？我们需要借助Date()函数返回日期的一部分进行判断：

```sql
select * from date_test where Date(birthday) = '1998-12-5'
```

## 查找某段时间内的数据

**查询1998年12月出生的用户**，我们指出上下界即可：

```sql
select * from date_test where Date(birthday) between '1998-12-1' and '1998-12-31'
```

**注意**：Date函数是必须的，如果忘了结果就是错误的，上界默认是'1998-12-01 00:00:00'没有什么问题，但是下界是'1998-12-31 00:00:00'就有问题了，31号这一天根本没有算进去。

你还可以这样写：

```sql
select * from date_test where Year(birthday)=1998 and Month(birthday)=12
```

**查找在'1998-01-01'之后的数据**：

```sql
select * from date_test where birthday >= '1998-01-01' 
```

**查找最近30天的数据**：

```sql
select * from date_test where TO_DAYS(now())-TO_DAYS(birthday) <= 30
```

TO_DAYS()函数日期从0000年开始的天数，now()返回当前的时间。

**查询昨天的数据**：

```sql
select * from date_test where TO_DAYS(now())-TO_DAYS(birthday) = 1
```



## 日期计算函数

### Now()函数

返回当前时间

```sql
select now()  # 1998-08-20 16:50:58
```



### DayOfWeek()函数

DayOfWeek函数返回日期的星期索引(1=星期天，2=星期一, ……7=星期六)

```sql
select DAYOFWEEK(now())  
```

### DayOfMonth()函数

返回日期是对应月的第几天

```sql
select DAYOFMONTH(now())
```

### DayOfYear()函数

返回date在一年中的日数, 在1到366范围内。

```sql
select DAYOFYEAR(now())
```

### Date()函数

返回dete对应的日期（date可能是包括具体的时间，而我们只需要对日期进行等性运算时使用）

```sql
select DATE(now())
```

### Month()函数

返回date的月份（1到12）。

```sql
select MONTH(now())
```

### Quarter() 函数

返回date的记录，范围1到4

```sql
select quarter(now())
```

### Year()函数

返回date的年份

```sql
select Year(now())
```

### TO_DAYS()函数（非常重要）

返回'0000'年开始到date的天数

```sql
select TO_DAYS('0000-01-01') #返回1
```



