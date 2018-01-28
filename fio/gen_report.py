# -*- coding: utf-8 -*-
#########################################################################
# File Name: gen_report.py
# Author: Ethan
# mail: lixianghan@daowoo.com,lixh017@163.com
# Created Time: Mon 30 Oct 2017 01:46:29 PM CST
#########################################################################
import sys
import os 
import re
import sqlite3
import fnmatch
import getopt
import linecache
import time


def create_db_table():
    cur.execute('drop table if exists "main".fio_rs_table;')
    cur.execute('CREATE TABLE "main"."fio_rs_table" ( \
         "task_id" INTEGER NOT NULL, \
         "task_name" text, \
         "client_num" integer, \
         "r_size" text, \
         "run_type" text, \
         "iodepth" text, \
         "jobs" TEXT, \
         "mode" TEXT, \
         "rwmix" TEXT, \
         "dev" TEXT, \
         "read_iops" TEXT, \
         "write_iops" TEXT, \
         "total_iops" TEXT, \
         "read_bw" TEXT, \
         "write_bw" TEXT, \
         "total_bw" TEXT, \
         "write_lat" TEXT, \
         "read_lat" TEXT, \
         "total_lat" TEXT, \
         "read_clat" TEXT, \
         "write_clat" TEXT, \
         "total_clat" TEXT, \
         "read_slat" TEXT, \
         "write_slat" TEXT, \
         "total_slat" TEXT, \
        PRIMARY KEY("task_id")); ')
    conn.commit()

def iops_value(line_value):
    iops=line_value.rstrip('\r\n').split(',')[0].split('=')[1]
    if fnmatch.fnmatch(iops,'*k*'):
        iops=float(iops.rstrip('\r\n').split('k')[0]) * 1024
    elif fnmatch.fnmatch(iops,'*M*'):
        iops=float(iops.rstrip('\r\n').split('M')[0]) * 1024 * 1024
    elif fnmatch.fnmatch(iops,'*G*'):
        iops=float(iops.rstrip('\r\n').split('G')[0]) * 1024 * 1024 * 1024
    elif fnmatch.fnmatch(iops,'*P*'):
        iops=float(iops.rstrip('\r\n').split('P')[0]) * 1024 * 1024 * 1024 * 1024
    else:
        iops=float(iops)
    
    return round(iops,3)

def bw_value(line_value):
    bw=line_value.rstrip('\r\n').split(',')[1].split('=')[1].split(' ')[0]
    if fnmatch.fnmatch(bw,'*Ki*'):
        bw=float(bw.rstrip('\r\n').split('Ki')[0]) 
    elif fnmatch.fnmatch(bw,'*Mi*'):
        bw=float(bw.rstrip('\r\n').split('Mi')[0]) * 1024
    elif fnmatch.fnmatch(bw,'*Gi*'):
        bw=float(bw.rstrip('\r\n').split('Gi')[0]) * 1024 * 1024
    elif fnmatch.fnmatch(bw,'*Pi*'):
        bw=float(bw.rstrip('\r\n').split('Pi')[0]) * 1024 * 1024 * 1024
    else:
        rw = float(bw / 1024)

    return round(bw,3)

def lat_value(line_value):
    unit=line_value.rstrip('\r\n').split(',')[0].split(')')[0].split('(')[1]
    lat=float(line_value.rstrip('\r\n').split(',')[2].split('=')[1])
    if unit == 'usec':
        lat = lat / 1000

    return round(lat,3)


def read_rs_log(path):
    run_log_list = fnmatch.filter(os.listdir(path),'*run.log')
    rs_list=[]
    
    for log in run_log_list:
        flg=False
        f_seek=0
        total_count=0
        write_iops=0
        read_iops=0
        total_iops=0
        write_bw=0
        read_bw=0
        total_bw=0
        write_lat=0
        write_slat=0
        write_clat=0
        read_lat=0
        read_slat=0
        read_clat=0
        total_lat=0
        total_slat=0
        total_clat=0
    
        task_name=log.rstrip('\r\n').split('_run.log')[0]
        size,run_type,iodepth,jobs,mode,rwmix,dev = log.rstrip('\r\n').split('-')
    
        iodepth = iodepth.split('iodepth')[0]
        jobs = jobs.split('jobs')[0]
        rwmix = rwmix.split('rw')[0]
        dev = dev.split('_')[0]
        
    
        f = open(path+'/'+log,'r')
        buffer = f.read()
        total_count = buffer.count('\n') + 1 
        client_num = buffer.count('hostname')
        f.close()
    
        if client_num == 0:
            client_num = 1
    
        for line in range(0,total_count):
            line_value=linecache.getline(path+'/'+log,line)
            if fnmatch.fnmatch(line_value,r'   read*'):
                read_iops=read_iops + iops_value(line_value)
                read_bw=read_bw + bw_value(line_value)
            elif fnmatch.fnmatch(line_value,'    clat*avg*'):
                read_clat=read_clat + lat_value(line_value)
            elif fnmatch.fnmatch(line_value,'     lat*avg*'):
                read_lat=read_lat + lat_value(line_value)
            elif fnmatch.fnmatch(line_value,'    slat*avg*'):
                read_slat=read_slat + lat_value(line_value)
            elif fnmatch.fnmatch(line_value,'  write*'):
                write_iops=write_iops + iops_value(line_value)
                write_bw=write_bw + bw_value(line_value)
            elif fnmatch.fnmatch(line_value,'    clat*avg*'):
                write_clat=write_clat + lat_value(line_value)
            elif fnmatch.fnmatch(line_value,'     lat*avg*'):
                write_lat=write_lat + lat_value(line_value)
            elif fnmatch.fnmatch(line_value,'    slat*avg*'):
                write_slat=write_slat + lat_value(line_value)

        total_iops = round((write_iops + read_iops),3)
        total_bw = round((write_bw + read_bw),3)
        if client_num > 0:
            total_lat = round(((write_lat + read_lat) / client_num),3)
            total_slat = round(((write_slat + read_slat) / client_num),3)
            total_clat = round(((write_clat + read_clat) / client_num),3)
        else:
            total_lat = round((write_lat + read_lat),3)
            total_slat = round((write_slat + read_slat),3)
            total_clat = round((write_clat + read_clat),3)
    
        #print 'task_name is :%s, client num is : %s ,size is : %s, run_type is %s, iodepth is %s ,jobs is %s , mode is %s ,rwmix is %s ,dev is %s ,read iops is %s, write iops is %s, total_iops is %s, read bw is %s, write bw is %s, total bw is %s, ,read_lat is %s, write lat is %s ,total lat is %s ,read clat is %s ,write clat is %s, total clat is %s, read slat %s, write slat %s ,total slat %s' % (task_name,client_num,size,run_type,iodepth,jobs,mode,rwmix,dev,read_iops,write_iops,total_iops,read_bw,write_bw,total_bw,read_lat,write_lat,total_lat,read_clat,write_clat,total_clat,read_slat,write_slat,total_slat)
        rs=(task_name,client_num,size,run_type,iodepth,jobs,mode,rwmix,dev,read_iops,write_iops,total_iops,read_bw,write_bw,total_bw,read_lat,write_lat,total_lat,read_clat,write_clat,total_clat,read_slat,write_slat,total_slat)
        rs_list.append(rs)

    return rs_list

def insert_value(rs_list):
    for rs in rs_list:
        rs=list(rs)
        for i in range(0,len(rs)):
            rs[i]=str(rs[i])
        rs_str='\",\"'.join(rs)
        rs_str='\"'+ rs_str +'\"'
        #rs_str='insert into "main".fio_rs_table(task_name,client_num,r_size,run_type,iodepth,jobs,rwmix,dev,read_iops,write_iops,total_iops,read_bw,write_bw,total_bw,write_lat,read_lat,total_lat,read_clat,write_clat,total_clat,read_slat,write_slat,total_slat) values(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)' % rs
        sql_str='insert into "main".fio_rs_table(task_name,client_num,r_size,run_type,iodepth,jobs,mode,rwmix,dev,read_iops,write_iops,total_iops,read_bw,write_bw,total_bw,read_lat,write_lat,total_lat,read_clat,write_clat,total_clat,read_slat,write_slat,total_slat) values(%s);' % rs_str 
        cur.execute(sql_str)
    conn.commit()

def exec_select(sql_str):
    sql_rs = cur.execute(sql_str)
    rs_list = []
    for row in sql_rs:
        rs_list.append(row[0])

    return rs_list

def exec_select_row():
    sql_str = 'select * from "main".fio_rs_table'
    sql_rs = cur.execute(sql_str)
    for row in sql_rs:
        rs_list = []
        for i in row:
            rs_list.append(str(i))
        
        print rs_list

#        for rg in range(len(row)):
#            if len(rs_list) < len(row):
#                rs_list.append([])
#            rs_list[rg].append(row[rg])
#
#    return rs_list


def get_client_num_list_fromdb():
    sql_str = 'select client_num from "main".fio_rs_table group by client_num;'
    return exec_select(sql_str)

def get_size_list_fromdb():
    sql_str = 'select r_size from "main".fio_rs_table group by r_size;'
    return exec_select(sql_str)

def get_mode_list_fromdb():
    sql_str = 'select mode from "main".fio_rs_table group by mode;'
    return exec_select(sql_str)

def get_jobs_list_fromdb():
    sql_str = 'select jobs from "main".fio_rs_table group by iodepth;'
    return exec_select(sql_str)

def get_iodepth_list_fromdb():
    sql_str = 'select iodepth from "main".fio_rs_table group by iodepth;'
    return exec_select(sql_str)

def get_run_type_list_fromdb():
    sql_str = 'select run_type from "main".fio_rs_table group by run_type;'
    return exec_select(sql_str)

def get_rwmix_list_fromdb():
    sql_str = 'select rwmix from "main".fio_rs_table group by rwmix;'
    return exec_select(sql_str)



def get_png_from_size(v_type):
    xlabel_title = 'Threads'
    if v_type == 'iops':
        sql_value = 'total_iops'
        ylabel_title = 'IOPS/s'
    if v_type == 'bw':
        sql_value = 'total_bw'
        ylabel_title = 'KBype/s'
    if v_type == 'lat':
        sql_value = 'total_lat'
        ylabel_title = 'ms'

    client_num_list=get_client_num_list_fromdb()
    size_list = get_size_list_fromdb()
    mode_list = get_mode_list_fromdb()
    jobs_list = get_jobs_list_fromdb()
    iodepth_list = get_iodepth_list_fromdb()
    run_type_list = get_run_type_list_fromdb()
    rwmix_list = get_rwmix_list_fromdb()

    for client in client_num_list:
        for run_type in run_type_list:
            for mode in mode_list:
                rs_dict = {}
                for size in size_list:
                    rs_dict[size] = {}
                    for jobs in jobs_list:
                        for iodepth in iodepth_list:
                            rs_dict[size][jobs+'job'+iodepth+'dp']={}
                            for rwmix in rwmix_list:
                                rs_dict[size][jobs+'job'+iodepth+'dp'][rwmix+'rw']=''
                                sql_str = 'select %s from "main".fio_rs_table where client_num="%s" and run_type="%s" and mode="%s" and r_size="%s" and jobs="%s" and iodepth="%s" and rwmix="%s"' % (sql_value,client,run_type,mode,size,jobs,iodepth,rwmix)
                                rs_list=exec_select(sql_str)
                                if len(rs_list) > 0:
                                    rs_dict[size][jobs+'job'+iodepth+'dp'][rwmix+'rw']=rs_list[0]
                                else:
                                    rs_dict[size][jobs+'job'+iodepth+'dp'][rwmix+'rw']=0

                #print rs_dict
                for r_size in rs_dict.keys():
                    if v_type == "iops":
                        prefix = r_size + '-' + run_type + '-' + str(client) + 'client-' + mode + '_iops'
                    elif v_type == "bw":
                        prefix = r_size + '-' + run_type + '-' + str(client) + 'client-' + mode + '_bw'
                    elif v_type == "lat":
                        prefix = r_size + '-' + run_type + '-' + str(client) + 'client-' + mode + '_lat'
                    dat_name = report_dir + '/' + prefix + '.dat'
                    gpm_name = report_dir + '/' + prefix + '.gpm'
                    if os.path.exists(dat_name):
                        os.remove(dat_name)
                    if os.path.exists(gpm_name):
                        os.remove(gpm_name)

                    dat_f = open(dat_name,'a+')
                    gpm_f = open(gpm_name,'a+')

                    gpm_flg = 0
                    for r_thread in rs_dict[r_size].keys():
                        value_list = []
                        #print r_size,thread
                        title_list = rs_dict[r_size][r_thread].keys()
                        #dat_f.write('thread ' + ' '.join(rwmix_title)+'\n')
                        for value in rs_dict[r_size][r_thread].keys():
                            value_list.append(str(rs_dict[r_size][r_thread][value]))
                        flg = 0
                        for i in value_list:
                            if i != '0':
                                flg = 1
                                break

                        if flg == 0:
                            dat_f.close()
                            os.remove(dat_name)
                            gpm_flg = 1
                            break

                        rs_str =  ' '.join(value_list)
                        dat_f.write(r_thread + ' ' + rs_str+'\n')
                    dat_f.close()

                    if gpm_flg == 0:
                        gpm_f.write('set title "%s"\nset terminal png size 680,480\n' % (prefix))
                        gpm_f.write('set output "%s.png"\n' % (report_dir + '/' + prefix))
                        gpm_f.write('set palette rgbformulae 7,5,15\n')
                        gpm_f.write('set style fill transparent solid 0.9 noborder\n')
                        gpm_f.write('set auto x\n')
                        gpm_f.write('set grid\n')
                        gpm_f.write('set xrange [-1:]\n')
                        gpm_f.write('set yrange [0:]\n')
                        gpm_f.write('set xlabel "%s"\n' % (xlabel_title))
                        gpm_f.write('set ylabel "%s"\n' % (ylabel_title))
                        gpm_f.write('set boxwidth 0.5 relative\n')
                        gpm_f.write('set xtics rotate by -45\n')
                        gpm_f.write('set key top right reverse\n')
                        gpm_f.write('set style data histograms\n')
                        gpm_f.write('set style histogram cluster gap 1\n')
                        gpm_f.write('set style fill solid 1.00 border -1\n')
                        gpm_f.write('plot "%s" using 2:xtic(1) title ' % (dat_name))

                        title_len=len(title_list)
                        data_flg = 3
                        for rg in range(title_len):
                            if rg == 0:
                                gpm_f.write('"%s", '% title_list[rg])
                            else:
                                if rg != (title_len - 1):
                                    gpm_f.write('\'\' using %s title "%s", ' % (data_flg,title_list[rg]))
                                elif title_len != 1:
                                    gpm_f.write('\'\' using %s title "%s"\n ' % (data_flg,title_list[rg]))
                                data_flg = data_flg + 1
                        gpm_f.close()
                        os.system('gnuplot ' + gpm_name)
                    else:
                        gpm_f.close()
                        os.remove(gpm_name)

    return 0

def get_png_from_thread(v_type):
    xlabel_title = 'client_num'
    if v_type == 'iops':
        sql_value = 'total_iops'
        ylabel_title = 'IOPS/s'
    if v_type == 'bw':
        sql_value = 'total_bw'
        ylabel_title = 'KBype/s'
    if v_type == 'lat':
        sql_value = 'total_lat'
        ylabel_title = 'ms'

    client_num_list=get_client_num_list_fromdb()
    size_list = get_size_list_fromdb()
    mode_list = get_mode_list_fromdb()
    jobs_list = get_jobs_list_fromdb()
    iodepth_list = get_iodepth_list_fromdb()
    run_type_list = get_run_type_list_fromdb()
    rwmix_list = get_rwmix_list_fromdb()

    for jobs in jobs_list:
        for iodepth in iodepth_list:
            #thread=int(jobs) * int(iodepth)
            thread=jobs+'job'+iodepth+'dp-'+str(int(jobs) * int(iodepth))
            for run_type in run_type_list:
                for mode in mode_list:
                    rs_dict = {}
                    for size in size_list:
                        rs_dict[size] = {}
                        for client in client_num_list:
                            rs_dict[size][client]={}
                            for rwmix in rwmix_list:
                                rs_dict[size][client][rwmix+'rw']=''
                                sql_str = 'select %s from "main".fio_rs_table where client_num="%s" and run_type="%s" and mode="%s" and r_size="%s" and jobs="%s" and iodepth="%s" and rwmix="%s"' % (sql_value,client,run_type,mode,size,jobs,iodepth,rwmix)
                                rs_list=exec_select(sql_str)
                                if len(rs_list) > 0:
                                    rs_dict[size][client][rwmix+'rw']=rs_list[0]
                                else:
                                    rs_dict[size][client][rwmix+'rw']=0

                #print rs_dict
                for r_size in rs_dict.keys():
                    if v_type == "iops":
                        prefix = r_size + '-' + run_type + '-' + thread + 'th-' + mode + '_iops'
                    elif v_type == "bw":
                        prefix = r_size + '-' + run_type + '-' + thread + 'th-' + mode + '_bw'
                    elif v_type == "lat":
                        prefix = r_size + '-' + run_type + '-' + thread + 'th-' + mode + '_lat'
                    dat_name = report_dir + '/' + prefix + '.dat'
                    gpm_name = report_dir + '/' + prefix + '.gpm'
                    if os.path.exists(dat_name):
                        os.remove(dat_name)
                    if os.path.exists(gpm_name):
                        os.remove(gpm_name)

                    dat_f = open(dat_name,'a+')
                    gpm_f = open(gpm_name,'a+')

                    gpm_flg = 0
                    for r_client in rs_dict[r_size].keys():
                        value_list = []
                        #print r_size,thread
                        title_list = rs_dict[r_size][r_client].keys()
                        #dat_f.write('thread ' + ' '.join(rwmix_title)+'\n')
                        for value in rs_dict[r_size][r_client].keys():
                            value_list.append(str(rs_dict[r_size][r_client][value]))
                        flg = 0
                        for i in value_list:
                            if i != '0':
                                flg = 1
                                break

                        if flg == 0:
                            dat_f.close()
                            os.remove(dat_name)
                            gpm_flg = 1
                            break

                        rs_str =  ' '.join(value_list)
                        dat_f.write(str(r_client)+ 'client ' + rs_str+'\n')
                    dat_f.close()

                    if gpm_flg == 0:
                        gpm_f.write('set title "%s"\nset terminal png size 680,480\n' % (prefix))
                        gpm_f.write('set output "%s.png"\n' % (report_dir + '/' + prefix))
                        gpm_f.write('set palette rgbformulae 7,5,15\n')
                        gpm_f.write('set style fill transparent solid 0.9 noborder\n')
                        gpm_f.write('set auto x\n')
                        gpm_f.write('set grid\n')
                        gpm_f.write('set xrange [-1:]\n')
                        gpm_f.write('set yrange [0:]\n')
                        gpm_f.write('set xlabel "%s"\n' % (xlabel_title))
                        gpm_f.write('set ylabel "%s"\n' % (ylabel_title))
                        gpm_f.write('set boxwidth 0.5 relative\n')
                        gpm_f.write('set xtics rotate by -45\n')
                        gpm_f.write('set key top right reverse\n')
                        gpm_f.write('set style data histograms\n')
                        gpm_f.write('set style histogram cluster gap 1\n')
                        gpm_f.write('set style fill solid 1.00 border -1\n')
                        gpm_f.write('plot "%s" using 2:xtic(1) title ' % (dat_name))

                        title_len=len(title_list)
                        data_flg = 3
                        for rg in range(title_len):
                            if rg == 0:
                                gpm_f.write('"%s", '% title_list[rg])
                            else:
                                if rg != (title_len - 1):
                                    gpm_f.write('\'\' using %s title "%s", ' % (data_flg,title_list[rg]))
                                elif title_len != 1:
                                    gpm_f.write('\'\' using %s title "%s"\n ' % (data_flg,title_list[rg]))
                                data_flg = data_flg + 1
                        gpm_f.close()
                        os.system('gnuplot ' + gpm_name)
                    else:
                        gpm_f.close()
                        os.remove(gpm_name)

    return 0
            #print value_list
            #print bw_rs_dict
            #print lat_rs_dict


def create_report_css(file_path):
    if os.path.exists(file_path):
        os.remove(file_path)
    f = open(file_path,'a+')
    content="""
* {
     margin:0;
     padding:0;
}
body {
    margin:0px auto;
    width:90%;
    font-size:14px;
}

div {
    clear:both;
}

h1 {
    margin-top:10px;
    margin-bottom:10px;
    width:100%;
}

h2 {
    margin-top:10px;
    margin-bottom:10px;
    width:100%;
}

h3 {
    margin-top:10px;
    margin-bottom:10px;
    width:100%;
}

ul {
    list-style:none;
    margin:100px auto;
    width:100%;
    text-align:center;
}

div#test_case ul li {
    clear:both;
    float:left;
    margin:0px auto;
    width:50%;
    text-align:left;
    font-size:18px;
}

ul li {
    float:left;
    margin:0px auto;
    width:50%;
    text-align:center;
    font-size:18px;
    margin-bottom:20px;
}
ul li img{
    width:400px;
    height:360px;
}

table{
    margin:0px auto;
}   
td{
    width:100px;
    height:24px;
    text-align:center;
    line-height:24px;
    border:1px solid silver;
}
.red{
    color:red;
}   
.top{
    background:#CCCCCC;
    cursor:pointer;
}   
.up{
    background:#FFFFCC no-repeat right 5px;
}   
.down{
    background:#FFFFCC no-repeat right 5px;
}   
.hov{
    background:#F0EFE5;
} 
    
    """
    f.write(content)
    f.close()

    return 0

def create_report_js(file_path):
    if os.path.exists(file_path):
        os.remove(file_path)
    f = open(file_path,'a+')
    scripts_str="""
    var tableSort = function(){   
    this.initialize.apply(this,arguments);   
    }   
      
    tableSort.prototype = {   
      
    initialize : function(tableId,clickRow,startRow,endRow,classUp,classDown,selectClass){   
    this.Table = document.getElementById(tableId);   
    this.rows = this.Table.rows;//所有行   
    this.Tags = this.rows[clickRow-1].cells;//标签td   
    this.up = classUp;   
    this.down = classDown;   
    this.startRow = startRow;   
    this.selectClass = selectClass;   
    this.endRow = (endRow == 999? this.rows.length : endRow);   
    this.T2Arr = this._td2Array();//所有受影响的td的二维数组   
    this.setShow();   
    },   
    //设置标签切换   
    setShow:function(){   
    var defaultClass = this.Tags[0].className;   
    for(var Tag ,i=0;Tag = this.Tags[i];i++){   
    Tag.index = i;   
    addEventListener(Tag ,'click', Bind(Tag,statu));   
    }   
    var _this =this;   
    var turn = 0;   
    function statu(){   
    for(var i=0;i<_this.Tags.length;i++){   
    _this.Tags[i].className = defaultClass;   
    }   
    if(turn==0){   
    addClass(this,_this.down)   
    _this.startArray(0,this.index);   
    turn=1;   
    }else{   
    addClass(this,_this.up)   
    _this.startArray(1,this.index);   
    turn=0;   
    }   
    }   
    },   
    //设置选中列样式   
    colClassSet:function(num,cla){   
    //得到关联到的td   
    for(var i= (this.startRow-1);i<(this.endRow);i++){   
    for(var n=0;n<this.rows[i].cells.length;n++){   
    removeClass(this.rows[i].cells[n],cla);   
    }   
    addClass(this.rows[i].cells[num],cla);   
    }   
    },   
    //开始排序 num 根据第几列排序 aord 逆序还是顺序   
    startArray:function(aord,num){   
    var afterSort = this.sortMethod(this.T2Arr,aord,num);//排序后的二维数组传到排序方法中去   
    this.array2Td(num,afterSort);//输出   
    },   
    //将受影响的行和列转换成二维数组   
    _td2Array:function(){   
    var arr=[];   
    for(var i=(this.startRow-1),l=0;i<(this.endRow);i++,l++){   
    arr[l]=[];   
    for(var n=0;n<this.rows[i].cells.length;n++){   
    arr[l].push(this.rows[i].cells[n].innerHTML);   
    }   
    }   
    return arr;   
    },   
    //根据排序后的二维数组来输出相应的行和列的 innerHTML   
    array2Td:function(num,arr){   
    this.colClassSet(num,this.selectClass);   
    for(var i= (this.startRow-1),l=0;i<(this.endRow);i++,l++){   
    for(var n=0;n<this.Tags.length;n++){   
    this.rows[i].cells[n].innerHTML = arr[l][n];   
    }   
    }   
    },   
    //传进来一个二维数组，根据二维数组的子项中的w项排序，再返回排序后的二维数组   
    sortMethod:function(arr,aord,w){   
    //var effectCol = this.getColByNum(whichCol);   
    arr.sort(function(a,b){   
    x = killHTML(a[w]);   
    y = killHTML(b[w]);   
    x = x.replace(/,/g,'');   
    y = y.replace(/,/g,'');   
    switch (isNaN(x)){   
    case false:   
    return Number(x) - Number(y);   
    break;   
    case true:   
    return x.localeCompare(y);   
    break;   
    }   
    });   
    arr = aord==0?arr:arr.reverse();   
    return arr;   
    }   
    }   
    /*-----------------------------------*/   
    function addEventListener(o,type,fn){   
    if(o.attachEvent){o.attachEvent('on'+type,fn)}   
    else if(o.addEventListener){o.addEventListener(type,fn,false)}   
    else{o['on'+type] = fn;}   
    }   
      
    function hasClass(element, className) {   
    var reg = new RegExp('(\\s|^)'+className+'(\\s|$)');   
    return element.className.match(reg);   
    }   
      
    function addClass(element, className) {   
    if (!this.hasClass(element, className))   
    {   
    element.className += " "+className;   
    }   
    }   
      
    function removeClass(element, className) {   
    if (hasClass(element, className)) {   
    var reg = new RegExp('(\\s|^)'+className+'(\\s|$)');   
    element.className = element.className.replace(reg,' ');   
    }   
    }   
      
    var Bind = function(object, fun) {   
    return function() {   
    return fun.apply(object, arguments);   
    }   
    }   
    //去掉所有的html标记   
    function killHTML(str){   
    return str.replace(/<[^>]+>/g,"");   
    }   
    //------------------------------------------------   
    //tableid 第几行是标签行，从第几行开始排序，第几行结束排序(999表示最后) 升序标签样式，降序标签样式 选中列样式   
    //注意标签行的class应该是一致的   
    var ex1 = new tableSort('iops_table',1,2,999,'up','down','hov');   
    var ex2 = new tableSort('bw_table',1,2,999,'up','down','hov');   
"""
    f.write(scripts_str)
    f.close()

def create_report_html(dir_path):
    file_name='report.html'
    file_path=dir_path + '/' + file_name


    if os.path.exists(file_path):
        os.remove(file_path)

    iops_png_client_list = fnmatch.filter(os.listdir(dir_path),"*client-*_iops.png")
    bw_png_client_list = fnmatch.filter(os.listdir(dir_path),"*client-*_bw.png")
    lat_png_client_list = fnmatch.filter(os.listdir(dir_path),"*client-*_lat.png")
    #print iops_png_client_list
    #print bw_png_client_list
    #print lat_png_client_list

    iops_png_thread_list = fnmatch.filter(os.listdir(dir_path),"*th-*_iops.png")
    bw_png_thread_list = fnmatch.filter(os.listdir(dir_path),"*th-*_bw.png")
    lat_png_thread_list = fnmatch.filter(os.listdir(dir_path),"*th-*_lat.png")
    #print iops_png_thread_list
    #print bw_png_thread_list
    #print lat_png_thread_list

    f = open(file_path,'a+')
    ## write des
    f.write('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n')
    f.write('<html xmlns="http://www.w3.org/1999/xhtml">\n')
    ## head
    f.write('<head>\n')
    f.write('<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />')
    f.write('<link rel="stylesheet" type="text/css" href="style/basic.css" />')
    f.write('<title>%s</title>\n' % 'test title')
    f.write('</head>\n')

    ## body
    f.write('<body >\n')
    ## title div
    f.write('<div id="title">')
    f.write('<h1>%s</h1>' % 'FIO performance test report !')
    f.write('</div>\n')

    ## test_case div 
    f.write('<div id="test_case">')
    f.write('<h2>%s</h2>\n' % 'Test case')

    f.write('\t<ul>\n')
    for path in path_list.split(','):
        f.write('\t\t<li><a href="%s" >%s</a></li>\n' % (path,path))
    f.write('\t</ul>\n')
    f.write('</div>\n')
    ## test data table
    f.write('<div id="test_data_table">')
    f.write('<h2>%s</h2>\n' % 'Test data table')
    f.write('\t<div id="iops_div" >\n')

    f.write('\t</div>\n')

    f.write('\t\t<h3>IOPS table </h3>\n')
    f.write('<table cellpadding="0" id="iops_table" >\n')
    f.write('<tr class="top" >\n')
    iops_title_list=['client_num','r_size','run_type','iodepth','jobs','mode','rwmix','read_iops','write_iops','total_iops','total_lat']
    for iops in iops_title_list:
        f.write('<th class="red" >%s</th>\n' % iops)
    f.write('</tr>\n')

    sql_str = 'select client_num,r_size,run_type,iodepth,jobs,mode,rwmix,read_iops,write_iops,total_iops,total_lat from "main".fio_rs_table'
    sql_rs = cur.execute(sql_str)
    for row in sql_rs:
        f.write('<tr>\n')
        rs_list = []
        for row_value in row:
            f.write('<td>%s</td>\n' % row_value)
        f.write('</tr>\n')
    f.write('</table>')

    f.write('\t\t<h3>Throughput table </h3>\n')
    f.write('<table cellpadding="0" id="bw_table" >\n')
    f.write('<tr class="top" >\n')

    bw_title_list=['client_num','r_size','run_type','iodepth','jobs','mode','rwmix','read_bw','write_bw','total_bw','total_lat']
    for bw in bw_title_list:
        f.write('<th class="red" >%s</th>\n' % bw)
    f.write('</tr>\n')

    sql_str = 'select client_num,r_size,run_type,iodepth,jobs,mode,rwmix,read_bw,write_bw,total_bw,total_lat from "main".fio_rs_table'
    sql_rs = cur.execute(sql_str)
    for row in sql_rs:
        f.write('<tr>\n')
        rs_list = []
        for row_value in row:
            f.write('<td>%s</td>\n' % row_value)
        f.write('</tr>\n')
    f.write('</table>')

    f.write('</div>\n')

    ##
    f.write('<div id="client_report" >')
    f.write('<h2>%s</h2>\n' % 'PNG result from size by client number')

    ### client report iops
    f.write('\t<div id="client_report_iops" >\n')
    f.write('\t\t<h3>IOPS result from size base by client number </h3>\n')

    f.write('\t\t<ul>\n')
    for png in iops_png_client_list: 
        f.write('\t\t\t<li>')
        f.write('<img src="%s" alt="%s" /></br>%s</li> \n' % (png, png.split('.')[0],png.split('.')[0]))

    f.write('\t\t</ul>\n')
    f.write('\t</div>\n')

    ### client report bw
    f.write('\t<div id="client_report_bw">\n')
    f.write('\t\t<h3>Throughput result from size base by client Number </h3>\n')

    f.write('\t\t<ul>\n')
    for png in bw_png_client_list: 
        f.write('\t\t\t<li>')
        f.write('<img src="%s" alt="%s" /></br>%s</li> \n' % (png,png.split('.')[0],png.split('.')[0]))

    f.write('\t\t</ul>\n')
    f.write('\t</div>\n')

    ### client report lat
    f.write('\t<div id="client_report_bw" >\n')
    f.write('\t\t<h3>Latcy result from size base by client Number </h3>\n')
    
    f.write('\t\t<ul>\n')
    for png in lat_png_client_list: 
        f.write('\t\t\t<li>')
        f.write('<img src="%s" alt="%s" /></br>%s</li> \n' % (png,png.split('.')[0],png.split('.')[0]))
    
    f.write('\t\t</ul>\n')
    f.write('\t</div>\n')
    #####

    ##end 
    f.write('</div>\n')
    ##
    ##
    f.write('<div id="thread_report" >\n')
    f.write('\t<h2>%s</h2>\n' % 'PNG result from size by threads')

    ### client report iops
    f.write('\t<div id="client_report_iops" >\n')
    f.write('\t\t<h3>IOPS result from size base by threads </h3>\n')

    f.write('\t\t<ul>\n')
    for png in iops_png_thread_list: 
        f.write('\t\t\t<li>')
        f.write('<img src="%s" alt="%s" /></br>%s</li>\n' % (png, png.split('.')[0],png.split('.')[0]))

    f.write('\t\t</ul>\n')
    f.write('\t</div>\n')

    ### client report bw
    f.write('\t<div id="client_report_bw">\n')
    f.write('\t\t<h3>Throughput result from size base by threads </h3>\n')

    f.write('\t\t<ul>\n')
    for png in bw_png_thread_list: 
        f.write('\t\t\t<li>')
        f.write('<img src="%s" alt="%s" /></br>%s</li> \n' % (png,png.split('.')[0],png.split('.')[0]) )

    f.write('\t\t</ul>\n')
    f.write('\t</div>\n')

    ### client report lat
    f.write('\t<div id="client_report_bw">\n')
    f.write('\t\t<h3>Latcy result from size base by threads </h3>\n')
    
    f.write('\t\t<ul>\n')
    for png in lat_png_thread_list: 
        f.write('\t\t\t<li>')
        f.write('<img src="%s" alt="%s" /></br>%s</li> \n' % (png,png.split('.')[0],png.split('.')[0]))
    
    f.write('\t\t</ul>\n')
    f.write('\t</div>\n')
    f.write('</div>\n')
    #####

    f.write('</body>\n')
    f.write('</html>\n')
    f.write('<script src="js/sort.js"></script>')
    f.close()

    return 0

def usage():
    print "usage:\n\tpython gen_report.py -d fio_test_task\n -d   --result_dir_list  fio test result dir\n "
    sys.exit(3)

try:
    options,args = getopt.getopt(sys.argv[1:],"hl:",["help","ip_list="])
except getopt.GetoptError:
    usage()

path_list='./fio_test_task'

for name,value in options:
    if name in ("-h","--help"):
        usage()
    if name in ("-d","--result_dir_list"):
        path_list=value
    
report_dir = './report'
if os.path.exists(report_dir):
    os.rename(report_dir,report_dir + '_' + str(int(time.time())) + '_bak')
os.makedirs(report_dir)
os.makedirs(report_dir+'/style')
os.makedirs(report_dir+'/js')

css_file=report_dir + '/style/basic.css'
js_file=report_dir + '/js/sort.js'

conn = sqlite3.connect('./fio_rs.db')
cur = conn.cursor()

create_db_table()



for path in path_list.split(','):
    os.system('cp -r %s %s' % (path,report_dir))
    rs_list=read_rs_log(path)
    insert_value(rs_list)


get_png_from_size('iops')
get_png_from_size('bw')
get_png_from_size('lat')

get_png_from_thread('iops')
get_png_from_thread('bw')
get_png_from_thread('lat')

create_report_css(css_file)
create_report_js(js_file)
create_report_html(report_dir)

