# MyBatis动态代理开发的理解

通常情况下，我们Mapper接口和对应的映射配置文件是放在同一个包中的，但是事实真的是这样吗？难道Mapper接口和映射配置文件就一定要放在一起吗？

## **MyBatis非动态代理开发**

在日常开发中我们或许都使用动态代理的方式，但是动态代理开发并不是MyBatis最基本的开发模式：

### **传统开发流程**

#### 第一步：在`resource/`目录下新建SqlMapConfig.xml文件：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE configuration
		PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
		"http://mybatis.org/dtd/mybatis-3-config.dtd">
<configuration>
	<environments default="development">
		<environment id="development">
			<transactionManager type="JDBC"/>
			<dataSource type="POOLED">
				<property name="driver" value="com.mysql.jdbc.Driver"/>
				<property name="url" value="jdbc:mysql://localhost:3306/test"/>
				<property name="username" value="root"/>
				<property name="password" value="980613"/>
			</dataSource>
		</environment>
	</environments>
	<mappers>
		<mapper resource="com/tjd/mapper/UserMapper.xml"></mapper>
	</mappers>
</configuration>
```

#### 第二步：在`com.tjd.mapper`包下创建映射文件：

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd" >
<mapper namespace="com.tjd.mapper.UserMapper">
    <select id="getUserById" resultType="com.tjd.pojo.User" parameterType="long">
        select * from user where uid = #{id}
    </select>
    <select id="getUserByName" resultType="com.tjd.pojo.User" parameterType="string" >
        select * from user where uname = #{name}
    </select>
</mapper>
```

走到这一步，MyBatis环境就搭建完成了，此时我们就需要开始进行数据库操作：

#### 第三步：使用MyBatis提供的API进行数据库操作

```java
public class MyBatisTest {
    @Test
    public void test() throws IOException {
        InputStream resource = Resources.getResourceAsStream("SqlMapConfig.xml");
        SqlSessionFactory sessionFactory = new SqlSessionFactoryBuilder().build(resource);
        SqlSession session = sessionFactory.openSession();
        Object o = session.selectOne("com.tjd.mapper.UserMapper.getUserById",1L);
    }
}
```

### **理解传统开发流程**

​	在非动态代理开发时，并不需要写什么Mapper接口，只需要配置映射文件，然后获取的SqlSeesion对象，通过该对象的selectOne或selectList方法进行数据库查询即可，而这些方法只需要传入SQL语句的ID即可执行相应的SQL语句，然后将结果映射为实体类。（注：通常我们会在ID前面加上映射文件的namespace，但是如果ID没有重复的情况下，是可以直接通过ID调用SQL语句）。

​	`需要注意的是，不进行动态代理开发时，在SqlMapConfig文件中只能使用<mapper resource>或<mapper url>进行映射文件的加载`。而由于使用resource指定的映射文件位置，所以映射文件实际上放在哪都无所谓，只要resource指向映射文件即可。

​	通常在这种开发模式中，我们仍然会创建Dao层代码，对数据库操作进行封装，但是其本质并没有变，就是MyBatis框架将映射文件的SQL语句加载进系统，然后通过获取的SqlSession对象执行指定的SQL语句，所以`在这种开发模式中，映射配置文件的位置、文件名、namespace、statement_id的填写格式并没有强制要求，唯一的要求就是每一个namespace+id可以唯一定位一个SQL语句`。



## **MyBatis动态代理开发**

在传统开发中，我们需要指定映射文件配置的SQL语句的ID才能执行SQL语句：

```java
User user = (User)session.selectOne("com.tjd.mapper.UserMapper.getUserById",1L); 
```

诚然，这种方式能够正常工作，并且对于使用旧版本 MyBatis 的用户来说也比较熟悉。不过现在有了一种更简洁的方式 ——动态代理开发，这种开发模式不仅可以执行更清晰和类型安全的代码，而且还不用担心易错的字符串字面值以及强制类型转换。

### **动态代理开发流程**

#### 第一步：创建Mapper接口

但是如果想要进行动态代理开发就需要满足动态代理开发的要求了，在传统开发模式中有没有Mapper接口都无所谓，但是由于采用的是动态代理开发，所以必须要一个接口：

```java
package com.tjd.mapper;
public interface UserMapper {
    User getUserById(Long id);
    User getUserByName(String name);
}
```

#### 第二步：创建映射配置文件

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd" >
<mapper namespace="com.tjd.mapper.UserMapper">
    <select id="getUserById" resultType="com.tjd.pojo.User" parameterType="long">
        select * from user where uid = #{id}
    </select>
    <select id="getUserByName" resultType="com.tjd.pojo.User" parameterType="string">
        select * from user where uname = #{name}
    </select>
</mapper>
```

`使用动态代理开发时，映射文件的namespace必须是Mapper接口的全限定类名，而SQL语句的ID必须与接口中的方法名一一对应`。但是映射文件名和映射文件的位置并没有强制要求，具体细节在后面讲解。

#### 第三步：配置MyBatis核心配置文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE configuration
		PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
		"http://mybatis.org/dtd/mybatis-3-config.dtd">
<configuration>

	<settings>
		<setting name="logImpl" value="STDOUT_LOGGING" />
	</settings>
	<typeAliases>
		<package name="com.tjd.spring_mybatis_plus.pojo"/>
	</typeAliases>

	<environments default="development">
		<environment id="development">
			<transactionManager type="JDBC"/>
			<dataSource type="POOLED">
				<property name="driver" value="com.mysql.jdbc.Driver"/>
				<property name="url" value="jdbc:mysql://localhost:3306/test"/>
				<property name="username" value="root"/>
				<property name="password" value="980613"/>
			</dataSource>
		</environment>
	</environments>
	<mappers>
		<mapper resource="com/tjd/spring_mybatis_plus/mapper/UserMapper.xml"></mapper>
		<!--<mapper class="com.tjd.spring_mybatis_plus.mapper.UserMapper"></mapper>-->
	</mappers>
</configuration>
```

在使用动态代理开发时，指定映射文件位置可以有四种模式：`<mapper resource>、<mapper url>、<mapper class>、<package>`，但是这四种配置模式对映射文件名和映射文件位置有着不同的影响，具体来说：

- 在使用`<mapper resource>、<mapper url>`时，映射文件可以放在任意地方，映射文件名可以任意取；

- 在使用`<mapper class>`和`<package>`时，映射文件必须与Mapper接口处于相同的包中，并且映射文件名和接口名相同。

#### 第四步：获取代理对象执行数据库操作

```java
public class MyBatisTest {
    @Test
    public void test() throws IOException {
        InputStream resource = Resources.getResourceAsStream("SqlMapConfig.xml");
        SqlSessionFactory sessionFactory = new SqlSessionFactoryBuilder().build(resource);
        SqlSession session = sessionFactory.openSession();
        //获取代理对象
        UserMapper mapper = session.getMapper(UserMapper.class);
        User userById = mapper.getUserById(1L);
    }
}
```



### 理解MyBatis动态代理开发

​	虽说是动态代理开发，但是实质的原理非常简单，就是MyBatis生成代理对象，在代理对象的方法中，会自动根据当前执行的方法名，然后定位到映射配置文件中配置的SQL语句。这就避免了我们使用字符串常量来调用SQL语句了，也避免了最后结果的强制类型转换。

​	在这种开发模式中，对映射配置文件有相应的要求：

- Mapper接口方法名和Mapper.xml中定义的SQL语句的ID一一对应。
- 映射配置文件的namespace与接口的全限定类名相同。
- Mapper接口方法的输入参数类型和mapper.xml中定义的每个sql 的parameterType的类型相同。
- Mapper接口方法的输出参数类型和mapper.xml中定义的每个sql的resultType的类型相同。

`但是对于映射配置文件位置和文件名的要求，取决于采用哪种模式加载配置文件(resource、url、class、package)。`



## Spring与MyBatis结合的动态代理开发

[MyBatis与Spring整合步骤](./_2MyBatis与Spring整合步骤.md)

