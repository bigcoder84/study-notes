## 方式一：

在SqlMapConfig.xml，配置如下信息：

```xml
<settings>
	<setting name="logImpl" value="STDOUT_LOGGING" />
</settings>
```

logImpl属性用于指定MyBatis 所用日志的具体实现，未指定时将自动查找。

属性值：SLF4J | LOG4J | LOG4J2 | JDK_LOGGING | COMMONS_LOGGING | STDOUT_LOGGING | NO_LOGGING

参考至：[mybatis的setting配置](https://blog.csdn.net/u014231523/article/details/53056032)

## 方式二：

新建log4j.properties，配置如下：

```shell
log4j.rootLogger=debug,stdout,logfile
 
###把日志输出到控制台###
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
#log4j.appender.stdout.Target=System.err
log4j.appender.stdout.layout=org.apache.log4j.SimpleLayout
 
### 把日志信息输出到文件:jbit.log ###
 
log4j.appender.logfile=org.apache.log4j.FileAppender
log4j.appender.logfile.File=jbit.log
log4j.appender.logfile.layout=org.apache.log4j.PatternLayout
log4j.appender.logfile.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss} %F %p %m%n
###显示sql语句
log4j.logger.com.mybatis=DEBUG
log4j.logger.com.mybatis.common.jdbc.SimpleDataSource=DEBUG
log4j.logger.com.mybatis.common.jdbc.ScriptRunner=DEBUG
log4j.logger.com.mybatis.sqlmap.engine.impl.SqlMapClientDelegate=DEBUG
log4j.logger.java.sql.Connection=DEBUG
log4j.logger.java.sql.Statement=DEBUG
log4j.logger.java.sql.PreparedStatement=DEBUG
```

