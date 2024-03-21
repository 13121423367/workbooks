1.经过测试环境测试这种方法不造成数据迁移，但是为了以防万一还是先设置不能数据迁移的标签
```
ceph osd set norebalance;ceph osd set norecover;ceph osd set nobackfill;
```
2.停止scrub
参考命令：

```
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 1;ceph osd pool set ${i} nodeep-scrub 1;done
```
检查命令：
```
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool get ${i} all | grep -E "noscrub|nodeep-scrub";done
```
3.数据池重新命名命令：
```
ceph osd pool rename poolname poolname-new
```
4.创建池子命令：

```
ceph osd pool create poolname pg-num pgp-num
```
(备注：创建池子的pg_num和pgp_num要一样）

5.设置池子属性

```
ceph osd pool application enable pool-name app-name
```

注释：app-name 是cephfs、rbd、rgw三个的任意一种

6.放开数据标签

```
ceph osd unset norebalance;ceph osd unset norecover;ceph osd unset nobackfill;
```
7.放开scrub：
参考命令：
```
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 0;ceph osd pool set ${i} nodeep-scrub 0;done
```
检查命令：
```
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool get ${i} all | grep -E "noscrub|nodeep-scrub";done
```