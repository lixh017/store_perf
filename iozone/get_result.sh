#!/bin/bash

if [[ $# -ne 3 ]]
then
    echo "Usage: $0 [file_prefix] [xfersize] [client_num]"
    echo "Example: $0 64k_seq_rw 4k 3"
    exit 1
fi

prefix=$1
suffix="kbs"
xfersize=$2
clients=$3

root_dir=$PWD
result_log="${root_dir}/$prefix.log"

if [[ -f ${result_log} ]]
then
   true >${result_log}
else
  touch ${result_log}
fi

xfersize_upper=`echo ${xfersize}|tr [a-z] [A-Z]`

# ls -d cluster*th*_4K*3client
for dir in `ls -d cluster*th*_${xfersize_upper}*${clients}client`
do
  cd $dir
  echo "Test scenario: $dir"| tee -a ${result_log}
  seq_write_val=`grep -i -w "initial write" *.log |cut -d '"' -f3|sed s/[[:space:]]//g`
  seq_read_val=`grep -w "Read" *.log |cut -d '"' -f3|sed s/[[:space:]]//g`
  
  rand_read_val=`grep -i -w "random read" *.log |cut -d '"' -f3|sed s/[[:space:]]//g`
  rand_write_val=`grep -i -w "random write" *.log |cut -d '"' -f3|sed s/[[:space:]]//g`

  if [[ ! -z ${seq_write_val} ]] && [[ ! -z ${seq_read_val} ]]
  then
     echo "Sequentail Write/Read values:($suffix} ${seq_write_val}/${seq_read_val}" |tee -a ${result_log}
     echo "---------------------------------------------------------------------------" |tee -a ${result_log}
  fi
  
  if [[ ! -z ${rand_write_val} ]] && [[ ! -z ${rand_read_val} ]]
  then
     echo "Random read/write values:($suffix} ${rand_read_val}/${rand_write_val}" |tee -a ${result_log}
     echo "---------------------------------------------------------------------------" |tee -a ${result_log}
  fi


  cd ${root_dir}
done


