#!/usr/bin/env bash
#
# File: https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/setChecker.sh
#
# Utility supporting executing tasks from within Kubernetes (k8s) pods
#
# Functions performing checks, e.g., that a specific environment variable has
# been set, or that a specific file exists and is accessible
#
# Dependencies:
# * setDistAndArch.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/setDistAndArch.sh)
# * setGnuTools.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/setGnuTools.sh)
# * setLogFunc.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/setLogFunc.sh)
#

#
THIS_KJW_SCRIPT_URL="https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/shlib/setCheckers.sh"
KJW_FUNC="default"

# Derive where KJW has been installed
# Reference: https://stackoverflow.com/a/246128/798053
KJW_CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"

# Set up environment variables for the Linux distribution, host name
# and architecture
source ${KJW_CURRENT_DIR}/setDistAndArch.sh
retval=$?
if [ "${retval}" != 0 ]
then
    echo "Call to setDistAndArch.sh failed. Returned code: ${retval}" > /dev/stderr
    return ${retval}
fi

# Set up envrionment variables for command-line tools differing on MacOS
source ${KJW_CURRENT_DIR}/setGnuTools.sh
retval=$?
if [ "${retval}" != 0 ]
then
    echo "Call to setGnuTools.sh failed. Returned code: ${retval}" > /dev/stderr
    return ${retval}
fi

# Set up envrionment variables for logging support functions
source ${KJW_CURRENT_DIR}/setLogFunc.sh
retval=$?
if [ "${retval}" != 0 ]
then
    echo "Call to setGnuTools.sh failed. Returned code: ${retval}" > /dev/stderr
    return ${retval}
fi

# Check that a list of environment variables have been specified
assertEnvVar() {
    declare -a envVarNameList=($@)
    for idx in "${!envVarNameList[@]}"
    do
	local myEnvVarName="${envVarNameList[$idx]}"
	local myEnvVarValue="${!myEnvVarName}"
	if [ -z "${myEnvVarValue}" ]
	then
	    if [ -z "${KJW_LOG_FILE}" -o ! -w "${KJW_LOG_FILE}" ]
	    then
		# The log file has not been specified yet, so we log onto
		# the standard error stream
		echo "Error - The ${myEnvVarName} environment variable should be set, but is not." > /dev/stderr
		echo "        Current script: ${KJW_SCRIPT_URL}"  > /dev/stderr
		if [ ! -z "${KJW_K8S_DEPL_FILE}" ]
		then
		    echo "        That script is usually launched by a Kubernetes deployment (${KJW_K8S_DEPL_FILE})"  > /dev/stderr
		fi

	    else
		# The log file has been specified, so we log onto it
		if [ -z "${KJW_K8S_DEPL_FILE}" ]
		then
		    logMulti "Error - The ${myEnvVarName} environment variable should be set, but is not." \
		      "        Current script: ${KJW_SCRIPT_URL}"
		else
		    logMulti "Error - The ${myEnvVarName} environment variable should be set, but is not." \
		      "        Current script: ${KJW_SCRIPT_URL}"  \
		      "        That script is usually launched by a Kubernetes deployment (${KJW_K8S_DEPL_FILE})"
		fi
	    fi

	    # Return the position of the first environment variable not
	    # specified
	    return $(( $idx + 1 ))
	fi
    done  
}
