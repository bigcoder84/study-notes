# Comparator静态方法

日常开发中我们经常会遇到集合排序的问题，而我们需要创建Comparator实例来定义排序的规则：

```java
package cn.bigcoder.moduletest._2Comparator;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * @author: Jindong.Tian
 * @date: 2020-10-11
 * @description:
 **/
public class Main {
    public static void main(String[] args) {
        List<Person> persons = buildPersonList();
        persons.sort((o1, o2) -> o2.getId() - o1.getId());
        System.out.println(persons);
    }

    private static List<Person> buildPersonList(){
        List<Person> results = new ArrayList<>();
        results.add(new Person(5,23));
        results.add(new Person(1,23));
        results.add(new Person(2,12));
        results.add(new Person(2,23));
        results.add(new Person(2,9));
        results.add(new Person(3,23));
        results.add(new Person(4,23));
        return results;
    }


    private static class Person{
        private Integer id;
        private Integer age;
		//...省略构造器以及Getter、Setter
    }
}

```

但是到了JDK8以后，Comparator接口新增了很多defualt方法：

```java
reversed() //反转排序规则
thenComparing() //多级排序
comparing() //构建正序排序的Comparator
```

这样我们可以优雅进行集合排序了：

```java
//根据ID正序排列，若ID相同这根据年龄逆序排列
persons.sort(Comparator.comparing(Person::getId).thenComparing(Comparator.comparing(Person::getAge).reversed()));
```

