#########################################################################
# File Name: gen_test_case.sh_
# Author: Ethan
# mail: lixianghan@daowoo.com,lixh017@163.com
# Created Time: Wed 11 Oct 2017 02:41:17 PM CST
#########################################################################
#!/bin/bash
export LC_ALL="en_US.utf-8"
export LANG="en_US.utf-8"

size='4k,8k,16k,32k,64k,128k,256k,512k,1024k'
thread='1,2,4,8,16,32,64'
iotype='write,read,rw,randrw,all'

#temp_dir="./task_`date +%s`_result"
temp_dir="./tests"


#out_size=$1
#out_thread=$2
#out_iotype=$3

function usage()
{
    echo -e "/bin/bash $0 [-s io_size] [-t threads] [-i iotype] [-f file_size] [-K]
option:
\t-s\tio_size\t\tSize for one IO option,default size incloude [4k,8k,16k,32k,64k,128k,256k,512k,1024k].
\t-t\tthreads\t\tThread number for one test clinet,default thread incloud [1,2,4,8,16,32,64]. 
\t-i\tio_type\t\tIOtype,for this test,default io_type incloud [write,read,rw,randrw].
\t-f\tfile_size\tTotal filesize of one host,default is 100M. 
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
        t) out_thread="$OPTARG" ;;
        i) out_iotype="$OPTARG" ;;
        f) out_file_size="$OPTARG" ;;
        h) usage ;;
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
   size=${in_size} 
fi

if [ ! -z ${out_thread} ]
then
    thread=${out_thread}
fi

if [ ! -z ${out_iotype} ]
then
    iotype=${out_iotype} 
fi


###create test case

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

    for th in `echo ${thread}|tr ',' ' '`
    do
        for it in `echo ${iotype}|tr ',' ' '`
        do
            if [ ${it} == "write" ]
            then
                test_type='0'
            elif [ ${it} == "read" ]
            then
                test_type='1'
            elif [ ${it} == "randrw" ]
            then
                test_type='2'
            elif [ ${it} == "rw" ]
            then
                test_type='0,1'
            elif [ ${it} == "all" ]
            then
                test_type='0,1,2'
            fi
            temp_file=${temp_dir}/${rs}/`printf "%0*d" "3" ${flg}`_${rs}_${th}thread_${it}.t
            if [ -f ${temp_file} ]
            then
                echo "The file [ ${temp_file} ] already exist ! "
            else
cat > ${temp_file} << EOF 
#!/bin/bash
# iozone_test: ${temp_file} ,v 1.0 `date` $
desc="====iozone test on [ ${rs}-${th}thread-${it}] ===="

dir=\`dirname \$0\`
. \${dir}/../../misc.sh
. \${dir}/../../conf

echo "1..1"

if [ -z \${host_list} ]
then
    expect_success /bin/bash \${dir}/../../iozone_cluster.sh -f \${total_size} -s ${rs} -i ${test_type} -t ${th} -d \${test_dir}    
else
    expect_success /bin/bash \${dir}/../../iozone_cluster.sh -f \${total_size} -s ${rs} -i ${test_type} -t ${th} -d \${test_dir} -c \${host_list} 
fi
EOF
                
                flg=`expr ${flg} + 1`
            fi
        done
    done
done

