#!/bin/bash

set -e

KF_VERSION=2.10.3
KF_ARCH=amd64
KF_TAR=kubefirst_${KF_VERSION}_linux_${KF_ARCH}.tar.gz
wget https://github.com/konstructio/kubefirst/releases/download/v${KF_VERSION}/${KF_TAR}
mkdir -p ${HOME}/.local/bin
export PATH="$PATH:${HOME}/.local/bin"
tar --overwrite -xvf ${KF_TAR} -C ${HOME}/.local/bin kubefirst
chmod +x ${HOME}/.local/bin
rm -rf $KF_TAR

echo "trying kubefirst version"
kubefirst version
