# -*- coding: utf-8 -*-
#########################################################################
# File Name: runTest.py
# Author: Ethan
# mail: lixianghan@daowoo.com,lixh017@163.com
# Created Time: Mon 25 Sep 2017 04:40:43 PM CST
#########################################################################

import saltoption
import json

class RunTest():
    def AsynRunTest(self,token,test_framwork,hosts_list):
        salt=SaltOption.SaltOption()
        jobs_list = []
        for host in hosts_list.split(','):
            if test_framwork == 'fio':
                jobs_list.append(salt.ExecCmd(token,host,fun='state.sls',arg='performance.fio.run_test',async=True))
        
        return jobs_list

run = RunTest()
salt = SaltOption.SaltOption()

hosts_list='172.16.131.212'
token = salt.getToken()
print hosts_list
print token
jobs_list=run.AsynRunTest(token,'fio',hosts_list)

print jobs_list

