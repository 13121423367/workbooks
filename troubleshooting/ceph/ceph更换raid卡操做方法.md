# ceph存储节点raid卡故障维护操作步骤

计算与存储复用的节点在关机前先做好虚机疏散等工作



## 1.暂停osd脱机、数据回填和数据恢复

设置noout、norebalance、norecover、nobackfill

参考命令：

在controller1执行

```
ceph osd set noout;ceph osd set norebalance;ceph osd set norecover;ceph osd set nobackfill;
```
检查命令：
```
ceph -s 
```



## 2.节点关机进行维护

IDC进行更换raid卡操作，期间ceph集群将不会产生数据迁移和恢复



## 3.节点维护完成，并且正常开机后检查raid卡是否正常

查看RAID组信息，参考命令：

```
megacli -LDInfo -LALL -aAll | grep RAID
```

结果：

```
RAID Level          : Primary-1, Secondary-0, RAID Level Qualifier-0
RAID Level          : Primary-0, Secondary-0, RAID Level Qualifier-0
RAID Level          : Primary-0, Secondary-0, RAID Level Qualifier-0
RAID Level          : Primary-0, Secondary-0, RAID Level Qualifier-0
RAID Level          : Primary-0, Secondary-0, RAID Level Qualifier-0
RAID Level          : Primary-0, Secondary-0, RAID Level Qualifier-0
RAID Level          : Primary-0, Secondary-0, RAID Level Qualifier-0
```



## 4. 恢复osd脱机、数据回填和数据恢复，等待集群进行数据恢复

参考命令：

在controller1执行

```
ceph osd unset noout;ceph osd unset norebalance;ceph osd unset norecover;ceph osd unset nobackfill;
```
检查命令：
```
ceph -s 
```

