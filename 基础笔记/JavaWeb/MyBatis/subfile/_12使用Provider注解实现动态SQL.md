# 使用Provider注解实现动态SQL

Mybatis3中增加了使用注解来配置Mapper的新特性，这里主要介绍@SelectProvider、@UpdateProvider、@InsertProvider和@DeleteProvider的使用方式。

这几个注解声明在Mapper对应的interface的方法上的，注解用于生成查询用的sql语句。如果对应的Mapper中已使用@Param来注解参数，则在对应的Prodiver的方法中无需写参数。

注解中参数：

- type：参数指定的Class类，必须要能够通过无参的构造函数来初始化；
- method：参数指定的方法，必须是public的，返回值必须为String，可以为static。

## 一、@SelectProvider

@ResultMap注解用于从查询结果集ResultSet中取数据然后拼装实体bean。

```java
public interface UserMapper {
     @SelectProvider(type = SqlProvider.class, method = "selectUser")
     @ResultMap("userMap")
     public User getUser(long userId);
}
```

```java
public class SqlProvider {
    public String selectUser(long userId){
         SELECT("id, name, email");
          FROM("USER");
          WHERE("ID = #{userId}");

    }
}
```

上例中定义了一个Mapper接口，其中定义了一个getUser方法，这个方法根据用户id来获取用户信息，并返回相应的User。而对应的SQL语句则写在SqlProvider类中。

## 二、@InsertProvider

```java
public interface UserMapper {
    @InsertProvider(type = SqlProvider.class, method = "addUser")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    int addUser(Tutor tutor);
}
```

```java
public class SqlProvider {
    public String addUser(User user) {
        return new SQL() {
            {
                INSERT_INTO("USER");
                if (user.getName() != null) {
                    VALUES("NAME", "#{name}");
                }
                if (user.getEmail() != null) {
                    VALUES("EMAIL", "#{email}");
                }
            }
        }.toString();
    }
}
```

## 三、**@UpdateProvider**

```java
public interface UserMapper {
    @UpdateProvider(type = SqlProvider.class, method = "updateUser")
    int updateUser(User user);
}
```

```java
public class SqlProvider {
    public String updateUser(User user) {
        return new SQL() {
            {
                UPDATE("USER");
                if (user.getName() != null) {
                    SET("NAME = #{name}");
                }
                if (user.getEmail() != null) {
                    SET("EMAIL = #{email}");
                }
                WHERE("ID= #{id}");
            }
        }.toString();
    }
}
```

## 四、@DeleteProvider

```java
public interface UserMapper {
    @DeleteProvider(type = SqlProvider.class, method = "deleteUser")
    int deleteUser(int id);
}
```

```java
public class SqlProvider {
    public String deleteUser(int id) {
        return new SQL() {
            {
                DELETE_FROM("USER");
                WHERE("ID= #{id}");
            }
        }.toString();
    }
}
```

## 项目实践

在一次项目中，我需要导入一个excel文件，该文件每一行有两百多个字段，我需要根据数据库中保存的字段导入规则进行校验，校验成功后，我需要将存在的字段插入数据库中，如果两百多个字段我都在Mapper文件使用`<if>`动态标签的话，那不仅费时费力，还极难维护，所以我们就可以通过@InsertProvider标签，根据数据库中查询出来的字段规则，动态生成SQL语句：

```java
import cn.uni.app.entity.csv.ColumnInfo;
import cn.uni.app.utils.ValidUtil;
import org.apache.ibatis.jdbc.SQL;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Map;

public class HospMainSql {

    public String addJxkhMain(List<ColumnInfo> list, Map<String, Object> params, String isZy) {
        return new SQL() {
            {
                //isZy=0则将数据插入t_card_info_import中，否则插入t_card_info_import_zy
                if ("0".equals(isZy)) {
                    INSERT_INTO("t_card_info_import");
                } else {
                    INSERT_INTO("t_card_info_import_zy");
                }
                //遍历所有字段规则，如果需要导入的数据中包含该字段，则将该字段插入数据库
                for (ColumnInfo info : list) {
                    Boolean bool = params.containsKey(info.getColname());
                    if (bool) {
                        switch (info.getColtype()) {
                            //如果是字符串类型
                            case "C":
                                VALUES(info.getColname(), "'" + params.get(info.getColname()).toString() + "'");
                                break;
                            //如果是日期类型
                            case "D":
                                VALUES(info.getColname(), "'" + params.get(info.getColname()).toString() + "'");
                                break;
                            //如果是数值类型
                            case "N":
                                if (!StringUtils.isEmpty(params.get(info.getColname()).toString().trim())) {
                                    VALUES(info.getColname(), ValidUtil.isNumeric1(params.get(info.getColname()).toString()));
                                }
                                break;
                        }
                    }
                }
                /**
                 * 下面几个字段与业务无关，在ts_upload_column_info中无约束
                 */
                VALUES("hospcode", "'" + params.get("hospcode").toString() + "'");
                VALUES("hisid", "'" + params.get("hisid").toString() + "'");
                //调用数据库中编写的，newId()函数，生成suid
                VALUES("suid", "newid()");
                //判断是否存在UploadId
                Boolean tag = params.containsKey("UploadId");
                if (tag) {
                    VALUES("UploadId", "'" + params.get("UploadId").toString() + "'");
                }
            }
        }.toString();
    }
}
```



```java
public class ColumnInfo {
    private Integer colid;
    private String colname;//字段名
    private String coldesc;//字段描述
    private String coltype;//数据类型
    private Integer collen;//数据长度
    private Integer colprec;//数据精度（如果是decimal）
    private Character notnull;//是否能为空
    private Integer orderid;//排序权重
} 
```



文章转载至：<https://www.cnblogs.com/JoeyWong/p/9457118.html>