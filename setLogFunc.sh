#!/usr/bin/env bash
#
# File: https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/setLogFunc.sh
#
# Utility supporting executing tasks from within Kubernetes (k8s) pods
#
# Logging support functions
#
# Dependencies:
# * setDistAndArch.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/setDistAndArch.sh)
# * setGnuTools.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/setGnuTools.sh)
#

#
THIS_KJW_SCRIPT_URL="https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/shlib/setLogFunc.sh"
KJW_FUNC="default"

# Set up environment variables for the Linux distribution, host name
# and architecture
source setDistAndArch.sh
retval=$?
if [ "${retval}" != 0 ]
then
    echo "Call to setDistAndArch.sh failed. Returned code: ${retval}" > /dev/stderr
    return ${retval}
fi

# Set up envrionment variables for command-line tools differing on MacOS
source setGnuTools.sh
retval=$?
if [ "${retval}" != 0 ]
then
    echo "Call to setGnuTools.sh failed. Returned code: ${retval}" > /dev/stderr
    return ${retval}
fi

# Logging module 
log() {
    if [ -z "${KJW_LOG_FILE}" ]
    then
	echo "Error - The KJW_LOG_FILE environment variable should be set and points to the file in which the logs may be written to" > /dev/stderr
	echo "        See ${THIS_KJW_SCRIPT_URL} for the details of the log() function."  > /dev/stderr
	return 1
    fi

    local canWriteToFile="$(touch ${KJW_LOG_FILE} 2> /dev/null && echo "Y" || echo "N")"
    if [ "${canWriteToFile}" == "N" ]
    then
	echo "Error - The ${KJW_LOG_FILE} is expected to be a wrtiteable file in which the logs may be written; apparently, no logs may be written to ${KJW_LOG_FILE}."  > /dev/stderr
	echo "        See ${THIS_KJW_SCRIPT_URL} for the details of the log() function."  > /dev/stderr
	return 1
    fi

    if [ -z "${KJW_SCRIPT_URL}" ]
    then
	echo "Error - The KJW_SCRIPT_URL environment variable should be set, but is not."
	echo "See ${THIS_KJW_SCRIPT_URL} for the details of the log() function."
	return 1
    fi

    local caller_script="$(basename ${THIS_KJW_SCRIPT_URL})"

    logTime="$(${DATE_TOOL} "+%Y-%m-%d %H:%M:%S" --utc)"

    echo "############### [${logTime} (UTC)][${KJW_UNAME}@${KJW_HNAME}][${KJW_PLTF}-${KJW_ARCH}][${caller_script}][${KJW_FUNC}]: $1 ######################" | tee -a ${KJW_LOG_FILE}
}

logMulti() {
    if [ -z "${KJW_LOG_FILE}" ]
    then
	echo "Error - The KJW_LOG_FILE environment variable should be set and points to the file in which the logs may be written." > /dev/stderr
	echo "        See ${THIS_KJW_SCRIPT_URL} for the details of the log() function."  > /dev/stderr
	return 1
    fi

    local canWriteToFile="$(touch ${KJW_LOG_FILE} 2> /dev/null && echo "Y" || echo "N")"
    if [ "${canWriteToFile}" == "N" ]
    then
	echo "Error - The ${KJW_LOG_FILE} is expected to be a wrtiteable file in which the logs may be written; apparently, no logs may be written to ${KJW_LOG_FILE}."  > /dev/stderr
	echo "        See ${THIS_KJW_SCRIPT_URL} for the details of the log() function."  > /dev/stderr
	return 1
    fi

    if [ -z "${KJW_SCRIPT_URL}" ]
    then
	echo "Error - The KJW_SCRIPT_URL environment variable should be set, but is not."
	echo "See ${THIS_KJW_SCRIPT_URL} for the details of the log() function."
	return 1
    fi

    local caller_script="$(basename ${THIS_KJW_SCRIPT_URL})"

    logTime="$(${DATE_TOOL} "+%Y-%m-%d %H:%M:%S" --utc)"

    echo "############### [${logTime} (UTC)][${KJW_UNAME}@${KJW_HNAME}][${KJW_PLTF}-${KJW_ARCH}][${caller_script}][${KJW_FUNC}] - begin ######################" | tee -a ${KJW_LOG_FILE}

    #declare -a line_list=($@)
    for myline in "$@"
    do
	echo "${myline}" | tee -a ${KJW_LOG_FILE}
    done

    echo "############### [${logTime} (UTC)][${KJW_UNAME}@${KJW_HNAME}][${KJW_FUNC}] - end ######################" | tee -a ${KJW_LOG_FILE}
}

logStart() {
    local descr="Generic Description - Place your own description here by calling logStart() with an argument"
    if [ ! -z "$1" ]
    then
	descr="$1"
    fi
    log "#############################################################################"
    log "#### ${descr} - Start ####"
}

logEnd() {
    local descr="Generic Description - Place your own description here by calling logStart() with an argument"
    if [ ! -z "$1" ]
    then
	descr="$1"
    fi
    log "#### ${descr} - End ####"
    log "#############################################################################"
}

