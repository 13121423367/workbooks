# openstack网络及硬盘qos设置

> 说明：qos意为 `服务质量`，即通过一定的使用限制措施，从而保证集群整体服务的稳定和质量
>
> **已挂载硬盘设置硬盘类型需要先分离！！**

### 一、网络qos设置

#### 1.1 修改Neutron配置文件，使其支持Qos

```bash
#修改Neutron.conf
service_plugins = neutron.services.qos.qos_plugin.QoSPlugin

#修改plugins/ml2/ml2_conf.ini
[ml2]
extension_drivers=qos

[agent]
extensions=qos
```

#### 1.2 重启neutron服务

```bash 
systemctl restart neutron-server.service neutron-linuxbridge-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service
```

#### 1.3 创建一个policy

```bash 
#创建网络qos，名称为test
openstack network qos policy create test
```

#### 1.4 添加限速rule

```bash
#设置规则
openstack network qos rule create b67368e8-187b-4777-822c-1af3ed59a59e --max-kbps 20480 --max-burst-kbits 30720 --type bandwidth-limit

#参数说明
  --max-kbps: 最大速度
  --max-burst-kbits: 最大突发流量
  --type: 限制类型 #带宽 bandwidth-limit
```

#### 1.5 绑定Port

```bash
#根据云主机查找port id
openstack port list --server SERVERID

#给端口设置qos,格式：openstack port set  --qos-policy QOS_ID  PORT_ID
openstack port set  --qos-policy b67368e8-187b-4777-822c-1af3ed59a59e 32873801-a55c-4656-8147-0dd1b576d75a
```

#### 1.6 绑定Network

```bash
#绑定整个网络
neutron net-update network_id --qos-policy qos_id
```

#### 1.7 取消绑定

```bash
openstack port unset --qos-policy port_id
```



### 二、硬盘qos设置

#### 1.1 检查硬盘是否设置过qos

 ```bash
#查看当前租户下所有云主机,以dadimanager，获取主机ID
openstack server list --project dadimanager

#通过云主机ID获取磁盘关联，以ID fdadda58-f9b7-4274-8d10-e58de1514b5b 为例，获取volume ID 
nova volume-attachments fdadda58-f9b7-4274-8d10-e58de1514b5b
+--------------------------------------+----------+--------------------------------------+--------------------------------------+
| ID                                   | DEVICE   | SERVER ID                            | VOLUME ID                            |
+--------------------------------------+----------+--------------------------------------+--------------------------------------+
| 9c155930-5c34-4601-acce-8cdf3580dfa3 | /dev/vda | fdadda58-f9b7-4274-8d10-e58de1514b5b | 9c155930-5c34-4601-acce-8cdf3580dfa3 |
| d38abfb1-bf88-4c51-9217-b66e41cb9766 | /dev/vdb | fdadda58-f9b7-4274-8d10-e58de1514b5b | d38abfb1-bf88-4c51-9217-b66e41cb9766 |
+--------------------------------------+----------+--------------------------------------+--------------------------------------+

#查看volume type
 openstack volume show 9c155930-5c34-4601-acce-8cdf3580dfa3 -c type
 
#如果type为none，则volume 未设置限速
 ```

#### 1.2 设置qos

```bash
#创建qos规则
cinder qos-create ceph-ssd-qos consumer=front-end read_bytes_sec=157286400  write_bytes_sec=157286400  read_iops_sec=1500  write_iops_sec=1500

#创建卷类型
cinder type-create ceph-ssd

#绑定存储后端，对应cinder.conf里的volume_backend_name=ceph
cinder type-key ceph-ssd set volume_backend_name=ceph

#查看卷类型
cinder type-list

#查看Qos
cinder qos-list

#将卷类型和qos绑定
cinder qos-associate QOS_ID TYPE_ID

#绑定 绑定了qos的卷类型 到硬盘
openstack volume set --type TYPE_ID
```

`创建qos可选参数及说明:`

- **total_bytes_sec：** 顺序读写总带宽上限

- **read_bytes_sec：** 顺序读带宽上限

- **write_bytes_sec：** 顺序写带宽上限

- **total_iops_sec：** 随机读写总IOPS上限

- **read_iops_sec：** 随机读IOPS上限

- **write_iops_sec：** 随机写IOPS上限

