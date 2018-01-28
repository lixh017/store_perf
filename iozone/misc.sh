# $YeeStor: autotest/misc.sh,v 1.0 2014/11/28 $

echo ${dir} | egrep '^/' >/dev/null 2>&1
if [ $? -eq 0 ]; then
	maindir="${dir}/../.."
else
	maindir="`pwd`/${dir}/../.."
fi
. ${maindir}/conf

echo ${dir} >> ${file_stdout}

ntest=1

expect_fail()
{
    #echo "${password}" | yfsuser logon --user_name root
    echo "test ${ntest}" >> ${file_stdout}
    echo $* >> ${file_stdout}
    `$* >>${file_stdout} 2>&1`
	#`echo "$@"|awk '{run=$0;system(run)}' >> ${file_stdout} 2>&1`
	#local err_count=`echo "$@"|awk '{run=$0;system(run)}' |tee -a ${file_stdout} grep -iE "error|required|exit"|wc -l`
	#if [ ${err_count} -ne 0 ]; then
	if [ ${?} -ne 0 ]; then
	    echo "ok ${ntest}"
	else
		echo "not ok ${ntest}"
	fi
	ntest=`expr $ntest + 1`
}

expect_success()
{
    local result=   
    #echo "${password}" | yfsuser logon --user_name root
    echo "test ${ntest}" >> ${file_stdout}
    echo $* >> ${file_stdout}
    `$* >>${file_stdout} 2>&1`
	#`echo "$@"|awk '{run=$0;system(run)}' >> ${file_stdout} 2>&1`
	#result=`echo "$@"|awk '{run=$0;system(run)}'| tee -a ${file_stdout} | grep "ERRNO" | awk {' print $4 '}`
	result=$?
	if [ -z ${result} ] || [ ${result} -eq 0 ] ; then
		echo "ok ${ntest}"
	else
		echo "not ok ${ntest}"
	fi
	ntest=`expr $ntest + 1`
}

expect_errno()
{
    status=0
	
    echo "${password}" | yfsuser logon --user_name root
    echo "test ${ntest}" >> ${file_stdout}
    echo $* >> ${file_stdout}
    value="${1}"
    shift
    #result=`$* 2>${file_stdout} | grep errno | awk {'print $3'} | awk -F, {'print $1'}`
    # Modify by Li Gang: 2015-11-13: In NAS test, if a cli command fails, the output message does not contain "program exit with code"
    # Modify by Li Gang: 2015-11-27: get correct error number that cli command returns
    # Modify by Li Gang: 2015-12-01: fix the issue: if the "echo" keyword shows in whole command, this command can't run successfully
    # debug: echo "command to execute:""$@"
    result=`echo "$@"|awk '{run=$0;system(run)}'| tee -a ${file_stdout}  | grep "program exit with code|" | awk -F: {'print $2'}`
    # Modify by Li Gang: 2016-10-28: fix bug: do not run command twice, just get "errno" from log file
	result_2=`grep "ERRNO" ${file_stdout} | awk {' print $4 '} |sort -u`
  
    if [[ ${result} -eq ${value} ]] || [[ ${result_2} -eq ${value} ]]; then
       status=1
    fi
    
    if [ ${status} -ne 0 ]; then
        echo "ok ${ntest}"
    else
        echo "not ok ${ntest}"
    fi
    ntest=`expr $ntest + 1`
}

test_check()
{
	if [ $* ]; then
		echo "ok ${ntest}"
	else
		echo "not ok ${ntest}"
	fi
	ntest=`expr $ntest + 1`
}

namegen()
{
	echo "YeeSAN_`dd if=/dev/urandom bs=1k count=1 2>${file_stdout} | md5sum  | cut -f1 -d' '`"
}

