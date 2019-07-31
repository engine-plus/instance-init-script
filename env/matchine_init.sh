#!/usr/bin/env bash

####
# 机器环境初始化脚本
# @author : tao.dong
# @date : 2018-08-09
#
# $1 : ec2_type 根据不同的机器类型创建执行特定的初始化脚本
####


if [ $# -lt 1 ]
then
  echo "[ERROR] command : {command_bash ec2_type}"
  exit -1
fi

EC2_TYPE=$1
INIT_SCRIPT="/etc/rc.d/rc.local"

. command/command_function.sh

# 创建目标目录
mkdir -p ${LOG_DIR}
chmod 0777 -R ${LOG_DIR}

SCRIPT_LOG "[INFO] init machine enviorment start"

rm -rf /mnt
mkdir /mnt

SCRIPT_LOG "[INFO] init machine dist start"

SCRIPT_FILE=""

if [ ${EC2_TYPE} = "h1.4xlarge" ]
then
  SCRIPT_FILE="env/disk/h1.4xlarge_init.sh"
elif [ ${EC2_TYPE} = "m5d.4xlarge" ]
then
  SCRIPT_FILE="env/disk/m5d.4xlarge_init.sh"
elif [ ${EC2_TYPE} = "m4.4xlarge" ]
then
  SCRIPT_FILE="env/disk/m4.4xlarge_init.sh"
fi

bash ${SCRIPT_FILE}

cat ${SCRIPT_FILE} >> ${INIT_SCRIPT}

# Disable THP
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/transparent_hugepage/enabled

echo 'echo never > /sys/kernel/mm/transparent_hugepage/defrag' >> ${INIT_SCRIPT}
echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> ${INIT_SCRIPT}

chmod 0755 ${INIT_SCRIPT}



sed -i '/^\/dev.*/d' /etc/fstab

SCRIPT_LOG "[INFO] init machine dist success"

# 删除无效或错误的主机域名
sed -i '/.*ip.*/d' /etc/hosts

SCRIPT_LOG "[INFO] init machine enviorment success"