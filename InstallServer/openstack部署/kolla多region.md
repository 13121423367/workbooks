RegionONE：

 

vim /etc/kolla/globals.yml

 

kolla_internal_vip_address: "172.16.103.49"

 

openstack_region_name: "RegionOne"

 

multiple_regions_names:

​        \- "{{ openstack_region_name }}"

​        \- "RegionTwo"

 

enable_keystone: "yes"

enable_horizon: "yes"

 

 

RegionTWO：

 

vim /etc/kolla/globals.yml

 

 

kolla_internal_vip_address: "172.16.103.37"

 

kolla_internal_fqdn_r1: "172.16.103.49"

 

openstack_region_name: "RegionTwo"

 

node_custom_config: "/etc/kolla/config"

 

keystone_admin_url: "{{ admin_protocol }}://{{ kolla_internal_fqdn_r1 }}:{{ keystone_admin_port }}"

keystone_internal_url: "{{ internal_protocol }}://{{ kolla_internal_fqdn_r1 }}:{{ keystone_public_port }}"

 

openstack_auth:

​        auth_url: "{{ admin_protocol }}://{{ kolla_internal_fqdn_r1 }}:{{ keystone_admin_port }}"

​        username: "admin"

​        password: "{{ keystone_admin_password }}"

​        project_name: "admin"

​        domain_name: "default"

 

enable_keystone: "no"

enable_horizon: "no"

 

mkdir /etc/kolla/config/

 

vim /etc/kolla/config/ceilometer.conf

 

[service_credentials]

auth_url = {{ keystone_internal_url }}

 

vim /etc/kolla/config/heat.conf

 

[DEFAULT]

region_name_for_services = RegionTwo  

[trustee]

www_authenticate_uri = {{ keystone_internal_url }}

auth_url = {{ keystone_internal_url }}

 

[ec2authtoken]

www_authenticate_uri = {{ keystone_internal_url }}

 

[clients_keystone]

www_authenticate_uri = {{ keystone_internal_url }}

 

vim /etc/kolla/config/mistral.conf

 

[keystone_authtoken]

auth_uri = {{ keystone_internal_url }}/v3

auth_url = {{ keystone_admin_url }}/v3

[openstack_actions]

default_region = RegionTwo

 

vim /etc/kolla/config/nova.conf

 

[placement]

auth_url = {{ keystone_admin_url }}

 

 

vim /etc/kolla/config/global.conf

 

[keystone_authtoken]

www_authenticate_uri = {{ keystone_internal_url }}

auth_url = {{ keystone_admin_url }}

 

scp root@172.16.103.49:/etc/kolla/passwords.yml /etc/kolla/passwords.yml

 

 

 

坑点：

1.所有region中要使用同一个passwords.yml

2.admin-openrc.sh   中region要自己修改

 

 

 

 

基于现有环境 添加Region

 

1.现有环境添加region

 

openstack region create HB2

 

2.添加endpoint

 

openstack endpoint create --region HB3 identity internal  [http://](http://172.16.103.49:5000/)[10.252.0.100](http://172.16.103.49:5000/)[:5000](http://172.16.103.49:5000/)

openstack endpoint create --region HB3 identity admin [http://](http://172.16.103.49:35357/)[10.252.0.100](http://172.16.103.49:35357/)[:35357](http://172.16.103.49:35357/)

openstack endpoint create --region HB3  identity public [http://](http://172.16.103.49:5000/)[10.252.0.100](http://172.16.103.49:5000/)[:5000](http://172.16.103.49:5000/)

 

3.后面按照RegionTwo继续往下走

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 