# SpringBoot中Jackson的使用

### JSON转java对象

```java
  ObjectMapper mapper=new ObjectMapper();
  String json="{\"name\":\"zcq\",\"age\":1,\"birthday\":12}";
  Person person=mapper.readValue(json,Person.class);
```

#### java对象转JSON（序列化）

- writeValueAsString方法

```java
ObjectMapper mapper=new ObjectMapper();
Person person=new Person("21",12);
String json=mapper.writeValueAsString(person);
```

- writeValue(参数一,Object)方法，参数一可以是一下三种：
  -  File：将obj对象转换为JSON字符串，并保存到指定的文件中
  -  Writer：将obj对象转换为JSON字符串，并将json数据填充到字符输出流中
  -  OutputStream：将obj对象转换为JSON字符串，并将json数据填充到字节输出流中

## 相关注解

### @JsonFormat

```java
//pattern样式，locale表示在中国，timezone表示东八区
@JsonFormat(pattern = "yyyy/MM/dd", locale = "zh", timezone = "GMT+8") 
private Date birthday;
```

可以将属性值在转成json时格式化。

### @JsonIgnore

在序列化时（对象转JSON字符串）时，Jackson会忽略注解标注的字段。

### @JsonInclude

```java
@JsonInclude(JsonInclude.Include.NON_NULL)
private String name;
```

Jackson详细使用方法请见：[《Jackson详解》](../../辅助工具/subfile/Jackson详解.md)、[《Jackson注解》](../../辅助工具/subfile/Jackson注解.md)

