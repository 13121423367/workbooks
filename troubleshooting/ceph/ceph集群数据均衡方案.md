# ceph数据均衡

说明：

​		该步骤只有第一次操作的时候需要得到osd.map以及out.txt（这两个名字可以自定义），然后根据结果优先选择要调整的pg，研发或者运维人员可以根据使用率情况选择执行的顺序，这里建议优先调整使用率高的osd，并且一次性调整不要超过3个，直到调整完成。

​		后续如果再出现数据不均衡再重新获取osdmap以及结果并进行调整。

​		如果只是想获取结果，则跳过步骤1，从步骤2执行到步骤6获取结果，禁用scrub是要做操作的时候才执行的

## ceph集群数据均衡步骤

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
### 2.设置ceph最低版本
命令：
```bash
ceph osd set-require-min-compat-client luminous --yes-i-really-mean-it
```
查看结果
```bash
set require_min_compat_client to luminous
```
查看特性命令(可忽略，线上都是L以及L以上版本)：
```bash
ceph features
```
### 3.获取OSDmap

命令：

```bash
ceph osd getmap -o osd.map
```
执行结果：
```bash
got osdmap epoch XXX
```
### 4.查看要均衡的存储池

命令：

```bash
ceph osd lspools
```

执行结果：

```bash
13 testpool1,14 pool1,15 .rgw.root,16 default.rgw.control......
```

### 5.对要操作的存储池执行计算并输出结果
命令：
```bash
osdmaptool osd.map --upmap out.txt --upmap-pool testpool1 --upmap-max 100
```
注意：osd.map是步骤3生成的文件，out.txt是输出的结果，testpool1是要操作的存储池名称，100是计算的次数，设置100即可

结果(以testpool存储池为例)：

```bash
osdmaptool: osdmap file 'osd.map'
writing upmap command output to: out.txt
checking for upmap cleanups
upmap, max-count 100, max deviation 5
 limiting to pools testpool1 ([13])
pools testpool1 
prepared 59/100 changes
```

### 6.对要操作的存储池执行计算并输出结果

命令：

```bash
cat out.txt
```

输出：

```bash
ceph osd pg-upmap-items 13.0 5 0
ceph osd pg-upmap-items 13.1 4 0
ceph osd pg-upmap-items 13.3 4 2
......
```



### 7.执行结果

说明：最简单的方式是直接source out.txt，但是这种迁移数据过多，不推荐使用，因此可以对结果执行其中的几项，分批次完成，这里以步骤6输出结果的第一个为例。

命令：

```bash
ceph osd pg-upmap-items 13.0 5 0
```

输出：

```bash
set 13.0 pg_upmap_items mapping to [5->0]
```



### 8.查看集群状态

命令：

```bash
ceph -s
```

### 9.开启scrub

#### 开启scrub
待集群恢复完成后开启，开启scrub命令:
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

说明：如果出现异常，那么还原调整前的pg，以之前的操作ceph osd pg-upmap-items 13.0 5 0为例。

```bash
ceph osd pg-upmap-items 13.0 0 5 
```

可以通过osd_recovery_max_active参数调整速度，以OSD.5为例

```bash
ceph tell osd.5 injectargs "--osd_recovery_max_active 3" 
```

