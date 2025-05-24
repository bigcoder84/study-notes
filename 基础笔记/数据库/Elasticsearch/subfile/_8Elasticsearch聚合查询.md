# Elasticsearch聚合查询

## 一. 概述

Elasticsearch除搜索以外，提供了针对ES 数据进行统计分析的功能。[聚合(aggregations)](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html)可以让我们极其方便的实现对数据的统计、分析、运算。例如：

- 什么品牌的手机最受欢迎？

- 这些手机的平均价格、最高价格、最低价格？
- 这些手机每月的销售情况如何？

### 1.1 聚合的基本语法

聚合查询的语法结构与其他查询相似，通常包含以下部分：

1. **查询条件**：指定需要聚合的文档，可使用标准的 Elasticsearch 查询语法，如 `term`、`match`、`range` 等。
2. **聚合函数**：指定要执行的聚合操作，如 `sum`、`avg`、`min`、`max`、`terms`、`date_histogram` 等，每个聚合命令都会生成一个聚合结果。
3. **聚合嵌套**：聚合命令可以嵌套，以便更细粒度地分析数据。

```json
GET <index_name>/_search
{
  "aggs": {
    "<aggs_name>": { // 聚合名称需要自己定义
      "<agg_type>": {
        "field": "<field_name>"
      }
    }
  }
}
```

字段说明：

| 字段名       | 说明                                                         |
| ------------ | ------------------------------------------------------------ |
| `aggs_name`  | 聚合函数的名称，需自定义。                                   |
| `agg_type`   | 聚合种类，如桶聚合（`terms`）、指标聚合（`avg`、`sum`、`min`、`max` 等）。 |
| `field_name` | 参与聚合的字段名称（域名）。                                 |

### 1.2 聚合分类

- Metric Aggregation（指标聚合）：一些数学运算，可以对文档字段进行统计分析，类比 MySQL 中的 `min()`、`max()`、`sum()` 操作。

```json
# SELECT MIN(price), MAX(price) FROM products
# Metric聚合的DSL类比实现
GET products/_search
{
  "aggs": {
    "min_price": {
      "min": {
        "field": "price"
      }
    },
    "max_price": {
      "max": {
        "field": "price"
      }
    }
  }
}
```

- Bucket Aggregation： 一些满足特定条件的文档的集合放置到一个桶里，每一个桶关联一个key，类比 `MySQL` 中的 `group by` 操作。

```json
# SELECT COUNT(*) FROM products GROUP BY category 
# Metric聚合的DSL类比实现 
GET products/_search
{
  "size": 0,
  "aggs": {
    "by_category": {
      "terms": {
        "field": "category.keyword"
      }
    }
  }
}
```

- Pipeline Aggregation：对其他的聚合结果进行二次聚合。

## 二. 指标聚合

**作用**：对数值型字段进行统计计算，输出单个或多个指标结果（如平均值、总和、最大值、最小值等）。
**核心功能**：

1. 基础统计指标
   - **`avg`**：计算平均值（如商品价格的平均值）。
   - **`sum`**：计算总和（如订单金额的总和）。
   - **`min/max`**：获取最小值 / 最大值（如库存的最小值、用户年龄的最大值）。
   - **`value_count`**：统计非空值的数量（如有效订单的数量）。
   - **`cardinality`**：计算去重后的唯一值数量（如统计活跃用户数）。
2. 高级统计指标
   - **`percentile`**：计算百分位数（如响应时间的 95% 分位数）。
   - **`extended_stats`**：返回扩展统计信息（包括方差、标准差等）。
   - **`histogram`**：对数值型数据进行直方图分组统计（需指定间隔）。
   - **`date_histogram`**：对日期型数据按时间间隔分组统计（如按天统计日志量）。

### 2.1 数据准备

