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
        echo $test_type_list |grep ',' >> /dev/null 2>&1
        if [ $? -eq 0 ]
        then
            test_type_list="{${test_type_list}}"
        fi
        thread_list=`echo ${rc}|cut -d '-' -f3`
        thread_list=`echo _"${thread_list//,/,_}"`
        thread_list="`echo "${thread_list//,/thread,}"thread`"
        echo $thread_list |grep ',' >> /dev/null 2>&1
        if [ $? -eq 0 ]
        then
            thread_list="{${thread_list}}"
        fi
        eval ls ./tests/$rs/*${thread_list}*${test_type_list}*  >> ${run_result_dir}/test_tmp
    done
fi

prove `cat ${run_result_dir}/test_tmp`

mv iozone*result ${run_result_dir}

python ./gen_report.py
tar czf report.tar.gz report
