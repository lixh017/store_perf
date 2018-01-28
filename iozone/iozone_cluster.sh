#!/bin/bash
# Modified      Date           Comments
# Li Gang       2017-08-25     Fix: fix bug when running single host test
# Li Gang       2017-08-25     Fix: recompute file size 
# Li Gang       2017-08-24     Fix: modify file size to "kb" based value
# Li Gang       2017-08-21     Fix: modify file size bases on thread number
# Li Gang       2017-08-17     Fix: add one input parameter [product_type]
# Li Gang       2017-07-17     Fix: enhance [mkdir] and file system type check before running test
# Li Gang       2017-06-21     Modify usage, fix bug when running iozone test on single node  
# Li Gang       2017-04-11     Last update: check iozone env


# 说明:
# 1) 运行集群测试和单机测试时，客户端的挂载目录必须保持一致;
# 2) 所有节点之间 需要建立ssh 互信任。


usage()
{
#    echo "$0 product_type total_file_size record_size test_type_list thread  test_dir host_list
#example:
#    [cluster test]: sh $0 WooStor 96G 1M 0,1 8 /mnt/yfs 172.16.16.21,172.16.16.22,172.16.16.23
#    [single node]:  sh $0 YeeOS  256G 256k 0,1 8 /mnt/yfs 172.16.16.24"
#
    echo "$0 [-p product_type] [-f total_size] [-s io_size] [-i test_type] [-t thread] [-d test_dir] [-c client_list]
example:
    [cluster test]: sh $0 -p YeeOS -f 100G -s 1M -i 0,1 -t 8 -d /mnt/yfs/iozone -c 172.16.16.21,172.16.16.22
    [single test]: sh $0 -p YeeOS -f 100G -s 1M -i 0,1 -t 8 -d /mnt/yfs/iozone -c 172.16.16.21
    [local test]: sh $0 -p YeeOS -f 100G -s 1M -i 0,1 -t 8 -d /mnt/yfs/iozone 
    "
    exit 1
}



check_iozone_env()
{
   which iozone >> /dev/null 2>&1
   return $?   
}


function create_as_list()
{
    local thread=$1
    local host_name=$2
    local dir=$3
    local iozone_exe_dir=$4
    local result_dir=$5
    #> ${result_dir}/client_as_list_${thread}

    for j in $host_name
    do
        for ((t=1;t<=$thread;t++))
        do
            ssh $j "mkdir -p $j $dir/$j/thread$t"
            echo "$j $dir/$j/thread$t ${iozone_exe_dir}" >> ${result_dir}/client_as_list_${thread}
        done
    done
}

check_mkdir()
{
    local dir_name=$1
    local ret_mkdir=

    mkdir -p ${dir_name}
    ret_mkdir=$?
    if [[ ${ret_mkdir} -gt 0 ]]
    then
         echo "mkdir [$dir_name] failed, abort test now !"
         exit ${ret_mkdir}
    else
      return 0
    fi
}


check_filesystem()
{
    local dir_name=$1
    local file_system_type=$2
    
    df -t ${file_system_type} ${dir_name} >> /dev/null 2>&1
    local ret_check_fs=$?
    if [[ ${ret_check_fs} -gt 0 ]]
    then
        echo "Error occurs when verifying file system type on dir [${dir_name}], abort test !"
        exit ${ret_check_fs}
    else
       return ${ret_check_fs}
    fi
}
  


function convert_to_kbyte()
{
    local sdata=$1

    local len=${#sdata}
    local start_pos=`expr $len - 1`
    local last_char=`echo ${sdata:$start_pos:1}|tr [A-Z] [a-z]`
    local data_conv=

    if [[ "${last_char}"X = "m"X ]];then
       data_conv=`awk 'BEGIN{printf "%.0f\n", '${sdata%?}'*'1024'}'`
    elif [[ "${last_char}"X = "g"X ]];then
       data_conv=`awk 'BEGIN{printf "%.0f\n", '${sdata%?}'*'1024'*'1024'}'`
    elif [[ "${last_char}"X = "k"X ]];then 
       data_conv=${sdata}
    else   # [byte] unit, need to divide by 1024
       data_conv=`awk 'BEGIN{printf "%.0f\n", '${sdata%?}'/'1024'}'`
    fi          

    echo ${data_conv}
}



function convert_to_mbyte()
{
    local sdata=$1

    local len=${#sdata}
    local start_pos=`expr $len - 1`
    local last_char=`echo ${sdata:$start_pos:1}|tr [A-Z] [a-z]`
    local data_conv=

    if [[ "${last_char}"X = "k"X ]];then
       data_conv=`awk 'BEGIN{printf "%.0f\n", '${sdata%?}'/'1024'}'`
    elif [[ "${last_char}"X = "g"X ]];then
       data_conv=`awk 'BEGIN{printf "%.0f\n", '${sdata%?}'*'1024'}'`
    elif [[ "${last_char}"X = "m"X ]];then 
       data_conv=${sdata}
    else   # [byte] unit, need to divide by 1024 ^ 2
       data_conv=`awk 'BEGIN{printf "%.0f\n", '${sdata%?}'/'1024'/'1024'}'`
    fi          

    echo ${data_conv}
}


function convert_to_gbyte()
{
    local sdata=$1

    local len=${#sdata}
    local start_pos=`expr $len - 1`
    local last_char=`echo ${sdata:$start_pos:1}|tr [A-Z] [a-z]`
    local data_conv=

    if [[ "${last_char}"X = "m"X ]];then
       data_conv=`awk 'BEGIN{printf "%.0f\n", '${sdata%?}'/'1024'}'`
    elif [[ "${last_char}"X = "k"X ]];then
       data_conv=`awk 'BEGIN{printf "%.0f\n", '${sdata%?}'/'1024'/'1024'}'`
    elif [[ "${last_char}"X = "g"X ]];then 
       data_conv=${sdata}
    else   # [byte] unit, need to divide by (1024 ^3)
       data_conv=`awk 'BEGIN{printf "%.0f\n", '${sdata%?}'/'1024'/'1024'/'1024'}'`
    fi          

    echo ${data_conv}
}

[[ $# -gt 0 ]] || usage

check_iozone_env
ret_check=$?
if [[ ${ret_check} -gt 0 ]]; then
    echo "iozone is not installed on the host, abort test !"
    exit 2
else
    iozone_exe_dir=`which iozone`
fi

cur_dir=$PWD

#product_type=$1
#f_total_size=$2
#rs=$3
#t_type=$4
#thread=$5
#test_dir=$6
#host_name="$7"


while getopts "f:s:i:t:d:c:h" Option
do
    case $Option in
        #p) product_type="$OPTARG" ;;
        f) f_total_size="$OPTARG" ;;
        s) rs="$OPTARG" ;;
        i) t_type="$OPTARG" ;;
        t) thread="$OPTARG" ;;
        d) test_dir="$OPTARG" ;;
        c) host_name="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

t_type="`echo $t_type | tr ',' ' '`"
host_name="`echo $host_name | tr ',' ' '`"

t_type_name=
for t_t in ${t_type}
do
    if [ -z ${t_type_name} ]
    then
        t_type_name=${t_t}
    else
        t_type_name="${t_type_name}-${t_t}"
    fi
done

cl_num=`echo ${host_name}|wc -w`
run_thread=`expr ${cl_num} \* ${thread}`

if [ ${cl_num} -eq 0 ]
then
    result_dir=iozone_${thread}th_${rs}_1client_${t_type_name}_result
    host_name='localhost'
else
    result_dir=iozone_${thread}th_${rs}_${cl_num}client_${t_type_name}_result
fi

export RSH=ssh
#export rsh=ssh

rm -rf ${result_dir}
mkdir -p ${result_dir}

# create config file for iozone cluster test
# example:
#host41 /mnt/yfs/iozone_cluster_test/host1/1/thread8  /usr/local/bin/iozone
#host41 /mnt/yfs/iozone_cluster_test/host1/1/thread16  /usr/local/bin/iozone
#host41 /mnt/yfs/iozone_cluster_test/host1/1/thread32  /usr/local/bin/iozone
#host41 /mnt/yfs/iozone_cluster_test/host1/1/thread64  /usr/local/bin/iozone
#host41 /mnt/yfs/iozone_cluster_test/host1/1/thread128  /usr/local/bin/iozone
#......

# Modify: 2017-06-21
# description: generate "client_as_list" file only in cluster mode
if [[ ${cl_num} -gt 0 ]]
then
   #sh client_as_list_for_ssh.sh ${thread} "${host_name}" ${test_dir}
   create_as_list ${thread} "${host_name}" ${test_dir} ${iozone_exe_dir} ${result_dir}

   #create test dir for this client
   #for d in `cat client_as_list_${thread}|awk {'print $2'}`
   #do
   #    check_mkdir $d
   #done
   # verify last dir in dir list
   #check_filesystem $d ${product_type}
else   # create dir: /mnt/woostor/iozone_cluster_test/<ip>
   check_mkdir ${test_dir}/${host_name}
fi
#/bin/bash client_as_list_for_ssh.sh ${thread} "${host_name}" ${test_dir}
#create_as_list ${thread} "${host_name}" ${test_dir} ${iozone_exe_dir} ${result_dir}
#create test dir for this client
 

test_type=
#if [ $type == "write" ]
#then
#    io_type='0'
#elif [ $t_type == "read" ]
#then
#   io_type='1' 
#elif [ $t_type == "randrw" ]
#then
#    io_type='2'
#elif [ $t_type == 'all' ]
#then
#    io_type='0 1 2'
#else
#    echo "This iozone test only support [write|read|randrw|all] ,all means [ write && read && randrw ] "
#    exit 2
#fi

#for i in ${io_type}
for i in ${t_type}
do
   test_type="${test_type} -i $i"
done
#test type:  -i 0 -i 1 -i 2 ...

# add: 2017-06-21
if [[ ${cl_num} -gt 0 ]]
then
    extra_option=" -+m ${result_dir}/client_as_list_${thread} "
   #extra_option=" -+m client_as_list_${thread} "
elif [[ ${cl_num} -eq 0 ]]
then
    extra_option=""
    cd ${test_dir}/${host_name}
    #check_filesystem "${test_dir}/${host_name}" ${product_type}
else
    echo "Invalid host number is detected, please verify if the value of parameter [host_name] is correct !"
    exit 3
fi
#extra_option=" -+m ${result_dir}/client_as_list_${thread} "

# 2017-08-25:  recompute file size
# 2017-08-24:  modify file size to "kb" based value
# 2017-08-21:  modify file size based on thread number
len=${#f_total_size}
len_2=`expr $len - 1`
# get real data, for example: input string=128g  return "128"
f_test_size_for_compute=`echo ${f_total_size:0:${len_2}}`
  
# get unit, for example: input str=128g  return "g" 
start_pos=`expr $len - 1`
f_size_unit=`echo ${f_total_size:$start_pos:1}|tr [A-Z] [a-z]`

f_test_size_per_thread=`awk 'BEGIN{printf "%.2f\n", '${f_test_size_for_compute}'/'${thread}'}'`
f_test_size="${f_test_size_per_thread}${f_size_unit}"

# bug: file size is used incorrectly  when [iozone] is running
# fix: by default iozone uses "kb" for file size, so need to convert value to [kbyte]
f_test_size_new=`convert_to_kbyte ${f_test_size}`

if [[ ${cl_num} -eq 0 ]]
then
    mkdir -p ${test_dir}/${host_name}; mkdir -p ${cur_dir}/${result_dir}; cd ${test_dir}/${host_name}; 
    ${iozone_exe_dir} ${test_type} -s ${f_test_size_new} -r ${rs} -+n -wpIC -Rb ${cur_dir}/${result_dir}/${result_dir}.xls -t ${thread} ${extra_option}  |tee -a ${cur_dir}/${result_dir}/${result_dir}.log
    ret=$?
    cd ${cur_dir}
    if [ $ret -ne 0 ] 
    then
    	exit 3
    fi
else
    ${iozone_exe_dir} ${test_type} -s ${f_test_size_new} -r ${rs} -+n -wpIC -Rb ${cur_dir}/${result_dir}/${result_dir}.xls -t ${run_thread} ${extra_option}  |tee -a ${cur_dir}/${result_dir}/${result_dir}.log
    ret=$?
    if [ $ret -ne 0 ] 
    then
    	exit 3
    fi
fi

# after test, return to original dir

