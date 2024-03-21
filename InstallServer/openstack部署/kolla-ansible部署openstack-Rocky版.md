### kolla-ansible部署openstack-Rocky版





/etc/kolla/globals.yml

/home/deploy/multinode

```bash
openstack安装包(私有云uc)：
[root@controller1 ~]# ll /home/deploy/*.tar.gz
-rw-r--r-- 1 root root  23903759 Jun 28  2019 /home/deploy/ceph-common.tar.gz
-rw-r--r-- 1 root root      8288 Jun 28  2019 /home/deploy/kolla_config.tar.gz
-rw-r--r-- 1 root root  40422995 Jun 28  2019 /home/deploy/pip_cache.tar.gz
-rw-r--r-- 1 root root 361070071 Jun 28  2019 /home/deploy/yum_cache.tar.gz

#关闭selinux【所有节点】
sed -i  "s/^SELINUX=.*\$/SELINUX=disabled/g" /etc/selinux/config

#升级内核【所有节点】    *如果内核版本为centos7.5默认版本3.10.0-862.el7.x86_64，需要升级内核版本，否则会出现DVR 模式下的floating IP无法DNAT

yum update kernel -y                        *需要重启机器使内核生效

#关闭防火墙服务【所有节点】
systemctl disable firewalld.service
systemctl stop firewalld.service

#设置主机名称【所有节点】
hostnamectl set-hostname nodex

#配置主机名映射【所有节点】
vi /etc/hosts
172.16.1.126  host1
172.16.1.140  host2
172.16.1.135  host3

#设置互信【node1节点】
ssh-keygen
ssh-copy-id host1
ssh-copy-id host2
ssh-copy-id host3

#配置KVM嵌套虚拟化【所有计算节点】可选
cat << EOF > /etc/modprobe.d/kvm-nested.conf
options kvm-intel nested=1
options kvm-intel enable_shadow_vmcs=1
options kvm-intel enable_apicv=1
options kvm-intel ept=1
EOF

 

#重新加载KVM内核

modprobe -r kvm_intel
modprobe -a kvm_intel



#验证
cat /sys/module/kvm_intel/parameters/nested

#配置内核参数，增加arp表的缓存 【所有节点】
vim /etc/sysctl.conf

net.ipv4.neigh.default.gc_thresh1 = 1024
net.ipv4.neigh.default.gc_thresh2 = 4096
net.ipv4.neigh.default.gc_thresh3 = 8192

#上传所有安装包到/home下并解压【所有节点】
tar -zxvf kolla_config.tar.gz
tar -zxvf pip_cache.tar.gz
tar -zxvf yum_cache.tar.gz

#安装rpm包【所有节点】
cd /home/yum/x86_64/7/
yum localinstall */packages/*.rpm -y

#安装pip包【所有节点】
cd /home
pip install --no-index --find-links=pip_cache -r requirements.txt

#创建cinder-volume卷组【所有存储节点】
    
losetup

dd if=/dev/zero of=cinder.img count=1 bs=1024M
losetup /dev/loop3   /home/cinder.img
pvcreate /dev/loop3
vgcreate cinder-volumes /dev/loop3

#配置ansible【部署节点】

sed -i "s/\#pipelining = False/pipelining = True/g" /etc/ansible/ansible.cfg
sed -i "/\#forks/a forks=100" /etc/ansible/ansible.cfg

vim /etc/ansible/ansible.cfg
pipelining=True
forks=100

#配置docker服务【所有节点】
mkdir -p /etc/systemd/system/docker.service.d
vim /etc/systemd/system/docker.service.d/kolla.conf

[Service]
MountFlags=shared
ExecStart=
ExecStart=/usr/bin/dockerd --insecure-registry 172.16.100.182:5000

注:172.16.100.182:5000为docker registry 的地址，根据实际情况填写
#重启docker服务【所有节点】
systemctl daemon-reload
systemctl enable docker
systemctl restart docker

#复制gloabals.yml配置文件到/etc/下，并修改相关配置【node1节点】
cp -r /usr/share/kolla-ansible   /etc/kolla/
cp /home/globals.yml  /etc/kolla/globals.yml

#根据当前环境修改下面配置【node1节点】

vim /etc/kolla/globals.yml

#vip地址，需要该ip不能被占用，用来访问dashboard的
kolla_internal_vip_address：172.16.1.300
docker_registry: "172.16.100.182:5000"
#网卡名为管理网ip所在都网卡名
network_interface: "p1p1"
#同一网络环境下如果有多套openstack平台需要需要设置不同vroute id
keepalived_virtual_router_id：“200"

#生成kolla配置密码，修改keystone admin密码【node1节点】

cp /etc/kolla/etc_examples/kolla/passwords.yml  /etc/kolla/passwords.yml

kolla-genpwd
vim  /etc/kolla/passwords.yml
keystone_admin_password: admin

#复制配置好的gloables.yml 到/etc/kolla下，根据环境，修改下列配置  【所有节点】
cp /home/etc/kolla/globals.yml   /etc/kolla/globals.yml
vim /etc/kolla/globals.yml

kolla_internal_vip_address: "172.16.100.30"
docker_registry: "172.16.100.182:5000"
network_interface: "em1"
storage_interface: "em2"
neutron_external_interface: "em3"

#修改multinode 文件 ,根据环境来修改【node1节点】
vim  multinode

[control]
node1
node3
node2

#DVR模式要添加下面两个group
[external-compute]

[inner-compute]

#配置各组件定制配置
mkdir /etc/kolla/config/

cat /etc/kolla/config/cinder.conf

[DEFAULT]
enabled_backends = ceph
verify_glance_signatures = disabled

cinder_internal_tenant_project_id = 2374946a235642878c94d9a19d537692
cinder_internal_tenant_user_id  = ddd40f27bf8546f2bb046747f54eccfd

[ceph]
image_volume_cache_enabled = True
image_volume_cache_max_size_gb = 1024
image_volume_cache_max_count = 100
rbd_pool = cinder-sas
volume_backend_name = ceph
rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_flatten_volume_from_snapshot = true
rbd_user = cinder-sas
rbd_max_clone_depth = 5
rbd_store_chunk_size = 4
rados_connect_timeout = -1
rbd_secret_uuid = db8de0e4-104e-4676-a70f-a1450aad6524
volume_driver = cinder.volume.drivers.rbd.RBDDriver

cat global.conf   [*多Region使用]

[keystone_authtoken]
www_authenticate_uri = {{ keystone_internal_url }}
auth_url = {{ keystone_admin_url }}

cat nova.conf

[DEFAULT]

block_device_allocate_retries = 1800
block_device_allocate_retries_interval= 3

vif_plugging_timeout = 10
vif_plugging_is_fatal = False
cpu_mode = host-model
ram_allocation_ratio=1.0
reserved_host_memory_mb = 30720
config_drive_format=vfat
resize_confirm_window = 1

[placement]
auth_url = {{ keystone_admin_url }}

[neutron]
region_name=RegionNma

[libvirt]
images_type = rbd
images_rbd_pool = nova
images_rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_user = nova
rbd_secret_uuid = a2cb8ebf-447b-4386-a366-70871cbea1d6
inject_password=true
inject_partition=-1
disk_cachemodes = network=writeback

#安装检查  【node1节点】
kolla-ansible -i ./multinode prechecks

#开始安装  【node1节点】
 kolla-ansible deploy -i /home/multinode

#生成 /etc/kolla/admin-openrc.sh 文件 【node1节点】
kolla-ansible post-deploy

#复制到其他节点
scp  /etc/kolla/admin-openrc.sh  root@node2:/root
scp  /etc/kolla/admin-openrc.sh  root@node3:/root

 

############################################
对接ceph部分
############################################

#创建cinder,nova,glance池  【node1节点】
ceph osd pool create cinder  128 128
ceph osd pool create glance128 128
ceph osd pool create nova128 128

#开通cinder、nova、glance用户权限【所有节点】
ceph auth get-or-create client.cinder-sas mon 'allow *' osd 'allow class-read object_prefix rbd_children,allow rwx pool=cinder-sas' mds 'allow *' -o /etc/ceph/ceph.client.cinder-sas.keyring        
ceph auth get-or-create client.nova  mon 'allow *' osd 'allow class-read object_prefix rbd_children,allow rwx pool=nova' mds 'allow *' -o /etc/ceph/ceph.client.nova.keyring        
ceph auth get-or-create client.glance mon 'allow *' osd 'allow class-read object_prefix rbd_children,allow rwx pool=glance' mds 'allow *' -o /etc/ceph/ceph.client.glance.keyring        

#随机生成两个uuid 【node1】
uuidgen              *cinder volume 使用  
55289eba-9371-4c2a-90e8-9ff56cdae2a8
uuidgen              *nova compute使用
1d6354ba-ca27-46ff-89b3-a35329d4a02e

 

#配置cinder-volume【所有存在cinder_volume的节点】

cp /etc/ceph/ceph.client.cinder.keyring    /etc/kolla/cinder-volume/
cp /etc/ceph/ceph.conf  /etc/kolla/cinder-volume/

vim /etc/kolla/cinder-volume/cinder.conf

enabled_backends = ceph

verify_glance_signatures = disabled

#admin project id
cinder_internal_tenant_project_id = 2374946a235642878c94d9a19d537692
#admin user id
cinder_internal_tenant_user_id  = ddd40f27bf8546f2bb046747f54eccfd

[ceph]
rbd_pool = cinder
volume_backend_name = ceph
rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_flatten_volume_from_snapshot = true
rbd_user = cinder
rbd_max_clone_depth = 5
rbd_store_chunk_size = 4
rados_connect_timeout = -1
rbd_secret_uuid = db8de0e4-104e-4676-a70f-a1450aad6524
volume_driver = cinder.volume.drivers.rbd.RBDDriver
#配置镜像缓存
image_volume_cache_enabled = True
#单位GB,具体视环境空间而定
image_volume_cache_max_size_gb = 1024  
#缓存镜像数         
image_volume_cache_max_count = 100                 

#重启cinder_volume

docker restart cinder_volume

#配置glance-api   【glance_api存在节点，一般情况在node1上】

#上传并安装ceph-common.tar.gz
docker cp /home/ceph-common.tar.gz glance_api:/root
docker exec -uroot -it glance_api bash
cd /root
tar -zxvf ceph-common.tar.gz
yum localinstall -y  ./var/lib/docker/volumes/kolla_logs/_data/ceph-rpm/*
exit

cp /etc/ceph/ceph.client.glance.keyring     /etc/kolla/glance-api/
cp /etc/ceph/ceph.conf  /etc/kolla/glance-api/

vim /etc/kolla/glance-api/glance-api.conf

[glance_store]
default_store = rbd
stores = rbd
rbd_store_user = glance
rbd_store_pool = glance

vim /etc/kolla/glance-api/config.json

{
    "command": "glance-api",
    "config_files": [
        {
            "source": "/var/lib/kolla/config_files/glance-api.conf",
            "dest": "/etc/glance/glance-api.conf",
            "owner": "glance",
            "perm": "0600"
        },   
        {
            "source": "/var/lib/kolla/config_files/ceph.*",
            "dest": "/etc/ceph/",
            "owner": "glance",
            "perm": "0700"
        }    ],
    "permissions": [
        {
            "path": "/var/lib/glance",
            "owner": "glance:glance",
            "recurse": true
        },
        {
            "path": "/var/log/kolla/glance",
            "owner": "glance:glance",
            "recurse": true
        }
    ]
}

#重启glance_api服务 【glance_api存在节点】
docker restart glance_api

#配置nova-compute 【所有计算节点】

cp /etc/ceph/ceph.client.nova.keyring    /etc/kolla/nova-compute/
cp /etc/ceph/ceph.conf  /etc/kolla/nova-compute/

vim /etc/kolla/nova-compute/nova.conf

[DEFAULT]
#使用云盘方式创建vm 超时设置
block_device_allocate_retries = 1800
block_device_allocate_retries_interval= 3
#多云主机同时创建超时设置
vif_plugging_timeout = 10
vif_plugging_is_fatal = False
cpu_mode = host-model
#保留主机内存
reserved_host_memory_mb = 10240
#内存超分
ram_allocation_ratio=1.0
#调整大小确认时间，1秒后自动确认。0为禁用
resize_confirm_window = 1

 

[libvirt]

images_type = rbd
images_rbd_pool = nova
images_rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_user = nova

rbd_secret_uuid = 1d6354ba-ca27-46ff-89b3-a35329d4a02e
inject_password=true
inject_partition=-1
#指定磁盘缓存模式，ceph使用network=writeback
disk_cachemodes = network=writeback

vim /etc/kolla/nova-compute/config.json

{
    "command": "nova-compute",
    "config_files": [
        {
            "source": "/var/lib/kolla/config_files/nova.conf",
            "dest": "/etc/nova/nova.conf",
            "owner": "nova",
            "perm": "0600"
        },   
        {
            "source": "/var/lib/kolla/config_files/ceph.*",
            "dest": "/etc/ceph/",
            "owner": "nova",
            "perm": "0700"
        }    ],
    "permissions": [
        {
            "path": "/var/log/kolla/nova",
            "owner": "nova:nova",
            "recurse": true
        },
        {
            "path": "/var/lib/nova",
            "owner": "nova:nova",
            "recurse": true
        }
    ]
}

 

#配置nova-libvirt【所有计算节点】

cp /etc/ceph/ceph.conf  /etc/kolla/nova-libvirt/

vim /etc/kolla/nova-libvirt/config.json

{
    "command": "/usr/sbin/libvirtd --listen",
    "config_files": [
        {
            "source": "/var/lib/kolla/config_files/libvirtd.conf",
            "dest": "/etc/libvirt/libvirtd.conf",
            "owner": "root",
            "perm": "0600"
        },
        {
            "source": "/var/lib/kolla/config_files/qemu.conf",
            "dest": "/etc/libvirt/qemu.conf",
            "owner": "root",
            "perm": "0600"
        },   
        {
            "source": "/var/lib/kolla/config_files/ceph.conf",
            "dest": "/etc/ceph/ceph.conf",
            "owner": "root",
            "perm": "0600"
        }     ]
}

 

vim /etc/kolla/nova-libvirt/libvirtd.conf

keepalive_interval = -1

 

docker exec -uroot -it  nova_libvirt  bash

echo -e "<secret ephemeral='no' private='no'>\n<uuid>55289eba-9371-4c2a-90e8-9ff56cdae2a8</uuid>\n<usage type='ceph'>\n<name>cinder_secret</name>\n</usage>\n</secret>\n"  > /tmp/cinder.xml

echo -e "<secret ephemeral='no' private='no'>\n<uuid>1d6354ba-ca27-46ff-89b3-a35329d4a02e</uuid>\n<usage type='ceph'>\n<name>nova_secret</name>\n</usage>\n</secret>\n"  > /tmp/nova.xml

virsh secret-define --file /tmp/cinder.xml
virsh secret-define --file /tmp/nova.xml

virsh secret-set-value --secret 55289eba-9371-4c2a-90e8-9ff56cdae2a8  --base64  AQCaGz9cNoAiJBAAPvEIuEBO/RUkr1/h/XtGXQ==
virsh secret-set-value --secret 1d6354ba-ca27-46ff-89b3-a35329d4a02e  --base64 AQCoAY5c7IuVFRAAtAKiXq/0dFMO6XjNvYDtoQ==

#AQCaGz9cNoAiJBAAPvEIuEBO/RUkr1/h/XtGXQ== 为client.cinder的id,通过cat /etc/ceph/ceph.client.cinder.keyring 查看
#AQCoAY5c7IuVFRAAtAKiXq/0dFMO6XjNvYDtoQ==为client.nova 的id,通过cat /etc/ceph/ceph.client.nova.keyring 查看

#最终生成下面两个文件
/etc/libvirt/secrets/55289eba-9371-4c2a-90e8-9ff56cdae2a8.base64
/etc/libvirt/secrets/55289eba-9371-4c2a-90e8-9ff56cdae2a8.xml
/etc/libvirt/secrets/1d6354ba-ca27-46ff-89b3-a35329d4a02e.base64
/etc/libvirt/secrets/1d6354ba-ca27-46ff-89b3-a35329d4a02e.xml

crtl+p+q 退出容器

#重启nova_libvirt服务 【所有计算节点】
docker restart nova_libvirt

#重启nova_compute服务 【所有计算节点】
docker restart nova_compute

#修改policy
docker exec -uroot -it neutron_server bash

vi /etc/neutron/policy.json

把policy、port相关的全部注释掉

# "create_policy": "rule:admin_only",

# "get_policy": "rule:regular_user",

# "update_policy": "rule:admin_only",

# "delete_policy": "rule:admin_only",

# "create_port": "",

........

 

 

##############################################
配置neutron，需要根据具体网络情况来配置
##############################################
下面使用em3 ，em4作为租户网网卡，模式均为vlan,【所有节点】

docker exec -uroot -it  openvswitch_vswitchd bash

ovs-vsctl add-br br-em3
ovs-vsctl add-br br-em4
ovs-vsctl add-port br-em3 em3
ovs-vsctl add-port br-em4 em4

vim /etc/kolla/neutron-openvswitch-agent/ml2_conf.ini

type_drivers = flat,vlan,vxlan
tenant_network_types = vlan

network_vlan_ranges = default:1000:2000,vlan1:300:300

[ovs]
bridge_mappings = default:br-p1p2,vlan1:br-bond1
datapath_type = system
ovsdb_connection = tcp:127.0.0.1:6640
#如果不适用vxlan模式，则这里直接填写管理网ip
local_ip = 172.16.1.140

docker restart  neutron_openvswitch_agent
使用docker restart 命令 重启 neutron_openvswitch_agent服务

 

#配置dhcp 租期为无限期

vim /etc/kolla/neutron-dhcp-agent/neutron.conf

[DEFAULT]

dhcp_lease_duration=-1

##############################################
evacuat
##############################################

#配置config drive

vim /etc/kolla/nova-compute/nova.conf

force_config_drive = true
config_drive_format=vfat

#配置dashboard 显示cloudkitty

vim  /etc/kolla/horizon/local_settings

OPENSTACK_KEYSTONE_URL = "http://172.16.100.30:5000/v3"

 

#配置cloudkittyprocessor 正常使用
*所有需要cloudkitty管理的project都需要在这里添加，如project 为demo，则下面--project为demo

openstack role add --project admin --user cloudkitty rating

 

#在现有环境中增加节点

前面正常配置.然后修改multinode 文件
vim multinode

[compute]
node1
node3
node2
node4
node5

然后执行
kolla-ansible deploy -i ./multinode --limit node4
kolla-ansible deploy -i ./multinode --limit node5

 

#虚拟机控制台修改为域名模式【所有计算节点】
vim /etc/kolla/nova-compute/nova.conf
novncproxy_base_url = http://iaas.fushionabc.com:6080/vnc_auto.html

#vm_monitor 启动
docker run -d -v /etc/hosts:/etc/hosts --name vm_monitor -p 9183:9183 --restart=always vm_monitorsapp:v1.0

#虚拟机evacuate时socket closed 导致疏散失败的解决方式

vim /etc/kolla/nova-libvirt/libvirtd.conf

keepalive_interval = -1

 

 

 

 

其他相关命令：

使用root权限进入容器内部
docker exec -uroot -it 1cfcf4b8daf6 bash

查看docker启动日志
docker logs 1cfcf4b8daf6

查看cinder_volume服务日志
less  /var/lib/docker/volumes/kolla_logs/_data/cinder-volume.log

单组件部署
kolla-ansible -i ./multinode deploy  -t  swift

单节点部署

kolla-ansible -i ./multinode deploy --limit node5

如果执行失败执行destroy操作
kolla-ansible destroy  -i ./multinode deploy  --yes-i-really-really-mean-it

#多vm使用不同镜像，选择创建新卷创建时候如果镜像过大导致cinder所在的物理机磁盘不够的时候 会失败

 

 

 

参考：http://www.cnblogs.com/yue-hong/p/7029216.html
```

 




