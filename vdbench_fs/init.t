#!/bin/bash
# vdbench test: ./tests/init/init.t ,v 1.0 Mon Nov 20 15:35:05 CST 2017 $
desc="====fio test on [ init ] ===="

dir=`dirname $0`
. ${dir}/../../misc.sh
. ${dir}/../../conf

echo "1..1"
if [ ! -z ${cache_io} ] && [ "${cache_io}" == "True" ]
then
    cache_flag='-c'
else
    cache_flag=''
fi
if [ ! -z "${file_size}" ]
then
    size_flag="-z ${file_size}"
else
    size_flag=""
fi
if [ ! -z "${run_time}" ]
then
    run_time_flag="-r ${run_time}"
else
    run_time_flag=""
fi

if [ ! -z "${host_list}" ]
then
    host_list_flag="-l ${host_list}"
else
    host_list_flag=
fi

if [ ! -z "${depth}" ]
then
    depth_flag="-D ${depth}"
else
    depth_flag=""
fi

if [ ! -z "${width}" ]
then
    width_flag="-W ${width}"
else
    width_flag=""
fi

if [ ! -z "${files}" ]
then
    files_flag="-F ${files}"
else
    files_flag=""
fi

if [ "$shared" == 'yes' ]
then
    shared_flag="-S"
else
    shared_flag=""
fi

if [ ! -z "$fileselect" ]
then
    select_flag="-C $fileselect"
else
    select_flag=""
fi

vd_conf=`/bin/bash ${dir}/../../genvdbench.sh -d ${test_dir} ${shared_flag} ${cache_flag}  ${run_time_flag} -b 1024k ${size_flag} ${host_list_flag} -m write ${run_time_flag} ${depth_flag} ${files_flag} ${width_flag} ${select_flag} -t 1 -M 0 -x ${run_result_dir}/`


mv $vd_conf ${run_result_dir}/init.vd
sed -i 's/format=no/format=only/g' ${run_result_dir}/init.vd

#echo $vd_conf |grep -q '.vd$' 
#if [ $? -ne 0 ]
#then
#    echo "genvdbench conf failed!"
#    exit 3
#fi
#rs_name=`basename $vd_conf|cut -d '.' -f 1`
mkdir -p ${run_result_dir}/init
mkdir -p ${run_result_dir}/init/logs


expect_success /opt/vdbench/vdbench -f ${run_result_dir}/init.vd -o `pwd`/${run_result_dir}/init/logs
