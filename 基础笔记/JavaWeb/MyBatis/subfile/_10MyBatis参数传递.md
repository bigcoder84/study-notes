# MyBatis参数传递

## 1. 传递单个参数

在使用MyBatis如果SQL语句只需要传入一个参数，那么括号里面填写什么都可以

```java
List<Tag> getTagsByArticleId(Long id);
```

```xml
<select id="getTagsByArticleId" parameterType="long" resultMap="tagMap">
    select * from tag where article_id=#{value}
</select>
```



## 2. 传递多个参数

### 2.1 使用Map传递（不推荐）

我们可以将多个参数封装在Map中，然后通过#{key}的形式来取出参数值

```java
List<Tag> getTagList(Map map);
```

```xml
<select id="getTagList" parameterType="hashmap" resultMap="tagMap">
    select * from tag where content=#{content} and article_id=#{articleId}
</select>
```

此种传递方式在开发中不允许使用。



### 2.2 使用索引值传递（不推荐）

当使用Mapper动态代理开发时，如果方法传入多个参数，那么我们通过#{index}的形式，依次取出参数值，index从0开始

```java
List<Tag> getTagList(String content,Long articleId);
```

```xml
<select id="getTagList" resultMap="tagMap">
    select * from tag where content=#{0} and article_id=#{1}
</select>
```



### 2.3 使用@Param注解（推荐使用）

```java
List<Tag> getTagList(@Param("content") String content,@Param("article_id") Long articleId);
```

```java
<select id="getTagList" resultMap="tagMap">
    select * from tag where content=#{content} and article_id=#{article_id}
</select>
```



### 2.4 封装类传递（参数较多时推荐使用）

```java
List<Tag> getTagList(Tag tag);
```

```java
<select id="getTagList" parameterType="Tag" resultMap="tagMap">
    select * from tag where content=#{content} and article_id=#{articleId}
</select>
```

