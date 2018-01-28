#!/usr/bin/env bash
#
BLK_SIZE=
BLOCK_SIZE=4k
SEQ=-1
TEMPLATE=/tmp/template.vd
TEST_TYPE="lun"
OUTFILE=
DISKS=
PRINTABLE_DISKS=
RUNTIME=300
ETA=0
MODES="write,randwrite,read,randread,rw,randrw"
CACHED_IO="FALSE"
PREFIX=""
PREFIX_FILENAME=""
HOST_LIST=""
THREAD=1
RWMIX=50
SERV_TYPE="ssh"
DEPTH=1
WIDTH=1
ANCHOR='/mnt/test'
FSIZES='1M'
FILES='10'
THREADS=1
SHARED='no'
HD_FLG=1
SD_FLG=1
WD_FLG=1
RD_FLG=1
RUN_TYPE=""
INTERVAL=10
FILESELECT="random"

show_help() {
	PROG=$(basename $0)
	echo "usage of ${PROG}:"
	cat << EOF
-h				: Show this help & exit
-c				: Enable cached-based IOs
					Disabled by default
-a				: Run sequential test then parallel one
					Disabled by default
-s				: Run sequential test (default value)
					one test after another then one disk after another
					Disabled by default
-p				: Run parallel test
					one test after anoter but all disks at the same time
					Enabled by default
					Default is ${IODEPTH}
-l				: Run host list
-d workdir  	: Run the tests on the dir
					Separated each disk with a comma
-D depth        : the test direcotry depth
-W width        : the test direcotry width
-F files        : the test file count on the sub direcotry.
-z filesize                     : Specify the working file size
-r seconds			: Time in seconds per benchmark
					0 means till the end of the device
					Default is ${RUNTIME} seconds
-b blocksize  : The blocksizes to test under fio format (4k, 1m, ...)
					Separated each blocksize with a comma
					Default is ${BLOCK_SIZE}
-m mode1,[mode2,mode3, ...]     : Define the fio IO profile to use like read, write, randread, randwrite
					Default is "${MODES}"
-t threads          : Thread number of one host
-x prefix			: Add a prefix to the vdbench filename
					Useful to let a context associated with the file
					If the prefix features a / (slash), prefix will be considered as a directory
-M rwmix            :Percentage of a mixed workload that should be reads. Default is "${RWMIX}"
                    Only support mode in randrw and rw.

Example:

${PROG} -d /mnt/test -a -b 4k,128k,1m  -r 100 -a -x dellr720-day2/

	Will generate an fio file that will run
		- a sequential bench on /mnt/test  for block size = 4k with write,randwrite,read,randread tests
			ETA ~ 4 tests * 4 disks * 100 seconds

Generating dellr720-day2/localhost-4k,128k,1m-all-write,randwrite,read,randread-yfs.fio
Estimated Time = 6000 seconds : 1 hour 40 minutes
EOF
}

diskname_to_printable() {
COUNT=0
for disk in $(echo $@ | tr "," " "); do
	R=$(basename ${disk} | sed 's|/|_|g')
	COUNT=$(($COUNT + 1))
	if [ ${COUNT} -eq 1 ]; then
		P="$R"
	else
		P="$P,$R"
	fi
done
echo $P
}

gen_template()
{
    > ${TEMPLATE}
}

gen_hd() {
    if [ ! -z ${HOST_LIST} ]; then
        printf 'hd=default,vdbench=/opt/vdbench,user=root,shell=%s\n' ${SERV_TYPE}  >> ${TEMPLATE}
        for host in `echo ${HOST_LIST} | tr ',' ' '`
        do
            printf 'hd=hd%s,system=%s\n' ${HD_FLG} ${host} >> ${TEMPLATE} 
            HD_FLG=`expr ${HD_FLG} + 1`
        done
    fi
}

gen_fsd() {
    if [ ${CACHED_IO} == "FALSE" ]
    then
        cache_flag=",openflags=o_direct"
    elif [ ${CACHED_IO} == "TRUE" ]
    then
        cache_flag=""
    fi


    case ${SEQ} in
        0)
            RUN_TYPE=para
            SD_FLG=1
            if [ -z ${HOST_LIST} ]
            then
                printf 'fsd=%s_fsd%s,anchor=%s,depth=%s,width=%s,files=%s,sizes=%s,shared=%s%s\n' ${RUN_TYPE} ${SD_FLG} "${TEST_DIR}/localhost" ${DEPTH} ${WIDTH} ${FILES} ${FSIZES} ${SHARED} ${cache_flag} >> ${OUTFILE}
                SD_FLG=`expr ${SD_FLG} + 1`
            else
                for host in `echo ${HOST_LIST} | tr ',' ' '`
                do
                    printf 'fsd=%s_fsd%s,anchor=%s,depth=%s,width=%s,files=%s,sizes=%s,shared=%s%s\n' ${RUN_TYPE} ${SD_FLG} "${TEST_DIR}/${host}" ${DEPTH} ${WIDTH} ${FILES} ${FSIZES} ${SHARED} ${cache_flag} >> ${OUTFILE}
                    SD_FLG=`expr ${SD_FLG} + 1`
                done
            fi
            ;;
        1)
            RUN_TYPE=seq
            SD_FLG=1
            if [ -z ${HOST_LIST} ]
            then
                printf 'fsd=%s_fsd%s,anchor=%s,depth=%s,width=%s,files=%s,sizes=%s,shared=%s%s\n' ${RUN_TYPE} ${SD_FLG} "${TEST_DIR}/localhost" ${DEPTH} ${WIDTH} ${FILES} ${FSIZES} ${SHARED} ${cache_flag} >> ${OUTFILE}
                SD_FLG=`expr ${SD_FLG} + 1`
            else
                for host in `echo ${HOST_LIST} | tr ',' ' '`
                do
                    printf 'fsd=%s_fsd%s,anchor=%s,depth=%s,width=%s,files=%s,sizes=%s,shared=%s%s\n' ${RUN_TYPE} ${SD_FLG} "${TEST_DIR}/${host}" ${DEPTH} ${WIDTH} ${FILES} ${FSIZES} ${SHARED} ${cache_flag} >> ${OUTFILE}
                    SD_FLG=`expr ${SD_FLG} + 1`
                done
            fi

            ;;
        2)
            RUN_TYPE=seq
            SD_FLG=1
            if [ -z ${HOST_LIST} ]
            then
                printf 'fsd=%s_fsd%s,anchor=%s,depth=%s,width=%s,files=%s,sizes=%s,shared=%s%s\n' ${RUN_TYPE} ${SD_FLG} "${TEST_DIR}/localhost" ${DEPTH} ${WIDTH} ${FILES} ${FSIZES} ${SHARED} ${cache_flag} >> ${OUTFILE}
                SD_FLG=`expr ${SD_FLG} + 1`
            else
                for host in `echo ${HOST_LIST} | tr ',' ' '`
                do
                    printf 'fsd=%s_fsd%s,anchor=%s,depth=%s,width=%s,files=%s,sizes=%s,shared=%s%s\n' ${RUN_TYPE} ${SD_FLG} "${TEST_DIR}/${host}" ${DEPTH} ${WIDTH} ${FILES} ${FSIZES} ${SHARED} ${cache_flag} >> ${OUTFILE}
                    SD_FLG=`expr ${SD_FLG} + 1`
                done
            fi
            RUN_TYPE=para
            SD_FLG=1
            if [ -z ${HOST_LIST} ]
            then
                printf 'fsd=%s_fsd%s,anchor=%s,depth=%s,width=%s,files=%s,sizes=%s,shared=%s%s\n' ${RUN_TYPE} ${SD_FLG} "${TEST_DIR}/localhost" ${DEPTH} ${WIDTH} ${FILES} ${FSIZES} ${SHARED} ${cache_flag} >> ${OUTFILE}
                SD_FLG=`expr ${SD_FLG} + 1`
            else
                for host in `echo ${HOST_LIST} | tr ',' ' '`
                do
                    printf 'fsd=%s_fsd%s,anchor=%s,depth=%s,width=%s,files=%s,sizes=%s,shared=%s%s\n' ${RUN_TYPE} ${SD_FLG} "${TEST_DIR}/${host}" ${DEPTH} ${WIDTH} ${FILES} ${FSIZES} ${SHARED} ${cache_flag} >> ${OUTFILE}
                    SD_FLG=`expr ${SD_FLG} + 1`
                done
            fi
            ;;

    esac

}

gen_fwd()
{
    case ${MODES} in
        write)
            fileio=sequential
            rdpct_flag=""
            ;;
        read)
            fileio=sequential
            rdpct_flag=""
            ;;
        randwrite)
            fileio=random
            rdpct_flag="rdpct=0,"
            ;;
        randread)
            fileio=random
            rdpct_flag="rdpct=100,"
            ;;
        rw)
            fileio=sequential
            rdpct_flag=""
            ;;
        randrw)
            fileio=random
            rdpct_flag="rdpct=$RWMIX,"
            ;;
        *)
            fileio=random
            rdpct_flag=""
            ;;
    esac
    
    case ${SEQ} in
        0)
            RUN_TYPE=para
            WD_FLG=1
            if [ -z ${HOST_LIST} ]
            then
                printf 'fwd=%s_fwd%s,fsd=%s_fsd%s,fileio=%s,fileselect=%s%s\n' ${RUN_TYPE} ${WD_FLG} ${RUN_TYPE} ${WD_FLG} ${fileio} ${FILESELECT} ${rdpct_flag}>> ${OUTFILE}
                WD_FLG=`expr ${WD_FLG} + 1`
            else
                for host in `echo ${HOST_LIST}|tr ',' ' '`
                do
                    printf 'fwd=%s_fwd%s,fsd=%s_fsd%s,host=hd%s,fileio=%s,fileselect=%s%s\n' ${RUN_TYPE} ${WD_FLG} ${RUN_TYPE} ${WD_FLG} ${WD_FLG} ${fileio} ${FILESELECT} ${rdpct_flag} >> ${OUTFILE}
                    WD_FLG=`expr ${WD_FLG} + 1`
                done
            fi
            ;;
        1)
            RUN_TYPE=seq
            WD_FLG=1
            if [ -z ${HOST_LIST} ]
            then
                printf 'fwd=%s_fwd%s,fsd=%s_fsd%s,fileio=%s,fileselect=%s%s\n' ${RUN_TYPE} ${WD_FLG} ${RUN_TYPE} ${WD_FLG} ${fileio} ${FILESELECT} ${rdpct_flag} >> ${OUTFILE}
                WD_FLG=`expr ${WD_FLG} + 1`
            else
                for host in `echo ${HOST_LIST}|tr ',' ' '`
                do
                    printf 'fwd=%s_fwd%s,fsd=%s_fsd%s,host=hd%s,fileio=%s,fileselect=%s%s\n' ${RUN_TYPE} ${WD_FLG} ${RUN_TYPE} ${WD_FLG} ${WD_FLG} ${fileio} ${FILESELECT} ${rdpct_flag} >> ${OUTFILE}
                    WD_FLG=`expr ${WD_FLG} + 1`
                done
            fi
            ;;
        2)
            WD_FLG=1
            RUN_TYPE=seq
            if [ -z ${HOST_LIST} ]
            then
                printf 'fwd=%s_fwd%s,fsd=%s_fsd%s,fileio=%s,fileselect=%s%s\n' ${RUN_TYPE} ${WD_FLG} ${RUN_TYPE} ${WD_FLG} ${fileio}  ${FILESELECT} ${rdpct_flag} >> ${OUTFILE}
                WD_FLG=`expr ${WD_FLG} + 1`
            else
                for host in `echo ${HOST_LIST}|tr ',' ' '`
                do
                    printf 'fwd=%s_fwd%s,fsd=%s_fsd%s,host=hd%s,fileio=%s,fileselect=%s%s\n' ${RUN_TYPE} ${WD_FLG} ${RUN_TYPE} ${WD_FLG} ${WD_FLG} ${fileio} ${FILESELECT} ${rdpct_flag} >> ${OUTFILE}
                    WD_FLG=`expr ${WD_FLG} + 1`
                done
            fi

            WD_FLG=1
            RUN_TYPE=para
            if [ -z ${HOST_LIST} ]
            then
                printf 'fwd=%s_fwd%s,fsd=%s_fsd%s,fileio=%s,fileselect=%s%s\n' ${RUN_TYPE} ${WD_FLG} ${RUN_TYPE} ${WD_FLG} ${fileio} ${FILESELECT} ${rdpct_flag} >> ${OUTFILE}
                WD_FLG=`expr ${WD_FLG} + 1`
            else
                for host in `echo ${HOST_LIST}|tr ',' ' '`
                do
                    printf 'fwd=%s_fwd%s,fsd=%s_fsd%s,host=hd%s,fileio=%s,fileselect=%s%s\n' ${RUN_TYPE} ${WD_FLG} ${RUN_TYPE} ${WD_FLG} ${WD_FLG} ${fileio} ${FILESELECT} ${rdpct_flag} >> ${OUTFILE}
                    WD_FLG=`expr ${WD_FLG} + 1`
                done
            fi
            ;;
    esac

}

gen_rd(){
    case ${SEQ} in
        2)
            RUN_TYPE=seq
            if [ -z ${HOST_LIST} ]
            then
                printf 'rd=%s_rd%s,fwd=%s_fwd%s,forthreads=(%s),forxfersize=(%s),fwdrate=max,format=no,el=%s,in=%s\n' ${RUN_TYPE} ${RD_FLG} ${RUN_TYPE} ${RD_FLG} `expr ${THREAD} \* ${client_num}` ${BLK_SIZE} ${RUNTIME} ${INTERVAL} >> ${OUTFILE}
                RD_FLG=$[${RD_FLG}+1]
            else
                for host in `echo $HOST_LIST|tr ',' ' '`
                do
                    printf 'rd=%s_rd%s,fwd=%s_fwd%s,forthreads=(%s),forxfersize=(%s),fwdrate=max,format=no,el=%s,in=%s\n' ${RUN_TYPE} ${RD_FLG} ${RUN_TYPE} ${RD_FLG} `expr ${THREAD} \* ${client_num}` ${BLK_SIZE} ${RUNTIME} ${INTERVAL} >> ${OUTFILE}
                    RD_FLG=$[${RD_FLG}+1]
                done
            fi
            RUN_TYPE=para
            printf 'rd=%s_rd%s,fwd=%s_fwd*,forthreads=(%s),forxfersize=(%s),fwdrate=max,format=no,el=%s,in=%s\n' ${RUN_TYPE} ${RD_FLG} ${RUN_TYPE} `expr ${THREAD} \* ${client_num}` ${BLK_SIZE} ${RUNTIME} ${INTERVAL} >> ${OUTFILE}
        ;;
        1)
            RUN_TYPE=seq
            if [ -z ${HOST_LIST} ]
            then
                printf 'rd=%s_rd%s,fwd=%s_fwd%s,forthreads=(%s),forxfersize=(%s),fwdrate=max,format=no,el=%s,in=%s\n' ${RUN_TYPE} ${RD_FLG} ${RUN_TYPE} ${RD_FLG} `expr ${THREAD} \* ${client_num}` ${BLK_SIZE} ${RUNTIME} ${INTERVAL} >> ${OUTFILE}
                RD_FLG=$[${RD_FLG}+1]
            else
                for host in `echo $HOST_LIST|tr ',' ' '`
                do
                    printf 'rd=%s_rd%s,fwd=%s_fwd%s,forthreads=(%s),forxfersize=(%s),fwdrate=max,format=no,el=%s,in=%s\n' ${RUN_TYPE} ${RD_FLG} ${RUN_TYPE} ${RD_FLG} `expr ${THREAD} \* ${client_num}` ${BLK_SIZE} ${RUNTIME} ${INTERVAL} >> ${OUTFILE}
                    RD_FLG=$[${RD_FLG}+1]
                done
            fi
        ;;
        0)
            RUN_TYPE=para
            printf 'rd=%s_rd%s,fwd=%s_fwd*,forthreads=(%s),forxfersize=(%s),fwdrate=max,format=no,el=%s,in=%s\n' ${RUN_TYPE} ${RD_FLG} ${RUN_TYPE} `expr ${THREAD} \* ${client_num}` ${BLK_SIZE} ${RUNTIME} ${INTERVAL} >> ${OUTFILE}
        ;;
    esac
}


parse_cmdline() {
while getopts "hacpsSd:t:b:C:D:W:F:l:m:M:x:r:z:" opt; do
  case ${opt} in
    h)
	show_help
	exit 0
	;;
    b)
	BLOCK_SIZE=${OPTARG}
	;;
    c)
	CACHED_IO="TRUE"
	;;
    s)
	if [ "${SEQ}" = "-1" ]; then
		SEQ=1
	fi
      ;;
    x)
	PREFIX=${OPTARG}
	echo "${PREFIX}" | grep -q "/"
	if [ "$?" -eq 0 ]; then
		mkdir -p ${PREFIX}
		# No need to keep the prefix for the log files
		# we do have a directory for that
		PREFIX_FILENAME=""
	else
		# We need to keep the prefix for the log files
		PREFIX_FILENAME=${PREFIX}
	fi
	;;
    r)
	RUNTIME=${OPTARG}
	;;
    l)
	HOST_LIST=${OPTARG}
      ;;
    p)
	if [ "${SEQ}" = "-1" ]; then
		SEQ=0
	fi
      ;;
    t)
    THREAD=${OPTARG}
      ;;
    D)
    DEPTH=${OPTARG}
    ;;
    W)
    WIDTH=${OPTARG}
    ;;
    F)
    FILES=${OPTARG}
    ;;
    C)
    FILESELECT=${OPTARG}
    ;;
    m)
    MODES=${OPTARG}
      ;;
    M) 
    RWMIX=${OPTARG}
    ;;
    S)
    SHARED='yes'
    ;;
    d)
 	TEST_DIR=${OPTARG}
	PRINTABLE_DISKS=$(diskname_to_printable "${TEST_DIR}")
      ;;
    a)
	SEQ=2
      ;;
    z)
	FSIZES=${OPTARG}
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      ;;
  esac
done

if [ "${SEQ}" = "-1" ]; then
	SEQ=0
fi

case $SEQ in
	2)
		OUTFILE=${PREFIX}${BLOCK_SIZE}-all-${THREAD}thread-${MODES}-${RWMIX}rw-${PRINTABLE_DISKS}.vd
	;;

	1)
		OUTFILE=${PREFIX}${BLOCK_SIZE}-sequential-${THREAD}thread-${MODES}-${RWMIX}rw-${PRINTABLE_DISKS}.vd
	;;
	0)
		OUTFILE=${PREFIX}${BLOCK_SIZE}-parallel-${THREAD}thread-${MODES}-${RWMIX}rw-${PRINTABLE_DISKS}.vd
	;;
esac

if [ -z "${TEST_DIR}" ]; then
	echo "Missing TEST_DIR!"
	echo "Please read the help !"
	show_help
	exit 1
fi

}

########## MAIN
gen_template
parse_cmdline "$@"
if [ -z ${HOST_LIST} ]
then
    client_num=1
else
    client_num=`echo $HOST_LIST|tr ',' ' '|wc -w`
fi
gen_hd

echo "${OUTFILE}"
cp -f ${TEMPLATE} ${OUTFILE}
echo >> ${OUTFILE}

for BLK_SIZE in $(echo ${BLOCK_SIZE} | tr "," " "); do
    gen_fsd
    gen_fwd
    gen_rd
done
#ETA_H=$((${ETA} / 3600))
#ETA_M=$(((${ETA} - (${ETA_H}*3600)) / 60))
#if [ "$ETA" = "0" ]; then
#	echo "Cannot estimate ETA as RUNTIME=0"
#else
#	echo "Estimated Time = ${ETA} seconds : ${ETA_H} hour ${ETA_M} minutes"
#fi
