# zabbix

## 1. 什么是 Zabbix

**说明：本文档是阅读官方文档后增删改查而写出。如有看不懂地方，可以阅读官方 [abbix使用手册](https://www.zabbix.com/documentation/current/zh/manual/introduction/about)**

Zabbix 由 Alexei Vladishev 创建，目前由 Zabbix SIA 主导开发和支持。

Zabbix 是一个企业级的开源分布式监控解决方案。

Zabbix 是一款监控网络的众多参数以及服务器、虚拟机、应用程序、服务、数据库、网站、云等的健康和完整性的软件。Zabbix 使用灵活的通知机制，允许用户为几乎任何事件配置基于电子邮件的告警，以实现对服务器问题做出快速反应。Zabbix 基于存储的数据提供出色的报告和数据可视化功能。这使得 Zabbix 成为容量规划的理想选择。

Zabbix 支持轮询和 trapping。所有 Zabbix 报告和统计数据以及配置参数都可以通过基于 Web 的前端访问。基于 Web 的前端确保可以从任何位置评估您的网络状态和服务器的健康状况。如果配置得当，不管对于拥有少量服务器的小型组织还是拥有大量服务器的大公司来讲，Zabbix 都可以在监控 IT 基础设施方面发挥重要作用。

Zabbix 是免费的。Zabbix 是在 GPL 通用公共许可证第 2 版下编写和分发的。这意味着它的源代码是免费分发的，可供公众使用。

## 2. Zabbix 功能

**Zabbix 是一个高度集成的网络监控解决方案，在一个软件包中提供了多种功能。**

**[数据收集](https://www.zabbix.com/documentation/current/zh/manual/config/items)**

- 可用性和性能检查
- 支持 SNMP（trapping 和 polling）、IPMI、JMX、VMware监控
- 自定义检查
- 以自定义间隔收集所需数据
- 由 server/proxy 和 agents 执行

**[灵活的阈值定义](https://www.zabbix.com/documentation/current/zh/manual/config/triggers)**

- 可以定义非常灵活的问题阈值，称为触发器，从后端数据库引用值

**[高度可配置的告警](https://www.zabbix.com/documentation/current/zh/manual/config/notifications)**

- 可以针对升级计划、收件人、媒体类型自定义发送通知
- 使用宏可以使通知变得有意义和有用
- 自动化操作包括执行远程命令

**[实时图形](https://www.zabbix.com/documentation/current/zh/manual/config/visualization/graphs/simple)**

- 采集到的监控项值可以使用内置的绘图功能立即绘图

**[网络监控功能](https://www.zabbix.com/documentation/current/zh/manual/web_monitoring)**

- Zabbix 可以跟踪网站上的模拟鼠标点击路径并检查功能和响应时间

**[广泛的可视化选项](https://www.zabbix.com/documentation/current/zh/manual/config/visualization)**

- 创建自定义图形的能力，可以将多个监控项组合成一个聚合图形
- 网络拓扑图
- 在仪表盘中显示幻灯片
- 报表
- 受监控资源的高级（业务）视图

**[历史数据存储](https://www.zabbix.com/documentation/current/zh/manual/installation/requirements#database-size)**

- 存储在数据库中的数据
- 可配置的历史（保留趋势）
- 内置管家程序

**[建议的配置](https://www.zabbix.com/documentation/current/zh/manual/config/hosts)**

- 将受监控的设备添加为主机
- 一旦主机被数据库添加，就会开始进行数据采集
- 将模板应用于受监控的设备

**[模板的使用](https://www.zabbix.com/documentation/current/zh/manual/config/templates)**

- 在模板中分组检查
- 模板可以继承其他模板

**[网络发现](https://www.zabbix.com/documentation/current/zh/manual/discovery)**

- 网络设备自动发现
- agent 自动注册
- 发现文件系统、网络接口和 SNMP OID

**[便捷的 web 界面](https://www.zabbix.com/documentation/current/zh/manual/web_interface)**

- 基于web的PHP前端
- 可从任何地方访问
- 可以通过你的方式点击（到任何页面）
- 审计日志

**[Zabbix API](https://www.zabbix.com/documentation/current/zh/manual/api)**

- Zabbix API 为 Zabbix 提供可编程接口，用于大规模操作、第 3 方软件集成和其他用途。

**[权限系统](https://www.zabbix.com/documentation/current/zh/manual/config/users_and_usergroups)**

- 安全用户认证
- 某些用户可以被限制仅访问某些视图

**[全功能且易于扩展的 agent](https://www.zabbix.com/documentation/current/zh/manual/concepts/agent)**

- 部署在被监控目标上
- Linux 和 Windows 操作系统都适用于

**[二进制守护进程](https://www.zabbix.com/documentation/current/zh/manual/concepts/server)**

- 用 C 编写，用于提高性能和减少内存占用
- 轻量级、便携

**[为复杂环境做好准备](https://www.zabbix.com/documentation/current/zh/manual/distributed_monitoring)**

- 使用 Zabbix proxy 轻松实现远程监控

## 3. Zabbix 概述

### 结构体系

Zabbix 由几个主要的软件组件组成。他们的职责概述如下。

#### Server

[Zabbix server](https://www.zabbix.com/documentation/current/zh/manual/concepts/server) 是 agents 向其报告可用性和完整性信息和统计信息的中心组件。server 是存储所有配置、统计和操作数据的中央存储库。

#### 数据存储

Zabbix 收集的所有配置信息以及数据都存储在数据库中。

#### Web 界面

为了从任何地方和任何平台轻松访问，Zabbix 提供了基于 Web 的界面。该接口是 Zabbix server 的一部分，通常（但不一定）与 server 运行在同一台设备上。

#### Proxy

[Zabbix proxy](https://www.zabbix.com/documentation/current/zh/manual/concepts/proxy) 可以代替 Zabbix server 收集性能和可用性数据。proxy 是 Zabbix 部署的可选部分；但是对于分散单个 Zabbix server 的负载非常有用。

#### Agent

Zabbix agent 部署在被监控目标上，以主动监控本地资源和应用程序，并将收集到的数据报告给 Zabbix server。从 Zabbix 4.4 开始，有两种类型的 agent 可用：[Zabbix agent](https://www.zabbix.com/documentation/current/zh/manual/concepts/agent) （轻量级，在许多平台上支持，用 C 编写）和 [Zabbix agent 2](https://www.zabbix.com/documentation/current/zh/manual/concepts/agent) （非常灵活，易于使用插件扩展，用 Go 编写）。

#### 数据流

此外，回顾一下 Zabbix 中的整体数据流也是很重要的。为了创建一个收集数据的监控项，必须首先创建一个主机。另一方面 Zabbix 必须首先拥有一个监控项来创建触发器。必须有触发器才能创建动作。因此，如果你想收到 *服务器 X* 上的 CPU 负载过高的警报，必须首先为 *服务器 X* 创建一个主机条目，然后创建一个用于监控其 CPU 的监控项，然后是一个触发器，如果 CPU 过高则触发动作，然后通过通过动作操作向您发送电子邮件。这可能看起来像很多步骤，其实使用模板并不需要。而且，由于这种设计，可以自定义创建非常灵活的设置。

## 4. 定义

### Zabbix 中一些常用术语的含义。

**host（主机）:** 要通过 IP/DNS 监控的联网设备。

**host group（主机组）:** 主机的逻辑分组；它可能包含主机和模板。主机组中的主机和模板没有以任何方式相互链接。在为不同用户组分配主机访问权限时使用主机组。

**item（监控项）:**你想要接收的主机的特定数据，一个度量/指标数据。

**value preprocessing（值预处理）:**  在数据存入数据库之前转化/预处理接收到的指标数据。

**trigger（触发器）:** 一个被用于定义问题阈值和 "评估" 控项接收到的数据的逻辑表达式。 当接收到的数据高于阈值时，触发器从 'Ok' 变成 'Problem' 状态。当接收到的数据低于阈值时，触发器保留/返回 'Ok' 的状态。

**event（事件）:**  一次发生的需要注意的事情，例如 触发器状态改变、自动发现/agent 自动注册。

**event tag（事件标签）:**  预设的事件标记 可以被用于事件关联，权限细化设置等。

**event correlation（事件关联）:** 一种灵活而精确地将问题与其解决方法联系起来的方法比如说，你可以定义触发器A告警的异常可以由触发器B解决，触发器B可能采用完全不同的数据采集方式。

**problem（问题）:** 一个处在 "问题" 状态的触发器。

**problem update（问题更新）:** Zabbix 提供的问题管理选项，例如添加评论、确认、更改严重性或手动关闭。

**action（动作）:** 对事件作出反应的预先定义的方法。一个动作由多个操作（例如发送通知)）和条件（什么情况下 执行操作）组成。

**escalation（升级):**  用于在动作中执行操作的自定义场景；发送通知/执行远程命令的序列。

**media（媒体）:** 发送告警通知的渠道；传输媒介。

**notification（通知）** 通过选定的媒体通道发送给用户的关于某个事件的消息。

**remote command（远程命令）**  在某些条件下在受监控主机上自动执行的预定义命令。

**template（模板）**  可以应用于一个或多个主机的一组实体集 （包含监控项、触发器、图表、低级别自动发现规则、web场景等）。 模版的应用使得主机上的监控任务部署快捷方便；也可以使监控任务的批量修改更加简单。模版是直接关联到每台单独的主机上。

**web scenario（web 场景）**  检查一个网站的可用性的一个或多个HTTP请求。

**frontend（前端）** Zabbix的web界面。

**dashboard（仪表盘）**  web界面的可定制部分，以可视化的单元（又叫小部件）显示重要信息的摘要和可视化。

**widget（小部件）** 在仪表板中使用的显示某种类型和来源的信息（摘要、地图、图表、时钟等）的可视化单元。

**Zabbix API:**  Zabbix API 允许您使用 JSON RPC 协议来创建、更新和获取 Zabbix 对象（如主机、监控项、图表等）或执行任何其他自定义任务。

**Zabbix server:**  Zabbix 软件的中央进程，执行监控、与 Zabbix proxy 和 agent 交互、计算触发器、发送通知；数据的中央存储库。

**Zabbix proxy:** 一个可以代表 Zabbix server 收集数据的进程，减轻 server 的一些处理负载。

**Zabbix agent:**  部署在被监控目标上以主动监控本地资源和应用程序的进程。

**Zabbix agent 2:** 新一代 Zabbix agent，主动监控本地资源和应用程序，允许使用自定义插件进行监控。

因为 Zabbix agent 2 与 Zabbix agent 共享许多功能，所以如果功能行为相同，文档中的术语 "Zabbix agent" 同时代表 Zabbix agent 和 Zabbix agent 2。Zabbix agent 2 仅在其功能不同的地方特别命名。

**encryption:** （加密- 使用传输层安全 (TLS) 协议 支持Zabbix组件（server，proxy，agent，zabbix_sender 和 zabbix_get 实用程序）之间的加密通信 。

**network discovery（网络发现）:** 网络设备的自动发现。

**low-level discovery（低级别自动发现）:** 自动发现特定设备上的底层实体（例如：文件系统、网络接口等)

**low-level discovery rule（自动别自动发现规则）:**用于在设备上自动发现低级别实体的一组定义。

**item prototype（监控项原型）:** 带有某些参数作为变量的度量，为低级别自动发现做好了准备。* 在低级别自动发现之后，变量被自动替换为实际发现的参数，度量标准自动开始收集数据。

**trigger prototype（触发器原型）:**以某些参数作为变量的触发器，为低级别自动发现做好准备。 在低级别自动发现之后，变量被自动替换为实际发现的参数，触发器自动开始计算数据。

其他一些 Zabbix 实体的 *原型* 也在低级别自动发现中使用 - 图形原型、主机原型、主机组原型。

**agent autoregistration（agent 自动注册）:** Zabbix agent 自动注册为主机 并开始监控的自动化过程。

