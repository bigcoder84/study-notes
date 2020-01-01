# 动态SQL

## 1. 分支判断

## 1.1 if标签

有时候我们更新操作时，传入的POJO类的属性值可能部分是空值，通过if语句可以实现属性的动态更新，做到只更新传入的属性列。

```xml
<update id="updateByPrimaryKeySelective" parameterType="TUser">
	update t_user set
	<if test="userName != null">
		userName = #{userName,jdbcType=VARCHAR},
	</if>
	<if test="realName != null">
		realName = #{realName,jdbcType=VARCHAR},
	</if>
	<if test="sex != null">
		sex = #{sex,jdbcType=TINYINT},
	</if>
	<if test="mobile != null">
		mobile = #{mobile,jdbcType=VARCHAR},
	</if>
	<if test="email != null">
		email = #{email,jdbcType=VARCHAR},
	</if>
	<if test="note != null">
		note = #{note,jdbcType=VARCHAR},
	</if>
	<if test="position != null">
		position_id = #{position.id,jdbcType=INTEGER}
	</if>
	where id = #{id,jdbcType=INTEGER}
</update>
```

这么做我们有一个问题就是当`position`属性为null时，SQL语句后面会多出一个逗号，会导致执行失败，此时我们就需要借助set标签，或者trim标签。

### 1.2 choose, when, otherwise

前面的if标签主要用于单分支判断，如果需要多分支判断使用choose标签会更加方便。

```xml
<select id="findActiveBlogLike" resultType="Blog">
    SELECT * FROM BLOG WHERE state = ‘ACTIVE’
    <choose>
        <when test="title != null">
            AND title like #{title}
        </when>
        <when test="author != null and author.name != null">
            AND author_name like #{author.name}
        </when>
        <otherwise>
            AND featured = 1
        </otherwise>
    </choose>
</select>
```

满足任何一个when标签就跳出choose，如果所有when标签都不满足就执行otherwise。和编程语言中`if-elseif-else`类似。



## 2. 辅助标签

### 2.1 set标签

set标签用于前置set元素，会动态前置 SET 关键字，同时也会删掉结尾无关的逗号。

在1.1中，我们遗留了一个问题，如果最后一个判断返回false，那么拼接的SQL语句就会多出一个逗号，导致语句执行失败，我们可以采用set标签来解决这个问题。

```xml
<update id="updateByPrimaryKeySelective" parameterType="TUser">
	update t_user
	<set>
		<if test="userName != null">
			userName = #{userName,jdbcType=VARCHAR},
		</if>
		<if test="realName != null">
			realName = #{realName,jdbcType=VARCHAR},
		</if>
		<if test="sex != null">
			sex = #{sex,jdbcType=TINYINT},
		</if>
		<if test="mobile != null">
			mobile = #{mobile,jdbcType=VARCHAR},
		</if>
		<if test="email != null">
			email = #{email,jdbcType=VARCHAR},
		</if>
		<if test="note != null">
			note = #{note,jdbcType=VARCHAR},
		</if>
		<if test="position != null">
			position_id = #{position.id,jdbcType=INTEGER},
		</if>
	</set>
	where id = #{id,jdbcType=INTEGER}
</update>
```

### 2.2 where标签

*where* 元素只会在至少有一个子元素的条件返回 SQL 子句的情况下才去插入“WHERE”子句。而且，若语句的开头为“AND”或“OR”，*where* 元素也会将它们去除。

```xml
<select id="selectIfandWhereOper" resultMap="BaseResultMap">
	select
	<include refid="Base_Column_List" />
	from t_user a
	<where>
		<if test="email != null and email != ''">
			and a.email like CONCAT('%', #{email}, '%')
		</if>
		<if test="sex != null ">
			and a.sex = #{sex}
		</if>
	</where>
</select>
```



### 2.3 trim标签

trim标签是最大强大的辅助标签，实质上where和set标签都是trim的简写：

where：

```xml
<trim prefix="where" prefixOverrides="AND |OR "></trim>
```

set:

```xml
<trim prefix="set" suffixOverrides=","></trim>
```

如果我们动态插入数据，则也需要去除逗号问题：

```xml
<insert id="insertSelective" >
	insert into t_user
	<trim prefix="(" suffix=")" suffixOverrides="," >
		<if test="id != null">
			id,
		</if>
		<if test="userName != null">
			userName,
		</if>
		<if test="realName != null">
			realName,
		</if>
		<if test="sex != null">
			sex,
		</if>
		<if test="mobile != null">
			mobile,
		</if>
		<if test="email != null">
			email,
		</if>
		<if test="note != null">
			note,
		</if>
	</trim>
	<trim prefix="values (" suffix=")" suffixOverrides=",">
		<if test="id != null">
			#{id,jdbcType=INTEGER},
		</if>
		<if test="userName != null">
			#{userName,jdbcType=VARCHAR},
		</if>
		<if test="realName != null">
			#{realName,jdbcType=VARCHAR},
		</if>
		<if test="sex != null">
			#{sex,jdbcType=TINYINT},
		</if>
		<if test="mobile != null">
			#{mobile,jdbcType=VARCHAR},
		</if>
		<if test="email != null">
			#{email,jdbcType=VARCHAR},
		</if>
		<if test="note != null">
			#{note,jdbcType=VARCHAR},
		</if>
	</trim>
</insert>
```



## 3. 循环

```xml
<select id="selectPostIn" resultType="domain.blog.Post">
    SELECT *
    FROM POST P
    WHERE ID in
    <foreach item="item" index="index" collection="list" open="(" separator="," close=")">
        #{item}
    </foreach>
</select>
```

foreach 元素的功能非常强大，它允许你指定一个集合，声明可以在元素体内使用的集合项（item）和索引（index）变量。它也允许你指定开头与结尾的字符串以及在迭代结果之间放置分隔符。这个元素是很智能的，因此它不会偶然地附加多余的分隔符。

**注意**:你可以将任何可迭代对象（如 List、Set 等）、Map 对象或者数组对象传递给 *foreach* 作为集合参数。当使用可迭代对象或者数组时，index 是当前迭代的次数，item 的值是本次迭代获取的元素。当使用 Map 对象（或者 Map.Entry 对象的集合）时，index 是键，item 是值。

foreach还可用于批量插入的场景中：

```xml
<insert id="insertForeach4Batch" >
	insert into t_user (userName, realName, sex, mobile, email, note, position_id)
	values
	<foreach collection="list" separator="," item="user">
		(
		#{user.userName,jdbcType=VARCHAR},
		#{user.realName,jdbcType=VARCHAR},
		#{user.sex,jdbcType=TINYINT},
		#{user.mobile,jdbcType=VARCHAR},
		#{user.email,jdbcType=VARCHAR},
		#{user.note,jdbcType=VARCHAR},
		#{user.position.id,jdbcType=INTEGER}
		)
	</foreach>
</insert>
```

