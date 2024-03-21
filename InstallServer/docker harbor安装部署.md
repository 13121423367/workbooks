## docker harbor安装部署

下载包    `https://github.com/goharbor/harbor/releases`



**1、解压**

`tar -zxvf harbor-offline-installer-v1.10.10.tgz`

`cd harbor`

**2.对配置文件进行备份**

`cp harbor.yml harbor.yml.bak`

**3、对配置文件进行修改**

 vim harbor.yml

**修改hostname改为本机ip、注释掉https内容、修改持久化目录、修改默认初始密码**

![image-20220216172432266](C:\Users\小贤\AppData\Roaming\Typora\typora-user-images\image-20220216172432266.png)



**4.执行脚本安装**

`sh install.sh`

**5.将harbor仓库地址添加为Docker信任列表**

在/etc/docker/创建daemon.json文件

`vim /etc/docker/daemon.json`

{  "registry-mirrors": ["https://ggb52j62.mirror.aliyuncs.com"], 

 "insecure-registries":["172.22.247.134"] *# 将Harbor仓库的地址添加为Dokcer的信任列表* 

}

`systemctl restart docker`



6.登录Harbor，提交推送

`docker login -u admin -p Harbor12345 172.22.247.134`

给镜像打标签

`docker tag nginx:latest 172.22.247.134/lxx/lxx-test-nginx:v1`

推送镜像

`docker push 172.22.247.134/lxx/lxx-test-nginx:v1`



7.其他服务器登录Harbor

vi /etc/docker/daemon.json

 添加一行参数  "insecure-registries":["172.22.247.134"]

`systemctl restart docker`

`docker login -u admin -p Harbor12345 172.22.247.134`

下载镜像

`docker pull 172.22.247.134/lxx/lxx-test-nginx:v1`