# openstack计算节点故障处理流程

## 一、环境说明

集群整体为 openstack+ceph的架构，根据各区业务情况，计算节点分为以下两种。

- 纯计算节点
- 计算+存储节点

每种情况处理流程稍有不同，下面分别细述

## 二、纯计算节点故障处理

### 2.1 节点宕机

#### 2.1.1 情形分析

  指物理节点在计划之外宕机，且未能立即重启的情况

- 影响  ----  节点上的客户虚机无法远程、业务无法访问
- 故障级别  -----  严重

#### 2.1.2 处理办法

##### 2.1.2.1 带外(BMC)尝试重启

进入节点的带外管理页面，手动进行电源重启操作，观察节点启动是否正常

- 重启正常 -------- 做以下检查

  ```bash
  #检查重点业务容器运行状况
  docker ps | grep -E '(nova|neutron|iscsid)'   #容器状态是否全为up状态
  
  #网络检查
  ip a | grep bond  #管理、存储、业务bond及其子网卡状态是否全为up
  ```

- 重启不正常，执行下一步

##### 2.1.2.2 节点主机疏散

 **在对应区任一控制节点执行**

- 原故障节点上所有主机信息收集

  ```bash
  openstack server list --all --host 故障节点主机名 -f value -c ID > evacuate_vm.txt
  ```

- 疏散

   公有云直接操作，私有云提前通知客户
   
   - 整机疏散
   
     ```bash
     nova host-evacuate 故障节点主机名  #正常回显示例如下
     +--------------------------------------+-------------------+---------------+
     | Server UUID                          | Evacuate Accepted | Error Message |
     +--------------------------------------+-------------------+---------------+
     | 8a5515a0-bdb3-414b-a739-8f1d6f6d9187 | True              |               |
     | 8e638045-0b14-41b0-844f-816ae2ee0185 | True              |               |
     +--------------------------------------+-------------------+---------------+
     ```
   
   - 单个云主机疏散
   
     适用于以下情形：
   
     - 云主机数量较少
   
     - 整机疏散失败
     - 个别云主机配置太高、无空余物理节点可容纳
   
     ```bash
     nova evacuate 主机id  #正常无回显
     ```

##### 2.1.2.3 疏散情况跟踪

根据之前收集的疏散信息，提取主机uuid列表、外网ip列表

```bash
#查询疏散主机的当前所在节点、状态，筛选出疏散异常的云主机
for i in `cat evacuate_vm.txt` ;do echo -en "$i\t" ; openstack server show -f value  -c OS-EXT-SRV-ATTR:host -c status $i  ; done | grep -v ACTIVE

#处理疏散后状态异常主机，将状态重置为active
nova reset-state --active 主机uuid  #单个主机重置
for i in `cat evacuate_vm.txt` ;do echo -en "$i\t" ;nova reset-state --active $i;done  #将所有疏散主机重置为active

#找一可通外网的主机，检测疏散主机的外网连通情况
for ip in `cat evacuate_vm.txt`;do ping -c 2 -w 2 $ip;if [ $? -ne 0 ];echo "$ip ngggg";done

#疏散主机vnc控制台状态查看
for i in `cat evacuate_vm.txt` ;do echo -en "$i\t" ;openstack console url show $i;done #获取控制台链接
#浏览器逐个打开排查，统计启动异常(卡住、黑屏等)的主机

#单开一个窗口定时查看故障节点上主机疏散情况
while true;do openstack server list --all --host 故障节点主机名;sleep 15;done
```

##### 2.1.2.4 疏散结果统计

| 主机uuid | 当前所在节点 | 当前状态 | 外网连接状况 | vnc控制台状态 | 备注 |
| :------: | :----------: | :------: | :----------: | :-----------: | :--: |
|          |              |          |              |               |      |

##### 2.1.2.5 故障原因深度排查

### 2.2 节点上主机异常

#### 2.2.1 情形分析

- 现象：单个计算节点上多个主机状态为active，但无法远程、重启后卡住或控制台显示异常
- 故障级别：高

#### 2.2.2 处理办法

##### 2.2.2.1 初步排查

- 优先排查节点管理网是否正常

  - 管理网异常的表现

    - 云主机远程、业务访问不受影响
    - 云主机控制台无法访问，已打开的也会断掉

    - 云主机的所有操作底层都无法真正执行，前端显示xx中
    - 节点上无法新建、删除云主机
    - 节点上云主机无法迁移、其他节点也不能迁移到该节点
    - **节点上的nova-compute服务被标记为down**

  - 处理办法

    - 联系网络处理，若1小时内无法恢复，执行 `2.2.2.3`

- 其次检查ceph集群状态是否正常

  - ceph集群状态异常的表现

    - 云主机启动、重启等操作卡顿或直接卡住
    - 远程卡顿或无法连接
    - 读写数据异常或报错
    - 业务访问卡顿或无法访问

  - 处理办法

    ceph集群问题，无需操作云主机，联系研发共同处理即可

- 若前两项都正常，联系研发排查nova相关容器服务是否正常

  - nova_libvirt服务异常的表现
    - 与管理网异常基本一致
    - 区别
      - nova_compute服务不会被标记为down
      - 已打开的控制台访问正常【刷新后断掉】，但无法打开新的控制台访问
  - nova_compute服务异常的表现
    - 与管理网异常基本一致
    - 区别
      - 已打开的控制台访问正常【刷新后断掉】，但无法打开新的控制台访问
    
  - 处理办法
    - 30分钟内可处理，等待研发处理完毕
    - 否则先尝试执行 `2.2.2.2`，不行再执行 `2.2.2.3`

##### 2.2.2.2 异常云主机迁移

**实际操作根据具体情况选择执行**

```bash
#单个热迁
openstack server migrate --live 目标节点主机名 异常主机uuid

#单个冷迁，热迁无法执行时操作
nova migrate --host 目标节点主机名 异常主机uuid

#整机热迁移
nova host-evacuate-live 故障节点主机名

#整机冷迁移
nova host-servers-migrate 故障节点主机名
```

##### 2.2.2.3 异常云主机疏散

 **仅在主机无法进行迁移操作时执行**

- 原云主机可以不关机，但为了防止意外情况，建议将故障节点上的`nova_libvirt`服务也一起停掉、将所有原云主机关机在疏散

```bash
#主机无法进行迁移操作时执行
ssh 故障节点主机名 'docker stop nova_compute;docker stop nova_libvirt' #停掉nova-compute、nova_libvirt服务，执行后等待1分钟
openstack hypervisor list | grep 故障节点主机名 #检查是否已标记为down
| 18 | 故障节点主机名            | QEMU            | xxx | down  |

#收集原云主机信息
openstack server list --all --host 故障节点主机名 > evacuate_vm.txt

#执行疏散 **实际操作根据具体情况选择执行**
nova evacuate 异常云主机  #单个云主机疏散
nova host-evacuate 故障节点主机名  #整机疏散
```

##### 2.2.2.4 疏散情况跟踪

 `参考：2.1.2.3`

##### 2.2.2.5 疏散结果统计

 `参考: 2.1.2.4`

##### 2.2..2.6  故障原因深度排查

## 三、计算+存储节点故障处理

### 3.1 节点宕机

由于该类型节点上多了存储节点功能，因此在操作前，需要先对ceph集群进行操作

#### 3.1.1 ceph集群标记

 ```bash
#停止scrub和deep-scrub
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 1;ceph osd pool set ${i} nodeep-scrub 1;done

#打上osd noout、no recover等标记
ceph osd set norebalance;ceph osd set norecover;ceph osd set nobackfill;ceph osd set noout
 ```

#### 3.1.2  故障处理

 **ceph做好标记后，将该节点按纯计算节点处理即可**

#### 3.1.3 恢复处理

```bash
#放开scrub和deep-scrub
for i in `ceph osd pool ls`;do echo "#########${i}#########";ceph osd pool set ${i} noscrub 0;ceph osd pool set ${i} nodeep-scrub 0;done

#取消osd noout、no recover等标记
ceph osd unset norebalance;ceph osd unset norecover;ceph osd unset nobackfill;ceph osd unset noout
```

### 3.2 节点上主机异常

**按纯计算节点处理即可**

## 四、疏散测试

### 4.1 目的

- 验证整机疏散时，节点负载情况和是否有并发限制
- 验证原虚机不关机，疏散后新主机启动、访问是否正常
- 验证疏散后，带数据盘的新主机实例启动、访问、数据盘读写是否正常

### 4.2 测试环境

```bash
[root@con01 ~]# openstack hypervisor list
+----+---------------------+-----------------+---------------+-------+
| ID | Hypervisor Hostname | Hypervisor Type | Host IP       | State |
+----+---------------------+-----------------+---------------+-------+
|  3 | compute1            | QEMU            | 172.16.100.54 | up    |
|  9 | compute2            | QEMU            | 172.16.100.55 | up    |
| 18 | compute3            | QEMU            | 172.16.100.56 | up    |
+----+---------------------+-----------------+---------------+-------+
```

### 4.3 测试项及结果

- 关闭compute1上的docker服务，整机疏散，所有实例仅有系统盘

  - 操作

    此时compute1上共36台虚机

    ```bash
    [root@con01 ~]# openstack server list --all --host compute1 | grep vm | wc -l
    36
    [root@con01 ~]# ssh compute1 'systemctl stop docker'
    [root@con01 ~]# openstack hypervisor list
    +----+---------------------+-----------------+---------------+-------+
    | ID | Hypervisor Hostname | Hypervisor Type | Host IP       | State |
    +----+---------------------+-----------------+---------------+-------+
    |  3 | compute1            | QEMU            | 172.16.100.54 | down  | #被标记为down
    |  9 | compute2            | QEMU            | 172.16.100.55 | up    |
    | 18 | compute3            | QEMU            | 172.16.100.56 | up    |
    +----+---------------------+-----------------+---------------+-------+
    [root@con01 ~]# nova host-evacuate compute1
    ```

  - 结果

    - 疏散命令执行后，10秒内所有主机状态更改为 **REBUILD**

    - 查看日志，分为两批疏散，第一次14台，第二次22台，应有并发控制，但不是恒定值
    - 疏散完成后，抽样检查当前所在节点、状态及控制台访问，均正常 
    - 此时原宿主机上虚机进程依旧存在且为running状态
    - 将compute1上docker服务重启，其nova_compute服务恢复后，原宿主机上虚机进程被删除

- 关闭compute2的docker服务，单实例疏散（带数据盘)

  - 操作

    ```bash
    ssh compute2 'systemctl stop docker'
    [root@con01 ~]# openstack hypervisor list
    +----+---------------------+-----------------+---------------+-------+
    | ID | Hypervisor Hostname | Hypervisor Type | Host IP       | State |
    +----+---------------------+-----------------+---------------+-------+
    |  3 | compute1            | QEMU            | 172.16.100.54 | up    | 
    |  9 | compute2            | QEMU            | 172.16.100.55 | down  |#被标记为down
    | 18 | compute3            | QEMU            | 172.16.100.56 | up    |
    +----+---------------------+-----------------+---------------+-------+
    
    #以vm999为例
    [root@con01 ~]# nova evacuate vm999
    ```

  - 结果

    - 疏散完成后，检查其当前所在节点、状态及控制台访问，均正常
    - 数据盘能够正常进行读写

