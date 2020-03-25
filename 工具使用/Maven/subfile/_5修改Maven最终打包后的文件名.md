# 修改Maven最终打包后的文件名

maven默认的打包名是：项目名+版本号。在pom文件中可以自定义：

```xml
<build>
    <finalName>名称</finalName>
</build>
```

