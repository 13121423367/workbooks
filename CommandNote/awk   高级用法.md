# awk   高级用法



##### 文件读取的几种方式

```shell
1.按照字符数量读取：每一次可读取一个字符，或者多个字符，直到把整个文件读取完
2.按照分隔符进行读取：一直读取知道遇到了分隔符才停止，下次继续从分隔的位置处向后读取，直到读完整个文件
3.按行读取：每次读取一行，直到把整个文件读完   “是按照分隔符读取的一种特殊情况:将分隔符指定为了换行符 \n  BEGIN{OFS="\n"}”
4.一次性读取整个文件 是按字符数量读取的特殊情况，也是按分隔符读取的特殊情况
```

###### awk用法入门

```bash
 awk 'awk_program' a.txt
 
 解释：
 a.txt 是awk要读取的文件，可以是0个或者一个文件，也可以是多个文件，如果不给定任何文件，但又需要读取文件，则表示从标准输入中读取
 '' 单引号包围的是awk代码，也称为awk程序，尽量使用单引号，因为在awk中经常使用`符号`,而符号在shell是变量符号，如果使用双引号包围awk代码，则符号会被shell解析成shell变量，然后进行shell变量替换，使用单引号包围awk代码，则会脱离shell的魔掌，使得 $ 服务留给了awk去解析
```

awk程序中，大量使用大括号，大括号表示代码块，代码块中间可以之间连用，代码块内部的多个语句需使用分 号";"分隔

```shell
awk '{print $0}' a.txt
awk '{print $0}{print $0;print $0}' a.txt

解释：
print $0  : 当前行
print $1  : 第一个字符串
print NR  : 变量NR表示当前处理的是第几行。
print NF  : 变量NF表示当前行有多少个字段，因此$NF就代表最后一个字段。
print $(NF-1)  : $(NF-1)代表倒数第二个字段。

awk的其他内置变量如下。
    FILENAME：当前文件名
    FS：字段分隔符，默认是空格和制表符。
    RS：行分隔符，用于分割每一行，默认是换行符。
    OFS：输出字段的分隔符，用于打印时分隔字段，默认为空格。
    ORS：输出记录的分隔符，用于打印时分隔记录，默认为换行符。
    OFMT：数字输出的格式，默认为％.6g
```

###### BEGIN和END语句块

```shell
[root@gitlab awk]# cat a.txt 
hello-world

awk 'BEGIN{print "我在前面"}{print $0}' a.txt 
我在前面
hello-worl

awk 'END{print "我在后面"}{print $0}' a.txt
hello-world
我在后面

awk 'BEGIN{print "我在前面"}{print $0}END{print "我在后面"}' a.txt
我在前面
hello-world
我在后面
```

**BEGIN代码块：**

- 在读取文件之前执行，且执行一次
- 在BEGIN代码块中，无法使用 $0 或其它一些特殊变量

**END代码块:**

- 在读取文件完成之后执行，且执行一次
- 有END代码块，必有要读取的数据(可以是标准输入)
- END代码块中可以使用$0等一些特殊变量，只不过这些特殊变量保存的是最后一轮awk循环的数据

**main代码块:**

- 读取文件时循环执行，(默认情况)每读取一行，就执行一次main代码块
- main代码块可有多个





###### 函数

awk提供了一些内置函数，方便对原始数据的处理。函数toupper()用于将字符转为大写。

```shell
[root@gitlab awk]# awk  '{ print toupper($1) }' a.txt 
HELLO-WORLD

其他常用函数如下。
    tolower()：字符转为小写。
    length()：返回字符串长度。
    substr()：返回子字符串。
    sin()：正弦。
    cos()：余弦。
    sqrt()：平方根。
    rand()：随机数
```



###### 条件

**awk允许指定输出条件，只输出符合条件的行。输出条件要写在动作的前面**

```
awk '条件 动作' 文件名
```

```shell
ifconfig 
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.17.67  netmask 255.255.240.0  broadcast 10.0.31.255
        inet6 fe80::5054:ff:fe03:6178  prefixlen 64  scopeid 0x20<link>
        ether 52:54:00:03:61:78  txqueuelen 1000  (Ethernet)
        RX packets 7391909  bytes 541418232 (516.3 MiB)
        RX errors 0  dropped 203  overruns 0  frame 0
        TX packets 245  bytes 10610 (10.3 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 122.14.194.189  netmask 255.255.255.0  broadcast 122.14.194.255
        inet6 fe80::5054:1ff:fe03:4b6  prefixlen 64  scopeid 0x20<link>
        ether 52:54:01:03:04:b6  txqueuelen 1000  (Ethernet)
        RX packets 35070845  bytes 2282823191 (2.1 GiB)
        RX errors 0  dropped 136861  overruns 0  frame 0
        TX packets 2211565  bytes 758113712 (722.9 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 41099155  bytes 3627944774 (3.3 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 41099155  bytes 3627944774 (3.3 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

[root@gitlab awk]# ifconfig |awk '/inet /{print $2}'
10.0.17.67
122.14.194.189
127.0.0.1
```

###### 只输出奇数行

```shell
cat demo.txt 
1        inet 10.0.17.67  netmask 255.255.240.0  broadcast 10.0.31.255
2        inet6 fe80::5054:ff:fe03:6178  prefixlen 64  scopeid 0x20<link>
3        ether 52:54:00:03:61:78  txqueuelen 1000  (Ethernet)
4        RX packets 7397976  bytes 541865206 (516.7 MiB)
5        RX errors 0  dropped 203  overruns 0  frame 0
6        TX packets 245  bytes 10610 (10.3 KiB)
7        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
8
9eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
10        inet 122.14.194.189  netmask 255.255.255.0  broadcast 122.14.194.255
11        inet6 fe80::5054:1ff:fe03:4b6  prefixlen 64  scopeid 0x20<link>
12        ether 52:54:01:03:04:b6  txqueuelen 1000  (Ethernet)
13        RX packets 35103219  bytes 2285022213 (2.1 GiB)
14        RX errors 0  dropped 136970  overruns 0  frame 0
15        TX packets 2230175  bytes 760430192 (725.2 MiB)
16        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

[root@gitlab awk]# awk 'NR % 2 == 1 {print $1}' demo.txt 
1
3
5
7
9eth1:
11
13
15
```

###### 打印第三行以后的行

```shell
[root@gitlab awk]# awk  'NR >3 {print $1}' demo.txt 
4
5
6
7
8
9eth1:
10
11
12
13
14
15
16

高阶一点的用法:

打印第十行到二十行中的行和$1
awk -F: '(NR>=10&&NR<=20){print NR,$1}'
```

###### 输出第二个字段等于指定值的行。

```shell
awk '$2 == "inet" {print $3}' demo.txt 
10.0.17.67
122.14.194.189

[root@gitlab awk]# awk '$2 == "inet" || $2 =="inet6" {print $3}' demo.txt 
10.0.17.67
fe80::5054:ff:fe03:6178
122.14.194.189
fe80::5054:1ff:fe03:4b6
```



awk的语法充斥着 pattern{action} 的模式，它们称为awk rule:

```swift
awk 'BEGIN{n=3} /^[0-9]/{$1>5}{$1=333;print $1} /Alice/{print "Alice"} END{print "hello"}' a.txt
```





##### if

**awk提供了if结构，用于编写复杂的条件。**

```shell
[root@gitlab awk]# cat demo.txt 
aaaaaa  cc
bbbbbb baa
cccbbb  bb
ddd  bb
222        aa
eeeeff  f
fgffff fff
ghhhhhh  ff

[root@gitlab awk]# awk '{if($1 > "c")print $1 ; else print "-------"}' demo.txt 
-------
-------
cccbbb
ddd
-------
eeeeff
fgffff
ghhhhhh
```















##### 案例 1：格式化空白

```shell
		aaaa			bbb		ccc 
	bbb			aaa	ccc
ddd    fff		eee	gg			hh	ii	jj

[root@gitlab tmp]#awk 'BEGIN{OFS="\t"}{$1=$1;print}' demo.txt
aaaa	bbb	ccc
bbb	aaa	ccc
ddd	fff	eee	gg	hh	ii	jj


cat demo2.txt 
1 qwrw saf 2r13r4 456t 
2 345 w 5463  36 435 
a 235  345  354 345 
10 324 325  352 wafs
20 3r 4 35 4tw tg4 
!%3 35 2143 53 

[root@gitlab tmp]#awk 'BEGIN{OFS="\t"};$1=$1{print}' demo2.txt 
1	qwrw	saf	2r13r4	456t
2	345	w	5463	36	435
a	235	345	354	345
10	324	325	352	wafs
20	3r	4	35	4tw	tg4
!%3	35	2143	53


awk的其他内置变量如下。

    FILENAME：当前文件名
    FS：字段分隔符，默认是空格和制表符。
    RS：行分隔符，用于分割每一行，默认是换行符。
    OFS：输出字段的分隔符，用于打印时分隔字段，默认为空格。
    ORS：输出记录的分隔符，用于打印时分隔记录，默认为换行符。
    OFMT：数字输出的格式，默认为％.6g
```



##### 案例 2：在某个字符后插入几个新字段

```shell
a	b	c	d

awk '{$2=$2" 1 2 3";print}' demo1.txt
```



##### 案例3： 筛选IPv4 地址

```shell
# 筛选出 ifconfig IPv4 获取到的地址  不包括127.0.0.1
ifconfig 
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.0.17.67  netmask 255.255.240.0  broadcast 10.0.31.255
        inet6 fe80::5054:ff:fe03:6178  prefixlen 64  scopeid 0x20<link>
        ether 52:54:00:03:61:78  txqueuelen 1000  (Ethernet)
        RX packets 1677440  bytes 122686575 (117.0 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 65  bytes 3050 (2.9 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 122.14.194.189  netmask 255.255.255.0  broadcast 122.14.194.255
        inet6 fe80::5054:1ff:fe03:4b6  prefixlen 64  scopeid 0x20<link>
        ether 52:54:01:03:04:b6  txqueuelen 1000  (Ethernet)
        RX packets 7976865  bytes 830244300 (791.7 MiB)
        RX errors 0  dropped 31123  overruns 0  frame 0
        TX packets 295628  bytes 34905059 (33.2 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 11881313  bytes 1115983484 (1.0 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 11881313  bytes 1115983484 (1.0 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0


ifconfig |awk '/inet / && !($2 ~ /^127/) {print $2}'
```



##### 案例4： 统计Nginx中访问状态不为200 的IP 次数并排序

```shell
awk '$8!=200{arr[$1]++}END{for(i in arr){print arr[i],i}}' access.log
```



##### 案例5：将下列排序  并以$1 (第一列)做判断，如果 $1> 2 打印整行，否则打印  -------------

```shell
1 qwrw saf 2r13r4 456t 
2 345 w 5463  36    435 
a 235  345  354 345 
10 324  325       352 wafs
20 3r 4 35 4tw tg4 
!%3 35 2  143 53

[root@gitlab tmp]# awk 'BEGIN{OFS="\t"} $1=$1 {if ($1 > "2") print $1;else print "-------------"}' demo2.txt
-------------
-------------
a
-------------
20
-------------
```

##### 案例6：计算平均值.

```shell
[root@gitlab awk]# cat demo.txt 
12	aaaaaa  cc  	1
3	bbbbbb baa2	2
4	cccbbb  bb	66
5	ddd  bb	 	3
76	222        aa	1
9	eeeeff  f	1
8	fgffff fff	34
0	ghhhhhh  ff	20

[root@gitlab awk]# awk '{sum+=$1}END{print "Average=",sum/NR}' demo.txt 
Average= 14.625
[root@gitlab awk]# awk '{sum+=$4}END{print "Average=",sum/NR}' demo.txt 
Average= 16

```

