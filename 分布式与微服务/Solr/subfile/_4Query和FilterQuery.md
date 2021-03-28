# Query和Filter Query

## 一. fq vs q

Solr查询有两个重要的查询操作组成，他们匹配用户查询请求参数以及对匹配的结果集进行排序，以便于匹配度较高的前几个索引文档会被返回。默认的索引文档会基于**相关性评分**进行排序，这意味着查询结果集被查询并收集到之后，需要一个额外的操作来计算每个匹配的索引文档的相关性评分。

为了高效查询匹配的索引文档以及对匹配的索引文档进行评分，Solr使用两个参数：fq和q。fq参数代表Filter Query；q参数代表Query。第一眼看到这两个参数感觉很难区分，因为他们拥有相同的查询语法，并且返回相同的查询结果和查询集数量，正因如此，大部分使用者觉得两者的功能是一样的，从而忽略了fq的存在。

fq只有一项单一职责：对匹配的索引文档进行过滤限制，不会对索引文档进行相关性评分操作。

而q参数拥有两项职责：

- 根据用户传入的查询条件匹配符合条件的索引文档；
- 使用相关性算法根据Term列表对匹配到的索引文档进行相关性评分，这些Term列表可能是用户传入的，也可能是对用户输入的查询文本字符串经过分词处理后得到的。

将查询的某些部分分离到Filter Query中，那么这些被分离到Filter Query的部分匹配到的索引文档将不会进行相关性评分操作，这将大量减少了索引文档相关性评分的计算工作量。

Solr内部会为每个Filter Query分配独立的缓存区来缓存Filter Query匹配到的索引文档，那么如果再次使用相同的Filter Query时会直接命中缓冲区中的索引文档。鉴于Filter Query内部的这种机制，应该将那些能够过滤掉大部分无效文档的查询条件通过fq去实现，你也可以将那些用户使用频率较高的查询条件使用fq参数实现。

## 二. fq和q的执行顺序

- 首先每个fq参数会在Fiter缓存区查找索引文档，如果在缓存中存在，那么会返回命中的DocSet;
- 如果q参数在Filter 缓存区没有命中且Filter缓存开启了，那么会根据fq参数构造Filter Query从Solr索引中加载获取每个索引文档的DocSet,并存人Filter 缓存
- 根据q参数构造主查询从Solr索引中加载匹配的所有索引文档，得到一个索引文档的集合，如果主查询返回的索引文档的内部ID在Filter Query缓存的DocSet中也存在，那么该索引文档就判定为应该返回给用户，然后就对该匹配的索引文档计算相关性评分;

- 如果主查询还包含其他POST Filter (它会在Query和Filter Query执行完毕之后才执行)，他们还会执行一部分的索引文档收集工作;

## 三. FilterQuery的执行顺序

如果你的查询请求中包含了多个Filter Query，每个Filter Query的执行顺序会直接影响你的查询性能，如果一个Filter Query提前执行并过滤掉一部分结果集缩小了查询匹配范围，那么接下来执行的Filter Query会基于更少的Document进行二次查询匹配，其查询速度自然就更快。相反的，如果一个 Filter Query必须要执行非常复杂的计算，比如geospatial Filter需要过滤指定半径的范围内的坐标点，那么此时应该给予更少的索引文档去执行昂贵的CPU计算，那么就意味着**那些比较昂贵的FilterQuery需要尽量靠后执行**。

当你清楚地知道FilterQuery中哪个执行开销是最昂贵的，Solr允许你通过指定一个cost参数来强制指定Filter Query的执行顺序，cost 参数表示对该Filter Query执行开销的一个估算数值，数值越大说明该Filter Query的执行开销越大，即意味着它应该越靠后执行。cost参数的具体使用语法如下所示:

```shell
fq={!cost=1}category:technology&
fq={!cost=2}date:[NOW/DAY-1YEAR TO *]&
fq={!geofilt pt=37.773,-122.419 sfield=location d=50 cost=3}
```

当时该Filter Query在Solr中被称为Post Filter