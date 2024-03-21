##### 1. 查找对应的`OS-EXT-SRV-ATTR:host` 和`OS-EXT-SRV-ATTR:instance_name`
```
openstack server show ID -f json  | grep 'OS-EXT-SRV-ATTR'
```



##### 2. 对目标虚机执行断电操作

```
ssh computexx docker exec nova_libvirt virsh destroy instance_name
```



##### 3. 重设虚机状态

```
nova reset-state ID  --active
```



##### 4. 关闭虚机

```
nova stop ID
```



##### 5. 迁移虚机（已关机，这里是冷迁）

```
nova migrate ID
```



##### 6. 迁移完成后开机

```
nova start ID
```



##### 7. 检查主机网络 

```
ping XXX
```
