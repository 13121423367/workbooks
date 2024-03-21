## 1.介绍

在centos7中，有几种防火墙共存：firewald , iptables . 默认情况下，CentOS是使用firewalld来管理netfilter子系统，不过底层调用的命令仍然是iptables

## 2.firewalld 和 iptables区别

1. firewalld 可以动态修改单挑规则，而不像iptables那样，在修改了规则后必须全部刷新才可以生效。
2. firewalld在使用上比iptables人性化很多，即使不明白"五张表五条链"而且对TCP/IP协议也不理解也可以实现大部分功能。
3. firewalld跟iptables比起来，不好的地方是每个服务都需要去设置才能放行，因为默认是拒绝。而iptables里默认每个服务是允许，需要拒绝才去限制。
4. firewalld自身并不具备防火墙的功能，而是和iptables一样需要通过内核的netfilter来实现，也就是说firewalld和iptables一样，他们的作用是用于维护规则，而真正使用规则干活的是内核的netfilter,只不过firewalld和iptables的结构以及使用方法不一样罢了。

## 3.区域管理概念

**区域管理**

通过将网络划分成不同的区域，制定不同区域之间的访问控制策略来控制不同程序间传送的数据流。例如，互联网不是可信任的区域，而内部网络是高度信任的区域。网络安全模型可以在安装，初次启动和首次建立网络连接时选择初始化。该模型描述了主机所连接的整个网络环境的可信级别，并定义了新连接的处理方式。

**有如下几种不同的初始化区域：**

- 阻塞区域（block）：任何传入的网络数据包都将被阻止
- 工作区域（work）：相信网络上的其他计算机，不会损害你的计算机
- 家庭区域（home）：相信网络上的其他计算机，不会损害你的计算机
- 公共区域（public）：不相信网络上的任何计算机，只有选择接受传入的网络连接
- 隔离区域（DMZ）：隔离区域也称为非军事区域，内外网络之间增加的一层网络，起到缓冲作用。对于隔离区域，只有选择接受传入的网络连接。
- 信任区域（trusted）：所有的网络连接都可以接受
- 丢弃区域（drop）：任何传入的网络连接都被拒绝
- 内部区域（internal）：信任网络上的其他计算机，不会损害你的计算机。只有选择接受传入的网络连接
- 外部区域（external）：不相信网络上的其他计算机，不会损害你的计算机。只有选择接受传入的网络连接

注：Firewalld的默认区域是public

firewalld默认提供了九个zone配置文件：block.xml、dmz.xml、drop.xml、external.xml、 home.xml、internal.xml、public.xml、trusted.xml、work.xml，他们都保存在“/usr/lib /firewalld/zones/”目录下。

## 4.iptables的配置

### 1.简述

iptables防火墙由Netfilter项目(http://www.netfilter.org) 开发，自2001年1月在Linux2.4内核发布以来就是Linux的一部分了。

Netfilter是由Linux提供的所有包过滤和包修改设施的官方项目名称，但这个术语同时也指Linux内核的一个框架，他可以用于在不同的阶段将函数挂接(hook)进网络栈。另一方面，iptables使用Netfilter框架指在将对数据包进行操作(如过滤)的函数挂接进网络栈。

所以，你可以认为Netfilter提供了一个框架，而iptables在它之上建立了防火墙功能

### 2.基本原理

规则（rules）其实就是网络管理员预定义的条件，规则一般的定义为“如果数据包头符合这样的条件，就这样处理这个数据包”。规则存储在内核空间的信息 包过滤表中，这些规则分别指定了源地址、目的地址、传输协议（如TCP、UDP、ICMP）和服务类型（如HTTP、FTP和SMTP）等。当数据包与规 则匹配时，iptables就根据规则所定义的方法来处理这些数据包，如放行（accept）、拒绝（reject）和丢弃（drop）等。配置防火墙的 主要工作就是添加、修改和删除这些规则

### 3.iptables传输数据包的过程

1. 当一个数据包进入网卡时，它首先进入PREROUTING链，内核根据数据包目的IP判断是否需要转送出去
2. 如果数据包就是进入本机的，它就会沿着图向下移动，到达INPUT链。数据包到了INPUT链后，任何进程都会收到它。本机上运行的程序可以发送数据包，这些数据包会经过OUTPUT链，然后到达POSTROUTING链输出
3. 如果数据包是要转发出去的，且内核允许转发，数据包就会如图所示向右移动，经过FORWARD链，然后到达POSTROUTING链输出

![图片](https://mmbiz.qpic.cn/mmbiz_png/QFzRdz9libEZzbQIWjzWxaJ7P5t74dkJpatSy7NUtIHYsmZib81sJgiaOqbWqWev0vemUDz2UsX43DrqeSQggAEzw/640?wx_fmt=png&from=appmsg&wxfrom=5&wx_lazy=1&wx_co=1)

### 4、iptables规则表和链

**表(tables)：**

iptables一共有四张表，称为filter, nat, mangle, raw。filter用于过滤，nat用于网络地址转换，mangle用于给数据包做标记以修改分组数据的特定规则，raw表则独立于Netfilter连接跟踪子系统

因此，如果你的目标是保护主机安全，那么着重考虑的是filter表，而如果像OpenStack那样，目的是做网络地址转换，就用NAT表，而mangle则用于QoS（服务质量控制），如对打上某个标记的分组数据分配较多带宽等等

**链(chains)：**

是数据包传播的路径，每个链其实就是众多规则中的一个检查清单，每一条链中可以有1条或者数条规则。当一个数据包到达一个链时，iptables就会从链中第一条规则开始检查，看数据包是否满足规则所定义的条件，如果满足，就会根据该规则所定义的方法处理该数据包。否则iptables将继续检查下一条规则，如果数据包不符合链中任一条规则，iptables就会根据该链预先定义的策略来处理数据包。

![图片](https://mmbiz.qpic.cn/mmbiz_png/QFzRdz9libEZzbQIWjzWxaJ7P5t74dkJpKialibWVtEOSjb5XnuibmL5FwrRicGNqZDFvNXUJK0K3TXF7BKlvcwS9Rg/640?wx_fmt=png&from=appmsg&wxfrom=5&wx_lazy=1&wx_co=1)

### 5.规则表处理的优先顺序

**Raw--mangle--nat--filter**

对filter表来说，最重要的是内置链INPUT/OUTPUT/FORWARD。顾名思义，INPUT应用于外部网络进入到本地主机的数据包，OUPTU则应用于从本地主机发送到外部网络的数据包。FORWARD则可以理解为将本地主机作为路由器，数据包从本地主机经过，但目标位于本地主机的下游。

### 6.管理和设置iptables规则

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/QFzRdz9libEZzbQIWjzWxaJ7P5t74dkJpD2IKonKYtyOLsicLM2IonxlcFCVcRBA3URNU7elug0BMe4fwIKiaQZ0Q/640?wx_fmt=jpeg&from=appmsg&wxfrom=5&wx_lazy=1&wx_co=1)

![图片](https://mmbiz.qpic.cn/mmbiz_jpg/QFzRdz9libEZzbQIWjzWxaJ7P5t74dkJpu3Jbx327moXXE9KIvvEicJF0NWpDDwAxagQaX7xARLm7ia0zj0o8t92Q/640?wx_fmt=jpeg&from=appmsg&wxfrom=5&wx_lazy=1&wx_co=1)

### 7.配置iptables之前firewalld的关闭

CentOS7默认的防火墙是firewall，所以要使用iptables得先将默认的firewall关闭，并另安装iptables进行防火墙的规则设定

```
[root@localhost ~]# systemctl stop firewalld.service            //停止firewall
[root@localhost ~]# systemctl disable firewalld.service        //禁止firewall开机启动
```

### 8.iptables的安装

先检查iptables是否有安装：

```
[root@localhost ~]# rpm –qa | grep iptables
iptables-1.4.21-16.el7.x86_64    //如果有显示这个，则说明已经安装了iptables
```

安装iptables

```
[root@localhost ~]# yum install –y iptables
[root@localhost ~]# yum install –y iptables-services
```

### 9.iptables的基本语法格式

```
iptables [-t 表名] 命令选项 ［链名］［条件匹配］ ［-j 目标动作或跳转］
```

说明：表名、链名用于指定 iptables命令所操作的表和链，命令选项用于指定管理iptables规则的方式（比如：插入、增加、删除、查看等；条件匹配用于指定对符合什么样 条件的数据包进行处理；目标动作或跳转用于指定数据包的处理方式（比如允许通过、拒绝、丢弃、跳转（Jump）给其它链处理。

### 10.**iptables**命令的管理控制选项

-A 在指定链的末尾添加（append）一条新的规则

-D 删除（delete）指定链中的某一条规则，可以按规则序号和内容删除

-I 在指定链中插入（insert）一条新的规则，默认在第一行添加

-R 修改、替换（replace）指定链中的某一条规则，可以按规则序号和内容替换

-L 列出（list）指定链中所有的规则进行查看

-E 重命名用户定义的链，不改变链本身

-F 清空（flush）

-N 新建（new-chain）一条用户自己定义的规则链

-X 删除指定表中用户自定义的规则链（delete-chain）

-P 设置指定链的默认策略（policy）

-Z 将所有表的所有链的字节和数据包计数器清零

-n 使用数字形式（numeric）显示输出结果

-v 查看规则表详细信息（verbose）的信息

-V 查看版本(version)

-h 获取帮助（help）

### 11.iptables命令的保存

```
[root@localhost ~]# service iptables save
```

### 12.iptables的基本操作

**清除所有规则**

⑴清除预设表filter中所有规则链中的规则

```
[root@localhost ~]# iptables -F
```

⑵清除预设表filter中使用者自定义链中的规则

```
[root@localhost ~]# iptables –X
[root@localhost ~]# iptables -Z
```

⑶清除NAT表规则

```
[root@localhost ~]# iptables –F –t nat
```

**设置链的默认策略，一般有二种方法**

⑴允许所有的包，然后再禁止所有危险的包通过防火墙

```
[root@localhost ~]# iptables –P INPUT ACCEPT
[root@localhost ~]# iptables –P OUTPUT ACCEPT
[root@localhost ~]# iptables –P FORWARD ACCEPT
```

⑵首先禁止所有的包，然后根据需要的服务允许特定的包通过防火墙

```
[root@localhost ~]# iptables –P INPUT DROP
[root@localhost ~]# iptables –P OUTPUT DROP
[root@localhost ~]# iptables –P FORWARD DROP
```

**向链中添加规则（下面的语句用于允许SSH连接本服务器）**

```
[root@localhost ~]# iptables -A INPUT -p tcp --dport 22 -j ACCEPT
[root@localhost ~]# iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT
```

**向链中添加规则（下面的语句用于允许PING命令测试本服务器）**

```
[root@localhost ~]# iptables -A INPUT -p icmp -j ACCEPT
[root@localhost ~]# iptables -A OUTPUT -p icmp -j ACCEPT
```

**iptables的配置文件**

直接编辑iptables的配置文件：

```
[root@localhost ~]# vim /etc/sysconfig/iptables
[root@localhost ~]# systemctl restart iptables.service              //最后重启防火墙使配置生效
[root@localhost ~]# systemctl enable iptables.service              //设置防火墙开机启动
[root@localhost ~]# iptables -L 
//查看防火墙规则,默认的是－t filter，如果是nat表查看，即iptables －t nat -L
```