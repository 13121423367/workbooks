# Jumpserver 

os : centos 7.9

JumpServer v2.0 版本功能演示

https://www.bilibili.com/video/BV1ZV41127GB     

JumpServer 从入门到精通 [开源堡垒机]

https://www.bilibili.com/video/BV19D4y1S7s4/?spm_id_from=333.788.recommend_more_video.5    



## 安装环境准备工作

用户名：root 

密码：pppNo.1!!!

```

```



## 安装部署 jumpserver

官方文档：https://docs.jumpserver.org/zh/master/

一键部署

```
# 默认会安装到 /opt/jumpserver-installer-v2.13.2 目录
curl -sSL https://github.com/jumpserver/jumpserver/releases/download/v2.13.2/quick_start.sh | bash
cd /opt/jumpserver-installer-v2.13.2
```


安装完成后配置文件 `/opt/jumpserver/config/config.txt`


```
cd /opt/jumpserver-installer-v2.13.2

# 启动
./jmsctl.sh start

# 停止
./jmsctl.sh down

# 卸载
./jmsctl.sh uninstall

# 帮助
./jmsctl.sh -h
```





```
cd /opt
wget https://github.com/jumpserver/installer/releases/download/v2.13.2/jumpserver-installer-v2.13.2.tar.gz
tar -xf jumpserver-installer-v2.13.2.tar.gz
cd jumpserver-installer-v2.13.2

# 根据需要修改配置文件模板, 如果不清楚用途可以跳过修改
cat config-example.txt
# 以下设置如果为空系统会自动生成随机字符串填入
## 迁移请修改 SECRET_KEY 和 BOOTSTRAP_TOKEN 为原来的设置
## 完整参数文档 https://docs.jumpserver.org/zh/master/admin-guide/env/

## 安装配置, amd64 默认使用华为云加速下载, arm64 请注释掉 DOCKER_IMAGE_PREFIX=swr.cn-south-1.myhuaweicloud.com
# DOCKER_IMAGE_PREFIX=swr.cn-south-1.myhuaweicloud.com
VOLUME_DIR=/opt/jumpserver
DOCKER_DIR=/var/lib/docker
SECRET_KEY=
BOOTSTRAP_TOKEN=
LOG_LEVEL=ERROR

##  MySQL 配置, USE_EXTERNAL_MYSQL=1 表示使用外置数据库, 请输入正确的 MySQL 信息
USE_EXTERNAL_MYSQL=0
DB_HOST=mysql
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=jumpserver

##  Redis 配置, USE_EXTERNAL_REDIS=1 表示使用外置数据库, 请输入正确的 Redis 信息
USE_EXTERNAL_REDIS=0
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

## Compose 项目设置, 如果 192.168.250.0/24 网段与你现有网段冲突, 请修改然后重启 JumpServer
COMPOSE_PROJECT_NAME=jms
COMPOSE_HTTP_TIMEOUT=3600
DOCKER_CLIENT_TIMEOUT=3600
DOCKER_SUBNET=192.168.250.0/24

## IPV6 设置, 容器是否开启 ipv6 nat, USE_IPV6=1 表示开启, 为 0 的情况下 DOCKER_SUBNET_IPV6 定义不生效
USE_IPV6=0
DOCKER_SUBNET_IPV6=2001:db8:10::/64

## Nginx 配置, USE_LB=1 表示开启, 为 0 的情况下, HTTPS_PORT 定义不生效
HTTP_PORT=80
SSH_PORT=2222
RDP_PORT=3389

USE_LB=0
HTTPS_PORT=443

## Task 配置, 是否启动 jms_celery 容器, 单节点必须开启
USE_TASK=1

## XPack, USE_XPACK=1 表示开启, 开源版本设置无效
USE_XPACK=0

# Core 配置, Session 定义, SESSION_COOKIE_AGE 表示闲置多少秒后 session 过期, SESSION_EXPIRE_AT_BROWSER_CLOSE=true 表示关闭浏览器即 session 过期
# SESSION_COOKIE_AGE=86400
SESSION_EXPIRE_AT_BROWSER_CLOSE=true

# Koko Lion XRDP 组件配置
CORE_HOST=http://core:8080

# 额外的配置
CURRENT_VERSION=
# 安装
./jmsctl.sh install

# 启动
./jmsctl.sh start
```





```
# 安装完成后配置文件 /opt/jumpserver/config/config.txt
cd /opt/jumpserver-installer-v2.13.2

# 启动
./jmsctl.sh start

# 停止
./jmsctl.sh down

# 卸载
./jmsctl.sh uninstall

# 帮助
./jmsctl.sh -h
```



>>> The Installation is Complete
1. You can use the following command to start, and then visit
cd /opt/jumpserver-installer-v2.13.2
./jmsctl.sh start
2. Other management commands
./jmsctl.sh stop
./jmsctl.sh restart
./jmsctl.sh backup
./jmsctl.sh upgrade
For more commands, you can enter ./jmsctl.sh --help to understand
3. Web access
http://192.168.0.28:80
Default username: admin  Default password: admin
4. Index.html1
5. SSH/SFTP access
  ssh -p2222 admin@192.168.0.28
  sftp -P2222 admin@192.168.0.28
6. More information
  Official Website: https://www.jumpserver.org/
  Documentation: https://docs.jumpserver.org/

