# jira容器化部署及迁移实践

### 一、说明

- 系统环境：centos7.5
- 部署架构：jira-8.8.0+mysql5.7

### 二、部署

#### 2.1 容器创建

```bash
#docker安装
yum -y install docker docker-compose

#创建持久化目录
mkdri /opt/{mysql,jira}_data

#docker-compose.yml编写
version: '2'
services:
    jira-mysql:
      container_name: jira-mysql
      image: mysql:5.7
      restart: always
      volumes:
        - /opt/mysql_data:/var/lib/mysql
      ports:
        - 3306:3306
      environment:
        - MYSQL_DATABASE=default
        - MYSQL_USER=default
        - MYSQL_PASSWORD=default
        - MYSQL_ROOT_PASSWORD=passwd
    jira:
      container_name: jira
      image: cptactionhank/atlassian-jira-software:8.8.0
      volumes:
        - /opt/jira_data:/var/atlassian/jira
      restart: always
      ports:
        - 8080:8080

#启动容器
docker-compose up -d
```

#### 2.2 数据库创建

```bash
docker exec jira-mysql mysql -uroot -ppasswd -e 'create database jira character set utf8 collate utf8_bin;'
docker exec jira-mysql mysql -uroot -ppasswd -e 'grant all privileges on jira.* to 'jira'@'%' identified by '密码';'
docker exec jira-mysql mysql -uroot -ppasswd -e 'flush privileges;'
```

#### 2.3 配置数据库驱动

```bash
#配置mysql驱动
wget https://cdn.mysql.com//Downloads/Connector-J/mysql-connector-java-5.1.48.tar.gz
tar zxf mysql-connector-java-5.1.48.tar.gz
docker cp mysql-connector-java-5.1.48/mysql-connector-java-5.1.48-bin.jar jira:/opt/atlassian/jira/lib/
```

#### 2.3 jira配置

##### 2.3.1 配置数据库连接

```xml
#创建dbconfig.xml文件，着重更改 jdbc:mysql://address=(protocol=tcp)(host=服务器ip)(port=数据库服务端口)/jira
cat > /opt/jira_data/dbconfig.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>

<jira-database-config>
  <name>defaultDS</name>
  <delegator-name>default</delegator-name>
  <database-type>mysql</database-type>
  <jdbc-datasource>
    <url>jdbc:mysql://address=(protocol=tcp)(host=172.16.100.25)(port=3306)/jira?useUnicode=true&amp;characterEncoding=UTF8&amp;sessionVariables=default_storage_engine=InnoDB</url>
    <driver-class>com.mysql.jdbc.Driver</driver-class>
    <username>jira</username>
    <password>jira数据库密码</password>
    <pool-min-size>20</pool-min-size>
    <pool-max-size>20</pool-max-size>
    <pool-max-wait>30000</pool-max-wait>
    <validation-query>select 1</validation-query>
    <min-evictable-idle-time-millis>60000</min-evictable-idle-time-millis>
    <time-between-eviction-runs-millis>300000</time-between-eviction-runs-millis>
    <pool-max-idle>20</pool-max-idle>
    <pool-remove-abandoned>true</pool-remove-abandoned>
    <pool-remove-abandoned-timeout>300</pool-remove-abandoned-timeout>
    <pool-test-on-borrow>false</pool-test-on-borrow>
    <pool-test-while-idle>true</pool-test-while-idle>
    <validation-query-timeout>3</validation-query-timeout>
  </jdbc-datasource>
</jira-database-config>
EOF
```

##### 2.3.2 破解配置

```bash
#下载破解包
wget https://files.cnblogs.com/files/tchua/atlassian-extras-3.2.rar
#复制到容器
docker cp atlassian-extras-3.2.jar  jira:/opt/atlassian/jira/atlassian-jira/WEB-INF/lib
```

#### 2.4 访问验证

```bash
#启动jira
docker start jira

#访问
http://ip:8080/
```

### 三、迁移实践

- 目的服务器：172.16.100.25
- 目的持久化目录
  - jira: /opt/jira/jira_data
  - mysql: /opt/jira/mysql_data

#### 3.1 迁移项

##### 3.1.1 jira数据迁移

源码安装下的数据路径：/var/atlassian/jira

注：若源jira为容器部署，且没有做持久化，先找到该路径在宿主机的映射目录

```bash
#示例
[root@jira ~]# docker inspect jira | grep _data
"Source": "/var/lib/docker/volumes/fa8d262e9451c5f766960c5eafab45143fdb7f52c2c0a886559f15f29e879950/_data",
[root@jira ~# cd /var/lib/docker/volumes/fa8d262e9451c5f766960c5eafab45143fdb7f52c2c0a886559f15f29e879950/_data
[root@jira _data]# ll
total 136
drwxr-x--- 2 daemon daemon   278 Nov  8 08:08 analytics-logs
drwx------ 4 daemon daemon    46 Apr 20  2020 caches
drwxr-x--- 3 daemon daemon    69 Jul 22 11:17 customisations
drwxr-x--- 3 daemon daemon    69 Apr 20  2020 customisations-backup
drwxr-x--- 4 daemon daemon    40 Apr 22  2020 data
-rw-r----- 1 daemon daemon  1184 Apr 20  2020 dbconfig.xml
drwxr-x--- 3 daemon daemon 94208 Nov  8 12:00 export  #该目录下若有多个zip,迁移最新的一次即可
drwxr-x--- 4 daemon daemon   108 Apr 21  2020 import
drwxr-x--- 2 daemon daemon  4096 Nov  7 04:22 log
drwxr-x--- 2 daemon daemon     6 Apr 20  2020 logos
drwxr-x--- 2 daemon daemon    76 Apr 20  2020 monitor
drwxr-x--- 6 daemon daemon   100 Apr 20  2020 plugins
drwxr-x--- 3 daemon daemon    26 Apr 20  2020 tmp

#原地址
[root@jira _data]# rsync -av -R --excluce "export*" ./* 172.16.100.25:/opt/jira/jira_data/


#目的服务器配置
- 参考2.3.1 ，更改dbconfig.xml
- 将原export下的最后一次备份导入到新服务器的import文件夹下
```

##### 3.1.2 jira数据库

```bash
#导出源jira数据库
docker cp 源jira数据库容器:/var/lib/mysql /tmp/

#降导出的mysql目录下所有文件导入新服务器的mysql_data目录下
rsync -av -R  /tmp/mysql/* 172.16.100.25:/opt/jira/mysql_data/

```

#### 3.2 验证

- 重启新jira、mysql容器

-  使用之前的账号登录新jira，检查以下项
  - 登录是否正常
  - 面板是否正常
  - 与源jira相比，数据是否存在丢失

