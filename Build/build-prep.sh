#!/bin/bash

set -e

# Pur extras
PURX="${HOME}/pur_extras"
ME=$(whoami)
ME_G=$(groups | awk '{print $1}')

if [[ "$(whoami)" == 'bts' ]];
then
	ME="pur"
	ME_G="pur"
fi

if [[ -z "${PSRC}" ]];
then
	echo "WARNING: THIS SCRIPT REQUIRES TO BE CALLED FROM THE PURBUILD SCRIPT."
	echo "DO NOT RUN IT STANDALONE."
	exit 1
fi

mkdir -p ${PURX}
sudo mv ${PLOGS} ${PURX}/.
sudo mv ${PSRC} ${PURX}/.
sudo mv ${PUR}/var/log/pur_install ${PURX}/chroot_logs
rm -f ${PUR}/chrootboot*
rm -rf ${PUR}/contrib


sudo chown -R ${ME} ${PURX}
find ${PURX}/. -type d -exec chmod 700 '{}' \;
find ${PURX}/. -type f -exec chmod 600 '{}' \;

