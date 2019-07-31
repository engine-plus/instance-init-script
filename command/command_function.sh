#!/usr/bin/env bash

AMBARI_LOG="ambari.log"
SCRIPT_LOG="ambari-install.log"
LOG_DIR="/var/log/ambari"

if [[ ! -d ${LOG_DIR} ]]
then
  mkdir -p ${LOG_DIR}
fi

function SCRIPT_LOG()
{
  log=$1
  log_time=$(date +'%Y-%m-%d:%H:%M:%S')
  echo "${log_time} $log" >> ${LOG_DIR}/${AMBARI_LOG}
}