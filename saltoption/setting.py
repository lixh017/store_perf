# -*- coding: utf-8 -*-
#########################################################################
# File Name: setting.py
# Author: Ethan
# mail: lixianghan@daowoo.com,lixh017@163.com
# Created Time: Wed 20 Sep 2017 04:20:27 PM CST
#########################################################################

salt_master_config = {
    "host_ip":'172.16.16.134',
    "port":'9100',
    "username":'saltapi',
    "password":'saltapi',
}

testtools = {
    'fio': {'service':True},
    'mdtest': {'service': False},
    'iozone':{'service': False},
    'vdbench':{'service': True}
}

product = {
    'YeeOS':{'version':['1.0']},
    'YeeFS':{'version':['4.1','4.2']},
    'WooStor':{'version':['3.0','3.1']},
    'Cone':{'version':['1.2','1.4']},
    'Sone':{'version':['1.2','1.4']}
}

montools = {
    'atop':{'service':True},
    'nmon':{'service':True}
}


