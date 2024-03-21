# 华北三区新增节点snap参数同步操作步骤
## 修改参数说明
由于华北三区新加的三个host节点：compute40、compute41、compute42关于snap中snaptrim和snaptrim_wait状态的三个参数不同步，所以需要执行同步操作。需要同步的参数如下：
参数名称 原始值=>新值
osd_pg_max_concurrent_snap_trims  2 => 5
osd_snap_trim_cost  1048576 => 104857600
osd_snap_trim_sleep_hdd 5 => 0

## 验证参数命令
在controller1目录下执行，执行命令：
```bash
ceph osd status | grep up | awk '{print $4,$2}' | while read host osd ; do echo $host:$osd  ; ssh $host ceph daemon osd.$osd config show < /dev/null |  grep -E 'osd_pg_max_concurrent_snap_trims|osd_snap_trim_cost|osd_snap_trim_sleep_hdd'  ; done
```
执行结果参考：
```
compute23:29
    "osd_pg_max_concurrent_snap_trims": "5",
    "osd_snap_trim_cost": "104857600",
    "osd_snap_trim_sleep_hdd": "0.000000",
compute40:30
    "osd_pg_max_concurrent_snap_trims": "2",
    "osd_snap_trim_cost": "1048576",
    "osd_snap_trim_sleep_hdd": "5.000000",
```
## 修改命令
在controller1目录下执行，执行命令：
```
ceph tell osd.\* injectargs  "--osd_pg_max_concurrent_snap_trims 5 "
ceph tell osd.\* injectargs  "--osd_snap_trim_cost 104857600"
ceph tell osd.\* injectargs  "--osd_snap_trim_sleep_hdd 0"
```
执行结果参考如下：
```
osd.0: osd_pg_max_concurrent_snap_trims = '5'
```
修改成功以后继续执行验证参数命令，确定所有osd的osd_pg_max_concurrent_snap_trims、osd_snap_trim_cost 104857600、osd_snap_trim_sleep_hdd参数一致

## 修改配置文件
修改配置文件之前先对各个节点的配置文件进行备份，修改完配置文件之后需要同步到各个节点
在controller1 的/etc/ceph/ceph.conf 配置文件进行修改，在[osd]下增加如下配置：

```
osd_pg_max_concurrent_snap_trims = 5
osd_snap_trim_cost = 104857600
osd_snap_trim_sleep_hdd = 0
```
修改完配置文件如下图所示：
```
[osd]
 osd_pg_max_concurrent_snap_trims = 5
 osd_snap_trim_cost = 104857600
 osd_snap_trim_sleep_hdd = 0
```
修改配置文件并且同步到各个节点完成以后，重启osd会自动读取配置文件中的配置，后期新增节点不需要再重新修改新增的osd关于snap这三个参数的配置
