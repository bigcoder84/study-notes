# Jackson常用注解

> 本文转载至：<https://blog.csdn.net/blwinner/article/details/98532847>

【翻译】<https://www.baeldung.com/jackson-annotations>
<https://www.baeldung.com/jackson-advanced-annotations>

## 一. 序列化注解

### 1.1 @JsonAnyGetter

该注解用于把可变的`Map`类型属性当做标准属性。
下例中，`ExtendableBean`实体有一个`name`属性和一组`kay/value`格式的可扩展属性:

```java
class ExtendableBean {
    public String name;
    public Map<String, String> properties;
    @JsonAnyGetter
    public Map<String, String> getProperties() {
        return properties;
    }
    public ExtendableBean(String name) {
        this.name = name;
        properties = new HashMap<>();
    }
    public void add(String key, String value){
        properties.put(key, value);
    }
}
```

**说明:** `name`属性访问级别是`public`, 是为了省略`get/set`方法, 简化示例，下面是把`ExtendableBean`实体序列化的过程:

```java
private static void whenSerializingUsingJsonAnyGetter_thenCorrect(){
        ExtendableBean bean = new ExtendableBean("My bean");
        bean.add("attr1", "val1");
        bean.add("attr2", "val2");
        String result = null;
        try {
            result = new ObjectMapper().writeValueAsString(bean);
        } catch (JsonProcessingException e) {
            e.printStackTrace();
        }
        System.out.println(result);
    }
```

序列化后的结果: `{"name":"My bean","attr2":"val2","attr1":"val1"}`

### 1.2 @JsonGetter

该注解是`@JsonProperty`的两个作用中的一个, 用来标记一个方法是`getter`方法。下例中, 指定方法`getTheName()`是属性`name`属性的`getter`方法

```java
public class MyBean {
    public int id;
    private String name;
 
    @JsonGetter("name")
    public String getTheName() {
        return name;
    }
}
```

下面是序列化过程:

```java
public void whenSerializingUsingJsonGetter_thenCorrect()
  throws JsonProcessingException {
    MyBean bean = new MyBean(1, "My bean");
    String result = new ObjectMapper().writeValueAsString(bean);
}
```

### 1.3 @JsonPropertyOrder

该注解可以指定实体属性序列化后的顺序

```java
@JsonPropertyOrder({ "name", "id" })
public class MyBean {
    public int id;
    public String name;
}
```

- 序列化后的结果:`{ "name":"My bean", "id":1}`
- 该注解有一个参数`alphabetic`, 如果为`true`, 表示按字母顺序序列化,此时输出结果:`{ "id":1, "name":"My bean"}`

### 1.4 @JsonRawValue

该注解可以让Jackson在序列化时把属性的值原样输出

下面的例子中, 我们给实体属性`attrs`赋值一个json字符串

```java
public class RawBean {
    public String name;
    @JsonRawValue
    public String attrs;
}
public void whenSerializingUsingJsonRawValue_thenCorrect()
  throws JsonProcessingException {  
    RawBean bean = new RawBean("My bean", "{\"attr\":false}");
    String result = new ObjectMapper().writeValueAsString(bean);
}
```

输出结果是: `{"name":"Mybean","attrs":{"attr":false}}`

### 1.5 @JsonValue

该注解作用于一个方法, 并且只用被注解的方法序列化整个实体对象。把1.1的实体例修改如下:

```java
class ExtendableBean {
   ...........
   //把注解换成JsonValue
    @JsonValue
    public Map<String, String> getProperties() {
        return properties;
    }
	..........
}
```

序列化过程不变, 则结果是: `{"attr2":"val2","attr1":"val1"}`

**可见, 属性name没有被序列化**

### 1.6 @JsonSerialize

该注解用于指定一个自定义序列化器(`custom serializer`)来序列化实体例的某属性

下例中, 用`@JsonSerialize`的参数`using`指明实体类属性`eventDate`的序列化器是`CustomDateSerializer`类:

```java
public class Event {
    public String name;
 
    @JsonSerialize(using = CustomDateSerializer.class)
    public Date eventDate;
}
```

下面是类`CustomDateSerializer`的定义:

```java
public class CustomDateSerializer extends StdSerializer<Date> {
    private static SimpleDateFormat formatter = new SimpleDateFormat("dd-MM-yyyy hh:mm:ss");
    public CustomDateSerializer() { this(null); } 
    public CustomDateSerializer(Class<Date> t) { super(t); }
    @Override
    public void serialize(Date value, JsonGenerator gen, SerializerProvider arg2) 
    	throws IOException, JsonProcessingException {
        gen.writeString(formatter.format(value));
    }
}
```

序列化:

```java
public void whenSerializingUsingJsonSerialize_thenCorrect(){
	SimpleDateFormat df = new SimpleDateFormat("yyyy/MM/DD hh:mm:ss");
	String toParse = "2019/08/19 16:28:00";
	Date date = null;
	try {
	    date = df.parse(toParse);
	} catch (ParseException e) {
	    e.printStackTrace();
	}
	Event event = new Event();
	event.name = "party";
	event.eventDate = date;
	try {
	    String result = new ObjectMapper().writeValueAsString(event);
	    System.out.println(result);
	} catch (JsonProcessingException e) {
	    e.printStackTrace();
	}
}
```

序列化结果: `{"name":"party","eventDate":"2019-08-19 04:28:00"}`
而如果没有`@JsonSerialize`注解的序列化结果是: `{"name":"party","eventDate":1566203280000}`

## 二. 反序列化注解

该注解可以调整反序列化时`构造器/构造工厂`的行为

当我们需要反序列化的Json字符串和目标实体类不完全匹配时, 这个注解非常有用

假设我们要反序列化下面的Json字符串:

```java
{
    "id":1,
    "theName":"My bean"
}
```

但是, 我们的目标实体类并没有一个名为`theName`的属性. 现在, 我们不想改变实体类本身, 我们只需在数据导出时做一些控制, 方法就是在构造器中使用`@JsonCreator`和`@JsonProperty`注解:

```java
public class BeanWithCreator {
    public int id;
    public String name;
 
    @JsonCreator
    public BeanWithCreator(
      @JsonProperty("id") int id, 
      @JsonProperty("theName") String name) {
        this.id = id;
        this.name = name;
    }
}
```

反序列化过程:

```java
public void whenDeserializingUsingJsonCreator_thenCorrect()  throws IOException {
    String json = "{\"id\":1,\"theName\":\"My bean\"}";
    BeanWithCreator bean = new ObjectMapper().readerFor(BeanWithCreator.class).readValue(json);
    assertEquals("My bean", bean.name);
}
```

### 2.2 @JacksonInject

该注解指明一个属性的值是通过注入得到而不是从Json字符串反序列得到

下例的实体例属性`id`的值用注解标明是注入值:

```java
public class BeanWithInject {
    @JacksonInject
    public int id;
     
    public String name;
}
```

反序列化过程:

```java
public void whenDeserializingUsingJsonInject_thenCorrect() throws IOException {
    String json = "{\"name\":\"My bean\"}";     
    InjectableValues inject = new InjectableValues.Std().addValue(int.class, 1);
    BeanWithInject bean = new ObjectMapper().reader(inject).forType(BeanWithInject.class).readValue(json);     
    assertEquals("My bean", bean.name);
    assertEquals(1, bean.id);
}
```

### 2.3 @JsonAnySetter

该注解允许我们把一个可变的`map`属性作为标准属性, 在反序列过程中, 从Json字符串得到的属性值会加入到`map`属性中。
实体例和注解:

```java
public class ExtendableBean {
    public String name;
    private Map<String, String> properties;
 
    @JsonAnySetter
    public void add(String key, String value) {
        properties.put(key, value);
    }
}
```

准备反序列化的Json字符串:

```java
{
    "name":"My bean",
    "attr2":"val2",
    "attr1":"val1"
}
```

反序列化过程:

```java
public void whenDeserializingUsingJsonAnySetter_thenCorrect()  throws IOException {
    String json = "{\"name\":\"My bean\",\"attr2\":\"val2\",\"attr1\":\"val1\"}"; 
    ExtendableBean bean = new ObjectMapper().readerFor(ExtendableBean.class).readValue(json);     
    assertEquals("My bean", bean.name);
    assertEquals("val2", bean.getProperties().get("attr2"));
}
```

### 2.4 @JsonSetter

该注解是`@JsonProperty`的另一个作用, 和`@JsonGetter`相对, 标记一个方法是`setter`方法

如果目标实体类没有和Json字符串数据完全匹配的方法时, 我们可以通过这个注解做一些调整让他们匹配

下例中指定方法`setTheName()`作为`name`属性的setter方法

```java
public class MyBean {
    public int id;
    private String name;
 
    @JsonSetter("name")
    public void setTheName(String name) {
        this.name = name;
    }
}
```

反序列化过程:

```java
public void whenDeserializingUsingJsonSetter_thenCorrect()  throws IOException {  
    String json = "{\"id\":1,\"name\":\"My bean\"}"; 
    MyBean bean = new ObjectMapper().readerFor(MyBean.class).readValue(json);
    assertEquals("My bean", bean.getTheName());
}
```

### 2.5 @JsonDeserialize

该注解标明使用自定义反序列化器(`custom deserializer`)
实体类:

```public class Event {
public class Event {
    public String name;
 
    @JsonDeserialize(using = CustomDateDeserializer.class)
    public Date eventDate;
}
```

自定义反序列化器:

```java
public class CustomDateDeserializer  extends StdDeserializer<Date> { 
    private static SimpleDateFormat formatter = new SimpleDateFormat("dd-MM-yyyy hh:mm:ss");
     public CustomDateDeserializer() { 
        this(null); 
    }  
    public CustomDateDeserializer(Class<?> vc) { 
        super(vc); 
    }
    @Override
    public Date deserialize(JsonParser jsonparser, DeserializationContext context) throws IOException {         
        String date = jsonparser.getText();
        try {
            return formatter.parse(date);
        } catch (ParseException e) {
            throw new RuntimeException(e);
        }
    }
}
```

反序列过程:

```java
public void whenDeserializingUsingJsonDeserialize_thenCorrect()  throws IOException {  
    String json = "{"name":"party","eventDate":"20-12-2014 02:30:00"}"; 
    SimpleDateFormat df = new SimpleDateFormat("dd-MM-yyyy hh:mm:ss");
    Event event = new ObjectMapper().readerFor(Event.class).readValue(json);     
    assertEquals("20-12-2014 02:30:00", df.format(event.eventDate));
}
```

### 2.6 @JsonAlias

该注解在反序列化过程中为属性定义一个或多个别名

实体类:

```java
public class AliasBean {
    @JsonAlias({ "fName", "f_name" })
    private String firstName;   
    private String lastName;
}
```

Json字符串中`fName`, `f_name`或`firstName`的值都可以被反序列到属性`firstName`

```java
public void whenDeserializingUsingJsonAlias_thenCorrect() throws IOException {
    String json = "{\"fName\": \"John\", \"lastName\": \"Green\"}";
    AliasBean aliasBean = new ObjectMapper().readerFor(AliasBean.class).readValue(json);
    assertEquals("John", aliasBean.getFirstName());
}
```



## 三. 属性包含注解

### 3.1 @JsonIgnoreProperties

该注解是一个**类级别**的注解, 标记一个或多个属性被Jackson**忽略**

实体类:

```java
@JsonIgnoreProperties({ "id" })
public class BeanWithIgnore {
    public int id;
    public String name;
}
```

序列化过程:

```java
public void whenSerializingUsingJsonIgnoreProperties_thenCorrect()  throws JsonProcessingException {  
    BeanWithIgnore bean = new BeanWithIgnore(1, "My bean"); 
    String result = new ObjectMapper().writeValueAsString(bean);     
    assertThat(result, containsString("My bean"));
    assertThat(result, not(containsString("id")));
}
```

参数`ignoreUnknown`为`true`时, Json字符串如果有未知的属性名, 则不会抛出异常

### 3.2 @JsonIgnore

该注解用于**属性级别**, 用于标明一个属性可以被Jackson**忽略**

实体类:

```java
public class BeanWithIgnore {
    @JsonIgnore
    public int id;
 
    public String name;
}
```

序列化过程:

```java
public void whenSerializingUsingJsonIgnore_thenCorrect()
  throws JsonProcessingException {
  
    BeanWithIgnore bean = new BeanWithIgnore(1, "My bean");
 
    String result = new ObjectMapper()
      .writeValueAsString(bean);
     
    assertThat(result, containsString("My bean"));
    assertThat(result, not(containsString("id")));
}
```

### 3.3 @JsonIgnoreType

该注解标记类型是注解作用的类型的属性都会被忽略

**必须作用于类, 标明以该类为类型的属性都会被Jackson忽略**

实体类:

```java
public class User {
    public int id;
    public Name name;
 
    @JsonIgnoreType
    public static class Name {
        public String firstName;
        public String lastName;
    }
}
```

序列化过程:

```java
public void whenSerializingUsingJsonIgnoreType_thenCorrect()  throws JsonProcessingException, ParseException {  
    User.Name name = new User.Name("John", "Doe");
    User user = new User(1, name); 
    String result = new ObjectMapper().writeValueAsString(user); 
    assertThat(result, containsString("1"));
    assertThat(result, not(containsString("name")));
    assertThat(result, not(containsString("John")));
}
```

### 3.4 @JsonInclude

该注解在序列化时会排除属性值是空值（empty或null）、没有默认值的属性。

**可作用在类和属性上**

```java
@JsonInclude(Include.NON_NULL)
public class MyBean {
    public int id;
    public String name;
}
```

序列化过程:

```java
public void whenSerializingUsingJsonInclude_thenCorrect()  throws JsonProcessingException {  
    MyBean bean = new MyBean(1, null); 
    String result = new ObjectMapper().writeValueAsString(bean);     
    assertThat(result, containsString("1"));
    assertThat(result, not(containsString("name")));
}
```

### 3.5 @JsonAutoDetect

该注解可以覆盖属性是否可见的默认语义, 比如对于不可见的`private`序列化时变成可见的

实体类:

```java
@JsonAutoDetect(fieldVisibility = Visibility.ANY)
public class PrivateBean {
    private int id;
    private String name;
}
```

序列化过程:

```java
public void whenSerializingUsingJsonAutoDetect_thenCorrect()  throws JsonProcessingException {
    PrivateBean bean = new PrivateBean(1, "My bean"); 
    String result = new ObjectMapper().writeValueAsString(bean);     
    assertThat(result, containsString("1"));
    assertThat(result, containsString("My bean"));
}
```

## 四. 常用注解

### 4.1 @JsonProperty

该注解可以指定属性在Json字符串中的名字

下例中在非标准的`setter`和`getter`方法上使用该注解, 可以成功序列化和反序列化

实体类:

```java
public class MyBean {
    public int id;
    private String name;
 
    @JsonProperty("name")
    public void setTheName(String name) {
        this.name = name;
    }
 
    @JsonProperty("name")
    public String getTheName() {
        return name;
    }
}
```

### 4.2 @JsonFormat

该注解指定序列化日期和时间时的格式

修改前面`1.7`的实体类:

```java
public class Event {
    public String name;
 
    @JsonFormat(pattern = "yyyy/MM/dd", locale = "zh", timezone = "GMT+8") 
    public Date eventDate;
}

```

### 4.3 @JsonUnwrapped

该注解指定值在序列化和反序列化时, 去除对应属性的外包装(根节点)

实体类:

```java
public class UnwrappedUser {
    public int id;
 
    @JsonUnwrapped
    public Name name;
 
    public static class Name {
        public String firstName;
        public String lastName;
    }
}
```

序列化过程:

```java
public void whenSerializingUsingJsonUnwrapped_thenCorrect()  throws JsonProcessingException, ParseException {
    UnwrappedUser.Name name = new UnwrappedUser.Name("John", "Doe");
    UnwrappedUser user = new UnwrappedUser(1, name); 
    String result = new ObjectMapper().writeValueAsString(user);     
    assertThat(result, containsString("John"));
    assertThat(result, not(containsString("name")));
}
```

序列化结果:

```java
{
    "id":1,
    "firstName":"John",
    "lastName":"Doe"
}
```

### 4.4 @JsonView

该注解指明属性序列化和反序列时的视图级别(View)

**视图类: 主要用于表明哪一级的实体类的属性会被序列化或反序列化**

```java
public class Views {
    public static class Public {}
    public static class Internal extends Public {}
}
```

实体类:

```java
class UserWithRoot {
    @JsonView(Views.Public.class)
    public int id;
    @JsonView(Views.Public.class)
    public String name;
    @JsonView(Views.Internal.class)
    public String school;
}
```

实例化过程:

```java
public void whenSerializingUsingJsonView_thenCorrect()
  throws JsonProcessingException {
    UserWithRoot user = new UserWithRoot();
    user.id = 1;
    user.name = "bl";
    user.school = "suide";
    try {
        System.out.println(new ObjectMapper().writerWithView(Views.Internal.class).writeValueAsString(user));
    } catch (JsonProcessingException e) {
        e.printStackTrace();
    }
}
```

本例中, `school`的视图级别是`View.Internal`类, 而序列化的映射器设定的视图显示级别是`Views.Public`类, 比`school`的类型高了一级, 所以序列化结果中没有`school`

```java
{"id":1,"name":"bl"}
```

而如果修改映射器的视图级别是`Views.Internal`类, 则序列化结果中包含`school`

```java
{"id":1,"name":"bl","school":"suide"}
```

### 4.5 @JsonManagedReference, @JsonBackReference

这两个注解配合使用, 可以解决两个不同类的属性的父子关系`(parent/child relationships`)和循环引用(`work around loops`)

使用`@JsonBackReference`可以在序列化时阻断循环引用, 原理是忽略被注解的属性, 否则会导致异常

本例中, 我们用这组注解来序列化`ItemWithRef`实体类:

```java
public class ItemWithRef {
    public int id;
    public String itemName;
 
    @JsonManagedReference
    public UserWithRef owner;
}
public class UserWithRef {
    public int id;
    public String name;
 
    @JsonBackReference
    public List<ItemWithRef> userItems;
}
```

序列化过程:

```java
public void whenSerializingUsingJacksonReferenceAnnotation_thenCorrect()  throws JsonProcessingException {
    UserWithRef user = new UserWithRef(1, "John");
    ItemWithRef item = new ItemWithRef(2, "book", user);
    user.addItem(item); 
    String result = new ObjectMapper().writeValueAsString(item); 
}
```

- 序列化结果:` {"id":2,"itemName":"book","owner":{"id":1,"name":"John"}}`

- 如果把注解对调并序列化user结果是: `{"id":1,"name":"John","userItems":[{"id":2,"itemName":"book"}]}`

### 4.6 @JsonIdentityInfo

该注解标明在序列化和反序列化一个值时, 该属性是否作为对象的**唯一标识**

**该特性可以有效的解除循环引用, 和`@JsonBackReference`的区别是循环引用的对象的一个属性, 可以作为该对象的唯一标识被序列化, 而`@JsonBackReference`的循环引用对象不会二次序列化**

```java
@JsonIdentityInfo(  generator = ObjectIdGenerators.PropertyGenerator.class,  property = "id")
public class ItemWithIdentity {
    public int id;
    public String itemName;
    public UserWithIdentity owner;
}

public class UserWithIdentity {
    public int id;
    public String name;
    public List<ItemWithIdentity> userItems;
}

```

实例化过程:

```java
public void whenSerializingUsingJsonIdentityInfo_thenCorrect()  throws JsonProcessingException {
    UserWithIdentity user = new UserWithIdentity(1, "John");
    ItemWithIdentity item = new ItemWithIdentity(2, "book", user);
    user.addItem(item); 
    String result = new ObjectMapper().writeValueAsString(item);
}
```

序列化结果:`{"id":2,"itemName":"book","owner":{"id":1,"name":"John","userItems":[2]}}`
这里循环引用对象是`ItemWithIdentity`, 当它作为`UserWithIdentity`的属性时, 指定它的id属性为其唯一标识序列化到`UserWithIdentity`当中

### 4.7 @JsonFilter

该注解可以在序列化时指定一个过滤器

下面为一个实体类指定一个过滤器:

```java
@JsonFilter("myFilter")
public class BeanWithFilter {
    public int id;
    public String name;
}
```

定义过滤器并进行序列化

```java
public void whenSerializingUsingJsonFilter_thenCorrect()  throws JsonProcessingException {
    BeanWithFilter bean = new BeanWithFilter(1, "My bean"); 
    FilterProvider filters = new SimpleFilterProvider().addFilter("myFilter",    
     						SimpleBeanPropertyFilter.filterOutAllExcept("name")); 
    String result = new ObjectMapper().writer(filters).writeValueAsString(bean);
}
```

序列化结果:`{"name":"My bean"}`

**这里添加了一个SimpleBeanPropertyFilter.filterOutAllExcept过滤器, 该过滤器的含义是除name属性外, 其他属性都被过滤掉(不序列化)**

## 五. 其他注解

### 5.1 @JsonAppend

该注解用来给一个被序列化的对象添加一个虚拟属性. 这个功能非常有用, 尤其是当我们想直接在Json字符串中添加额外的信息时, 不再需要修改类的定义. 举例来说, 它可以很方便的在Json文档中插入bean的版本信息, 而不需要bean提供对应的属性.

使用@JsonAppend注解的实体类:

```java
@JsonAppend(attrs = {@JsonAppend.Attr(value = "version")})
public class BeanWithAppend {
    private int id;
    private String name;
    // constructor, getters and setters
}
```

序列化过程:

```java
BeanWithAppend bean = new BeanWithAppend(2, "Bean With Append Annotation");
ObjectWriter writer = mapper.writerFor(BeanWithAppend.class).withAttribute("version", "1.0");
String jsonString = writer.writeValueAsString(bean);
```

序列化结果: `{ "id": 2, "name": "Bean With Append Annotation", "version": "1.0" }`

### 5.2 @JsonNaming

该注解用来在序列化时选择一个属性命名习惯来代替默认属性名. 注解参数value用来指定已有命名习惯, 或用户定义的命名习惯
除默认值(`value=LOWER_CAMEL_CASE`, 即驼峰命名法)外, Jackson库同时提供了4种内置的属性命名习惯:

- KEBAB_CASE: 属性名单词用短线分隔连接, 比如：hello-world
- LOWER_CASE: 属性名用小写字母而且没有分隔符, 比如：helloworld
- SNAKE_CASE: 属性名用小写字母而且用下划线做分隔符, 比如：hello_world
- UPPER_CAMEL_CASE: 属性名所有单词用大写开头而且没有分隔符, 比如：HelloWorld

下例中用`SNAKE_CASE`命名法, 将属性`beanName`名序列化为`bean_name`：

```java
@JsonNaming(PropertyNamingStrategy.SnakeCaseStrategy.class)
public class NamingBean {
    private int id;
    private String beanName;
    // constructor, getters and setters
}
```

序列化过程:

```java
NamingBean bean = new NamingBean(3, "Naming Bean");
String jsonString = mapper.writeValueAsString(bean);        
```

序列化结果: `{ "id": 3, "bean_name": "Naming Bean" }`

### 5.3 @JsonPropertyDescription

Jackson的独立模块JSON Schema提供了创建`Json信息表(Json schemas)`来描述Java的类型信息. 信息表可用于输出我们期望的序列化Java对象, 或者在反序列化前验证`Json文档(document)`

注解`@JsonPropertyDescription`允许把人类可读的描述信息, 附加在要创建的Json信息表的`description`属性

```java
public class PropertyDescriptionBean {
    private int id;
    @JsonPropertyDescription("This is a description of the name property")
    private String name;
    // getters and setters
}
```

序列化过程: 这里生成Json信息表的同时为它附加了`description`属性

```java
SchemaFactoryWrapper wrapper = new SchemaFactoryWrapper();
mapper.acceptJsonFormatVisitor(PropertyDescriptionBean.class, wrapper);
JsonSchema jsonSchema = wrapper.finalSchema();
String jsonString = mapper.writeValueAsString(jsonSchema);
```

序列化结果:

```java
{
    "type": "object",
    "id": "urn:jsonschema:com:baeldung:jackson:annotation:extra:PropertyDescriptionBean",
    "properties": 
    {
        "name": 
        {
            "type": "string",
            "description": "This is a description of the name property"
        },
 
        "id": 
        {
            "type": "integer"
        }
    }
}
```

### 5.4 @JsonPOJOBuilder

该注解用来配置一个`builder`类用于定制反序列化过程, 尤其是当Json文档中属性命名习惯和POJO类对象的属性不同.

准备反序列化的Json字符串: `{ "id": 5, "name": "POJO Builder Bean"}`

反序列化的目标类:

```java
@JsonDeserialize(builder = BeanBuilder.class)
public class POJOBuilderBean {
    private int identity;
    private String beanName;
    // constructor, getters and setters
}
```

**注意:**`BeanBuilder`是自定义bulider类, 参见下文.
可以看到, bean属性的名称和Json字符串中对应属性的名称不同. 这就是`@JsonPOJOBuilder`发挥作用的地方.
`@JsonPOJOBuilder`有两个参数:

- buildMethodName: 一个无参方法, 用来在绑定Json属性和bean属性后, 创建bean的实例
- withPrefix: 方法名前缀, 有该前缀的方法是用来匹配Json属性和bean的属性. 默认前缀是`with`
  下面是`BeanBuilder`类定义:

```java
@JsonPOJOBuilder(buildMethodName = "createBean", withPrefix = "construct")
public class BeanBuilder {
    private int idValue;
    private String nameValue;
 
    public BeanBuilder constructId(int id) {
        idValue = id;
        return this;
    }
 
    public BeanBuilder constructName(String name) {
        nameValue = name;
        return this;
    }
 
    public POJOBuilderBean createBean() {
        return new POJOBuilderBean(idValue, nameValue);
    }
}
```

上面的代码中, 我们配置了注解`@JsonPOJOBuilder`的参数, 用`createBean`方法作为`build`方法, 用`construct`前缀来匹配属性名

```java
String jsonString = "{\"id\":5,\"name\":\"POJO Builder Bean\"}";
POJOBuilderBean bean = mapper.readValue(jsonString, POJOBuilderBean.class);
```

### 5.5 @JsonTypeId

该注解作用于属性, 使得该属性不再是普通属性, 其值代表bean类的类型ID(`TypeId), 可以用它来描述多态时实体类对象的实际类型

```java
public class TypeIdBean {
    private int id;
    @JsonTypeId
    private String name;
 
    // constructor, getters and setters
}
```

序列化过程:

```java
mapper.enableDefaultTyping(DefaultTyping.NON_FINAL);
TypeIdBean bean = new TypeIdBean(6, "Type Id Bean");
String jsonString = mapper.writeValueAsString(bean);
```

序列化结果:`["Type Id Bean",{"id":6}]`

- mapper.enableDefaultTyping(DefaultTyping.NON_FINAL)的作用是在序列化结果中显示实体类类型属性
- 结果是一个Json对象, 其中"Type Id Bean"是实体类ID的描述, {"id":6}是类的属性值
  

## 六. 禁用Jackson注解

通过设置`MapperFeature.USE_ANNOTATIONS`可以禁用实体类上的Jackson注解

```java
@JsonInclude(Include.NON_NULL)
@JsonPropertyOrder({ "name", "id" })
public class MyBean {
    public int id;
    public String name;
}
```

序列化过程：

```java
public void whenDisablingAllAnnotations_thenAllDisabled()  throws IOException {
    MyBean bean = new MyBean(1, null); 
    ObjectMapper mapper = new ObjectMapper();
    mapper.disable(MapperFeature.USE_ANNOTATIONS);
    String result = mapper.writeValueAsString(bean);
}
```

- 序列化结果:`{ "id":1, "name":null}`
- 如果注释掉`mapper.disable(MapperFeature.USE_ANNOTATIONS);`, 则序列化结果是: `{"id":1}`

