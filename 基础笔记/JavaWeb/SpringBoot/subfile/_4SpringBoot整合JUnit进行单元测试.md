# SpringBoot整合JUnit进行单元测试

## 第一步：导入jar包

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

## 第二步：编写测试类

```java
@RunWith(SpringJUnit4ClassRunner.class)
@SpringBootTest(classes = SpringbootstudyApplication.class)
public class SpringbootstudyApplicationTests {

    @Autowired
    private UserMapper userMapper;
    @Test
    public void contextLoads() {
        User user = userMapper.getUserById(1L);
        System.out.println(user);
    }

}
```