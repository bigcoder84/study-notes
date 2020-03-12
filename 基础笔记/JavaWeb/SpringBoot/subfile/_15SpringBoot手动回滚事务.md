# SpringBoot手动回滚事务

手动回滚事务：

```java
 TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
```

案例：

```java
@Service("userService")
@Transactional  //事务的注解
public class UserServiceImpl implements UserService{
	@Autowired
	UserMapper userMapper;
	
	@Override
	public List<User> getAllUser() throws Exception {		
		try {
			List<User> list = userMapper.getAllUser();
			return list;
		} catch (Exception e) {
		//强制手动事务回滚
			 TransactionAspectSupport.currentTransactionStatus().setRollbackOnly();
		}
		return null;
	}
	
}
```

