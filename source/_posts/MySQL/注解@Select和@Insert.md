---
title: 注解@Select和@Insert
categories:
- MySQL
---
```
spring:
  datasource:
    url: jdbc:mysql://192.168.32.225:3306/seata_demo?characterEncoding=utf8&useUnicode=true&useSSL=false&serverTimezone=UTC&allowMultiQueries=true
    driver-class-name: com.mysql.cj.jdbc.Driver
    username: root
    password: hxr
```


```java
@Component
public interface MyUserDetailsServerMapper {

    /**
     * 根据用户名查询
     * @param username
     * @return
     */
    @Select("SELECT username,password " +
            "FROM tb_user " +
            "WHERE username=#{username}")
    MyUserDetails findByUsername(@Param("username") String username);

    /**
     * 根据用户名查询角色列表
     * @param username
     * @return
     */
    @Select("SELECT r.enname " +
            "FROM tb_role r " +
            "LEFT JOIN tb_user_role ur ON ur.role_id=r.id " +
            "LEFT JOIN tb_user u ON u.id=ur.user_id " +
            "WHERE u.username=#{username}")
    List<String> findRoleByUsername(@Param(value = "username") String username);

    /**
     * 根据用户角色查询权限
     * @param roleCodes
     * @return
     */
    @Select("<script> " +
            "SELECT url " +
            "FROM tb_permission p " +
            "LEFT JOIN tb_role_permission rp ON rp.permission_id=p.id " +
            "LEFT JOIN tb_role r ON r.id=rp.role_id " +
            "WHERE r.enname IN " +
            "<foreach collection='roleCodes' item='roleCode' open='(' separator=',' close=')'> " +
            "#{roleCode} " +
            "</foreach> " +
            "</script>")
    List<String> findAuthorityByRoleCodes(@Param(value = "roleCodes") List<String> roleCodes);

}
```
****
```java
public interface AppUserDao{

    @Options(useGeneratedKeys = true, keyProperty = "id")
    @Insert("insert into app_user(username,password,nickname,headImgUrl,phone,sex" +
            " values(#{username},#{password},#{nickname},#{headImgUrl},#{phone},#{sex}")
    int save(AppUser appUser);

    int update(AppUser appUser);

}
```
```xml
<update id="update">
  update app_user
  <set>
    <if test="password != null and password != ''">
      password = #{password,jdbcType=VARCHAR},
    </if>
    <if>
      nickname = #{nickname,jdbcType=VARCHAR},
    </if>
    <if test="headImgUrl != null and headImgUrl != ''">
      headImgUrl = #{headImgUrl,jdbcType=VARCHAR},
    </if>
    <if test="phone != null and phone != ''">
      phone = #{phone,jdbcType=VARCHAR},
    </if>
    <if test="sex != null and sex != ''">
      sex = #{sex,jdbcType=VARCHAR},
    </if>
  </set>
  where id = #{id,jdbcType=INTEGER}
</update>
```
