### 1. 设置各个pool暂停scrub和deep-scrub

命令：
```
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 1;ceph osd pool set ${i} nodeep-scrub 1;done
```
检查命令：
```
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool get ${i} all | grep -E "noscrub|nodeep-scrub";done
```



### 2. 设置norebalance、norecover、nobackfill、noout

命令：
```
ceph osd set norebalance;ceph osd set norecover;ceph osd set nobackfill;ceph osd set noout;
```
检查命令：
```
ceph -s 
```



### 3. 重启osd服务

登录到相应的host执行 查找host可使用命令`ceph osd find osd.xx`

命令：

```
systemctl restart ceph-osd@XX.service
```

检查命令：

```
ps -ef | grep osd
```



### 4.恢复norebalance、norecover、nobackfill、noout

命令：

```
ceph osd unset norebalance;ceph osd unset norecover;ceph osd unset nobackfill;ceph osd unset noout;
```



### 5.设置各个pool开启scrub和deep-scrub

待所有OSD都重启完成并且集群数据重新分布完成之后，设置各个pool开启scrub和deep-scrub
命令：

```
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 0;ceph osd pool set ${i} nodeep-scrub 0;done
```
检查命令：
```
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool get ${i} all | grep -E "noscrub|nodeep-scrub";done
```
