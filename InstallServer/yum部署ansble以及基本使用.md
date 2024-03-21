# yum部署ansble以及基本使用



**ansible：是自动化运维工具，基于Python开发，实现批量系统设置、批量程序部署、批量执行命令等功能。其中，批量部署是立身于ansible的模块进行工作的**







### 基础环境准备

| 主机            | 角色   | 软件    |
| --------------- | ------ | ------- |
| 192.168.162.128 | master | ansible |
| 192.168.162.129 | node   |         |
| 192.168.162.130 | node   |         |

1）防火墙、Selinux禁用、禁用swap交换分区

```shell
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
swapoff -a 
```

2）备份原有yum源安装阿里源和epel源

```shell
mkdir Centos-base.bak && mv ./* Centos-base.bak/
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

```

### ansible安装

```shell
yum -y install ansible			##安装

whereis ansible					##查看ansible的安装路径
ansible: /usr/bin/ansible /etc/ansible /usr/share/ansible /usr/share/man/man1/ansible.1.gz

ansible --version				##查看ansible的版本
ansible 2.9.27
  config file = /etc/ansible/ansible.cfg
  configured module search path = [u'/root/.ansible/plugins/modules', u'/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python2.7/site-packages/ansible
  executable location = /usr/bin/ansible
  python version = 2.7.5 (default, Aug  7 2019, 00:51:29) [GCC 4.8.5 20150623 (Red Hat 4.8.5-39)]
```



修改hosts配置,创建ssh密钥

```
vim hosts			### 修改hosts文件 
192.168.162.129		### 在文件的最后添加上你想控制的机器的ip
192.168.162.130

ssh-keygen
ssh-copy-id 192.168.162.129
ssh-copy-id 192.168.162.130

ansible -m ping all
192.168.162.129 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": false, 
    "ping": "pong"
}
192.168.162.130 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": false, 
    "ping": "pong"
}
```







### ansible 基础命令使用

```
ansible 192.168.162.129 -m setup |grep vcpus		##查看192.168.162.129cpu个数
        "ansible_processor_vcpus": 1, 
ansible all -m setup |grep vcpus					##查看all主机cpu个数
        "ansible_processor_vcpus": 1, 
        "ansible_processor_vcpus": 1,
```





```shell
#command模块
#不支持`$ `"<"', `">"', `"|"',`";"' and `"&"'；有这些符号需用shell模块
语法：  ansible <host-pattern> [-m module_name] [-a args] [options

ansible all -m command -a  'useradd test'					#批量添加用户
192.168.162.130 | CHANGED | rc=0 >>

192.168.162.129 | CHANGED | rc=0 >>
```



```shell
#shell模块：
ansible all -m shell -a 'echo "123456" |passwd --stdin test'	#批量给用户设置密码
192.168.162.130 | CHANGED | rc=0 >>
Changing password for user test.
passwd: all authentication tokens updated successfully.
192.168.162.129 | CHANGED | rc=0 >>
Changing password for user test.
passwd: all authentication tokens updated successfully.
```



```shell
 #copy模块：
ansible all -m copy -a 'src=~/1.txt dest=/tmp/ backup=yes mode=0644 owner=test'
#src：源文件所在路径；
#owner文件的属主；group文件的属组，属主属组必须存在
#dest:目的地路径；mode文件的权限，backup是否备份

192.168.162.130 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": true, 
    "checksum": "22596363b3de40b06f981fb85d82312e8c0ed511", 
    "dest": "/tmp/1.txt", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "6f5902ac237024bdd0c176cb93063dc4", 
    "mode": "0644", 
    "owner": "test", 
    "size": 12, 
    "src": "/root/.ansible/tmp/ansible-tmp-1648737774.97-58033-186522222233297/source", 
    "state": "file", 
    "uid": 1001
}
192.168.162.129 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": true, 
    "checksum": "22596363b3de40b06f981fb85d82312e8c0ed511", 
    "dest": "/tmp/1.txt", 
    "gid": 0, 
    "group": "root", 
    "md5sum": "6f5902ac237024bdd0c176cb93063dc4", 
    "mode": "0644", 
    "owner": "test", 
    "size": 12, 
    "src": "/root/.ansible/tmp/ansible-tmp-1648737775.0-58032-204842734608145/source", 
    "state": "file", 
    "uid": 1001
}
```





```shell
#fetch模块：
fetch模块和copy模块区别在于 fetch是去拿节点上的东西，copy是复制给节点

ansible all -m fetch -a 'src=/tmp/1.txt dest=/tmp/'
#将节点上/tmp/1.tex 复制到本机上的tmp目录下

192.168.162.130 | CHANGED => {
    "changed": true, 
    "checksum": "22596363b3de40b06f981fb85d82312e8c0ed511", 
    "dest": "/tmp/192.168.162.130/tmp/1.txt", 
    "md5sum": "6f5902ac237024bdd0c176cb93063dc4", 
    "remote_checksum": "22596363b3de40b06f981fb85d82312e8c0ed511", 
    "remote_md5sum": null
}
192.168.162.129 | CHANGED => {
    "changed": true, 
    "checksum": "22596363b3de40b06f981fb85d82312e8c0ed511", 
    "dest": "/tmp/192.168.162.129/tmp/1.txt", 
    "md5sum": "6f5902ac237024bdd0c176cb93063dc4", 
    "remote_checksum": "22596363b3de40b06f981fb85d82312e8c0ed511", 
    "remote_md5sum": null
}

ls /tmp/
192.168.162.129        192.168.162.130
```



```shell
#yum模块
#批量安装Nginx
ansible all -m yum -a 'name=nginx state=latest'

192.168.162.129 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": true, 
    "changes": {
        "installed": [
            "nginx"
        ], 
        "updated": []
    }, 
    "msg": "", 
    "obsoletes": {
        "iwl7265-firmware": {
            "dist": "noarch", 
            "repo": "@anaconda", 
            "version": "22.0.7.0-72.el7"
        }, 
        "webkitgtk4-plugin-process-gtk2": {
            "dist": "x86_64", 
            "repo": "@anaconda", 
            "version": "2.22.7-2.el7"
        }
    }, 
    "rc": 0, 
    "results": [
        "Loaded plugins: fastestmirror, langpacks\nLoading mirror speeds from cached hostfile\n * base: mirrors.aliyun.com\n * extras: mirrors.aliyun.com\n * updates: mirrors.aliyun.com\nResolving Dependencies\n--> Running transaction check\n---> Package nginx.x86_64 1:1.20.1-9.el7 will be installed\n--> Processing Dependency: nginx-filesystem = 1:1.20.1-9.el7 for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Processing Dependency: libcrypto.so.1.1(OPENSSL_1_1_0)(64bit) for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Processing Dependency: libssl.so.1.1(OPENSSL_1_1_0)(64bit) for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Processing Dependency: libssl.so.1.1(OPENSSL_1_1_1)(64bit) for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Processing Dependency: nginx-filesystem for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Processing Dependency: libcrypto.so.1.1()(64bit) for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Processing Dependency: libssl.so.1.1()(64bit) for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Running transaction check\n---> Package nginx-filesystem.noarch 1:1.20.1-9.el7 will be installed\n---> Package openssl11-libs.x86_64 1:1.1.1k-2.el7 will be installed\n--> Finished Dependency Resolution\n\nDependencies Resolved\n\n================================================================================\n Package                 Arch          Version                Repository   Size\n================================================================================\nInstalling:\n nginx                   x86_64        1:1.20.1-9.el7         epel        587 k\nInstalling for dependencies:\n nginx-filesystem        noarch        1:1.20.1-9.el7         epel         24 k\n openssl11-libs          x86_64        1:1.1.1k-2.el7         epel        1.5 M\n\nTransaction Summary\n================================================================================\nInstall  1 Package (+2 Dependent packages)\n\nTotal download size: 2.1 M\nInstalled size: 5.2 M\nDownloading packages:\n--------------------------------------------------------------------------------\nTotal                                              1.5 MB/s | 2.1 MB  00:01     \nRunning transaction check\nRunning transaction test\nTransaction test succeeded\nRunning transaction\n  Installing : 1:openssl11-libs-1.1.1k-2.el7.x86_64                         1/3 \n  Installing : 1:nginx-filesystem-1.20.1-9.el7.noarch                       2/3 \n  Installing : 1:nginx-1.20.1-9.el7.x86_64                                  3/3 \n  Verifying  : 1:nginx-filesystem-1.20.1-9.el7.noarch                       1/3 \n  Verifying  : 1:openssl11-libs-1.1.1k-2.el7.x86_64                         2/3 \n  Verifying  : 1:nginx-1.20.1-9.el7.x86_64                                  3/3 \n\nInstalled:\n  nginx.x86_64 1:1.20.1-9.el7                                                   \n\nDependency Installed:\n  nginx-filesystem.noarch 1:1.20.1-9.el7  openssl11-libs.x86_64 1:1.1.1k-2.el7 \n\nComplete!\n"
    ]
}
192.168.162.130 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": true, 
    "changes": {
        "installed": [
            "nginx"
        ], 
        "updated": []
    }, 
    "msg": "", 
    "obsoletes": {
        "iwl7265-firmware": {
            "dist": "noarch", 
            "repo": "@anaconda", 
            "version": "22.0.7.0-72.el7"
        }, 
        "webkitgtk4-plugin-process-gtk2": {
            "dist": "x86_64", 
            "repo": "@anaconda", 
            "version": "2.22.7-2.el7"
        }
    }, 
    "rc": 0, 
    "results": [
        "Loaded plugins: fastestmirror, langpacks\nLoading mirror speeds from cached hostfile\n * base: mirrors.aliyun.com\n * extras: mirrors.aliyun.com\n * updates: mirrors.aliyun.com\nResolving Dependencies\n--> Running transaction check\n---> Package nginx.x86_64 1:1.20.1-9.el7 will be installed\n--> Processing Dependency: nginx-filesystem = 1:1.20.1-9.el7 for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Processing Dependency: libcrypto.so.1.1(OPENSSL_1_1_0)(64bit) for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Processing Dependency: libssl.so.1.1(OPENSSL_1_1_0)(64bit) for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Processing Dependency: libssl.so.1.1(OPENSSL_1_1_1)(64bit) for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Processing Dependency: nginx-filesystem for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Processing Dependency: libcrypto.so.1.1()(64bit) for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Processing Dependency: libssl.so.1.1()(64bit) for package: 1:nginx-1.20.1-9.el7.x86_64\n--> Running transaction check\n---> Package nginx-filesystem.noarch 1:1.20.1-9.el7 will be installed\n---> Package openssl11-libs.x86_64 1:1.1.1k-2.el7 will be installed\n--> Finished Dependency Resolution\n\nDependencies Resolved\n\n================================================================================\n Package                 Arch          Version                Repository   Size\n================================================================================\nInstalling:\n nginx                   x86_64        1:1.20.1-9.el7         epel        587 k\nInstalling for dependencies:\n nginx-filesystem        noarch        1:1.20.1-9.el7         epel         24 k\n openssl11-libs          x86_64        1:1.1.1k-2.el7         epel        1.5 M\n\nTransaction Summary\n================================================================================\nInstall  1 Package (+2 Dependent packages)\n\nTotal download size: 2.1 M\nInstalled size: 5.2 M\nDownloading packages:\n--------------------------------------------------------------------------------\nTotal                                              1.2 MB/s | 2.1 MB  00:01     \nRunning transaction check\nRunning transaction test\nTransaction test succeeded\nRunning transaction\n  Installing : 1:openssl11-libs-1.1.1k-2.el7.x86_64                         1/3 \n  Installing : 1:nginx-filesystem-1.20.1-9.el7.noarch                       2/3 \n  Installing : 1:nginx-1.20.1-9.el7.x86_64                                  3/3 \n  Verifying  : 1:nginx-filesystem-1.20.1-9.el7.noarch                       1/3 \n  Verifying  : 1:openssl11-libs-1.1.1k-2.el7.x86_64                         2/3 \n  Verifying  : 1:nginx-1.20.1-9.el7.x86_64                                  3/3 \n\nInstalled:\n  nginx.x86_64 1:1.20.1-9.el7                                                   \n\nDependency Installed:\n  nginx-filesystem.noarch 1:1.20.1-9.el7  openssl11-libs.x86_64 1:1.1.1k-2.el7 \n\nComplete!\n"
    ]
}


ansible all -m shell -a 'rpm -q nginx'
[WARNING]: Consider using the yum, dnf or zypper module rather than running 'rpm'.  If you need to use command because yum, dnf or zypper is insufficient you can add 'warn:
false' to this command task or set 'command_warnings=False' in ansible.cfg to get rid of this message.
192.168.162.130 | CHANGED | rc=0 >>
nginx-1.20.1-9.el7.x86_64
192.168.162.129 | CHANGED | rc=0 >>
nginx-1.20.1-9.el7.x86_64

```



```shell
#service模块：
#启动nginx服务
ansible all -m service -a 'name=nginx state=started'
192.168.162.129 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": true, 
    "name": "nginx", 
    "state": "started", 
    "status": {
        "ActiveEnterTimestampMonotonic": "0", 
        "ActiveExitTimestampMonotonic": "0", 
192.168.162.130 | CHANGED => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    }, 
    "changed": true, 
    "name": "nginx", 
    "state": "started", 
    "status": {
        "ActiveEnterTimestampMonotonic": "0", 
        "ActiveExitTimestampMonotonic": "0", 
        "ActiveState": "inactive", 
        "After": "network-online.target system.slice -.mount systemd-journald.socket nss-lookup.target remote-fs.target tmp.mount basic.target", 
        "AllowIsolate": "no", 
        "AmbientCapabilities": "0",         


#停止nginx服务
ansible all -m service -a 'name=nginx state=stopped'
```



```shell
#script模块：
#一个脚本在多台主机一次性执行：
cat test.sh 
#!/bin/bash
touch /tmp/a.txt
[root@master ~]# ansible all -m script -a '/root/test.sh' 
192.168.162.130 | CHANGED => {
    "changed": true, 
    "rc": 0, 
    "stderr": "Shared connection to 192.168.162.130 closed.\r\n", 
    "stderr_lines": [
        "Shared connection to 192.168.162.130 closed."
    ], 
    "stdout": "", 
    "stdout_lines": []
}
192.168.162.129 | CHANGED => {
    "changed": true, 
    "rc": 0, 
    "stderr": "Shared connection to 192.168.162.129 closed.\r\n", 
    "stderr_lines": [
        "Shared connection to 192.168.162.129 closed."
    ], 
    "stdout": "", 
    "stdout_lines": []
}

#查看/tmp目录
ansible all -m command -a 'ls /tmp/'
192.168.162.129 | CHANGED | rc=0 >>
a.txt
192.168.162.130 | CHANGED | rc=0 >>
a.txt
```





```shell
 #ansible-console:控制台式的批量交互执行
 
[root@master ~]# ansible-console
Welcome to the ansible console.
Type help or ? to list commands.

 
 root@all (2)[f:5]$ pwd
192.168.162.129 | CHANGED | rc=0 >>
/root
192.168.162.130 | CHANGED | rc=0 >>
/root
root@all (2)[f:5]$ list
192.168.162.129
192.168.162.130
root@all (2)[f:5]$ ip a |grep inet
192.168.162.129 | CHANGED | rc=0 >>
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host 
    inet 192.168.162.129/24 brd 192.168.162.255 scope global noprefixroute dynamic ens33
    inet6 fe80::8088:3cef:ac97:787b/64 scope link noprefixroute 
    inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
192.168.162.130 | CHANGED | rc=0 >>
    inet 127.0.0.1/8 scope host lo
    inet6 ::1/128 scope host 
    inet 192.168.162.130/24 brd 192.168.162.255 scope global noprefixroute dynamic ens33
    inet6 fe80::8088:3cef:ac97:787b/64 scope link tentative noprefixroute dadfailed 
    inet6 fe80::7914:a510:356c:a292/64 scope link tentative noprefixroute dadfailed 
    inet6 fe80::ee73:d391:2eae:33c4/64 scope link noprefixroute 
    inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
```





### ansible-playbook



```shell
#批量安装docker，并批量做好配置文件

vim installDocker.yml
---          #标准格式

- hosts: all        #  -表示定义一个变量
  remote_user: root
  tasks:
  - name: install docker
    yum: name=docker state=latest        #yum表示要用到的模块

```

```shell
#批量安装多个APP：
vim multi.yml 

---

- hosts: web
  remote_user: root
  tasks:
  - name: install app
    yum: name={{ item  }} state=latest
    with_items:
       - tomcat
       - nginx
       - mysql
```











### ansible执行后返回结果所用的三种颜色



绿色：命令执行成功但受控端的状态没有（无需）发送改变

黄色：命令执行成功且受控端的状态发生了改变

红色：命令执行失败
