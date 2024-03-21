## 虚机绑定VIP

**根据虚机的IP地址查看关联的端口ID**
```shell
openstack port list --fixed-ip ip-address=10.122.67.140
```
**根据端口ID查看绑定情况**

```shell
openstack port show ccbe9802-cbc3-4c40-93f9-09ea3bc6b885（端口ID）
```
**绑定VIP**

```shell
openstack port set --allowed-address ip-address=10.122.67.19 ccbe9802-cbc3-4c40-93f9-09ea3bc6b885
# ip-address=  需要绑定的 VIP 地址
# ccbe9802-cbc3-4c40-93f9-09ea3bc6b885	端口ID
```

**查看虚机的信息**

```shell
# 查询实例ID
openstack server list --ip 10.122.67.140 --all-projects
# 根据实例ID查询虚机详细信息
openstack server show 0485f086-d4ed-4e5b-bf61-47f9066a9ae1
```

