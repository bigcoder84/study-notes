# SpringBoot热部署配置

### 第一步：在pom文件中引入spring-boot-devtools模块

```java
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
</dependency>
```



### 第二步：配置spring-boot-maven-plugin插件

```java
<plugins>
    <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
        <configuration>
            <!--如果没有该配置,devtools不会起作用-->
            <fork>true</fork>
        </configuration>
    </plugin>
</plugins>
```



配置完成后，我们修改源码或者配置文件项目会自动重启，但这种重启会比手动重启快很多。其深层原理是使用两个ClassLoader，一个ClassLoader加载那些不会改变的类（例如第三方jar包），另一个ClassLoader加载那些会改变的类，称为Restart ClassLoader。这样有代码更改的时候，原来Restart ClassLoader加载的类会被丢弃，而重新加载被更改的类，这样速度就会比手动重启更快。