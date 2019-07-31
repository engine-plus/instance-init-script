#!/usr/bin/env bash

set -e

if [ $# -lt 1 ]
then
  echo "[ERROR] command : {command_bash labelname}"
  exit -1
fi

HostName=$(hostname -f)
LabelName=$1

. command/command_function.sh

SCRIPT_LOG "Add ${HostName} to ${LabelName}"
su -l yarn -c "yarn rmadmin -replaceLabelsOnNode ${HostName}=${LabelName}"
SCRIPT_LOG "Add ${HostName} to ${LabelName} success"