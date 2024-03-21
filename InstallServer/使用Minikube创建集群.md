# 使用Minikube创建集群

## 1、配置环境

CentOS7
**IP：**     			 	172.22.247.69
**hostname：**   	prometheus
**kubelet:**   		    v1.18.0
**minikube:**  		  v1.18.0
**kubernetes:**		v1.18.0



## 2、准备工作

2.1）关闭防火墙和Selinux

```
systemctl stop firewalld && systemctl disable firewalld
setenforce 0
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
```

2.2)禁用swap交换分区

```
swapoff -a 
```



## 3、Docker安装

3.1)、 配置docker源

```
yum install -y wget
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
```

3.2) 、安装docker环境依赖

```
yum install -y yum-utils device-mapper-persistent-data lvm2
```

3.3)、安装docker，docker版本需要与Kubernetes版本能够兼容使用

```
yum install docker-ce-18.09.9 docker-ce-cli-18.09.9 containerd.io -y 
```

3.4）、启动docker并设置为开机自启

```
systemctl start docker && systemctl enable docker
```

3.5）、配置镜像加速

```
mkdir -p /etc/docker 
tee /etc/docker/daemon.json <<-'EOF'
{
    "registry-mirrors": ["https://mxdu1aof.mirror.aliyuncs.com"], 
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
```



6.重新启动守护进程并重启docker

```
systemctl daemon-reload && systemctl restart docker
```





## 4、安装Kubectl 和 Minikube

1.下载Kubectl 和 Minikube，这里均使用v1.18.0版本，与Kubernetes版本对应

http://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl
https://storage.googleapis.com/minikube/releases/v1.18.0/minikube-linux-amd64 （下载后重命名为minikube）

2.将下载后的kubectl和minikube 放到centos的/usr/local/bin/ 目录下，并设为可执行文件

```
chmod +x kubectl && chmod +x minikube
cp kubectl /usr/local/bin/ && cp minikube /usr/local/bin/
ls /usr/local/bin/
```

![image-20220310013514971](C:\Users\小贤\AppData\Roaming\Typora\typora-user-images\image-20220310013514971.png)



3.查看kubectl版本和minikube版本，校验是否成功

```
kubectl version --client
minikube version
```

![image-20220310013621244](C:\Users\小贤\AppData\Roaming\Typora\typora-user-images\image-20220310013621244.png)



4.配置Kubernetes源,Kubernetes-YUM由阿里巴巴开源镜像网提供

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

5.更新yum缓存

```
yum clean all
yum -y makecache
```

6.安装bash-completion命令补全以及 安装conntrack

```
yum -y install bash-completion
source /etc/profile.d/bash_completion.sh
yum install -y conntrack
```

7.下载minikube start所需要的镜像，通过阿里云镜像网下载

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.18.0 &&
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.18.0 &&
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.18.0 &&
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.18.0 &&
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 &&
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.4.3 &&
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.6.7 &&
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/storage-provisioner:v1.8.1
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

```
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.18.0 k8s.gcr.io/kube-apiserver:v1.18.0 &&
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.18.0 k8s.gcr.io/kube-controller-manager:v1.18.0 &&
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.18.0 k8s.gcr.io/kube-scheduler:v1.18.0 &&
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.18.0 k8s.gcr.io/kube-proxy:v1.18.0 &&
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.2 k8s.gcr.io/pause:3.2 &&
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.4.3 k8s.gcr.io/etcd:3.4.3-0 &&
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.6.7 k8s.gcr.io/coredns:1.6.7 &&
docker tag registry.cn-hangzhou.aliyuncs.com/google_containers/storage-provisioner:v1.8.1 gcr.io/k8s-minikube/storage-provisioner:v1.8.1
```

[![复制代码](https://common.cnblogs.com/images/copycode.gif)](javascript:void(0);)

8.启动minikube

```
minikube start --vm-driver=none --kubernetes-version='v1.18.0'  # –vm-driver=none表示使用Linux本机作为运行环境，--kubernetes-version表示使用的版本
```

![img](https://img2020.cnblogs.com/blog/994830/202107/994830-20210708131216954-1092484153.png)

 9.解决报错，上图画出的是报错问题

```
yum -y install socat　　　　　　　　　　　　　　　　　　　　　　# 安装socat
systemctl enable kubelet.service　　　　　　　　　　　　　　 # 在hosts中配置名称
echo "1" >/proc/sys/net/bridge/bridge-nf-call-iptables  # 在bridge-nf-call-iptables 写入1
```

![img](https://img2020.cnblogs.com/blog/994830/202107/994830-20210708131806196-377530444.png)

 表示已经成功了！

10.安装minikube dashboard

首先启动kubect proxy

```
kubectl proxy --port=8001 --address='172.22.247.69' --accept-hosts='^.*' &
```

其次运行

```
minikube dashboard
```

![image-20220310024252189](C:\Users\小贤\AppData\Roaming\Typora\typora-user-images\image-20220310024252189.png)



##  浏览器访问

http://172.22.247.69:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/#/overview?namespace=default

![image-20220310024407333](C:\Users\小贤\AppData\Roaming\Typora\typora-user-images\image-20220310024407333.png)





































































