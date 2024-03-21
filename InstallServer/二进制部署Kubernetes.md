# 二进制部署Kubernetes

[TOC]









### **Kubernetes的重要概念**



##### **Cluster** 

Cluster 是计算、存储和网络资源的集合，Kubernetes 利用这些资源运行各种基于容器的应用。

##### **Master** 

Master 是 Cluster 的大脑，它的主要职责是调度，即决定将应用放在哪里运行。Master 运行 Linux 操作系统，可以是物理机或者虚拟机。为了实现高可用，可以运行多个 Master。

##### **Node** 

Node 的职责是运行容器应用。Node 由 Master 管理，Node 负责监控并汇报容器的状态，并根据 Master 的要求管理容器的生命周期。Node 运行在 Linux 操作系统，可以是物理机或者是虚拟机。

##### **Pod** 

Pod 是 Kubernetes 的最小工作单元。每个 Pod 包含一个或多个容器。Pod 中的容器会作为一个整体被 Master 调度到一个 Node 上运行。

**Kubernetes 引入 Pod 主要基于下面两个目的：**

1. 1. 可管理性。
      有些容器天生就是需要紧密联系，一起工作。Pod 提供了比容器更高层次的抽象，将它们封装到一个部署单元中。Kubernetes 以 Pod 为最小单位进行调度、扩展、共享资源、管理生命周期。
   2. 通信和资源共享。
      Pod 中的所有容器使用同一个网络 namespace（命名空间），即相同的 IP 地址和 Port 空间。它们可以直接用 localhost 通信。同样的，这些容器可以共享存储，当 Kubernetes 挂载 volume 到 Pod，本质上是将 volume 挂载到 Pod 中的每一个容器。

**Pods 有两种使用方式：**

1. 1. 运行单一容器。
      `one-container-per-Pod` （每一个容器一个pod）是 Kubernetes 最常见的模型，这种情况下，只是将单个容器简单封装成 Pod。即便是只有一个容器，Kubernetes 管理的也是 Pod 而不是直接管理容器。
   2. 运行多个容器。
      但问题在于：哪些容器应该放到一个 Pod 中？ 
      答案是：这些容器联系必须 非常紧密，而且需要 直接共享资源。



举个例子。

下面这个 Pod 包含两个容器：一个 File Puller，一个是 Web Server。

content Manager：内容管理者					consumers：消费者

![image-20220323010408925](C:\Users\小贤\AppData\Roaming\Typora\typora-user-images\image-20220323010408925.png)

File Puller 会定期从外部的 Content Manager 中拉取最新的文件，将其存放在共享的 volume 中。Web Server 从 volume 读取文件，响应 Consumer 的请求。

这两个容器是紧密协作的，它们一起为 Consumer 提供最新的数据；同时它们也通过 volume 共享数据。所以放到一个 Pod 是合适的。

再来看一个反例：是否需要将 Tomcat 和 MySQL 放到一个 Pod 中？

Tomcat 从 MySQL 读取数据，它们之间需要协作，但还不至于需要放到一个 Pod 中一起部署，一起启动，一起停止。同时它们是之间通过 JDBC 交换数据，并不是直接共享存储，所以放到各自的 Pod 中更合适。 

##### **Controller（控制器）** 

Kubernetes 通常不会直接创建 Pod，而是通过 Controller 来管理 Pod 的。Controller 中定义了 Pod 的部署特性，比如有几个副本，在什么样的 Node 上运行等。为了满足不同的业务场景，Kubernetes 提供了多种 Controller，包括 **Deployment、ReplicaSet、DaemonSet、StatefuleSet、Job** 等，我们逐一讨论。

**Deployment**（部署） 是最常用的 Controller，比如前面在线教程中就是通过创建 Deployment 来部署应用的。Deployment 可以管理 Pod 的多个副本，并确保 Pod 按照期望的状态运行。

**ReplicaSet（副本集）** 实现了 Pod 的多副本管理。使用 Deployment 时会自动创建 ReplicaSet，也就是说 Deployment 是通过 ReplicaSet 来管理 Pod 的多个副本，我们通常不需要直接使用 ReplicaSet。

**DaemonSet（守护进程集）** 用于每个 Node 最多只运行一个 Pod 副本的场景。正如其名称所揭示的，DaemonSet 通常用于运行 daemon。

**StatefuleSet（有状态集）** 能够保证 Pod 的每个副本在整个生命周期中名称是不变的。而其他 Controller 不提供这个功能，当某个 Pod 发生故障需要删除并重新启动时，Pod 的名称会发生变化。同时 StatefuleSet 会保证副本按照固定的顺序启动、更新或者删除。

**Job** 用于运行结束就删除的应用。而其他 Controller 中的 Pod 通常是长期持续运行。

##### **Service（服务）** 

Deployment 可以部署多个副本，每个 Pod 都有自己的 IP，外界如何访问这些副本呢？

通过 Pod 的 IP 吗？
要知道 Pod 很可能会被频繁地销毁和重启，它们的 IP 会发生变化，用 IP 来访问不太现实。

答案是 Service。
Kubernetes Service 定义了外界访问一组特定 Pod 的方式。Service 有自己的 IP 和端口，Service 为 Pod 提供了负载均衡。

Kubernetes 运行容器（Pod）与访问容器（Pod）这两项任务分别由 Controller 和 Service 执行。 

##### **Namespace（命名空间）**

如果有多个用户或项目组使用同一个 Kubernetes Cluster，如何将他们创建的 Controller、Pod 等资源分开呢？

答案就是 Namespace。
Namespace 可以将一个物理的 Cluster 逻辑上划分成多个虚拟 Cluster，每个 Cluster 就是一个 Namespace。不同 Namespace 里的资源是完全隔离的。

Kubernetes 默认创建了两个 Namespace。

```
[root@linux-node1 ~]# kubectl get namespace
NAME          STATUS    AGE
default       Active    1d
kube-system   Active    1d
```

**`default`** -- 创建资源时如果不指定，将被放到这个 Namespace 中。

**`kube-system`** -- Kubernetes 自己创建的系统资源将放到这个 Namespace 中。



### Kubernetes架构和集群规划

- ### （1）Kubernetes架构

![img](https://images2018.cnblogs.com/blog/1349539/201807/1349539-20180706110354540-513539099.png)

- ### （2）K8S架构拆解图

![img](https://images2018.cnblogs.com/blog/1349539/201807/1349539-20180706110412085-561909306.png)

##### **`K8S Master`节点**

**从上图可以看到，Master是K8S集群的核心部分，主要运行着以下的服务：kube-apiserver（kube接口服务）、kube-scheduler（kube调度器）、kube-controller-manager（Kube控制器经理）、etcd和Pod网络（如：flannel）**

```
API Server：K8S对外的唯一接口，提供HTTP/HTTPS RESTful API，即kubernetes API。所有的请求都需要经过这个接口进行通信。主要处理REST操作以及更新ETCD中的对象。是所有资源增删改查的唯一入口。 
Scheduler：资源调度，负责决定将Pod放到哪个Node上运行。Scheduler在调度时会对集群的结构进行分析，当前各个节点的负载，以及应用对高可用、性能等方面的需求。 
Controller Manager：负责管理集群各种资源，保证资源处于预期的状态。Controller Manager由多种controller组成，包括replication controller、endpoints controller、namespace controller、serviceaccounts controller等 
ETCD：负责保存k8s 集群的配置信息和各种资源的状态信息，当数据发生变化时，etcd会快速地通知k8s相关组件。Pod网络：Pod要能够相互间通信，K8S集群必须部署Pod网络，flannel是其中一种的可选方案。
```

##### **`K8S Node`节点**

***\*Node是Pod运行的地方，Kubernetes支持Docker、rkt等容器Runtime。Node上运行的K8S组件包括kubelet（kube从节点）、kube-proxy（kube代理）和Pod网络。\****

```
Kubelet：kubelet是node的agent，当Scheduler确定在某个Node上运行Pod后，会将Pod的具体配置信息（image、volume等）发送给该节点的kubelet，kubelet会根据这些信息创建和运行容器，并向master报告运行状态。
Kube-proxy：service在逻辑上代表了后端的多个Pod，外界通过service访问Pod。service接收到请求就需要kube-proxy完成转发到Pod的。每个Node都会运行kube-proxy服务，负责将访问的service的TCP/UDP数据流转发到后端的容器，如果有多个副本，kube-proxy会实现负载均衡，有2种方式：LVS或者Iptables 
Docker Engine：负责节点的容器的管理工作
```

**Kubernetes中pod创建流程**

　　Pod是Kubernetes中最基本的部署调度单元，可以包含container，逻辑上表示某种应用的一个实例。例如一个web站点应用由前端、后端及数据库构建而成，这三个组件将运行在各自的容器中，那么我们可以创建包含三个container的pod。

![img](https://images2018.cnblogs.com/blog/1349539/201808/1349539-20180815162434680-131252737.png)

**具体的创建步骤包括：**

（1）客户端提交创建请求，可以通过API Server的Restful API，也可以使用kubectl命令行工具。支持的数据类型包括JSON和YAML。

（2）API Server处理用户请求，存储Pod数据到etcd。

（3）调度器通过API Server查看未绑定的Pod。尝试为Pod分配主机。

（4）过滤主机 (调度预选)：调度器用一组规则过滤掉不符合要求的主机。比如Pod指定了所需要的资源量，那么可用资源比Pod需要的资源量少的主机会被过滤掉。

（5）主机打分(调度优选)：对第一步筛选出的符合要求的主机进行打分，在主机打分阶段，调度器会考虑一些整体优化策略，比如把容一个Replication Controller的副本分布到不同的主机上，使用最低负载的主机等。

（6）选择主机：选择打分最高的主机，进行binding操作，结果存储到etcd中。

（7）kubelet根据调度结果执行Pod创建操作： 绑定成功后，scheduler会调用APIServer的API在etcd中创建一个boundpod对象，描述在一个工作节点上绑定运行的所有pod信息。运行在每个工作节点上的kubelet也会定期与etcd同步boundpod信息，一旦发现应该在该工作节点上运行的boundpod对象没有更新，则调用Docker API创建并启动pod内的容器。









## 环境准备与规划

| 角色   | IP              | 组件                                                         |
| ------ | --------------- | ------------------------------------------------------------ |
| master | 192.168.162.128 | etcd、kube-apisever、kube-controller-manager、kube-scheduler |
| node1  | 192.168.162.129 | kube-proxy、kubelet、docker、flannel、etcd                   |
| node2  | 192.168.162.130 | kube-proxy、kubelet、docker、flannel、etcd                   |

![img](https://images2018.cnblogs.com/blog/1349539/201808/1349539-20180817114911404-1641639402.png) 

- 关闭防护墙、SElinux、swap

  ```
  systemctl stop firewalld
  systemctl disable firewalld
  
  sed -i 's/enforcing/disabled/' /etc/selinux/config
  
  swapoff -a
  sed -ri 's/.*swap.*/#&/' /etc/fstab
  ```

- 修改主机名称

  ```shell
  vim /etc/hostname
  k8s-master
  
  reboot
  ```

- 在master中添加hosts

  ```shell
  cat >> /etc/hosts << EOF
  192.168.162.128 k8s-master
  192.168.162.129 k8s-node1
  192.168.162.130 k8s-node2
  EOF
  ```

  

- 将桥接的IPv4流量传递到iptables的链

```shell
cat >>/etc/sysctl.d/k8s.conf  << EOF
#开启网桥模式，可将网桥的流量传递给iptables链
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
#关闭ipv6协议
net.ipv6.conf.all.disable_ipv6=1
net.ipv4.ip_forward=1
EOF
sysctl --system
```

- 时间同步

  ```shell
  ansible all -m yum -a 'name=ntpdate state=latest'
  ansible all -m command -a 'ntpdate time.windows.com'
  
  或者每个主机上手工执行
  yum -y install ntpdate
  ntpdate time.windows.com
  ```

  




### 1.Master组件安装



######  签发证书（k8s-master）

CFSSL是CloudFlare公司开源的一款PKI/TLS工具。CFSSL包含一个命令行工具和一个用于签名、验证和捆绑TLS证书的HTTP API服务，使用Go语言编写。
CFSSL使用配置文件生成证书，因此自签之前，需要生成它识别的json格式的配置文件，CFSSL提供了方便的命令行生成配置文件。
CFSSL用来为etcd提供TLS证书，它支持签三种类型的证书：

1. client证书，服务端连接客户端时携带的证书，用于客户端验证服务端身份，如kube-apiserver访问etcd；
2. server证书，客户端连接服务端时携带的证书，用于服务端验证客户端身份，如etcd对外提供服务；
3. peer证书，相互之间连接时使用的证书，如etcd节点之间进行验证和通信。



------

###### 下载证书制作工具



```shell
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -O /usr/local/bin/cfssl
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -O /usr/local/bin/cfssljson
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -O /usr/local/bin/cfssl-certinfo
chmod +x /usr/local/bin/cfssl*

cfssl：证书签发的工具命令
cfssljson：将cfssl生成的证书（json格式）变为文件承载式证书
cfssl-certinfo：验证证书的信息
"cfssl-certinfo -cert <证书名称> ”可查看证书的信息
```

------



#### 1.1	服务证书

------

###### 1.1.1 需要准备的证书：

- admin-key.pem

- admin.pem

- ca-key.pem

- ca.pem

- kube-proxy-key.pem

- kube-proxy.pem

- kubernetes-key.pem

- kubernetes.pem



使用证书的组件如下：

- etcd：使用 ca-key.pem、ca.pem 、server-key.pem、server.pem

- kube-apiserver：使用 ca.pem、ca-key、apiserver-key.pem、apiserver.pem

- kube-proxy：使用 ca.pem、kube-proxy-key.pem、kube-proxy.pem

- kubectl：使用 ca.pem、admin.pem、admin-key.pem



-----------------------------------

###### 1.1.2 创建根证书配置文件



```shell
#创建CA证书

创建存放证书目录

mkdir -p /opt/kubernetes/ssl/
cd /opt/kubernetes/ssl/

#创建证书配置文件

vim ca-config.json
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}

字段说明：
ca-config.json：可以定义多个 profiles，分别指定不同的过期时间、使用场景等参数；后续在签名证书时使用某个 profile；
signing：表示该证书可以签名其他证书；生成的ca.pem证书中 CA=TRUE；
server auth：表示client可以用该 CA 对server提供的证书进行验证；
client auth：表示server可以用该CA对client提供的证书进行验证；
expiry：过期时间
```



```shell
#创建CA证书签名请求文件

vim ca-csr.json
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ],
    "ca": {
       "expiry": "87600h"
    }
}

字段说明：

“CN”：Common Name，kube-apiserver 从证书中提取该字段作为请求的用户名 (User Name)；浏览器使用该字段验证网站是否合法；
“O”：Organization，kube-apiserver 从证书中提取该字段作为请求用户所属的组 (Group)；
```



```shell
#生成CA证书和私钥

cfssl gencert -initca ca-csr.json | cfssljson -bare ca
ls | grep ca
ca-config.json
ca.csr
ca-csr.json
ca-key.pem
ca.pem

其中ca-key.pem是ca的私钥，ca.csr是一个签署请求，ca.pem是CA证书，是后面kubernetes组件会用到的RootCA。
```



###### 1.1.3 创建kubernetes证书

```shell 
创建kubernetes证书签名请求文件 kubernetes-csr.json

vim kubernetes-csr.json
{
    "CN": "kubernetes",
    "hosts": [
      "127.0.0.1",
      "192.168.162.128",
      "192.168.162.129",
      "192.168.162.130",
      "10.0.0.0/24",
      "kubernetes",
      "kube-api.wangdong.com",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "BeiJing",
            "L": "BeiJing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}

字段说明：

如果 hosts 字段不为空则需要指定授权使用该证书的 IP 或域名列表。

由于该证书后续被 etcd 集群和 kubernetes master使用，将etcd、master节点的IP都填上，同时还有service网络的首IP。(一般是 kube-apiserver 指定的 service-cluster-ip-range 网段的第一个IP，如 10.0.0.0/24 )

我这里的设置包括三个etcd，1个master，以上物理节点的IP也可以更换为主机名。
```





###### 1.1.4 生成kubernetes证书和私钥

```shell
生成kubernetes证书和私钥

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

ls |grep kubernetes
kubernetes.csr
kubernetes-csr.json
kubernetes-key.pem
kubernetes.pem
```





###### 1.1.5 创建admin证书签名请求文件admin-csr.json

```shell
#创建admin证书

admin-csr.json
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "system:masters",
      "OU": "System"
    }
  ]
}

说明：

后续 kube-apiserver 使用 RBAC 对客户端(如 kubelet、kube-proxy、Pod)请求进行授权；

kube-apiserver 预定义了一些 RBAC 使用的 RoleBindings，如 cluster-admin 将 Group system:masters 与 Role cluster-admin 绑定，该 Role 授予了调用kube-apiserver 的所有 API的权限；

O指定该证书的 Group 为 system:masters，kubelet 使用该证书访问 kube-apiserver 时 ，由于证书被 CA 签名，所以认证通过，同时由于证书用户组为经过预授权的 system:masters，所以被授予访问所有 API 的权限；

注：这个admin 证书，是将来生成管理员用的kube config 配置文件用的，现在我们一般建议使用RBAC 来对kubernetes 进行角色权限控制， kubernetes 将证书中的CN 字段 作为User， O 字段作为 Group
```



###### 1.1.6 生成admin证书和私钥

```shell
 cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin

ls | grep admin
admin.csr
admin-csr.json
admin-key.pem
admin.pem
```





###### 1.1.7 创建kube-proxy证书

```shell
创建 kube-proxy 证书签名请求文件 kube-proxy-csr.json

vim kube-proxy-csr.json
{
  "CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}

说明：

CN 指定该证书的 User 为 system:kube-proxy；

kube-apiserver 预定义的 RoleBinding system:node-proxier 将User system:kube-proxy 与 Role system:node-proxier 绑定，该 Role 授予了调用 kube-apiserver Proxy 相关 API 的权限；
```



###### 1.1.8 生成kube-proxy证书和私钥

```shell
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes  kube-proxy-csr.json | cfssljson -bare kube-proxy
 
ls |grep kube-proxy
kube-proxy.csr
kube-proxy-csr.json
kube-proxy-key.pem
kube-proxy.pem

经过上述操作，我们会用到如下文件：

ls | grep pem
admin-key.pem
admin.pem
ca-key.pem
ca.pem
kube-proxy-key.pem
kube-proxy.pem
kubernetes-key.pem
kubernetes.pem
```





###### 1.1.9 查看证书信息

```shell
cfssl-certinfo -cert kubernetes.pem
{
  "subject": {
    "common_name": "kubernetes",
    "country": "CN",
    "organization": "k8s",
    "organizational_unit": "System",
    "locality": "BeiJing",
    "province": "BeiJing",
    "names": [
      "CN",
      "BeiJing",
      "BeiJing",
      "k8s",
      "System",
      "kubernetes"
    ]
  },
  "issuer": {
    "common_name": "kubernetes",
    "country": "CN",
    "organization": "k8s",
    "organizational_unit": "System",
    "locality": "BeiJing",
    "province": "BeiJing",
    "names": [
      "CN",
      "BeiJing",
      "BeiJing",
      "k8s",
      "System",
      "kubernetes"
    ]
  },
  "serial_number": "307090529115608935130449510158686817396429767663",
  "sans": [
    "kubernetes",
    "kube-api.wangdong.com",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local",
    "127.0.0.1",
    "192.168.162.128",
    "192.168.162.129",
    "192.168.162.130"
  ],
  "not_before": "2022-05-09T06:07:00Z",
  "not_after": "2032-05-06T06:07:00Z",
  "sigalg": "SHA256WithRSA",
  "authority_key_id": "16:2D:26:E6:61:F3:DD:7:1C:1F:15:54:63:46:56:37:7C:EE:A:E1",
  "subject_key_id": "DD:DF:83:8B:B:54:E0:93:C3:D8:67:CA:1D:4C:6D:C1:A7:11:C6:E8",
  "pem": "-----BEGIN CERTIFICATE-----\nMIIEljCCA36gAwIBAgIUNcpqY2qDJ6dTDV5TcGD0kD85Q+8wDQYJKoZIhvcNAQEL\nBQAwZTELMAkGA1UEBhMCQ04xEDAOBgNVBAgTB0JlaUppbmcxEDAOBgNVBAcTB0Jl\naUppbmcxDDAKBgNVBAoTA2s4czEPMA0GA1UECxMGU3lzdGVtMRMwEQYDVQQDEwpr\ndWJlcm5ldGVzMB4XDTIyMDUwOTA2MDcwMFoXDTMyMDUwNjA2MDcwMFowZTELMAkG\nA1UEBhMCQ04xEDAOBgNVBAgTB0JlaUppbmcxEDAOBgNVBAcTB0JlaUppbmcxDDAK\nBgNVBAoTA2s4czEPMA0GA1UECxMGU3lzdGVtMRMwEQYDVQQDEwprdWJlcm5ldGVz\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxfUc+fuk/5cs+20Lmzig\nH5l8NUq+rrOJVo6lMHrcxI8Xutf8SKWBkvWk3WJq2B4FGHCEZR1HmXUl6CzGabab\nLfJUV+lmV//Cndd3rQwPLi64T6RIt62QTkv2Y153cBTORwyCgKzxiWVdvf9XZ2eO\naEsvvG2mKjKw2AUcioUkpJSNrldOBmh1498GsGOJLqDi6Xs+ytGZPLGoFEZu9xuE\n8r73/ivEv8/atZSmi87b/Yqqu1XyvQFU1Hn0UINS1GHa0tYCvGSGKq3frQaQK/1r\nMD4cgxi2Fr/jasHOIqpcn55jTIXHwPYsEJnCrPeI0WCscPideoFCNrfPvlgquhFa\nqQIDAQABo4IBPDCCATgwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUF\nBwMBBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTd34OLC1Tgk8PY\nZ8odTG3BpxHG6DAfBgNVHSMEGDAWgBQWLSbmYfPdBxwfFVRjRlY3fO4K4TCBuAYD\nVR0RBIGwMIGtggprdWJlcm5ldGVzghVrdWJlLWFwaS53YW5nZG9uZy5jb22CEmt1\nYmVybmV0ZXMuZGVmYXVsdIIWa3ViZXJuZXRlcy5kZWZhdWx0LnN2Y4Iea3ViZXJu\nZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVygiRrdWJlcm5ldGVzLmRlZmF1bHQuc3Zj\nLmNsdXN0ZXIubG9jYWyHBH8AAAGHBMCoooCHBMCoooGHBMCoooIwDQYJKoZIhvcN\nAQELBQADggEBALZTfoXSXj58pS1uIYT5ksVScFXDqUZt/yZnyuiy3NrKvRPNY+v+\nN7aUZh8YRz7pLAsY/xUG0w+ZESohhYa+8cDCww8sHriuggCZSV3bWG2nt5zhR/rN\ncdBPwWQq7jDq4F/6Q28Q7nB2L627L5mJp/LnwXBKRee4edGhK+ebAKh7hbZ79lbz\nNqdoy9AyOZpgiQ01ZD2XGm4jJkEpRqKgTKbZo8iW+Xb/y90GgrKjcPkB0JEotM+g\nRwpfMFPsrB7Pt9E9m8zyrShomz7ytd379DGIdEQYTsuIp5Bqzw+RHA6QzK3XzDsd\nOgvzKTRoAwnCf0N2HFZtd1Yoc5dlzwE+wHM=\n-----END CERTIFICATE-----\n"

在搭建k8s集群的时候，将这些文件分发到至此集群中其他节点机器中即可。至此，TLS证书创建完毕。
```





#### 1.2	etcd概述

###### 1.2.1 etcd简介

etcd是CoreOS团队于2013年6月发起的开源项目，它的目标是一个高可用的分布式键值（key-value）数据库。etcd内部采用raft协议作为一致性算法，etcd是go语言编写的。



------



###### 1.2.2 etcd特点

etcd作为服务发现系统，有以下的特点：
简单：安装配置简单，而且提供了HTTP API进行交互，使用也很简单
安全：支持SSL证书验证
快速：单实例支持每秒2k+读写操作
可靠：采用raft算法，实现分布式系统数据的可用性和一致性



------



###### 1.2.3 etcd端口

etcd目前默认使用2379端口提供HTTP API服务，2380端口和peer通信（这两个端口已经被IANA（互联网数字分配机构）官方预留给etcd）。即etcd默认使用2379端口对外为客户端提供通讯，使用端口2380来进行服务器间内部通讯。
etcd在生产环境中一般推荐集群方式部署。由于etcd的leader选举机制，要求至少为3台或以上的奇数台。



------





###### 1.2.4 安装etcd master



1、下载安装包	`https://github.com/etcd-io/etcd/releases`

通过lrzsz将二进制包上传到创建的目录中

```
mkdir -p /opt/bin/{bin,cfg,ssl}
tar -zxvf etcd-v3.5.2-linux-amd64.tar.gz
cd etcd-v3.5.2-linux-amd64/
cp etcd etcdctl /opt/etcd/bin/

#把刚刚配置的证书放到/opt/etcd/ssl/
```





```shell
#编写etcd配置文件


cat >> /opt/etcd/cfg/etcd <<EOF
#[Member]
ETCD_NAME="etcd01"
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.162.128:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.162.128:2379"
 
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.162.128:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.162.128:2379"
ETCD_INITIAL_CLUSTER="etcd01=https://192.168.162.128:2380,etcd02=https://192.168.162.129:2380,etcd03=https://192.168.162.130:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF
 
#Member:成员配置
#ETCD_NAME：节点名称，集群中唯一。成员名字，集群中必须具备唯一性，如etcd01
#ETCD_DATA_DIR：数据目录。指定节点的数据存储目录，这些数据包括节点ID，集群ID，集群初始化配置，Snapshot文件，若未指定-wal-dir，还会存储WAL文件；如果不指定会用缺省目录
#ETCD_LISTEN_PEER_URLS：集群通信监听地址。用于监听其他member发送信息的地址。ip为全0代表监听本机所有接口
#ETCD_LISTEN_CLIENT_URLS：客户端访问监听地址。用于监听etcd客户发送信息的地址。ip为全0代表监听本机所有接口
 
#Clustering：集群配置
#ETCD_INITIAL_ADVERTISE_PEER_URLS：集群通告地址。其他member使用，其他member通过该地址与本member交互信息。一定要保证从其他member能可访问该地址。静态配置方式下，该参数的value一定要同时在--initial-cluster参数中存在
#ETCD_ADVERTISE_CLIENT_URLS：客户端通告地址。etcd客户端使用，客户端通过该地址与本member交互信息。一定要保证从客户侧能可访问该地址
#ETCD_INITIAL_CLUSTER：集群节点地址。本member使用。描述集群中所有节点的信息，本member根据此信息去联系其他member
#ETCD_INITIAL_CLUSTER_TOKEN：集群Token。用于区分不同集群。本地如有多个集群要设为不同
#ETCD_INITIAL_CLUSTER_STATE：加入集群的当前状态，new是新集群，existing表示加入已有集群。
```



```shell
#编写etcd使用systemctl命令启动脚本

cat >> /usr/lib/systemd/system/etcd.service <<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
 
[Service]
Type=notify
EnvironmentFile=/opt/etcd/cfg/etcd
ExecStart=/opt/etcd/bin/etcd \
--name=etcd01 \
--data-dir="/var/lib/etcd/" \
--listen-peer-urls=https://192.168.162.128:2380 \
--listen-client-urls=https://192.168.162.128:2379,http://127.0.0.1:2379 \
--advertise-client-urls=https://192.168.162.128:2379 \
--initial-advertise-peer-urls=https://192.168.162.128:2380 \
--initial-cluster=etcd01=https://192.168.162.128:2380,etcd02=https://192.168.162.129:2380,etcd03=https://192.168.162.130:2380 \
--initial-cluster-token="etcd-cluster" \
--initial-cluster-state=new \
--cert-file=/opt/etcd/ssl/server.pem \
--key-file=/opt/etcd/ssl/server-key.pem \
--trusted-ca-file=/opt/etcd/ssl/ca.pem \
--peer-cert-file=/opt/etcd/ssl/server.pem \
--peer-key-file=/opt/etcd/ssl/server-key.pem \
--peer-trusted-ca-file=/opt/etcd/ssl/ca.pem
Restart=on-failure
LimitNOFILE=65536
 
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload 
systemctl enable etcd.service
systemctl start etcd.service
```



###### 1.2.5 安装etcd node

```shell
##传输etcd目录里面包含了bin,cfg,ssl
scp -r /opt/etcd/ root@192.168.162.129:/opt/etcd/
scp -r /opt/etcd/ root@192.168.162.130:/opt/etcd/

##传输etcd systemctl启动配置文件
scp /usr/lib/systemd/system/etcd.service root@192.168.162.129:/usr/lib/systemd/system/
scp /usr/lib/systemd/system/etcd.service root@192.168.162.130:/usr/lib/systemd/system/

##修改node节点上配置
cat /opt/etcd/cfg/etcd
#[Member]
ETCD_NAME="etcd02"                   ##名称修改
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="https://192.168.162.129:2380"     ##修改url ip地址
ETCD_LISTEN_CLIENT_URLS="https://192.168.162.129:2379"
 
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.162.129:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.162.129:2379"
ETCD_INITIAL_CLUSTER="etcd01=https://192.168.162.128:2380,etcd02=https://192.168.162.129:2380,etcd03=https://192.168.162.130:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"



cat /usr/lib/systemd/system/etcd.service 
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
 
[Service]
Type=notify
EnvironmentFile=/opt/etcd/cfg/etcd
ExecStart=/opt/etcd/bin/etcd \
--name=etcd02 \
--data-dir="/var/lib/etcd/default.etcd" \
--listen-peer-urls=https://192.168.162.129:2380 \
--listen-client-urls=https://192.168.162.129:2379,http://127.0.0.1:2379 \
--advertise-client-urls=https://192.168.162.129:2379 \
--initial-advertise-peer-urls=https://192.168.162.129:2380 \
--initial-cluster=etcd01=https://192.168.162.128:2380,etcd02=https://192.168.162.129:2380,etcd03=https://192.168.162.130:2380 \
--initial-cluster-token="etcd-cluster" \
--initial-cluster-state=new \
--cert-file=/opt/etcd/ssl/server.pem \
--key-file=/opt/etcd/ssl/server-key.pem \
--trusted-ca-file=/opt/etcd/ssl/ca.pem \
--peer-cert-file=/opt/etcd/ssl/server.pem \
--peer-key-file=/opt/etcd/ssl/server-key.pem \
--peer-trusted-ca-file=/opt/etcd/ssl/ca.pem
Restart=on-failure
LimitNOFILE=65536
 
[Install]
WantedBy=multi-user.target

systemctl daemon-reload 
systemctl enable etcd.service
systemctl start etcd.service
```



###### 1.2.5 启动etcd，查看健康状态

```shell
systemctl status etcd
● etcd.service - Etcd Server
   Loaded: loaded (/usr/lib/systemd/system/etcd.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2022-04-21 23:32:58 CST; 4h 29min ago
 Main PID: 1093 (etcd)
    Tasks: 9
   CGroup: /system.slice/etcd.service
           └─1093 /opt/etcd/bin/etcd --name=etcd01 --data-dir="/var/lib/etcd/" --listen-peer-urls=https://192.168.162.128:2380 --listen-client-urls=https://192.168.162.128:23...

Apr 22 03:47:17 k8s-master etcd[1093]: the clock difference against peer 96985c19373a3b9e is too high [3.101724285s > 1s]
Apr 22 03:48:17 k8s-master etcd[1093]: the clock difference against peer 96985c19373a3b9e is too high [2.781711024s > 1s]
Apr 22 03:49:19 k8s-master etcd[1093]: the clock difference against peer 96985c19373a3b9e is too high [2.505940661s > 1s]
Apr 22 03:50:20 k8s-master etcd[1093]: the clock difference against peer 96985c19373a3b9e is too high [1.428231646s > 1s]
Apr 22 03:51:50 k8s-master etcd[1093]: the clock difference against peer 96985c19373a3b9e is too high [3.264637673s > 1s]
Apr 22 03:53:56 k8s-master etcd[1093]: the clock difference against peer 96985c19373a3b9e is too high [1.452784275s > 1s]
Apr 22 04:00:23 k8s-master etcd[1093]: the clock difference against peer 96985c19373a3b9e is too high [1.915457473s > 1s]
Apr 22 04:00:53 k8s-master etcd[1093]: the clock difference against peer 96985c19373a3b9e is too high [3.370293856s > 1s]
Apr 22 04:01:56 k8s-master etcd[1093]: the clock difference against peer 96985c19373a3b9e is too high [2.975050571s > 1s]
Apr 22 04:02:23 k8s-master etcd[1093]: the clock difference against peer d80c93549990874e is too high [4.508892143s > 1s]


##查看集群状态
./opt/etcd/bin/etcdctl --endpoints=https://192.168.162.128:2379,https://192.168.162.129:2379,https://192.168.162.130:2379 --ca-file=/opt/etcd/ssl/ca.pem --cert-file=/opt/etcd/ssl/server.pem --key-file=/opt/etcd/ssl/server-key.pem  cluster-health

member 8de9442b117cf886 is healthy: got healthy result from https://192.168.162.128:2379
member 96985c19373a3b9e is healthy: got healthy result from https://192.168.162.129:2379
member d80c93549990874e is healthy: got healthy result from https://192.168.162.130:2379


--cert-file：识别HTTPS端使用SSL证书文件
--key-file：使用此SSL密钥文件标识HTTPS客户端
--ca-file：使用此CA证书验证启用https的服务器的证书
--endpoints：集群中以逗号分隔的机器地址列表
cluster-health：检查etcd集群的运行状况
```



```shell
##由于每次输入查看命令都很麻烦，可以把它设置为全局变量并且重命名
vim ~/.bashrc
alias etcdstatus='./etcdctl --endpoints=https://192.168.162.128:2379,https://192.168.162.129:2379,https://192.168.162.130:2379 --ca-file=/opt/etcd/ssl/ca.pem --cert-file=/opt/etcd/ssl/server.pem --key-file=/opt/etcd/ssl/server-key.pem  cluster-health'

#使环境变量生效
source ~/.bashrc

#把etcdctl移动到/usr/local/bin
cp /opt/etcd/bin/etcdctl /usr/local/bin/

#添加软连接
ln -s /usr/local/bin/etcdctl
```



###### 1.2.6 切换v3版本查看健康状态

```shell
#切换到etcd3版本查看集群节点状态和成员列表  v2和v3命令略有不同，etcd2和etcd3也是不兼容的，默认版本是v2版本
export ETCDCTL_API=3


etcdctl --write-out=table endpoint status
+----------------+------------------+---------+---------+-----------+-----------+------------+
|    ENDPOINT    |        ID        | VERSION | DB SIZE | IS LEADER | RAFT TERM | RAFT INDEX |
+----------------+------------------+---------+---------+-----------+-----------+------------+
| 127.0.0.1:2379 | 8de9442b117cf886 |  3.2.12 |   25 kB |     false |      1135 |         49 |
+----------------+------------------+---------+---------+-----------+-----------+------------+

#显示成员列表
etcdctl --write-out=table member list

#切换回v2版本
export ETCDCTL_API=2  
```

------





#### 1.3 Flannel网络配置



###### 1.3.1 K8S中Pod网络通信



![img](https://img2020.cnblogs.com/blog/2391905/202110/2391905-20211027183825676-153149742.png)



- **Pod内容器与容器之间的通信**
  在同一个Pod内的容器（Pod内的容器是不会跨宿主机的）共享同一个网络命令空间，相当于它们在同一台机器上一样，可以用localhost地址访问彼此的端口。

- **同一个Node内Pod之间的通信**
  每个Pod都有一个真实的全局IP地址，同一个Node内的不同Pod之间可以直接采用对方Pod的IP地址进行通信，Pod1与Pod2都是通过Veth连接到同一个docker0网桥，网段相同，所以它们之间可以直接通信。

-  **不同Node上Pod之间的通信**
  Pod地址与docker0在同一网段，docker0网段与宿主机网卡是两个不同的网段，且不同Node之间的通信只能通过宿主机的物理网卡进行。
  要想实现不同Node上Pod之间的通信，就必须想办法通过主机的物理网卡IP地址进行寻址和通信。因此要满足两个条件：Pod的IP不能冲突，将Pod的IP和所在的Node的IP关联起来，通过这个关联让不同Node上Pod之间直接通过内网IP地址通信。



###### 1.3.2 Flannel简介

Flannel的功能是让集群中的不同节点主机创建的Docker容器都具有全集群唯一的虚拟IP地址。
Flannel是Overlay网络的一种，也是将TCP源数据包封装在另一种网络包里面进行路由转发和通信，目前支持UDP、VXLAN、host-GW三种数据转发方式。

**Overlay Network**

叠加网络，在二层或者三层几乎网络上叠加的一种虚拟网络技术模式，该网络中的主机通过虚拟链路隧道连接起来（类似于VPN）



###### 1.3.3 Flannnel工作原理

![img](https://img2020.cnblogs.com/blog/2391905/202110/2391905-20211027185006339-1072847392.png)



数据从node01上Pod的源容器中发出后，经由所在主机的docker0虚拟网卡转发到flannel.1虚拟网卡，flanneld服务监听在flanne.1数据网卡的另外一端。
Flannel通过Etcd服务维护了一张节点间的路由表。源主机node01的flanneld服务将原本的数据内容封装到UDP中后根据自己的路由表通过物理网卡投递给目的节点node02的flanneld服务，数据到达以后被解包，然后直接进入目的节点的dlannel.1虚拟网卡，之后被转发到目的主机的docker0虚拟网卡，最后就像本机容器通信一样由docker0转发到目标容器。



###### 1.3.4 ETCD之Flannel提供说明

存储管理Flannel可分配的IP地址段资源

监控ETCD中每个Pod的实际地址，并在内存中建立维护Pod节点路由表



###### 1.3.5 Flannel部署--在master01节点上操作



```cmake
[root@master01 ~]# cd /opt/etcd/ssl

##添加flannel网络配置信息，写入分配的子网段到etcd中，供flannel使用
/opt/etcd/bin/etcdctl \
--ca-file=/opt/etcd/ssl/ca.pem \
--cert-file=/opt/etcd/ssl/server.pem \
--key-file=/opt/etcd/ssl/server-key.pem \
--endpoints="https://192.168.162.128:2379,https://192.168.162.129:2379,https://192.168.162.130:2379" \
> set /coreos.com/network/config '{"Network":"172.17.0.0/16", "Backend":{"Type":"vxlan"}}'


##查看写入的信息

/opt/etcd/bin/etcdctl \
--ca-file=/opt/etcd/ssl/ca.pem \
--cert-file=/opt/etcd/ssl/server.pem \
--key-file=/opt/etcd/ssl/server-key.pem \
--endpoints="https://192.168.162.128:2379,https://192.168.162.129:2379,https://192.168.162.130:2379" \
get /coreos.com/network/config

{"Network":"172.17.0.0/16","Backend":{"Type":"vxlan"}}


set ：给键赋值
set /coreos.com/network/config：添加一条网络配置记录，这个配置将用于flannel分配给每个docker的虚拟IP地址段
get ：获取网络配置记录，后面不用再跟参数
Network：用于指定Flannel地址池
Backend：用于指定数据包以什么方式转发，默认为udp模式，Backend为vxlan比起预设的udp性能相对好一些。

```





###### 1.3.5 Flannel部署--**在所有node节点上操作**

```shell
##上传flannel安装包flannel-linux-amd64.tar.gz到/opt目录中
tar -zxvf flannel-v0.17.0-linux-amd64.tar.gz
ls
flanneld  flannel-v0.17.0-linux-amd64.tar.gz  mk-docker-opts.sh  README.md
#flanneld             为主要的执行文件
#mk-docker-opts.sh    脚本用于生成Docker启动参数
#README.md   		  自述文件


mkdir -p /opt/kubernetes/{cfg,bin,ssl}
mv mk-docker-opts.sh flanneld /opt/kubernetes/bin/
```

```shell
##创建flanneld配置文件
cat > /opt/kubernetes/cfg/flanneld <<EOF
FLANNEL_OPTIONS="-etcd-endpoints=https://192.168.162.128:2379,https://192.168.162.129:2379,https://192.168.162.130:2379 \
-etcd-cafile=/opt/etcd/ssl/ca.pem \
-etcd-certfile=/opt/etcd/ssl/server.pem \
-etcd-keyfile=/opt/etcd/ssl/server-key.pem"
EOF


##创建flanneld.service服务管理文件
cat > /usr/lib/systemd/system/flanneld.service <<EOF
[Unit]
Description=Flanneld overlay address etcd agent
After=network-online.target network.target
Before=docker.service
 
[Service]
Type=notify
EnvironmentFile=/opt/kubernetes/cfg/flanneld
ExecStart=/opt/kubernetes/bin/flanneld --ip-masq \$FLANNEL_OPTIONS
ExecStartPost=/opt/kubernetes/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/subnet.env
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
EOF

#flanneld启动后会使用 mk-docker-opts.sh 脚本生成 docker 网络相关配置信息
#mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS：将组合选项键设置为环境变量DOCKER_NETWORK_OPTIONS，docker启动时将使用此变量
#mk-docker-opts.sh -d /run/flannel/subnet.env：指定要生成的docker网络相关信息配置文件的路径，docker启动时候引用此配置
 
systemctl daemon-reload
systemctl enable flanneld
systemctl restart flanneld
```



node01

```shell
##flannel启动后会生成一个docker网络相关信息配置文件/run/flannel/subnet.env，包含了docker要使用flannel通讯的相关参数


cat /run/flannel/subnet.env
DOCKER_OPT_BIP="--bip=172.17.57.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=false"
DOCKER_OPT_MTU="--mtu=1450"
DOCKER_NETWORK_OPTIONS=" --bip=172.17.57.1/24 --ip-masq=false --mtu=1450"

--bip：指定docker启动时的子网
--ip-masq：设置ipmasq=false关闭snat伪装策略
--mtu=1450：mtu要留出50字节给外层的vxlan封包的额外开销使用



ifconfig 
docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 0.0.0.0
        ether 02:42:a4:f1:37:2c  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0


flannel.1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450
        inet 172.17.57.0  netmask 255.255.255.255  broadcast 0.0.0.0
        inet6 fe80::289a:3dff:fe2a:de08  prefixlen 64  scopeid 0x20<link>
        ether 2a:9a:3d:2a:de:08  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 23 overruns 0  carrier 0  collisions 0

........
```

node02

```shell
##flannel启动后会生成一个docker网络相关信息配置文件/run/flannel/subnet.env，包含了docker要使用flannel通讯的相关参数
cat /run/flannel/subnet.env
DOCKER_OPT_BIP="--bip=172.17.27.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=false"
DOCKER_OPT_MTU="--mtu=1450"
DOCKER_NETWORK_OPTIONS=" --bip=172.17.27.1/24 --ip-masq=false --mtu=1450"

--bip：指定docker启动时的子网
--ip-masq：设置ipmasq=false关闭snat伪装策略
--mtu=1450：mtu要留出50字节给外层的vxlan封包的额外开销使用



ifconfig 
docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 0.0.0.0
        ether 02:42:fb:51:fd:ca  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
        
flannel.1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450
        inet 172.17.27.0  netmask 255.255.255.255  broadcast 0.0.0.0
        inet6 fe80::ac83:7eff:fe03:8266  prefixlen 64  scopeid 0x20<link>
        ether ae:83:7e:03:82:66  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 20 overruns 0  carrier 0  collisions 0
        

```







###### 1.3.6 修改docker0网卡网段与flannel一致

```shell

vim /lib/systemd/system/docker.service 
 
#13行，插入环境文件
EnvironmentFile=/run/flannel/subnet.env

systemctl daemon-reload
systemctl restart docker

6: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default 
    link/ether 02:b1:e2:e9:e8:62 brd ff:ff:ff:ff:ff:ff
    inet 172.17.79.0/32 scope global flannel.1
       valid_lft forever preferred_lft forever
    inet6 fe80::b1:e2ff:fee9:e862/64 scope link 
       valid_lft forever preferred_lft forever
7: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:8a:95:6e:26 brd ff:ff:ff:ff:ff:ff
    inet 172.17.79.1/24 scope global docker0
       valid_lft forever preferred_lft forever

```





###### 1.3.7 容器间跨网通信

 ```shell
 docker run -itd centos:7 bash
 docker ps -a
 CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
 32f2b66969ac        centos:7            "bash"              21 hours ago        Up 21 hours                      awesome_davinci      
 ping -I 172.17.83.2 172.17.79.2
 
 ```







#### 1.4	kube-apiserver服务

###### 1.4.1 上传压缩包到/usr/local/k8s/

```shell
tar -zxvf kubernetes-server-linux-amd64.tar.gz

mkdir -p /opt/kubernetes/{bin,cfg,ssl}
cp kube-apiserver kube-controller-manager kube-scheduler /opt/kubernetes/bin/
```





###### 1.4.2 配置kube-apiserver启动参数

```shell
vim /opt/kubernetes/cfg/kube-apiserver
KUBE_APISERVER_OPTS="--logtostderr=true \
--v=4 \
--etcd-servers=https://192.168.162.128:2379,https://192.168.162.129:2379,https://192.168.162.130:2379 \
--bind-address=0.0.0.0 \
--secure-port=6443 \
--advertise-address=192.168.162.128 \
--allow-privileged=true \
--service-cluster-ip-range=10.0.0.0/24 \
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,NodeRestriction,DefaultStorageClass \
--authorization-mode=RBAC,Node \
--enable-bootstrap-token-auth \
--token-auth-file=/opt/kubernetes/cfg/token.csv \
--service-node-port-range=30000-32767 \
--tls-cert-file=/opt/kubernetes/ssl/apiserver.pem  \
--tls-private-key-file=/opt/kubernetes/ssl/apiserver-key.pem \
--client-ca-file=/opt/kubernetes/ssl/ca.pem \
--service-account-key-file=/opt/kubernetes/ssl/ca-key.pem \
--etcd-cafile=/opt/etcd/ssl/ca.pem \
--etcd-certfile=/opt/etcd/ssl/server.pem \
--etcd-keyfile=/opt/etcd/ssl/server-key.pem"


##KUBE_APISERVER_OPTS="--logtostderr=true \\   在向文件输出日志的同时，也将日志写到标准输出。
##--v=4 \\									日志级别详细程度的数字。v=4为调试级别详细输出	
##--etcd-servers=https://192.168.162.128:2379,https://192.168.162.129:2379,https://192.168.162.130:2379 \\	要连接的 etcd 服务器列表（scheme://ip:port），以逗号分隔。	
##--bind-address=0.0.0.0 \\  用来监听 --secure-port 端口的 IP 地址。 集群的其余部分以及 CLI/web 客户端必须可以访问所关联的接口。 如果为空白或未指定地址（0.0.0.0 或 ::），则将使用所有接口。
##--secure-port=6443 \\					默认值：6443  带身份验证和鉴权机制的 HTTPS 服务端口。 不能用 0 关闭。
##--advertise-address=192.168.162.128 \\   	向集群成员通知 apiserver 消息的 IP 地址。 这个地址必须能够被集群中其他成员访问。 如果 IP 地址为空，将会使用 --bind-address， 如果未指定 --bind-address，将会使用主机的默认接口地址。
##--allow-privileged=true \\				允许拥有系统特权的容器运行，默认值false
##--service-cluster-ip-range=10.0.0.0/24 \\     CIDR 表示的 IP 范围用来为服务分配集群 IP。 此地址不得与指定给节点或 Pod 的任何 IP 范围重叠。
##--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,NodeRestriction,DefaultStorageClass \\   启动插件
##--authorization-mode=RBAC,Node \\     在安全端口使用RBAC,Node授权模式，未通过授权的请求拒绝，默认值AlwaysAllow。RBAC是用户通过角色与权限进行关联的模式；Node模式（节点授权）是一种特殊用途的授权模式，专门授权由kubelet发出的API请求，在进行认证时，先通过用户名、用户分组验证是否是集群中的Node节点，只有是Node节点的请求才能使用Node模式授权
##--enable-bootstrap-token-auth \\                       启用以允许将 "kube-system" 名字空间中类型为 "bootstrap.kubernetes.io/token" 的 Secret 用于 TLS 引导身份验证。
##--token-auth-file=/opt/kubernetes/cfg/token.csv \\      如果设置该值，这个文件将被用于通过令牌认证来保护 API 服务的安全端口。
##--service-node-port-range=30000-32767 \\  默认值：30000-32767    保留给具有 NodePort 可见性的服务的端口范围。 例如："30000-32767"。范围的两端都包括在内。
##--tls-cert-file=/opt/kubernetes/ssl/apiserver.pem  \\     	包含用于 HTTPS 的默认 x509 证书的文件。（CA 证书（如果有）在服务器证书之后并置）。 如果启用了 HTTPS 服务，并且未提供 --tls-cert-file 和 --tls-private-key-file， 为公共地址生成一个自签名证书和密钥，并将其保存到 --cert-dir 指定的目录中。
##--tls-private-key-file=/opt/kubernetes/ssl/apiserver-key.pem \\     包含匹配 --tls-cert-file 的 x509 证书私钥的文件。
##--client-ca-file=/opt/kubernetes/ssl/ca.pem \\       如果已设置，则使用与客户端证书的 CommonName 对应的标识对任何出示由 client-ca 文件中的授权机构之一签名的客户端证书的请求进行身份验证。
##--service-account-key-file=/opt/kubernetes/ssl/ca-key.pem \\  	包含 PEM 编码的 x509 RSA 或 ECDSA 私钥或公钥的文件，用于验证 ServiceAccount 令牌。 指定的文件可以包含多个键，并且可以使用不同的文件多次指定标志。 如果未指定，则使用 --tls-private-key-file。 提供 --service-account-signing-key 时必须指定。
##--etcd-cafile=/opt/etcd/ssl/ca.pem \\                    	用于保护 etcd 通信的 SSL 证书颁发机构文件。
##--etcd-certfile=/opt/etcd/ssl/server.pem \\                   用于保护 etcd 通信的 SSL 证书文件。
##--etcd-keyfile=/opt/etcd/ssl/server-key.pem"				用于保护 etcd 通信的 SSL 密钥文件。




#编写system的service文件
vim /usr/lib/systemd/system/kube-apiservice.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
 
[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-apiserver
ExecStart=/opt/kubernetes/bin/kube-apiserver $KUBE_APISERVER_OPTS
Restart=on-failure
 
[Install]
WantedBy=multi-user.target

systemctl enable kube-apiservice
systemctl daemon-reload
systemctl start kube-apiservice
systemctl status kube-apiservice
```







------

#### 1.5	kube-controller-manager服务



###### 1.5.1 配置controller-manager启动参数

```shell
vim /opt/kubernetes/cfg/kube-controller-manager
KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=true \
--v=4 \
--master=192.168.162.128:8080 \
--leader-elect=true \
--address=127.0.0.1 \
--service-cluster-ip-range=10.0.0.0/24 \
--cluster-name=kubernetes \
--cluster-signing-cert-file=/opt/kubernetes/ssl/ca.pem \
--cluster-signing-key-file=/opt/kubernetes/ssl/ca-key.pem  \
--root-ca-file=/opt/kubernetes/ssl/ca.pem \
--service-account-private-key-file=/opt/kubernetes/ssl/ca-key.pem \
--experimental-cluster-signing-duration=87600h0m0s"

#--logtostderr=true	将日志写出到标准错误输出（stderr）而不是写入到日志文件
#--master string    Kubernetes API 服务器的地址。此值会覆盖 kubeconfig 文件中所给的地址。
#--leader-elect=true 默认值：true 在执行主循环之前，启动领导选举（Leader Election）客户端，并尝试获得领导者身份。 在运行多副本组件时启用此标志有助于提高可用性
#--address ip     默认值：0.0.0.0针对 --secure-port 端口上请求执行监听操作的 IP 地址。 所对应的网络接口必须从集群中其它位置可访问（含命令行及 Web 客户端）。 如果此值为空或者设定为非特定地址（0.0.0.0 或 ::）， 意味着所有网络接口都在监听范围。
#--cluster-name=kubernetes：集群名称，与CA证书里的CN匹配
#--cluster-signing-cert-file：指定签名的CA机构根证书，用来签名为 TLS BootStrapping 创建的证书和私钥
#--root-ca-file：指定根CA证书文件路径，用来对 kube-apiserver 证书进行校验，指定该参数后，才会在 Pod 容器的 ServiceAccount 中放置该 CA 证书文件
#--experimental-cluster-signing-duration：设置为 TLS BootStrapping 签署的证书有效时间为10年，默认为1年





vim /usr/lib/systemd/system/kube-controller-manager.service

[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
 
[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-controller-manager
ExecStart=/opt/kubernetes/bin/kube-controller-manager \$KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure
 
[Install]
WantedBy=multi-user.target


```

###### 1.5.2 启动服务

```shell
systemctl enable kube-controller-manager.service
systemctl start kube-controller-manager
```





------

#### 1.6	kube-scheduler服务

###### 1.6.1 配置kube-scheduler启动参数

```shell
vim /opt/kubernetes/cfg/kube-scheduler
KUBE_SCHEDULER_OPTS="--logtostderr=true \
--v=4 \
--master=192.168.162.128:8080 \
--leader-elect=true"

#--master：监听 apiserver 的地址和8080端口
#--leader-elect=true：启动 leader 选举
#k8s中Controller-Manager和Scheduler的选主逻辑：k8s中的etcd是整个集群所有状态信息的存储，涉及数据的读写和多个etcd之间数据的同步，对数据的一致性要求严格，所以使用较复杂的 raft 算法来选择用于提交数据的主节点。而 apiserver 作为集群入口，本身是无状态的web服务器，多个 apiserver 服务之间直接负载请求并不需要做选主。Controller-Manager 和 Scheduler 作为任务类型的组件，比如 controller-manager 内置的 k8s 各种资源对象的控制器实时的 watch apiserver 获取对象最新的变化事件做期望状态和实际状态调整，调度器watch未绑定节点的pod做节点选择，显然多个这些任务同时工作是完全没有必要的，所以 controller-manager 和 scheduler 也是需要选主的，但是选主逻辑和 etcd 不一样的，这里只需要保证从多个 controller-manager 和 scheduler 之间选出一个 leader 进入工作状态即可，而无需考虑它们之间的数据一致和同步。




vim /usr/lib/systemd/system/kube-controller-manager.service

[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
 
[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-scheduler
ExecStart=/opt/kubernetes/bin/kube-scheduler $KUBE_SCHEDULER_OPTS
Restart=on-failure
 
[Install]
WantedBy=multi-user.target


```

###### 1.6.2 启动服务

```shell
systemctl enable kube-controller-manager.service
systemctl start kube-controller-manager
```



------





###### 1.7.7   创建bootstrap token认证文件

```shell
#获取随机数前16个字节内容，以十六进制格式输出，并删除其中空格
head -c 16 /dev/urandom | od -An -t x | tr -d ' '
fd8b14c6de9d44dd400b1d7711bc0d26
#生成token.csv文件，按照Token序列号，用户名，UID，用户组的格式生成
cat > /opt/kubernetes/cfg/token.csv <<EOF 
fd8b14c6de9d44dd400b1d7711bc0d26,kubelet-bootstrap,10001,"sysytem:kubelet-bootstrap"
EOF

```



###### 1.8 查看组件状态

```shell
kubectl get componentstatuses
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok                   
scheduler            Healthy   ok                   
etcd-0               Healthy   {"health": "true"}   
etcd-2               Healthy   {"health": "true"}   
etcd-1               Healthy   {"health": "true"}
```









### 2. Node1组件安装

#### 2.1	docker服务

```shell
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

sudo yum install -y yum-utils device-mapper-persistent-data lvm2

  --yum-util 提供yum-config-manager功能，另外两个是devicemapper驱动依赖的
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

###  3、查看可以安装的docker版本

yum list docker-ce --showduplicates | sort -r `//查看可以安装的版本并倒序排序

###  4、安装最新版本Docker

   `注意：安装Docker最新版本，无需加版本号：
sudo yum install -y docker

###  5、设Docker阿里云加速器

sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://lkq3q0he.mirror.aliyuncs.com"]
}
EOF

### 6、启动Docker设置开机启动与重启docker服务

sudo systemctl daemon-reload `//重新加载服务配置文件

sudo systemctl enable docker.service && systemctl restart docker.service
```



#### 2.2	kubelet服务

------

###### 2.2.1 将kubelet、kube-proxy 二进制文件传输到node节点上

```shell

[root@k8s-master bin]# scp kubelet kube-proxy root@192.168.162.129:/opt/kubernetes/bin/
kubelet                                                                                        100%  149MB   5.9MB/s   00:25    
kube-proxy

[root@k8s-master bin]# scp kubelet kube-proxy root@192.168.162.130:/opt/kubernetes/bin/
kubelet                                                                                        100%  149MB   5.9MB/s   00:25    
kube-proxy


```



###### 2.2.2 在Master端操作

```shell
#将kubelet-bootstrap用户绑定到系统集群角色

/opt/kubernetes/bin/kubectl create clusterrolebinding kubelet-bootstrap \
  --clusterrole=system:node-bootstrapper \
  --user=kubelet-bootstrap
clusterrolebinding.rbac.authorization.k8s.io/kubelet-bootstrap created


#如果提示以下报错，是因为之前已经创建过错误的签名，签名被占用，需要删除已经被占用的签名
Error from server (AlreadyExists): clusterrolebindings.rbac.authorization.k8s.io "kubelet-bootstrap" already exists

#解决方法：删除原有签名，重新生成
kubectl delete clusterrolebindings kubelet-bootstrap

```



```shell


# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server="https://192.168.162.128:6443" \
  --kubeconfig=bootstrap.kubeconfig
  
#--embed-certs=true：表示将ca.pem证书写入到生成的bootstrap.kubeconfig文件中
  
  
# 设置客户端认证参数，kubelet 使用 bootstrap token 认证
kubectl config set-credentials kubelet-bootstrap \
  --token=fd8b14c6de9d44dd400b1d7711bc0d26 \
  --kubeconfig=bootstrap.kubeconfig
  
# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig  
  
 # 使用上下文参数生成 bootstrap.kubeconfig 文件
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig 



#创建kube-proxy.kubeconfig文件
# 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/opt/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server="https://192.168.162.128:6443" \
  --kubeconfig=kube-proxy.kubeconfig
 
# 设置客户端认证参数，kube-proxy 使用 TLS 证书认证
kubectl config set-credentials kube-proxy \
  --client-certificate=/opt/kubernetes/ssl/kube-proxy.pem \
  --client-key=/opt/kubernetes/ssl/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
 
# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
 
# 使用上下文参数生成 kube-proxy.kubeconfig 文件
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig


ls
bootstrap.kubeconfig	kube-proxy.kubeconfig

```



###### 2.2.3 把配置文件bootstrap.kubeconfig、kube-proxy.kubeconfig拷贝到node节点

```shell
[root@k8s-master cfg]# scp bootstrap.kubeconfig kube-proxy.kubeconfig root@192.168.162.129:/opt/kubernetes/cfg/
bootstrap.kubeconfig                                                                           100% 2169     1.0MB/s   00:00    
kube-proxy.kubeconfig                                                                          100% 6275     2.2MB/s   00:00    

[root@k8s-master cfg]# scp bootstrap.kubeconfig kube-proxy.kubeconfig root@192.168.162.130:/opt/kubernetes/cfg/
bootstrap.kubeconfig                                                                           100% 2169     1.3MB/s   00:00    
kube-proxy.kubeconfig                                                                          100% 6275     2.7MB/s   00:00

```



###### 2.2.4 编写kubelet、kubelet.config、systemd启动文件

```shell
vim /opt/kubernetes/cfg/kubelet


KUBELET_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=192.168.162.129 \
--kubeconfig=/opt/kubernetes/cfg/kubelet.kubeconfig \
--bootstrap-kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig \
--config=/opt/kubernetes/cfg/kubelet.config \
--cert-dir=/opt/kubernetes/ssl \
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-containers/pause-amd64:3.0"


#--hostname-override：指定kubelet节点在集群中显示的主机名或IP地址，默认使用主机hostname；kube-proxy和kubelet的此项参数设置必须完全一致
#--kubeconfig：指定kubelet.kubeconfig文件位置，用于如何连接到apiserver，里面含有kubelet证书，master授权完成后会在node节点上生成 kubelet.kubeconfig 文件
#--bootstrap-kubeconfig：指定连接 apiserver 的 bootstrap.kubeconfig 文件
#--config：指定kubelet配置文件的路径，启动kubelet时将从此文件加载其配置
#--cert-dir：指定master颁发的客户端证书和密钥保存位置
#--pod-infra-container-image：指定Pod基础容器（Pause容器）的镜像。Pod启动的时候都会启动一个这样的容器，每个pod之间相互通信需要Pause的支持，启动Pause需要Pause基础镜像



#创建kubelet配置文件（该文件实际上就是一个yml文件，语法非常严格，不能出现tab键，冒号后面必须要有空格，每行结尾也不能有空格）
vim /opt/kubernetes/cfg/kubelet.config
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 192.168.162.129
port: 10250
readOnlyPort: 10255
cgroupDriver: systemd
clusterDNS: ["10.0.0.2"]
clusterDomain: cluster.local.
failSwapOn: false
authentication:
  anonymous:
    enabled: true
    
       
#注意：当命令行参数与此配置文件（kubelet.config）有相同的值时，就会覆盖配置文件中的该值。   



cat > /usr/lib/systemd/system/kubelet.service <<EOF
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service
 
[Service]
EnvironmentFile=/opt/kubernetes/cfg/kubelet
ExecStart=/opt/kubernetes/bin/kubelet $KUBELET_OPTS
Restart=on-failure
KillMode=process
 
[Install]
WantedBy=multi-user.target
EOF

systemctl enable kubelet.service
systemctl restart kubelet.service
```







#### 2.3	kube-proxy服务



###### 2.3.1 创建 kube-proxy 启动参数配置文件

```shell
#创建 kube-proxy 启动参数配置文件
cat >/opt/kubernetes/cfg/kube-proxy <<EOF
KUBE_PROXY_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=192.168.162.129 \
--cluster-cidr=10.0.0.0/24 \
--proxy-mode=ipvs \
--kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig"
EOF



#--hostnameOverride: 参数值必须与 kubelet 的值一致，否则 kube-proxy 启动后会找不到该 Node，从而不会创建任何 ipvs 规则
#--cluster-cidr：指定 Pod 网络使用的聚合网段，Pod 使用的网段和 apiserver 中指定的 service 的 cluster ip 网段不是同一个网段。 kube-proxy 根据 --cluster-cidr 判断集群内部和外部流量，指定 --cluster-cidr 选项后 kube-proxy 才会对访问 Service IP 的请求做 SNAT，即来自非 Pod 网络的流量被当成外部流量，访问 Service 时需要做 SNAT。
#--proxy-mode：指定流量调度模式为 ipvs 模式
#--kubeconfig: 指定连接 apiserver 的 kubeconfig 文件

```



###### 2.3.2 创建systemd kube-proxy.service文件

```shel
cat > /usr/lib/systemd/system/kube-proxy.service <<EOF
[Unit]
Description=Kubernetes Proxy
After=network.target
 
[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-proxy
ExecStart=/opt/kubernetes/bin/kube-proxy $KUBE_PROXY_OPTS
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
EOF



systemctl enable kube-proxy.service
systemctl restart kube-proxy.service
```







### 3. Node2组件安装

#### 3.1.	kubelet服务

###### 3.1.1 编写kubelet、kubelet.config、systemd启动文件

```shell
vim /opt/kubernetes/cfg/kubelet


KUBELET_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=192.168.162.130 \
--kubeconfig=/opt/kubernetes/cfg/kubelet.kubeconfig \
--bootstrap-kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig \
--config=/opt/kubernetes/cfg/kubelet.config \
--cert-dir=/opt/kubernetes/ssl \
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-containers/pause-amd64:3.0"


#--hostname-override：指定kubelet节点在集群中显示的主机名或IP地址，默认使用主机hostname；kube-proxy和kubelet的此项参数设置必须完全一致
#--kubeconfig：指定kubelet.kubeconfig文件位置，用于如何连接到apiserver，里面含有kubelet证书，master授权完成后会在node节点上生成 kubelet.kubeconfig 文件
#--bootstrap-kubeconfig：指定连接 apiserver 的 bootstrap.kubeconfig 文件
#--config：指定kubelet配置文件的路径，启动kubelet时将从此文件加载其配置
#--cert-dir：指定master颁发的客户端证书和密钥保存位置
#--pod-infra-container-image：指定Pod基础容器（Pause容器）的镜像。Pod启动的时候都会启动一个这样的容器，每个pod之间相互通信需要Pause的支持，启动Pause需要Pause基础镜像



#创建kubelet配置文件（该文件实际上就是一个yml文件，语法非常严格，不能出现tab键，冒号后面必须要有空格，每行结尾也不能有空格）
vim /opt/kubernetes/cfg/kubelet.config
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 192.168.162.130
port: 10250
readOnlyPort: 10255
cgroupDriver: systemd
clusterDNS: ["10.0.0.2"]
clusterDomain: cluster.local.
failSwapOn: false
authentication:
  anonymous:
    enabled: true
    
       
#注意：当命令行参数与此配置文件（kubelet.config）有相同的值时，就会覆盖配置文件中的该值。   



cat > /usr/lib/systemd/system/kubelet.service <<EOF
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service
 
[Service]
EnvironmentFile=/opt/kubernetes/cfg/kubelet
ExecStart=/opt/kubernetes/bin/kubelet $KUBELET_OPTS
Restart=on-failure
KillMode=process
 
[Install]
WantedBy=multi-user.target
EOF

systemctl enable kubelet.service
systemctl restart kubelet.service
```



------

#### 3.2	kube-proxy服务



###### 3.2.1 创建 kube-proxy 启动参数配置文件

```shell
#创建 kube-proxy 启动参数配置文件
cat >/opt/kubernetes/cfg/kube-proxy <<EOF
KUBE_PROXY_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=192.168.162.130 \
--cluster-cidr=10.0.0.0/24 \
--proxy-mode=ipvs \
--kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig"
EOF



#--hostnameOverride: 参数值必须与 kubelet 的值一致，否则 kube-proxy 启动后会找不到该 Node，从而不会创建任何 ipvs 规则
#--cluster-cidr：指定 Pod 网络使用的聚合网段，Pod 使用的网段和 apiserver 中指定的 service 的 cluster ip 网段不是同一个网段。 kube-proxy 根据 --cluster-cidr 判断集群内部和外部流量，指定 --cluster-cidr 选项后 kube-proxy 才会对访问 Service IP 的请求做 SNAT，即来自非 Pod 网络的流量被当成外部流量，访问 Service 时需要做 SNAT。
#--proxy-mode：指定流量调度模式为 ipvs 模式
#--kubeconfig: 指定连接 apiserver 的 kubeconfig 文件

```



###### 2.3.2 创建systemd kube-proxy.service文件

```shel
cat > /usr/lib/systemd/system/kube-proxy.service <<EOF
[Unit]
Description=Kubernetes Proxy
After=network.target
 
[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-proxy
ExecStart=/opt/kubernetes/bin/kube-proxy $KUBE_PROXY_OPTS
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
EOF



systemctl enable kube-proxy.service
systemctl restart kube-proxy.service
```



------





### 4.查看node节点状态



###### 4.1 查看CSR请求状态

```shell
[root@k8s-master cfg]# kubectl get csr
NAME                                                   AGE       REQUESTOR           CONDITION
node-csr-DaW1zxwSnwLh82HJT7pVBwkx5-JH0YTkuL8Mgxs61ZE   37m       kubelet-bootstrap   Pending
node-csr-qQUh27SDTmDigl-3aOfSXWk6aMycRPH6XBaGF7WMlLk   42m       kubelet-bootstrap   Pending


#发现有来自于kubelet-bootstrap的申请，处于待办状态
```

###### 4.2 通过通过CSR请求

```shell
#kubectl certificate approve [node-csr-......]


#批准kulet node-csr-DaW1zxwSnwLh82HJT7pVBwkx5-JH0YTkuL8Mgxs61ZE通过申请
kubectl certificate approve node-csr-DaW1zxwSnwLh82HJT7pVBwkx5-JH0YTkuL8Mgxs61ZE

#提示这个说明批准成功
certificatesigningrequest.certificates.k8s.io "node-csr-DaW1zxwSnwLh82HJT7pVBwkx5-JH0YTkuL8Mgxs61ZE" approved


#查看验证
kubectl get csr
NAME                                                   AGE       REQUESTOR           CONDITION
node-csr-DaW1zxwSnwLh82HJT7pVBwkx5-JH0YTkuL8Mgxs61ZE   1h        kubelet-bootstrap   Approved
node-csr-ZHJ2POAuXOQzqrZ-3Ku2cK4q3_mZsU6bmckL8S5xY1g   12m       kubelet-bootstrap   Pending

```

###### 4.3 删除全部的csr请求

```shell
#kubectl delete csr node-csr-DaW1zxwSnwLh82HJT7pVBwkx5-JH0YTkuL8Mgxs61ZE

kubectl get csr |awk 'NR>2{print p}{p=$1}'|xargs kubectl delete csr

#awk 'NR>2{print p}{p=$1}'   打印行号大于1 并且只显示$1 第一列 

```



4.4 查看node节点状态

```shell
kubectl get node
NAME              STATUS    ROLES     AGE       VERSION
192.168.162.129   Ready     <none>    9h        v1.10.13
192.168.162.130   Ready     <none>    9h        v1.10.13

```



