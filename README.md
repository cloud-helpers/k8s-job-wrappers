

# Overview
[This project](https://github.com/cloud-helpers/k8s-job-wrappers)
contains a few Shell scripts supporting the execution of tasks both from
within Kubernetes (k8s) pods (_i.e._, from within a container) and from
a laptop or a virtual machine (VM).
The idea is to use the same support scripts to test an application both
from the usual daily environment (_e.g._, laptop, virtual machine (VM) on
a cloud provider) and from a container in a Kubernertes deployment.

K8S Job Wrappers is abbreviated as KJB.

# Usage
* Download and extract the archive of Shell scripts (from a `Dockerfile`,
  just remove the `sudo` keyword):
```bash
LOGSUP_VERSION="0.0.2"
curl -L -s \
  https://github.com/cloud-helpers/k8s-job-wrappers/archive/refs/tags/v$LOGSUP_VERSION.tar.gz \
  -o k8s-job-wrappers.tar.gz && \
tar zxf k8s-job-wrappers.tar.gz && rm -f k8s-job-wrappers.tar.gz && \
sudo mv -f k8s-job-wrappers-$LOGSUP_VERSION /usr/local/ && \
sudo ln -s /usr/local/k8s-job-wrappers-$LOGSUP_VERSION /usr/local/k8s-job-wrappers
```

* All the following steps may be performed from your own Shell script

* Specify a few environment variables
  + URL of the caller script:
```bash
export KJW_SCRIPT_URL="https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/k8s-job-wrapper-main.sh"
```
  + File-path to the log file:
```bash
export KJW_LOG_FILE="$HOME/tmp/application/my-application.log"
```
  + Name of the caller function:
```bash
export KJW_FUNC="main"
```
  + URL of a container image specification file (_e.g._, `Dockerfile`, if any):
```bash
export KJW_CTR_FILE="URL-to-container-image-specification-file"
```
  + URL of the Kubernetes deployment file (if any):
```bash
export KJW_K8S_DEPL_FILE="URL-to-K8S-deployment-YAML-file"
```

* Make sure that the log file is writeable:
```bash
mkdir -p $(dirname $KJW_LOG_FILE)
rm -f $KJW_LOG_FILE ; touch $KJW_LOG_FILE
```

* Source the Shell support script:
```bash
source /usr/local/k8s-job-wrappers/setLogFunc.sh
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
cat $KJW_LOG_FILE
```

* Clean up the generated log file:
```bash
rm -f $KJW_LOG_FILE
```


