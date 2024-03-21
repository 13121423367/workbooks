```bash
[root@compute23 ~]# cat /proc/net/bonding/bond2 

# bond组信息
Ethernet Channel Bonding Driver: v3.7.1 (April 27, 2011)

Bonding Mode: IEEE 802.3ad Dynamic link aggregation
Transmit Hash Policy: layer2 (0)
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0

802.3ad info
LACP rate: slow
Min links: 0
Aggregator selection policy (ad_select): stable
System priority: 65535
System MAC address: e4:43:4b:59:c5:98
Active Aggregator Info:
	Aggregator ID: 5
	Number of ports: 1
	Actor Key: 15
	Partner Key: 1
	Partner Mac Address: 00:00:00:00:00:00

#  接口信息 em1
Slave Interface: em1
MII Status: up
Speed: 10000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: e4:43:4b:59:c5:98
Slave queue ID: 0
Aggregator ID: 5
Actor Churn State: none
Partner Churn State: churned
Actor Churned Count: 0
Partner Churned Count: 1
details actor lacp pdu:  #  服务器接口信息
    system priority: 65535
    system mac address: e4:43:4b:59:c5:98  #  接口 mac 地址
    port key: 15
    port priority: 255
    port number: 1
    port state: 77  #  正常值为 61
details partner lacp pdu:  #  交换机信息
    system priority: 65535
    system mac address: 00:00:00:00:00:00  #  交换机 mac 地址（应该是交换机本征vlan的mac，非交换机接口mac，接到同一个交换机上的网卡看到的mac地址都是一样的）
    oper key: 1
    port priority: 255
    port number: 1  #  交换机接口（em1 和 em2 对应的 port number肯定是不一样的）
    port state: 1   #  正常值为 61

#  接口信息em2
Slave Interface: em2
MII Status: up
Speed: 10000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: e4:43:4b:59:c5:9a
Slave queue ID: 0
Aggregator ID: 6
Actor Churn State: churned
Partner Churn State: churned
Actor Churned Count: 1
Partner Churned Count: 1
details actor lacp pdu:
    system priority: 65535
    system mac address: e4:43:4b:59:c5:98
    port key: 15
    port priority: 255
    port number: 2
    port state: 69
details partner lacp pdu:
    system priority: 65535
    system mac address: 00:00:00:00:00:00
    oper key: 1
    port priority: 255
    port number: 1
    port state: 1



交换机侧：mac一致、port num 不一样、port state为61
```



#### 根据策略查询到的结果

**以下是port state不是61**

| 区域 |         节点         |     网卡     | 网络类型 |   备注   |
| :--: | :------------------: | :----------: | :------: | :------: |
| HB2  |     controller2      | bond2 - p1p1 |  存储网  |          |
|      |                      | bond3 - p4p2 | 业务内网 |          |
|      |     controller3      | bond3 - p4p1 | 业务内网 |          |
|      |                      | bond4 - p4p3 | 业务外网 |          |
| HB3  |  compute17（计算）   | bond2 - p2p2 |  存储网  |          |
| HK1  |  compute23（计算）   |    bond2     |  存储网  | 交换机配bond0 |
|      | storage01（存储） | bond1 - em2  |  管理网  | 单口bond |
|      | storage02（存储） | bond1 - em2  |  管理网  | 单口bond |
|      | storage03（存储） | bond1 - em2  |  管理网  | 单口bond |
|      | storage04（存储） | bond1 - em2  |  管理网  | 单口bond |
|      | storage05（存储） | bond1 - em2  |  管理网  | 单口bond |

```bash
[root@compute23 ~]# cat /var/log/messages | grep Link
Sep 18 20:51:10 compute23 kernel: [qede_link_update:2426(p6p4)]Link is down
Sep 18 20:51:10 compute23 kernel: [qede_link_update:2419(p6p4)]Link is up
Sep 18 21:00:07 compute23 kernel: [qede_unload:2244(p6p4)]Link is down
Sep 18 21:00:07 compute23 kernel: [qede_link_update:2419(p6p4)]Link is up
Sep 18 21:00:11 compute23 kernel: [qede_unload:2244(p6p4)]Link is down
Sep 18 21:00:11 compute23 kernel: [qede_link_update:2419(p6p4)]Link is up
[root@compute23 ~]# ip a | grep p6p4
9: p6p4: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc mq master bond4 state UP group default qlen 1000
[root@compute23 ~]# cat /proc/net/bonding/bond4 
Ethernet Channel Bonding Driver: v3.7.1 (April 27, 2011)

Bonding Mode: IEEE 802.3ad Dynamic link aggregation
Transmit Hash Policy: layer2 (0)
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0

802.3ad info
LACP rate: slow
Min links: 0
Aggregator selection policy (ad_select): stable
System priority: 65535
System MAC address: 34:80:0d:05:c9:1a
Active Aggregator Info:
	Aggregator ID: 1
	Number of ports: 2
	Actor Key: 15
	Partner Key: 5
	Partner Mac Address: 80:05:88:44:ed:ad

Slave Interface: p6p3
MII Status: up
Speed: 10000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 34:80:0d:05:c9:1a
Slave queue ID: 0
Aggregator ID: 1
Actor Churn State: none
Partner Churn State: none
Actor Churned Count: 0
Partner Churned Count: 0
details actor lacp pdu:
    system priority: 65535
    system mac address: 34:80:0d:05:c9:1a
    port key: 15
    port priority: 255
    port number: 1
    port state: 61
details partner lacp pdu:
    system priority: 32768
    system mac address: 80:05:88:44:ed:ad
    oper key: 5
    port priority: 32768
    port number: 59
    port state: 61

Slave Interface: p6p4
MII Status: up
Speed: 10000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 34:80:0d:05:c9:1b
Slave queue ID: 0
Aggregator ID: 1
Actor Churn State: none
Partner Churn State: none
Actor Churned Count: 0
Partner Churned Count: 0
details actor lacp pdu:
    system priority: 65535
    system mac address: 34:80:0d:05:c9:1a
    port key: 15
    port priority: 255
    port number: 2
    port state: 61
details partner lacp pdu:
    system priority: 32768
    system mac address: 80:05:88:44:ed:ad
    oper key: 5
    port priority: 32768
    port number: 5
    port state: 61
[root@compute23 ~]# date
Sat Sep 18 21:10:52 CST 2021
[root@compute23 ~]# cat /var/log/messages | grep Link
Sep 18 20:51:10 compute23 kernel: [qede_link_update:2426(p6p4)]Link is down
Sep 18 20:51:10 compute23 kernel: [qede_link_update:2419(p6p4)]Link is up
Sep 18 21:00:07 compute23 kernel: [qede_unload:2244(p6p4)]Link is down
Sep 18 21:00:07 compute23 kernel: [qede_link_update:2419(p6p4)]Link is up
Sep 18 21:00:11 compute23 kernel: [qede_unload:2244(p6p4)]Link is down
Sep 18 21:00:11 compute23 kernel: [qede_link_update:2419(p6p4)]Link is up
[root@compute23 ~]# 

```

