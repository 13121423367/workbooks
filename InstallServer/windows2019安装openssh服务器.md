# windows2019 安装 openssh服务器

## 安装 openssh

打开设置 --- 应用

![image-20211102171957509](images/windows2019安装openssh服务器/image-20211102171957509.png)



应用和功能下，选择管理可选功能。

![image-20211102172059270](images/windows2019安装openssh服务器/image-20211102172059270.png)



打开添加功能找到 openssh 服务器 安装。注意：安装前要确定服务器可以上网。

下图是安装完成的效果。

![image-20211102172250518](images/windows2019安装openssh服务器/image-20211102172250518.png)



## 配置 openssh 启动

打开“服务”

![image-20211102172501077](images/windows2019安装openssh服务器/image-20211102172501077.png)



双击 “OpenSSH SSH Server”

![image-20211102172558759](images/windows2019安装openssh服务器/image-20211102172558759.png)



设置启动类型：自动。防火墙会自动添加放行 22号端口。