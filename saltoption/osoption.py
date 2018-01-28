# -*- coding: utf-8 -*-
#########################################################################
# File Name: osoption.py
# Author: Ethan
# mail: lixianghan@daowoo.com,lixh017@163.com
# Created Time: Wed 20 Sep 2017 04:26:05 PM CST
#########################################################################
import saltoption
import json

class osoption():

    def __init__(self):
        self.salt = saltoption.SaltOption()

    def ConfigAutoSSH(self,hosts_list):
        rs_list = []
        for host in hosts_list.split(','):
            rs_list.append(self.salt.ExecCmd(host,fun='state.sls',arg='osoption.auto_ssh.auto_ssh'))

        return rs_list

    def ConfigHostName(self,hosts_list): 
        rs_list = []
        for host in hosts_list.split(','):
            kwarg={'pillar': {'local_ip': host}}
            rs_list.append(self.salt.ExecCmd(host,fun='state.sls',arg='osoption.host_name.config_hostname', kwarg=kwarg))

        return rs_list

    def ConfigHosts(self,hosts_list,ip_list): 
        rs_list = []
        kwarg={'pillar': {'ip_list': ip_list}}
        for host in hosts_list.split(','):
            rs_list.append(self.salt.ExecCmd(host,fun='state.sls',arg='osoption.host_name.config_hosts', kwarg=kwarg))

        return rs_list

    def HostOptioin(self,hosts_list):
        rs_list=[]


        return rs_list



def main():
    os = osoption()

    hosts_list='172.16.20.111,172.16.21.110,172.16.21.144'
    print json.dumps(os.ConfigAutoSSH(hosts_list),indent=4)
    print json.dumps(os.ConfigHostName(hosts_list),indent=4)
    print json.dumps(os.ConfigHosts(hosts_list,hosts_list),indent=4)


if __name__ == '__main__':
    main()
