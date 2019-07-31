#!/usr/bin/env bash

###########################################################################################
# @desc : 安装 ambari-agent 服务
# @author : tao.dong
# @date : 2018-08-09
#
# $1 : ambari_version  : version for ambari server
# $2 : server_hostname : hostname for ambari server
# $3 : cluster_name    : cluster name for ambari
# $4 : user_key        : access key for user login
#########################################################################################

set -e

if [ $# -ne 4 ]
then
  echo "[ERROR] command : {command_bash ambari_version server_name, cluster_name, user_key}"
  exit -1
fi

AMBARI_VERSION=$1
SERVER_HOSTNAME=$2
CLUSTER_NAME=$3
USER_KEY=$4

EXPECTED_HOSTNAME=$(hostname -f)

SERVER_NAME="ambari-agent"
REPO_FILE="http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/${AMBARI_VERSION}/ambari.repo"

. command/command_function.sh

AMBARI_LOG="ambari-agent.log"

SCRIPT_LOG "[INFO] command param : $*"
SCRIPT_LOG "[INFO] ambari initialization now ...."
SCRIPT_LOG "[INFO] ambari agent : ${AMBARI_VERSION}"
SCRIPT_LOG "[INFO] REPO_FILE : ${REPO_FILE}"
SCRIPT_LOG "[INFO] Download repo file : ${REPO_FILE}"

## 下载服务
wget "${REPO_FILE}" -O /etc/yum.repos.d/ambari.repo -o ${LOG_DIR}/${SCRIPT_LOG}
yum -y install --nogpgcheck ${SERVER_NAME}-${AMBARI_VERSION}

## 修改配置
SCRIPT_LOG "[INFO] update ambari configuration file now.."
sed -i.back "s/hostname=localhost/hostname=${SERVER_HOSTNAME}/g" /etc/${SERVER_NAME}/conf/${SERVER_NAME}.ini
SCRIPT_LOG "[INFO] start ${SERVER_NAME} now ...."

# 启动服务
export AMBARI_PASSPHRASE=DEV
/usr/sbin/${SERVER_NAME} restart --expected-hostname=${EXPECTED_HOSTNAME}

SCRIPT_LOG "[INFO] start ${SERVER_NAME} success ...."

if [ "${CLUSTER_NAME}" == "NULL" ]
then
    exit 0
fi

# 注册服务
python ambari/ambari_agent.py ${SERVER_HOSTNAME} ${CLUSTER_NAME} ${USER_KEY} ${EXPECTED_HOSTNAME} >> ${LOG_DIR}/${AMBARI_LOG} 2>&1
