### 一、报错详情

`PTY allocation request failed on channel 0`

![image-20211105161639584](images/ssh远程PTY报错处理办法/image-20211105161639584.png)

- 无法获取远程终端，但可以执行远程命令

### 二、处理办法

```bash
ssh 172.16.100.61 'umount /dev/pts;mount devpts /dev/pts -t devpts'
```

