#!/usr/bin/env python
#-*- coding:utf8 -*-

import base64
import requests
import json
import time
import sys

###
#  参数：
#   $1 : ${userName}:${passwd}
#   $2 : ${serverName}
#   $3 : ${clusterName}
#   $4 : ${hostName}
#   $5 : ${componentName}
#
#
# 安装 ambari 组件：
#  认证 : ${userName}:${passWord}
#
#  注册 :
#  POST : http://${serverName}:8080/api/v1/clusters/${clusterName}/hosts/${hostName}/host_components/${ComponentName}
#         http://ip-172-31-27-83.ec2.internal:8080/api/v1/clusters/ambari_test_cluster/hosts/ip-172-31-23-241.ec2.internal/host_components/METRICS_MONITOR
#
#  下载 :
#  PUT : http://${serverName}:8080/api/v1/clusters/${clusterName}/hosts/${hostName}/host_components/${ComponentName}  | {"HostRoles":{"state":"INSTALLED"}}
#
#  安装 :
#  PUT : http://${serverName}:8080/api/v1/clusters/${clusterName}/hosts/${hostName}/host_components/${ComponentName}  | {"HostRoles":{"state":"STARTED"}}
###



class AmbariComponent(object):

    def __init__(self, argc, argv):
        if(argc != 5):
            sys.stderr.write("Command : [script {serverName} {clusterName} {userName}:{passwd} {hostName} {componentName}] \n")
            sys.stdout.flush()
            exit(-1)

        self.serverName = argv[0]
        self.clusterName = argv[1]
        self.userKey = "Basic {0}".format(base64.b64encode(argv[2]))
        self.hostName = argv[3]
        self.componentName = argv[4]

    def createComponent(self):
        url = "http://{0}:8080/api/v1/clusters/{1}/hosts/{2}/host_components/{3}".format(self.serverName, self.clusterName, self.hostName, self.componentName)
        header = {
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'X-Requested-By': 'X-Requested-By',
            'Authorization' : self.userKey
        }
        AmbariComponent.postMethod(url, header, None)

    def installComponent(self):
        url = "http://{0}:8080/api/v1/clusters/{1}/hosts/{2}/host_components/{3}".format(self.serverName, self.clusterName, self.hostName, self.componentName)
        header = {
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'X-Requested-By': 'X-Requested-By',
            'Authorization': self.userKey
        }
        data = {"Body":{"HostRoles":{"state":"INSTALLED"}}}
        AmbariComponent.putMethod(url, head=header, data=json.dumps(data))

    def startComponent(self):
        url = "http://{0}:8080/api/v1/clusters/{1}/hosts/{2}/host_components/{3}".format(self.serverName, self.clusterName, self.hostName, self.componentName)
        header = {
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'X-Requested-By': 'X-Requested-By',
            'Authorization': self.userKey
        }
        data = {"Body":{"HostRoles":{"state":"STARTED"}}}
        AmbariComponent.putMethod(url, head=header, data=json.dumps(data))


    def getComponentStatus(self):
        url = "http://{0}:8080/api/v1/clusters/{1}/hosts/{2}/host_components/{3}?fields=HostRoles/state"\
            .format(self.serverName, self.clusterName, self.hostName, self.componentName)
        header = {
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'X-Requested-By' : 'X-Requested-By',
            'Authorization': self.userKey
        }

        res = AmbariComponent.getMethod(url, head=header)

        return json.loads(res)["HostRoles"]["state"]

    def start(self):

        print("[INFO] INSTALL component {0} start ....".format(self.componentName))
        sys.stdout.flush()

        # 创建服务
        self.createComponent()
        print("[INFO] create component {0} success !!!".format(self.componentName))
        sys.stdout.flush()
        # 下载服务
        self.installComponent()
        print("[INFO] install component {0} start ...".format(self.componentName))
        sys.stdout.flush()

        # 校验下载过程
        while True:
            time.sleep(1)
            status = self.getComponentStatus()

            if status == "INSTALLING" or status == "INIT" :
                print("[INFO] install component {0} now and status : {1} ...".format(self.componentName, status))
                sys.stdout.flush()
                continue
            elif status == "INSTALL_FAILED" :
                self.installComponent()
                print("[ERROR] install component {0} failed and reinstall component ...".format(self.componentName))
                sys.stdout.flush()
            else:
                break

        print("[INFO] install component {0} success and now start !!!".format(self.componentName))
        sys.stdout.flush()

        # 启动服务
        self.startComponent()
        print("[INFO] start component {0} now ...".format(self.componentName))
        sys.stdout.flush()

        # 校验启动过程
        while True :
            time.sleep(1)
            status = self.getComponentStatus()
            if status == "STARTING" or status == "INSTALLED" :
                print("[INFO] start component {0} now and now status : {1}".format(self.componentName, status))
                sys.stdout.flush()
                continue
            else:
                break

        print("[INFO] start component {0} success !!!".format(self.componentName))
        sys.stdout.flush()

        print("[INFO] INSTALL component {0} success !!!!".format(self.componentName))
        sys.stdout.flush()

    @staticmethod
    def getMethod(url, head):
        r = requests.get(url=url, headers=head)
        if(r.status_code >= 300):
            raise IOError(r.text)
        return r.text

    @staticmethod
    def postMethod(url, head , data):
        r = requests.post(url=url, data=data, headers=head)
        if (r.status_code >= 300):
            raise IOError(r.text)
        return r.text

    @staticmethod
    def putMethod(url, head , data):
        r = requests.put(url=url, data=data, headers=head)
        if (r.status_code >= 300):
            raise IOError(r.text)
        return r.text


if __name__ == '__main__':
    ambariComponent = AmbariComponent(len(sys.argv[1:]), sys.argv[1:])
    try :
        ambariComponent.start()
    except IOError as e:
        print("[ERROR] install component error : {0} - {1}".format(str(sys.argv), str(e)))
        sys.stdout.flush()
