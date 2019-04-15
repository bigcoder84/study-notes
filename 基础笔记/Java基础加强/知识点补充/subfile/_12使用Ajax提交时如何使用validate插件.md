## 使用Ajax提交时validate插件如何手动校验

​	通常我们采用`<input type="submit">`提交表单，此时配置的validate插件就会自动进行校验，而如果我们使用Ajax提交这个表单，该如何继续使用validate提供的校验功能呢？

#### 方法一

​	我们可以为`submitHandler`属性配置一个函数，该函数在用户**点击提交按钮并校验通过后才会触发**，所以我们可以在这个函数中发起Ajax请求。

```html
<html lang="zh-CN">
<head>
<title>听到微笑的博客读者墙</title>
<style type="text/css">
.error {
	color: red;
	font-weight: 7;
	padding-left: 10px;
}
</style>
<script src="/js/jquery-2.1.4.min.js"></script>
</head>

<body class="user-select">
	<form id="form" class="form-horizontal" method="post">
		<input type="email" name="email" >
		<textarea id="content" name="content"></textarea>
		<button type="submit" >提交</button>
	</form>
	<script src="/js/jquery.validate.min.js"></script>
	<script>
		$(function() {
			$("#form").validate({
				submitHandler : function(form) { //验证通过后执行的方法
					var formData = $("#form").serialize();
					$.post(
						"${pageContext.request.contextPath}/user/message/add.action",
						formData,
						function(data) {
							//请求成功
						},
						"json"
					);
				},
				rules : {
					title : {
						"required" : true
					},
					email : {
						"required" : true,
						"email" : true
					},
					content : {
						"required" : true
					}
				},
				messages : {
					title : {
						"required" : "必填",
					},
					email : {
						"required" : "必填",
						"email" : "请输入正确的邮箱格式"
					},
					content : {
						"required" : "必填",
					}
				}
			});
		});
	</script>
</body>
</html>
```

#### 方法二

​	可以使用`valid()`方法进行手动校验：

```javascript
var tag = $("#form").valid();//返回true表示验证通过
if(tag){
    $.post(
   
    );
}
```

