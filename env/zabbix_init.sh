#!/usr/bin/env bash

#####################################
# zabbix 监控初始化:
#
# @author : tao.dong
# @date : 2018-11-21
####################################

TAG_NAME="Name"
GROUP_NAME="Group"

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
EC2_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')

TAG_VALUE=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCE_ID}" "Name=key,Values=${TAG_NAME}" --region ${EC2_REGION} --output=text | cut -f5)
GROUP_VALUE=$(aws ec2 describe-tags --filters "Name=resource-id,Values=${INSTANCE_ID}" "Name=key,Values=${GROUP_NAME}" --region ${EC2_REGION} --output=text | cut -f5)
HOST_NAME=$(curl -s http://169.254.169.254/latest/meta-data/hostname)
PUBLIC_ADDRESS=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

. command/command_function.sh

SCRIPT_LOG "Init Zabbix Agent start ..."

wget http://mirrors.mobvista.com/os_init/zabbix-3.0.1-1.el6.x86_64.rpm
rpm -ivh zabbix-3.0.1-1.el6.x86_64.rpm

sed -i "/^Hostname=/s/=.*$/=${TAG_VALUE}_${PUBLIC_ADDRESS}_${HOST_NAME}/" /usr/local/zabbix/etc/zabbix_agentd.conf
sed -i "/HostMetadata=/s/=.*$/=LinuxMobvista_${GROUP_VALUE}/" /usr/local/zabbix/etc/zabbix_agentd.conf

/etc/init.d/zabbix_agentd restart

SCRIPT_LOG "Init Zabbix Agent success !!!"


