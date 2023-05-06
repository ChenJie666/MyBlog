---
title: Azkaban整合LDAP（有点问题）
categories:
- 随笔
---
## 问题
报错：
```
2021/08/27 20:31:00.073 +0800 ERROR [StdOutErrRedirect] [Azkaban] Exception in thread "pool-9-thread-1" 
2021/08/27 20:31:00.074 +0800 ERROR [StdOutErrRedirect] [Azkaban] java.lang.IncompatibleClassChangeError: Class org.apache.mina.filter.codec.ProtocolCodecFilter does not implement the requested interface org.apache.mina.core.filterchain.IoFilter
2021/08/27 20:31:00.075 +0800 ERROR [StdOutErrRedirect] [Azkaban] 	at org.apache.mina.core.filterchain.DefaultIoFilterChain.register(DefaultIoFilterChain.java:463)
2021/08/27 20:31:00.075 +0800 ERROR [StdOutErrRedirect] [Azkaban] 	at org.apache.mina.core.filterchain.DefaultIoFilterChain.addLast(DefaultIoFilterChain.java:234)
2021/08/27 20:31:00.075 +0800 ERROR [StdOutErrRedirect] [Azkaban] 	at org.apache.mina.core.filterchain.DefaultIoFilterChainBuilder.buildFilterChain(DefaultIoFilterChainBuilder.java:553)
2021/08/27 20:31:00.076 +0800 ERROR [StdOutErrRedirect] [Azkaban] 	at org.apache.mina.core.polling.AbstractPollingIoProcessor$Processor.addNow(AbstractPollingIoProcessor.java:832)
2021/08/27 20:31:00.076 +0800 ERROR [StdOutErrRedirect] [Azkaban] 	at org.apache.mina.core.polling.AbstractPollingIoProcessor$Processor.handleNewSessions(AbstractPollingIoProcessor.java:752)
2021/08/27 20:31:00.076 +0800 ERROR [StdOutErrRedirect] [Azkaban] 	at org.apache.mina.core.polling.AbstractPollingIoProcessor$Processor.run(AbstractPollingIoProcessor.java:652)
2021/08/27 20:31:00.077 +0800 ERROR [StdOutErrRedirect] [Azkaban] 	at org.apache.mina.util.NamePreservingRunnable.run(NamePreservingRunnable.java:51)
2021/08/27 20:31:00.077 +0800 ERROR [StdOutErrRedirect] [Azkaban] 	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
2021/08/27 20:31:00.077 +0800 ERROR [StdOutErrRedirect] [Azkaban] 	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
2021/08/27 20:31:00.077 +0800 ERROR [StdOutErrRedirect] [Azkaban] 	at java.lang.Thread.run(Thread.java:748)
```

在依赖
```
        <dependency>
            <groupId>org.apache.mina</groupId>
            <artifactId>mina-core</artifactId>
            <version>2.1.3</version>
            <scope>compile</scope>
        </dependency>
```
中有ProtocolCodecFilter和IoFilter类，但是ProtocolCodecFilter已经继承了IoFilter接口的实现类IoFilterAdapter，所以为什么还是会报错ProtocolCodecFilter没有实现IoFilter接口？？？

## 步骤
查看[官网文档](https://azkaban.readthedocs.io/en/latest/userManager.html#custom-user-manager)，实现LDAP整合Azkaban，需要我们自己写类实现UserManager接口，将项目打成jar包放到指定目录下。

**依赖**
```
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>org.cj</groupId>
    <artifactId>azkaban-ldap</artifactId>
    <version>1.0.0</version>

    <dependencies>
        <dependency>
            <groupId>com.github.azkaban.azkaban</groupId>
            <artifactId>azkaban-common</artifactId>
            <version>3.16.0</version>
        </dependency>

        <!-- ldap测试 -->
        <dependency>
            <groupId>org.zapodot</groupId>
            <artifactId>embedded-ldap-junit</artifactId>
            <version>0.5.2</version>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>org.apache.directory.api</groupId>
            <artifactId>api-all</artifactId>
            <version>1.0.0</version>
            <exclusions>
                <exclusion>
                    <groupId>org.slf4j</groupId>
                    <artifactId>slf4j-api</artifactId>
                </exclusion>
                <exclusion>
                    <groupId>org.apache.mina</groupId>
                    <artifactId>mina-core</artifactId>
                </exclusion>
            </exclusions>
        </dependency>
        <dependency>
            <groupId>org.apache.mina</groupId>
            <artifactId>mina-core</artifactId>
            <version>2.1.3</version>
            <scope>compile</scope>
        </dependency>

        <!-- 日志 -->
        <dependency>
            <groupId>log4j</groupId>
            <artifactId>log4j</artifactId>
            <version>1.2.17</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <version>3.8.1</version>
                <configuration>
                    <target>1.8</target>
                    <source>1.8</source>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-assembly-plugin</artifactId>
                <version>3.1.1</version>
                <configuration>
                    <descriptorRefs>
                        <descriptorRef>jar-with-dependencies</descriptorRef>
                    </descriptorRefs>
                </configuration>
                <executions>
                    <execution>
                        <id>make-assembly</id>
                        <phase>package</phase>
                        <goals>
                            <goal>single</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```
这里有个坑，就是azkaban-common包一直下载失败。无奈只能网上下载jar包然后导入到Mavne本地仓库中，步骤如下：
①将maven的settings.xml文件中的repository仓库地址修改为idea中指定的repository的地址。（如果idea中配置的respository仓库地址就是setting.xml文件中配置的respository地址，可以忽略此步骤）
```
<localRepository>C:\Users\Administrator\.m2epository</localRepository>
```
②执行命令将本地jar包添加到repository仓库中
```
mvn install:install-file -DgroupId=com.github.azkaban.azkaban -DartifactId=azkaban-common -Dversion=3.16.0 -Dpackaging=jar -Dfile=./azkaban-common-3.16.0.jar
```
③查看仓库目录，可以发现已经导入了azkaban-common包。

**实现类**
```
import azkaban.user.*;
import azkaban.utils.Props;
import org.apache.directory.api.ldap.model.cursor.CursorException;
import org.apache.directory.api.ldap.model.cursor.EntryCursor;
import org.apache.directory.api.ldap.model.entry.Attribute;
import org.apache.directory.api.ldap.model.entry.Entry;
import org.apache.directory.api.ldap.model.entry.Value;
import org.apache.directory.api.ldap.model.exception.LdapException;
import org.apache.directory.api.ldap.model.filter.FilterEncoder;
import org.apache.directory.api.ldap.model.message.SearchScope;
import org.apache.directory.ldap.client.api.LdapConnection;
import org.apache.directory.ldap.client.api.LdapNetworkConnection;


import org.apache.log4j.Logger;

import java.io.IOException;
import java.util.List;

public class LdapUserManager implements UserManager {
    final static Logger logger = Logger.getLogger(UserManager.class);

    public static final String LDAP_HOST = "user.manager.ldap.host";
    public static final String LDAP_PORT = "user.manager.ldap.port";
    public static final String LDAP_USE_SSL = "user.manager.ldap.useSsl";
    public static final String LDAP_USER_BASE = "user.manager.ldap.userBase";
    public static final String LDAP_USERID_PROPERTY = "user.manager.ldap.userIdProperty";
    public static final String LDAP_EMAIL_PROPERTY = "user.manager.ldap.emailProperty";
    public static final String LDAP_BIND_ACCOUNT = "user.manager.ldap.bindAccount";
    public static final String LDAP_BIND_PASSWORD = "user.manager.ldap.bindPassword";
    public static final String LDAP_ALLOWED_GROUPS = "user.manager.ldap.allowedGroups";
    public static final String LDAP_ADMIN_GROUPS = "user.manager.ldap.adminGroups";
    public static final String LDAP_GROUP_SEARCH_BASE = "user.manager.ldap.groupSearchBase";
    public static final String LDAP_EMBEDDED_GROUPS = "user.manager.ldap.embeddedGroups";

    private String ldapHost;
    private int ldapPort;
    private boolean useSsl;
    private String ldapUserBase;
    private String ldapUserIdProperty;
    private String ldapUEmailProperty;
    private String ldapBindAccount;
    private String ldapBindPassword;
    private List<String> ldapAllowedGroups;
    private List<String> ldapAdminGroups;
    private String ldapGroupSearchBase;
    private boolean ldapEmbeddedGroups;

    public LdapUserManager(Props props) {
        ldapHost = props.getString(LDAP_HOST);
        ldapPort = props.getInt(LDAP_PORT);
        useSsl = props.getBoolean(LDAP_USE_SSL);
        ldapUserBase = props.getString(LDAP_USER_BASE);
        ldapUserIdProperty = props.getString(LDAP_USERID_PROPERTY);
        ldapUEmailProperty = props.getString(LDAP_EMAIL_PROPERTY);
        ldapBindAccount = props.getString(LDAP_BIND_ACCOUNT);
        ldapBindPassword = props.getString(LDAP_BIND_PASSWORD);
        ldapAllowedGroups = props.getStringList(LDAP_ALLOWED_GROUPS);
        ldapAdminGroups = props.getStringList(LDAP_ADMIN_GROUPS);
        ldapGroupSearchBase = props.getString(LDAP_GROUP_SEARCH_BASE);
        ldapEmbeddedGroups = props.getBoolean(LDAP_EMBEDDED_GROUPS, false);
    }

    @Override
    public User getUser(String username, String password) throws UserManagerException {
        if (username == null || username.trim().isEmpty()) {
            throw new UserManagerException("Username is empty.");
        } else if (password == null || password.trim().isEmpty()) {
            throw new UserManagerException("Password is empty.");
        }

        LdapConnection connection = null;
        EntryCursor result = null;

        try {
            connection = getLdapConnection();

            result = connection.search(
                    ldapUserBase,
                    "(" + escapeLDAPSearchFilter(ldapUserIdProperty + "=" + username) + ")",
                    SearchScope.SUBTREE
            );

            if (!result.next()) {
                throw new UserManagerException("No user " + username + " found");
            }

            final Entry entry = result.get();

            if (result.next()) {
                throw new UserManagerException("More than one user found");
            }

            if (!isMemberOfGroups(connection, entry, ldapAllowedGroups)) {
                throw new UserManagerException("User is not member of allowed groups");
            }

            connection.bind(entry.getDn(), password);

            Attribute idAttribute = entry.get(ldapUserIdProperty);
            Attribute emailAttribute = null;
            if (ldapUEmailProperty.length() > 0) {
                emailAttribute = entry.get(ldapUEmailProperty);
            }

            if (idAttribute == null) {
                throw new UserManagerException("Invalid id property name " + ldapUserIdProperty);
            }
            User user = new User(idAttribute.getString());
            if (emailAttribute != null) {
                user.setEmail(emailAttribute.getString());
            }

            if (isMemberOfGroups(connection, entry, ldapAdminGroups)) {
                logger.info("Granting admin access to user: " + username);
                user.addRole("admin");
            }

            return user;

        } catch (LdapException e) {
            throw new UserManagerException("LDAP error: " + e.getMessage(), e);
        } catch (CursorException e) {
            throw new UserManagerException("Cursor error", e);
        } finally {
            if (result != null) {
                try {
                    result.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (connection != null) {
                try {
                    connection.close();
                } catch (IOException e) {
                    throw new UserManagerException("IO error", e);
                }
            }
        }
    }

    /**
     * @return true, when user is member of provided list of expectedGroups or if expectedGroups is empty; false, otherwise
     */
    private boolean isMemberOfGroups(LdapConnection connection, Entry user, List<String> expectedGroups) throws CursorException, LdapException {
        if (expectedGroups.size() == 0) {
            return true;
        }
        if (ldapEmbeddedGroups) {
            Attribute groups = user.get("memberof");
            for (String expectedGroupName : expectedGroups) {
                String expectedGroup = "CN=" + expectedGroupName + "," + ldapGroupSearchBase;
                final boolean isMember = attributeContainsNormalized(expectedGroup, groups);
                logger.info("For group '" + expectedGroupName + "' " +
                        "searched for '" + expectedGroup + "' " +
                        "within user groups '" + groups.toString() + "'. " +
                        "User is member: " + isMember);
                if (isMember) {
                    return true;
                }
            }
            return false;
        } else {
            Attribute usernameAttribute = user.get(ldapUserIdProperty);
            if (usernameAttribute == null) {
                logger.info("Could not extract attribute '" + ldapUserIdProperty + "' for entry '" + user + "'. Not checking further groups.");
                return false;
            }
            Value usernameValue = usernameAttribute.get();
            if (usernameValue == null) {
                logger.info("Could not extract value of attribute '" + ldapUserIdProperty + "' for entry '" + user + "'. Not checking further groups.");
                return false;
            }

            String username = usernameValue.getString();
            for (String expectedGroupName : expectedGroups) {
                String expectedGroup = "CN=" + expectedGroupName + "," + ldapGroupSearchBase;
                logger.info("For group '" + expectedGroupName + "' " +
                        "looking up '" + expectedGroup + "'...");
                Entry result = connection.lookup(expectedGroup);

                if (result == null) {
                    logger.info("Could not lookup group '" + expectedGroup + "'. Not checking further groups.");
                    return false;
                }

                Attribute objectClasses = result.get("objectClass");
                if (objectClasses != null && objectClasses.contains("groupOfNames")) {
                    Attribute members = result.get("member");

                    if (members == null) {
                        logger.info("Could not get members of group '" + expectedGroup + "'. Not checking further groups.");
                        return false;
                    }

                    String userDn = "cn=" + username + "," + ldapUserBase;
                    boolean isMember = members.contains(userDn);
                    logger.info("Searched for userDn '" + userDn + "' " +
                            "within group members of group '" + expectedGroupName + "'. " +
                            "User is member: " + isMember);
                    if (isMember) {
                        return true;
                    }
                } else {
                    Attribute members = result.get("memberuid");
                    if (members == null) {
                        logger.info("Could not get members of group '" + expectedGroup + "'. Not checking further groups.");
                        return false;
                    }

                    boolean isMember = members.contains(username);
                    logger.info("Searched for username '" + username + "' " +
                            "within group members of group '" + expectedGroupName + "'. " +
                            "User is member: " + isMember);
                    if (isMember) {
                        return true;
                    }
                }
            }
            return false;
        }
    }

    /**
     * Tests if the attribute contains a given value (case insensitive)
     *
     * @param expected  the expected value
     * @param attribute the attribute encapsulating a list of values
     * @return a value indicating if the attribute contains a value which matches expected
     */
    private boolean attributeContainsNormalized(String expected, Attribute attribute) {
        if (expected == null) {
            return false;
        }
        for (Value value : attribute) {
            if (value.toString().toLowerCase().equals(expected.toLowerCase())) {
                return true;
            }
        }
        return false;
    }

    @Override
    public boolean validateUser(String username) {
        if (username == null || username.trim().isEmpty()) {
            return false;
        }

        LdapConnection connection = null;
        EntryCursor result = null;

        try {
            connection = getLdapConnection();

            result = connection.search(
                    ldapUserBase,
                    "(" + escapeLDAPSearchFilter(ldapUserIdProperty + "=" + username) + ")",
                    SearchScope.SUBTREE
            );

            if (!result.next()) {
                return false;
            }


            final Entry entry = result.get();

            if (!isMemberOfGroups(connection, entry, ldapAllowedGroups)) {
                return false;
            }

            // Check if more than one user found
            return !result.next();

        } catch (LdapException e) {
            return false;
        } catch (CursorException e) {
            return false;
        } finally {
            if (result != null) {
                try {
                    result.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }

            if (connection != null) {
                try {
                    connection.close();
                } catch (IOException e) {
                    return false;
                }
            }
        }
    }

    @Override
    public boolean validateGroup(String group) {
        return ldapAllowedGroups.contains(group);
    }

    @Override
    public Role getRole(String roleName) {
        Permission permission = new Permission();
        permission.addPermissionsByName(roleName.toUpperCase());
        return new Role(roleName, permission);
    }

    @Override
    public boolean validateProxyUser(String proxyUser, User realUser) {
        return false;
    }

    private LdapConnection getLdapConnection() throws LdapException {
        LdapConnection connection = new LdapNetworkConnection(ldapHost, ldapPort, useSsl);
        connection.bind(ldapBindAccount, ldapBindPassword);
        return connection;
    }

    /**
     * See also https://www.owasp.org/index.php/Preventing_LDAP_Injection_in_Java
     */
    static String escapeLDAPSearchFilter(String filter) {
        return FilterEncoder.encodeFilterValue(filter);
    }
}
```
**测试类**
```
import azkaban.user.Role;
import azkaban.user.User;
import azkaban.user.UserManagerException;
import azkaban.utils.Props;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;
import org.zapodot.junit.ldap.EmbeddedLdapRule;
import org.zapodot.junit.ldap.EmbeddedLdapRuleBuilder;

import static org.junit.Assert.*;

public class LdapUserManagerTest {

    @Rule
    public ExpectedException thrown = ExpectedException.none();

    @Rule
    public EmbeddedLdapRule embeddedLdapRule = EmbeddedLdapRuleBuilder
            .newInstance()
            .usingDomainDsn("dc=example,dc=com")
            .withSchema("custom-schema.ldif")
            .importingLdifs("default.ldif")
            .bindingToPort(11389)
            .usingBindDSN("cn=read-only-admin,dc=example,dc=com")
            .usingBindCredentials("password")
            .build();

    private LdapUserManager userManager;

    @Before
    public void setUp() throws Exception {
        Props props = getProps();
        userManager = new LdapUserManager(props);
    }

    private Props getProps() {
        Props props = new Props();
//        props.put(LdapUserManager.LDAP_HOST, "localhost");
//        props.put(LdapUserManager.LDAP_PORT, "11389");
//        props.put(LdapUserManager.LDAP_USE_SSL, "false");
//        props.put(LdapUserManager.LDAP_USER_BASE, "dc=example,dc=com");
//        props.put(LdapUserManager.LDAP_USERID_PROPERTY, "uid");
//        props.put(LdapUserManager.LDAP_EMAIL_PROPERTY, "mail");
//        props.put(LdapUserManager.LDAP_BIND_ACCOUNT, "cn=read-only-admin,dc=example,dc=com");
//        props.put(LdapUserManager.LDAP_BIND_PASSWORD, "password");
//        props.put(LdapUserManager.LDAP_ALLOWED_GROUPS, "");
//        props.put(LdapUserManager.LDAP_GROUP_SEARCH_BASE, "dc=example,dc=com");
        props.put(LdapUserManager.LDAP_HOST, "192.168.101.174");
        props.put(LdapUserManager.LDAP_PORT, "389");
        props.put(LdapUserManager.LDAP_USE_SSL, "false");
        props.put(LdapUserManager.LDAP_USER_BASE, "ou=azkaban,dc=ldap,dc=chenjie,dc=asia");
        props.put(LdapUserManager.LDAP_USERID_PROPERTY, "uid");
        props.put(LdapUserManager.LDAP_EMAIL_PROPERTY, "mail");
        props.put(LdapUserManager.LDAP_BIND_ACCOUNT, "cn=admin,dc=ldap,dc=chenjie,dc=asia");
        props.put(LdapUserManager.LDAP_BIND_PASSWORD, "bigdata123");
        props.put(LdapUserManager.LDAP_ALLOWED_GROUPS, "");
        props.put(LdapUserManager.LDAP_GROUP_SEARCH_BASE, "dc=ldap,dc=chenjie,dc=asia");
        return props;
    }

    @Test
    public void testGetUser() throws Exception {
        User user = userManager.getUser("chenjie", "chenjie");

        System.out.println(user);

//        assertEquals("gauss", user.getUserId());
//        assertEquals("gauss@ldap.example.com", user.getEmail());
    }

    @Test
    public void testGetUserWithAllowedGroup() throws Exception {
        Props props = getProps();
        props.put(LdapUserManager.LDAP_ALLOWED_GROUPS, "svc-test");
        final LdapUserManager manager = new LdapUserManager(props);

        User user = manager.getUser("gauss", "password");

        assertEquals("gauss", user.getUserId());
        assertEquals("gauss@ldap.example.com", user.getEmail());
    }

    @Test
    public void testGetUserWithAllowedGroupThatGroupOfNames() throws Exception {
        Props props = getProps();
        props.put(LdapUserManager.LDAP_ALLOWED_GROUPS, "svc-test2");
        final LdapUserManager manager = new LdapUserManager(props);

        User user = manager.getUser("gauss", "password");

        assertEquals("gauss", user.getUserId());
        assertEquals("gauss@ldap.example.com", user.getEmail());
    }


    @Test
    public void testGetUserWithEmbeddedGroup() throws Exception {
        Props props = getProps();
        props.put(LdapUserManager.LDAP_ALLOWED_GROUPS, "svc-test");
        props.put(LdapUserManager.LDAP_EMBEDDED_GROUPS, "true");
        final LdapUserManager manager = new LdapUserManager(props);

        User user = manager.getUser("gauss", "password");

        assertEquals("gauss", user.getUserId());
        assertEquals("gauss@ldap.example.com", user.getEmail());
    }

    @Test
    public void testGetUserWithInvalidPasswordThrowsUserManagerException() throws Exception {
        thrown.expect(UserManagerException.class);
        userManager.getUser("gauss", "invalid");
    }

    @Test
    public void testGetUserWithInvalidUsernameThrowsUserManagerException() throws Exception {
        thrown.expect(UserManagerException.class);
        userManager.getUser("invalid", "password");
    }

    @Test
    public void testGetUserWithEmptyPasswordThrowsUserManagerException() throws Exception {
        thrown.expect(UserManagerException.class);
        userManager.getUser("gauss", "");
    }

    @Test
    public void testGetUserWithEmptyUsernameThrowsUserManagerException() throws Exception {
        thrown.expect(UserManagerException.class);
        userManager.getUser("", "invalid");
    }

    @Test
    public void testValidateUser() throws Exception {
        assertTrue(userManager.validateUser("gauss"));
        assertFalse(userManager.validateUser("invalid"));
    }

    @Test
    public void testGetRole() throws Exception {
        Role role = userManager.getRole("admin");

        assertTrue(role.getPermission().isPermissionNameSet("ADMIN"));
    }

    @Test
    public void testInvalidEmailPropertyDoesNotThrowNullPointerException() throws Exception {
        Props props = getProps();
        props.put(LdapUserManager.LDAP_EMAIL_PROPERTY, "invalidField");
        userManager = new LdapUserManager(props);
        User user = userManager.getUser("gauss", "password");

        assertEquals("gauss", user.getUserId());
        assertEquals("", user.getEmail());
    }

    @Test
    public void testInvalidIdPropertyThrowsUserManagerException() throws Exception {
        thrown.expect(UserManagerException.class);

        Props props = getProps();
        props.put(LdapUserManager.LDAP_USERID_PROPERTY, "invalidField");
        userManager = new LdapUserManager(props);
        userManager.getUser("gauss", "password");
    }

    @Test
    public void testEscapeLDAPSearchFilter() throws Exception {
        assertEquals("No special characters to escape", "Hi This is a test #çà", LdapUserManager.escapeLDAPSearchFilter("Hi This is a test #çà"));
        assertEquals("LDAP Christams Tree", "Hi \28This\29 = is \2A a \5C test # ç à ô", LdapUserManager.escapeLDAPSearchFilter("Hi (This) = is * a \ test # ç à ô"));
    }
}
```

`注意版本，3.2.0 以上不适用！`

<br>
参考和使用的[Github上的项目](https://github.com/researchgate/azkaban-ldap-usermanager)，我只是把gradle项目改为了[maven项目]()。
