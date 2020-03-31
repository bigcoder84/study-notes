# MyBatis内部对象的生命周期

**SqlSessionFactoryBuilder**：读取配置文件信息，创建SqlSessionFactory，建造者模式，方法级别生命周期。

**SqlSessionFactory**：创建SqlSession，工厂单例模式，存在于程序的整个生命周期。

**SqlSession**：代表依次数据库连接，可以直接发送SQL执行，也可调用Mapper.xml中的SQL访问数据库，还可通过获取Mapper代理类对象访问数据库。**线程不安全，要保证线程独享**。

