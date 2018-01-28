# -*- coding: utf-8 -*-
#########################################################################
# File Name: test.py
# Author: Ethan
# mail: lixianghan@daowoo.com,lixh017@163.com
# Created Time: Wed 13 Sep 2017 03:04:16 PM CST
#########################################################################

import os
import sys
import json
import SaltOption

salt=SaltOption.SaltOption()

#token = salt.getToken()

host_list='172.16.131.212,172.16.131.147,172.16.131.113'
#tgt='172.16.131.113'
fun='state.sls'
#arg='rpm -qa|grep fio'
#arg='testtools.mdtest.install_openmpi'
#arg='testtools.mdtest.copy_ld_conf'
#arg='testtools.mdtest.copy_mdtest_bin'
#arg='testtools.mdtest.prepare_test_env'
#arg='auto_ssh.auto_ssh'
arg='test_env.host_name.config_hosts'

#print GetMinions(host_ip,port,token,'172.16.131.212')

#jobs_list=[]
#for tgt in host_list.split(','):
#    jobs_list.append(salt.AsyncExecCmd(token,tgt,fun,arg=arg))
#
##print GetJobStatus(host_ip,port,token)
##
#for job in jobs_list:
#    job_id = job['jid']
#    job_status=salt.GetJobStatus(token,job_id=job_id)
#    print json.dumps(job_status,indent=4, sort_keys=True)

#print token
args = {'pillar':{"ip_list":"172.16.131.212,172.16.131.147"}}
print args
for tgt in host_list.split(','):
    rs = salt.ExecCmd(tgt,fun,arg=arg,kwarg=args)
    print json.dumps(rs,indent=4)
