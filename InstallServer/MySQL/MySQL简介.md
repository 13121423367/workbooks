# MySQL 



## 什么是数据库？

数据库（Database）是按照数据结构来组织、存储和管理数据的仓库。

每个数据库都有一个或多个不同的 API 用于创建，访问，管理，搜索和复制所保存的数据。

我们也可以将数据存储在文件中，但是在文件中读写数据速度相对较慢。

所以，现在我们使用关系型数据库管理系统（RDBMS）来存储和管理大数据量。所谓的关系型数据库，是建立在关系模型基础上的数据库，借助于集合代数等数学概念和方法来处理数据库中的数据。

RDBMS 即关系数据库管理系统(Relational Database Management System)的特点：

- 1.数据以表格的形式出现
- 2.每行为各种记录名称
- 3.每列为记录名称所对应的数据域
- 4.许多的行和列组成一张表单
- 5.若干的表单组成database

------

## RDBMS 术语



在我们开始学习MySQL 数据库前，让我们先了解下RDBMS的一些术语：

- **数据库:** 数据库是一些关联表的集合。
- **数据表:** 表是数据的矩阵。在一个数据库中的表看起来像一个简单的电子表格。
- **列:** 一列(数据元素) 包含了相同类型的数据, 例如邮政编码的数据。
- **行：**一行（=元组，或记录）是一组相关的数据，例如一条用户订阅的数据。
- **冗余**：存储两倍数据，冗余降低了性能，但提高了数据的安全性。
- **主键**：主键是唯一的。一个数据表中只能包含一个主键。你可以使用主键来查询数据。
- **外键：**外键用于关联两个表。
- **复合键**：复合键（组合键）将多个列作为一个索引键，一般用于复合索引。
- **索引：**使用索引可快速访问数据库表中的特定信息。索引是对数据库表中一列或多列的值进行排序的一种结构。类似于书籍的目录。
- **参照完整性:** 参照的完整性要求关系中不允许引用不存在的实体。与实体完整性是关系模型必须满足的完整性约束条件，目的是保证数据的一致性。

**MySQL 为关系型数据库(Relational Database Management System), 这种所谓的"关系型"可以理解为"表格"的概念, 一个关系型数据库由一个或数个表格组成, 如图所示的一个表格:**

![img](https://www.runoob.com/wp-content/uploads/2014/03/0921_1.jpg)

- 表头(header): 每一列的名称;
- 列(col): 具有相同数据类型的数据的集合;
- 行(row): 每一行用来描述某条记录的具体信息;
- 值(value): 行的具体信息, 每个值必须与该列的数据类型相同;
- **键(key)**: 键的值在当前列中具有唯一性。

## 数据库表的存储位置

MySQL数据表以文件方式存放在磁盘中：

包括表文件、数据文件以及数据库的选项文件
位置：MySQL安装目录\data下存放数据表。目录名对应数据库名，该目录下文件名对应数据表
注：

InnoDB类型数据表只有一个*. frm文件，以及上一级目录的ibdata1文件
MylSAM类型数据表对应三个文件：

*. frm —— 表结构定义文件
*. MYD —— 数据文件
*. MYI —— 索引文件
存储位置：因操作系统而异，可查my.ini




------

## MySQL数据库

MySQL 是一个关系型数据库管理系统，由瑞典 MySQL AB 公司开发，目前属于 Oracle 公司。MySQL 是一种关联数据库管理系统，关联数据库将数据保存在不同的表中，而不是将所有数据放在一个大仓库内，这样就增加了速度并提高了灵活性。

- MySQL 是开源的，目前隶属于 Oracle 旗下产品。
- MySQL 支持大型的数据库。可以处理拥有上千万条记录的大型数据库。
- MySQL 使用标准的 SQL 数据语言形式。
- MySQL 可以运行于多个系统上，并且支持多种语言。这些编程语言包括 C、C++、Python、Java、Perl、PHP、Eiffel、Ruby 和 Tcl 等。
- MySQL 对 PHP 有很好的支持，PHP 是很适合用于 Web 程序开发。
- MySQL 支持大型数据库，支持 5000 万条记录的数据仓库，32 位系统表文件最大可支持 4GB，64 位系统支持最大的表文件为8TB。
- MySQL 是可以定制的，采用了 GPL 协议，你可以修改源码来开发自己的 MySQL 系统。



## 安装

所有平台的 MySQL 下载地址为： [MySQL 下载](https://dev.mysql.com/downloads/mysql/) 。 挑选你需要的 *MySQL Community Server* 版本及对应的平台。

> **注意：**安装过程我们需要通过开启管理员权限来安装，否则会由于权限不足导致无法安装。

------

### Linux/UNIX 上安装 MySQL

Linux平台上推荐使用RPM包来安装Mysql,MySQL AB提供了以下RPM包的下载地址：

- **MySQL** - MySQL服务器。你需要该选项，除非你只想连接运行在另一台机器上的MySQL服务器。
- **MySQL-client** - MySQL 客户端程序，用于连接并操作Mysql服务器。
- **MySQL-devel** - 库和包含文件，如果你想要编译其它MySQL客户端，例如Perl模块，则需要安装该RPM包。
- **MySQL-shared** - 该软件包包含某些语言和应用程序需要动态装载的共享库(libmysqlclient.so*)，使用MySQL。
- **MySQL-bench** - MySQL数据库服务器的基准和性能测试工具。

安装前，我们可以检测系统是否自带安装 MySQL:

安装前，我们可以检测系统是否自带安装 MySQL:

```
rpm -qa | grep mysql
```

如果你系统有安装，那可以选择进行卸载:

```
rpm -e mysql　　// 普通删除模式
rpm -e --nodeps mysql　　// 强力删除模式，如果使用上面命令删除时，提示有依赖的其它文件，则用该命令可以对其进行强力删除
```

**安装 MySQL：**

接下来我们在 Centos7 系统下使用 yum 命令安装 MySQL，需要注意的是 CentOS 7 版本中 MySQL数据库已从默认的程序列表中移除，所以在安装前我们需要先去官网下载 Yum 资源包，下载地址为：https://dev.mysql.com/downloads/repo/yum/

![img](images/MySQL简介/repo-name-small.png)

```
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
rpm -ivh mysql-community-release-el7-5.noarch.rpm
yum update
yum install mysql-server

```

权限设置：

```
chown -R mysql:mysql /var/lib/mysql/
```

初始化 MySQL：

```
mysqld --initialize
```

/usr/bin/mysqladmin -u root password 'new-password'





启动 MySQL：

```
systemctl start mysqld
```

查看 MySQL 运行状态：

```
systemctl status mysqld
```

**注意：**如果我们是第一次启动 mysql 服务，mysql 服务器首先会进行初始化的配置。

> 此外,你也可以使用 MariaDB 代替，MariaDB 数据库管理系统是 MySQL 的一个分支，主要由开源社区在维护，采用 GPL 授权许可。开发这个分支的原因之一是：甲骨文公司收购了 MySQL 后，有将 MySQL 闭源的潜在风险，因此社区采用分支的方式来避开这个风险。
>
> MariaDB的目的是完全兼容MySQL，包括API和命令行，使之能轻松成为MySQL的代替品。
>
> ```
> yum install mariadb-server mariadb 
> ```
>
> mariadb数据库的相关命令是：
>
> ```
> systemctl start mariadb  #启动MariaDB
> systemctl stop mariadb  #停止MariaDB
> systemctl restart mariadb  #重启MariaDB
> systemctl enable mariadb  #设置开机启动
> ```

------

##### 验证 MySQL 安装

在成功安装 MySQL 后，一些基础表会表初始化，在服务器启动后，你可以通过简单的测试来验证 MySQL 是否工作正常。

使用 mysqladmin 工具来获取服务器状态：

使用 mysqladmin 命令来检查服务器的版本, 在 linux 上该二进制文件位于 /usr/bin 目录，在 Windows 上该二进制文件位于C:\mysql\bin 。

```
[root@host]# mysqladmin --version
```

linux上该命令将输出以下结果，该结果基于你的系统信息：

```
mysqladmin  Ver 8.23 Distrib 5.0.9-0, for redhat-linux-gnu on i386
```

如果以上命令执行后未输出任何信息，说明你的Mysql未安装成功。

------

##### 使用 MySQL Client(Mysql客户端) 执行简单的SQL命令

你可以在 MySQL Client(Mysql客户端) 使用 mysql 命令连接到 MySQL 服务器上，默认情况下 MySQL 服务器的登录密码为空，所以本实例不需要输入密码。

命令如下：

```
[root@host]# mysql
```

以上命令执行后会输出 mysql>提示符，这说明你已经成功连接到Mysql服务器上，你可以在 mysql> 提示符执行SQL命令：

```shell
mysql> SHOW DATABASES;        # 查看数据库名 
+----------+
| Database |
+----------+
| mysql    |
| test     |
+----------+
2 rows in set (0.13 sec)

mysql> show tables;           # 查看表名
+---------------------------+
| Tables_in_mysql           |
+---------------------------+
| columns_priv              |
| db                        |
| event                     |
| func                      |
| general_log               |
| help_category             |
| help_keyword              |
| help_relation             |
| help_topic                |
| innodb_index_stats        |
| innodb_table_stats        |
| ndb_binlog_index          |
| plugin                    |
| proc                      |
| procs_priv                |
| proxies_priv              |
| servers                   |
| slave_master_info         |
| slave_relay_log_info      |
| slave_worker_info         |
| slow_log                  |
| tables_priv               |
| time_zone                 |
| time_zone_leap_second     |
| time_zone_name            |
| time_zone_transition      |
| time_zone_transition_type |
| user                      |
+---------------------------+
28 rows in set (0.00 sec)
```

------

##### Mysql安装后需要做的

Mysql安装成功后，默认的root用户密码为空，你可以使用以下命令来创建root用户的密码：

```
[root@host]# mysqladmin -u root password "new_password";
```

现在你可以通过以下命令来连接到Mysql服务器：

```
[root@host]# mysql -u root -p
Enter password:*******
```

**注意：**在输入密码时，密码是不会显示了，你正确输入即可。

------

##### 登录 MySQL

当 MySQL 服务已经运行时, 我们可以通过 MySQL 自带的客户端工具登录到 MySQL 数据库中, 首先打开命令提示符, 输入以下格式的命名:

```
mysql -h 主机名 -u 用户名 -p
```

参数说明：

- **-h** : 指定客户端所要登录的 MySQL 主机名, 登录本机(localhost 或 127.0.0.1)该参数可以省略;
- **-u** : 登录的用户名;
- **-p** : 告诉服务器将会使用一个密码来登录, 如果所要登录的用户名密码为空, 可以忽略此选项。

如果我们要登录本机的 MySQL 数据库，只需要输入以下命令即可：

```
mysql -u root -p
```

按回车确认, 如果安装正确且 MySQL 正在运行, 会得到以下响应:

```
Enter password:
```

若密码存在, 输入密码登录, 不存在则直接按回车登录。登录成功后你将会看到 Welcome to the MySQL monitor... 的提示语。

然后命令提示符会一直以 **mysql>** 加一个闪烁的光标等待命令的输入, 输入 **exit** 或 **quit** 退出登录。



### 忘记密码解决办法：

- **1：跳过密码登录**

  - ```shell
    [root@mysql ~]# vim /etc/my.cnf
    [mysqld]
    skip-grant-tables  # 表示跳过密码验证；
    ```

- **2：重启mysql服务。**
  - `systemctl restart mysql`

- **3：修改密码。**
  - ​    切换数据库：
  -    use mysql;

- 执行改账号sql：


```shell
mysql> use mysql;
Database changed

mysql> update user set authentication_string=password('XU!@sx0629') where user='root';

mysql> SELECT user,authentication_string FROM user;
+------+-------------------------------------------+
| user | authentication_string                     |
+------+-------------------------------------------+
| root | *23AE809DDACAF96AF0FD78ED04B6A265E05AA257 |
| root | *23AE809DDACAF96AF0FD78ED04B6A265E05AA257 |
| root | *23AE809DDACAF96AF0FD78ED04B6A265E05AA257 |
| root | *23AE809DDACAF96AF0FD78ED04B6A265E05AA257 |
|      | NULL                                      |
|      | NULL                                      |
+------+-------------------------------------------+
6 rows in set (0.00 sec)

########## 通过表中可以看到  有用户的密码为NULL，需要执行以下命令 将所有的root、127、localhost全都更改密码。

UPDATE user SET Password=PASSWORD('XU!@sx0629') where USER='root' and host='127.0.0.1' or host='localhost';
```

