# -*- coding: utf-8 -*-
#########################################################################
# File Name: init_install.py
# Author: Ethan
# mail: lixianghan@daowoo.com,lixh017@163.com
# Created Time: Thu 23 Nov 2017 04:07:28 PM CST
#########################################################################
import os
import sys
import getopt
import json
from testtools import testtool
from osoption import osoption

tools = testtool()
osopt = osoption()

def usage():
    print "usage:\n\tpython init_install.py -l 172.16.30.1,172.16.30.2\n -l     --ip_list  input you want to option hosts list\n "
    sys.exit(3)

#hosts_list='172.16.131.212,172.16.131.37,172.16.131.113,172.16.131.70,172.16.131.109'
hosts_list=''

try:
    options,args = getopt.getopt(sys.argv[1:],"hl:",["help","ip_list="])
except getopt.GetoptError:
    usage()

for name,value in options:
    if name in ("-h","--help"):
        usage()
    if name in ("-l","--ip_list"):
        hosts_list=value
    
if hosts_list == '':
    usage()


for tool_name in ['fio','mdtest','iozone','vdbench']:
    print json.dumps(tools.InstallTestTool(tool_name,hosts_list),indent=4)

print json.dumps(osopt.ConfigAutoSSH(hosts_list),indent=4)
print json.dumps(osopt.ConfigHostName(hosts_list),indent=4)
print json.dumps(osopt.ConfigHosts(hosts_list,hosts_list),indent=4)
