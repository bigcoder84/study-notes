# Solr查询字段为空的数据

### 字符串类型

可以通过下面这种查询方式找到所有`描述description`为空的数据。

```
-description:* OR description:""
```

### 整数类型

可以通过下面这种查询方式找到所有`页码page`为空的数据。

```
-page:* OR page:0
```

### 查询`fileld > 10 OR filed is null`语义

```shell
((*:* -filed :*) OR (filed:[* TO 10]))
```



