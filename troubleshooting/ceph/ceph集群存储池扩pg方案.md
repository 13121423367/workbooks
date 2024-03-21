# ceph集群存储池扩pg方案
##### (存储池名字：pool_name ;存储池id：pool_id;存储池现有pg数：XXXXXX;存储池扩容以后的pg数：YYYYYY)
## ceph集群存储池扩pg步骤

### 1. 禁用scrub

#### 停止 scrub
停止scrub命令：
```bash
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 1;ceph osd pool set ${i} nodeep-scrub 1;done
```
停止scrub结果：
```bash
#########pool_name#########
set pool pool_id noscrub to 1
set pool pool_id nodeep-scrub to 1
```
#### 检查 scrub 开关状态:
检查命令：
```bash
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool get ${i} all | grep -E "noscrub|nodeep-scrub";done
```
检查结果：
```bash
#########pool_name#########
noscrub: true
nodeep-scrub: true
```
### 2.查看存储池现有pg数
查看需要扩pg的存储池的pg_num和pgp_num
查看pg_num命令：
```bash
ceph osd pool get pool_name pg_num
```
查看pg_num结果
```bash
pg_num: XXXXXX(存储池中的pg数)
```
查看pgp_num命令：
```bash
ceph osd pool get pool_name pgp_num
```
查看结果
```bash
pgp_num: XXXXXX(存储池中的pg数)
```
### 3.修改存储池的pg数量
调整pg的数量需要调整pg_num和pgp_num
修改pg_num命令：
```bash
ceph osd pool set pool_name pg_num YYYYYY
```
执行结果：
```bash
set pool pool_id pg_num to YYYYYY
```
修改pgp_num命令：
```bash
ceph osd pool set pool_name pgp_num YYYYYY
```
执行结果：
```bash
set pool pool_id pgp_num to YYYYYY
```
#### 重复执行步骤2查看pg_num和pgp_num的值是否为YYYYYY
### 4.查看集群状态
#### 查看集群状态
命令：
```bash
ceph -s
```
通过watch -n 1 "ceph -s"，等待数据重平衡完成，集群变成HEALTH_OK状态即可开启scrub
### 5.开启scrub
#### 开启scrub
开启scrub命令:
``` bash
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 0;ceph osd pool set ${i} nodeep-scrub 0;done
```
开启scrub结果：
```bash
#########pool_name#########
set pool pool_id noscrub to 0
set pool pool_id nodeep-scrub to 0
```
#### 检查 scrub 开关状态
检查命令
```bash
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool get ${i} all | grep -E "noscrub|nodeep-scrub";done
```
检查结果：
```bash
#########pool_name#########
noscrub: false
nodeep-scrub: false
```
## 回滚方案
说明：该操作不可逆，目前相关参数是最低值，造成迁移的数据量相对较小。如果集群出现slow,请调整以下值。
### 调整osd_recovery_sleep 值，默认为0.2，调整为1
```bash
ceph tell osd.\* injectargs "--osd_recovery_sleep  1"
```