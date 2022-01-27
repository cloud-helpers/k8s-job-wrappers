#!/usr/bin/env bash
#
# File: https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/setVersionedEnv.sh
#
# Utility supporting executing tasks from within Kubernetes (k8s) pods
#
# Functions supporting the preparation of a versioned environment, such as
# configuration directories and files, as well as output directories,
# for instance for data transformation steps. The whole idea is to support
# the full reproducibility/observability of data transformation processes
#
# Dependencies:
# * setDistAndArch.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/setDistAndArch.sh)
# * setGnuTools.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/setGnuTools.sh)
# * setLogFunc.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/setLogFunc.sh)
# * setCloudStorage.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/setCloudStorage.sh)
#

#
THIS_KJW_SCRIPT_URL="https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/shlib/setVersionedEnv.sh"
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

# Set up cloud storage related functions
source ${KJW_CURRENT_DIR}/setCloudStorage.sh
retval=$?
if [ "${retval}" != 0 ]
then
    echo "Call to setCloudStorage.sh failed. Returned code: ${retval}" > /dev/stderr
    return ${retval}
fi

# Export a few variables with the various time-stamp components
setTSVar() {
	local FUNC_CUR="${KJW_FUNC}"
	KJW_FUNC="setTSVar"
	log "Beginning of function"
	
	# Time-stamp, used to derive the folder hierarchy on S3, to store both the
	# test reports as well as the log files
	NOW_TS="$(${DATE_TOOL} "+%Y-%m-%d-%H-%M-%S" --utc)"

	# Derive the time-based folder structure
	## Up to the day
	TS_YEAR="$(echo "${NOW_TS}"|cut -d'-' -f1)"
	TS_MONTH="$(echo "${NOW_TS}"|cut -d'-' -f2)"
	TS_DAY="$(echo "${NOW_TS}"|cut -d'-' -f3)"
	TS_UP2DAY_DIR="${TS_YEAR}/${TS_YEAR}-${TS_MONTH}/${TS_YEAR}-${TS_MONTH}-${TS_DAY}"
	STS_DIR="${TS_UP2DAY_DIR}/${NOW_TS}"
	## Up to the hour
	TS_HOUR="$(echo "${NOW_TS}"|cut -d'-' -f4)"
	TS_MINUTE="$(echo "${NOW_TS}"|cut -d'-' -f5)"
	TS_UP2HR_DIR="${TS_UP2DAY_DIR}/${TS_YEAR}-${TS_MONTH}-${TS_DAY}-${TS_HOUR}"
	TS_DIR="${TS_UP2HR_DIR}/${NOW_TS}"

	# Metadata time-stamped folder
	S3_TSMTD_URL="${S3_MTD_URL}/${STS_DIR}"

	# Log time-stamped folder
	S3_TSLOG_URL="${S3_LOG_URL}/${TS_DIR}"

	#
	export S3_URL="s3://${S3_BUCKET}"
	S3_MTD_BROWSABLE_URL="$(translateS3Folder ${S3_MTD_URL})"
	S3_TSMTD_BROWSABLE_URL="$(translateS3Folder ${S3_TSMTD_URL})"
	S3_LOG_BROWSABLE_URL="$(translateS3Folder ${S3_LOG_URL})"
	S3_TSLOG_BROWSABLE_URL="$(translateS3Folder ${S3_TSLOG_URL})"
	DATA_S3_BASE_BROWSABLE_URL="$(translateS3Folder ${DATA_S3_BASE_URL})"
	APP_DATA_S3_BROWSABLE_URL="$(translateS3Filepath ${APP_DATA_S3_URL})"

	#
	log "End of function"
	KJW_FUNC="${FUNC_CUR}"
}

# Create the versioned tree structure on the local file-system 
setTSDirs() {
	local FUNC_CUR="${KJW_FUNC}"
	KJW_FUNC="setTSDirs"
	log "Beginning of function"
	
	if [ -z "${KJW_DATA_DIR}" ]
	then
		logMulti "Error - The KJW_DATA_DIR environment variable should be set, but is not." \
				 ". Current script: ${THIS_KJW_SCRIPT_URL}" \
				 ". That script is usually launched from within a virtual machine."
		#
		log "End of function"
		return 1
	fi

	if [ ! -d "${KJW_DATA_DIR}" ]
	then
		logMulti "Error - The ${KJW_DATA_DIR} local data directory should exist and accessible, but does not." \
				 ". Current script: ${THIS_KJW_SCRIPT_URL}" \
				 ". That script is usually launched from within a virtual machine."
		#
		log "End of function"
		return 1
	fi

	# Meta-data directory
	export KJW_MTD_DIR="${KJW_DATA_DIR}/metadata"
	#mkdir -p ${KJW_MTD_DIR}

	# Metadata file
	export KJW_MTD_FILE="${KJW_MTD_DIR}/kjw-${S3_APP_DIR}.csv"
	#rm -f ${KJW_MTD_FILE}

	#
	log "End of function"
	KJW_FUNC="${FUNC_CUR}"
}

reportTSEnv() {
	local FUNC_CUR="${KJW_FUNC}"
	KJW_FUNC="setTSDirs"
	log "Beginning of function"
	
	# Reporting
	log "File: ${SCRIPT_GIT_URL}"
	logMulti "Versioned env" \
			 "=============" \
			 "* NOW_TS: ${NOW_TS}" \
			 "* STS_DIR: ${STS_DIR}" \
			 "* TS_DIR: ${TS_DIR}" \
			 "." \
			 "S3 bucket" \
			 "=========" \
			 "* KJW_S3_BUCKET: ${KJW_S3_BUCKET}" \
			 "* KJW_S3_URL: ${KJW_S3_URL}" \
			 "* S3_APP_DIR: ${S3_APP_DIR}" \
			 "* S3_MTD_URL: ${S3_MTD_URL}" \
			 " => ${S3_MTD_BROWSABLE_URL}" \
			 "* S3_TSMTD_URL: ${S3_TSMTD_URL}" \
			 " => ${S3_TSMTD_BROWSABLE_URL}" \
			 "* S3_LOG_URL: ${S3_LOG_URL}" \
			 " => ${S3_LOG_BROWSABLE_URL}" \
			 "* S3_TSLOG_URL: ${S3_TSLOG_URL}" \
			 " => ${S3_TSLOG_BROWSABLE_URL}" \
			 "* S3_APP_DATA_DIR: ${S3_APP_DATA_DIR}" \
			 "* DATA_S3_BASE_URL: ${DATA_S3_BASE_URL}" \
			 " => ${DATA_S3_BASE_BROWSABLE_URL}" \
			 "* APP_DATA_S3_URL: ${CARRIERS_DATA_S3_URL}" \
			 " => ${APP_DATA_S3_BROWSABLE_URL}" \
			 "."

	#
	log "End of function"
	KJW_FUNC="${FUNC_CUR}"
}

# Create a metadata file and upload it on to AWS S3
updateMetadata() {
	local FUNC_CUR="${KJW_FUNC}"
	KJW_FUNC="updateMetadata"
	log "Beginning of function"
	
	# Sanity check
	if [ -z "${KJW_MTD_DIR}" ]
	then
		logMulti "Error - KJW_MTD_DIR variable should be set, but is not." \
		  ". Current script: ${THIS_KJW_SCRIPT_URL}" \
		  ". That function (${FUNC_CUR}) is usually launched from within a virtual machine."
		#
		log "End of function"
		KJW_FUNC="${FUNC_CUR}"
		return 1
	fi
	if [ -z "${KJW_MTD_FILE}" ]
	then
		logMulti "Error - KJW_MTD_FILE variable should be set, but is not." \
		  ". Current script: ${THIS_KJW_SCRIPT_URL}" \
		  ". That function (${FUNC_CUR}) is usually launched from within a virtual machine."
		#
		log "End of function"
		KJW_FUNC="${FUNC_CUR}"
		return 1
	fi
	if [ -z "${S3_MTD_URL}" ]
	then
		logMulti "Error - S3_MTD_URL variable should be set, but is not." \
		  ". Current script: ${THIS_KJW_SCRIPT_URL}" \
		  ". That function (${FUNC_CUR}) is usually launched from within a virtual machine."
		#
		log "End of function"
		KJW_FUNC="${FUNC_CUR}"
		return 1
	fi
	if [ -z "${S3_TSMTD_URL}" ]
	then
		logMulti "Error - S3_TSMTD_URL variable should be set, but is not." \
		  ". Current script: ${THIS_KJW_SCRIPT_URL}" \
		  ". That function (${FUNC_CUR}) is usually launched from within a virtual machine."
		#
		log "End of function"
		KJW_FUNC="${FUNC_CUR}"
		return 1
	fi
	
	cat > ${KJW_MTD_FILE} << _EOF
NOW_TS^${NOW_TS}
ISNOT_CONTAINER^${ISNOT_CONTAINER}
KJW_DATA_DIR^${KJW_DATA_DIR}
TMP_DATA_DIR^${TMP_DATA_DIR}
KJW_MTD_DIR^${KJW_MTD_DIR}
KJW_MTD_FILE^${KJW_MTD_FILE}
KJW_LOG_FILE^${KJW_LOG_FILE}
STS_DIR^${STS_DIR}
TS_DIR^${TS_DIR}
APP_DATA_FILENAME^${APP_DATA_FILENAME}
APP_DATA_TYPE^${APP_DATA_TYPE}
APP_MTD_FILENAME^${APP_MTD_FILENAME}
KJW_S3_BUCKET^${KJW_S3_BUCKET}
KJW_S3_URL^${KJW_S3_URL}
S3_APP_DIR^${S3_APP_DIR}
S3_MTD_URL^${S3_MTD_URL}
S3_MTD_BROWSABLE_URL^${S3_MTD_BROWSABLE_URL}
S3_TSMTD_URL^${S3_TSMTD_URL}
S3_TSMTD_BROWSABLE_URL^${S3_TSMTD_BROWSABLE_URL}
S3_LOG_URL^${S3_LOG_URL}
S3_LOG_BROWSABLE_URL^${S3_LOG_BROWSABLE_URL}
S3_TSLOG_URL^${S3_TSLOG_URL}
S3_TSLOG_BROWSABLE_URL^${S3_TSLOG_BROWSABLE_URL}
S3_APP_DATA_DIR^${S3_APP_DATA_DIR}
DATA_S3_BASE_URL^${DATA_S3_BASE_URL}
DATA_S3_BASE_BROWSABLE_URL^${DATA_S3_BASE_BROWSABLE_URL}
APP_DATA_S3_URL^${APP_DATA_S3_URL}
APP_DATA_S3_BROWSABLE_URL^${APP_DATA_S3_BROWSABLE_URL}
curl-version^$(curl --version|head -1)
aws-cli-version^$(aws --version)
jq-version^$(jq --version)
_EOF

	# Upload to (and check) the base metadata folder on S3
    log "Uploading metadata file from ${KJW_MTD_DIR}/ to AWS S3 (${S3_MTD_URL} ; ${S3_MTD_BROWSABLE_URL})..."
    logMulti "$(aws s3 sync --no-progress ${KJW_MTD_DIR}/ ${S3_MTD_URL} 2>&1)"

    log "Content of AWS S3 (${S3_MTD_URL} ; ${S3_MTD_BROWSABLE_URL}):"
    logMulti "$(aws s3 ls --human --summarize ${S3_MTD_URL}/ 2>&1)"

	# Upload to (and check) the time-stamped metadata folder on S3
    log "Uploading metadata file from ${KJW_MTD_DIR}/ to AWS S3 (${S3_TSMTD_URL} ; ${S3_TSMTD_BROWSABLE_URL})..."
    logMulti "$(aws s3 sync --no-progress ${KJW_MTD_DIR}/ ${S3_TSMTD_URL} 2>&1)"

    log "Content of AWS S3 (${S3_TSMTD_URL} ; ${S3_TSMTD_BROWSABLE_URL}):"
    logMulti "$(aws s3 ls --human --summarize ${S3_TSMTD_URL}/ 2>&1)"

	#
	log "End of function"
	KJW_FUNC="${FUNC_CUR}"
}

