#!/usr/bin/env bash


#######################################################
# @desc   : ambari 组件安装与初始化过程
# @author : tao.dong
# @date   : 2018-08-09
#
# $1 server_name  : hostname for server
# $2 cluster_name : cluster name for ambari
# $3 user_key     : access key for user login
#
# "DATANODE"
# "HDFS_CLIENT"
# "MAPREDUCE2_CLIENT", "NODEMANAGER", "YARN_CLIENT", "TEZ_CLIENT", "GANGLIA_MONITOR", "HCAT",
# "HIVE_CLIENT", "HIVE_METASTORE", "HIVE_SERVER", "WEBHCAT_SERVER", "HBASE_CLIENT", "HBASE_MASTER",
# "HBASE_REGIONSERVER", "PIG", "SQOOP", "OOZIE_CLIENT", "OOZIE_SERVER", "ZOOKEEPER_CLIENT", "ZOOKEEPER_SERVER",
# "FALCON_CLIENT", "SUPERVISOR", "FLUME_HANDLER", "METRICS_MONITOR", "KAFKA_BROKER", "KERBEROS_CLIENT", "KNOX_GATEWAY", "SLIDER", "SPARK_CLIENT"
#
#######################################################

set -e

if [ $# -lt 4 ]
then
 echo "[ERROR] command : {BASH serverName clusterName  userKey component ...}"
 exit -1
fi


SERVER_HOSTNAME=$1
CLUSTER_NAME=$2
USER_KEY=$3
COMPONENT_LIST=${@:4:$(($#-4+1))}

LOCAL_HOSTNAME="$(hostname -f)"

. command/command_function.sh

AMBARI_LOG="ambari-agent.log"

SCRIPT_LOG "[INFO] command param : $*"

python ambari/ambari_agent_component.py "${SERVER_HOSTNAME}" "${CLUSTER_NAME}" "${USER_KEY}" "${LOCAL_HOSTNAME}" "METRICS_MONITOR" >> ${LOG_DIR}/${AMBARI_LOG}

for component_tool in ${COMPONENT_LIST}
do
  if [ "${component_tool}" = "METRICS_MONITOR" ]
  then
    continue
  fi

  python ambari/ambari_agent_component.py "${SERVER_HOSTNAME}" "${CLUSTER_NAME}" "${USER_KEY}" "${LOCAL_HOSTNAME}" "${component_tool}" >> ${LOG_DIR}/${AMBARI_LOG}
done
