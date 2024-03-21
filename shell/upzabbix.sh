#!/bin/bash

#########################################
#  by:xusx3				#
#  version:v2.0				#
#  本脚本为一键完成zabbix配置文件更改	#
#					#
#########################################
# 正则匹配ip地址
GREEN_COLOR='\e[32m'
YELLOW_COLOR='\e[33m'
RED_COLOR='\e[31m'
RESET_COLOR='\e[0m'
IP_PATTERN='^10(\.([0-9]|[0-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])){3}$'

while true; do
	echo -e "$YELLOW_COLOR请输入你要修复迁移的zabbix服务器IP和目标AZ,示例:\"${GREEN_COLOR}10.0.1.1 Linux-HETO1-PRD $RESET_COLOR \" \n "
    read -p "" _IP _AZ
	if [[ $_IP =~ $IP_PATTERN ]]; then
        break
    else
        echo -e "${RED_COLORIP}地址格式不规范,请重新输入！$RESET_COLOR"
    fi
done
echo -e "${YELLOW_COLOR}您要操作的IP地址为:${GREEN_COLOR}$_IP AZ为:${_AZ} $RESET_COLOR "

# 远程连接
execute_remote_cmd() {
    local _cmd="$1"
    sudo su - infomgr -c "ssh -n -o StrictHostKeyChecking=no  $_IP '${_cmd}'"
}

RPM_INSTALL(){
local install_cmd=
	if [ "${1}" = 6 ];then
			# Centos6/Redhat6/Oracle Linux6：
			install_cmd=sudo rpm -ivh http://10.122.49.186/lenovo_zabbix_agent_packages/zabbix-agent-for-lenovo-4.0.5-1.el6.x86_64.rpm
	elif [ "${1}" = 7 ];then
			# Centos7/Redhat7/Oracle Linux7:
			install_cmd=sudo rpm -ivh http://10.122.49.186/lenovo_zabbix_agent_packages/zabbix-agent-for-lenovo-4.0.5-1.el7.x86_64.rpm
	elif [ "${1}" = 8 ];then
			#Redhat 8:
			install_cmd=sudo rpm -ivh http://10.122.49.186/lenovo_zabbix_agent_packages/zabbix-agent-for-lenovo-4.0.5-1.el8.x86_64.rpm
	elif [ "${1}" = 11 ];then
			# SUSE11:
			install_cmd=sudo rpm -ivh http://10.122.49.186/lenovo_zabbix_agent_packages/zabbix-agent-for-lenovo-4.0.5-1.sle11.x86_64.rpm
	elif [ "${1}" = 12 ];then
			#SUSE12:
			install_cmd=sudo rpm -ivh http://10.122.49.186/lenovo_zabbix_agent_packages/zabbix-agent-for-lenovo-4.0.5-1.sle12.x86_64.rpm
	elif [ "${1}" = 15 ];then
			#SUSE 15:
			install_cmd=sudo rpm -ivh http://10.122.49.186/lenovo_zabbix_agent_packages/zabbix-agent-for-lenovo-4.0.5-1.sle15.x86_64.rpm
	fi;	
	execute_remote_cmd "${install_cmd}"
}

INSTALL_SERVICE(){
        # 检查远程服务器上的zabbix agent配置
        echo -e "${YELLOW_COLOR}${_IP}服务器当前未发生改变前的配置 $RESET_COLOR"
		result_config=$(execute_remote_cmd "sudo cat /usr/local/zabbix_agents/etc/zabbix_agentd.conf | grep -v ^$ | grep -v ^# | grep HostMetadata")
		if [ -z "$result_config" ]; then
			execute_remote_cmd "sudo cat /usr/local/zabbix_agents/etc/zabbix_agentd.conf | grep -v ^$ | grep -v ^#"
		else	
			execute_remote_cmd "sudo cat /usr/local/zabbix_agents/etc/zabbix_agentd.conf | grep -v ^$ | grep -v ^# | grep HostMetadata"
		fi
		
        # 检查远程服务器上的zabbix agent版本
        result1_version=$(execute_remote_cmd "rpm -qa | grep zabbix")
        if [[ -z ${result1_version} ]]; then
		local result_status=""
                echo -e "${YELLOW_COLOR} $_IP这台服务器安装的为旧版本zabbix，需要停止进程并安装新版本zabbix,正在为您安装 ...${RESET_COLOR}"
				execute_remote_cmd "sudo kill -9 $(ps -ef |grep zabbix_agent |grep -v grep |awk '{print $2}') "
				execute_remote_cmd "suso mv /usr/local/zabbix_agents /tmp"
                RPM_INSTALL "$1"
                execute_remote_cmd "sudo bash /usr/local/zabbix_agents/modifyConfig/modify_server_ip.sh $_AZ"
				echo -e "$YELLOW_COLOR $_IP 发生改变后的配置 $RESET_COLOR"
                execute_remote_cmd "sudo cat /usr/local/zabbix_agents/etc/zabbix_agentd.conf | grep -v ^$ | grep -v ^# | grep HostMetadata"
				result_status=$(execute_remote_cmd "sudo ps -ef |grep zabbix_agent |grep -v grep")
				if [[ -z ${result_status} ]]; then			
					echo -e "$RED_COLOR 失败，请手工排查 $RESET_COLOR"; exit 1
				else
					echo -e "$GREEN_COLOR 已成功安装完成 $RESET_COLOR " 
					echo -e "*********************************$(date)********************************************"
					exit 0

				fi	
        else
                echo -e "$YELLOW_COLOR $_IP 这台服务器安装的为新版本zabbix $RESET_COLOR "
                sudo su - infomgr -c "scp /home/infomgr/modify_server_ip_714.sh infomgr@$_IP:/tmp/ "
                execute_remote_cmd "sudo bash /tmp/modify_server_ip_714.sh $_AZ "
                # 检查修改后的配置
				echo -e "$YELLOW_COLOR $_IP 发生改变后的配置 $RESET_COLOR"				
                execute_remote_cmd "sudo cat /usr/local/zabbix_agents/etc/zabbix_agentd.conf | grep -v ^$ | grep -v ^# | grep HostMetadata"
				result_status=$(execute_remote_cmd "sudo ps -ef |grep zabbix_agent |grep -v grep")
				if [[ -z ${result_status} ]]; then			
					echo -e "$RED_COLOR 失败，请手工排查 $RESET_COLOR"; exit 1
				else
					echo -e "$GREEN_COLOR 已成功安装完成 $RESET_COLOR " 
					echo -e "*********************************$(date)********************************************"
					exit 0
				fi	
        fi
}

# 获取服务器的OS和VERSION
OS_TYPE=$(sudo su - infomgr -c "ssh -n -o StrictHostKeyChecking=no $_IP \
	'if [ -f /etc/os-release ]; then source /etc/os-release && echo \$ID | tr '[:upper:]' '[:lower:]'; \
	elif [ -f /etc/redhat-release ]; then awk '\''{print \$1}'\'' /etc/redhat-release | head -1 | tr '[:upper:]' '[:lower:]'; \
	elif [ -f /etc/oracle-release ]; then echo \"oracle\"; \
	elif [ -f /etc/SuSE-release ]; then echo \"suse\"; \
	elif [ -f /etc/debian_version ]; then echo \"debian\"; \
	else echo '\''没有查询到这个'\${_IP}'服务器的操作系统，请自行操作'\''; exit 1; fi'")
	
OS_VERSION=$(sudo su - infomgr -c "ssh -n -o StrictHostKeyChecking=no $_IP 'if [ -f /etc/os-release ]; then source /etc/os-release && echo \$VERSION_ID | grep -o -E '\''[0-9]+\.[0-9]|[0-9]'\'' | awk -F. '\''{print \$1}'\''; \
	elif [ -f /etc/redhat-release ]; then cat /etc/redhat-release | grep -o -E '\''[0-9]+\.[0-9]|[0-9]'\'' | awk -F. '\''{print \$1}'\''; \
	elif [ -f /etc/SuSE-release ]; then source /etc/SuSE-release && echo \$VERSION | grep -o -E '\''[0-9]+\.[0-9]|[0-9]'\'' | awk -F. '\''{print \$1}'\''; \
	elif [ -f /etc/debian_version ]; then cat /etc/debian_version | sed '\''s/[^0-9.]//g'\''; \
	else echo '\''没有查询到这个'\${_IP}'服务器的版本号，请自行操作'\''; exit 1; fi'")
	
# 判断操作系统来执行不同的安装命令	
case "$OS_TYPE" in 
	"centos"|"red"|"oracle")
		if [ "$OS_VERSION" -ge 6 ] && [ "$OS_VERSION" -lt 7 ]; then
			echo -e "当前服务器操作系统为 $OS_TYPE 6...\n开始进行安装"
			INSTALL_SERVICE 6
		elif [ "$OS_VERSION" -ge  7 ] && [ "$OS_VERSION" -lt 8 ]; then
			echo -e "当前服务器操作系统为 $OS_TYPE 7...\n开始进行安装"
			INSTALL_SERVICE 7
		elif [ "$OS_VERSION" -ge  8 ] && [ "$OS_VERSION" -lt 9 ]; then
			echo -e "当前服务器操作系统为 $OS_TYPE 8...\n开始进行安装"
			INSTALL_SERVICE 8
		fi
		;;
	"rocky")
		echo -e "当前服务器操作系统为 $OS_TYPE 8...\n开始进行安装"
		INSTALL_SERVICE 8
		;;
	"suse"|"sles")	
		if [ "$OS_VERSION" -ge 11 ] && [ "$OS_VERSION" -lt 12 ]; then
			echo -e "当前服务器操作系统为 $OS_TYPE 11...\n开始进行安装"
			INSTALL_SERVICE 11
		elif [ "$OS_VERSION" -ge 12 ] && [ "$OS_VERSION" -lt 13 ]; then
			echo -e "当前服务器操作系统为 $OS_TYPE 12...\n开始进行安装"
			INSTALL_SERVICE 12
		elif [ "$OS_VERSION" -ge 15 ] && [ "$OS_VERSION" -lt 16 ]; then
			echo -e "当前服务器操作系统为 $OS_TYPE 15...\n开始进行安装"
			INSTALL_SERVICE 15
		fi
		;;
	"debian")	
		if [[ "$OS_TYPE" == "debian" ]]; then
			echo -e "$RED_COLOR 当前服务器操作系统为 $OS_TYPE ，请手工安装$RESET_COLOR"
			exit 0
		fi
		;;
	*)
		echo -e "$RED_COLOR 当前操作系统为 $OS_TYPE $OS_VERSION 出现异常，请手工安装. $RESET_COLOR"
		exit 1
		;;		
esac
