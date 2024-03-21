## 部署Frp内网穿刺

### 1、服务器端（公网服务器）

##### **1.1）、安装Frp**     

​		ftp下载地址：`https://github.com/fatedier/frp`  找到最新版本





![image-20220307045605958](C:\Users\小贤\AppData\Roaming\Typora\typora-user-images\image-20220307045605958.png)



- 将安装包解压到/usr/local/frp    `tar -zxvf frp_0.39.1_linux_amd64.tar.gz -C/usr/local/frp`



![image-20220307050610137](C:\Users\小贤\AppData\Roaming\Typora\typora-user-images\image-20220307050610137.png)

前两个文件（c结尾代表client）分别是客户端程序和客户端配置文件。

后两个文件（s结尾代表server）分别是服务端程序和服务端配置文件

这里是为服务端配置frp 只关注**frps**和**frps.ini**即可





##### **1.2）、修改配置文件**

对frps.ini文件进行配置

```
vim frps.ini

[common]
bind_port = 7000
token = 12345678

bind_port：表示用于客户端和服务端连接的端口，这个端口号之后在配置客户端的时候要用到
token是：用于客户端和服务端连接的口令
因用到了7000端口这里我们找到服务器的策略组将6000-8000端口开放


```

##### **1.3)、添加云服务器端口**![image-20220307054706543](C:\Users\小贤\AppData\Roaming\Typora\typora-user-images\image-20220307054706543.png)



##### 1.4）、启动服务

	nohup ./frps -c frps.ini &


​	
​	[root@VM-4-7-centos frp_0.39.1_linux_amd64]# ps -ef |grep frp
​	root      6052  2700  0 05:24 pts/0    00:00:00 ./frps -c frps.ini
​	root      9394  6484  0 05:52 pts/3    00:00:00 grep --color=auto frp


### 2、客户端

##### 		2.1）、安装frp

```
wget https://github.com/fatedier/frp/releases/download/v0.39.1/frp_0.39.1_linux_amd64.tar.gz
mkdir -p /usr/local/frp
tar -zxvf frp_0.39.1_linux_amd64.tar.gz -C /usr/local/frp/
```

##### 		2.2）、修改frpc.ini配置文件

```

[root@Prometheus frp_0.39.1_linux_amd64]# cat frpc.ini
[common]
server_addr = 101.35.126.215
server_port = 7000
token = 12345678

[ssh]
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 7001



server_addr：为服务端IP地址，填入即可。
server_port：为服务器端口，填入你设置的端口号即可，如果未改变就是7000
token：是你在服务器上设置的连接口令，原样填入即可。

[xxx]：表示一个规则名称，自己定义，便于查询即可。
type：表示转发的协议类型，有TCP和UDP等选项可以选择
local_port：是本地应用的端口号，按照实际应用工作在本机的端口号填写即可。
remote_port：是该条规则在服务端开放的端口号
```



​		2.3）、启动服务

```
nohup ./frpc -c frpc.ini &

[root@Prometheus frp_0.39.1_linux_amd64]# ps -ef |grep frp
root      3615  8417  0 06:38 pts/1    00:00:00 ./frpc -c frpc.ini
root      3695  3677  0 06:44 pts/4    00:00:00 grep --color=auto frp
```





### 3、验证连接服务器

![image-20220307064627033](C:\Users\小贤\AppData\Roaming\Typora\typora-user-images\image-20220307064627033.png)

