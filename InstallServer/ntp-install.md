# Red Hat/CentOS 6（或以下版本） 配置NTP

本文档适用于低版本，后续会进行补充

## 已安装ntp，修改时间源

##### 1.查看配置文件

```shell
cat /etc/ntp.conf |grep -Ev '^$|^#'
driftfile /var/lib/ntp/drift
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict -6 ::1
server 0.rhel.pool.ntp.org iburst
server 1.rhel.pool.ntp.org iburst
server 2.rhel.pool.ntp.org iburst
server 3.rhel.pool.ntp.org iburst
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
```

##### 2.注释掉默认的配置文件

```shell
sudo sed -i '/^server.*iburst$/ s/^/## /' /etc/ntp.conf
```

##### 3.修改配置文件

```shell
sudo bash -c "cat >> /etc/ntp.conf << EOF
server 10.96.224.1 iburst
server 10.96.224.2 iburst
server 10.96.1.52  iburst
EOF"
```

##### 4.重启服务

```shell
sudo /etc/init.d/ntpd restart && sudo chkconfig ntpd on
```

##### 5.查看时间

```shell
for i in 10.96.40.61 10.96.40.62 10.96.92.9 10.96.92.8;do sudo su - infomgr -c "ssh -o StrictHostKeyChecking=no  $i 'date'";done
```

------



## 未安装ntp，安装并进行配置时间源

##### 1.对之前残留进行卸载

```shell
rpm -qa |grep ntp
sudo rpm -e ntpdate-4.2.6p5-15.el6_10.x86_64
```

##### 2.下载ntp服务

```shell
yum install -y ntp
```

##### 3.注释掉默认的配置文件

```shell
sudo sed -i '/^server.*iburst$/ s/^/## /' /etc/ntp.conf
```

##### 4.修改配置文件

```shell
sudo bash -c "cat >> /etc/ntp.conf << EOF
server 10.96.224.1 iburst
server 10.96.224.2 iburst
server 10.96.1.52  iburst
EOF"
```

##### 5.重启服务

```shell
sudo /etc/init.d/ntpd restart && sudo chkconfig ntpd on
```

##### 6.查看时间

```shell
for i in 10.96.40.61 10.96.40.62 10.96.92.9 10.96.92.8;do sudo su - infomgr -c "ssh -o StrictHostKeyChecking=no  $i 'date'";done
```

