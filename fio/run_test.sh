#########################################################################
# File Name: run_test.sh
# Author: Ethan
# mail: lixianghan@daowoo.com,lixh017@163.com
# Created Time: Mon 16 Oct 2017 02:30:25 PM CST
#########################################################################
#!/bin/bash
export LC_ALL="en_US.utf-8"
export LANG="en_US.utf-8"


source ./conf

if [ -d ${run_result_dir} ]
then
    mv ${run_result_dir} ${run_result_dir}_`date +%s`_bak
fi
mkdir -p ${run_result_dir}

> ${run_result_dir}/test_tmp
if [ -z ${run_test_config} ]
then
    tests=`ls tests/* -R`
else
    for rc in `echo ${run_test_config}|tr '|' ' '`
    do
        rs=`echo ${rc}|cut -d '-' -f 1`
        test_type_list=`echo ${rc}|cut -d '-' -f 2`
        test_type_list="`echo _"${test_type_list//,/,_}"`"
        echo $test_type_list |grep -q ','
        if [ $? -eq 0 ]
        then
            test_type_list="{${test_type_list}}"
        fi

        jobs_list=`echo ${rc}|cut -d '-' -f3`
        jobs_list=`echo _"${jobs_list//,/,_}"`
        jobs_list="`echo "${jobs_list//,/'jobs',}"jobs`"
        echo $jobs_list |grep -q ','
        if [ $? -eq 0 ]
        then
            jobs_list="{${jobs_list}}"
        fi

        iodepth_list=`echo ${rc}|cut -d '-' -f4`
        iodepth_list=`echo _"${iodepth_list//,/,_}"`
        iodepth_list="`echo "${iodepth_list//,/'iodepth',}"iodepth`"
        echo $iodepth_list |grep -q ','
        if [ $? -eq 0 ]
        then
            iodepth_list="{${iodepth_list}}"
        fi

        rwmix_list=`echo ${rc}|cut -d '-' -f5`
        rwmix_list=`echo _"${rwmix_list//,/,_}"`
        rwmix_list="`echo "${rwmix_list//,/'rw',}"rw`"
        echo $rwmix_list |grep -q ','
        if [ $? -eq 0 ]
        then
            rwmix_list="{${rwmix_list}}"
        fi

        eval ls ./tests/$rs/*${jobs_list}*${iodepth_list}*${run_type}*${rwmix_list}*${test_type_list}*  >> ${run_result_dir}/test_tmp
        if [ $? -ne 0 ]
        then
            echo "some case do not finde ,please check case!"
            exit 3
        fi
    done
fi

prove `cat ${run_result_dir}/test_tmp`

python ./gen_report.py
tar czf report.tar.gz report
#mv iozone*result ${run_result_dir}
