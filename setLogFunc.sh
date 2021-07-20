#!/usr/bin/env bash
#
# File: https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/shlib/setLogFunc.sh
#
# Utility supporting executing tasks from within Kubernetes (k8s) pods
#

#
THIS_SCRIPT_GIT_URL="https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/shlib/setLogFunc.sh"
FUNC="default"
HNAME="$(cat /etc/hostname 2> /dev/null || hostname 2> /dev/null || echo "Unknown-hostname")"
UNAME="$(id -u -n)"

export DATE_TOOL="date"
if [ -f /usr/bin/sw_vers ]
then
	DATE_TOOL="gdate"
	if [ ! $(command -v ${DATE_TOOL}) ]
	then
		echo "Error - Cannot find GNU coreutils tools (e.g., ${DATE_TOOL}). " \
			 "Install those with \`brew install coreutils\`"
		return 1
	fi
fi

# Logging module 
log() {
	if [ -z "${LOG_FILE}" ]
	then
		echo "Error - The LOG_FILE environment variable should be set and points to the file in which the logs may be written." > /dev/stderr
		echo "        See ${THIS_SCRIPT_GIT_URL} for the details of the log() function."  > /dev/stderr
		return 1
	fi
	local canWriteToFile="$(touch ${LOG_FILE} 2> /dev/null && echo "Y" || echo "N")"
	if [ "${canWriteToFile}" == "N" ]
	then
		echo "Error - The ${LOG_FILE} is expected to be a wrtiteable file in which the logs may be written; apparently, no logs may be written to ${LOG_FILE}."  > /dev/stderr
		echo "        See ${THIS_SCRIPT_GIT_URL} for the details of the log() function."  > /dev/stderr
		return 1
	fi
	if [ -z "${SCRIPT_GIT_URL}" ]
	then
		echo "Error - The SCRIPT_GIT_URL environment variable should be set, but is not."
		echo "See ${THIS_SCRIPT_GIT_URL} for the details of the log() function."
		return 1
	fi
	local caller_script="$(basename ${THIS_SCRIPT_GIT_URL})"
    logTime="$(${DATE_TOOL} "+%Y-%m-%d %H:%M:%S" --utc)"
    echo "############### [${logTime} (UTC)][${UNAME}@${HNAME}][${caller_script}][${FUNC}]: $1 ######################" | tee -a ${LOG_FILE}
}

logMulti() {
	if [ -z "${LOG_FILE}" ]
	then
		echo "Error - The LOG_FILE environment variable should be set and points to the file in which the logs may be written." > /dev/stderr
		echo "        See ${THIS_SCRIPT_GIT_URL} for the details of the log() function."  > /dev/stderr
		return 1
	fi
	local canWriteToFile="$(touch ${LOG_FILE} 2> /dev/null && echo "Y" || echo "N")"
	if [ "${canWriteToFile}" == "N" ]
	then
		echo "Error - The ${LOG_FILE} is expected to be a wrtiteable file in which the logs may be written; apparently, no logs may be written to ${LOG_FILE}."  > /dev/stderr
		echo "        See ${THIS_SCRIPT_GIT_URL} for the details of the log() function."  > /dev/stderr
		return 1
	fi
	if [ -z "${SCRIPT_GIT_URL}" ]
	then
		echo "Error - The SCRIPT_GIT_URL environment variable should be set, but is not."
		echo "See ${THIS_SCRIPT_GIT_URL} for the details of the log() function."
		return 1
	fi
	local caller_script="$(basename ${THIS_SCRIPT_GIT_URL})"
    logTime="$(${DATE_TOOL} "+%Y-%m-%d %H:%M:%S" --utc)"
    echo "############### [${logTime} (UTC)][${UNAME}@${HNAME}][${caller_script}][${FUNC}] - begin ######################" | tee -a ${LOG_FILE}
	#declare -a line_list=($@)
    for myline in "$@"
	do
		echo "${myline}" | tee -a ${LOG_FILE}
	done
    echo "############### [${logTime} (UTC)][${UNAME}@${HNAME}][${FUNC}] - end ######################" | tee -a ${LOG_FILE}
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

