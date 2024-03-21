# 华北三区 Ceph 集群添加节点

## 一、准备工作

### 1. 检查环境

关闭防火墙

```
systemctl disable firewalld.service
systemctl stop firewalld.service
```

关闭 selinux

```
sed -i  "s/^SELINUX=.*\$/SELINUX=disabled/g" /etc/selinux/config
```

设置时区

```
timedatectl set-timezone Asia/Shanghai
```

检查无秘钥登录

检查网络（管理网、存储网前端、存储网后端）

### 2. 配置时间同步

安装软件包(centos7.5 默认安装)

```
yum install chrony -y 
systemctl enable chronyd && systemctl start chronyd 
systemctl status chronyd
```

修改配置文件（IP为controller节点的 vip 10.250.0.6） 
```
vi /etc/chrony.conf 
server 10.250.0.6 iburst
```
重启
```
systemctl restart chronyd
```
检查同步源
```
chronyc sources -v
210 Number of sources = 1
  .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
 / .- Source state '*' = current synced, '+' = combined , '-' = not combined,
| /   '?' = unreachable, 'x' = time may be in error, '~' = time too variable.
||                                                 .- xxxx [ yyyy ] +/- zzzz
||      Reachability register (octal) -.           |  xxxx = adjusted offset,
||      Log2(Polling interval) --.      |          |  yyyy = measured offset,
||                                \     |          |  zzzz = estimated error.
||                                 |    |           \
MS Name/IP address         Stratum Poll Reach LastRx Last sample               
===============================================================================
^* 10.250.0.6                3   7    17    32  +5182ns[+5881ns] +/-   25ms
```

查看日期时间及NTP状态
```
timedatectl
      Local time: Tue 2021-04-20 11:30:36 CST
  Universal time: Tue 2021-04-20 03:30:36 UTC
        RTC time: Tue 2021-04-20 03:30:36
       Time zone: Asia/Shanghai (CST, +0800)
     NTP enabled: yes
NTP synchronized: yes
 RTC in local TZ: no
      DST active: n/a
```


### 3. 配置ceph阿里源以及epel源
在/etc/yum.repos.d目录，新建 ceph.repo、epel.repo文件。

-	Ceph阿里源如下：
```bash
[ceph]
name=ceph
baseurl=http://mirrors.aliyun.com/ceph/rpm-luminous/el7/x86_64/
gpgcheck=0
priority=1

[ceph-noarch]
name=cephnoarch
baseurl=http://mirrors.aliyun.com/ceph/rpm-luminous/el7/noarch/
gpgcheck=0
priority=1

[ceph-source]
name=ceph-source
baseurl=http://mirrors.aliyun.com/ceph/rpm-luminous/el7/SRPMS/
gpgcheck=0
priority=1
```

-	安装 epel 源
```
yum install epel-release -y
```

设置环境变量
```bash
export CEPH_DEPLOY_REPO_URL=http://mirrors.aliyun.com/ceph/rpm-luminous/el7
export CEPH_DEPLOY_GPG_URL=http://mirrors.aliyun.com/ceph/keys/release.asc
yum clean all
yum makecache
```
检测命令： 
```bash
env | grep CEPH_DEPLOY_REPO_URL
env | grep CEPH_DEPLOY_GPG_URL
```
如果服务器重启了需要重新配置CEPH_DEPLOY_REPO_URL，CEPH_DEPLOY_GPG_URL

### 4. 配置/etc/hosts文件
新增的节点ip和节点名字加入hosts文件，如下举例。并且把配置文件同步到其他所有节点（包括控制节点和存储节点）
```
10.250.0.XX computeXX
```
### 5. 安装ceph rpm包
从 controller1 上 /root/ceph-rpm-install-offline.tar.gz 拷贝过来；在controller1上执行：
```
scp /root/ceph-rpm-install-offline.tar.gz computeXX:/root/ceph-rpm-install-offline.tar.gz
```
在computexx上创建配置文件目录/etc/ceph

```
mkdir /root/ceph-rpm-list
tar -zxf /root/ceph-rpm-install-offline.tar.gz -C /root/ceph-rpm-list
cd /root/ceph-rpm-list/ && yum  localinstall  -y *.rpm 
```
检测命令：
```
ceph -v
```
从 controller1 上拷贝配置文件到 computeXX 上的 /etc/ceph 目录下
```
cd /etc/ceph && scp ceph.client.admin.keyring ceph.conf computeXX:/etc/ceph
```

### 6. 升级内核
```
rpm -Uvh linux-firmware-20191203-76.gite8a0f4c.el7.noarch.rpm
rpm -Uvh kernel-3.10.0-1127.10.1.el7.x86_64.rpm
```
安装完成后，重启服务器
检查命令：

```
uname -a 
```

## 二、新增osd操作步骤

以下操作均在 controller1 的 /etc/ceph 目录下执行

### 1. 设置各个pool暂停scrub和deep-scrub

参考命令：
```
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 1;ceph osd pool set ${i} nodeep-scrub 1;done
```
检查命令：
```
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool get ${i} all | grep -E "noscrub|nodeep-scrub";done
```
### 2. 设置norebalance、norecover、nobackfill

参考命令：
```
ceph osd set norebalance;ceph osd set norecover;ceph osd set nobackfill;ceph osd set noout;
```
检查命令：
```
ceph -s 
```
### 3. 部署新增节点，以computeXX、rackYY为例
-	ssh到computeXX将ssd磁盘(sdb)分区
参考命令：
```bash
cat >> parted.sh << EOF
mklabel gpt
mkpart wal-log1 0% 6%
mkpart rockdb1 6% 20%
mkpart wal-log2 20% 26%
mkpart rockdb2 26% 40%
mkpart wal-log3 40% 46%
mkpart rockdb3 46% 60%
mkpart wal-log4 60% 66%
mkpart rockdb4 66% 80%
mkpart wal-log5 80% 86%
mkpart rockdb5 86% 100%
quit
EOF
parted /dev/sdb < parted.sh
```
检查命令：
```
lsblk
```

-	获取由由系统生成的crush map: 
``` bash
ceph osd getcrushmap -o {crushmap-name}
```
-	增加computeXX到集群中，移动computeXX到固定机架
```
ceph osd crush add-bucket computeXX host
ceph osd crush move computeXX rack=rackYY
```
-	在controller1节点上的/etc/ceph目录下新增osd
参考命令：
```bash
ceph-deploy --overwrite-conf osd create computeXX --data /dev/sdc --block-db /dev/sdb2 --block-wal /dev/sdb1
ceph-deploy --overwrite-conf osd create computeXX --data /dev/sdd --block-db /dev/sdb4 --block-wal /dev/sdb3
ceph-deploy --overwrite-conf osd create computeXX --data /dev/sde --block-db /dev/sdb6 --block-wal /dev/sdb5
ceph-deploy --overwrite-conf osd create computeXX --data /dev/sdf --block-db /dev/sdb8 --block-wal /dev/sdb7
ceph-deploy --overwrite-conf osd create computeXX --data /dev/sdg --block-db /dev/sdb10 --block-wal /dev/sdb9
```
检查命令：
```
ceph osd df tree
```
### 4. 放开数据重分布

参考命令：
```
ceph osd unset norebalance;ceph osd unset norecover;ceph osd unset nobackfill;ceph osd unset noout;
```
检查命令：
```
ceph -s
```
待所有OSD都添加完成并且集群数据重新分布完成之后，设置各个pool开启scrub和deep-scrub
参考命令：

```
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 0;ceph osd pool set ${i} nodeep-scrub 0;done
```
检查命令：
```
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool get ${i} all | grep -E "noscrub|nodeep-scrub";done
```

## 三、回滚方案
### 1. 踢出osd

如果部署过程中出现问题，则把新增的OSD从集群中踢出(暂停scrub，recover等已经在文档中提及)，操作步骤如下。
-	查看新增主机(以computeXX为例)以及主机上的OSD（以x为例）
```
ceph osd tree
```
-	从controller1节点连接computeXX
```
ssh computeXX 
systemctl stop ceph-osd@x.service && systemctl disable ceph-osd@x.service
exit
```
在controller1上执行：
```
ceph osd out osd.x
ceph osd crush remove osd.x
ceph auth del osd.x
ceph osd rm x
ssh compute1
```
在computeXX上执行：
```
umount /var/lib/ceph/osd/ceph-x 
exit
```
 ### 2. IO限速：
新加osd之后，如果recover速率过高，对clientIO产生较大影响时，对recover进行限速处理
```
ceph tell osd.\* injectargs "--osd_max_backfills 1" 
ceph tell osd.\* injectargs "--osd_recovery_max_active 1" --default 3
ceph tell osd.\* injectargs "--osd_recovery_sleep 1" --default 0 
```
### 3.把原来的crush map 注入集群:
如果在对机架操作出现问题时，把原来的crushmap重新载入集群
```
   ceph osd setcrushmap -i {compiled-crushmap-filename}
```
