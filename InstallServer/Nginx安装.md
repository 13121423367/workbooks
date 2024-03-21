![image-20220707000336692](C:\Users\徐思贤\AppData\Roaming\Typora\typora-user-images\image-20220707000336692.png)







## Nginx安装

#### 基础环境

```bash
hostnamectl set-hostname  nginx1
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum clean all
yum makecache fast

yum install -y iptables-services
systemctl disable firewalld.service && systemctl stop firewalld.service


cat /etc/sysconfig/selinux |grep '^SELINUX='
SELINUX=disabled

cat >> /etc/sysctl.conf << EOF
> net.ipv4.ip_forward = 1
> EOF

cat >/etc/sysconfig/iptables <<EOF
# sample configuration for iptables service
# you can edit this manually or use system-config-firewall
# please do not ask us to add additional ports/services to this default configuration
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 10602 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 10601 -j ACCEPT
-A INPUT -j DROP
-A FORWARD -j DROP
COMMIT
EOF
systemctl enable iptables.service && systemctl start iptables.service 


```

#### yum 安装nginx

```bash
yum install nginx -y

vim /etc/nginx/nginx.conf
    server {
        listen       10601;
        root         /usr/share/nginx/html;

        location  / {
            proxy_pass https://www.qq.com;  #设置代理地址
        }

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }



vim /etc/init.d/realserver 
#!/bin/bash

#虚拟的vip 根据自己的实际情况定义
SNS_VIP=10.12.29.114
/etc/rc.d/init.d/functions
case "$1" in
start)
       ifconfig lo:0 $SNS_VIP netmask 255.255.255.255 broadcast $SNS_VIP
       /sbin/route add -host $SNS_VIP dev lo:0
       echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
       echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
       echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
       echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce
       sysctl -p >/dev/null 2>&1
       echo "RealServer Start OK"
       ;;
stop)
       ifconfig lo:0 down
       route del $SNS_VIP >/dev/null 2>&1
       echo "0" >/proc/sys/net/ipv4/conf/lo/arp_ignore
       echo "0" >/proc/sys/net/ipv4/conf/lo/arp_announce
       echo "0" >/proc/sys/net/ipv4/conf/all/arp_ignore
       echo "0" >/proc/sys/net/ipv4/conf/all/arp_announce
       echo "RealServer Stoped"
       ;;
*)
       echo "Usage: $0 {start|stop}"
       exit 1
esac
exit 0

chmod 755 /etc/init.d/realserver
chmod 755 /etc/rc.d/init.d/functions
service realserver start

systemctl stop nginx && systemctl start nginx
```

#### yum 安装keepalived-master

```bash
yum install keepalived -y

[root@keepalived-master keepalived]# cat keepalived.conf 
! Configuration File for keepalived

global_defs {
   router_id keepalived-master
}

vrrp_instance VI_1 {
    state MASTER
    interface ens192
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        10.12.29.114
    }
}

virtual_server 10.12.29.114 10601 {
    delay_loop 6
    lb_algo wrr
    lb_kind DR
    nat_mask 255.255.255.0
    protocol TCP
    real_server 10.12.29.115 10601 {
        weight 1
        TCP_CHECK {
            		connect_timeout 3
           		 nb_get_retry 3
          		 delay_before_retry 3
          		 connect_port 10601
        }
    }
    real_server 10.12.29.116 10601 {
        weight 1
        TCP_CHECK {
            		connect_timeout 3
            		nb_get_retry 3
            		delay_before_retry 3
           		connect_port 10601
        }
    }
    real_server 10.12.29.117 10601 {
        weight 1
        TCP_CHECK {
          		connect_timeout 3
           		nb_get_retry 3
            		delay_before_retry 3
            		connect_port 10601
        }
    }
}





```

#### yum安装keepalived-backup

```bash
[root@keepalived-backup keepalived]# cat keepalived.conf 
! Configuration File for keepalived

global_defs {

   router_id keepalived-master 
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens192
    virtual_router_id 51
    priority 50
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        10.12.29.114
    }
}
virtual_server 10.12.29.114 10601 {
    delay_loop 6
    lb_algo wrr
    lb_kind DR
    nat_mask 255.255.255.0
    protocol TCP
    real_server 10.12.29.115 10601 {
        weight 1
        TCP_CHECK {
            		connect_timeout 3
           		 nb_get_retry 3
          		 delay_before_retry 3
          		 connect_port 10601
        }
    }
    real_server 10.12.29.116 10601 {
        weight 1
        TCP_CHECK {
            		connect_timeout 3
            		nb_get_retry 3
            		delay_before_retry 3
           		connect_port 10601
        }
    }
    real_server 10.12.29.117 10601 {
        weight 1
        TCP_CHECK {
            		connect_timeout 3
            		nb_get_retry 3
            		delay_before_retry 3
           		connect_port 10601
        }
    }
}


[root@keepalived-master keepalived]# cat /etc/sysconfig/iptables
# sample configuration for iptables service
# you can edit this manually or use system-config-firewall
# please do not ask us to add additional ports/services to this default configuration
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -p vrrp -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 10602 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 10601 -j ACCEPT
-A INPUT -j DROP
-A FORWARD -j DROP
COMMIT

systemctl stop iptables && systemctl start iptables



#安装IPVSadm
yum install ipvsadm -y


#查看当前配置的虚拟服务和各个RS的权重
ipvsadm -Ln

#查看当前ipvs模块中记录的连接（可用于观察转发情况）
ipvsadm -lnc

#查看ipvs模块的转发情况统计
ipvsadm -Ln --stats | --rate

#查看lvs的超时时间
ipvsadm -L --timeout


#优化连接超时时间
ipvsadm --set 1 10 300

```

#### 

```bash

```













































