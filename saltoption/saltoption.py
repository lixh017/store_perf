# -*- coding: utf-8 -*-
#########################################################################
# File Name: SaltOption.py
# Author: Ethan
# mail: lixianghan@daowoo.com,lixh017@163.com
# Created Time: Wed 13 Sep 2017 03:06:07 PM CST
import requests
import json

from setting import salt_master_config 

try:
    import cookielib
except:
    import http.cookiejar as cookielib

#import ssl 
#context = ssl._create_unverified_context()

from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

host_ip=salt_master_config['host_ip']
port = salt_master_config['port']

salt_api = 'http://' + host_ip + ':' + port + '/' 

username = salt_master_config['username']
password = salt_master_config['password']


class SaltOption:
    def __init__(self): 
        self.url = salt_api
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36",
            "Content-type": "application/json"
            # "Content-type": "application/x-yaml"
        }
        self.token = self.get_token()
        self.headers['X-Auth-Token'] = self.token

    def get_token(self):
        params = {'client': 'local', 'fun': '', 'tgt': ''}
        # self.params = {'client': 'local', 'fun': '', 'tgt': '', 'arg': ''}
        login_url = salt_api + "login"
        login_params = {'username': username, 'password': password, 'eauth': 'pam'}
        token = self.get_data(login_url, login_params)['token']
        return token

    def get_data(self,url, params):
        send_data = json.dumps(params)
        request = requests.post(url, data=send_data, headers=self.headers, verify=False)
        response = request.json()
        result = dict(response)
        # print result
        return result['return'][0]

    def ExecCmd(self, tgt, fun, arg=None, kwarg=None):
        """远程执行命令，相当于salt 'client1' cmd.run 'free -m'"""
        params = {'client': 'local', 'fun': fun, 'tgt': tgt, 'tgt_type': 'list'}
        if arg:
            params['arg'] = arg
        if kwarg:
            params['kwarg'] = kwarg
        #print '命令参数: ', params
        result = self.get_data(self.url, params)
        return result

    def AsyncExecCmd(self, tgt, fun, arg=None, kwarg=None):
        """远程执行命令，相当于salt 'client1' cmd.run 'free -m'"""
        params = {'client': 'local_async', 'fun': fun, 'tgt': tgt, 'tgt_type': 'list'}
        if arg:
            params['arg'] = arg
        if kwarg:
            params['kwarg'] = kwarg

        #print '命令参数: ', params
        result = self.get_data(self.url, params)
        return result

def main():
    host_ip='172.16.16.134'
    port='9100'
    username='saltapi'
    password='saltapi'

    salt=SaltOption()

    token = salt.getToken()

    host_list='172.16.131.212,172.16.131.147,172.16.131.113'
    #tgt='172.16.131.113'
    fun='cmd.run'
    arg='rpm -qa|grep fio'

    #print GetMinions(host_ip,port,token,'172.16.131.212')

    jobs_list=[]
    for tgt in host_list.split(','):
        jobs_list.append(salt.ExecCmd(token,tgt,fun,arg=arg,async=True))

    #print GetJobStatus(host_ip,port,token)
    #
    for job in jobs_list:
        job_id = job['jid']
        job_status=salt.GetJobStatus(token,job_id=job_id)
        print json.dumps(job_status,indent=4, sort_keys=True)

if __name__ == '__main__':
    main()
