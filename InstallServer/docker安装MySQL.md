## docker安装MySQL

1、查看可用版本、下载镜像

`docker search mysql`

`docker pull mysql:latest`

2、创建容器映射目录

`mkdir -p docker/mysql/conf`

`touch docker/mysql/conf/my.cnf`

3、启动容器

`docker run -itd -p 3306:3306 --name mysql -v /root/docker/mysql/conf:/etc/mysql/conf.d -e MYSQL_ROOT_PASSWORD=123456 mysql`



-p  3306:3306  															**#将3306端口映射到3306**

--name   mysql  														  **#定义容器名称为mysql**

-v /root/docker/mysql/conf:/etc/mysql/conf.d      **#挂载容器目录做持久化**                                    

-e MYSQL_ROOT_PASSWORD=123456					**#定义MySQL密码为123456**