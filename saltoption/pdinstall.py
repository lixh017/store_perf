# -*- coding: utf-8 -*-
#########################################################################
# File Name: pdinstall.py
# Author: Ethan
# mail: lixianghan@daowoo.com,lixh017@163.com
# Created Time: Thu 28 Sep 2017 04:23:11 PM CST
#########################################################################
import saltoption
import json
from setting import product as product

class testtool():

    def __init__(self):
        self.salt = saltoption.SaltOption()
        self.support_porduct = []
        for pd in product.keys():
            for ver in product[pd]['version']
                pd_ver = pd + '_' + ver
                self.support_porduct.append(pd_ver)

    def InstallProduct(self,pd_name,pd_version,install_host,install_option=None):
        rs_list=[]
        pd_ver = pd_name + '_' + pd_version
        if pd_ver in self.support_product:
            arg_str = pd_name + '.' + pd_version.lower() + '.' + pd_version.replace('.','u')+".install"
            ret = self.salt.ExecCmd(host,fun='state.sls',arg=arg_str)
            rs_list.append(ret)
            
        return rs_list

    def UninstallProduct(self,pd_name,pd_version,install_host,install_option=None):
        rs_list=[]
        pd_ver = pd_name + '_' + pd_version
        if pd_ver in self.support_product:
            for host in hosts_list_split(','):
                arg_str = pd_name + '.' + pd_version.lower() + '.' + pd_version.replace('.','u')+".install"
                ret = self.salt.ExecCmd(host,fun='state.sls',arg=arg_str)
                rs_list.append(ret)
        else:
            ret = 'do not suport this product [ ' + pd_name + '_'+ pd_version + ' ]'
            
        return rs_list

def main():
    tt = testtool()

    hosts_list='172.16.131.212,172.16.131.147,172.16.131.113'
    for tool_name in ['fio','mdtest','iozone','vdbench']:
        print json.dumps(tt.InstallTestTool(tool_name,hosts_list),indent=4)

