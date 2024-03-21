### Kolla部署trove

```bash
Kolla部署trove

1. 开启kolla部署trove enable_horizon_trove取消这一行的注释 enable_trove: no改成yes
   enable_horizon_trove: "{{ enable_trove | bool }}"
   enable_trove: "yes"
2. 修改trove的模板配置文件 (1). /usr/share/kolla-ansible/ansible/roles/trove/templates/trove.conf.j2
   [default] 部分添加如下参数：
   trove_auth_url = http://10.252.0.100:5000/v3
   max_volumes_per_tenant = 4096
   max_accepted_volume_size = 4096
   volume_fstype = ext4
   volumes = -1
   backups = -1
   instances = -1

# Maximum time (in seconds) to wait for Guest Agent 'quick'

agent_call_low_timeout = 30

# Maximum time (in seconds) to wait for a cluster to become active.

cluster_usage_timeout = 1800

# Maximum time (in seconds) to wait for a Guest to become active.

usage_timeout = 600

# Maximum time (in seconds) to wait for taking a Guest Agent replication snapshot.

agent_replication_snapshot_timeout = 1800

# Maximum time (in seconds) to wait for a service to become alive.

timeout_wait_for_service=600

# If set, use this value for pool_timeout with SQLAlchemy.

pool_timeout = 120
#Page size for listing users
users_page_size=1000

# Page size for listing databases

databases_page_size=1000

# Page size for listing instances

instances_page_size=1000

# Page size for listing clusters

clusters_page_size=1000

# Page size for listing backups.

backups_page_size=1000

# Page size for listing configurations.

configurations_page_size=1000

# Page size for listing modules.

modules_page_size=1000
agent_heartbeat_time = 60
reboot_time_out = 60
[database] 部分添加如下
idle_timeout = 3600
pool_timeout = 120
max_retries = 5
在末尾添加如下参数：
[mysql]
root_on_create = False
tcp_ports = 3306
volume_support = True
ignore_users = os_admin, root
ignore_dbs = mysql, information_schema, performance_schema
[redis]
tcp_ports = 6379, 16379
volume_support = True
cluster_support = False
[mongodb]
tcp_ports = 2500, 27017, 27019
volume_support = True
num_config_servers_per_cluster = 1
num_query_routers_per_cluster = 1
cluster_support = False
(2). 修改trove-conductor.conf.j2 ，在database部分添加pool_timeout = 120
[DEFAULT]
trove_auth_url = http://10.252.0.100:5000/v3
#control_exchange = trove
[database]
connection = mysql+pymysql://{{ trove_database_user }}:{{ trove_database_password }}@{{ trove_database_address }}/{{ trove_database_name }}
max_retries = -1
pool_timeout = 120
(3). 修改trove-taskmanager.conf.j2 database部分,添加数据库超时
[DEFAULT]
trove_auth_url = http://10.252.0.100:5000/v3
idle_timeout = 3600
pool_timeout = 120

3. kolla部署trove, 注意查看multinode中的要部署的节点
   [root@controller1 trove-api]# cat /home/multinode|grep trove -C 3

# trove部署到了控制节点，注意这里control，如果是单个节点，添加节点的即可。例如computer1

[trove:children]
control

# Trove

[trove-api:children]
trove
[trove-conductor:children]
trove
[trove-taskmanager:children]
trove
kolla-ansible deploy -i ./multinode -t trove --limit

4. kolla在部署trove有些缺陷，修改trove的docker启动文件config.json并且，需要将如下配置文件添加到trove相应的配置目录。 由
   于配置文件相同，所以修改一个节点后，同步到其他的节点即可。
   添加api-paste.ini到每个trove节点的trove服务的目录，例如，controller1，controller2，controller3都部署了trove-api、troveconductor、trove-taskmanager服务，需要到每个节点的每个每个服务下面创建api-paste.ini文件,修改配置文件中的auth_url一小
   段为openstack相应的keystone的url和trove的密码。
   [composite:trove]
   use = call:trove.common.wsgi:versioned_urlmap
   /: versions
   /v1.0: troveapi
   [app:versions]
   paste.app_factory = trove.versions:app_factory
   [pipeline:troveapi]
   pipeline = cors http_proxy_to_wsgi faultwrapper osprofiler authtoken authorization contextwrapper ratelimit extensions troveapp
   #pipeline = debug extensions troveapp
   [filter:extensions]
   paste.filter_factory = trove.common.extensions:factory
   [filter:authtoken]
   paste.filter_factory = keystonemiddleware.auth_token:filter_factory

# 需要修改相应的值

auth_url = http://172.16.100.100:5000/v3
admin_user = trove
admin_password = GW5mGb
admin_tenant_name = service
[filter:authorization]
paste.filter_factory = trove.common.auth:AuthorizationMiddleware.factory
[filter:cors]
paste.filter_factory = oslo_middleware.cors:filter_factory
oslo_config_project = trove
[filter:contextwrapper]
paste.filter_factory = trove.common.wsgi:ContextMiddleware.factory
[filter:faultwrapper]
paste.filter_factory = trove.common.wsgi:FaultWrapper.factory
[filter:ratelimit]
paste.filter_factory = trove.common.limits:RateLimitingMiddleware.factory
[filter:osprofiler]
paste.filter_factory = osprofiler.web:WsgiMiddleware.factory
[app:troveapp]
paste.app_factory = trove.common.api:app_factory
#Add this filter to log request and response for debugging
[filter:debug]
paste.filter_factory = trove.common.wsgi:Debug
[filter:http_proxy_to_wsgi]
use = egg:oslo.middleware#http_proxy_to_wsgi
修改每个节点每个服务配置文件目录下面config.json
shell> cat /etc/kolla/trove-api/config.json
{
"command": "trove-api --config-file=/etc/trove/trove.conf",
"config_files": [
{
"source": "/var/lib/kolla/config_files/trove.conf",
"dest": "/etc/trove/trove.conf",
"owner": "trove",
"perm": "0600"
},{
"source": "/var/lib/kolla/config_files/api-paste.ini",
"dest": "/etc/trove/api-paste.ini",
"owner": "trove",
"perm": "0600"
}
],
"permissions": [
{
"path": "/var/log/kolla/trove",
"owner": "trove:trove",
"recurse": true
}
]
}
shell> cat /etc/kolla/trove-conductor/config.json
{
"command": "trove-conductor --config-file=/etc/trove/trove-conductor.conf",
"config_files": [
{
"source": "/var/lib/kolla/config_files/trove.conf",
"dest": "/etc/trove/trove.conf",
"owner": "trove",
"perm": "0600"
},
{
"source": "/var/lib/kolla/config_files/trove-conductor.conf",
"dest": "/etc/trove/trove-conductor.conf",
"owner": "trove",
"perm": "0600"
},{
"source": "/var/lib/kolla/config_files/api-paste.ini",
"dest": "/etc/trove/api-paste.ini",
"owner": "trove",
"perm": "0600"
}
],
"permissions": [
{
"path": "/var/log/kolla/trove",
"owner": "trove:trove",
"recurse": true
},
{
"path": "/var/lib/trove",
"owner": "trove:trove",
"recurse": true
}
]
}
shell> cat /etc/kolla/trove-taskmanager/config.json
{
"command": "trove-taskmanager --config-file=/etc/trove/trove-taskmanager.conf",
"config_files": [
{
"source": "/var/lib/kolla/config_files/trove.conf",
"dest": "/etc/trove/trove.conf",
"owner": "trove",
"perm": "0600"
},
{
 kolla在部署trove-conductor的时候，在配置文件中添加了rabbitmq exchange，而trove默认的exhange是openstack，所以在conductor接收不到trove
—guestagent广播的服务状态。创建数据库实例一直在building。
"source": "/var/lib/kolla/config_files/trove-taskmanager.conf",
"dest": "/etc/trove/trove-taskmanager.conf",
"owner": "trove",
"perm": "0600"
},{
"source": "/var/lib/kolla/config_files/trove-guestagent.conf",
"dest": "/etc/trove/trove-guestagent.conf",
"owner": "trove",
"perm": "0600"
},{
"source": "/var/lib/kolla/config_files/api-paste.ini",
"dest": "/etc/trove/api-paste.ini",
"owner": "trove",
"perm": "0600"
}
],
"permissions": [
{
"path": "/var/log/kolla/trove",
"owner": "trove:trove",
"recurse": true
},
{
"path": "/var/lib/trove",
"owner": "trove:trove",
"recurse": true
}
]
}
(2). trove-taskmanager目录添加trove-guestagent.conf配置文件 注意修改{{}}部分的变量
transport_url: rabbitmq连接地址 trove_auth_url：keystone 的url地址 swift_url： swift 的url os_region_name： region name
[DEFAULT]
debug = True
log_dir = /var/log/trove/
log_file = trove-guestagent.log
transport_url = {{ rpc_transport_url }}
trove_auth_url = {{ internal_protocol }}://{{ kolla_internal_fqdn }}:{{ keystone_public_port }}/v3
swift_url = http://{{ kolla_internal_fqdn }}:8080/v1/AUTH_
os_region_name = {{ openstack_region_name }}
datastore_registry_ext = mysql:trove.guestagent.datastore.mysql.manager.Manager, percona:trove.guestagent.datastore.mysql.manager.Manager,
mariadb:trove.guestagent.datastore.experimental.mariadb.manager.Manager,mongodb:trove.guestagent.datastore.experimental.mongodb.manager.Manager,redis:trove.guestage
root_grant = ALL
root_grant_option = True
default_password_length = 16
swift_service_type = object-store
torage_strategy = SwiftStorage
storage_namespace = trove.common.strategies.storage.swift
backup_swift_container = database_backups
backup_use_gzip_compression = True
backup_use_openssl_encryption = True
backup_aes_cbc_key = "default_aes_cbc_key"
backup_use_snet = False
backup_chunk_size = 65536
backup_segment_max_size = 2147483648
volume_fstype = ext4
[mysql]
backup_strategy = MySQLDump
backup_namespace = trove.guestagent.strategies.backup.mysql_impl
restore_namespace = trove.guestagent.strategies.restore.mysql_impl
replication_strategy = MysqlBinlogReplication
replication_namespace = trove.guestagent.strategies.replication.mysql_binlog
mount_point = /var/lib/mysql
[redis]
backup_strategy = RedisBackup
backup_namespace = trove.guestagent.strategies.backup.experimental.redis_impl
restore_namespace = trove.guestagent.strategies.restore.experimental.redis_imp

5. 最后验证，如果镜像已经上传，并且已经关联完毕，可以开始创建数据库服务测试。

# 注释或者删除这行

control_exchange = trove
添加对mysql5.7的支持:

1. 镜像的修改，在这里不做描述和记录了。
2. 修改trove_taskmanager容器中的mysql模板

# 切换到如下目录创建mysql5.7的目录

/var/lib/kolla/venv/lib/python2.7/site-packages/trove/templates/mysql
mkdir mysqsl5.7

# copy config.template 到mysql5.7目录，然后添加关闭密码验证的参数:

validate_password = off

3. 字符集不支持['utf8mb4', 'utf16', 'utf16le', 'utf32']
   需要修改源码：trove/common/db/mysql/data.py目录中的字典。

# vim /home/trove/trove/ven/lib/python2.7/site-packages/trove/common/db/mysql/data.py

vi /var/lib/kolla/venv/lib/python2.7/site-packages/trove/common/db/mysql/data.py

# 最新的master分支已经更新

https://raw.githubusercontent.com/openstack/trove/master/trove/common/db/mysql/data.py

4. 修改mysql5.7镜像不支持主从语句的bug
   ! 注意： 已经在镜像制作的过程中修改： 注释掉原来的语句，mysql5.7在查询主从状态的时候已经不用SHOW GLOBAL STATUS like
   'slave_running'查询。

# vim /home/trove/trove/ven/lib/python2.7/site-packages/trove/guestagent/datastore/mysql_common/service.py

def verify_slave_status():
#actual_status = client.execute(

# "SHOW GLOBAL STATUS like 'slave_running'").first()[1]

#return actual_status.upper() == status.upper()
actual_status = client.execute('select SERVICE_STATE from performance_schema.replication_applier_status;').first()[0]
bctual_status = client.execute('select SERVICE_STATE from performance_schema.replication_connection_status;').first()[0]
LOG.debug("xxxxxxxx: actual_status: %s"%actual_status)
LOG.debug("xxxxxxxx: bctual_status: %s"%bctual_status)
if actual_status.upper() == status.upper() and bctual_status == status.upper():
return True
else:
return False
docker cp 5.7 trove_api:/var/lib/kolla/venv/lib/python2.7/site-packages/trove/templates/mysql/
docker cp 5.7 trove_conductor:/var/lib/kolla/venv/lib/python2.7/site-packages/trove/templates/mysql/
docker cp 5.7 trove_taskmanager:/var/lib/kolla/venv/lib/python2.7/site-packages/trove/templates/mysql/
docker cp mysql trove_api:/var/lib/kolla/venv/lib/python2.7/site-packages/trove/common/db/
docker cp mysql trove_conductor:/var/lib/kolla/venv/lib/python2.7/site-packages/trove/common/db/
docker cp mysql trove_taskmanager:/var/lib/kolla/venv/lib/python2.7/site-packages/trove/common/db/
```


