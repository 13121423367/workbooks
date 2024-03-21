## 北研迁移zabbix处理手册



### windows OS

下载并解压 `http://10.122.49.186/lenovo_zabbix_agent_packages/zabbix4_autoinstall_win.zip`

**脚本名称:	`modify_server_ip.bat`**

1、将脚本放置到C:\zabbix4_autoinstall_win，以管理员身份运行powershell 如下命令

```powershell
# 更改配置文件
C:\zabbix4_autoinstall_win\modify_server_ip.bat Windows-HETO1-PRD
C:\zabbix4_autoinstall_win\modify_server_ip.bat Windows-VA32O1-PRD
# 查看windows 操作系统信息
(Get-WmiObject Win32_OperatingSystem).Caption
```

**脚本名称:`zabbix_install_deploy.bat`**

```powershell
# 停止
C:\zabbix_agents\bin\zabbix_agentd.exe -c C:\zabbix_agents\conf\zabbix_agentd.conf -d
# 卸载
C:\zabbix4_autoinstall_win\uninstall.bat
#安装
C:\zabbix4_autoinstall_win\zabbix_install_deploy.bat Windows-HETO1-PRD
```

**重启服务**

![image-20230808091936434](D:\Desktop\lenovo\工作技术文档\markdown-img\zabbix安装.assets\image-20230808091936434.png)

------

### Linux OS

#### install

1、如果是镜像模板交付的虚机，那么只需跑一下脚本即可

```bash
bash /usr/local/zabbix_agents/modifyConfig/modify_server_ip.sh Linux-HETO1-PRD

#modify_server_ip.sh	路径下有存在这个脚本
#Linux-HETO1-PRD		$1 参数， Linux 为操作系统  HET为内蒙城市 PRD为生产
```

2、如果是一台没有安装zabbix的服务器或者zabbix已经卸载重新安装的情况，需要先安装zabbix的rpm包，然后再跑一下配置脚本；

**rpm包说明如下：**

```bash
Centos6/Redhat6/Oracle Linux6：
rpm -ivh http://10.122.49.186/lenovo_zabbix_agent_packages/zabbix-agent-for-lenovo-4.0.5-1.el6.x86_64.rpm

Centos7/Redhat7/Oracle Linux7:
rpm -ivh http://10.122.49.186/lenovo_zabbix_agent_packages/zabbix-agent-for-lenovo-4.0.5-1.el7.x86_64.rpm

SUSE11:
rpm -ivh http://10.122.49.186/lenovo_zabbix_agent_packages/zabbix-agent-for-lenovo-4.0.5-1.sle11.x86_64.rpm
SUSE12:
rpm -ivh http://10.122.49.186/lenovo_zabbix_agent_packages/zabbix-agent-for-lenovo-4.0.5-1.sle12.x86_64.rpm
 
Redhat 8:
rpm -ivh http://10.122.49.186/lenovo_zabbix_agent_packages/zabbix-agent-for-lenovo-4.0.5-1.el8.x86_64.rpm
 
SUSE 15:
rpm -ivh http://10.122.49.186/lenovo_zabbix_agent_packages/zabbix-agent-for-lenovo-4.0.5-1.sle15.x86_64.rpm
```

安装完成后执行修改配置脚本

```shell
bash /usr/local/zabbix_agents/modifyConfig/modify_server_ip.sh Linux-SHEO2-TST
```

查看Zabbix-agent配置文件

```shell
grep -vE "^#|^$" /usr/local/zabbix_agents/etc/zabbix_agentd.conf
```

#### uninstall

1、查看进程状态

```shell
netstat -utpln |grep 10050
ps -ef |grep zabbix
```

2、关闭zabbix进程

```shell
ps -ef |grep zabbix |awk '!/grep/ {print $2}'|xargs kill -9
```

3、卸载zabbix

```shell
rpm -qa |grep zabbix |xargs rpm -e
```



### 报错排查

**1、监控收取不到zabbix-agent提供的信息**

```shell
可能是在执行脚本的时候$1参数输入错误，查看配置文件验证
grep -vE "^#|^$" /usr/local/zabbix_agents/etc/zabbix_agentd.conf
```

**2、安装时错误**

```shell
可能是rpm安装时选择了错误的rpm包导致，检查操作系统输入，根据操作系统来下载不同的URL
source /etc/os-release && echo $ID
awk '{print $1}' /etc/redhat-release
cat /etc/oracle-release 
cat /etc/debian_version
```

**3、日后补充**