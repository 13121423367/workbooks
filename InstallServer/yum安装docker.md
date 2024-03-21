# yum安装docker

### 1.卸载掉之前安装过的docker

sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine

### 2、配置阿里云yum源仓库

`sudo yum install -y yum-utils device-mapper-persistent-data lvm2`  

  --yum-util 提供yum-config-manager功能，另外两个是devicemapper驱动依赖的
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

###  3、查看可以安装的docker版本

 `yum list docker-ce --showduplicates | sort -r` //查看可以安装的版本并倒序排序

###  4、安装最新版本Docker

   注意：安装Docker最新版本，无需加版本号：
 `sudo yum install -y docker`



###  5、设Docker阿里云加速器

`sudo mkdir -p /etc/docker`
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://lkq3q0he.mirror.aliyuncs.com"]
}
EOF

### 6、启动Docker设置开机启动与重启docker服务

` sudo systemctl daemon-reload` //重新加载服务配置文件

` sudo systemctl enable docker.service && systemctl restart docker.service`  