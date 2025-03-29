# 文档管理

ElasticSearch的数据交互接口是基于HTTP协议实现的，基本格式如下：

```
http://localhost:9200/{index}/{type}/{id} 
```

- **index：索引名称，可以类比关系型数据库的表**
- **type：类型名称，需要注意的是，在7.x之后，去掉了type属性，默认用“_doc”，8.x不再支持在请求中指定类型**
- **id：即id，可以不指定，elasticSearch会自动生成**
- **文档：即对象的json序列化**
- ***元数据：即elasticSearch的数据格式，一般如下，”_source”对应的数据即为我们存储的文档\***

## 一. 插入文档

```bash
POST /{index_name}/_doc/{id}
{
   ...
}
```

- index_name：索引名称
- id：文档ID，该参数非必填。如果未填写ID则会新增文档，并自动生成ID。指定ID后，如果文档存在，则会更新；若不存在，则新增。

新增文档，不指定ID：

![](../images/6.png)

新增文档，指定ID：

![](../images/7.png)

## 二. 更新文档

```bash
PUT /{index_name}/_doc/{id}
{
   ...
}
```

- index_name：索引名称
- id：文档ID，必填。

## 三. 删除文档

## 

```bash
DELETE /{index_name}/_doc/{id}
```

- index_name：索引名称
- id：文档ID，必填。

![](../images/8.png)

## 四. 查询文档



