# Spring事务回滚

在注解式事务中我们只需要在类或方法上面加上@Transactional注解即可完成对方法的事务控制。

**默认情况下**：

- 程序抛出RuntimeException异常时，事务会发生回滚。
- 程序抛出Exception异常时，事务不发生会馆。

**如何改变spring的这种默认事务行为**？

-  添加@Transactional(noRollbackFor=RuntimeException.class)让spring对于RuntimeException不回滚事务。 
-  添加@Transactional(RollbackFor=Exception.class)让spring对于Exception进行事务的回滚。 

**需要注意的点**：

 @Transactional 注解应该只被应用到 public 可见度的方法上。 如果你在 protected、private 或者 package-visible 的方法上使用 @Transactional 注解，它也不会报错， 但是这个被注解的方法将不会展示已配置的事务设置。 

