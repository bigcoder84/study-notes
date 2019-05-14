## 由Spring的配置文件引出对xml文件的schema约束的理解

#### Spring配置文件的约束头

```xml
<?xml version="1.0" encoding="UTF-8"?>  
<beans xmlns="http://www.springframework.org/schema/beans"        
    xmlns:mvc="http://www.springframework.org/schema/mvc"     
    xmlns:tx="http://www.springframework.org/schema/tx"  
    xmlns:aop="http://www.springframework.org/schema/aop"  
    xmlns:context="http://www.springframework.org/schema/context"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"              
    xsi:schemaLocation="                                               
            http://www.springframework.org/schema/beans    
            http://www.springframework.org/schema/beans/spring-beans.xsd    
            http://www.springframework.org/schema/context     
            http://www.springframework.org/schema/context/spring-context.xsd    
            http://www.springframework.org/schema/mvc    
            http://www.springframework.org/schema/mvc/spring-mvc.xsd  
            http://www.springframework.org/schema/tx   
            http://www.springframework.org/schema/tx/spring-tx.xsd  
            http://www.springframework.org/schema/aop  
            http://www.springframework.org/schema/aop/spring-aop.xsd "  
    default-autowire="byName">  
</beans>  
```

​	上面是我们最常用的applicationContext.xml的配置文件的最开始部分，很多时候我们只是知道这些必须添加，但为什么，添加哪些都不甚清 楚。我们知道spring在启动的时候会验证 xml文档，这些引入的schema即用来验证配置文件的xml文档语法的正确性。下面先来看看如何验证xml文档验证的相关知识。

#### XML的schema约束

​	先来说说xml文档的schema约束，它定义了xml文档的结构，内容和语法，包括元素和属性、关系的结构以及数据类型等等。有以下几点需要遵循：

1. 所有的标签和属性都需要Schema来定义。（schema本身由w3c来定义）。
2. 所有的schema文件都需要以个ID，这里我们称之为 namespace，其值时一个url，通常是这个xml的xsd文件的地址。
3. namespace值由 targetNamespace属性来指定
4. 引入一个schema约束，使用属性xmlns，属性值即为对应schema文件的命名空间 nameSpace。
5. 如果引入的schema非w3c组织定义的，必须指定schema文件的位置，schema文件的位置由 schemaLocation来指定。
6. 引入多个schema文件需要使用 别名。别名形式如下： xmlns:alias。

#### 对于上述配置文件的详细解读

1. 声明默认的名称空间（xmlns="http://www.springframework.org/schema/beans"）

2. 声明XML Schema实例名称空间（http://www.w3.org/2001/XMLSchema-instance），并将xsi前缀与该名称空间绑定， 这样模式处理器就可以识别xsi:schemaLocation属性。XML Schema实例名称空间的前缀通常使用xsi

3. 使用xsi:schemaLocation属性指定名称空间（http://www.springframework.org/schema/beans） 和模式位置（http://www.springframework.org/schema/beans/spring-beans.xsd）相关。 XML Schema推荐标准中指出，xsi:schemaLocation属性可以在实例中的任何元素上使用，而不一定是根元素，不 过`xsi:schemaLocation`属性必须出现在它要验证的任何元素和属性之前。

4. 使用别名引入多个schema文件。如上述 xmlns:mvc 、xmlns:tx 、xmlns:context等等。

   



​	