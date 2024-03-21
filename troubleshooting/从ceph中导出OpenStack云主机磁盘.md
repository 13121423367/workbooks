### 脚本内容

```bash
[root@controller1 crontab]# cat ceph_export_disk.sh
#!/bin/bash

# 加载环境变量
source /root/admin-openrc.sh

SERVER=b6aa0f11-b8e3-4e9f-a23a-f081abd880d6

# 查看云主机volume列表，放到for循环中
for DISK in `openstack server show -f value -c volumes_attached $SERVER | awk -F \' '{print $2}'`
do
	echo -e '\n\t查看卷快照列表，带时间\n'
	rbd snap ls cinder-sas/volume-$DISK
	echo -e '\n\t查看卷快照列表，带大小\n'
	rbd du --image cinder-sas/volume-$DISK
	echo '---------------------------------------------------------------------------------------------------------------'
done

echo -e '\n\t导出快照的命令\n'
echo "rbd export --snap volume-xxxxx@snapshot-xxxxx  sys.qcow2"
echo "rbd export --snap volume-xxxxx@snapshot-xxxxx data.qcow2"
echo -e '\n\t导出卷的命令\n'
echo "rbd export --image volume-xxxxx  sys.qcow2"
echo "rbd export --image volume-xxxxx data.qcow2"

echo -e "\n\t注意不要在控制节点执行导出命令，找一个不重要且空间够的计算节点操作\n"
```

###  执行结果

```bash
[root@controller1 crontab]# sh ceph_export_disk.sh

	查看卷快照列表，带时间

SNAPID NAME                                            SIZE TIMESTAMP                
604768 snapshot-80ea3664-3811-40f0-b424-fa97bae0a3af 50 GiB Sat Oct  9 16:11:34 2021 
623474 snapshot-e8e40b64-7e49-4ae8-ab79-3b539493440d 50 GiB Sat Oct 16 16:13:04 2021 
642347 snapshot-960d91cc-b40f-4b1e-8d10-e4dae1889cee 50 GiB Sat Oct 23 16:15:26 2021 
647747 snapshot-4a5bb1e5-fb72-491a-9709-932f305c2239 50 GiB Mon Oct 25 16:14:12 2021 
650489 snapshot-8157da73-5676-4a8f-924a-22fe81eb9d79 50 GiB Tue Oct 26 16:16:22 2021 
653199 snapshot-5ba20280-bd84-43d9-b38b-a86c5e1c81cb 50 GiB Wed Oct 27 16:16:41 2021 

	查看卷快照列表，带大小

NAME                                                                                      PROVISIONED    USED 
volume-93c11f71-f684-4329-bb30-2031a0bf88f4@snapshot-80ea3664-3811-40f0-b424-fa97bae0a3af      50 GiB  11 GiB 
volume-93c11f71-f684-4329-bb30-2031a0bf88f4@snapshot-e8e40b64-7e49-4ae8-ab79-3b539493440d      50 GiB 1.2 GiB 
volume-93c11f71-f684-4329-bb30-2031a0bf88f4@snapshot-960d91cc-b40f-4b1e-8d10-e4dae1889cee      50 GiB 884 MiB 
volume-93c11f71-f684-4329-bb30-2031a0bf88f4@snapshot-4a5bb1e5-fb72-491a-9709-932f305c2239      50 GiB 580 MiB 
volume-93c11f71-f684-4329-bb30-2031a0bf88f4@snapshot-8157da73-5676-4a8f-924a-22fe81eb9d79      50 GiB 716 MiB 
volume-93c11f71-f684-4329-bb30-2031a0bf88f4@snapshot-5ba20280-bd84-43d9-b38b-a86c5e1c81cb      50 GiB 604 MiB 
volume-93c11f71-f684-4329-bb30-2031a0bf88f4                                                    50 GiB 592 MiB 
<TOTAL>                                                                                        50 GiB  15 GiB 
---------------------------------------------------------------------------------------------------------------

	查看卷快照列表，带时间

SNAPID NAME                                             SIZE TIMESTAMP                
604767 snapshot-258e1548-f860-4c22-9ab9-96946689b2ff 150 GiB Sat Oct  9 16:11:34 2021 
623475 snapshot-40114cbb-e0cf-483b-8aea-9e017a492a7d 150 GiB Sat Oct 16 16:13:04 2021 
642346 snapshot-fe197969-ba7e-408d-80aa-27cc9666bc15 150 GiB Sat Oct 23 16:15:25 2021 
647746 snapshot-dbd45251-5538-4970-8804-c36d0419b403 150 GiB Mon Oct 25 16:14:12 2021 
650488 snapshot-b035b015-764c-4679-baa2-e4fd9a43286c 150 GiB Tue Oct 26 16:16:22 2021 
653200 snapshot-00937845-0b4c-4817-a5ae-9ab231d7412e 150 GiB Wed Oct 27 16:16:42 2021 

	查看卷快照列表，带大小

NAME                                                                                      PROVISIONED    USED 
volume-1022265b-23cb-457e-b716-1a2a46244367@snapshot-258e1548-f860-4c22-9ab9-96946689b2ff     150 GiB 109 GiB 
volume-1022265b-23cb-457e-b716-1a2a46244367@snapshot-40114cbb-e0cf-483b-8aea-9e017a492a7d     150 GiB 9.0 GiB 
volume-1022265b-23cb-457e-b716-1a2a46244367@snapshot-fe197969-ba7e-408d-80aa-27cc9666bc15     150 GiB 8.8 GiB 
volume-1022265b-23cb-457e-b716-1a2a46244367@snapshot-dbd45251-5538-4970-8804-c36d0419b403     150 GiB 6.7 GiB 
volume-1022265b-23cb-457e-b716-1a2a46244367@snapshot-b035b015-764c-4679-baa2-e4fd9a43286c     150 GiB 7.9 GiB 
volume-1022265b-23cb-457e-b716-1a2a46244367@snapshot-00937845-0b4c-4817-a5ae-9ab231d7412e     150 GiB 7.0 GiB 
volume-1022265b-23cb-457e-b716-1a2a46244367                                                   150 GiB 6.4 GiB 
<TOTAL>                                                                                       150 GiB 155 GiB 
---------------------------------------------------------------------------------------------------------------

	导出快照的命令，一般选最后一个快照

rbd export --snap volume-xxxxx@snapshot-xxxxx  sys.qcow2
rbd export --snap volume-xxxxx@snapshot-xxxxx data.qcow2

	导出卷的命令

rbd export --image volume-xxxxx  sys.qcow2
rbd export --image volume-xxxxx data.qcow2

	注意不要在控制节点执行导出命令，找一个不重要且空间够的计算节点操作

```