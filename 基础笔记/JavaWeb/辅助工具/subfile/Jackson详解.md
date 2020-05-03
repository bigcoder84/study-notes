# Jackson详解

Jackson是一个功能强大的Java序列化库。除了支持常用的json，同时还支持Smile，BSON，XML，CSV，YAML。

Jackson的json库提供了3种API：

- Streaming API ： 性能最好
- Tree Model ： 最灵活
- Data Binding ： 最方便

其中最常用到的就是Data Binding了，基本的用法如下

```java
ObjectMapper mapper = new ObjectMapper();
String json = mapper.writeValueAsString(foo);
Foo foo = mapper.readValue(json, Foo.class);
```

**ObjectMapper是线程安全的，应该尽量的重用**。

需要注意的是，Jackson是基于JavaBean来序列化属性的，如果属性没有GETTER方法，默认是不会输出该属性的。

但是在序列化的时候，经常会有特殊的需求来对输出的结果进行自定义。

比如不输出某几个属性，或者自定义属性的名字，等等。

## 一. 引入类库

```xml
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.9.7</version>
</dependency>
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-core</artifactId>
    <version>2.9.7</version>
</dependency>
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-annotations</artifactId>
    <version>2.9.7</version>
</dependency>
```

## 二. Data Binding

我们先创建两个实体封装类：

```java
public class Student {
    private String name;
    private Integer age;
    private List<Subject> subjects;
}
public class Subject {
    private Integer score;
    private String subjectName;
    @JsonFormat(pattern = "yyyy/MM/dd hh:mm:ss", locale = "zh", timezone = "GMT+8")
    private Date time;//考试时间
                                        
    public Subject(Integer score, String subjectName, Date time) {
        this.score = score;
        this.subjectName = subjectName;
        this.time = time;
    }
}
```

### 2.1 生成JSON字符串

```java
public void testDataBindingGenerate() throws JsonProcessingException {
    Student student = new Student();
    student.setName("张三");
    student.setAge(15);
    List<Subject> subjects = new ArrayList<>();
    student.setSubjects(subjects);
    subjects.add(new Subject(75, "数学", new Date()));
    subjects.add(new Subject(68, "语文", new Date()));
    subjects.add(new Subject(35, "英语", new Date()));
    ObjectMapper objectMapper = new ObjectMapper();
    String json = objectMapper.writeValueAsString(student);
    System.out.println(json);
}
```

### 2.2 解析JSON字符串

```java
public void testDataBindingParseJson() throws IOException {
    String json = "{\"name\":\"张三\",\"age\":15,\"subjects\":[{\"score\":75,\"subjectName\":\"数学\"," +
            "\"time\":\"2020/05/03 02:38:14\"},{\"score\":68,\"subjectName\":\"语文\",\"time\":\"2020/05/03 02:38:14\"},{\"score\":35,\"subjectName\":\"英语\",\"time\":\"2020/05/03 02:38:14\"}]}";
    ObjectMapper objectMapper = new ObjectMapper();
    Student student = objectMapper.readValue(json, Student.class);
    System.out.println(student);
}
```



## 三. Tree Model 

树模式在没有实体类封装时使用，它能将JSON字符串转换为`ObjectNode`的形式，其中`ObjectNode`可以嵌套其他的`ObjectNode`，也就是说复杂的JSON结构都能够轻松的转换为一个`ObjectNode`。而`ObjectNode`可以代表一个对象也可以代表一个数组。

### 3.1 生成JSON字符串

```java
public void testJSONGenerate() throws IOException {
    JsonNodeFactory jsonNodeFactory = JsonNodeFactory.instance;
    //JsonFactory 实例，线程安全
    JsonFactory jsonFactory = new JsonFactory();
    //根节点
    ObjectNode rootNode = jsonNodeFactory.objectNode();
    //往根节点中添加普通键值对
    rootNode.put("name", "aaa");
    rootNode.put("email", "aaa@aa.com");
    rootNode.put("age", 24);
    //往根节点中添加一个子对象
    ObjectNode petsNode = jsonNodeFactory.objectNode();
    petsNode.put("petName", "kitty")
            .put("petAge", 3);
    rootNode.set("pets", petsNode);
    //往根节点中添加一个数组
    ArrayNode arrayNode = jsonNodeFactory.arrayNode();
    arrayNode.add("java")
            .add("linux")
            .add("mysql");
    rootNode.set("skills", arrayNode);
    //调用ObjectMapper的writeTree方法根据节点生成最终json字符串
    JsonGenerator generator = jsonFactory.createGenerator(System.out);
    ObjectMapper objectMapper = new ObjectMapper();
    objectMapper.writeTree(generator, rootNode);
}
```

### 3.2 解析JSON字符串

```java
public void testJsonParse() throws IOException {
    String str = "{\"name\":\"aaa\",\"email\":\"aaa@aa.com\",\"age\":24,\"pets\":{\"petName\":\"kitty\",\"petAge\":3},\"skills\":[\"java\",\"linux\",\"mysql\"]}";
    ObjectMapper objectMapper = new ObjectMapper();
    //使用ObjectMapper的readValue方法将json字符串解析到JsonNode实例中
    JsonNode rootNode = objectMapper.readTree(str);
    JsonNode pets = rootNode.get("pets");
    System.out.println(pets);
}
```



## 四. Streaming API

### 4.1 生成JSON字符串

```java
 @Test
public void test() throws IOException {
    JsonFactory jfactory = new JsonFactory();

    /*** write to file ***/
    JsonGenerator jGenerator = jfactory.createGenerator(new File(
            "C:\\Users\\Lenovo\\Desktop\\Hello.json"),  JsonEncoding.UTF8);
    jGenerator.writeStartObject(); // {

    jGenerator.writeStringField("name", "mkyong"); // "name" : "mkyong"
    jGenerator.writeNumberField("age", 29); // "age" : 29

    jGenerator.writeFieldName("messages"); // "messages" :
    jGenerator.writeStartArray(); // [

    jGenerator.writeString("msg 1"); // "msg 1"
    jGenerator.writeString("msg 2"); // "msg 2"
    jGenerator.writeString("msg 3"); // "msg 3"

    jGenerator.writeEndArray(); // ]

    jGenerator.writeEndObject(); // }
    jGenerator.close();

}
```

### 4.2 解析JSON字符串

```java
@Test
public void test2() throws IOException {
    JsonFactory jfactory = new JsonFactory();
    /*** read from file ***/
    JsonParser jParser = jfactory.createParser(new File("C:\\Users\\Lenovo\\Desktop\\Hello.json"));
    // loop until token equal to "}"
    while (jParser.nextToken() != JsonToken.END_OBJECT) {

        String fieldname = jParser.getCurrentName();
        if ("name".equals(fieldname)) {

            // current token is "name",
            // move to next, which is "name"'s value
            jParser.nextToken();
            System.out.println(jParser.getText()); // display mkyong

        }

        if ("age".equals(fieldname)) {

            // current token is "age",
            // move to next, which is "name"'s value
            jParser.nextToken();
            System.out.println(jParser.getIntValue()); // display 29

        }

        if ("messages".equals(fieldname)) {

            jParser.nextToken(); // current token is "[", move next

            // messages is array, loop until token equal to "]"
            while (jParser.nextToken() != JsonToken.END_ARRAY) {

                // display msg1, msg2, msg3
                System.out.println(jParser.getText());

            }

        }

    }
    jParser.close();
}
```

