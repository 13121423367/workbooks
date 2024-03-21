# 一．老云踢出OSD操作步骤（computexxx osd yyyy  sdz）

## 操作步骤

### 1. 禁用scrub(执行机器、目录、验证方法)

#### 停止 scrub

停止scrub命令：
```bash
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 1;ceph osd pool set ${i} nodeep-scrub 1;done
```
停止scrub结果(仅供参考)：
```bash
#########poolname#########
set pool poolnumber noscrub to 1
set pool poolnumber nodeep-scrub to 1
```

#### 检查 scrub 开关状态:
检查命令为：
```bash
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool get ${i} all | grep -E "noscrub|nodeep-scrub";done
```
检查结果(仅供参考)：
```bash
#########poolname#########
noscrub: true
nodeep-scrub: true
```
### 2. 停止并禁用该osd的服务

```bash
ssh computexxx "systemctl stop ceph-osd@yyyy.service"
ssh computexxx "systemctl disable ceph-osd@yyyy.service"
```
### 3. 切换目录到 /etc/ceph 下

```bash
cd /etc/ceph
```

### 4. 将osd标记为out

```bash
ceph osd out osd.yyyy
```

### 5. 将osd从crushmap中剔除

```bash
ceph osd crush remove osd.yyyy
```

### 6. 删除OSD认证

```bash
ceph auth del osd.yyyy
```

### 7. 彻底将osd从集群删除

```bash
ceph osd rm osd.yyyy
```

### 8. ssh 到删除的host目录，解绑已经移除的osd的目录

```bash
ssh computexxx "umount /var/lib/ceph/osd/ceph-yyyy"
```

### 9.查看集群状态和OSD是否已经移除

检查命令：
```bash
ceph osd df tree
ceph -s
```
#### 如果新加或踢出osd之后，recover速率太低，整个集群恢复时间较长，可以对recover进行提速处理。老云集群默认osd_max_backfills为1，可以适当调高，观察是否会有slow，如果出现slow可以先把osd_max_backfills恢复默认值，如果观察还有slow，再调整osd_recovery_sleep参数。

```bash
ceph tell osd.\* injectargs "--osd_max_backfills 3"
```

##### 如果新加或踢出osd之后，recover速率过高，对clientIO产生较大影响时(集群产生slow request)，可以对recover进行限速处理

参考命令：

```bash
ceph tell osd.\* injectargs "--osd_recovery_sleep 1" 
```

通过watch -n 1 "ceph -s"观察是否出现slow request，如果执行上述命令后，仍然影响clientIO，可继续加大osd_recovery_sleep值，重新执行。

等待数据重平衡完成，集群变成HEALTH_OK状态即可开启scrub

### 10.开启scrub
#### 开启scrub
开启scrub命令:
``` bash
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 0;ceph osd pool set ${i} nodeep-scrub 0;done
```
开启scrub结果(仅供参考)：
```bash
#########poolname#########
set pool poolnumber noscrub to 0
set pool poolnumber nodeep-scrub to 0
```

#### 检查 scrub 开关状态
检查命令为
```bash
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool get ${i} all | grep -E "noscrub|nodeep-scrub";done
```
检查结果(仅供参考)：
```bash
#########poolname#########
noscrub: false
nodeep-scrub: false
```

