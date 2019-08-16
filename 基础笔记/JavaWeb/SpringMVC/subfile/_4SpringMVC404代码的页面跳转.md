## SpringMVC跳转到自定义404页面的三种方法

​	有时候我们并不想跳转到系统自定义的错误页面中，那么我们需要自定义页面并且实现它的跳转

#### 方法一：

​	在`web.xml`文件中的`<web-app>`节点下配置：

```xml
<error-page>
    <error-code>404</error-code>
    <location>/WEB-INF/errors/404.jsp</location>
</error-page>
```

#### 方式二：

​	编写一个通用处理器，将所有没有匹配到确定处理器的请求，全部跳转到指定的404页面

```java
@RequestMapping("*")
public String test3(){
     return "404";
}
```

#### 方式三：

​	重写SpringMVC的核心过滤器的noHandlerFound方法，实现自定义的DispatcherServlet：

```xml
<servlet>
    <servlet-name>springmvc</servlet-name>
    <servlet-class>com.exceptionpage.test</servlet-class>
    <init-param>
      <param-name>contextConfigLocation</param-name>
      <param-value>classpath:spring-mvc.xml</param-value>
    </init-param>
  </servlet>
  <servlet-mapping>
    <servlet-name>springmvc</servlet-name>
    <url-pattern>/</url-pattern>
  </servlet-mapping>
```

​	controller类需要继承DispatcherServlet，并重写noHandlerFound方法

```java
@Override
    protected void noHandlerFound(HttpServletRequest request,
                                  HttpServletResponse response) throws Exception {
        System.out.println("successful execute...");
        response.sendRedirect(request.getContextPath() + "/notFound");
    }

    @RequestMapping("/notFound")
    public String test2(){
          System.out.println("successful...");
          return "404";
    }
```

​	若没有匹配上url，则调用noHandlerFound方法，并且重定向到一个新的方法，新的方法中跳转到404.jsp页面。