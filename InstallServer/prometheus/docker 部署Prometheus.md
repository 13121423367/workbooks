## docker 部署Prometheus

**1)、下载镜像**

```
docker pull prom/node-exporter
docker pull prom/prometheus
docker pull grafana/grafana
```



**2)、创建容器配置文件挂载启动容器**



```
mkdir /opt/prometheus && cd /opt/prometheus
vim prometheus.yml


global:
  scrape_interval:     60s
  evaluation_interval: 60s
scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['10.12.29.100:9090']
        labels:
          instance: prometheus
  - job_name: linux
    static_configs:
      - targets: ['10.12.29.101:9100']
  - job_name: windows
    static_configs:
      - targets: ['10.12.29.102:9100']
      - targets: ['10.12.29.103:9100']
      - targets: ['10.12.29.104:9100']


```

```
  docker run -it \
  	-d \
  	--name=prometheus \
    --restart=always \
    -p 9090:9090 \
	-v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml  \
    -v prometheus_data:/prometheus \
    -v /etc/localtime:/etc/localtime:ro \
    prom/prometheus
    
    
docker run -it -d --name=prometheus --restart=always -p 9090:9090 -v  /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml -v prometheus_data:/prometheus -v /etc/localtime:/etc/localtime:ro prom/prometheus
```

**3)、启动node节点**



```
docker run -d -p 9100:9100 \
  --restart=always \
  -v "/proc:/host/proc:ro" \
  -v "/sys:/host/sys:ro" \
  -v "/:/rootfs:ro" \
  --name 1.10 \
  --net="host" \
  prom/node-exporter
```



**4)、创建挂载目录启动grafana**

 ```
mkdir /opt/grafana-storage
chmod 777 -R /opt/grafana-storage

docker run -d \
  --restart=always \
  --name=grafana \
  -p 3000:3000 \
  -v /opt/grafana-storage:/var/lib/grafana \
  -e TZ=Asia/Shanghai \
  -e "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource" \
  grafana/grafana  

 ```



**5)、监控mysql数据库，数据库节点安装mysqld-exporter**

```
docker network create my-mysql-network
docker pull prom/mysqld-exporter

docker run -d \
  -p 9104:9104 \
  --restart always \
  --network my-mysql-network  \
  -e DATA_SOURCE_NAME="root:123456@(192.168.1.100:3306)/" \
  prom/mysqld-exporter
```





**6)、监控sql server数据库**

从阿里镜像安装、修改标签

```
docker pull registry.cn-hangzhou.aliyuncs.com/newbe36524/server:2019-latest
docker tag registry.cn-hangzhou.aliyuncs.com/newbe36524/server:2019-latest sql.server
mkdir /opt/mssql

docker run -itd \
    --net=host \
    --name sql.server \
    -e 'ACCEPT_EULA=Y' \
    -p 1433:1433 \
    -e 'MSSQL_PID=<HMWJ3-KY3J2-NMVD7-KG4JR-X2G8G>' \
    -e 'SA_PASSWORD=<ZAQ12wsx!>' \
    -v /opt/mssql:/var/opt/mssql \
    sql.server
```


https://github.com/awaragi/prometheus-mssql-exporter

监控SQL server数据库

docker pull awaragi/prometheus-mssql-exporter

docker run -d \
-e SERVER=10.150.100.107 \
-e USERNAME=SA \
-e PASSWORD=9Trk7uWTAvyT9HIN \
-p 4001:4000 \
--name prometheus-mssql-exporter2 \
awaragi/prometheus-mssql-exporter


mssql_instance_local_time 自纪元在本地实例上经过的秒数
mssql_connections{database,state} 活动连接数
mssql_deadlocks 自上次重启以来导致死锁的每秒锁请求数
mssql_user_errors 自上次重启以来的用户错误数/秒
mssql_kill_connection_errors 自上次重启以来的终止连接错误数/秒
mssql_log_growths{database} 数据库的事务日志在上次重新启动时被扩展的总次数
mssql_page_life_expectancy 指示页面在没有引用的情况下将在此节点上的缓冲池中停留的最小秒数。微软过去的传统建议是 PLE 应该保持在 300 秒以上
mssql_io_stall{database,type} 自上次重启以来停顿的等待时间 (ms)
mssql_io_stall_total{database} 自上次重启以来停顿的等待时间 (ms)
mssql_batch_requests 每秒接收的 Transact-SQL 命令批次数。此统计信息受所有约束（例如 I/O、用户数量、缓存大小、请求复杂性等）的影响。高批量请求意味着良好的吞吐量
mssql_page_fault_count 自上次重启以来的页面错误数
mssql_memory_utilization_percentage 内存利用率百分比
mssql_total_physical_memory_kb 以 KB 为单位的总物理内存
mssql_available_physical_memory_kb 可用物理内存 (KB)
mssql_total_page_file_kb 以 KB 为单位的总页面文件
mssql_available_page_file_kb 可用页面文件 (KB)





**7)、监控Windows主机性能**

1、运行windows_exporter-0.16.0-amd64  可直接在网页访问 127.0.0.1:9182 默认端口为9182

2、使用CMD命令方式启动   cmd执行  sc config windows_exporter start=delayed-auto	
我们还可以看看它的执行文件路径，里面就是它的启动命令了，原来默认端口是9182啊
 "C:\Program Files\windows_exporter\windows_exporter.exe" --log.format logger:eventlog?name=windows_exporter  --telemetry.addr :9182
从这里可以看出，wim_exporter的日志信息  --log.format logger:eventlog  放入了windows自带的 eventlog中去了；	  



Windows CMD查看端口
netstat -aon|findstr "9182"


查看被占用端口对应的PID
tasklist|findstr "3716"

结束进程 强制（/F参数）杀死 pid 为 9088 的所有进程包括子进程（/T参数）
taskkill /T /F /PID 9088 