# windows批量创建用户



## powershell方式

设置密码为交互式，密码无法显示为明文。使用此方法多用户密码一致时较为方便。


```powershell
echo -n "请输入一个密码，然后按回车键继续"
$Password = Read-Host -AsSecureString

# 定义用户列表
$users = "one", "two", "three"

for($i=0; $i -lt $users.Length; $i++) 
{
    #  创建用户，并配置用户属性：账号用户永不过期、密码永不过期、用户不能修改密码
	New-LocalUser -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword -Password $Password -Name $users[$i]
    #  添加用户到远程桌面组
	Add-LocalGroupMember -Group 'Remote Desktop Users' -Member $users[$i]
}
```





## cmd 方式

```powershell
# 创建用户，设置密码，用户永不过期，用户不能修改密码
net user abc pppNo.1!!! /add /EXPIRES:NEVER /PASSWORDCHG:NO

# 密码用不过期
Set-LocalUser -PasswordNeverExpires 1 -Name abc

# 将用户添加到远程桌面组
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member abc
```



RDP 记录

```powershell
net user anzhipeng eMm2Mv0Ji5Eug6QY /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user liuyumeng UejCxh7FX9tg88NM /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user lvqian ULHsiWvbBw6d0IPA /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user quliwei lKlh3RZ1ImTc4hWb /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user shenyaohui UDuFQmheFGEOOLH5 /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user wangguangliang DlVWiKJ1ZbeYZ0X6 /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user wanghe qFW32QzSJuIs8RWh /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user wangshiyao SZMjiZUl5yRddfH6 /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user caojianping MHVVie3eRUlumAoO /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user chenyukun E8eclYwhLl1bAGoL /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user guoshijie 6JZx41JNWypIHjma /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user leijianteng gEQqqd5R6gm5qck0 /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user lijufa CNLN51STmYXpc8Bs /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user liyuanjun ml952696Br5jCC1k /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user songjingjing jBJE6pSM0VJSmbrq /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user zhaoruxia Dgpp7tl6UxofQ3tE /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user tianyuanming nHxOQNPspOZ9TlNw /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user zhangxinran Va9oHKCQixUPGba6 /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user jiangxingchun f3OnX5XBUM8KqDIb /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user guojing SXuVuEoGvq8NRWzk /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user sunjianxing DRxSDRvsblhw0sBr /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user zhangxiang 2ACNwzhCn2w23cp8 /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user oguojing n9qw5s8WkjyCemCg /add /EXPIRES:NEVER /PASSWORDCHG:NO
net user zhuwei 3TQ42EWULUNeBE4w /add /EXPIRES:NEVER /PASSWORDCHG:NO

Set-LocalUser -PasswordNeverExpires 1 -Name anzhipeng
Set-LocalUser -PasswordNeverExpires 1 -Name liuyumeng
Set-LocalUser -PasswordNeverExpires 1 -Name lvqian
Set-LocalUser -PasswordNeverExpires 1 -Name quliwei
Set-LocalUser -PasswordNeverExpires 1 -Name shenyaohui
Set-LocalUser -PasswordNeverExpires 1 -Name wangguangliang
Set-LocalUser -PasswordNeverExpires 1 -Name wanghe
Set-LocalUser -PasswordNeverExpires 1 -Name wangshiyao
Set-LocalUser -PasswordNeverExpires 1 -Name caojianping
Set-LocalUser -PasswordNeverExpires 1 -Name chenyukun
Set-LocalUser -PasswordNeverExpires 1 -Name guoshijie
Set-LocalUser -PasswordNeverExpires 1 -Name leijianteng
Set-LocalUser -PasswordNeverExpires 1 -Name lijufa
Set-LocalUser -PasswordNeverExpires 1 -Name liyuanjun
Set-LocalUser -PasswordNeverExpires 1 -Name songjingjing
Set-LocalUser -PasswordNeverExpires 1 -Name zhaoruxia
Set-LocalUser -PasswordNeverExpires 1 -Name tianyuanming
Set-LocalUser -PasswordNeverExpires 1 -Name zhangxinran
Set-LocalUser -PasswordNeverExpires 1 -Name jiangxingchun
Set-LocalUser -PasswordNeverExpires 1 -Name guojing
Set-LocalUser -PasswordNeverExpires 1 -Name sunjianxing

Add-LocalGroupMember -Group 'Remote Desktop Users' -Member anzhipeng
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member liuyumeng
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member lvqian
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member quliwei
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member shenyaohui
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member wangguangliang
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member wanghe
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member wangshiyao
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member caojianping
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member chenyukun
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member guoshijie
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member leijianteng
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member lijufa
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member liyuanjun
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member songjingjing
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member zhaoruxia
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member tianyuanming
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member zhangxinran
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member jiangxingchun
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member guojing
Add-LocalGroupMember -Group 'Remote Desktop Users' -Member sunjianxing
```

