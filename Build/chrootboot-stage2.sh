#!/bin/bash

env -i HOME=${HOME} TERM=${TERM} PS1='\u:\w\$ ' > /dev/null 2>&1
set +h
umask 022 
echo
set +h

set -e

#set -e
if [ "${PS4}" == 'Line ${LINENO}: ' ];
then
        set -x
fi

PUR="/"
PSRC="/sources"
PTLS="/tools"
PCNTRB="/contrib"
export PUR PSRC PCNTRB PTLS

if [ "${USER}" == 'bts' ];
then
        export MAKEFLAGS="-j $(($(egrep '^processor[[:space:]]*:' /proc/cpuinfo | wc -l)+1))"
fi
ulimit -n 512

PLOGS=/var/log/pur_install
rm -rf ${PLOGS}
mkdir -p ${PLOGS}

contsrc_prep () {
        pkg=${1}
        if [ -z "${pkg}" ];
        then
                echo "WARNING: coresrc_prep called with no packagename!"
                exit 1
        fi
        rm -rf ${PSRC}/${pkg}
        cp -a ${PSRC}/pur_src/contrib/${pkg} ${PSRC}
        cd ${PSRC}/${pkg}
}

contsrc_prep2 () {
        pkg=${1}
        if [ -z "${pkg}" ];
        then
                echo "WARNING: coresrc_prep2 called with no packagename!"
                exit 1
        fi
        rm -rf ${PSRC}/${pkg}
        cp -a ${PSRC}/pur_src/contrib/${pkg} ${PSRC}
        mkdir ${PSRC}/${pkg}/${pkg}-build
        cd ${PSRC}/${pkg}/${pkg}-build
}

contsrc_clean () {
        pkg=${1}
        if [ -z "${pkg}" ];
        then
                echo "WARNING: coresrc_clean called with no packagename!"
                exit 1
        fi
        cd ${PSRC}
        rm -rf ${PSRC}/${pkg}
}

rm -rf /tools
rm -f /usr/lib/lib{bfd,opcodes}.a
rm -f /usr/lib/libbz2.a
rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
rm -f /usr/lib/libltdl.a
rm -f /usr/lib/libfl.a
rm -f /usr/lib/libfl_pic.a
rm -f /usr/lib/libz.a
rm -rf /tmp/*


# LibreSSL
echo "[LibreSSL] Configuring..."
contsrc_prep libressl
# configure here
./configure --prefix=/usr --with-openssldir=/etc/ssl > ${PLOGS}/libressl_configure.1 2>&1
echo "[LibreSSL] Building..."
# compile here
make > ${PLOGS}/libressl_make.1 2>&1
make install >> ${PLOGS}/libressl_make.1 2>&1
contsrc_clean libressl

# python
echo "[Python] Configuring..."
contsrc_prep python
./configure --prefix=/usr > ${PLOGS}/python_configure.1 2>&1
echo "[Python] Building..."
make > ${PLOGS}/python_make.1 2>&1
make install >> ${PLOGS}/python_make.1 2>&1
contsrc_clean python

# libevent
# dependency for NTPsec so it's actually usable.
# needs to stay installed- is a runtime dep
contsrc_prep libevent
echo "[LibEvent] Configuring..."
./configure --prefix=/usr > ${PLOGS}/libevent_configure.1 2>&1
echo "[LibEvent] Building..."
make > ${PLOGS}/libevent_make.1 2>&1
make install >> ${PLOGS}/libevent_make.1 2>&1
contsrc_clean libevent

# NTPsec
# note: if we remove NTPsec as a base/contrib dep,
# we can remove python2 and libevent2 as well.
# without python2, ntpsec does not build
# and without libevent2:
##  Warning libevent2 does not work
##  This means ntpdig will not be built 
##  While not necessary you will lose 'ntpdate' functionality.
echo "[NTPsec] Configuring..."
contsrc_prep ntpsec
# configure here
python waf configure --prefix=/usr > ${PLOGS}/ntpsec_configure.1 2>&1
echo "[NTPsec] Building..."
# compile here
python waf > ${PLOGS}/ntpsec_make.1 2>&1
python waf install >> ${PLOGS}/npsec_make.1 2>&1
contsrc_clean ntpsec


# Net-Tools
# stable 1.6.0 release doesn't build properly in newer gcc.
# maybe incorporate "git archive -o repo.tar --remote=<repo url> <commit id>"?
#echo "[Net-Tools] Configuring..."
contsrc_prep net-tools
# configure here
#./configure --prefix=/usr > ${PLOGS}/net-tools_configure.1 2>&1
echo "[Net-Tools] Building..."
# compile here
yes "" | make > ${PLOGS}/net-tools_make.1 2>&1
make install >> ${PLOGS}/net-tools_make.1 2>&1
contsrc_clean net-tools



# zfs
contsrc_prep zfs
echo "[ZFS] Configuring..."
./configure --prefix=/usr > ${PLOGS}/zfs_configure.1 2>&1
echo "[ZFS] Building..."
make > ${PLOGS}/zfs_make.1 2>&1
make install >> ${PLOGS}/zfs_make.1 2>&1

## We need to built the kernel BEFORE spl.
## It wants the kernel sources, not just the headers...?
## Anyways, make sure to not do a coresrc_clean linux after the
## *kernel* is built.
#cd ${PSRC}/zfs/spl
#echo "[SPL] Configuring..."
#./configure --prefix=/usr > ${PLOGS}/spl_configure.1 2>&1
#echo "[SPL] Building..."
#make > ${PLOGS}/spl_make.1 2>&1
#make install >> ${PLOGS}/spl_make.1 2>&1
#contsrc_clean zfs

# cleanup python since we just needed it for ntpsec
rm -rf /usr/{lib,include,bin,share/man/man1}/python*
