#!/bin/bash

set -e

PUR=${HOME}/purroot	
PTLS='/tools'
set +e
sudo umount -l ${PUR}/{run,sys,proc,dev} > /dev/null 2>&1
set -e
sudo mount --bind /dev ${PUR}/dev
sudo mount -t devpts devpts ${PUR}/dev/pts -o gid=5,mode=620
sudo mount -t proc proc ${PUR}/proc
sudo mount -t sysfs sysfs ${PUR}/sys
sudo mount -t tmpfs tmpfs ${PUR}/run

sudo chroot ${PUR} /usr/bin/env -i					\
	HOME=/root							\
	TERM="$TERM"							\
	PS1='\u:\w\$ '							\
	PATH=/bin:/usr/bin:/sbin:/usr/sbin				\
	PUR="/"								\
	PSRC="/sources"							\
	PTLS="/tools"							\
	PCNTRB="/contrib"						\
	MAKEFLAGS="${MAKEFLAGS}"					\
	/bin/bash --login

sudo umount -l ${PUR}/{run,sys,proc,dev} > /dev/null 2>&1
