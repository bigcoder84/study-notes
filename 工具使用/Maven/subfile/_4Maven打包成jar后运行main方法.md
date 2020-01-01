# Maven打包成jar后运行main方法

```xml
<build>
        <plugins>
            <plugin>
                <artifactId>maven-assembly-plugin</artifactId>
                <configuration>
                    <appendAssemblyId>false</appendAssemblyId>
                    <descriptorRefs>
                        <descriptorRef>jar-with-dependencies</descriptorRef>
                    </descriptorRefs>
                    <archive>
                        <manifest>
                            <mainClass>RunJob</mainClass>
                        </manifest>
                    </archive>
                </configuration>
                <executions>
                    <execution>
                        <id>make-assembly</id>
                        <phase>package</phase>
                        <goals>
                            <goal>assembly</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
```

其中`<mainClass>RunJob</mainClass>`填写含有Main的class名，然后执行以下命令：

```java
mvn assembly:assembly
```

打包成功后会把所有依赖Jar的class打在一个jar包中。使用以下命令运行jar，参数依次跟在后面，如果有的话:

```java
java -jar BuildKettleJob-1.0.jar 
```



文章转载至：<https://www.cnblogs.com/maxiaofang/p/6254392.html>

