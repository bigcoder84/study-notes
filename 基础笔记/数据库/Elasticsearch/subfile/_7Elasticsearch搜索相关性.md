# Elasticsearch搜索相关性

## 一. 相关性概述

### 1.1 什么是相关性

搜索是用户和搜索引擎的对话，用户关心的是搜索结果的相关性

- 是否可以找到所有相关的内容（召回率）
- 有多少不相关的内容被返回了（精度）
- 文档的打分是否合理

- 结合业务需求，平衡结果排名

相关性是指在搜索引擎中，描述一个文档与查询语句匹配程度的度量标准。这种相关性通过为每个匹配查询条件的文档计算一个相关性评分（_score）来实现，评分越高表示文档与查询语句的匹配程度越高。

如下例子：显而易见，查询JAVA多线程设计模式，文档id为2,3的文档的算分更高。

| 关键词   | 文档 ID     |
| -------- | ----------- |
| JAVA     | 1,2,3       |
| 设计模式 | 1,2,3,4,5,6 |
| 多线程   | 2,3,7,9     |

**Elasticsearch 使用评分算法，根据查询条件与索引文档的匹配程度来确定每个文档的相关性**。同时，为了满足各种特定的业务需求，Elasticsearch 也充分允许用户自定义评分。

在下面示例中，_score 就是 Elasticsearch 检索返回的评分，其值可以衡量每个文档与查询的匹配程 度，即相关性。每个文档都有对应的评分，该得分由正浮点数表示。文档评分越高，则该文档的相关性越高。

### 1.2 计算相关性评分

Elasticsearch使用布尔模型查找匹配文档，并用一个名为“实用评分函数”的公式来计算相关性。这个公式借鉴了 `TF-IDF`（词频-逆向文档频率）和向量空间模型，同时加入了一些现代的新特性，如协调因子、字段长度归一化以及词/查询语句权重提升。

Elasticsearch 5之前的版本，评分机制或者打分模型是基于 `TF-IDF` 实现的。从 Elasticsearch 5之后，默认的打分机制改成了`Okapi BM25`。其中 `BM` 是 `Best Match` 的缩写，25是指经过25次迭代调整之后得出的算法，它是由 `TF-IDF` 机制进化来的。

传统 `TF-IDF` 和 `BM25` 都使用逆向文档频率来区分普通词（不重要）和非普通词（重要），使用词频来衡量某个词在文档中出现的频率。两种机制的逻辑相似：首先，文档里的某个词出现得越频繁，文档与这个词就越相关，得分越高；其次，某个词在集合中所有文档里出现的频次越高，则它的权重越低、得分越低。也就是说，某个词在集合中所有文档里越罕见，其得分越高。

`BM25` 在传统 `TF-IDF` 的基础上增加了几个可调节的参数，使得它在应用上更佳灵活和强大，具有较高的实用性。

#### 1.2.1 `TF-IDF` 评分公式

![](../images/48.png)

- `TF` 是词频(Term Frequency)：检索词在**文档**中出现的频率越高，相关性也越高。

  ```txt
  词频（TF） = 某个词在文档中出现的次数 / 文档的总词数
  ```

- `IDF` 是逆向文本频率(Inverse Document Frequency)：每个检索词在**索引**中出现的频率，频率越高，相关性越低。总文档中有些词比如“是”、“的” 、“在” 在所有文档中出现频率都很高，并不重要，可以减少多个文档中都频繁出现的词的权重。

  ```txt
  逆向文本频率（IDF）= log (语料库的文档总数 / (包含该词的文档数+1))
  ```

- 字段长度归一值（field-length norm)：检索词出现在一个内容短的 title 要比同样的词出现在一个内容长的 content 字段权重更大。

以上三个因素：词频（term frequency）、逆向文本频率（inverse document frequency）和字段长度归一值（field-length norm）——**是在文档被索引时计算并存储的，最后将它们结合在一起计算单个词在特定文档中的权重**。

#### 1.2.2 `BM25` 评分公式

`BM25` 就是对 `TF-IDF` 算法的改进，对于 `TF-IDF` 算法，`TF(t)` 部分的值越大，整个公式返回的值就会越大。

![](../images/49.png)

`BM25` 公式：

![](../images/50.png)

#### 1.2.3 通过 Explain API 查看算分明细

```java
PUT /test_score/_bulk
{
    "index": {
        "_id": 1
    }
}{
    "content": "we use Elasticsearch to power the search"
}{
    "index": {
        "_id": 2
    }
}{
    "content": "we like elasticsearch"
}{
    "index": {
        "_id": 3
    }
}{
    "content": "Thre scoring of documents is caculated by the scoring formula"
}{
    "index": {
        "_id": 4
    }
}{
    "content": "you know,for search"
}
```

第二步：查询数据

```json
GET /test_score/_search
{
    "explain": true,
    "query": {
        "match": {
            "content": "elasticsearch"
        }
    }
}
```

在查询中增加 `explain=true` 选项，我们就可看到Elasticsearch查询解释：
```json
{
    "took": 3, //该查询请求花费的时间，单位是毫秒。这里took: 3意味着查询耗时 3 毫秒。
    "timed_out": false, //查询是否超时。false表明查询未超时。
    "_shards": {
        "total": 1, //参与查询的分片总数，这里是 1。
        "successful": 1, //成功执行查询的分片数量，这里为 1。
        "skipped": 0, //被跳过的分片数量，这里是 0。
        "failed": 0 //查询失败的分片数量，这里是 0。
    },
    "hits": {
        "total": {
            "value": 2, //匹配查询条件的文档总数，这里是 2。
            "relation": "eq" //表示value和实际匹配文档数的关系，eq代表相等。
        },
        "max_score": 0.8713851, //所有匹配文档中的最高得分，这里是 0.8713851。
        "hits": [
            {
                "_shard": "[test_score][0]", //文档所在的分片信息。
                "_node": "Uzem2zI7R2CgvIYzeQ89kw", //文档所在的节点 ID。
                "_index": "test_score", //文档所在的索引名称。
                "_id": "2", //文档的唯一 ID。
                "_score": 0.8713851, //文档的得分，这里是 0.8713851。
                "_source": {
                    "content": "we like elasticsearch" //文档的原始内容。
                },
                "_explanation": { // 算分过程解释
                    "value": 0.8713851,
                    "description": "weight(content:elasticsearch in 1) [PerFieldSimilarity], result of:",
                    "details": [
                        {
                            "value": 0.8713851,
                            "description": "score(freq=1.0), computed as boost * idf * tf from:", // 文档得分的计算公式为：score = boost * idf * tf
                            "details": [
                                {
                                    "value": 2.2,
                                    "description": "boost",
                                    "details": []
                                },
                                {
                                    "value": 0.6931472,
                                    "description": "idf, computed as log(1 + (N - n + 0.5) / (n + 0.5)) from:", //idf计算公式
                                    "details": [
                                        {
                                            "value": 2,
                                            "description": "n, number of documents containing term", //n，包含term的文档数
                                            "details": []
                                        },
                                        {
                                            "value": 4,
                                            "description": "N, total number of documents with field", //N，包含字段的文档总数
                                            "details": []
                                        }
                                    ]
                                },
                                {
                                    "value": 0.5714286,
                                    "description": "tf, computed as freq / (freq + k1 * (1 - b + b * dl / avgdl)) from:", //tf计算公式
                                    "details": [
                                        {
                                            "value": 1,
                                            "description": "freq, occurrences of term within document",
                                            "details": []
                                        },
                                        {
                                            "value": 1.2,
                                            "description": "k1, term saturation parameter", //系数
                                            "details": []
                                        },
                                        {
                                            "value": 0.75,
                                            "description": "b, length normalization parameter",
                                            "details": []
                                        },
                                        {
                                            "value": 3,
                                            "description": "dl, length of field",
                                            "details": []
                                        },
                                        {
                                            "value": 6,
                                            "description": "avgdl, average length of field",
                                            "details": []
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
            }，
            .......
        ]
    }
}
```

我们以 `ID=2` 的文档为例进行分析，从查询解释可以得出：

得分的计算公式为：`score = boost * idf * tf`

1. `boost`

- **含义**：查询时为该字段设置的权重，默认值是 1，这里是 2.2。较高的`boost`值会使包含该词的文档得分更高。
- **示例值**：`value = 2.2`

2. `idf`（逆文档频率）

- **含义**：体现了一个词在整个索引中的稀有程度。词越稀有，`idf`值越高，文档得分也越高。

- 计算公式：

  ```
  idf = log(1 + (N - n + 0.5) / (n + 0.5))
  ```

  - **`n`**：包含该词的文档数量，这里是 2。
  - **`N`**：包含该字段的文档总数，这里是 4。

- **示例计算**：

```python
import math
n = 2
N = 4
idf = math.log(1 + (N - n + 0.5) / (n + 0.5))
print(idf)  
```

计算结果为 0.6931472。

3. `tf`（词频）

- **含义**：表示一个词在文档中出现的频率。不过，为了避免长文档因为词多而得分过高，会进行长度归一化处理。

- 计算公式：

  ```
  tf = freq / (freq + k1 * (1 - b + b * dl / avgdl))
  ```

  - **`freq`**：词在文档中出现的次数，这里是 1。
  - **`k1`**：词频饱和度参数，默认值为 1.2。它控制着词频对得分的影响程度。
  - **`b`**：长度归一化参数，默认值为 0.75。用于平衡文档长度对得分的影响。
  - **`dl`**：文档字段的长度，`_id`为`2`的文档中`dl`是 3。
  - **`avgdl`**：该字段所有文档的平均长度，这里是 6。

- **示例计算（以`_id`为`2`的文档为例）**：

```python
freq = 1
k1 = 1.2
b = 0.75
dl = 3
avgdl = 6
tf = freq / (freq + k1 * (1 - b + b * dl / avgdl))
print(tf)  
```

计算结果为 0.5714286。

以`_id`为`2`的文档为例，最终得分计算如下：

```python
boost = 2.2
idf = 0.6931472
tf = 0.5714286
score = boost * idf * tf
print(score)  
```

计算结果为 0.8713851，与响应中的`_score`值一致。

综上所述，Elasticsearch 通过综合考虑词的稀有程度、在文档中的出现频率以及文档长度等因素，为每个匹配的文档计算得分。

### 1.3 自定义评分策略

自定义评分是用来优化Elasticsearch默认评分算法的一种有效方法，可以更好地满足特定应用场景的需求。

自定义评分的核心是通过修改评分来修改文档相关性，在最前面的位置返回用户最期望的结果。

Elasticsearch自定义评分的主要作用如下：

1. 排序偏好：通过在搜索结果中给每个文档自定义评分，可以更好地满足搜索用户的排序偏好。
2. 特殊字段权重：通过给特定字段赋予更高的权重，可以让这些字段对搜索结果的影响更大。
3. 业务逻辑需求：根据业务需求，可以定义复杂的评分逻辑，使搜索结果更符合业务需求。

4. 自定义用户行为：可以使用用户行为数据（如点击率）作为评分因素，提高用户搜索体验。

**搜索结果相关性与自定义评分的关系**:

搜索引擎本质是一个匹配过程，即从海量的数据中找到匹配用户需求的内容。判定内容与用户查询的相关性一直是搜索引擎领域的核心研究课题之一。如果搜索引擎不能准确地识别用户查询的意图并将相关结果排在前面的位置，那么搜索结果就不能满足用户的需求，从而影响用户对搜索引擎的满意度。

![](../images/51.png)

如上图所示，左侧圆圈代表用户期望通过搜索引擎获取的结果，右侧圆圈代表用户最终得到的结果。左右两个圆的交集部分即为预期结果与实际结果的相关性。

## 二. 自定义评分策略

然而，如何实现这样的自定义评分策略，以确保搜索结果能够最大限度地满足用户需求呢？我们可以从多个层面，包括索引层面、查询层面以及后处理阶段着手。

以下是几种主要的自定义评分策略：

- Index Boost: 在索引层面修改相关性 
- boosting: 修改文档相关性 
- negative_boost: 降低相关性 
- function_score: 自定义评分 
- rescore_query：查询后二次打分

### 2.1 在索引层面修改相关性（Index Boost）

Index Boost这种方式能在跨多个索引搜索时为每个索引配置不同的级别。所以它适用于索引级别调整评分。

**案例**：一批数据里有不同的标签，数据结构一致，要将不同的标签存储到不同的索引(A、B、C)，并严格按照标签来分类展示（先展示A类，然后展示B类，最后展示C类），应该用什么方式查询呢？

**准备数据**：

创建三个索引，并分别插入一条数据：

```json
PUT my_index_100a/_doc/1
{
    "subject":"subject 1"
}
PUT my_index_100b/_doc/1
{
    "subject":"subject 1"
}
PUT my_index_100c/_doc/1
{
    "subject":"subject 1"
}
```

由于三个索引中数据都是一致的，所以我们查询的 `subject.keyword="subject 1"` 的数据的 `TF` 和 `IDF` 都是一致的，所以可以看到，最终查询出来的三个文档得分都是一致的：
```json
POST my_index_100*/_search
{
    "query": {
        "term": {
            "subject.keyword": {
                "value": "subject 1"
            }
        }
    }
}
```

![](../images/52.png)

如果我们想让文档最终得分，按照 先展示A类，然后展示B类，最后展示C类的顺序展示，我们可以借助 `indices_boost` 提升索引的权重，让A排在最前，其次是B，最后是C。 

```json
POST my_index_100*/_search
{
    "query": {
        "term": {
            "subject.keyword": {
                "value": "subject 1"
            }
        }
    },
    "indices_boost": [
        {
            "my_index_100a": 1.5
        },
        {
            "my_index_100b": 1.2
        },
        {
            "my_index_100c": 1
        }
    ]
}
```

![](../images/53.png)

### 2.2 修改文档相关性（boosting）

boosting可在查询时修改文档的相关度。boosting值所在范围不同，含义也不同。

- 若boosting值为0～1，如0.2，代表降低评分；
- 若 boosting 值＞1，如1.5，则代表提升评分。

适用于某些特定的查询场景，用户可以自定义修改满足某个查询条件的结果评分。

**准备数据**：

```json
POST /blogs/_bulk
{"index":{"_id":1}}
{"title":"Apple iPad","content":"Apple iPad,Apple iPad"}
{"index":{"_id":2}}
{"title":"Apple iPad,Apple iPad","content":"Apple iPad"}
```

两个文档有一定相似性，它们都包含了 `title`、`content` 字段，并且都有 `Apple iPad` 词项，区别是 `ID=1` 的文档 `content` 长一点，`ID=2` 的文档 `title` 长一点。

**查询**：

```json
GET /blogs/_search
{
    "query": {
        "bool": {
            "should": [
                {
                    "match": {
                        "title": {
                            "query": "apple,ipad"
                        }
                    }
                },
                {
                    "match": {
                        "content": {
                            "query": "apple,ipad"
                        }
                    }
                }
            ]
        }
    }
}
```

由于两个文档中 `title` 和 `content` 字段都包含了 "Apple" 和 "iPad"，并且“词频”和“逆向文本频率”是一致的

得分情况：

| 文档 | title 词频得分                     | title 逆向文本频率得分             | content 词频得分                   | content 逆向文本频率得分           |
| ---- | ---------------------------------- | ---------------------------------- | ---------------------------------- | ---------------------------------- |
| ID=1 | Apple(0.5714286)+ipad(0.5714286)   | Apple(0.18232156)+ipad(0.18232156) | Apple(0.5263158)+ipad(0.5263158)） | Apple(0.18232156)+ipad(0.18232156) |
| ID=2 | Apple(0.5263158)+ipad(0.5263158)） | Apple(0.18232156)+ipad(0.18232156) | Apple(0.5714286)+ipad(0.5714286)   | Apple(0.18232156)+ipad(0.18232156) |

ID=1，2的数据 `IDF(逆向文本频率)` 值都是一致的，但是ID=1 `title` 字段的 `TF(词频)` 与 ID=2 `content`字段 `TF(词频)` 是一致的，同时ID=1 `content` 字段的 `TF(词频)` 与ID=2 `title`字段 `TF(词频)` 也是一致的，导致两个文档最终的得分相同。

![](../images/54.png)

此时**如果我们需要增加title计算相关性的权重**，可以使用 `boosting`：

```json
GET /blogs/_search
{
    "query": {
        "bool": {
            "should": [
                {
                    "match": {
                        "title": {
                            "query": "apple,ipad",
                            "boost": 4
                        }
                    }
                },
                {
                    "match": {
                        "content": {
                            "query": "apple,ipad",
                            "boost": 1
                        }
                    }
                }
            ]
        }
    }
}
```

![](../images/55.png)



