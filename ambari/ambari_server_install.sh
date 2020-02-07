#!/usr/bin/env bash

#####################################################################################
# @desc : ambari server 安装启动过程
# @user : tao.dong
#
# $1 : version
# $2 : mysql host address
# $3 : mysql db name
# $4 : mysql db user name
# $5 : mysql db user passwd
# $6 : ambari_user
# $7 : ambari_password
######################################################################################

if [ $# -ne 7 ]
then
   echo "[ERROR] command : {command_bash ambari_version meta_host meta_db db_user db_pass ambari_user ambari_passwd}"
   exit -1
fi


AMBARI_VERSION=$1
META_HOST=$2
META_DBNAME=$3
META_USERNAME=$4
META_PASSWD=$5
AMBARI_USER=$6
AMBARI_PASSWD=$7

REPO_FILE="http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/${AMBARI_VERSION}/ambari.repo"
MYSQL_JAR="https://repo1.maven.org/maven2/mysql/mysql-connector-java/6.0.6/mysql-connector-java-6.0.6.jar"
AMVARI_SERVER_LIB="/usr/lib/ambari-server"
AMBARI_CONF="/etc/ambari-server/conf/ambari.properties"
PASS_FILE="/etc/ambari-server/conf/password.dat"

. command/command_function.sh

AMBARI_LOG="ambari-server.log"

SCRIPT_LOG "[INFO] command param : $*"

# 下载ambari-server
SCRIPT_LOG "[INFO] AMBARI_VERSION : ${AMBARI_VERSION}"
SCRIPT_LOG "[INFO] REPO_FILE : ${REPO_FILE}"
wget "${REPO_FILE}" -O /etc/yum.repos.d/ambari.repo -o ${LOG_DIR}/${SCRIPT_LOG}
yum install ambari-server -y  >> ${LOG_DIR}/${AMBARI_LOG}
SCRIPT_LOG "[INFO] INSTALL ambari sucesss"

mysql -h ${META_HOST} -u${META_USERNAME} -p${META_PASSWD} -e "SELECT 1" >> ${LOG_DIR}/${AMBARI_LOG} 2>&1
reqDb=$(mysqlshow -h ${META_HOST} -u${META_USERNAME} -p${META_PASSWD} ${META_DBNAME} | grep -v Wildcard | grep -o ${META_DBNAME})

# 判断数据库是否存在
if [ "${reqDb}" = "${META_DBNAME}" ]
then
    SCRIPT_LOG "[ERROR] mysql DB is already exist"
    exit -1
fi

# 初始化 mysql jdbc 工具
SCRIPT_LOG "[INFO] init mysql jdbc tool"
wget ${MYSQL_JAR} -O ${AMVARI_SERVER_LIB}/mysql-connector-java.jar
rm -rf /usr/share/java
mkdir -p /usr/share/java
cp ${AMVARI_SERVER_LIB}/mysql-connector-java.jar /usr/share/java/
cp ${AMVARI_SERVER_LIB}/mysql-connector-java.jar /var/lib/ambari-server/resources/
SCRIPT_LOG "[INFO] init mysql jdbc tool success"

# 初始化配置文件
SCRIPT_LOG "[INFO] init ambari configation file"
sed -i 's/-Xmx[[:alnum:]]\+m/-Xmx10240m/g' /var/lib/ambari-server/ambari-env.sh
mv ${AMBARI_CONF} /etc/ambari-server/conf/ambari.properties-bak
cp conf/ambari-${AMBARI_VERSION}.properties ${AMBARI_CONF}
sed -i "s/#{DBHOST}/${META_HOST}/g" ${AMBARI_CONF}
sed -i "s/#{DATABASE}/${META_DBNAME}/g" ${AMBARI_CONF}
sed -i "s/#{DBUSER}/${META_USERNAME}/g" ${AMBARI_CONF}
echo "${META_PASSWD}" > ${PASS_FILE}
SCRIPT_LOG "[INFO] init ambari configation file success"


# 同步 DB 信息
SCRIPT_LOG "[INFO] init db message"

mysql -h${META_HOST} -u${META_USERNAME} -p${META_PASSWD} << EOF >> ${LOG_DIR}/${AMBARI_LOG} 2>&1
CREATE DATABASE \`${META_DBNAME}\` CHARACTER SET utf8;
use ${META_DBNAME};
source conf/ambari-meta-${AMBARI_VERSION}.sql;
EOF

SCRIPT_LOG "[INFO] init db message success"

# 启动 ambari_server
ambari-server restart >> ${LOG_DIR}/${AMBARI_LOG} 2>&1

# 创建新的管理用户
if [ "${AMBARI_USER}" = "admin" ]
then
    curl -X PUT -uadmin:admin -H "X-Requested-By:ambari" -d "{\"Users/password\":\"${AMBARI_PASSWD}\",\"Users/old_password\":\"admin\"}" http://localhost:8080/api/v1/users/${AMBARI_USER}
else
  curl -X POST -uadmin:admin -H "X-Requested-By:ambari" -d "{\"Users/user_name\":\"${AMBARI_USER}\",\"Users/password\":\"${AMBARI_PASSWD}\",\"Users/active\":true,\"Users/admin\":true}" http://localhost:8080/api/v1/users
  curl -X DELETE -u${AMBARI_USER}:${AMBARI_PASSWD} -H "X-Requested-By:ambari" -d '{"id":"admin"}' http://localhost:8080/api/v1/users/admin
fi


# add stack
curl -H "X-Requested-By: ambari" -X PUT -u${AMBARI_USER}:${AMBARI_PASSWD} http://localhost:8080/api/v1/stacks/HDP/versions/3.0/operating_systems/redhat7/repositories/HDP-3.0 -d '{"Repositories":{"base_url":"http://public-repo-1.hortonworks.com/HDP/centos7/3.x/updates/3.0.0.0","repo_name":"HDP","verify_base_url":true}}'

curl -H "X-Requested-By: ambari" -X PUT -u${AMBARI_USER}:${AMBARI_PASSWD} http://localhost:8080/api/v1/stacks/HDP/versions/3.0/operating_systems/redhat7/repositories/HDP-3.0-GPL -d '{"Repositories":{"base_url":"http://public-repo-1.hortonworks.com/HDP-GPL/centos7/3.x/updates/3.0.0.0","repo_name":"HDP-GPL","verify_base_url":true}}'

curl -H "X-Requested-By: ambari" -X PUT -u${AMBARI_USER}:${AMBARI_PASSWD} http://localhost:8080/api/v1/stacks/HDP/versions/3.0/operating_systems/redhat7/repositories/HDP-UTILS-1.1.0.22 -d '{"Repositories":{"base_url":"http://public-repo-1.hortonworks.com/HDP-UTILS-1.1.0.22/repos/centos7","repo_name":"HDP-UTILS","verify_base_url":true}}'
