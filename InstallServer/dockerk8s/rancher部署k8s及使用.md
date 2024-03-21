## rancher部署k8s及使用

### 1、k8s概述

kubernetes是为容器服务而生的一个可移植容器的编排管理工具，当前k8s已经主导了云业务流程，推动了微服务架构等热门技术、k8s主要包括以下几点：

**服务发现与调度、负载均衡、服务自愈、服务弹性扩容、横向扩容、存储卷挂载**



### 2、k8s集群架构

1）主节点：	承载k8s的控制和管理整个集群系统的控制面板

2）工作节点：运行用户实际的应用



![在这里插入图片描述](https://img-blog.csdnimg.cn/20201106161844633.png?pt=5&ek=1&kp=1&sce=0-12-12)



### 3、使用Rancher部署k8s

Rancher是业界唯一完全开源的企业级容器管理平台，为企业用户提供在生产环境中落地使用容器所需的一切功能与组件。
Rancher2.0基于Kubernetes构建，使用Rancher，DevOps团队可以轻松测试、部署和管理应用程序，运维团队可以部署、管理和维护一切Kubernetes集群，无论集群运行在何基础设施之上。



`docker pull rancher/rancher:v2.4.8`

`mkdir /home/rancher`

`docker run -d --privileged --name rancher -v /home/rancher:/var/lib/rancher --restart=unless-stopped -p 70:80 -p 442:443 rancher/rancher:v2.4.8`





--privileged                             ##使用该参数，[container](https://so.csdn.net/so/search?q=container&spm=1001.2101.3001.7020)内的root拥有真正的root权限,甚至允许你在docker容器中启动docker容器

--restart=unless-stopped		##在容器退出时总是重启容器，但是不考虑在Docker守护进程启动时就已经停止了的容器

