# SpringMVC处理全局异常

在使用Shiro权限控制框架后，如果使用注解在Controller控制访问的角色，如果权限不足，就会抛出`AuthorizationException`异常：

```java
@RequiresRoles({"admin"})//需要admin角色才能访问，否则抛出异常
@RequestMapping("/article/update/{id}.html")
public String toUpdateArticlePage(Model model, @PathVariable Long id) {
	List<BlogArticleCategory> categoryList = categoryService.getAllCategory();
	model.addAttribute("categoryList", categoryList);
	BlogArticle article = articleService.getArticleById(id);
	model.addAttribute("article", article);
	return "update-article";
}
```

我们需要全局的捕获该异常，然后跳转到权限不足的画面：

```java
@ControllerAdvice
public class GlobalExceptionResolver {

    /**
     * 处理AuthorizationException异常
     * @return
     */
    @ExceptionHandler(AuthorizationException.class)
    public String handlerException(){
        return "unauthorized";
    }
}
```

1. 通过 `@ControllerAdvice` 指定该类为 `Controller` 增强类。
2. 通过 `@ExceptionHandler` 自定捕获的异常类型。

如果需要返回JSON数据，可以采用@ResponseBody注解。