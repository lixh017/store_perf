#!/usr/bin/env bash
#
#  Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#  Author: Erwan Velu  <erwan@enovance.com>
#
#  The license below covers all files distributed with fio unless otherwise
#  noted in the file itself.
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License version 2 as
#  published by the Free Software Foundation.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

BLK_SIZE=
BLOCK_SIZE=4k
SEQ=-1
TEMPLATE=/tmp/template.fio
OUTFILE=
DISKS=
PRINTABLE_DISKS=
RUNTIME=300
ETA=0
MODES="write,randwrite,read,randread"
SHORT_HOSTNAME=
CACHED_IO="FALSE"
PREFIX=""
PREFIX_FILENAME=""
IODEPTH=1
NUMJOBS=1
SHARED="FALSE"
RWMIX=0
PER_JOB_LOGS=0
IOENGINE=libaio

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
-i ioengine			: Defines how the job issues I/O.default is libaio 
-D iodepth			: Run with the specified iodepth
					Default is ${IODEPTH}
-d disk1[,disk2,disk3,..]	: Run the tests on the selected disks
					Separated each disk with a comma
-z filesize                     : Specify the working file size, if you are passing filepaths to -d
                                        Disabled by default
-r seconds			: Time in seconds per benchmark
					0 means till the end of the device
					Default is ${RUNTIME} seconds
-S share file system:  workdir is share file_system,will auto splite director,test file must in same dirctory!
-b blocksize[,blocksize1, ...]  : The blocksizes to test under fio format (4k, 1m, ...)
					Separated each blocksize with a comma
					Default is ${BLOCK_SIZE}
-m mode1,[mode2,mode3, ...]     : Define the fio IO profile to use like read, write, randread, randwrite
					Default is "${MODES}"
-n numjobs          : Run fio test jobs number
-j per_job_logs		:If set, this generates bw/clat/iops log with per file private filenames. 
				If not set, jobs with identical names will share the log filename. Default: False
-x prefix			: Add a prefix to the fio filename
					Useful to let a context associated with the file
					If the prefix features a / (slash), prefix will be considered as a directory
-M rwmix            :Percentage of a mixed workload that should be reads. Default is "${RWMIX}"
                    Only support mode in randrw and rw.
-A cmd_to_run			: System command to run after each job (exec_postrun in fio)
-B cmd_to_run			: System command to run before each job (exec_prerun in fio)

Example:

${PROG} -d /dev/sdb,/dev/sdc,/dev/sdd,/dev/sde -a -b 4k,128k,1m -r 100 -a -x dellr720-day2/

	Will generate an fio file that will run
		- a sequential bench on /dev/sdb /dev/sdc /dev/sdd /dev/sde for block size = 4k with write,randwrite,read,randread tests
			ETA ~ 4 tests * 4 disks * 100 seconds
		- a sequential bench on /dev/sdb /dev/sdc /dev/sdd /dev/sde for block size = 128k with write,randwrite,read,randread tests
			ETA ~ 4 tests * 4 disks * 100 seconds
		- a sequential bench on /dev/sdb /dev/sdc /dev/sdd /dev/sde for block size = 1m with write,randwrite,read,randread tests
			ETA ~ 4 tests * 4 disks * 100 seconds
		- a parallel bench on /dev/sdb /dev/sdc /dev/sdd /dev/sde for block size = 4k with write,randwrite,read,randread tests
			ETA ~ 4 tests * 100 seconds
		- a parallel bench on /dev/sdb /dev/sdc /dev/sdd /dev/sde for block size = 128k with write,randwrite,read,randread tests
			ETA ~ 4 tests * 100 seconds
		- a parallel bench on /dev/sdb /dev/sdc /dev/sdd /dev/sde for block size = 1m with write,randwrite,read,randread tests
			ETA ~ 4 tests * 100 seconds

Generating dellr720-day2/localhost-4k,128k,1m-all-write,randwrite,read,randread-sdb,sdc,sdd,sde.fio
Estimated Time = 6000 seconds : 1 hour 40 minutes
EOF
}

finish_template() {
echo "iodepth=${IODEPTH}" >> ${TEMPLATE}
echo "numjobs=${NUMJOBS}" >> ${TEMPLATE}

if [ "${RUNTIME}" != "0" ]; then
	echo "runtime=${RUNTIME}" >> ${TEMPLATE}
	echo "time_based" >> ${TEMPLATE}
fi

if [ "${CACHED_IO}" = "FALSE" ]; then
	echo "direct=1" >> ${TEMPLATE}
fi
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

gen_template() {
cat >${TEMPLATE} << EOF
[global]
ioengine=libaio
invalidate=1
ramp_time=5
group_reporting
EOF
}

gen_seq_suite() {
TYPE=$1
disk=$2
PRINTABLE_DISK=$(diskname_to_printable ${disk})

if [ ${TYPE} != 'randrw' ] || [ ${TYPE} != 'rw' ]
then
    local RWMIX=0
fi

if [ ${SHARED} == "TRUE" ]
then
    test_file_str="directory=`dirname ${disk}`
filename=`basename ${disk}`"
else
    test_file_str="filename=${disk}"
fi

cat >> ${OUTFILE} << EOF
[${TYPE}-${PRINTABLE_DISK}-${BLK_SIZE}-seq]
stonewall
bs=${BLK_SIZE}
$test_file_str
rw=${TYPE}
rwmixread=${RWMIX}
per_job_logs=${PER_JOB_LOGS}
write_bw_log=/tmp/${BLK_SIZE}-${IODEPTH}iodepth-${NUMJOBS}jobs-${PRINTABLE_DISK}-${TYPE}-${RWMIX}rw-seq.results
write_iops_log=/tmp/${BLK_SIZE}-${IODEPTH}iodepth-${NUMJOBS}jobs-${PRINTABLE_DISK}-${TYPE}-${RWMIX}rw-seq.results
write_lat_log=/tmp/${BLK_SIZE}-${IODEPTH}iodepth-${NUMJOBS}jobs-${PRINTABLE_DISK}-${TYPE}-${RWMIX}rw-seq.results
EOF
ETA=$((${ETA} + ${RUNTIME}))
}

gen_seq_fio() {
for disk in $(echo ${DISKS} | tr "," " "); do
	for mode in $(echo ${MODES} | tr "," " "); do
		gen_seq_suite "${mode}" "${disk}"
	done
done
}


gen_para_suite() {
TYPE=$1
NEED_WALL=$2
D=0
for disk in $(echo ${DISKS} | tr "," " "); do
    PRINTABLE_DISK=$(diskname_to_printable ${disk})
    cat >> ${OUTFILE} << EOF
[${TYPE}-${PRINTABLE_DISK}-${BLK_SIZE}-para]
bs=${BLK_SIZE}
EOF

if [ "$D" = 0 ]; then
    echo "stonewall" >> ${OUTFILE}
    D=1
fi

if [ ${TYPE} != 'randrw' ] && [ ${TYPE} != 'rw' ]
then
    local RWMIX=0
fi

if [ ${SHARED} == "TRUE" ]
then
    test_file_str="directory=`dirname ${disk}`
filename=`basename ${disk}`"
else
    test_file_str="filename=${disk}"
fi

cat >> ${OUTFILE} << EOF
${test_file_str} 
rw=${TYPE}
rwmixread=${RWMIX}
per_job_logs=${PER_JOB_LOGS}
write_bw_log=/tmp/${BLK_SIZE}-${IODEPTH}iodepth-${NUMJOBS}jobs-${PRINTABLE_DISK}-${TYPE}-${RWMIX}rw-para.results
write_iops_log=/tmp/${BLK_SIZE}-${IODEPTH}iodepth-${NUMJOBS}jobs-${PRINTABLE_DISK}-${TYPE}-${RWMIX}rw-para.results
write_lat_log=/tmp/${BLK_SIZE}-${IODEPTH}iodepth-${NUMJOBS}jobs-${PRINTABLE_DISK}-${TYPE}-${RWMIX}rw-para.results
EOF
done

ETA=$((${ETA} + ${RUNTIME}))
echo >> ${OUTFILE}
}

gen_para_fio() {
for mode in $(echo ${MODES} | tr "," " "); do
	gen_para_suite "${mode}"
done
}

gen_fio() {
case ${SEQ} in
	2)
		gen_seq_fio
		gen_para_fio
	;;
	1)
		gen_seq_fio
	;;
	0)
		gen_para_fio
	;;
esac
}

parse_cmdline() {
while getopts "hacpsd:b:r:Si:m:n:M:x:z:j:D:A:B:" opt; do
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
    S)
    SHARED="TRUE"
    ;;
    r)
	RUNTIME=${OPTARG}
      ;;
    p)
	if [ "${SEQ}" = "-1" ]; then
		SEQ=0
	fi
      ;;
    j)
    	PER_JOB_LOGS=${OPTARG}
      ;;
    m)
        MODES=${OPTARG};
      ;;
    M) RWMIX=${OPTARG};
      ;;
    d)
 	DISKS=${OPTARG}
	PRINTABLE_DISKS=$(diskname_to_printable "${DISKS}")
      ;;
    D)
	IODEPTH=${OPTARG}
      ;;
    i)
    	IOENGINE=${OPTARG}
      ;;
    n)
	NUMJOBS=${OPTARG}
      ;;
    a)
	SEQ=2
      ;;
    B)
	echo "exec_prerun=${OPTARG}" >> ${TEMPLATE}
      ;;
    A)
	echo "exec_postrun=${OPTARG}" >> ${TEMPLATE}
      ;;
    z)
	FSIZE=${OPTARG}
	echo "size=${FSIZE}" >> ${TEMPLATE}
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      ;;
  esac
done

if [ "${SEQ}" = "-1" ]; then
	SEQ=0
fi

SHORT_HOSTNAME=$(hostname -s)
case $SEQ in
	2)
		OUTFILE=${PREFIX}${BLOCK_SIZE}-all-${IODEPTH}iodepth-${NUMJOBS}jobs-${MODES}-${RWMIX}rw-${PRINTABLE_DISKS}.fio
	;;

	1)
		OUTFILE=${PREFIX}${BLOCK_SIZE}-sequential-${IODEPTH}iodepth-${NUMJOBS}jobs-${MODES}-${RWMIX}rw-${PRINTABLE_DISKS}.fio
	;;
	0)
		OUTFILE=${PREFIX}${BLOCK_SIZE}-parallel-${IODEPTH}iodepth-${NUMJOBS}jobs-${MODES}-${RWMIX}rw-${PRINTABLE_DISKS}.fio
	;;
esac

if [ -z "${DISKS}" ]; then
	echo "Missing DISKS !"
	echo "Please read the help !"
	show_help
	exit 1
fi

}

check_mode_order() {
FOUND_WRITE="NO"
CAUSE="You are reading data before writing them          "

# If no write occurs, let's show a different message
echo ${MODES} | grep -q "write"
if [ "$?" -ne 0 ]; then
	CAUSE="You are reading data while never wrote them before"
fi

for mode in $(echo ${MODES} | tr "," " "); do
	echo ${mode} | grep -q write
	if [ "$?" -eq 0 ]; then
		FOUND_WRITE="YES"
	fi
	echo ${mode} | grep -q "read"
	if [ "$?" -eq 0 ]; then
		if [ "${FOUND_WRITE}" = "NO" ]; then
			echo "###############################################################"
			echo "# Warning : $CAUSE#"
			echo "# On some storage devices, this could lead to invalid results #"
			echo "#                                                             #"
			echo "# Press Ctrl-C to adjust pattern order if you have doubts     #"
			echo "# Or Wait 5 seconds before the file will be created           #"
			echo "###############################################################"
			sleep 5
			# No need to try showing the message more than one time
			return
		fi
	fi
done
}


########## MAIN
gen_template
parse_cmdline "$@"
finish_template
#check_mode_order

#echo "Generating ${OUTFILE}"
echo "${OUTFILE}"
cp -f ${TEMPLATE} ${OUTFILE}
echo >> ${OUTFILE}

for BLK_SIZE in $(echo ${BLOCK_SIZE} | tr "," " "); do
	gen_fio
done
ETA_H=$((${ETA} / 3600))
ETA_M=$(((${ETA} - (${ETA_H}*3600)) / 60))
if [ "$ETA" = "0" ]; then
	echo "Cannot estimate ETA as RUNTIME=0"
#else
#	echo "Estimated Time = ${ETA} seconds : ${ETA_H} hour ${ETA_M} minutes"
fi
