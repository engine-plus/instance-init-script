#!/usr/bin/env python
#-*- coding:utf8 -*-
import base64
import requests
import json
import time
import sys

###
#  参数 :
#     $1 : userKey
#     $2 : serverName
#     $3 : clusterName
#     $4 : hostName
#
#
#  注册主机 :
#    POST :  http://${serverName}:8080/api/v1/clusters/${clusterName}/hosts/${hostName}
#            http://ip-172-31-27-83.ec2.internal:8080/api/v1/clusters/ambari_test_cluster/hosts/ip-172-31-27-83.ec2.internal
#
#  check 已经注册的主机
#    GET  : http://${serverName}:8080/api/v1/clusters/${clusterName}/hosts
###

class AmbariAgent(object):

    def __init__(self, argc, argv):

        if argc != 4:
            print("[SCRIPT ${serverName} ${clusterName} ${userKey} ${hostName}] ")
            sys.stdout.flush()
            exit(-1)

        self.serverName = argv[0]
        self.clusterName = argv[1]
        self.userKey = "Basic {0}".format(base64.b64encode(argv[2]))
        self.hostName = argv[3]

    def registerHost(self):

        url = "http://{0}:8080/api/v1/clusters/{1}/hosts/{2}".format(self.serverName, self.clusterName, self.hostName)
        header = {
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'X-Requested-By': 'X-Requested-By',
            'Authorization': self.userKey
        }

        AmbariAgent.postMethod(url=url, head=header, data=None)


    def checkoutHost(self):
        url = "http://{0}:8080/api/v1/clusters/{1}/hosts".format(self.serverName, self.clusterName)
        header = {
            'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'X-Requested-By': 'X-Requested-By',
            'Authorization': self.userKey
        }

        hosts = []

        res = AmbariAgent.getMethod(url=url, head=header)
        data=json.loads(res)

        for hostItem in data["items"] :
            hosts.append(hostItem["Hosts"]["host_name"])

        return self.hostName in hosts


    def start(self):
        # 注册服务
        print("[INFO] register host start ... ")
        sys.stdout.flush()
        self.registerHost()

        # 检查服务状态
        while not self.checkoutHost() :
            print("[INFO] register host now ...")
            sys.stdout.flush()
            time.sleep(1)

        print("[INFO] register host seccuss !!! ")
        sys.stdout.flush()

    @staticmethod
    def getMethod(url, head) :
        r = requests.get(url=url, headers=head)
        if (r.status_code >= 300):
            raise IOError(r.text)
        return r.text

    @staticmethod
    def postMethod(url, head, data) :
        r = requests.post(url=url, data=data, headers=head)
        if (r.status_code >= 300):
            raise IOError(r.text)
        return r.text


if __name__ == '__main__':

    ambariAgent = AmbariAgent(len(sys.argv[1:]), sys.argv[1:])

    try :
        ambariAgent.start()
    except IOError as e :
        print("[ERROR] install component error : {0} - {1} \n".format(str(sys.argv), str(e)))
        sys.stdout.flush()