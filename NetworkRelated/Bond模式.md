## **Bond 模式**

Bond 模式指的是将多个物理网卡绑定在一起，形成一个虚拟接口，并使用某种负载均衡算法将数据流量分配到各个物理网卡上，从而提高网络带宽和冗余能力。常用的 Bond 模式有以下四种：

#### **1. Round-robin (平衡轮询) 模式**

Round-robin 模式是最简单的 Bond 模式之一。该模式会将传输的数据包平均地分配到各个物理网卡上，实现负载均衡。

该模式适用于多台服务器之间通信的场景。

#### **2. Active-backup (热备份) 模式**

Active-backup 模式又称为 failover 模式。该模式只有一个物理网卡处于活动状态，而其他网卡则处于备份状态。当活动网卡发生故障时，备份网卡会自动接管网络流量。

该模式适用于需要保证网络连通性的关键应用场景。

#### **3. LACP (链路聚合控制协议) 模式**

LACP 是一种基于标准的协议，可实现多个设备之间的链路聚合。使用 LACP 模式时，需要确保所有物理网卡和交换机都支持 LACP 协议。

该模式适用于对网络带宽要求较高的场景，如数据中心、云计算等。

#### **4. Broadcast (广播) 模式**

Broadcast 模式会将传输的数据包广播到所有物理网卡上。该模式不具备负载均衡能力，只适用于特定场景下的测试或调试操作。

### **Bond 配置**

在 CentOS 7 系统中配置 Bond 主要分为以下几个步骤：

1. 安装 bonding 模块。

```shell
yum install -y bonding
```

2. 编辑 /etc/modprobe.d/bonding.conf 文件，设置 bonding 模块相关参数。

```shell
options bond0 mode=balance-rr miimon=100
```
3. 创建 Bond 接口配置文件。

```shell
cp /etc/sysconfig/network-scripts/ifcfg-enp0s3 /etc/sysconfig/network-scripts/ifcfg-bond0 cp /etc/sysconfig/network-scripts/ifcfg-enp0s8 /etc/sysconfig/network-scripts/ifcfg-bond0
```
4. 编辑 Bond 接口配置文件（如 ifcfg-bond0），根据实际情况进行修改。

```shell
DEVICE=bond0 NAME=bond0 TYPE=Bond BONDING_OPTS="mode=balance-rr miimon=100" ONBOOT=yes BOOTPROTO=none IPADDR=x.x.x.x NETMASK=x.x.x.x
```
5. 启动 Bond 接口。

```shell
ifup bond0
```
6. 验证 Bond 是否正常工作。

```shell
cat /proc/net/bonding/bond0
```
以上是在 CentOS 7 系统中配置 Bond 的详细步骤。在实际应用中，应根据具体需求选择合适的模式以及相应的配置参数。