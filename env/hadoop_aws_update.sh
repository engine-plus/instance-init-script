#!/usr/bin/env bash

HADOOP_AWS_TAR="conf/aws-java-sdk.tar.gz"

if [ $# -lt 1 ]
then
  echo "[ERROR] command : {command_bash hadoop_version}"
  exit -1
fi

HADOOP_VERSION=$1

TARGET_PATH="/usr/hdp/${HADOOP_VERSION}"

. command/command_function.sh

SCRIPT_LOG "Aws hadoop sdk update"

tar -zxvf ${HADOOP_AWS_TAR} -C aws-java-sdk/

find ${TARGET_PATH} -name "*aws*.jar" -exec rm -f {} \;

cp aws-java-sdk/* ${TARGET_PATH}/hadoop/
cp aws-java-sdk/* ${TARGET_PATH}/hbase/

SCRIPT_LOG "Aws hadoop sdk update finish"