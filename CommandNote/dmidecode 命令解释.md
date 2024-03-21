# dmidecode 命令解释



dmidecode 可以查询 BIOS、系统、主板、处理器、内存、缓存等非常重要信息，下面介绍一下常用命令

```shell
[root@demo ~]# dmidecode -t1
# dmidecode 3.0
Getting SMBIOS data from sysfs.
SMBIOS 2.7 present.

Handle 0x0100, DMI type 1, 27 bytes
System Information
	Manufacturer: Dell Inc.
	Product Name: PowerEdge R720			# 服务器型号
	Version: Not Specified
	Serial Number: 7GTKD92					# 主板的序列号，也称SN号
	UUID: 4C4C4544-0047-5410-804B-B7C04F443932
	Wake-up Type: Power Switch
	SKU Number: SKU=NotProvided;ModelName=PowerEdge R720
	Family: Not Specified
```

**服务器序列号（SN）号**

```shell
dmidecode -s system-serial-number 
```

**最大支持存容量**

```
[root@demo ~]# dmidecode | grep "Maximum Capacity" |sed  "s/^[ \t]*//" 
Maximum Capacity: 1536 GB
```

**查看插槽上内存的速率,没插就是unknown。**

```shell
[root@storage114 ~]# dmidecode|grep -A16 "Memory Device"|grep 'Speed'
	Speed: 1333 MHz
	Speed: 1333 MHz
	Speed: 1333 MHz
	Speed: 1333 MHz
	Speed: Unknown
	Speed: Unknown
	Speed: Unknown
	Speed: Unknown
	Speed: Unknown
	Speed: Unknown
	Speed: Unknown
	Speed: Unknown
	Speed: 1333 MHz
	Speed: 1333 MHz
	Speed: 1333 MHz
	Speed: 1333 MHz
	Speed: Unknown
	Speed: Unknown
	Speed: Unknown
	Speed: Unknown
	Speed: Unknown
	Speed: Unknown
	Speed: Unknown
	Speed: Unknown
```



**查看内存信息**

```
[root@demo ~]#  dmidecode -t memory  
# dmidecode 3.0
Getting SMBIOS data from sysfs.
SMBIOS 2.7 present.

Handle 0x1000, DMI type 16, 23 bytes
Physical Memory Array
	Location: System Board Or Motherboard
	Use: System Memory
	Error Correction Type: Multi-bit ECC
	Maximum Capacity: 1536 GB
	Error Information Handle: Not Provided
	Number Of Devices: 24

Handle 0x1100, DMI type 17, 34 bytes
Memory Device
	Array Handle: 0x1000
	Error Information Handle: Not Provided
	Total Width: 72 bits
	Data Width: 64 bits
	Size: 16384 MB
	Form Factor: DIMM
	Set: 1
	Locator: DIMM_A1 
	Bank Locator: Not Specified
	Type: DDR3
	Type Detail: Synchronous Registered (Buffered)
	Speed: 1600 MHz
	Manufacturer: 00CE04B300CE
	Serial Number: 12AD8057
	Asset Tag: 03143021
	Part Number: M393B2G70QH0-YK0  
	Rank: 2
	Configured Clock Speed: 1600 MHz				# 内存的速度

Handle 0x1101, DMI type 17, 34 bytes
Memory Device
	Array Handle: 0x1000
	Error Information Handle: Not Provided
	Total Width: 72 bits
	Data Width: 64 bits
	Size: 16384 MB
	Form Factor: DIMM
	Set: 1
	Locator: DIMM_A2 
	Bank Locator: Not Specified
	Type: DDR3
	Type Detail: Synchronous Registered (Buffered)
	Speed: 1600 MHz
	Manufacturer: 00CE04B300CE
	Serial Number: 12AD8057
	Asset Tag: 03143021
	Part Number: M393B2G70QH0-YK0  
	Rank: 2
	Configured Clock Speed: 1600 MHz

Handle 0x1102, DMI type 17, 34 bytes
Memory Device
	Array Handle: 0x1000
	Error Information Handle: Not Provided
	Total Width: 72 bits
	Data Width: 64 bits
	Size: 16384 MB
	Form Factor: DIMM
	Set: 1
	Locator: DIMM_A3 
	Bank Locator: Not Specified
	Type: DDR3
	Type Detail: Synchronous Registered (Buffered)
	Speed: 1600 MHz
	Manufacturer: 00CE04B300CE
	Serial Number: 12AD8057
	Asset Tag: 03143021
	Part Number: M393B2G70QH0-YK0  
	Rank: 2
	Configured Clock Speed: 1600 MHz

Handle 0x1103, DMI type 17, 34 bytes
Memory Device
	Array Handle: 0x1000
	Error Information Handle: Not Provided
	Total Width: 72 bits
	Data Width: 64 bits
	Size: 16384 MB
	Form Factor: DIMM
	Set: 1
	Locator: DIMM_A4 
	Bank Locator: Not Specified
	Type: DDR3
	Type Detail: Synchronous Registered (Buffered)
	Speed: 1600 MHz
	Manufacturer: 00CE04B300CE
	Serial Number: 12AD8057
	Asset Tag: 03143021
	Part Number: M393B2G70QH0-YK0  
	Rank: 2
	Configured Clock Speed: 1600 MHz

[root@storage117 ~]# dmidecode | grep -A16 "Memory Device" | grep "Size" 
	Size: 16384 MB
	Size: 16384 MB
	Size: 16384 MB
	Size: 16384 MB
	Size: No Module Installed
	Size: No Module Installed
	Size: No Module Installed
	Size: No Module Installed
	Size: No Module Installed
	Size: No Module Installed
	Size: No Module Installed
	Size: No Module Installed
	Size: 16384 MB
	Size: 16384 MB
	Size: 16384 MB
	Size: 16384 MB
	Size: No Module Installed
	Size: No Module Installed
	Size: No Module Installed
	Size: No Module Installed
	Size: No Module Installed
	Size: No Module Installed
	Size: No Module Installed
	Size: No Module Installed

```

