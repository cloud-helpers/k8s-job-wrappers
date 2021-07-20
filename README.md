

# Overview
[This project](https://github.com/cloud-helpers/k8s-job-wrappers)
contains a few Shell scripts supporting the execution of tasks both from
within Kubernetes (k8s) pods (_i.e._, from within a container) and from
a laptop or a virtual machine (VM).
The idea is to use the same support scripts to test an application both
from the usual daily environment (_e.g._, laptop, virtual machine (VM) on
a cloud provider) and from a container in a Kubernertes deployment.

# Usage
* Download and extract the archive of Shell scripts:
```bash
LOGSUP_VER="0.0.1"
wget https://github.com/cloud-helpers/k8s-job-wrappers/archive/refs/tags/v$LOGSUP_VER.tar.gz -O k8s-job-wrappers.tar.gz
tar zxf k8s-job-wrappers.tar.gz && rm -f k8s-job-wrappers.tar.gz
```

* All the following steps may be performed from your own Shell script

* Specify a few environment variables
  + URL of the caller script:
```bash
export SCRIPT_GIT_URL="https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/k8s-job-wrapper-main.sh"
```
  + File-path to the log file:
```bash
export LOG_FILE="$HOME/tmp/application/my-application.log"
```
  + Name of the caller function:
```bash
export FUNC="main"
```

* Make sure that the log file is writeable:
```bash
$ mkdir -p $(dirname $LOG_FILE)
$ touch $LOG_FILE
```

* Source the Shell support script:
```bash
source k8s-job-wrappers-$LOGSUP_VER/setLogFunc.sh
```

* Call the `log` functions
  + Beginning of the script:
```bash
logStart "My own application - We can achieve great things with collaboration"
```
  + Single-line log:
```bash
log "A single line log"
```
  + Multi-line log:
```bash
logMulti "The first line of a multi-line log" \
         ". Another line" \
         ". Last line"
```
  + End of the script:
```bash
logEnd "My own application - We can achieve great things with collaboration"
```

* And that is it. In order to check the resulting log file:
```bash
cat $LOG_FILE
```
