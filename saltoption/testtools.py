# -*- coding: utf-8 -*-
#########################################################################
# File Name: TestTools.py
# Author: Ethan
# mail: lixianghan@daowoo.com,lixh017@163.com
# Created Time: Mon 25 Sep 2017 02:45:56 PM CST
#########################################################################
import saltoption
import json
from setting import testtools as testtools

class testtool():

    def __init__(self):
        self.salt = saltoption.SaltOption()
        self.support_list = testtools.keys()
        self.service_support_list = []
        for tool in self.support_list:
            if testtools[tool]['service'] == True:
                self.service_support_list.append(tool)
        
    def InstallTestTool(self,tool_name,hosts_list):
        rs_list = []
        if tool_name in self.support_list: 
            for host in hosts_list.split(','):
                arg_str='testtools.' + tool_name + '.install'
                ret = self.salt.ExecCmd(host,fun='state.sls',arg=arg_str)
                rs_list.append(ret)
        else:
            ret = 'do not suport test tool [ ' + tool_name + ' ]'
            rs_list.append(ret)

        return rs_list

    def UninstallTestTool(self,tool_name,hosts_list):
        rs_list = []
        if tool_name in self.support_list: 
            for host in hosts_list.split(','):
                arg_str='testtools.' + tool_name + '.uninstall'
                ret = self.salt.ExecCmd(host,fun='state.sls',arg=arg_str)
                rs_list.append(ret)
        else:
            ret = 'do not suport test tool [ ' + tool_name + ' ]'
            rs_list.append(ret)

        return rs_list

    def StartToolService(self,hosts_list):
        rs_list = []
        if tool_name in self.service_support_list: 
            for host in hosts_list.split(','):
                arg_str='testtools.' + tool_name + '.start_service'
                ret = self.salt.ExecCmd(host,fun='state.sls',arg=arg_str)
                rs_list.append(ret)
        else:
            ret = 'do not suport test tool [ ' + tool_name + ' ]'
            rs_list.append(ret)
        
        return rs_list

    def StopToolService(self,hosts_list):
        rs_list = []
        if tool_name in self.service_support_list: 
            for host in hosts_list.split(','):
                arg_str='testtools.' + tool_name + '.stop_service'
                ret = self.salt.ExecCmd(host,fun='state.sls',arg=arg_str)
                rs_list.append(ret)
        else:
            ret = 'do not suport test tool [ ' + tool_name + ' ]'
            rs_list.append(ret)
        
        return rs_list

    def RestartToolService(self,hosts_list):
        rs_list = []
        if tool_name in self.service_support_list: 
            for host in hosts_list.split(','):
                arg_str='testtools.' + tool_name + '.restart_service'
                ret = self.salt.ExecCmd(host,fun='state.sls',arg=arg_str)
                rs_list.append(ret)
        else:
            ret = 'do not suport test tool [ ' + tool_name + ' ]'
            rs_list.append(ret)
        
        return rs_list

def main():
    tt = testtool()

    hosts_list='172.16.131.212,172.16.131.37,172.16.131.113,172.16.131.70,172.16.131.109'
    for tool_name in ['fio','mdtest','iozone','vdbench']:
        print json.dumps(tt.InstallTestTool(tool_name,hosts_list),indent=4)

if __name__ == '__main__':
    main()
