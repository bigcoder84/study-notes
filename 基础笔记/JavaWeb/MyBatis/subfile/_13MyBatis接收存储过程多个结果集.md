# MyBatis接收存储过程多个结果集

```java
List<List<Map<String, Object>>> proc_qc_report_Summary_ErrKind_dept(@Param("hospCode") String hospCode,
                                                                        @Param("startDate") String startDate,
                                                                        @Param("endDate") String endDate,
                                                                        @Param("errorType") String errorType,
                                                                        @Param("dept") String dept,
                                                                        @Param("opCode") String opCode);
```

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd" >
<mapper namespace="cn.uni.app.mapper.CardQualityInfoMapper">

    <resultMap type="java.util.HashMap" id="ares1"></resultMap>
    <resultMap type="java.util.HashMap" id="ares2"></resultMap>

<select id="proc_qc_report_Summary_ErrKind_dept" resultMap="ares1,ares2">
        <![CDATA[
          exec  proc_qc_report_Summary_ErrKind_dept
            #{hospCode,mode=IN,jdbcType=VARCHAR},
			#{startDate,mode=IN,jdbcType=TIMESTAMP},
			#{endDate,mode=IN,jdbcType=TIMESTAMP},
			#{errorType,mode=IN,jdbcType=TIMESTAMP},
			#{dept,mode=IN,jdbcType=TIMESTAMP},
			#{opCode,mode=IN,jdbcType=VARCHAR}
           ]]>
    </select>
</mapper>
```

