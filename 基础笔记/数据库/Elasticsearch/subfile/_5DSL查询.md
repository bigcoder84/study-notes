# DSL查询

Elasticsearch Query DSL（Domain Specific Language）是一种基于 JSON 的声明式查询语言，专为复杂搜索场景设计。初次接触 Elasticsearch 的查询语法可能会以让你觉得混乱，本质上是因为它采用了**分层嵌套结构**的设计，同时遵循了**组合模式（Composite Pattern）**的理念。这种设计允许查询语句以灵活的方式组合，但也会让初次接触的人感到层次复杂。

Elasticsearch 的查询语法遵循一个原则：**任何查询条件都可以嵌套在其他查询中**。无论是简单的 `term` 查询还是复杂的 `bool` 查询，它们都被视为可组合的原子单位。这种设计使得语法具有极高的灵活性，但也带来了嵌套层次的问题。

Elasticsearch 的查询可以看作一棵树，树的每个节点可以是两种类型：

1. **叶子查询（Leaf Query）**：如 `term`、`match`、`range`，**直接对字段进行操作，不可再嵌套其他查询**。
2. **复合查询（Compound Query）**：如 `bool`、`dis_max`，用于组合多个子查询（叶子或复合），形成逻辑条件。

## 一. 叶子查询

### 1.1 精确查询

下列查询用于精确匹配字段的 **未经分词** 的原始值（通常针对 `keyword` 类型或数值类型字段）。

#### 1.1.1 `term` 查询

**用途**：精确匹配 `keyword` 类型字段的值。
​**​示例​**​：查询 `city.keyword` 为 `"Millville"` 的账户。

```json
GET /{index_name}/_search
{
  "query": {
    "term": {
      "city.keyword": "Hobucken"
    }
  }
}
```

city字段类型是 `text`，Elasticsearch定义一个 `text` 类型的字段（比如 `city`），Elasticsearch 会默认做两件事：

1. **分词处理**：将原始值拆分成词项（如 `"New York"` → `["new", "york"]`），用于全文搜索。

2. **自动生成子字段 `keyword`**：将原始值完整存储为 `keyword` 类型，用于精确匹配（如过滤、排序、聚合）。

   ![](../images/29.png)

此次查询是使用term精确查询，所以我们可以借助 `city` 的 `keyword` 子字段进行精确匹配：

![](../images/28.png)

#### 1.1.2 `terms` 查询

**用途**：匹配 `keyword` 字段的多个精确值。
​**​示例​**​：查询 `state.keyword` 是 `"WA"` 或 `"TX"` 的账户。

```json
GET /{index_name}/_search
{
  "query": {
    "terms": {
      "state.keyword": ["WA", "TX"]
    }
  }
}
```

#### 1.1.3 `range` 查询

**用途**：匹配数值或日期的范围。
​**​示例​**​：查询年龄在 `[30, 40]` 之间的账户。

```json
GET /{index_name}/_search
{
  "query": {
    "range": {
      "age": {
        "gte": 30,
        "lte": 40
      }
    }
  }
}
```

#### 1.1.4 `exists` 查询

**用途**：检查字段是否存在。
​**​示例​**​：查询 `address.keyword` 字段存在的账户。

```json
GET /{index_name}/_search
{
  "query": {
    "exists": {
      "field": "address.keyword"
    }
  }
}
```

#### 1.1.5 `prefix` 查询

**用途**：匹配字段值的前缀。
​**​示例​**​：查询 `address.keyword` 以 `"990"` 开头的账户。

```json
GET /{index_name}/_search
{
  "query": {
    "prefix": {
      "address.keyword": "990"
    }
  }
}
```

#### 1.1.6 `wildcard` 查询

**用途**：通配符匹配（`*` 多字符，`?` 单字符）。
​**​示例​**​：查询 `email.keyword` 匹配 `"*@gmail.com"` 的账户。

```json
GET /{index_name}/_search
{
  "query": {
    "wildcard": {
      "email.keyword": "*@gmail.com"
    }
  }
}
```

#### 1.1.7 `regexp` 查询

**用途**：正则表达式匹配。
​**​示例​**​：查询 `state.keyword` 以 `"C"` 开头且长度为 2 的账户。

```json
GET /{index_name}/_search
{
  "query": {
    "regexp": {
      "state.keyword": "C.{1}"
    }
  }
}
```

#### 1.1.8 `fuzzy` 查询

**用途**：容忍拼写错误的模糊匹配。
​**​示例​**​：模糊匹配 `employer.keyword` 为 `"Googlo"`（可能匹配 `"Google"`）。

```json
GET /{index_name}/_search
{
  "query": {
    "fuzzy": {
      "employer.keyword": {
        "value": "Googlo",
        "fuzziness": "AUTO"
      }
    }
  }
}
```

#### 1.1.9 `ids` 查询

**用途**：通过文档 ID 查询。
​**​示例​**​：查询 ID 为 `1` 和 `2` 的账户。

```json
GET /{index_name}/_search
{
  "query": {
    "ids": {
      "values": ["1", "2"]
    }
  }
}
```

### 1.2 全文检索查询（Full-Text）

#### 1.2.1 `match_all` 查询

`match_all`表示查询所有的数据，`sort`即按照什么字段排序

```bash
GET /{index_name}/_search
{
  "query": {
    "match_all": {}
  },
  "sort": [
    {
      "account_number": "asc"
    }
  ]
}
```

![](../images/21.png)

相关字段解释

- `took`：Elasticsearch运行查询所花费的时间（以毫秒为单位）
- `timed_out`：搜索请求是否超时
- `_shards`：搜索了多少个分片，以及成功，失败或跳过了多少个碎片的细目分类。
- `max_score`：找到的最相关文档的分数
- `hits.total.value`：找到了多少个匹配的文档
- `hits.sort`：文档的排序位置（不按相关性得分排序时）
- `hits._score`：文档的相关性得分（使用match_all时不适用）

#### 1.2.2 `match` 查询

**用途**：对 `text` 类型字段分词后匹配任意分词。
​**​示例​**​：在 `address` 字段中搜索包含 `"Avenue"` 或 `"Street"` 的账户。

```json
GET /{index_name}/_search
{
  "query": {
    "match": {
      "address": "Avenue Street"
    }
  }
}
```

#### 1.2.3 `match_phrase` 查询

**用途**：匹配完整短语（分词顺序一致）。
​**​示例​**​：在 `address` 字段中搜索 `"959 National Avenue"`。

```json
GET /{index_name}/_search
{
  "query": {
    "match_phrase": {
      "address": "959 National Avenue"
    }
  }
}
```

#### 1.2.4 `match_phrase_prefix` 查询

**用途**：匹配短语前缀。
​**​示例​**​：在 `address` 字段中搜索以 `"990"` 开头的短语。

```json
GET /{index_name}/_search
{
  "query": {
    "match_phrase_prefix": {
      "address": "990"
    }
  }
}
```

#### 1.2.5 `common` 查询

**用途**：优化高频词（如停用词）的匹配。
​**​示例​**​：在 `address` 字段中搜索 `"Avenue and the Street"`，优先低频词。

```json
GET /{index_name}/_search
{
  "query": {
    "common": {
      "address": {
        "query": "Avenue and the Street",
        "cutoff_frequency": 0.001
      }
    }
  }
}
```

## 二. 复合查询

### 2.1 bool

布尔查询是最常用的组合查询，不仅将多个查询条件组合在一起，并且将查询的结果和结果的评分组合在一起。当查询条件是多个表达式的组合时，布尔查询非常有用，实际上，布尔查询把多个子查询组合（combine）成一个布尔表达式，所有子查询之间的逻辑关系是与（and）；只有当一个文档满足布尔查询中的所有子查询条件时，Elasticsearch 引擎才认为该文档满足查询条件。

布尔查询支持的子查询类型共有四种，分别是：`must`，`should`，`must_not` 和 `filter`：

- `must`：指定**必须满足**的条件（类似 SQL 中的 `AND`），文档必须同时满足所有 `must` 子句才能被匹配。**贡献算分**
- `must_not`：指定**必须不满足**的条件（类似 SQL 中的 `NOT`），匹配该条件的文档会被直接排除。
- `filter`： 与 `must` 类似，指定**必须满足**的条件，但**不计算相关性得分**，仅用于过滤文档。
- `should`： 指定**可选满足**的条件（类似 SQL 中的 `OR`），文档满足其中一个或多个子句会提升相关性得分，但非必需。**满足的子句越多，文档得分越高**；若未满足任何子句，文档仍可能被匹配（除非 `minimum_should_match` 强制要求）。

| 字段       | 条件类型               | 是否必须匹配                             | 影响得分 | 性能优化                       |
| ---------- | ---------------------- | ---------------------------------------- | -------- | ------------------------------ |
| `must`     | 必须满足               | 是                                       | 是       | 无（需计算得分）               |
| `filter`   | 必须满足               | 是                                       | 否       | 有（缓存结果，适合结构化数据） |
| `must_not` | 必须不满足             | 是（排除）                               | 是       | 部分优化（排除逻辑简单）       |
| `should`   | 可选满足（提升相关性） | 否（可通过 `minimum_should_match` 强制） | 是       | 无（需计算得分）               |

`bool` 查询语法有以下特点

- 子查询可以任意顺序出现
- 可以嵌套多个查询，包括 `bool` 查询
- 如果 `bool` 查询中没有 `must` 条件，`should` 中必须至少满足一条才会返回结果。

**示例**：查询年龄大于 30、城市是 `"Brogan"`，且不来自 `"EmployerA"` 的账户。

```json
GET /{index_name}/_search
{
  "query": {
    "bool": {
      "must": [
        { "range": { "age": { "gt": 30 } } },
        { "term": { "city.keyword": "Brogan" } }
      ],
      "must_not": [
        { "term": { "employer.keyword": "EmployerA" } }
      ],
      "filter": [
        { "range": { "balance": { "gte": 5000 } } }
      ]
    }
  }
}
```

![](../images/30.png)

### 2.2 dis_max

**用途**：取多个子查询中的最高分。
​**​示例​**​：在 `address` 或 `employer` 字段中搜索 `"Avenue"`。

```json
GET /{index_name}/_search
{
  "query": {
    "dis_max": {
      "queries": [
        { "match": { "address": "Avenue" } },
        { "match": { "employer": "Avenue" } }
      ],
      "tie_breaker": 0.3
    }
  }
}
```

### 2.3 function_score

**用途**：自定义评分规则。
​**​示例​**​：搜索 `"Avenue"`，并为 `gender.keyword` 为 `"F"` 的账户增加权重。

```json
GET /{index_name}/_search
{
  "query": {
    "function_score": {
      "query": { "match": { "address": "Avenue" } },
      "functions": [
        {
          "filter": { "term": { "gender.keyword": "F" } },
          "weight": 2
        }
      ],
      "boost_mode": "multiply"
    }
  }
}
```

### 2.4 boosting

**用途**：对某些条件的结果降权。
​**​示例​**​：搜索 `"Avenue"`，但降低来自 `"EmployerB"` 的账户的得分。

```json
GET /{index_name}/_search
{
  "query": {
    "boosting": {
      "positive": { "match": { "address": "Avenue" } },
      "negative": { "term": { "employer.keyword": "EmployerB" } },
      "negative_boost": 0.2
    }
  }
}
```

## 三. 分页查询

本质上就是from和size两个字段

```bash
GET /{index_name}/_search
{
  "query": {
    "match_all": {}
  },
  "sort": [
    {
      "account_number": "asc"
    }
  ],
  "from": 2,
  "size": 5
}
```

在 Elasticsearch 的查询请求中，`from` 和 `size` 这两个参数主要用于实现分页功能。下面为你详细解释这两个参数在你给出的查询中的作用：

- `from` 参数明确了查询结果起始的偏移量，也就是跳过前 `from` 条数据，从第 `from+1` 条结果开始返回。**它的默认值是 0，跳过前0条数据，从第1条结果返回**。在你的查询里，`from` 的值设定为 2，这表明 Elasticsearch 会跳过前 2 条结果，从第 3 条结果开始返回。

- `size` 参数指定了查询结果返回的最大文档数量。**它的默认值为 10，即默认返回 10 条结果**。在你的查询中，`size` 的值为 5，这就表示 Elasticsearch 只会返回至多 5 条结果。





