import sys
import base64
import requests
import json

class AmbariServer(object):

    def __init__(self, argc, argv):
        if argc != 4:
            print("[SCRIPT ${serverName} ${clusterName} ${userKey} ${hostName}] ")
            sys.stdout.flush()
            exit(-1)

        self.serverName = argv[0]
        self.clusterName = argv[1]
        self.userKey = "Basic {0}".format(base64.b64encode(argv[2]))
        self.hostName = argv[3]

    def create_admin_user(self, username, password):

        user_message = {
            "Users/user_name":username,
            "Users/password":password,
            "Users/active":True,
            "Users/admin":True
        }
        request_address = "http://{0}:8080/api/v1/user"

        pass

    @staticmethod
    def getMethod(url, head):
        r = requests.get(url=url, headers=head)
        if (r.status_code >= 300):
            raise IOError(r.text)
        return r.text

    @staticmethod
    def postMethod(url, head, data):
        r = requests.post(url=url, data=data, headers=head)
        if (r.status_code >= 300):
            raise IOError(r.text)
        return r.text

    @staticmethod
    def deleteMethod(url, head, data):
        r = requests.delete(url=url, data=data, headers=head)
        if (r.status_code >= 300):
            raise IOError(r.text)
        return r.text


if __name__ == '__main__':
    server = AmbariServer(len(sys.argv[1:], sys.argv[1:]))