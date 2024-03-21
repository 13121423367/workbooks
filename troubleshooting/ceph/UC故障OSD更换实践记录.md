# UC故障OSD更换实践记录

### 一、前言

>  本文记录的是uc集群的一次故障osd更换实践，存在一定的时效性，仅做参考

- osd编号：103
- 所在节点：compute69
- 原盘符：sdf
- 操作时间：2021/4/23



### 二、更换流程

**注：以下所有命令均在 uc controller1上 /etc/ceph 目录下执行！**

```bash
#在故障盘所在主机上再确认一次故障盘位
megacli cfgdsply -aALL  | grep -Ei "(slot|count)"
Slot Number: 0  #盘位0
Media Error Count: 0
Other Error Count: 0
Predictive Failure Count: 0
.....
Slot Number: 6  #盘位6
Media Error Count: 5
Other Error Count: 0
Predictive Failure Count: 0
```



#### 2.1 停止scrub及deep-scrub

> 说明：
>
> - scrub: 数据一致性校验
> - deep-scrub：深度校验
>
> - 集群默认全天开启scrub，需要进行换盘操作时，先暂时停止scrub（正在进行的不会停止，但不会新增）

```bash
#命令如下,通知每个pool暂停scrub及deep-scrub
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 1;ceph osd pool set ${i} nodeep-scrub 1;done

#检查命令，全为true表示已正常暂停
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool get ${i} all | grep -E "noscrub|nodeep-scrub";done

#实例
[root@controller1 ceph]# for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool get ${i} all | grep -E "noscrub|nodeep-scrub";done
#########nova#########
noscrub: true
nodeep-scrub: true
#########glance#########
noscrub: true
nodeep-scrub: true
#########k8s#########
noscrub: true
nodeep-scrub: true
#########cinder-sas#########
.................

```

#### 2.2 设置标记

> 说明：暂停集群重分布、暂停集群恢复、暂停集群回填数据、暂停集群将osd标记out

```bash
ceph osd set norebalance && ceph osd set norecover && ceph osd set nobackfill && ceph osd set noout
```

#### 2.3 停止故障osd进程

> 说明：访问需要换盘的服务器，停止对应osd的进程，拷贝原osd挂载的tmpfs目录下内容，并卸载osd对应的tmpfs挂载目录/var/lib/ceph/osd/ceph-xx

```bash
#xx为故障osd编号
ssh computexx "systemctl stop ceph-osd@xx.service && cp -r /var/lib/ceph/osd/ceph-xx /var/lib/ceph/osd/ceph-xx-$(date +%Y%m%d) && 
umount /var/lib/ceph/osd/ceph-xx" 
```

#### 2.4 踢出故障osd

```bash
#将osd从crush map中移除
ceph osd crush remove osd.xx
#删除需要换盘的osd密钥
ceph auth del osd.xx
#删除故障盘
ceph osd rm xx
```

#### 2.5 机房侧更换故障盘

> 说明：先邮件通知机房，告知故障盘具体信息【所在设备、所在盘位等】，让其预先准备所需硬盘
>
> - 邮件给到机房、孙建兴、刘瑞华即可

![image-20210428144645642](../../images/image-20210428144645642.png)

机房侧更换完成后，运维侧做以下操作

##### 2.5.1 检测新硬盘是否有坏块

 ```bash
#查看硬盘是否有坏道,结果全为0则表示正常
megacli cfgdsply -aALL  | grep -Ei "(slot|count)"  #期待结果如下
......
Slot Number: 6
Media Error Count: 0
Other Error Count: 0
Predictive Failure Count: 0
Shield Counter: 0
......
......
 ```

##### 2.5.2 运维侧重做 RAID0

> 说明：
>
> - 数据盘需要**单独**做 RAID0，使用megacli工具设置
> - 本次故障硬盘的盘位 **6**

```bash
#创建raid0
megacli -CfgLdAdd -R0 [32:x] WB RA Cached -strpsz64 -a0  #[32:x] 32固定不变，后面一位根据盘位变化

#实例
[root@compute69 ~]# megacli -CfgLdAdd -R0 [32:6] WB RA Cached -strpsz64 -a0

Adapter 0: Created VD 3

Adapter 0: Configured the Adapter!!

Exit Code: 0x00
```

#### 2.6 部署新盘到集群

#####  2.6.1 擦除旧盘符，设置新盘符

> 说明：
>
> - 新硬盘如果不是全新盘，可能会遗留之前的盘符，需要进行擦除
> - 本次新加硬盘在其他平台作为osd使用过
> - 更换后，新盘符为 **sdh**
> - --block-db与--block-wal 可通过查看原osd备份得知

- lsblk查看盘符信息

​    ![image-20210428145917118](/images/image-20210428145917118.png)

- 擦除

  ```bash
  #作为osd使用过，盘符信息为 ceph-xxx
  dmsetup remove ceph--b57493d8--23be--48e6--8ba2--89b304f36eee-osd--block--8caea96b--f07f--4c0c--8917--b9ef4116a1c8
  
  #如果未作为osd使用过，使用下列命令擦除
  dmsetup remove /dev/$(pvscan | grep '/dev/sdx' | awk '{print $4}')/*  #sdx为旧盘符
  ```

- 设置新盘符

  ```bash
  wipefs -af /dev/sdx --sdx为新盘符
  ```

##### 2.6.2 部署

 ```bash
#computexx: 节点主机名  --data: 新盘符 /dev/sdh  --block-db:加速盘分区 /dev/sdb8  --block-wal:加速盘分区 /dev/sdb7
ceph-deploy --overwrite-conf osd create computexx --data /dev/sdx --block-db /dev/sdbx --block-wal /dev/sdbx
 ```

#### 2.7 取消标记

  ```bash
ceph osd unset norebalance && ceph osd unset norecover && ceph osd unset nobackfill && ceph osd unset noout
  ```

#### 2.8 速度调节

> 说明：根据集群和osd对应的磁盘读写压力，适当调整osd_max_backfills参数(默认值为1)，控制osd数据回填速率。**以调整完参数1分钟之内集群不出现slow request和新增osd使用率不超过80%为界限，按照每次增加2的速率增加**

```bash
#调整单个osd速度，xx为编号
ceph tell osd.xx injectargs "--osd_max_backfills 3"

#调整所有osd速度
ceph tell osd.\* injectargs "--osd_max_backfills 3"

ceph tell osd.\* injectargs "--osd_max_backfills 1" 
ceph tell osd.\* injectargs "--osd_recovery_max_active 1" --default 3
ceph tell osd.\* injectargs "--osd_recovery_sleep 1" --default 0 
```

#### 2.9 放开scrub及调整速度

> 说明：集群重分布完成，恢复为 `HEALTH_OK`状态后，放开`scurb`及调整速度为 `1`

```bash
#放开scrub
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 0;ceph osd pool set ${i} nodeep-scrub 0;done

#检查命令，全为false表示已正常放开
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool get ${i} all | grep -E "noscrub|nodeep-scrub";done

#调整速度为1
ceph tell osd.\* injectargs "--osd_max_backfills 1"
```

#### 2.10 回滚方案

如果出现问题，则暂停恢复操作
`ceph osd set norebalance && ceph osd set norecover && ceph osd set nobackfill && ceph osd set noout`

### 三、拔错盘的处理办法

更换前一定要确认好！若出现意外，使用以下方法恢复

在目标主机上操作

```bash
#让机房人员将原盘插回

#插回后，磁盘的raid信息会变成外来，需要重新导入
megacli  -cfgforeign -scan -a0   #确认-扫描外来配置的个数
megacli -cfgforeign -preview -a0 #确认-查看当前的磁盘在normal时的位置，是否为原来的盘位
megacli -cfgforeign -import -a0  #外来导入配置，恢复虚拟磁盘组

#将原osd目录恢复，使用操作前的备份
rm -rf /var/lib/ceph/osd/ceph-xx
cp -r /var/lib/ceph/osd/ceph-xx-$(date +%Y%m%d) /var/lib/ceph/osd/ceph-xx

#更改目录权限
chown -R /var/lib/ceph/osd/ceph-xx

#重新添加keyring
ceph auth add osd.xx osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/ceph-xx/keyring

#启动osd服务
systemctl start ceph-osd@xx

#ceph -s查看是否加入，若正常加入，放开标记，等待集群状态恢复正常后，再更换真正的故障盘
```

