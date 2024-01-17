#!/usr/bin/env bash
#
# File: https://github.com/cloud-helpers/k8s-job-wrappers/tree/main/setConfMgt.sh
#
# Utility supporting executing tasks from within Kubernetes (k8s) pods
#
# Functions supporting setting up environment variables from configuration files
#
# Dependencies:
# * setDistAndArch.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/main/setDistAndArch.sh)
# * setGnuTools.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/main/setGnuTools.sh)
# * setLogFunc.sh (https://github.com/cloud-helpers/k8s-job-wrappers/tree/main/setLogFunc.sh)
#

#
THIS_KJW_SCRIPT_URL="https://github.com/cloud-helpers/k8s-job-wrappers/tree/main/setConfMgt.sh"
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

# Check that the yq command-line utility has been installed and works
YQ_TOOL="$(command -v yq 2> /dev/null)"
if [ "${YQ_TOOL}" == "" ]
then
	logMulti "Error - The yq command-line utility has not been installed." \
		"Install it with \`brew install yq\` on MacOS or see https://github.com/mikefarah/yq for other platforms"
	return 1
fi

# Setup the environment variables specified in configuration files. Parameters:
# $1 - environment, e.g., 'local', 'dev', 'preprod', 'prod'
# $2 - base directory, e.g., 'confs'
# $3 - base name of the configuration files, e.g., params (the configuration file would then be params.yml)
setEnvVarsFromConfFiles() {
	local FUNC_CUR="${KJW_FUNC}"
	KJW_FUNC="setTSVar"
	log "Beginning of function"

	# Parse parameters
	ENV=${1:-"local"}
	CONFS_DIR=${2:-"confs"}
	CFG_BASE_NAME=${3:-"params"}

	# Reporting
	logMulti "ENV=${ENV} (derived from first parameter or default)" \
			 "CONFS_DIR=${CONFS_DIR} (derived from second parameter or default)" \
			 "CFG_BASE_NAME=${CFG_BASE_NAME} (derived from third parameter or default)" \
			 "=> Configuration files to be sourced: ${CONFS_DIR}/base/${CFG_BASE_NAME}.y*ml ${CONFS_DIR}/${ENV}/${CFG_BASE_NAME}.y*ml"

	# Sanity checks
	if [ ! -d "${CONFS_DIR}" ]; then
		log "Error - The ${CONFS_DIR}/ base directory does not seem to exist"
		log "End of function"; KJW_FUNC="${FUNC_CUR}"; return 1
	fi
	if [ ! -d "${CONFS_DIR}/base" ]; then
		log "Error - The ${CONFS_DIR}/base/ directory does not seem to exist"
		log "End of function"; KJW_FUNC="${FUNC_CUR}"; return 1
	fi
	if [ ! -d "${CONFS_DIR}/${ENV}" ]; then
		log "Error - The ${CONFS_DIR}/${ENV}/ directory does not seem to exist"
		log "End of function"; KJW_FUNC="${FUNC_CUR}"; return 1
	fi
	if [ ! -f "${CONFS_DIR}/base/${CFG_BASE_NAME}.yml" -a ! -f "${CONFS_DIR}/base/${CFG_BASE_NAME}.yaml" ]; then
		log "Error - No ${CONFS_DIR}/base/${CFG_BASE_NAME}.y*ml file seems to exist"
		log "End of function"; KJW_FUNC="${FUNC_CUR}"; return 1
	fi
	if [ ! -f "${CONFS_DIR}/${ENV}/${CFG_BASE_NAME}.yml" -a ! -f "${CONFS_DIR}/${ENV}/${CFG_BASE_NAME}.yaml" ]; then
		log "Error - No ${CONFS_DIR}/${ENV}/${CFG_BASE_NAME}.y*ml file seems to exist"
		log "End of function"; KJW_FUNC="${FUNC_CUR}"; return 1
	fi	
	
	#
	TMP_YQ_RST_FP="yq-results.txt"
	TMP_CFG_FP="yq-results.cfg"
	log "Setting up environment variables from ${CONFS_DIR}/base/${CFG_BASE_NAME}.y*ml ${CONFS_DIR}/${ENV}/${CFG_BASE_NAME}.y*ml..."
	yq ea '. as $item ireduce ({}; . * $item )' ${CONFS_DIR}/base/${CFG_BASE_NAME}.y*ml ${CONFS_DIR}/${ENV}/${CFG_BASE_NAME}.y*ml > ${TMP_YQ_RST_FP} 2>&1
	retval=$?
	if [ "${retval}" != 0 ]
	then
		log "Error - The parsing of the configuration files (${CONFS_DIR}/base/${CFG_BASE_NAME}.y*ml and ${CONFS_DIR}/${ENV}/${CFG_BASE_NAME}.y*ml) failed."
		log ".       See the ${TMP_YQ_RST_FP} file for details:"
		logMulti "$(ls -lFh ${TMP_YQ_RST_FP})"
		logMulti "$(cat ${TMP_YQ_RST_FP})"
		rm -f ${TMP_YQ_RST_FP}
		log "End of function"; KJW_FUNC="${FUNC_CUR}"
		return ${retval}
	fi

	# Transform the format from VAR: "value" to VAR="value", so that it may be
	# sourced directly by the Bash interpreter
	grep -e "^[[:alnum:]]" ${TMP_YQ_RST_FP} | tr : = | tr -d " " > ${TMP_CFG_FP}
	#
	logMulti "Merged environment variables to be setup:" \
			 "$(cat ${TMP_CFG_FP})"

	#
	source ${TMP_CFG_FP}

	# Cleaning and reporting
	rm -f ${TMP_YQ_RST_FP} ${TMP_CFG_FP}
	log "... done"

	#
	log "End of function"
	KJW_FUNC="${FUNC_CUR}"
}
