# kubernetes证书

下载安装cfssl命令行工具

```shell
[root@dong bin]# wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 
[root@dong bin]# wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 
[root@dong bin]# wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 
[root@dong bin]# chmod +x cfssl*
[root@dong bin]# mv cfssl_linux-amd64 /usr/local/bin/cfssl
[root@dong bin]# mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
[root@dong bin]# mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
[root@dong bin]# export PATH=/usr/local/bin:$PATH

创建CA证书
```





创建存放证书目录

```shell
[root@dong bin]# mkdir -p /opt/kubernetes/ssl/
[root@dong bin]# cd /opt/kubernetes/ssl/
```







```shell
#创建证书配置文件
[root@dong ssl]# vim ca-config.json
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}

字段说明：

ca-config.json：可以定义多个 profiles，分别指定不同的过期时间、使用场景等参数；后续在签名证书时使用某个 profile；
signing：表示该证书可以签名其他证书；生成的ca.pem证书中 CA=TRUE；
server auth：表示client可以用该 CA 对server提供的证书进行验证；
client auth：表示server可以用该CA对client提供的证书进行验证；
expiry：过期时间
```





```shell
#创建CA证书签名请求文件

[root@dong ssl]# vim ca-csr.json
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ],
    "ca": {
       "expiry": "87600h"
    }
}
```



```shell
#创建CA证书签名请求文件

[root@dong ssl]# vim ca-csr.json
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ],
    "ca": {
       "expiry": "87600h"
    }
}
```




字段说明：

“CN”：Common Name，kube-apiserver 从证书中提取该字段作为请求的用户名 (User Name)；浏览器使用该字段验证网站是否合法；

“O”：Organization，kube-apiserver 从证书中提取该字段作为请求用户所属的组 (Group)；

生成CA证书和私钥

[root@dong ssl]# cfssl gencert -initca ca-csr.json | cfssljson -bare ca
[root@dong ssl]# ls | grep ca
ca-config.json
ca.csr
ca-csr.json
ca-key.pem
ca.pem
1.
2.
3.
4.
5.
6.
7.
其中ca-key.pem是ca的私钥，ca.csr是一个签署请求，ca.pem是CA证书，是后面kubernetes组件会用到的RootCA。
-----------------------------------
©著作权归作者所有：来自51CTO博客作者Wdddddddddd的原创作品，请联系作者获取转载授权，否则将追究法律责任
Kubernetes 之 二进制安装(二) 证书详解
https://blog.51cto.com/u_13210651/2361208