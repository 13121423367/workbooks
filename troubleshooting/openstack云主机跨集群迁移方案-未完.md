# openstack虚机跨集群迁移方案

### 一、前言

- **原集群**`LY`不准备继续提供服务，需将集群中的所有客户虚机迁移到**新集群**`HB3`
- 原集群`LY`的所有客户云主机均在租户`laoyun`下
- 原集群`LY`的所有客户云主机仅有`外网ip`
- 因所有集群共用一套`keystone`认证，因此新集群无需新创租户
- 因两个集群在同一机房，本次采用`LY服务器compute12光纤直连HB3存储前端网`的方式，提高迁移速度
- 迁移到新集群后，云主机ip需与原来一致，保证客户业务不中断！
- **本方案仅做参考**

### 二、前期准备

#### 2.1 网络准备

##### 2.1.1 LY【原集群】云主机网络收集

```bash
#导出所有云主机
[root@ly-controller1 ~]# openstack server list --project laoyun > server.txt

#获取主机ip
[root@ly-controller1 ~]#cat server.txt | egrep -o 'IPV4_EXT.*' | awk -F '|' '{print $1}' | cut -d '=' -f 2 > ly_ip.txt

#获取现阶段使用的子网网段
[root@ly-controller1 ~]# cat ly_ip.txt | cut -c 1-10 | sort | uniq
117.50.115
117.50.116
117.50.117
```

##### 2.1.2 HB3【新集群】创建迁移网络并测试

```bash
#创建外部网络LY_IPV4_EXT，本次研发已创建好
[root@controller1 ~]# openstack network list | grep LY
| fff0c354-29a8-4c05-868d-b4143cac7930 | LY_IPV4_EXT       | 6a4d5cee-b57c-446b-80d6-4781adf4e12c, bb80dcc8-79e1-4de9-9baa-de67595fe0da, bb8b7192-005c-4afb-86da-00a326ee521e
|

#按上一步收集的子网网段创建子网
[root@controller1 ~]# openstack subnet list --network LY_IPV4_EXT
+--------------------------------------+------------+--------------------------------------+-----------------+
| ID                                   | Name       | Network                              | Subnet          |
+--------------------------------------+------------+--------------------------------------+-----------------+
| 6a4d5cee-b57c-446b-80d6-4781adf4e12c | subnet_117 | fff0c354-29a8-4c05-868d-b4143cac7930 | 117.50.117.0/24 |
| bb80dcc8-79e1-4de9-9baa-de67595fe0da | subnet_116 | fff0c354-29a8-4c05-868d-b4143cac7930 | 117.50.116.0/24 |
| bb8b7192-005c-4afb-86da-00a326ee521e | subnet_115 | fff0c354-29a8-4c05-868d-b4143cac7930 | 117.50.115.0/24 |
+--------------------------------------+------------+--------------------------------------+-----------------+
```

##### 2.1.3 HB3【新集群】创建ip进行占位

`根据2.1.1得到的ly_ip.txt，编写脚本依次创建ip进行占位`

- 脚本如下

  ```bash
  #/bin/bash
  #根据老云的云主机ip在新集群创建ip进行占位
  network=fff0c354-29a8-4c05-868d-b4143cac7930
  project=laoyun
  for ip in `cat ly_ip.txt`;
  do
    subnet=$(echo $ip | cut -d '.' -f 3)
    name=$(echo $ip | sed 's/\./_/g')
    openstack port create --network $network --fixed-ip subnet=subnet_$subnet,ip-address=$ip --project $project $name > /dev/null
    if [ $? -eq 0 ]
     then
       echo "$ip创建成功" >> create_ip_success.txt
    else
       echo "$ip创建失败" >> create_ip_failed.txt
    fi
  done
  ```

- 测试

  ```bash
  #原主机ip数
  [root@controller1 ~]# cat ly_ip.txt | wc -l
  342
  
  #成功ip数
  [root@controller1 ~]# cat create_ip_success.txt | wc -l
  342
  
  #失败ip数
  [root@controller1 ~]# cat create_ip_failed.txt | wc -l
  0
  
  #新集群租户 laoyun下目标ip数
  [root@controller1 ~]# openstack port list --project laoyun | grep 117 | wc -l
  342
  ```

​     **数量一致，创建成功**





#### 2.2 迁移环境准备

##### 2.2.1 ceph环境准备

 `如前言所说，使用LY compute12作为中转机，直连到HB3 ceph集群的存储前端网。在compute12上同时存放LY和HB3的ceph集群配置，之后便可以通过指定不同的配置文件，从comupte12直接导出LY虚机的卷，并导入到HB3中，大大提高迁移效率`

  HB3存储前端网：10.250.1.0/24

  LY compute12待配置网卡：p4p3

- 物理接线

  与网络、机房协同操作，已完成

- 中转机网络配置

  ```bash
  #LY compute12 p4p3配置
  [root@ly-compute12 ~]# more /etc/sysconfig/network-scripts/ifcfg-p4p3
  TYPE=Ethernet
  BOOTPROTO=static
  NAME=p4p3
  DEVICE=p4p3
  ONBOOT=yes
  USERCTL=no
  IPADDR=10.250.1.100
  NETMASK=255.255.255.0
  ```

- 连通测试

  ```bash
  [root@ly-compute12 ~]# ping 10.250.1.13
  PING 10.250.1.13 (10.250.1.13) 56(84) bytes of data.
  64 bytes from 10.250.1.13: icmp_seq=1 ttl=64 time=0.117 ms
  64 bytes from 10.250.1.13: icmp_seq=2 ttl=64 time=0.182 ms
  64 bytes from 10.250.1.13: icmp_seq=3 ttl=64 time=0.147 ms
  ```

- rbd安装

  `rbd是ceph的块存储操作程序，需要提前安装，本次已安装`

  ```bash
  yum -y install centos-release-ceph-nautilus.noarch
  yum -y install ceph-common
  ```

- 复制ceph集群配置文件

  `分别复制LY及HB3 ceph集群配置文件到compute12不同目录`

  ```bash
  #LY ceph
  [root@ly-compute12 ~]# ls /etc/ceph
  ceph.bootstrap-mds.keyring  ceph.bootstrap-osd.keyring  ceph.client.admin.keyring       ceph.client.glance.keyring  ceph.conf    ceph.mon.keyring
  ceph.bootstrap-mgr.keyring  ceph.bootstrap-rgw.keyring  ceph.client.cinder-sas.keyring  ceph.client.nova.keyring    ceph-deploy-ceph.log  rbdmap
  
  #HB3 ceph
  [root@ly-compute12 ~]# ls /etc/hb3/ceph/
  ceph.bootstrap-mds.keyring  ceph.bootstrap-rgw.keyring      ceph.client.glance.keyring  ceph.conf-20201010  ceph.conf.auto_deploy.ori   tmpX21bfE
  ceph.bootstrap-mgr.keyring  ceph.client.admin.keyring       ceph.client.nova.keyring    ceph.conf-20201102  ceph-deploy-ceph.log       rbdmap
  ceph.bootstrap-osd.keyring  ceph.client.cinder-sas.keyring  ceph.conf                   ceph.conf.20210319  ceph.mon.keyring           tmpN8qjXr
  qianyi@123
  ```

- rbd测试查看

  `通过指定不同的配置文件查看不同ceph集群的pool数据`

    两个集群都存储pool `glance`，以查看glance为例

  ```bash
  #LY compute12查看LY pool glance的前三数据，因为中转机位于LY，因此查看LY的无需指定配置文件
  [root@ly-compute12 ~]# rbd ls glance | head -3
  052f4e16-fde0-48a8-861c-9c6c814676c5
  22e17210-eb00-4c7c-b00c-5bd0d5052551
  271ae9d6-c3f5-4b36-95a6-26c863531292
  
  #HB3任一存储节点查看glance前三数据
  [root@compute18 ~]# rbd ls glance | head -3
  048d5471-1f49-46cb-afd3-7208d0901048
  05a94345-6306-40d7-9cea-f1392b90060e
  079f1705-5e94-4a57-ad48-e8d57b0316fb
  
  
  #LY compute12通过指定HB3配置文件，查看HB3 glance前三数据，与上一步结果进行对比，一致则正常
  [root@ly-compute12 ceph]# rbd ls glance -c /etc/hb3/ceph/ceph.conf -k /etc/hb3/ceph/ceph.client.admin.keyring | head -3
  048d5471-1f49-46cb-afd3-7208d0901048
  05a94345-6306-40d7-9cea-f1392b90060e
  079f1705-5e94-4a57-ad48-e8d57b0316fb
  ```

  由上可知，compute12查看两个ceph集群的数据正常，ceph环境准备完毕

##### 2.2.2 openstack环境准备

 `在compute12上创建两个租户laoyun的认证文件，一个指向LY，一个指向HB3，并安装openstack客户端`

 ```bash
#安装openstack客户端,本次已安装
yum -y install python-openstackclient

#创建指向LY的认证文件
[root@ly-compute12 qianyi]# more LY-openrc.sh
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=laoyun
export OS_TENANT_NAME=laoyun
export OS_USERNAME=laoyun
export OS_PASSWORD=xxxx
export OS_AUTH_URL=http://xxx/v3
export OS_INTERFACE=internal
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME=LY
export OS_AUTH_PLUGIN=password

#创建指向HB3的认证文件
[root@ly-compute12 qianyi]# more HB3-openrc.sh
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=laoyun
export OS_TENANT_NAME=laoyun
export OS_USERNAME=laoyun
export OS_PASSWORD=xxxx
export OS_AUTH_URL=http://xxx/v3
export OS_INTERFACE=internal
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME=HB3  #注意更改
export OS_AUTH_PLUGIN=password

#分别source，并查看租户laoyun的虚机，以LY为例，观察是否符合实际情况
[root@ly-compute12 qianyi]# source LY-openrc.sh
[root@ly-compute12 qianyi]# openstack server list | head -5
 ```

查看正常，openstack环境准备完毕

#### 2.3 系统盘及数据盘迁移测试

#####  2.3.1 LY【原集群】租户现用镜像收集

- centos6_6_base
- offical-centos6.5
- offical-centos7.4
- offical-win2012_vol_datacenter_base 
- win08

##### 2.3.2 LY创建虚机进行系统盘迁移

  `在LY中根据上一步收集的镜像分别建一台虚机【虚机ip需在2.1.1收集的网段中】，模拟客户虚机，将系统盘导出到compute12，再导入到HB3 ceph集群中，HB3中根据导入的盘新建虚机`

   **以centos6_6_base为例：**

- LY创建虚机，并导出系统盘到中转机

  ```bash
  #LY新建虚机centos6.6-test，在控制节点查看信息
  
  [root@ly-controller1 ~]# openstack server list --project laoyun
  +--------------------------------------+----------------+--------+----------------------------+-------+--------+
  | ID                                   | Name           | Status | Networks                   | Image | Flavor |
  +--------------------------------------+----------------+--------+----------------------------+-------+--------+
  | 878462f3-3680-4c94-b8aa-893ca7231ca4 | centos6.6-test | ACTIVE | IPV4_EXT_NET=117.50.115.73 |       | 2C2G   |
  +--------------------------------------+----------------+--------+----------------------------+-------+--------+
  
  #centos6.6-test中写入任意数据
  
  #控制节点查看虚机centos6.6-test的磁盘挂载情况，第一个为系统盘，其他为数据盘！
  [root@ly-controller1 ~]# openstack server show 878462f3-3680-4c94-b8aa-893ca7231ca4 -c volumes_attached
  +------------------+-------------------------------------------+
  | Field            | Value                                     |
  +------------------+-------------------------------------------+
  | volumes_attached | id='db18684e-7b89-4701-aef3-34486f37fc2f' |
  |                  | id='5f055468-018e-4e7d-8c1f-817ad68b9fe9' |
  +------------------+-------------------------------------------+
  
  #compute12上操作，将LY ceph pool cinder-sas中的虚机系统盘导出到本地
  #创建存放目录
  [root@ly-compute12 ~]# mkdir /qianyi
  
  #导出系统盘，以虚机ip.bak进行命名
  [root@ly-compute12 ~]# rbd export cinder-sas/volume-db18684e-7b89-4701-aef3-34486f37fc2f /qianyi/117_50_115_73.bak
  Exporting image: 100% complete...done.
  
  
  #导出速度粗略计算为：110MB/S
  ```
- HB3创建同规格硬盘，设为可启动

  `在HB3中,laoyun租户下创建一块与LY导出的系统盘规格相同的硬盘，设置为可启动`

  ```bash
#LY compute12上操作
[root@ly-compute12 ~]# source /qianyi/HB3-openrc.sh
[root@ly-compute12 ~]# openstack volume create --bootable --size 30 centos6.6_qianyi
[root@ly-compute12 ~]# openstack volume list --project laoyun
+--------------------------------------+------------------+-----------+------+-------------+
| ID                                   | Name             | Status    | Size | Attached to |
+--------------------------------------+------------------+-----------+------+-------------+
| 082bf9f0-e8ea-446b-8eea-f289d1200348 | centos6.6-qianyi | available |   30 |             |
+--------------------------------------+------------------+-----------+------+-------------+
  ```

- 在HB3 ceph中，替换上一步所建硬盘

  ```bash
  #LY compute12上操作
  
  #硬盘重命名
  [root@ly-compute12 ~]# rbd rename cinder-sas/volume-082bf9f0-e8ea-446b-8eea-f289d1200348 cinder-sas/volume-082bf9f0-e8ea-446b-8eea-f289d1200348.bak -c /etc/hb3/ceph/ceph.conf -k /etc/hb3/ceph/ceph.client.admin.keyring
  
  #硬盘替换
  [root@ly-compute12 ~]# rbd import /qianyi/117_50_115_73.bak cinder-sas/volume-082bf9f0-e8ea-446b-8eea-f289d1200348 -c /etc/hb3/ceph/ceph.conf -k /etc/hb3/ceph/ceph.client.admin.keyring
  Importing image: 100% complete...done.
  
  
  #导入速度粗略计算为：64MB/S
  ```

- 在HB3中，使用替换后的硬盘创建虚机

  ```bash
  #LY compute12上操作
  #先暂时卸载原虚机的ip
  [root@ly-compute12 ~]# source /qianyi/LY-openrc.sh
  [root@ly-compute12 ~]# openstack server remove port centos6.6-qianyi dab6fe9b-0b8a-45f2-9a8b-46c79392dea2
  
  #HB3中查询ip，获取端口id
  [root@ly-compute12 ~]# openstack port list | grep 117_50_115_73
  | 4b40c9e1-7b25-418c-a844-1794361a48b1 | 117_50_115_73_qy_test | fa:16:3e:0b:85:aa | ip_address='117.50.115.73', subnet_id='bb8b7192-005c-4afb-86da-00a326ee521e'  | DOWN   |
  
  #HB3创建新虚机
  [root@ly-compute12 ~]# openstack server create --flavor 48b52d2b-fe39-4503-b7b6-6d7a382a2020 --volume 3ecb319f-6d64-40d3-8759-6982888a7f39 --nic port-id=4b40c9e1-7b25-418c-a844-1794361a48b1 centos6.6_qy_hb3
  ```

- 测试

  `创建完成后，进入控制台测试以下几点`

  - 密码是否一致
  - 任意写入的文件是否存在
  - ip是否一致
  - 业务访问是否正常

##### 2.3.1 LY虚机中数据盘迁移

- 迁移重点
  - 硬盘大小一致
  - 硬盘类型一致
  - 设置为不可启动
  - 创建新虚机时，一同挂载



### 
