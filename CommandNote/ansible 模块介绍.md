# 常用模块

#### synchronize 文件目录同步模块

**模块主要用于目录、文件的同步，主要基于rsync命令工具同步目录和文件**

```
- compress：开启压缩，默认为开启
- archive：是否采用归档模式同步，保证源文件和目标文件属性一致
- checksum：是否效验
- dirs：以非递归的方式传送目录
- links：同步链接文件
- recursive：是否递归yes/no
- rsync_opts：使用rsync的参数
- copy_links：同步的时候是否复制链接
- delete：删除源中没有但目标存在的文件，使两边内容一样，以推送方为主
- src：源目录及文件
- dest：目标文件及目录
- dest_port：目标接收的端口
- rsync_path：服务的路径，指定rsync在远程服务器上执行
- rsync_remote_user：设置远程用户名
- –exclude=.log：忽略同步以.log结尾的文件，这个可以自定义忽略什么格式的文件，或者.txt等等都可以，但是由于这个是rsync命令的参数，所以必须和rsync_opts一起使用，比如rsync_opts=--exclude=.txt这种模式
- mode：同步的模式，rsync同步的方式push、pull，默认是推送push，从本机推送给远程主机，pull表示从远程主机上拿文件
```

演示

```
ansible x.x.x.x -m synchronize -a "src=/etc/docker dest=/etc"


- hosts: 192.168.1.1     # 远端主机
  remote_user:root   # 远端主机的操作用户
  task:
    - name: controll to node
      synchronize:
        src: /xxx/xxx    # 控制端路径
        dest: /.../...   # 远端主机路径
        mode: push       # 默认为push可不写
```