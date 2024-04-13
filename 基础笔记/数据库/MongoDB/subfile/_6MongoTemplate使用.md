# SpringBoot 集成 spring-data-mongodb

> 本文转载至：[SpringBoot 集成 Spring Data Mongodb 操作 MongoDB 详解 | 小豆丁技术栈 (mydlq.club)](http://www.mydlq.club/article/85/)

- [SpringBoot 集成 spring-data-mongodb](#springboot-集成-spring-data-mongodb)
  - [一. MongoDB 简介](#一-mongodb-简介)
  - [二. MongoDB 特征](#二-mongodb-特征)
  - [三、MongoDB 概念](#三mongodb-概念)
    - [3.1 基本概念](#31-基本概念)
    - [3.2 数据类型](#32-数据类型)
  - [四. SpringBoot 操作 MongoDB 示例](#四-springboot-操作-mongodb-示例)
    - [4.1 Maven 引入相关依赖](#41-maven-引入相关依赖)
    - [4.2 Application 文件中添加 MongoDB 连接配置](#42-application-文件中添加-mongodb-连接配置)
    - [4.3 创建用于测试的实体类](#43-创建用于测试的实体类)
    - [4.5 集合操作](#45-集合操作)
      - [4.5.1 创建集合](#451-创建集合)
      - [4.5.2 查询集合](#452-查询集合)
      - [4.5.3 删除集合](#453-删除集合)
    - [4.6 视图操作](#46-视图操作)
    - [4.7 文档操作](#47-文档操作)
      - [4.7.1 文档插入](#471-文档插入)
      - [4.7.2 文档存储](#472-文档存储)
      - [4.7.2 文档查询](#472-文档查询)
      - [4.7.3 文档更新](#473-文档更新)
      - [4.7.4 文档删除](#474-文档删除)
    - [4.8 聚合操作](#48-聚合操作)
      - [4.8.1 聚合表达式](#481-聚合表达式)
      - [4.8.2 聚合管道操作符](#482-聚合管道操作符)
    - [4.9 索引操作](#49-索引操作)
      - [4.9.1 创建索引](#491-创建索引)
      - [4.9.2 查询索引](#492-查询索引)
      - [4.9.3 删除索引](#493-删除索引)
    - [4.10 RunCommand 命令操作](#410-runcommand-命令操作)
  - [五. SpringBoot 引入 MongoDB 中的事务](#五-springboot-引入-mongodb-中的事务)
    - [5.1 配置事务管理器](#51-配置事务管理器)
    - [5.2 创建事务测试服务](#52-创建事务测试服务)

## 一. MongoDB 简介

MongoDB 是一个介于关系数据库和非关系数据库之间的产品，是非关系数据库当中功能最丰富，且与关系数据库的最为相像的。它支持的数据结构非常松散，是类似 json 的 bson 格式，因此可以存储比较复杂的数据类型。Mongo 最大的特点是它支持的查询语言非常强大，其语法有点类似于面向对象的查询语言，几乎可以实现类似关系数据库单表查询的绝大部分功能，而且还支持对数据建立索引。

## 二. MongoDB 特征

MongoDB 是一个文档数据库，它的数据以文档方式进行存储，将数据存储在类似 JSON 的 BSON 文档中，其特征如下：

- 数据以 BSON 方式存储
  - 允许灵活和动态的模式。
  - 支持数组和嵌套对象作为值。
  - 处理数据的最自然，最有效的方式。
  - 文档模型轻松映射到应用程序代码中的对象
- 强大的查询语言
  - 支持聚合和其他现代用例，例如基于地理的搜索，图形搜索和文本搜索。
  - 查询本身就是 JSON，因此很容易组合。不再需要串联字符串来动态生成 SQL 查询。
  - 丰富而富有表现力的查询语言，无论您在文档中有多嵌套，都可以按任何字段进行过滤和排序。
- 拥有关系数据库的所有功能
  - 支持查询联接。
  - 具有快照隔离功能的分布式多文档 ACID 事务。
  - 两种类型的关系，而不是一种"引用"和"嵌入式"。
- 分布式数据库为核心
  - 水平扩展
  - 内置了高可用性
  - 地理分布并且易于使用
- **MongoDB 免费使用**

## 三、MongoDB 概念

简单介绍下 MongoDB 的概念知识，方便后续使用 SpringBoot 操作 MongoDB 时候对 MongoDB 相关概念知道其作用。

> 本文章并不是用于介绍 MongoDB 知识，而是介绍在 Java 语言中 SpringBoot 框架里如何操作 MongoDB。所以，在操作 MongoDB 前，最好对其知识点进行一下系统的学习。

### 3.1 基本概念

MongoDB 基本概念指的是学习 MongoDB 最先应该了解的词汇，比如 MongoDB 中的"数据库"、"集合"、"文档"这三个名词：

- **文档（Document）：** 文档是 MongoDB 中最基本的数据单元，由键值对组成，类似于 JSON 格式，可以存储不同字段，字段的值可以包括其他文档，数组和文档数组。
- **集合（Collection）：** 集合指的是文档组（类似于 Mysql 中的表的概念），里面可以存储许多文档。
- **数据库（Database）：** MongoDB 中可以存在多个数据库，每个数据库中中用有不同的集合与用户权限，这样可以供不同的项目组使用不同的数据库。

当然，还有其它一些概念，比如：

- **_id（主键）：** 主键主要作用是用于保证数据完整性，加快数据库的访问速度，方便快速定位某个文档。在 MongoDB 中可以手动指定文档主键 ID，如果未手动指定则 MongoDB 会生成 12 位的 ObjectID。
- **index（索引）：** 索引是一种特殊的数据结构，存储在一个易于遍历读取的数据集合中，其能够对数据库文档中的数据进行排序的一种结构。索引通常能极大提高文档查询效率，如果没有设置索引，MongoDB 会遍历集合中的整个文档，选取符合查询条件的文档记录。这种查询效率是非常低的，当处理大量时，查询可能需要花费几十秒甚至几分钟，这对网站的性能是非常致命的。
- **field（字段）：** 文档中的字段，类似于关系型数据库中的列。
- **aggregation（聚合）** MongoDB 中聚合主要用于处理数据处理，例如统计平均值、求和等，可以快速通过聚合操作，汇总数据，尤其是对绘制图表添加了便利。

### 3.2 数据类型

以下为 MongoDB 中常用的几种数据类型：

- **String：** 字符串，存储数据常用的数据类型。在 MongoDB 中，UTF-8 编码的字符串才是合法的。
- **Integer：** 整型数值，用于存储数值。根据你所采用的服务器，可分为 32 位或 64 位。
- **Boolean：** 布尔值，用于存储布尔值（true/false）。
- **Double：** 双精度浮点值，用于存储浮点值。
- **Min/Max keys：** 将一个值与 BSON（二进制的 JSON）元素的最低值和最高值相对比。
- **Array：** 用于将数组或列表或多个值存储为一个键。
- **Timestamp：** 时间戳。记录文档修改或添加的具体时间。
- **Object：** 用于内嵌文档。
- **Null：** 用于创建空值。
- **Symbol：** 符号。该数据类型基本上等同于字符串类型，但不同的是，它一般用于采用特殊符号类型的语言。
- **Date：** 日期时间，用 UNIX 时间格式来存储当前日期或时间。你可以指定自己的日期时间：创建 Date 对象，传入年月日信息。
- **Object ID：** 对象 ID，用于创建文档的 ID。
- **Binary Data：** 二进制数据，用于存储二进制数据。
- **Code：** 代码类型，用于在文档中存储 JavaScript 代码。
- **Regular expression：** 正则表达式类型，用于存储正则表达式。

## 四. SpringBoot 操作 MongoDB 示例

这里使用 Spring Data MongoDB 封装的 MongoDB 官方 Java 驱动 MongoTemplate 对 MongoDB 进行操作。

> 关于使用简单的 Repositories 方式来操作 MongoDB 这种用法只能实现较简单的操作，使用简单但是灵活性比较差，所以这里就不介绍这种使用方式了。

### 4.1 Maven 引入相关依赖

Maven 引入 SpringBoot 和 MongoDB 相关依赖组件：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-mongodb</artifactId>
</dependency>
```

### 4.2 Application 文件中添加 MongoDB 连接配置

在 SpringBoot 的 application.yml 文件中添加连接 MongoDB 的配置参数，内容如下：

```yaml
spring:
  data:
    mongodb:
      host: 127.0.0.1
      port: 27017
      database: test
      username: admin
      password: 123456
```

参数介绍：

- **spring.data.mongodb.host：** 指定 MongoDB Server 地址
- **spring.data.mongodb.port：** 指定 MongoDB Server 端口
- **spring.data.mongodb.database：** 指定使用的数据库
- **spring.data.mongodb.username：** MongoDB 用户名
- **spring.data.mongodb.password：** MongoDB 密码

### 4.3 创建用于测试的实体类

创建用于示例中测试的实体 User 和 Status 类：

```java
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;
import lombok.ToString;
import lombok.experimental.Accessors;
import org.springframework.data.mongodb.core.mapping.MongoId;
import java.util.Date;

@Data
@ToString
@Accessors(chain = true)
public class User {

    /**
     * 使用 @MongoID 能更清晰的指定 _id 主键
     */
    @MongoId
    private String id;
    private String name;
    private String sex;
    private Integer salary;
    private Integer age;
    @JsonFormat( pattern ="yyyy-MM-dd", timezone ="GMT+8")
    private Date birthday;
    private String remake;
    private Status status;

}

@Data
@ToString
@Accessors(chain = true)
public class Status {

    private Integer weight;
    private Integer height;

}
```

### 4.5 集合操作

#### 4.5.1 创建集合

```java
import org.springframework.data.mongodb.core.CollectionOptions;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.CriteriaDefinition;
import org.springframework.data.mongodb.core.validation.Validator;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;

@Service
public class CreateCollectionService {

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 创建【集合】
     * 
     * 创建一个大小没有限制的集合（默认集合创建方式） 
     * 
     * @return 创建集合的结果
     */
    public Object createCollection() {
        // 设置集合名称
        String collectionName = "users1";
        // 创建集合并返回集合信息
        mongoTemplate.createCollection(collectionName);
        // 检测新的集合是否存在，返回创建结果
        return mongoTemplate.collectionExists(collectionName) ? "创建视图成功" : "创建视图失败";
    }

    /**
     * 创建【固定大小集合】
     * 
     * 创建集合并设置 `capped=true` 创建 `固定大小集合`，可以配置参数 `size` 限制文档大小，可以配置参数 `max` 限制集合文档数量。
     *
     * @return 创建集合的结果
     */
    public Object createCollectionFixedSize() {
        // 设置集合名称
        String collectionName = "users2";
        // 设置集合参数
        long size = 1024L;
        long max = 5L;
        // 创建固定大小集合
        CollectionOptions collectionOptions = CollectionOptions.empty()
                // 创建固定集合。固定集合是指有着固定大小的集合，当达到最大值时，它会自动覆盖最早的文档。
                .capped()
                // 固定集合指定一个最大值，以千字节计(KB),如果 capped 为 true，也需要指定该字段。
                .size(size)
                // 指定固定集合中包含文档的最大数量。
                .maxDocuments(max);
        // 执行创建集合
        mongoTemplate.createCollection(collectionName, collectionOptions);
        // 检测新的集合是否存在，返回创建结果
        return mongoTemplate.collectionExists(collectionName) ? "创建视图成功" : "创建视图失败";
    }

    /**
     * 创建【验证文档数据】的集合
     *
     * 创建集合并在文档"插入"与"更新"时进行数据效验，如果符合创建集合设置的条件就进允许更新与插入，否则则按照设置的设置的策略进行处理。
     *
     * * 效验级别：
     *   - off：关闭数据校验。
     *   - strict：(默认值) 对所有的文档"插入"与"更新"操作有效。
     *   - moderate：仅对"插入"和满足校验规则的"文档"做"更新"操作有效。对已存在的不符合校验规则的"文档"无效。 
     * * 执行策略：
     *   - error：(默认值) 文档必须满足校验规则，才能被写入。
     *   - warn：对于"文档"不符合校验规则的 MongoDB 允许写入，但会记录一条告警到 mongod.log 中去。日志内容记录报错信息以及该"文档"的完整记录。
     * 
     * @return 创建集合结果
     */
    public Object createCollectionValidation() {
        // 设置集合名称
        String collectionName = "users3";
        // 设置验证条件,只允许岁数大于20的用户信息插入
        CriteriaDefinition criteria = Criteria.where("age").gt(20);
        // 设置集合选项验证对象
        CollectionOptions collectionOptions = CollectionOptions.empty()
                .validator(Validator.criteria(criteria))
                // 设置效验级别
                .strictValidation()
                // 设置效验不通过后执行的动作
                .failOnValidationError();
        // 执行创建集合
        mongoTemplate.createCollection(collectionName, collectionOptions);
        // 检测新的集合是否存在，返回创建结果
        return mongoTemplate.collectionExists(collectionName) ? "创建集合成功" : "创建集合失败";
    }

}
```

#### 4.5.2 查询集合

```java
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;

@Service
public class QueryCollectionService {

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 获取【集合名称】列表
     *
     * @return 集合名称列表
     */
    public Object getCollectionNames() {
        // 执行获取集合名称列表
        return mongoTemplate.getCollectionNames();
    }

    /**
     * 检测集合【是否存在】
     *
     * @return 集合是否存在
     */
    public boolean collectionExists() {
        // 设置集合名称
        String collectionName = "users";
        // 检测新的集合是否存在，返回检测结果
        return mongoTemplate.collectionExists(collectionName);
    }

}
```

#### 4.5.3 删除集合

```java
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;

@Service
public class RemoveCollectionService {

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 删除【集合】
     *
     * @return 创建集合结果
     */
    public Object dropCollection() {
        // 设置集合名称
        String collectionName = "users3";
        // 执行删除集合
        mongoTemplate.getCollection(collectionName).drop();
        // 检测新的集合是否存在，返回删除结果
        return !mongoTemplate.collectionExists(collectionName) ? "删除集合成功" : "删除集合失败";
    }

}
```

### 4.6 视图操作

```java
import org.bson.Document;
import org.bson.conversions.Bson;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.List;

@Service
public class ViewService {

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 创建视图
     *
     * @return 创建视图结果
     */
    public Object createView() {
        // 设置视图名
        String newViewName = "usersView";
        // 设置获取数据的集合名称
        String collectionName = "users";
        // 定义视图的管道,可是设置视图显示的内容多个筛选条件
        List<Bson> pipeline = new ArrayList<>();
        // 设置条件，用于筛选集合中的文档数据，只有符合条件的才会映射到视图中
        pipeline.add(Document.parse("{\"$match\":{\"sex\":\"女\"}}"));
        // 执行创建视图
        mongoTemplate.getDb().createView(newViewName, collectionName, pipeline);
        // 检测新的集合是否存在，返回创建结果
        return mongoTemplate.collectionExists(newViewName) ? "创建视图成功" : "创建视图失败";
    }

    /**
     * 删除视图
     *
     * @return 删除视图结果
     */
    public Object dropView() {
        // 设置待删除的视图名称
        String viewName = "usersView";
        // 检测视图是否存在
        if (mongoTemplate.collectionExists(viewName)) {
            // 删除视图
            mongoTemplate.getDb().getCollection(viewName).drop();
            return "删除视图成功";
        }
        // 检测新的集合是否存在，返回创建结果
        return !mongoTemplate.collectionExists(viewName) ? "删除视图成功" : "删除视图失败";
    }

}
```

### 4.7 文档操作

#### 4.7.1 文档插入

```java
import lombok.extern.slf4j.Slf4j;
import mydlq.club.example.entity.Status;
import mydlq.club.example.entity.User;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Date;
import java.util.List;

@Slf4j
@Service
public class InsertService {

    /** 设置集合名称 */
    private static final String COLLECTION_NAME = "users";

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 插入【一条】文档数据，如果文档信息已经【存在就抛出异常】
     *
     * @return 插入的文档信息
     */
    public Object insert() {
        // 设置用户信息
        User user = new User()
                .setId("10")
                .setAge(22)
                .setSex("男")
                .setRemake("无")
                .setSalary(1500)
                .setName("zhangsan")
                .setBirthday(new Date())
                .setStatus(new Status().setHeight(180).setWeight(150));
        // 插入一条用户数据，如果文档信息已经存在就抛出异常
        User newUser = mongoTemplate.insert(user, COLLECTION_NAME);
        // 输出存储结果
        log.info("存储的用户信息为：{}", newUser);
        return newUser;
    }

    /**
     * 插入【多条】文档数据，如果文档信息已经【存在就抛出异常】
     *
     * @return 插入的多个文档信息
     *
     */
    public Object insertMany(){
        // 设置两个用户信息
        User user1 = new User()
                .setId("11")
                .setAge(22)
                .setSex("男")
                .setRemake("无")
                .setSalary(1500)
                .setName("shiyi")
                .setBirthday(new Date())
                .setStatus(new Status().setHeight(180).setWeight(150));
        User user2 = new User()
                .setId("12")
                .setAge(22)
                .setSex("男")
                .setRemake("无")
                .setSalary(1500)
                .setName("shier")
                .setBirthday(new Date())
                .setStatus(new Status().setHeight(180).setWeight(150));
        // 使用户信息加入结合
        List<User> userList = new ArrayList<>();
        userList.add(user1);
        userList.add(user2);
        // 插入一条用户数据，如果某个文档信息已经存在就抛出异常
        Collection<User> newUserList = mongoTemplate.insert(userList, COLLECTION_NAME);
        // 输出存储结果
        for (User user : newUserList) {
            log.info("存储的用户信息为：{}", user);
        }
        return newUserList;
    }

}
```

#### 4.7.2 文档存储

```java
import lombok.extern.slf4j.Slf4j;
import mydlq.club.example.entity.Status;
import mydlq.club.example.entity.User;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import java.util.Date;

@Slf4j
@Service
public class SaveService {

    /** 设置集合名称 */
    private static final String COLLECTION_NAME = "users";

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 存储【一条】用户信息，如果文档信息已经【存在就执行更新】
     *
     * @return 存储的文档信息
     */
    public Object save() {
        // 设置用户信息
        User user = new User()
                .setId("13")
                .setAge(22)
                .setSex("男")
                .setRemake("无")
                .setSalary(2800)
                .setName("kuiba")
                .setBirthday(new Date())
                .setStatus(new Status().setHeight(169).setWeight(150));
        // 存储用户信息,如果文档信息已经存在就执行更新
        User newUser = mongoTemplate.save(user, COLLECTION_NAME);
        // 输出存储结果
        log.info("存储的用户信息为：{}", newUser);
        return newUser;
    }

}
```

#### 4.7.2 文档查询

```java
import lombok.extern.slf4j.Slf4j;
import mydlq.club.example.entity.User;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import java.util.Arrays;
import java.util.List;

@Slf4j
@Service
public class QueryService {

    /**
     * 设置集合名称
     */
    private static final String COLLECTION_NAME = "users";

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 查询集合中的【全部】文档数据
     *
     * @return 全部文档列表
     */
    public Object findAll() {
        // 执行查询集合中全部文档信息
        List<User> documentList = mongoTemplate.findAll(User.class, COLLECTION_NAME);
        // 输出结果
        for (User user : documentList) {
            log.info("用户信息：{}", user);
        }
        return documentList;
    }

    /**
     * 根据【文档ID】查询集合中文档数据
     *
     * @return 文档信息
     */
    public Object findById() {
        // 设置查询的文档 ID
        String id = "1";
        // 根据文档ID查询集合中文档数据，并转换为对应 Java 对象
        User user = mongoTemplate.findById(id, User.class, COLLECTION_NAME);
        // 输出结果
        log.info("用户信息：{}", user);
        return user;
    }

    /**
     * 根据【条件】查询集合中【符合条件】的文档，只取【第一条】数据
     *
     * @return 符合条件的第一条文档
     */
    public Object findOne() {
        // 设置查询条件参数
        int age = 22;
        // 创建条件对象
        Criteria criteria = Criteria.where("age").is(age);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 查询一条文档，如果查询结果中有多条文档，那么就取第一条
        User user = mongoTemplate.findOne(query, User.class, COLLECTION_NAME);
        // 输出结果
        log.info("用户信息：{}", user);
        return user;
    }

    /**
     * 根据【条件】查询集合中【符合条件】的文档，获取其【文档列表】
     *
     * @return 符合条件的文档列表
     */
    public Object findByCondition() {
        // 设置查询条件参数
        String sex = "女";
        // 创建条件对象
        Criteria criteria = Criteria.where("sex").is(sex);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 查询并返回结果
        List<User> documentList = mongoTemplate.find(query, User.class, COLLECTION_NAME);
        // 输出结果
        for (User user : documentList) {
            log.info("用户信息：{}", user);
        }
        return documentList;
    }

    /**
     * 根据【条件】查询集合中【符合条件】的文档，获取其【文档列表】并【排序】
     *
     * @return 符合条件的文档列表
     */
    public Object findByConditionAndSort() {
        // 设置查询条件参数
        String sex = "男";
        String sort = "age";
        // 创建条件对象
        Criteria criteria = Criteria.where("sex").is(sex);
        // 创建查询对象，然后将条件对象添加到其中，然后根据指定字段进行排序
        Query query = new Query(criteria).with(Sort.by(sort));
        // 执行查询
        List<User> documentList = mongoTemplate.find(query, User.class, COLLECTION_NAME);
        // 输出结果
        for (User user : documentList) {
            log.info("用户信息：{}", user);
        }
        return documentList;
    }

    /**
     * 根据【单个条件】查询集合中的文档数据，并【按指定字段进行排序】与【限制指定数目】
     *
     * @return 符合条件的文档列表
     */
    public Object findByConditionAndSortLimit() {
        // 设置查询条件参数
        String sex = "男";
        String sort = "age";
        int limit = 2;
        // 创建条件对象
        Criteria criteria = Criteria.where("sex").is(sex);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria).with(Sort.by(sort)).limit(limit);
        // 执行查询
        List<User> documentList = mongoTemplate.find(query, User.class, COLLECTION_NAME);
        // 输出结果
        for (User user : documentList) {
            log.info("用户信息：{}", user);
        }
        return documentList;
    }

    /**
     * 根据【单个条件】查询集合中的文档数据，并【按指定字段进行排序】与【并跳过指定数目】
     *
     * @return 符合条件的文档列表
     */
    public Object findByConditionAndSortSkip() {
        // 设置查询条件参数
        String sex = "男";
        String sort = "age";
        int skip = 1;
        // 创建条件对象
        Criteria criteria = Criteria.where("sex").is(sex);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria).with(Sort.by(sort)).skip(skip);
        // 查询并返回结果
        List<User> documentList = mongoTemplate.find(query, User.class, COLLECTION_NAME);
        // 输出结果
        for (User user : documentList) {
            log.info("用户信息：{}", user);
        }
        return documentList;
    }

    /**
     * 查询【存在指定字段名称】的文档数据
     *
     * @return 符合条件的文档列表
     */
    public Object findByExistsField() {
        // 设置查询条件参数
        String field = "sex";
        // 创建条件
        Criteria criteria = Criteria.where(field).exists(true);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 查询并返回结果
        List<User> documentList = mongoTemplate.find(query, User.class, COLLECTION_NAME);
        // 输出结果
        for (User user : documentList) {
            log.info("用户信息：{}", user);
        }
        return documentList;
    }

    /**
     * 根据【AND】关联多个查询条件，查询集合中的文档数据
     *
     * @return 符合条件的文档列表
     */
    public Object findByAndCondition() {
        // 设置查询条件参数
        String sex = "男";
        Integer age = 22;
        // 创建条件
        Criteria criteriaSex = Criteria.where("sex").is(sex);
        Criteria criteriaAge = Criteria.where("age").is(age);
        // 创建条件对象，将上面条件进行 AND 关联
        Criteria criteria = new Criteria().andOperator(criteriaSex, criteriaAge);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 查询并返回结果
        List<User> documentList = mongoTemplate.find(query, User.class, COLLECTION_NAME);
        // 输出结果
        for (User user : documentList) {
            log.info("用户信息：{}", user);
        }
        return documentList;
    }

    /**
     * 根据【OR】关联多个查询条件，查询集合中的文档数据
     *
     * @return 符合条件的文档列表
     */
    public Object findByOrCondition() {
        // 设置查询条件参数
        String sex = "男";
        int age = 22;
        // 创建条件
        Criteria criteriaSex = Criteria.where("sex").is(sex);
        Criteria criteriaAge = Criteria.where("age").is(age);
        // 创建条件对象，将上面条件进行 OR 关联
        Criteria criteria = new Criteria().orOperator(criteriaSex, criteriaAge);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 查询并返回结果
        List<User> documentList = mongoTemplate.find(query, User.class, COLLECTION_NAME);
        // 输出结果
        for (User user : documentList) {
            log.info("用户信息：{}", user);
        }
        return documentList;
    }

    /**
     * 根据【IN】关联多个查询条件，查询集合中的文档数据
     *
     * @return 符合条件的文档列表
     */
    public Object findByInCondition() {
        // 设置查询条件参数
        Integer[] ages = {20, 22, 25};
        // 创建条件
        List<Integer> ageList = Arrays.asList(ages);
        // 创建条件对象
        Criteria criteria = Criteria.where("age").in(ageList);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 查询并返回结果
        List<User> documentList = mongoTemplate.find(query, User.class, COLLECTION_NAME);
        // 输出结果
        for (User user : documentList) {
            log.info("用户信息：{}", user);
        }
        return documentList;
    }

    /**
     * 根据【逻辑运算符】查询集合中的文档数据
     *
     * @return 符合条件的文档列表
     */
    public Object findByOperator() {
        // 设置查询条件参数
        int min = 25;
        int max = 35;
        // 创建条件对象
        Criteria criteria = Criteria.where("age").gt(min).lte(max);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 查询并返回结果
        List<User> documentList = mongoTemplate.find(query, User.class, COLLECTION_NAME);
        // 输出结果
        for (User user : documentList) {
            log.info("用户信息：{}", user);
        }
        return documentList;
    }

    /**
     * 根据【正则表达式】查询集合中的文档数据
     *
     * @return 符合条件的文档列表
     */
    public Object findByRegex() {
        // 设置查询条件参数
        String regex = "^zh*";
        // 创建条件对象
        Criteria criteria = Criteria.where("name").regex(regex);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 查询并返回结果
        List<User> documentList = mongoTemplate.find(query, User.class, COLLECTION_NAME);
        // 输出结果
        for (User user : documentList) {
            log.info("用户信息：{}", user);
        }
        return documentList;
    }

    /**
     * 统计集合中符合【查询条件】的文档【数量】
     *
     * @return 符合条件的文档列表
     */
    public Object countNumber() {
        // 设置查询条件参数
        int age = 22;
        // 创建条件对象
        Criteria criteria = Criteria.where("age").is(age);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 查询并返回结果
        long count = mongoTemplate.count(query, User.class, COLLECTION_NAME);
        // 输出结果
        log.info("符合条件的文档数量：{}", count);
        return count;
    }

}
```

#### 4.7.3 文档更新

```java
import com.mongodb.client.result.UpdateResult;
import lombok.extern.slf4j.Slf4j;
import mydlq.club.example.entity.User;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;

@Slf4j
@Service
public class UpdateService {

    /**
     * 设置集合名称
     */
    private static final String COLLECTION_NAME = "users";

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 更新集合中【匹配】查询到的第一条文档数据，如果没有找到就【创建并插入一个新文档】
     *
     * @return 执行更新的结果
     */
    public Object update() {
        // 创建条件对象
        Criteria criteria = Criteria.where("age").is(30);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 创建更新对象,并设置更新的内容
        Update update = new Update().set("age", 33).set("name", "zhangsansan");
        // 执行更新，如果没有找到匹配查询的文档，则创建并插入一个新文档
        UpdateResult result = mongoTemplate.upsert(query, update, User.class, COLLECTION_NAME);
        // 输出结果信息
        String resultInfo = "匹配到" + result.getMatchedCount() + "条数据,对第一条数据进行了更改";
        log.info("更新结果：{}", resultInfo);
        return resultInfo;
    }

    /**
     * 更新集合中【匹配】查询到的【文档数据集合】中的【第一条数据】
     *
     * @return 执行更新的结果
     */
    public Object updateFirst() {
        // 创建条件对象
        Criteria criteria = Criteria.where("name").is("zhangsan");
        // 创建查询对象，然后将条件对象添加到其中，并设置排序
        Query query = new Query(criteria).with(Sort.by("age").ascending());
        // 创建更新对象,并设置更新的内容
        Update update = new Update().set("age", 30).set("name", "zhangsansan");
        // 执行更新
        UpdateResult result = mongoTemplate.updateFirst(query, update, User.class, COLLECTION_NAME);
        // 输出结果信息
        String resultInfo = "共匹配到" + result.getMatchedCount() + "条数据,修改了" + result.getModifiedCount() + "条数据";
        log.info("更新结果：{}", resultInfo);
        return resultInfo;
    }

    /**
     * 更新【匹配查询】到的【文档数据集合】中的【所有数据】
     *
     * @return 执行更新的结果
     */
    public Object updateMany() {
        // 创建条件对象
        Criteria criteria = Criteria.where("age").gt(28);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 设置更新字段和更新的内容
        Update update = new Update().set("age", 29).set("salary", "1999");
        // 执行更新
        UpdateResult result = mongoTemplate.updateMulti(query, update, User.class, COLLECTION_NAME);
        // 输出结果信息
        String resultInfo = "总共匹配到" + result.getMatchedCount() + "条数据,修改了" + result.getModifiedCount() + "条数据";
        log.info("更新结果：{}", resultInfo);
        return resultInfo;
    }

}
```

#### 4.7.4 文档删除

```java
import com.mongodb.client.result.DeleteResult;
import lombok.extern.slf4j.Slf4j;
import mydlq.club.example.entity.User;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import java.util.List;

@Slf4j
@Service
public class RemoveService {

    /**
     * 设置集合名称
     */
    private static final String COLLECTION_NAME = "users";

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 删除集合中【符合条件】的【一个]或[多个】文档
     *
     * @return 删除用户信息的结果
     */
    public Object remove() {
        // 设置查询条件参数
        int age = 30;
        String sex = "男";
        // 创建条件对象
        Criteria criteria = Criteria.where("age").is(age).and("sex").is(sex);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 执行删除查找到的匹配的全部文档信息
        DeleteResult result = mongoTemplate.remove(query, COLLECTION_NAME);
        // 输出结果信息
        String resultInfo = "成功删除 " + result.getDeletedCount() + " 条文档信息";
        log.info(resultInfo);
        return resultInfo;
    }

    /**
     * 删除【符合条件】的【单个文档】，并返回删除的文档。
     *
     * @return 删除的用户信息
     */
    public Object findAndRemove() {
        // 设置查询条件参数
        String name = "zhangsansan";
        // 创建条件对象
        Criteria criteria = Criteria.where("name").is(name);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 执行删除查找到的匹配的第一条文档,并返回删除的文档信息
        User result = mongoTemplate.findAndRemove(query, User.class, COLLECTION_NAME);
        // 输出结果信息
        String resultInfo = "成功删除文档信息，文档内容为：" + result;
        log.info(resultInfo);
        return result;
    }

    /**
     * 删除【符合条件】的【全部文档】，并返回删除的文档。
     *
     * @return 删除的全部用户信息
     */
    public Object findAllAndRemove() {
        // 设置查询条件参数
        int age = 22;
        // 创建条件对象
        Criteria criteria = Criteria.where("age").is(age);
        // 创建查询对象，然后将条件对象添加到其中
        Query query = new Query(criteria);
        // 执行删除查找到的匹配的全部文档,并返回删除的全部文档信息
        List<User> resultList = mongoTemplate.findAllAndRemove(query, User.class, COLLECTION_NAME);
        // 输出结果信息
        String resultInfo = "成功删除文档信息，文档内容为：" + resultList;
        log.info(resultInfo);
        return resultList;
    }

}
```

### 4.8 聚合操作

#### 4.8.1 聚合表达式

```java
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.aggregation.Aggregation;
import org.springframework.data.mongodb.core.aggregation.AggregationOperation;
import org.springframework.data.mongodb.core.aggregation.AggregationResults;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import java.util.Map;

/**
 * 聚合表达式 $group
 *
 * @author mydlq
 */
@Slf4j
@Service
public class AggregateGroupService {

    /**
     * 设置集合名称
     */
    private static final String COLLECTION_NAME = "users";

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 使用管道操作符 $group 结合 $count 方法进行聚合统计
     *
     * @return 聚合结果
     */
    public Object aggregationGroupCount() {
        // 使用管道操作符 $group 进行分组，然后统计各个组的文档数量
        AggregationOperation group = Aggregation.group("age").count().as("numCount");
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(group);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

    /**
     * 使用管道操作符 $group 结合表达式操作符 $max 进行聚合统计
     *
     * @return 聚合结果
     */
    public Object aggregationGroupMax() {
        // 使用管道操作符 $group 进行分组，然后统计各个组文档某字段最大值
        AggregationOperation group = Aggregation.group("sex").max("salary").as("salaryMax");
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(group);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

    /**
     * 使用管道操作符 $group 结合表达式操作符 $min 进行聚合统计
     *
     * @return 聚合结果
     */
    public Object aggregationGroupMin() {
        // 使用管道操作符 $group 进行分组，然后统计各个组文档某字段最小值
        AggregationOperation group = Aggregation.group("sex").min("salary").as("salaryMin");
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(group);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

    /**
     * 使用管道操作符 $group 结合表达式操作符 $sum 进行聚合统计
     *
     * @return 聚合结果
     */
    public Object aggregationGroupSum() {
        // 使用管道操作符 $group 进行分组，然后统计各个组文档某字段值合计
        AggregationOperation group = Aggregation.group("sex").sum("salary").as("salarySum");
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(group);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

    /**
     * 使用管道操作符 $group 结合表达式操作符 $avg 进行聚合统计
     *
     * @return 聚合结果
     */
    public Object aggregationGroupAvg() {
        // 使用管道操作符 $group 进行分组，然后统计各个组文档某字段值平均值
        AggregationOperation group = Aggregation.group("sex").avg("salary").as("salaryAvg");
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(group);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

    /**
     * 使用管道操作符 $group 结合表达式操作符 $first 获取每个组的包含某字段的文档的第一条数据
     *
     * @return 聚合结果
     */
    public Object aggregationGroupFirst() {
        // 先对数据进行排序，然后使用管道操作符 $group 进行分组，最后统计各个组文档某字段值第一个值
        AggregationOperation sort = Aggregation.sort(Sort.by("salary").ascending());
        AggregationOperation group = Aggregation.group("sex").first("salary").as("salaryFirst");
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(sort, group);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

    /**
     * 使用管道操作符 $group 结合表达式操作符 $last 获取每个组的包含某字段的文档的最后一条数据
     *
     * @return 聚合结果
     */
    public Object aggregationGroupLast() {
        // 先对数据进行排序，然后使用管道操作符 $group 进行分组，最后统计各个组文档某字段值第最后一个值
        AggregationOperation sort = Aggregation.sort(Sort.by("salary").ascending());
        AggregationOperation group = Aggregation.group("sex").last("salary").as("salaryLast");
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(sort, group);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

    /**
     * 使用管道操作符 $group 结合表达式操作符 $push 获取某字段列表
     *
     * @return 聚合结果
     */
    public Object aggregationGroupPush() {
        // 先对数据进行排序，然后使用管道操作符 $group 进行分组，然后以数组形式列出某字段的全部值
        AggregationOperation push = Aggregation.group("sex").push("salary").as("salaryFirst");
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(push);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

}

```

#### 4.8.2 聚合管道操作符

```java
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.aggregation.Aggregation;
import org.springframework.data.mongodb.core.aggregation.AggregationOperation;
import org.springframework.data.mongodb.core.aggregation.AggregationResults;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import java.util.Map;

@Slf4j
@Service
public class AggregatePipelineService {

    /**
     * 设置集合名称
     */
    private static final String COLLECTION_NAME = "users";

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 使用 $group 和 $match 聚合,先使用 $match 过滤文档，然后再使用 $group 进行分组
     *
     * @return 聚合结果
     */
    public Object aggregateGroupMatch() {
        // 设置聚合条件，先使用 $match 过滤岁数大于 25 的用户，然后按性别分组，统计每组用户工资最高值
        AggregationOperation match = Aggregation.match(Criteria.where("age").lt(25));
        AggregationOperation group = Aggregation.group("sex").max("salary").as("sexSalary");
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(match, group);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

    /**
     * 使用 $group 和 $sort 聚合,先使用 $group 进行分组，然后再使用 $sort 排序
     *
     * @return 聚合结果
     */
    public Object aggregateGroupSort() {
        // 设置聚合条件，按岁数分组，然后统计每组用户工资最大值和用户数，按每组用户工资最大值升序排序
        AggregationOperation group = Aggregation.group("age")
                .max("salary").as("ageSalary")
                .count().as("ageCount");
        AggregationOperation sort = Aggregation.sort(Sort.by("ageSalary").ascending());
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(group, sort);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

    /**
     * 使用 $group 和 $limit 聚合,先使用 $group 进行分组，然后再使用 $limit 限制一定数目文档
     *
     * @return 聚合结果
     */
    public Object aggregateGroupLimit() {
        // 设置聚合条件，先按岁数分组，然后求每组用户的工资总数、最大值、最小值、平均值，限制只能显示五条
        AggregationOperation group = Aggregation.group("age")
                .sum("salary").as("sumSalary")
                .max("salary").as("maxSalary")
                .min("salary").as("minSalary")
                .avg("salary").as("avgSalary");
        AggregationOperation limit = Aggregation.limit(5L);
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(group, limit);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

    /**
     * 使用 $group 和 $skip 聚合,先使用 $group 进行分组，然后再使用 $skip 跳过一定数目文档
     *
     * @return 聚合结果
     */
    public Object aggregateGroupSkip() {
        // 设置聚合条件，先按岁数分组，然后求每组用户的工资总数、最大值、最小值、平均值，跳过前 2 条
        AggregationOperation group = Aggregation.group("age")
                .sum("salary").as("sumSalary")
                .max("salary").as("maxSalary")
                .min("salary").as("minSalary")
                .avg("salary").as("avgSalary");
        AggregationOperation limit = Aggregation.skip(2L);
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(group, limit);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

    /**
     * 使用 $group 和 $project 聚合,先使用 $group 进行分组，然后再使用 $project 限制显示的字段
     *
     * @return 聚合结果
     */
    public Object aggregateGroupProject() {
        // 设置聚合条件,按岁数分组，然后求每组用户工资最大值、最小值，然后使用 $project 限制值显示 salaryMax 字段
        AggregationOperation group = Aggregation.group("age")
                .max("salary").as("maxSalary")
                .min("salary").as("minSalary");
        AggregationOperation project = Aggregation.project("maxSalary");
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(group, project);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

    /**
     * 使用 $group 和 $unwind 聚合,先使用 $project 进行分组，然后再使用 $unwind 拆分文档中的数组为一条新文档记录
     *
     * @return 聚合结果
     */
    public Object aggregateProjectUnwind() {
        // 设置聚合条件，设置显示`name`、`age`、`title`字段，然后将结果中的多条文档按 title 字段进行拆分
        AggregationOperation project = Aggregation.project("name", "age", "title");
        AggregationOperation unwind = Aggregation.unwind("title");
        // 将操作加入到聚合对象中
        Aggregation aggregation = Aggregation.newAggregation(project, unwind);
        // 执行聚合查询
        AggregationResults<Map> results = mongoTemplate.aggregate(aggregation, COLLECTION_NAME, Map.class);
        for (Map result : results.getMappedResults()) {
            log.info("{}", result);
        }
        return results.getMappedResults();
    }

}
```

**聚合管道操作符:**

- **$project：** 可以从文档中选择想要的字段，和不想要的字段（指定的字段可以是来自输入文档或新计算字段的现有字段 ，也可以通过管道表达式进行一些复杂的操作，例如数学操作，日期操作，字符串操作，逻辑操作。
- **$match：** 用于过滤数据，只输出符合条件的文档。$match使用MongoDB的标准查询操作。
- **$limit：** 用来限制MongoDB聚合管道返回的文档数。
- **$skip：** 在聚合管道中跳过指定数量的文档，并返回余下的文档。
- **$unwind：** 将文档中的某一个数组类型字段拆分成多条，每条包含数组中的一个值。
- **$group：** 将集合中的文档分组，可用于统计结果。
- **$sort：** 将输入文档排序后输出。

### 4.9 索引操作

#### 4.9.1 创建索引

```java
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.IndexOptions;
import com.mongodb.client.model.Indexes;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;

@Slf4j
@Service
public class CreateIndexService {

    /** 设置集合名称 */
    private static final String COLLECTION_NAME = "users";

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 创建升序索引
     *
     * @return 索引信息
     */
    public Object createAscendingIndex() {
        // 设置字段名称
        String field = "name";
        // 创建索引
        return mongoTemplate.getCollection(COLLECTION_NAME).createIndex(Indexes.ascending(field));
    }

    /**
     * 创建降序索引
     *
     * @return 索引信息
     */
    public Object createDescendingIndex() {
        // 设置字段名称
        String field = "name";
        // 创建索引
        return mongoTemplate.getCollection(COLLECTION_NAME).createIndex(Indexes.descending(field));
    }

    /**
     * 创建升序复合索引
     *
     * @return 索引信息
     */
    public Object createCompositeIndex() {
        // 设置字段名称
        String field1 = "name";
        String field2 = "age";
        // 创建索引
        return mongoTemplate.getCollection(COLLECTION_NAME).createIndex(Indexes.ascending(field1, field2));
    }

    /**
     * 创建文字索引
     *
     * @return 索引信息
     */
    public Object createTextIndex() {
        // 设置字段名称
        String field = "name";
        // 创建索引
        return mongoTemplate.getCollection(COLLECTION_NAME).createIndex(Indexes.text(field));
    }

    /**
     * 创建哈希索引
     *
     * @return 索引信息
     */
    public Object createHashIndex() {
        // 设置字段名称
        String field = "name";
        // 创建索引
        return mongoTemplate.getCollection(COLLECTION_NAME).createIndex(Indexes.hashed(field));
    }

    /**
     * 创建升序唯一索引
     *
     * @return 索引信息
     */
    public Object createUniqueIndex() {
        // 设置字段名称
        String indexName = "name";
        // 配置索引选项
        IndexOptions options = new IndexOptions();
        // 设置为唯一索引
        options.unique(true);
        // 创建索引
        return mongoTemplate.getCollection(COLLECTION_NAME).createIndex(Indexes.ascending(indexName), options);
    }

    /**
     * 创建局部索引
     *
     * @return 索引信息
     */
    public Object createPartialIndex() {
        // 设置字段名称
        String field = "name";
        // 配置索引选项
        IndexOptions options = new IndexOptions();
        // 设置过滤条件
        options.partialFilterExpression(Filters.exists("name", true));
        // 创建索引
        return mongoTemplate.getCollection(COLLECTION_NAME).createIndex(Indexes.ascending(field), options);
    }

}
```

#### 4.9.2 查询索引

```java
import com.mongodb.client.ListIndexesIterable;
import lombok.extern.slf4j.Slf4j;
import org.bson.Document;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;
import java.util.ArrayList;
import java.util.List;

/**
 * 查询索引操作
 *
 * @author mydlq
 */
@Slf4j
@Service
public class QueryIndexService {

    /** 设置集合名称 */
    private static final String COLLECTION_NAME = "users";

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 获取当前【集合】对应的【所有索引】的【名称列表】
     *
     * @return 当前【集合】所有【索引名称列表】
     */
    public Object getIndexAll() {
        // 获取集合中所有列表
        ListIndexesIterable<Document> indexList = mongoTemplate.getCollection(COLLECTION_NAME).listIndexes();
        // 创建字符串集合
        List<Document> list = new ArrayList<>();
        // 获取集合中全部索引信息
        for (Document document : indexList) {
            log.info("索引列表：{}",document);
            list.add(document);
        }
        return list;
    }

}
```

#### 4.9.3 删除索引

```java
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;

@Slf4j
@Service
public class RemoveIndexService {

    @Resource
    private MongoTemplate mongoTemplate;

    /** 设置集合名称 */
    private static final String COLLECTION_NAME = "users";

    /**
     * 根据索引名称移除索引
     */
    public void removeIndex() {
        // 设置索引名称
        String indexName = "name_1";
        // 删除集合中某个索引
        mongoTemplate.getCollection(COLLECTION_NAME).dropIndex(indexName);
    }

    /**
     * 移除全部索引
     */
    public void removeIndexAll() {
        // 删除集合中全部索引
        mongoTemplate.getCollection(COLLECTION_NAME).dropIndexes();
    }

}
```

### 4.10 RunCommand 命令操作

```java
import org.bson.Document;
import org.bson.conversions.Bson;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Service;
import javax.annotation.Resource;

@Service
public class RunCommandService {

    @Resource
    private MongoTemplate mongoTemplate;

    /**
     * 执行 mongoDB 自定义命令，详情可以查看：https://docs.mongodb.com/manual/reference/command/
     *
     * @return 执行命令返回结果的 Json 结果
     * @description 执行自定义 mongoDB 命令
     */
    public Object runCommand() {
        // 自定义命令
        String jsonCommand = "{\"buildInfo\":1}";
        // 将 JSON 字符串解析成 MongoDB 命令
        Bson bson = Document.parse(jsonCommand);
        // 执行自定义命令
        return mongoTemplate.getDb().runCommand(bson);
    }

}
```

## 五. SpringBoot 引入 MongoDB 中的事务

> 注意：单节点 mongodb 不支持事务，需要搭建 MongoDB 复制集。

### 5.1 配置事务管理器

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.MongoDatabaseFactory;
import org.springframework.data.mongodb.MongoTransactionManager;

/**
 * 配置事务管理器
 *
 * @author mydlq
 */
@Configuration
public class TransactionConfig {

    @Bean
    MongoTransactionManager transactionManager(MongoDatabaseFactory dbFactory) {
        return new MongoTransactionManager(dbFactory);
    }

}
```

### 5.2 创建事务测试服务

```java
import mydlq.club.example.entity.Status;
import mydlq.club.example.entity.User;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import javax.annotation.Resource;
import java.util.Date;

@Service
public class TransactionExample {

    /** 设置集合名称 */
    private static final String COLLECTION_NAME = "users";

    @Resource
    private MongoTemplate mongoTemplate;

    @Transactional(rollbackFor = Exception.class)
    public Object transactionTest(){
        // 设置两个用户信息
        User user1 = new User()
                .setId("11")
                .setAge(22)
                .setSex("男")
                .setRemake("无")
                .setSalary(1500)
                .setName("shiyi")
                .setBirthday(new Date())
                .setStatus(new Status().setHeight(180).setWeight(150));
        // 插入数据
        User newUser1 = mongoTemplate.insert(user1, COLLECTION_NAME);
        // 抛出异常，观察数据是否进行回滚
        int error = 1/0;
        return newUser1;
    }

}
```

