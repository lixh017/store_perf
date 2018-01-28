#########################################################################
# File Name: gen_test_case.sh
# Author: Ethan
# mail: lixianghan@daowoo.com,lixh017@163.com
# Created Time: Wed 18 Oct 2017 10:14:52 AM CST
#########################################################################
#!/bin/bash
export LC_ALL="en_US.utf-8"
export LANG="en_US.utf-8"
source ./conf 
size='4k,8k,64k,256k,1024k'
test_mode='write,read,randread,randwrite,rw,randrw'
run_type='para,seq'
#iodepth='1,4,8,16,32'
thread='1,2,4,8,16,32'
rw_mix='0,100,50,60,70,80'
file_size=0

temp_dir="./tests"

function usage()
{
    echo -e "/bin/bash $0 [-s io_size] [-n numjobs] [-m test_mode] [-D iodepth ] [-M rwmix ]
option:
\t-s\tio_size\tTest io block size default is [4k,8k,16k,32k,64k,128k,256k,512k,1024k]. 
\t-n\tnumjobs\tTest jobs number,default is 1. 
\t-m\ttest_mode\tTest io mode,default [write,read,rw,randrw]
\t-D\tiodepth\tiodepth for one job ,default is 1
\t-z\tfile_size\tSpecify the working file size, if you are passing filepaths to -d
\t-t\trun_time\tTest exec time,default is 300.
\t-C\tcache_io\tUse host mem cache,default is False.
\t-M\trwmix\t Percentage of a mixed workload that should be reads. Default: 50. Only support mode of randrw and rw.


useage:
    /bin/bash $0 -s 4k,8k -t 1,4,8 -i write -f 100G 
    /bin/bash $0  # will create all tests case
    "
    exit 3
}

while getopts "s:t:i:f:h" Option
do
    case $Option in
        s) out_size="$OPTARG" ;;
        n) out_numjobs="$OPTARG" ;;
        m) out_test_mode="$OPTARG" ;;
        D) out_iodepth="$OPTARG" ;;
        z) out_file_size="$OPTARG" ;;
        t) out_runtime="$OPTARG" ;;
        C) out_cache_io="$OPTARG" ;;
        ?) usage ;;
    esac
done

if [ -f ${temp_dir} ]
then
    echo "The [ ${temp_dir} ] is a file,please check it! "
elif [ ! -d ${temp_dir} ]
then
    mkdir -p ${temp_dir}
fi

if [ ! -z ${out_size} ]
then
    size=${out_size}
fi

if [ ! -z ${out_file_size} ]
then
    file_size=${out_file_size}
fi

if [ ! -z ${out_numjobs} ]
then
    numjobs=${out_numjobs}
fi

if [ ! -z ${out_rw_mix} ]
then
    rw_mix=${out_rw_mix}
fi
if [ ! -z ${out_test_mode} ]
then
    test_mode=${out_test_mode}
fi

if [ ! -z ${out_iodepth} ]
then
    iodepth=${out_iodepth}
fi

if [ ! -z ${out_cache_io} ]
then
    cache_io=${out_cache_io}
fi

if [ ! -z ${out_runtime} ]
then
    runtime=${out_runtime}
fi

for rs in `echo ${size} |tr ',' ' '`
do
    if [ ! -d ${temp_dir}/${rs} ]
    then
        mkdir -p ${temp_dir}/${rs}
    fi

    if [ -z "`ls ${temp_dir}/${rs}`" ]
    then
        flg=0
    else
        end_flg=`ls ${temp_dir}/${rs}|tail -n1|cut -d '_' -f1`
        flg=`expr $end_flg + 1`
    fi
    for mode in `echo ${test_mode}|tr ',' ' '`
    do
        for run in `echo ${run_type}|tr ',' ' '`
        do
            if [ ${run} == 'para' ] 
            then
                run_flag='-p'
            elif [ ${run} == 'seq' ]
            then
                run_flag='-s'
            elif [ ${run} == 'all' ]
            then
                run_flag='-a'
            fi
            for th in `echo $thread|tr ',' ' '`
            do
                if [ ${mode} != 'rw' ] && [ ${mode} != 'randrw' ]
                then
                    range_rw_mix='0'
                else
                    range_rw_mix=${rw_mix}
                fi

                for mix in `echo ${range_rw_mix}|tr ',' ' '`
                do
                    temp_file=${temp_dir}/${rs}/`printf "%0*d" "4" ${flg}`_${rs}_${th}thread_${run}_${mix}rw_${mode}.t
                    if [ -f ${temp_file} ]
                    then
                        echo "The file [ ${temp_file} ] already exist ! "
                    else
cat > ${temp_file} << EOF 
#!/bin/bash
# vdbench test: ${temp_file} ,v 1.0 `date` $
desc="====fio test on [ ${rs}-${th}thread_${run}_${mix}rw_${mode} ] ===="

dir=\`dirname \$0\`
. \${dir}/../../misc.sh
. \${dir}/../../conf

echo "1..1"
if [ ! -z \${cache_io} ] && [ "\${cache_io}" == "True" ]
then
    cache_flag='-c'
else
    cache_flag=''
fi
if [ ! -z "\${file_size}" ]
then
    size_flag="-z \${file_size}"
else
    size_flag=""
fi
if [ ! -z "\${run_time}" ]
then
    run_time_flag="-r \${run_time}"
else
    run_time_flag=""
fi

if [ ! -z "\${host_list}" ]
then
    host_list_flag="-l \${host_list}"
else
    host_list_flag=
fi

if [ ! -z "\${depth}" ]
then
    depth_flag="-D \${depth}"
else
    depth_flag=""
fi

if [ ! -z "\${width}" ]
then
    width_flag="-W \${width}"
else
    width_flag=""
fi

if [ ! -z "\${files}" ]
then
    files_flag="-F \${files}"
else
    files_flag=""
fi

if [ "\$shared" == 'yes' ]
then
    shared_flag="-S"
else
    shared_flag=""
fi

if [ ! -z "\$fileselect" ]
then
    select_flag="-C \$fileselect"
else
    select_flag=""
fi

vd_conf=\`/bin/bash \${dir}/../../genvdbench.sh -d \${test_dir} \${shared_flag} \${cache_flag} ${run_falg} \${run_time_flag} -b ${rs} \${size_flag} \${host_list_flag} -m ${mode} \${run_time_flag} \${depth_flag} \${files_flag} \${width_flag} \${select_flag} -t ${th} -M ${mix} -x \${run_result_dir}/\`

echo \$vd_conf |grep -q '.vd$' 
if [ \$? -ne 0 ]
then
    echo "genvdbench conf failed!"
    exit 3
fi
rs_name=\`basename \$vd_conf|cut -d '.' -f 1\`
mkdir -p \${run_result_dir}/\$rs_name
mkdir -p \${run_result_dir}/\$rs_name/logs


mkdir -p \${run_result_dir}/\${rs_name}/logs/
expect_success /opt/vdbench/vdbench -f \$vd_conf -o \`pwd\`/\${run_result_dir}/\${rs_name}/logs
EOF
                
                        flg=`expr ${flg} + 1`
                    fi
                done
            done
        done
    done
done
mkdir -p tests/init
cp init.t ./tests/init
