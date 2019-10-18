# Swagger

## 1. 认识Swagger

Swagger 是一个规范和完整的框架，用于生成、描述、调用和可视化 RESTful 风格的 Web 服务。总体目标是使客户端和文件系统作为服务器以同样的速度来更新。文件的方法，参数和模型紧密集成到服务器端的代码，允许API来始终保持同步。 

 **作用：**

  *1. 接口的文档在线自动生成。*

  *2. 功能测试。*

 **Swagger是一组开源项目，其中主要要项目如下：**

1.  **Swagger-tools**:提供各种与Swagger进行集成和交互的工具。例如模式检验、Swagger 1.2文档转换成Swagger 2.0文档等功能。

2. **Swagger-core**: 用于Java/Scala的的Swagger实现。与JAX-RS(Jersey、Resteasy、CXF...)、Servlets和Play框架进行集成。

3.  **Swagger-js**: 用于JavaScript的Swagger实现。

4. **Swagger-node-express**: Swagger模块，用于node.js的Express web应用框架。

5. **Swagger-ui**：一个无依赖的HTML、JS和CSS集合，可以为Swagger兼容API动态生成优雅文档。

6. **Swagger-codegen**：一个模板驱动引擎，通过分析用户Swagger资源声明以各种语言生成客户端代码。



## 2. SpringBoot搭建Swagger

### 2.1 Maven引入Swagger

```xml
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger2</artifactId>
    <version>2.2.2</version>
</dependency>

<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger-ui</artifactId>
    <version>2.2.2</version>
</dependency>
```

### 2.2 创建Swagger2配置类

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
 
import springfox.documentation.builders.ApiInfoBuilder;
import springfox.documentation.builders.PathSelectors;
import springfox.documentation.builders.RequestHandlerSelectors;
import springfox.documentation.service.ApiInfo;
import springfox.documentation.spi.DocumentationType;
import springfox.documentation.spring.web.plugins.Docket;
import springfox.documentation.swagger2.annotations.EnableSwagger2;
/**
 * Swagger2配置类
 * 在与spring boot集成时，放在与Application.java同级的目录下。
 * 通过@Configuration注解，让Spring来加载该类配置。
 * 再通过@EnableSwagger2注解来启用Swagger2。
 */
@Configuration
@EnableSwagger2
public class Swagger2 {
    
    /**
     * 创建API应用
     * apiInfo() 增加API相关信息
     * 通过select()函数返回一个ApiSelectorBuilder实例,用来控制哪些接口暴露给Swagger来展现，
     * 本例采用指定扫描的包路径来定义指定要建立API的目录。
     *
     * @return
     */
    @Bean
    public Docket createRestApi() {
        return new Docket(DocumentationType.SWAGGER_2)
                .apiInfo(apiInfo())
                .select()
                .apis(RequestHandlerSelectors.basePackage("com.swaggerTest.controller"))
                .paths(PathSelectors.any())
                .build();
    }
    
    /**
     * 创建该API的基本信息（这些基本信息会展现在文档页面中）
     * 访问地址：http://项目实际地址/swagger-ui.html
     * @return
     */
    private ApiInfo apiInfo() {
        return new ApiInfoBuilder()
                .title("Spring Boot中使用Swagger2构建RESTful APIs")
                .description("更多请关注http://www.baidu.com")
                .termsOfServiceUrl("http://www.baidu.com")
                .contact("sunf")
                .version("1.0")
                .build();
    }
}
```



## 3. Swagger的使用

### 3.1 常用注解

在完成了上述配置后，其实已经可以生产文档内容，但是这样的文档主要针对请求本身，描述的主要来源是函数的命名，对用户并不友好，我们通常需要自己增加一些说明来丰富文档内容。  **Swagger使用的注解及其说明：**

 @Api：用在类上，说明该类的作用。

@ApiOperation：注解来给API增加方法说明。

@ApiImplicitParams : 用在方法上包含一组参数说明。

@ApiImplicitParam：用来注解来给方法入参增加说明。

-  **paramType**：指定参数放在哪个地方 
-  name：参数名 
-  dataType：参数类型 
-  required：参数是否必须传 
-  value：说明参数的意思 
-  defaultValue：参数的默认值 

@ApiResponses：用于表示一组响应

@ApiResponse：用在@ApiResponses中，一般用于表达一个错误的响应信息

- **code**：数字，例如400
- **message**：信息，例如"请求参数没填好"
-  **response**：抛出异常的类  

@ApiModel：描述一个Model的信息（一般用在请求参数无法使用@ApiImplicitParam注解进行描述的时候）

- **@ApiModelProperty**：描述一个model的属性

### 3.2 案例

```java
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiParam;

import io.swagger.annotations.ApiResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.ehcache.EhCacheCacheManager;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import cn.uni.app.config.controller.AppBaseController;
import cn.uni.app.service.MemberService;
import cn.uni.common.core.dto.ListDto;

@RestController
@RequestMapping("/member")
@Api(description = "用户相关操作")

/**
 * 用户控制类
 * @author Mark
 *
 */
public class MemberController extends AppBaseController {

	@Autowired
	private MemberService memberService;
	@Autowired
	private EhCacheCacheManager cacheManager;
	
	
	@GetMapping("/getQueryProcBiMainMj")
	@ApiOperation("存储过程查询省市医院服务能力数据")
	public ListDto<Map<String, Object>> getQueryProcBiMainMj(
			@ApiParam("开始时间")@RequestParam(defaultValue="2018-01-01")String sdate,
			@ApiParam("结束时间")@RequestParam(defaultValue="2018-12-31")String edate) {
		return memberService.getQueryProcBiMainMj(sdate,edate);
	}
	
	@GetMapping("/getQueryProcBiMainZy")
	@ApiOperation("存储过程查询省市医院出院人次和机构数")
	public ListDto<Map<String, Object>> getQueryProcBiMainZy(
			@ApiParam("开始时间")@RequestParam(defaultValue="2018-01-01")String sdate,
			@ApiParam("结束时间")@RequestParam(defaultValue="2018-12-31")String edate) {
		return memberService.getQueryProcBiMainZy(sdate,edate);
	}
	
	
	@GetMapping("/identifyCode")
	@ApiOperation("获取验证码")
	public void identifyCode(HttpServletResponse response, HttpServletRequest request) {
	
	}
	

	
}

```



