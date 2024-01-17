#!/usr/bin/env bash
#
# File: https://github.com/cloud-helpers/k8s-job-wrappers/tree/main/setCloudStorage.sh
#
# Utility supporting executing tasks from within Kubernetes (k8s) pods
#
# Functions supporting interacting with cloud storage, AWS S3 to begin with
#
# Dependencies:
# * setDistAndArch.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/main/setDistAndArch.sh)
# * setGnuTools.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/main/setGnuTools.sh)
# * setLogFunc.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/main/setLogFunc.sh)
#

#
THIS_KJW_SCRIPT_URL="https://github.com/cloud-helpers/k8s-job-wrappers/tree/main/setCloudStorage.sh"
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

# Set up log functions
source ${KJW_CURRENT_DIR}/setLogFunc.sh
retval=$?
if [ "${retval}" != 0 ]
then
    echo "Call to setLogFunc.sh failed. Returned code: ${retval}" > /dev/stderr
    return ${retval}
fi

# Translate an S3 folder into a browsable URL
translateS3Folder() {
	local FUNC_CUR="${KJW_FUNC}"
	KJW_FUNC="translateS3Folder"
	log "Beginning of function"

	#
	local s3_path="${KJW_S3_URL}"
	if [ ! -z "$1" ]
	then
		s3_path="$1"
	fi

	# Extract the S3 bucket name and S3 relative file-path
	local s3_bucket="$(echo "${s3_path}"|cut -d'/' -f3,3)"
	local s3_rel_path="$(echo "${s3_path}"|cut -d'/' -f4-)"

	#
	local s3_trsltd_url="https://s3.console.aws.amazon.com/s3/buckets/${s3_bucket}?prefix=${s3_rel_path}/"
	echo ${s3_trsltd_url}
	
	#
	log "End of function"
	KJW_FUNC="${FUNC_CUR}"
}

# Translate an S3 file-path into a browsable URL
translateS3Filepath() {
	local FUNC_CUR="${KJW_FUNC}"
	KJW_FUNC="translateS3Filepath"
	log "Beginning of function"

	#
	local s3_path="${KJW_S3_URL}"
	if [ ! -z "$1" ]
	then
		s3_path="$1"
	fi

	# Extract the S3 bucket name and S3 relative file-path
	local s3_bucket="$(echo "${s3_path}"|cut -d'/' -f3,3)"
	local s3_rel_path="$(echo "${s3_path}"|cut -d'/' -f4-)"

	#
	local s3_trsltd_url="https://s3.console.aws.amazon.com/s3/object/${s3_bucket}?prefix=${s3_rel_path}"
	echo ${s3_trsltd_url}
	
	#
	log "End of function"
	KJW_FUNC="${FUNC_CUR}"
}

# Content of the remote data folder on AWS S3
browseS3Folder() {
	local FUNC_CUR="${KJW_FUNC}"
	KJW_FUNC="browseS3Folder"
	log "Beginning of function"

	# Sanity checks
	if [ -z "${KJW__S3_BASE_URL}" ]
	then
		logMulti "Error - KJW__S3_BASE_URL environment variable should be set, but is not." \
		  ". Current script: ${SCRIPT_GIT_URL}" \
		  ". That function (${KJW_FUNC}) is usually launched from within a virtual machine."
		#
		log "End of function"
		KJW_FUNC="${FUNC_CUR}"
		return 1
	fi
	
	#
    log "Content of the Carrier Contact Statistics API data folder on AWS S3 (${DATA_S3_BASE_URL} ; ${DATA_S3_BASE_BROWSABLE_URL}):"
    logMulti "$(aws s3 ls --human --summarize ${DATA_S3_BASE_URL}/ 2>&1)"

	#
	log "End of function"
	KJW_FUNC="${FUNC_CUR}"
}

