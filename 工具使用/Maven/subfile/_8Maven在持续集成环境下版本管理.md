# Maven在持续集成环境下版本管理

> 本文参考至：[Maven – Maven CI Friendly Versions (apache.org)](https://maven.apache.org/maven-ci-friendly.html)

从Maven 3.5.0-beta-1开始，你可以在pom文件中使用`${revision}` 、`${sha1}`、`${changelist}`作为版本的占位符。

## 一. 单模块应用

```xml
<project>
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.apache</groupId>
    <artifactId>apache</artifactId>
    <version>18</version>
  </parent>
  <groupId>org.apache.maven.ci</groupId>
  <artifactId>ci-parent</artifactId>
  <name>First CI Friendly</name>
  <version>${revision}</version>
  ...
</project>
```

当然，这是一种简单的情况，为了简单起见，我们只使用`${revision}`来展示一般的教程

基于以上pom，你可以使用下列命令来构建项目：

```shell
mvn clean package
```

但是这样会有一个问题，Maven不知道要为当前项目构建成什么版本，因此，您需要为项目定义版本。 第一种方式是使用这样的命令行：

```shell
mvn -Drevision=1.0.0-SNAPSHOT clean package
```

随着时间的推移，这将变得很麻烦，因为你每一次构建都需要带上这个版本参数。因此，另一种解决方案是在pom文件中添加一个`reversion`属性（peroperties）：

```xml
<project>
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.apache</groupId>
    <artifactId>apache</artifactId>
    <version>18</version>
  </parent>
  <groupId>org.apache.maven.ci</groupId>
  <artifactId>ci-parent</artifactId>
  <name>First CI Friendly</name>
  <version>${revision}</version>
  ...
  <properties>
    <revision>1.0.0-SNAPSHOT</revision>
  </properties>
</project>
```

这样看上去视乎不如直接将版本写到`<version>`标签中，但是在多模块项目中`<properties>`的标签是可以继承的，在后面多模块演示中会运用这一特性。

关于使用的属性的说明。你只能使用那些命名为`${revision}`，` ${sha1}`，`${changelist}`的属性，而不能使用其他命名的属性：

```xml
<project>
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.apache</groupId>
    <artifactId>apache</artifactId>
    <version>18</version>
  </parent>
  <groupId>org.apache.maven.ci</groupId>
  <artifactId>ci-parent</artifactId>
  <name>First CI Friendly</name>
  <version>${revision}</version>
  ...
  <properties>
    <revision>1.0.0-${buildNumber}-SNAPSHOT</revision>
  </properties>
</project>
```

上面的例子不会像预期的那样工作。如果您希望拥有更大的灵活性，您可以像这样使用不同属性的组合：

```xml
<project>
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.apache</groupId>
    <artifactId>apache</artifactId>
    <version>18</version>
  </parent>
  <groupId>org.apache.maven.ci</groupId>
  <artifactId>ci-parent</artifactId>
  <name>First CI Friendly</name>
  <version>${revision}${sha1}${changelist}</version>
  ...
  <properties>
    <revision>1.3.1</revision>
    <changelist>-SNAPSHOT</changelist>
    <sha1/>
  </properties>
</project>
```

如果您想制作`2.0.0-SNAPSHOT`，可以使用它来实现：

```shell
mvn -Drevision=2.0.0 clean package
```

如果你想构建1.3.1版本，可以使用它来实现：

```shell
mvn -Dchangelist= clean package
```

或者如果你想发布另一个版本：

```shell
mvn -Drevision=2.7.8 -Dchangelist= clean package
```

## 二. 多模块应用

所以现在让我们看看我们有一个多模块构建的情况。我们有一个父pom和一个或多个子模块。父pom看起来像这样：

```xml
<project>
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.apache</groupId>
    <artifactId>apache</artifactId>
    <version>18</version>
  </parent>
  <groupId>org.apache.maven.ci</groupId>
  <artifactId>ci-parent</artifactId>
  <name>First CI Friendly</name>
  <version>${revision}</version>
  ...
  <properties>
    <revision>1.0.0-SNAPSHOT</revision>
  </properties>
  <modules>
    <module>child1</module>
    ..
  </modules>
</project>
```

子模块看起来像这样：

```xml
<project>
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.apache.maven.ci</groupId>
    <artifactId>ci-parent</artifactId>
    <version>${revision}</version>
  </parent>
  <groupId>org.apache.maven.ci</groupId>
  <artifactId>ci-child</artifactId>
   ...
</project>
```

我们在子模块中使用继承至父POM的`reversion`属性去定义`<parent>`，这样我们需要更改项目的版本，只需要更改父POM中的`reversion`属性，那样所有的子模块依赖的父POM版本也会随之改变，由于子模块的版本又是继承于父POM，那么修改一个`reversion`属性就可以将整个项目的所有子模块版本更改。

## 三. 依赖管理

在多模块构建中，通常需要定义模块之间的依赖关系。定义依赖项及其相应版本的常用方法是使用`${project.version}`并没有改变。

所以正确的方法可以在下面的例子中看到:

```xml
<project>
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.apache</groupId>
    <artifactId>apache</artifactId>
    <version>18</version>
  </parent>
  <groupId>org.apache.maven.ci</groupId>
  <artifactId>ci-parent</artifactId>
  <name>First CI Friendly</name>
  <version>${revision}</version>
  ...
  <properties>
    <revision>1.0.0-SNAPSHOT</revision>
  </properties>
  <modules>
    <module>child1</module>
    ..
  </modules>
</project>
```

子模块定义：

```xml
<project>
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.apache.maven.ci</groupId>
    <artifactId>ci-parent</artifactId>
    <version>${revision}</version>
  </parent>
  <groupId>org.apache.maven.ci</groupId>
  <artifactId>ci-child</artifactId>
   ...
  <dependencies>
    <dependency>
      <groupId>org.apache.maven.ci</groupId>
      <!--ci-child依赖于child2模块，这里使用${project.version}代表引用当前项目的version-->
      <artifactId>child2</artifactId>
      <version>${project.version}</version>
    </dependency>
  </dependencies>
</project>
```

如果你尝试使用`${revision}`而不是`${project.version}`，您的构建将失败。

## 四. Install And Deploy

如果您想要使用上述设置来安装或部署项目，则必须配置`flat-maven-plugin`，否则Maven将不能正常运行：

```xml
<project>
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.apache</groupId>
    <artifactId>apache</artifactId>
    <version>18</version>
  </parent>
  <groupId>org.apache.maven.ci</groupId>
  <artifactId>ci-parent</artifactId>
  <name>First CI Friendly</name>
  <version>${revision}</version>
  ...
  <properties>
    <revision>1.0.0-SNAPSHOT</revision>
  </properties>
 
 <build>
  <plugins>
    <plugin>
      <groupId>org.codehaus.mojo</groupId>
      <artifactId>flatten-maven-plugin</artifactId>
      <version>1.1.0</version>
      <configuration>
        <updatePomFile>true</updatePomFile>
        <flattenMode>resolveCiFriendliesOnly</flattenMode>
      </configuration>
      <executions>
        <execution>
          <id>flatten</id>
          <phase>process-resources</phase>
          <goals>
            <goal>flatten</goal>
          </goals>
        </execution>
        <execution>
          <id>flatten.clean</id>
          <phase>clean</phase>
          <goals>
            <goal>clean</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
  </build>
  <modules>
    <module>child1</module>
    ..
  </modules>
</project>
```

