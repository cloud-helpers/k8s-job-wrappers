#!/usr/bin/env bash
#
# File: https://github.com/cloud-helpers/k8s-job-wrappers/tree/master/setDistAndArch.sh
#
# Utility supporting executing tasks from within Kubernetes (k8s) pods
#
# Linux distribution and architecture
#
# On MacOS:
#  - Reference: https://ryanparman.com/posts/2019/using-gnu-command-line-tools-in-macos-instead-of-freebsd-tools/
#  - coreutils provides, in a non exhaustive list, date, wc, head
#  - sed is provided by gnu-sed
#

# Host name (on a K8S pod, it is the pod ID)
export KJW_HNAME="$(cat /etc/hostname 2> /dev/null || hostname 2> /dev/null || echo "Unknown-hostname")"

# User name (e.g., root)
export KJW_UNAME="$(id -u -n)"

# Platform (e.g., Linux, Darwin)
export KJW_PLTF="$(uname | tr '[:upper:]' '[:lower:]')"

# Architecture (e.g., amd64)
export KJW_ARCH="$(uname -m|sed 's/x86_/amd/')"

# Local IP address on AWS EC2 instances (to be improved: currently times out
# on non-AWS VM)
#KJW_LOCIP_AWS="$(curl -s 169.254.169.254/latest/meta-data/local-ipv4)"

