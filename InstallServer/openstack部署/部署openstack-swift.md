### 部署openstack-swift



```bash
部署准备：

存储节点：192.168.0.2 192.168.0.3 192.168.0.4
三块磁盘：sdc, sdd, sde  

部署开始



磁盘分区表    

# <WARNING ALL DATA ON DISK will be LOST!>

index=0
for d in sdc sdd sde; do

# 注意：lable->KOLLA_SWIFT_DATA ，kolla部署用于这个标签识别

​    parted /dev/${d} -s -- mklabel gpt mkpart KOLLA_SWIFT_DATA 1 -1
​    sudo mkfs.xfs -f -L d${index} /dev/${d}1
​    (( index++ ))
done

生成 rings  

STORAGE_NODES=(192.168.0.2 192.168.0.3 192.168.0.4)
KOLLA_SWIFT_BASE_IMAGE="10.252.6.12:5555/centos-source-swift-base:rocky"

mkdir -p /etc/kolla/config/swift

# Object ring

docker run \
  --rm \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
  $KOLLA_SWIFT_BASE_IMAGE \
  swift-ring-builder \
    /etc/kolla/config/swift/object.builder create 10 3 1

for node in ${STORAGE_NODES[@]}; do
    for i in {0..2}; do
      docker run \
        --rm \
        -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
        $KOLLA_SWIFT_BASE_IMAGE \
        swift-ring-builder \
          /etc/kolla/config/swift/object.builder add r1z1-${node}:6000/d${i} 1;
    done
done

# Account ring

docker run \
  --rm \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
  $KOLLA_SWIFT_BASE_IMAGE \
  swift-ring-builder \
    /etc/kolla/config/swift/account.builder create 10 3 1

for node in ${STORAGE_NODES[@]}; do
    for i in {0..2}; do
      docker run \
        --rm \
        -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
        $KOLLA_SWIFT_BASE_IMAGE \
        swift-ring-builder \
          /etc/kolla/config/swift/account.builder add r1z1-${node}:6001/d${i} 1;
    done
done

# Container ring

docker run \
  --rm \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
  $KOLLA_SWIFT_BASE_IMAGE \
  swift-ring-builder \
    /etc/kolla/config/swift/container.builder create 10 3 1

for node in ${STORAGE_NODES[@]}; do
    for i in {0..2}; do
      docker run \
        --rm \
        -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
        $KOLLA_SWIFT_BASE_IMAGE \
        swift-ring-builder \
          /etc/kolla/config/swift/container.builder add r1z1-${node}:6002/d${i} 1;
    done
done

for ring in object account container; do
  docker run \
    --rm \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
    $KOLLA_SWIFT_BASE_IMAGE \
    swift-ring-builder \
      /etc/kolla/config/swift/${ring}.builder rebalance;
done

kolla 中启用swift
在/etc/kolla/globals.yml中启用swift  

enable_swift : "yes"

修改swift.conf模板配置文件，添加max_header_size=32768  

vim /usr/share/kolla-ansible/ansible/roles/swift/templates/swift.conf.j2
[swift-constraints]
max_header_size=32768

修改proxy_server.conf模板,添加member角色

vim /usr/share/kolla-ansible/ansible/roles/swift/templates/proxy-server.conf.j2

[filter:authtoken]
auth_uri = {{ internal_protocol }}://10.252.0.100:{{ keystone_public_port }}
auth_url = {{ admin_protocol }}://10.252.0.100:{{ keystone_admin_port }}

[filter:keystoneauth]
use = egg:swift#keystoneauth
operator_roles = admin,{{ keystone_default_user_role }},ResellerAdmin,member

查看rings生成后，用Kolla Ansible部署服务
确认multinode配置文件中部署的节点后，执行如下命令部署  

kolla-ansible deploy -i ./multinode  -t swift



部署结束，开始验证部署



验证  

$ swift stat
                          Account: AUTH_4c19d363b9cf432a80e34f06b1fa5749
                     Containers: 1
                        Objects: 0
                          Bytes: 0
Containers in policy "policy-0": 1
   Objects in policy "policy-0": 0
     Bytes in policy "policy-0": 0
    X-Account-Project-Domain-Id: default
                    X-Timestamp: 1440168098.28319
                     X-Trans-Id: txf5a62b7d7fc541f087703-0055d73be7
                   Content-Type: text/plain; charset=utf-8
                  Accept-Ranges: bytes

$ swift upload mycontainer README.rst
README.md

$ swift list
mycontainer

$ swift download mycontainer README.md
README.md [auth 0.248s, headers 0.939s, total 0.939s, 0.006 MB/s]



部署遇到的问题

swiftclient:RESP STATUS: 400 Header Line Too Long
描述：默认，用kolla-ansible部署完swift，在验证swift的时候会出现： 400 Header Line Too Long
shell
swiftclient:RESP STATUS: 400 Header Line Too Long

解决方案：在每个swift.conf文件添加[swift-constraints] max_header_size=32768
修改线上节点脚本

for sf in $(find /etc/kolla/swift-* -name  swift.conf);do  cat >>${sf}<<EOF  
[swift-constraints]
max_header_size=32768
EOF
done

for i in $(docker ps |grep swift |awk '{print $1}');do docker restart $i ; done

备份显示403 禁止访问
描述： 这个问题是由于funsionabc创建的用户都是属于member角色，所以在配置文件中要添加member



[root@controller3 ~]# cat /etc/kolla/swift-proxy-server/proxy-server.conf |grep role
operator_roles = admin,_member_,ResellerAdmin,member
```

