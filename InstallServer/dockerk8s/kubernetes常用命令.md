# kubernetes常用命令

# kubectl相关

### 命令

##### 1、基本命令

| 命令    | 作用             |
| ------- | ---------------- |
| create  | 创建资源         |
| edit    | 编辑资源         |
| get     | 获取资源         |
| patch   | 更新（修改）资源 |
| delete  | 删除资源         |
| explain | 展示资源文档     |





##### 2、运行/调试命令

| 命令      | 作用                  |
| --------- | --------------------- |
| run       | 在集群中运行指定镜像  |
| expose    | 暴露资源为service     |
| describe  | 展示资源内部信息      |
| logs      | 输出容器在pod中的日志 |
| attach    | 进入运行中的容器      |
| cp        | 在pod内外复制文件     |
| rollout   | 管理资源的发布        |
| scale     | 扩/缩容Pod数量        |
| autoscale | 自动调整pod数量       |



### 资源分类

##### 1、集群级别资源



| 资源名称  | 缩写 | 说明     | 资源作用     |
| --------- | ---- | -------- | ------------ |
| nodes     | no   | node节点 | 集群组成部分 |
| namespace | ns   | 命名空间 | 隔离Pod      |





##### 2、pod资源

| 资源名称 | 缩写 | 说明 | 资源作用           |
| -------- | ---- | ---- | ------------------ |
| pods     | po   | pod  | 装载容器的最小单元 |



##### 3、pod资源控制器

| **资源名称**             | **缩写** | **说明** | **资源作用** |
| ------------------------ | -------- | -------- | ------------ |
| replicationcontroller    | rc       |          | 控制pod资源  |
| replicasets              | rs       |          | 控制pod资源  |
| daemonsets               | ds       |          | 控制pod资源  |
| jobs                     |          |          | 控制pod资源  |
| cronjobs                 | cj       |          | 控制pod资源  |
| horizontalpodautoscalers | hpa      |          | 控制pod资源  |
| statefulsets             | sts      |          | 控制pod资源  |





##### 4、服务发现资源



| 资源名称 | 缩写 | 说明 | 资源作用        |
| -------- | ---- | ---- | --------------- |
| services | svc  | 服务 | 统一pod对外接口 |
| ingress  | ing  |      | 统一pod对外接口 |



| 参数 | 说明                                                         |
| ---: | ------------------------------------------------------------ |
|   -A | 展示所有                                                     |
|   -f | 指定文件                                                     |
|   -k | 处理kustomization目录。此标志不能与-f或-R一起使用。          |
|   -L | 指定标签lebel                                                |
|   -o | 指定输出格式，常用的有json、yaml、wide(详细列表)             |
|   -R | 递归处理-f，–filename中使用的目录。在需要管理时非常有用      |
|   -l | 要进行筛选的选择器（只支持标签查询），支持“=”、“=”和“！=”。（例如-l键1=value1，键2=value2）用法示例：`kubectl get pod -l "key=value"` |
|   -w | 持续跟踪命令的状态或者事件变化，类似`tail -f`功能            |
|   -n | 指定命名空间,`--namepace`的缩写                              |
|   -i | 即使未连接任何组件，也要保持pod中容器上的stdin打开。         |
|   -t | 为pod中的每个容器分配了一个tty。                             |



### 资源管理方式

命令行敲出的指令分为2种，

- 其中`kubectl`、`run`、`create`、`apply` 等等都是命令，
- 前面带`-`或者`--`的都是参数，比如`--port`、`-image`、`-n`



**资源管理方式分类**

| 类型           | 操作对象 | 适用环境 | 优点         | 缺点                           | 使用频率 |
| -------------- | -------- | -------- | ------------ | ------------------------------ | -------- |
| 命令式对象管理 | 对象     | 测试     | 简单         | 只操作活动对象，无法审计、跟踪 | 较少     |
| 命令式对象配置 | 文件     | 开发     | 可以审计跟踪 | 项目大时，配置文件多，操作麻烦 | 常用     |
| 声明式对象配置 | 目录     | 开发     | 支持目录操作 | 意外情况下难以调试             | 较少     |

##### 1、命令式对象管理

直接使用命令去操作k8s资源，命令和参数一起出现

```
kubectl run nginx-pod --image=nginx:1.17.1 --port=80
```



##### 2、命令式对象配置

通过命令和配置文件去操作作k8s资源，命令还是那个命令，只不过参数都放在配置文件里面

```
kubectl create/patch -f nginx-pod.yaml
```



##### 3、声明式对象配置

```
kubectl apply -f nginx-pod.yaml
```

使用apply创建资源，

- 如果资源不存在，就创建，相当于执行`kubectl create -f nginx-pod.yaml`
- 如果资源存在，就修改，相当于执行`kubectl patch -f nginx-pod.yaml`

### node

##### 1、获取所有节点



```shell
[root@k8s-master ~]# kubectl get nodes
NAME              STATUS    ROLES     AGE       VERSION
192.168.162.129   Ready     <none>    1d        v1.10.13
192.168.162.130   Ready     <none>    1d        v1.10.13


NAME ： 节点名称

STATUS ：节点状态
		Ready ： 已就绪
		NotReady：未就绪
		
ROLES ：角色

AGE：运行时长，从启动到现在运行了多长时间

VERSION ： 版本
```















