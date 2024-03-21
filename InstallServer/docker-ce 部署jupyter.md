## 使用docker-ce 部署jupyter

### 1. 更改yum源为国内阿里源

```bash
#对原来的yum文件进行备份
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo_bak

#下载阿里云的Centos-Base.repo到/etc、yum.reposd
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

#清空原本yum缓存
yum clean all

#生成新的阿里云的yum缓存，加速下载预热数据
yum makecache
```





### 2. 安装docker-ce

```shell
#1.安装依赖关系
yum install -y yum-utils device-mapper-persistent-data lvm2

#添加阿里源
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo

#更新yum缓存
yum makecache fast
 
#下载docker-ce
yum -y install docker-ce

#启动docker并设置开机自启
systemctl start docker &&systemctl enable docker

#设置阿里云加速
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://zd29wsn0.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker
```





### 3. 安装jupyter

```bash
docker run -d -p 80:8888 --name jupyter jupyter/base-notebook



```



脚本部署

```bash
vim install-jupyter.sh
#!/bin/bash


curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

yum clean all && yum makecache

#1.安装依赖关系
yum install -y yum-utils device-mapper-persistent-data lvm2

#添加阿里源
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo

#更新yum缓存
yum makecache fast
 
#下载docker-ce
yum -y install docker-ce

#启动docker并设置开机自启
systemctl start docker &&systemctl enable docker

#设置阿里云加速
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://zd29wsn0.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker


docker run -d -p 80:8888 --name jupyter jupyter/base-notebook
```



#### 注

**####安装最新版docker-ce需要centos7.9版本，否则容器无法启动成功。**





































