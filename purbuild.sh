#!/bin/bash
set -e
## For moar debugging, before you run the script, run
## 	export PS4='Line ${LINENO}: '
##  (or add to your ~/.bashrc)
## That prints the line number of the current command
## (and with set -x, the actual command) for the script
## being run.-bts,Tue Jan 19 07:29:38 EST 2016
if [ "${PS4}" == 'Line ${LINENO}: ' ];
then
	set -x
fi

# RELEASE VERSION #
PUR_RLS="2016.04"
RLS_MOD="-RELEASE"
# for testing...
if [[ "$(whoami)" == "bts" ]];
then
	RLS_URL="http://10.1.1.1/pur"
else
	RLS_URL="http://g.rainwreck.com/pur"
fi

purlogo() {
cat <<"EOT"
            _   _
__________ (_) (_)       .____    .__                     
\______   \__ _________  |    |   |__| ____  __ _____  ___
 |     ___/  |  \_  __ \ |    |   |  |/    \|  |  \  \/  /
 |    |   |  |  /|  | \/ |    |___|  |   |  \  |  />    < 
 |____|   |____/ |__|    |_______ \__|___|  /____//__/\_ \
                                 \/       \/            \/  

Pür Linux Buildscript Version 1
Pür Linux Version ${PUR_RLS}${RLS_MOD}

You should have received a License file, if you cloned from Github.
If not, please see https://github.com/PurLinux/Base/blob/CURRENT/LICENSE
This script is released under a Simplified 2-Clause BSD license. Support 
truly Free software, and use a BSD license for your projects. 
GPL restrictions just make it Open, not Free.

LFS was originally used for reference, and to bootstrap the project.
FreeBSD inspired this project.
PkgSrc from NetBSD is used as the primary package management utility.
Instead of donating to Pür, go donate to LFS, the FreeBSD project, or NetBSD.
We're a small project, and currently have enough resources to do the needful.
Your money is better spent with the aforementioned projects.

This is the first half of the Pür Linux build process, which occurrs within 
the host environment. At the end, another script is called and run within a chroot.

EOT
}

purlogo


# Only supported on Arch.

#Deps list:
#_______________________________________
# gawk		|			|
# sed		|-- included in the	|
# grep		|   "base" group	|
#_______________|			|
# gcc					|-- included in the
# make					|   "base-devel" group
# bison					|
# patch					|
#_______________________________________|	
# gmp		|
# mpfr		|
# libmpc	|-- must be explicitly
# wget/curl	|   installed
#_______________|


#Important: Key Verification of packages is being implemented in an automated method
# where this script will fail and print to your screen if a key fails. It will require GPG to be installed.

# Build tests are commented out in some places due to some machines just plain being too fast/new.

# Check to make sure sh is a link to bash
if [ "$(sha256sum $(which sh) | awk '{print $1}')" != "$(sha256sum $(which bash) | awk '{print $1}')" ];
then
	echo " /!\ /!\ /!\ WARNING WARNING WARNING /!\ /!\ /!\ /!\ "
        echo " Your $(which sh) is NOT linked to $(which bash)!!   "
	echo " Please fix this (i.e. via: ln -sf $(which bash) $(which sh)"
        echo "/!\ /!\ /!\ WARNING WARNING WARNING /!\ /!\ /!\ /!\ "
        exit 1
fi

if [[ "$(whoami)" == "root" ]];
then
        echo " /!\ /!\ /!\ WARNING WARNING WARNING /!\ /!\ /!\ /!\ "
        echo " Don't run me as root. Create a new user!!      "
        echo "/!\ /!\ /!\ WARNING WARNING WARNING /!\ /!\ /!\ /!\ "
        exit 1
fi
echo

# Are we using curl or wget?
if ! type curl > /dev/null 2>&1;
then
        fetch_cmd="$(which wget) -c --progress=bar --tries=5 --waitretry 3 -a /tmp/fetch.log"
else
        fetch_cmd="$(which curl) --progress-bar -LSOf --retry 5 --retry-delay 3 -C -"
fi


# Scrub/create paths
mkdir -p ${HOME}/purroot
PUR=${HOME}/purroot
PLOGS=${PUR}/logs
rm -rf ${PLOGS}
mkdir -p ${PLOGS}

# Setting up ENV
# WELL, if this isn't the most hacky thing in the world. see the chroot section.
PATH_LOC=${PATH}
env_vars=$(env | sed -re "s/=(.*)/='\1'/g")
env > ${PLOGS}/env_vars.pre_clear
echo "Setting up the environment and cleaning results from previous runs if necessary..."
env -i HOME=${HOME} TERM=${TERM} PS1='\u:\w\$ ' > /dev/null 2>&1
set +h
umask 022
echo

# clean up from previous failed runs
if [ -z "${PUR}" ];
then
	echo "PUR VARIABLE IS UNSET! Further process will cause host system damage."
	exit 1
fi
set +e
sudo umount -l ${PUR}/{run,sys,proc,dev} > /dev/null 2>&1
sudo rm -rf ${PUR}/{bin,boot,etc,home,lib,mnt,opt,run,sys,proc,dev} > /dev/null 2>&1
set -e
# sudo is needed if tools has been chown'd
PTLS=/tools
PSRC=${PUR}/sources
PCNTRB=${PUR}/contrib
sudo rm -rf ${PTLS}
mkdir -p ${PUR}/tools
mkdir -p ${PSRC}
find ${PSRC}/. -maxdepth 1 -ignore_readdir_race -type d -exec rm -rf '{}' \; > /dev/null 2>&1
sudo chmod a+wt ${PSRC}
mkdir -p ${PCNTRB}
find ${PCNTRB}/. -maxdepth 1 -ignore_readdir_race -type d -exec rm -rf '{}' \; > /dev/null 2>&1
LC_ALL=POSIX
PUR_TGT="$(uname -m)-pur-linux-gnu"
sudo rm -rf ${PTLS}
sudo ln -s ${PUR}/tools /

rm -rf ${PTLS}/include
mkdir -p ${PTLS}/include
PATH=${PTLS}/bin:/usr/local/bin:/bin:/usr/bin
export LC_ALL PUR_TGT PATH PBLD

rm -rf ${HOME}/specs
mkdir -p ${HOME}/specs
sudo ln -s ${HOME}/specs /specs
if [ "${USER}" == 'bts' ];
then
	export MAKEFLAGS="-j $(($(egrep '^processor[[:space:]]*:' /proc/cpuinfo | wc -l)+1))"
fi
ulimit -n 512 ## Needed for building GNU Make on Debian


#Fetching everything.
cd ${PSRC}
echo "Fetching source tarballs (if necessary) and cleaning up from previous builds (if necessary). This may take a while..."
# using the official LFS mirror- ftp://mirrors-usa.go-parts.com/lfs/lfs-packages/7.8/- because upstream sites/mirrors are stupid and do things like not support RETRY.
# luckily, they bundle the entire archive in one handy tarball.
find . -maxdepth 1 -ignore_readdir_race -type d -exec rm -rf '{}' \; > /dev/null 2>&1
find . -maxdepth 1 -ignore_readdir_race -type f -not -name "pur_src*.tar.xz" -delete > /dev/null 2>&1
if [ -f "pur_src.${PUR_RLS}${RLS_MOD}.tar.xz" ];
then
	if type sha256sum > /dev/null 2>&1;
	then
		echo "Checking integrity..."
		${fetch_cmd} -s "${RLS_URL}/pur_src.${PUR_RLS}${RLS_MOD}.tar.xz.sha256"
		set +e
		$(which sha256sum) -c pur_src.${PUR_RLS}${RLS_MOD}.tar.xz.sha256
		if [ "${?}" != '0' ];
		then
			echo "SHA256 checksum failed. Try deleting ${PSRC}/pur_src.${PUR_RLS}${RLS_MOD}.tar.xz and re-running."
			exit 1
		fi
		set -e
	fi
else
	${fetch_cmd} ${RLS_URL}/pur_src.${PUR_RLS}${RLS_MOD}.tar.xz
	if type sha256sum > /dev/null 2>&1;
	then
		echo "Checking integrity..."
		${fetch_cmd} -s "${RLS_URL}/pur_src.${PUR_RLS}${RLS_MOD}.tar.xz.sha256"
		set +e
		$(which sha256sum) -c pur_src.${PUR_RLS}${RLS_MOD}.tar.xz.sha256
		if [ "${?}" != '0' ];
		then
			echo "SHA256 checksum failed. Try deleting ${PSRC}/pur_src.${PUR_RLS}${RLS_MOD}.tar.xz and re-running."
			exit 1
		fi
		set -e
	fi
fi
echo "Extracting main packageset..."
tar --totals -Jxf pur_src.${PUR_RLS}${RLS_MOD}.tar.xz
#cd pur_src/core
#mv * ${PSRC}
#cd ../contrib
#mv * ${PCNTRB}
#rm -rf pur_src
cd ${PSRC}/pur_src/core
GLIBCVERS=$(egrep '^glibc-[0-9]' versions.txt | sed -re 's/^.*[A-Za-z]-([0-9\.]+).*/\1/g')
#HOSTGLIBCVERS="2.11" # <2.13 had serious security issues, we don't want any possible contamination
HOSTGLIBCVERS="2.13"
# or, we can detect the host's actual glibc version.
#HOSTGLIBCVERS=$(/lib/libc.so.6 | egrep 'release\ version\ [0-9\.]+\,? ' | sed -re 's/^.*[[:space:]]+([0-9\.]+)(,|[[:space:]]+).*/\1/g')
GCCVER=$(egrep '^gcc-[0-9]' versions.txt | sed -re 's/[A-Za-z]*-(.*)$/\1/g')
PERLVER=$(egrep '^perl-[0-9]' versions.txt | sed -re 's/[A-Za-z]*-(.*)$/\1/g')
PERLMAJ=$(echo ${PERLVER} | sed -re 's/([0-9]*)\..*$/\1/g')
TCLVER=$(egrep '^tcl-[0-9]' versions.txt | sed -re 's/[A-Za-z]*-(.*)$/\1/g' | awk -F. '{print $1"."$2}')
VIMVER=$(egrep '^vim-[0-9]' versions.txt | sed -re 's/[A-Za-z]*-(.*)$/\1/g' | sed -e 's/\.//g')
export GLIBCVERS HOSTGLIBCVERS GCCVER PERLVER PERLMAJ TLCVER VIMVER

# Okay, so this would take way too much time...
#src_core_x () {
#	cd ${PSRC}
#	pkg=${1}
#	rm -rf ${pkg}
#	tar -C ${PSRC} -Jxf ${PSRC}/pur_src.${PUR_RLS}${RLS_MOD}.tar.xz pur_src/core/${pkg}
#	mv ${PSRC}/pur_src/core/${pkg} ${PSRC}/${pkg}
#	rm -rf ${PSRC}/pur_src
#}

coresrc_prep () {
	pkg=${1}
	if [ -z "${pkg}" ];
	then
		echo "WARNING: coresrc_prep called with no packagename!"
		exit 1
	fi
	rm -rf ${PSRC}/${pkg}
	cp -a ${PSRC}/pur_src/core/${pkg} ${PSRC}
	cd ${PSRC}/${pkg}
}

coresrc_prep2 () {
	pkg=${1}
	if [ -z "${pkg}" ];
	then
		echo "WARNING: coresrc_prep2 called with no packagename!"
		exit 1
	fi
	rm -rf ${PSRC}/${pkg}
	cp -a ${PSRC}/pur_src/core/${pkg} ${PSRC}
	mkdir ${PSRC}/${pkg}/${pkg}-build
	cd ${PSRC}/${pkg}/${pkg}-build
}

coresrc_clean () {
	pkg=${1}
	if [ -z "${pkg}" ];
	then
		echo "WARNING: coresrc_clean called with no packagename!"
		exit 1
	fi
	cd ${PSRC}
	rm -rf ${PSRC}/${pkg}
}

echo



############################################
# BUILDING BOOTSTRAP ENVIRONMENT IN /TOOLS #
############################################

#binutils first build
echo "Binutils - first pass."
coresrc_prep2 binutils
echo "[Binutils] Configuring..."
../configure --prefix=${PTLS}		\
	--with-sysroot=${PUR}		\
	--with-lib-path=${PTLS}/lib	\
	--target=${PUR_TGT}		\
	--disable-nls			\
	--disable-werror > ${PLOGS}/binutils_configure.1 2>&1

echo "[Binutils] Building..."
make > ${PLOGS}/binutils_make.1 2>&1
case $(uname -m) in
  x86_64) ln -s ${PTLS}/lib ${PTLS}/lib64 ;;
esac
make install >> ${PLOGS}/binutils_make.1 2>&1
coresrc_clean binutils

## building GCC first run.
echo "GCC - first pass."
#GCC DEPS
# May want to consider this in the future, just for keeping compat with GCC's suggested practices:
# Using  ./contrib/download_prerequisites instead of manually grabbing
coresrc_prep2 gcc

for i in mpfr mpc gmp;
do
	coresrc_prep ${i}
	cp -a ${PSRC}/${i} ${PSRC}/gcc/.
done
cd ${PSRC}/gcc

#GCC
echo "[GCC] Configuring..."
for file in $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h);
do
  cp -u ${file}{,.orig}
  sed -re "s@/lib(64)?(32)?/ld@${PTLS}&@g" -e "s@/usr@${PTLS}@g" ${file}.orig > ${file}
  echo "
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 \"${PTLS}/lib/\"
#define STANDARD_STARTFILE_PREFIX_2 \"\"" >> ${file}
  touch ${file}.orig
done
cd ${PSRC}/gcc/gcc-build
../configure						\
    --target=${PUR_TGT}					\
    --prefix=${PTLS}					\
    --with-glibc-version=${HOSTGLIBCVERS}		\
    --with-sysroot=${PUR}				\
    --with-newlib					\
    --without-headers					\
    --with-local-prefix=${PTLS}				\
    --with-native-system-header-dir=${PTLS}/include	\
    --disable-nls					\
    --disable-shared					\
    --disable-multilib					\
    --disable-decimal-float				\
    --disable-threads					\
    --disable-libatomic					\
    --disable-libgomp					\
    --disable-libquadmath				\
    --disable-libssp					\
    --disable-libvtv					\
    --disable-libstdcxx					\
    --enable-languages=c,c++ > ${PLOGS}/gcc_configure.1 2>&1

echo "[GCC] Building..."
make > ${PLOGS}/gcc_make.1 2>&1
make install >> ${PLOGS}/gcc_make.1 2>&1
coresrc_clean gcc
for i in mpfr mpc gmp;
do
	coresrc_clean ${i}
done

## Grabbing latest kernel headers
echo "[Kernel] Making and installing headers..."
coresrc_prep linux
make mrproper > ${PLOGS}/kernel-headers_make.1 2>&1
make INSTALL_HDR_PATH=dest headers_install >> ${PLOGS}/kernel-headers_make.1 2>&1
cp -r dest/include/* ${PTLS}/include
coresrc_clean linux

# Building glibc - first pass
echo "GlibC - first pass."
coresrc_prep2 glibc
echo "[GlibC] Configuring..."
../configure						\
      --prefix=${PTLS}					\
      --host=${PUR_TGT}					\
      --build=$(../scripts/config.guess)		\
      --disable-profile					\
      --enable-kernel=2.6.32				\
      --enable-obsolete-rpc				\
      --with-headers=${PTLS}/include			\
      libc_cv_forced_unwind=yes				\
      libc_cv_ctors_header=yes				\
      libc_cv_c_cleanup=yes > ${PLOGS}/glibc_configure.1 2>&1
# Note: the below was originally enabled.
# However, this version of GlibC is scrapped in the final version and likely the umlaut
# might break things- so disabling for sane initial toolchain.
#      --with-pkgversion='Pür Linux glibc'                 \

echo "[GlibC] Building..."
make > ${PLOGS}/glibc_make.1 2>&1
make install >> ${PLOGS}/glibc_make.1 2>&1

# Testing!
echo -n "Runnning tests before continuing... "
echo 'int main(){}' > dummy.c
${PUR_TGT}-gcc dummy.c
if readelf -l a.out | grep ": ${PTLS}" | grep -q ld-linux-x86-64.so.2;
then
	echo "Test passed."
	rm dummy.c a.out
else
	echo "Test Failed. Now Exiting, post glibc build."
	exit 1
fi
coresrc_clean glibc

#libstc++
echo "LibstdC++ - first pass."
coresrc_prep2 gcc
echo "[LibstdC++] Configuring..."
../libstdc++-v3/configure		\
    --host=${PUR_TGT}			\
    --prefix=${PTLS}			\
    --disable-multilib			\
    --disable-nls			\
    --disable-libstdcxx-threads		\
    --disable-libstdcxx-pch		\
    --with-gxx-include-dir=${PTLS}/${PUR_TGT}/include/c++/${GCCVER} > ${PLOGS}/libstdc++_configure.1 2>&1

echo "[LibstdC++] Building..."
make > ${PLOGS}/libstdc++_make.1 2>&1
make install >> ${PLOGS}/libstdc++_make.1 2>&1
coresrc_clean gcc


##############################
# BUILDING TOOLKIT IN /TOOLS #
##############################

# binutils pass 2
echo "Binutils - second pass."
coresrc_prep2 binutils
echo "[Binutils] Configuring..."
CC=${PUR_TGT}-gcc		\
AR=${PUR_TGT}-ar		\
RANLIB=${PUR_TGT}-ranlib	\
../configure			\
    --prefix=${PTLS}		\
    --disable-nls		\
    --disable-werror		\
    --with-lib-path=${PTLS}/lib	\
    --with-sysroot > ${PLOGS}/binutils_configure.2 2>&1

echo "[Binutils] Building..."
make > ${PLOGS}/binutils_make.2 2>&1
make install >> ${PLOGS}/binutils_make.2 2>&1
#fiddly bits
make -C ld clean > ${PLOGS}/binutils_post-tweaks.2 2>&1
make -C ld LIB_PATH=/usr/lib:/lib >> ${PLOGS}/binutils_post-tweaks.2 2>&1
cp ld/ld-new ${PTLS}/bin
coresrc_clean binutils

# GCC round 2
echo "GCC - second pass."
coresrc_prep2 gcc
#cd ${PTLS}/lib # why is this here?
cd ${PSRC}/gcc
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > $(dirname $(${PUR_TGT}-gcc -print-libgcc-file-name))/include-fixed/limits.h
for file in $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h);
do
  cp -u ${file}{,.orig}
  sed -re "s@/lib(64)?(32)?/ld@${PTLS}&@g" -e "s@/usr@${PTLS}@g" ${file}.orig > ${file}
  echo "
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 \"${PTLS}/lib/\"
#define STANDARD_STARTFILE_PREFIX_2 \"\"" >> ${file}
  touch ${file}.orig
done
for i in mpfr mpc gmp;
do
	coresrc_prep ${i}
	cp -a ${PSRC}/${i} ${PSRC}/gcc/.
done

cd ${PSRC}/gcc/gcc-build
find ./ -name 'config.cache' -exec rm -rf '{}' \;
echo "[GCC] Configuring..."
CC=${PUR_TGT}-gcc					\
CXX=${PUR_TGT}-g++					\
AR=${PUR_TGT}-ar					\
RANLIB=${PUR_TGT}-ranlib				\
../configure						\
    --prefix=${PTLS}					\
    --with-local-prefix=${PTLS}				\
    --with-native-system-header-dir=${PTLS}/include	\
    --enable-languages=c,c++				\
    --disable-libstdcxx-pch				\
    --disable-multilib					\
    --disable-bootstrap					\
    --disable-libgomp > ${PLOGS}/gcc_configure.2 2>&1

echo "[GCC] Building..."
make > ${PLOGS}/gcc_make.2 2>&1
make install >> ${PLOGS}/gcc_make.2 2>&1
ln -s gcc ${PTLS}/bin/cc

#testing again
echo -n "Runnning tests before continuing... "
echo 'int main(){}' > dummy.c
${PUR_TGT}-gcc dummy.c
if readelf -l a.out | grep ": ${PTLS}" | grep -q ld-linux;
then
	echo "Test passed."
	rm dummy.c a.out
else
	echo "Test Failed. Now Exiting, post GCC Round 2 build"
        rm dummy.c a.out
        exit 1
fi
coresrc_clean gcc
for i in mpfr mpc gmp;
do
	coresrc_clean ${i}
done

## Tests
echo "Running further tests..."
# TCL
coresrc_prep tcl
cd unix
echo "[TCL] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/tcl_configure.1 2>&1
echo "[TCL] Building..."
make > ${PLOGS}/tcl_make.1 2>&1
TZ=UTC make test >> ${PLOGS}/tcl_test.1 2>&1
make install >> ${PLOGS}/tcl_test.1 2>&1
chmod u+w ${PTLS}/lib/libtcl${TCLVER}.so
make install-private-headers >> ${PLOGS}/tcl_test.1 2>&1
ln -s tclsh${TCLVER} ${PTLS}/bin/tclsh
coresrc_clean tcl

#Expect
coresrc_prep expect
echo "[Expect] Configuring..."
sed -i -e 's:/usr/local/bin:/bin:' configure
./configure --prefix=${PTLS}		\
            --with-tcl=${PTLS}/lib	\
            --with-tclinclude=${PTLS}/include > ${PLOGS}/expect_configure.1 2>&1

echo "[Expect] Building..."
make > ${PLOGS}/expect_make.1 2>&1
make tests >> ${PLOGS}/expect_make.1 2>&1
make SCRIPTS="" install >> ${PLOGS}/expect_make.1 2>&1
coresrc_clean expect

#DejaGNU
coresrc_prep dejagnu
echo "[DejaGNU] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/dejagnu_configure.1 2>&1

echo "[DejaGNU] Building..."
make install > ${PLOGS}/dejagnu_make.1 2>&1
#make check >> ${PLOGS}/dejagnu_make.1 2>&1
coresrc_clean dejagnu

#check
coresrc_prep check
echo "[Check] Configuring..."
# this is necessary since we download from git rather than sourceforge. fuck sourceforge.
autoreconf --install > ${PLOGS}/check_configure.1 2>&1
PKG_CONFIG= ./configure --prefix=${PTLS} >> ${PLOGS}/check_configure.1 2>&1

echo "[Check] Building..."
make > ${PLOGS}/check_make.1 2>&1
#make check >> ${PLOGS}/check_make.1 2>&1
make install >> ${PLOGS}/check_make.1 2>&1
coresrc_clean check

# ncurses
coresrc_prep ncurses
echo "[nCurses] Configuring..."
sed -i -e 's/mawk//' configure # used for ncurses
./configure --prefix=${PTLS}	\
            --with-shared	\
            --without-debug	\
            --without-ada	\
            --enable-widec	\
            --enable-overwrite > ${PLOGS}/ncurses_configure.1 2>&1

echo "[nCurses] Building..."
make > ${PLOGS}/ncurses_make.1 2>&1
make install >> ${PLOGS}/ncurses_make.1 2>&1
coresrc_clean ncurses

#bash
coresrc_prep bash
echo "[Bash] Configuring..."
./configure --prefix=${PTLS} --without-bash-malloc > ${PLOGS}/bash_configure.1 2>&1

echo "[Bash] Building..."
make > ${PLOGS}/bash_make.1 2>&1
# make tests >> ${PLOGS}/bash_make.1 2>&1
make install >> ${PLOGS}/bash_make.1 2>&1
ln -s bash ${PTLS}/bin/sh
coresrc_clean bash

#Bzip2
coresrc_prep bzip2
echo "[Bzip2] Building..."
make > ${PLOGS}/bzip2_make.1 2>&1
make PREFIX=${PTLS} install >> ${PLOGS}/bzip2_make.1 2>&1
coresrc_clean bzip2

#Coreutils
coresrc_prep coreutils
echo "[Coreutils] Configuring..."
./configure --prefix=${PTLS} --enable-install-program=hostname > ${PLOGS}/coreutils_configure.1 2>&1

echo "[Coreutils] Building..."
make > ${PLOGS}/coreutils_make.1 2>&1
# make RUN_EXPENSIVE_TESTS=yes check >> ${PLOGS}/coreutils_make.1 2>&1
make install >> ${PLOGS}/coreutils_make.1 2>&1
coresrc_clean coreutils

#Diffutils
coresrc_prep diffutils
echo "[Diffutils] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/diffutils_configure.1 2>&1

echo "[Diffutils] Building..."
make > ${PLOGS}/diffutils_make.1 2>&1
# make check >> ${PLOGS}/diffutils_make.1 2>&1
make install >> ${PLOGS}/diffutils_make.1 2>&1
coresrc_clean diffutils

# File
coresrc_prep file
echo "[File] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/file_configure.1 2>&1

echo "[File] Building..."
make > ${PLOGS}/file_make.1 2>&1
#make check >> ${PLOGS}/file_make.1 2>&1
make install >> ${PLOGS}/file_make.1 2>&1
coresrc_clean file

# Findutils
coresrc_prep findutils
echo "[Findutils] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/findutils_configure.1 2>&1

echo "[Findutils] Building..."
make > ${PLOGS}/findutils_make.1 2>&1
#make check >> ${PLOGS}/findutils_makee.1 2>&1
make install >> ${PLOGS}/findutils_makee.1 2>&1
coresrc_clean findutils

# GAWK
coresrc_prep gawk
echo "[Gawk] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/gawk_configure.1 2>&1

echo "[Gawk] Building..."
make > ${PLOGS}/gawk_make.1 2>&1
#make check >> ${PLOGS}/gawk_make.1 2>&1
make install >> ${PLOGS}/gawk_make.1 2>&1
coresrc_clean gawk

#gettext
coresrc_prep gettext
cd gettext-tools
echo "[Gettext] Configuring..."
EMACS="no" ./configure --prefix=${PTLS} --disable-shared > ${PLOGS}/gettext_configure.1 2>&1

echo "[Gettext] Building..."
make -C gnulib-lib > ${PLOGS}/gettext_make.1 2>&1
make -C intl pluralx.c >> ${PLOGS}/gettext_make.1 2>&1
make -C src msgfmt >> ${PLOGS}/gettext_make.1 2>&1
make -C src msgmerge >> ${PLOGS}/gettext_make.1 2>&1
make -C src xgettext >> ${PLOGS}/gettext_make.1 2>&1
cp src/{msgfmt,msgmerge,xgettext} ${PTLS}/bin
coresrc_clean gettext

# GNU Grep
coresrc_prep grep
echo "[Grep] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/grep_configure.1 2>&1

echo "[Grep] Building..."
make > ${PLOGS}/grep_make.1 2>&1
#make check >> ${PLOGS}/grep_make.1 2>&1
make install >> ${PLOGS}/grep_make.1 2>&1
coresrc_clean grep

# GNU GZip
coresrc_prep gzip
echo "[Gzip] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/gzip_configure.1 2>&1

echo "[Gzip] Building..."
make > ${PLOGS}/gzip_make.1 2>&1
#make check >> ${PLOGS}/gzip_make.1 2>&1
make install >> ${PLOGS}/gzip_make.1 2>&1
coresrc_clean gzip

# M4
coresrc_prep m4
echo "[M4] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/m4_configure.1 2>&1

echo "[M4] Building..."
make > ${PLOGS}/m4_make.1 2>&1
#make check >> ${PLOGS}/m4_make.1 2>&1
make install >> ${PLOGS}/m4_make.1 2>&1
coresrc_clean m4

# GNU Make
coresrc_prep make
echo "[Make] Configuring..."
./configure --prefix=${PTLS} --without-guile > ${PLOGS}/make_configure.1 2>&1

echo "[Make] Building..."
make > ${PLOGS}/make_make.1 2>&1
#make check >> ${PLOGS}/make_make.1 2>&1
make install >> ${PLOGS}/make_make.1 2>&1
coresrc_clean make

#GNU Patch
coresrc_prep patch
echo "[Patch] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/patch_configure.1 2>&1

echo "[Patch] Building..."
make > ${PLOGS}/patch_make.1 2>&1
#make check >> ${PLOGS}/patch_make.1 2>&1
make install >> ${PLOGS}/patch_make.1 2>&1
coresrc_clean patch

# Perl (Will be removed from Base eventually/hopefully)
coresrc_prep perl
echo "[Perl] Configuring..."
sh Configure -des -Dprefix=${PTLS} -Dlibs=-lm > ${PLOGS}/perl_configure.1 2>&1

echo "[Perl] Building..."
make > ${PLOGS}/perl_make.1 2>&1
cp perl cpan/podlators/pod2man ${PTLS}/bin
mkdir -p ${PTLS}/lib/perl${PERLMAJ}/${PERLVER}
cp -R lib/* ${PTLS}/lib/perl${PERLMAJ}/${PERLVER}
coresrc_clean perl

#GNU Sed
coresrc_prep sed
echo "[Sed] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/sed_configure.1 2>&1

echo "[Sed] Building..."
make > ${PLOGS}/sed_make.1 2>&1
#make check >> ${PLOGS}/sed_make.1 2>&1
make install >> ${PLOGS}/sed_make.1 2>&1
coresrc_clean sed

#GNU Tar
coresrc_prep tar
echo "[Tar] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/tar_configure.1 2>&1

echo "[Tar] Building..."
make > ${PLOGS}/tar_make.1 2>&1
#make check >> ${PLOGS}/tar_make.1 2>&1
make install >> ${PLOGS}/tar_make.1 2>&1
coresrc_clean tar

#GNU Texinfo
coresrc_prep texinfo
echo "[Texinfo] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/texinfo_configure.1 2>&1

echo "[Texinfo] Building..."
make > ${PLOGS}/texinfo_make.1 2>&1
#make check >> ${PLOGS}/texinfo_make.1 2>&1
make install >> ${PLOGS}/texinfo_make.1 2>&1
coresrc_clean texinfo

# Util-Linux
coresrc_prep util-linux
echo "[Util-Linux] Configuring..."
./configure --prefix=${PTLS}			\
            --without-python			\
            --disable-makeinstall-chown		\
            --without-systemdsystemunitdir	\
            PKG_CONFIG="" > ${PLOGS}/util-linux_configure.1 2>&1

echo "[Util-Linux] Building..."
# i've had issues with this failing- not finding zlib.h, libudev.h, etc.
#MAKEFLAGS_DFLT=${MAKEFLAGS}
#MAKEFLAGS=''
#make -j1 > ${PLOGS}/util-linux_make.1 2>&1
make > ${PLOGS}/util-linux_make.1 2>&1
make install >> ${PLOGS}/util-linux_make.1 2>&1
coresrc_clean util-linux
#MAKEFLAGS=${MAKEFLAGS_DFLT}

#Xz
coresrc_prep xz
echo "[Xz] Configuring..."
./configure --prefix=${PTLS} > ${PLOGS}/xz_configure.1 2>&1

echo "[Xz] Building..."
make > ${PLOGS}/xz_make.1 2>&1
#make check >> ${PLOGS}/xz_make.1 2>&1
make install >> ${PLOGS}/xz_make.1 2>&1
coresrc_clean xz

PATH=${PATH_LOC}

# Stripping bootstrap env
# strip throws a non-0 because some /usr/bin's are actually bash scripts, etc.
set +e
strip --strip-debug ${PTLS}/lib/* > /dev/null 2>&1
/usr/bin/strip --strip-unneeded ${PTLS}/{,s}bin/* > /dev/null 2>&1
set -e
rm -rf ${PTLS}/{,share}/{info,man,doc}

# CHOWNing Bootstrap
sudo chown -R root:root ${PTLS}


############################################
# PREPPING CHROOT                          #
############################################

#dis some bullshit. sudo apparently may want env vars back. the script has none, essentially.
#env > ${PLOGS}/env_vars.pre_restore
#eval ${env_vars}
## and if that don't work...
#while read line;
#do
#	eval ${line}
#done < ${PLOGS}/env_vars.pre_clear
#env > ${PLOGS}/env_vars.post_restore

#Device Nodes
sudo mkdir -p ${PUR}/{dev,proc,sys,run}
sudo mknod -m 600 ${PUR}/dev/console c 5 1
sudo mknod -m 666 ${PUR}/dev/null c 1 3
# Temporary workaround? Either going with eudev or the old static way, not sure yet! Wheee putting off decisions!
# I vote for eudev, personally. It'll give us way better hardware detection/hotplugging/etc. support. -bts. Thu Jan 21 09:14:51 EST 2016
sudo mount --bind /dev ${PUR}/dev
sudo mount -t devpts devpts ${PUR}/dev/pts -o gid=5,mode=620
sudo mount -t proc proc ${PUR}/proc
sudo mount -t sysfs sysfs ${PUR}/sys
sudo mount -t tmpfs tmpfs ${PUR}/run
if [ -h ${PUR}/dev/shm ];
then
	sudo mkdir -p ${PUR}/$(readlink ${PUR}/dev/shm)
fi
# Entering chroot 
cd ${PUR}
rm -f chrootboot{,-stage2}.sh
if [ "${USER}" == 'bts' ];
then
	# used in development
	${fetch_cmd} http://10.1.1.1/pur/chrootboot.sh
	${fetch_cmd} http://10.1.1.1/pur/chrootboot-stage2.sh
else
	${fetch_cmd} https://raw.githubusercontent.com/PurLinux/Base/CURRENT/chrootboot.sh
	${fetch_cmd} https://raw.githubusercontent.com/PurLinux/Base/CURRENT/chrootboot-stage2.sh
fi
chmod +x chrootboot.sh
chmod +x chrootboot-stage2.sh
echo "ENTERING CHROOT"
sudo chroot "${PUR}" ${PTLS}/bin/env -i      			\
		HOME=/root					\
		TERM="${TERM}"					\
		PS1='\u:\w (chroot) \$ '			\
		PS4="${PS4}"					\
		PATH=/bin:/usr/bin:/sbin:/usr/sbin:${PTLS}/bin	\
		GCCVER=${GCCVER}				\
		VIMVER=${VIMVER}				\
		MAKEFLAGS="${MAKEFLAGS}"			\
		${PTLS}/bin/bash +h /chrootboot.sh

touch ${PUR}/chrootboot1.success

#sudo chroot "${PUR}" ${PTLS}/bin/env -i HOME=/root TERM=$TERM	\
#		PS1='\u:\w\$ '					\
#		PATH=/bin:/usr/bin:/sbin:/usr/sbin		\
#		${PTLS}/bin/find /{,usr/}{bin,lib,sbin} -type f	\
#		-exec ${PTLS}/bin/strip --strip-debug '{}' ';'

#touch ${PUR}/chrootboot2.success
set +e
sudo find ${PTLS}/{,usr}/{bin,lib,sbin} -type f -exec strip --strib-debug '{}' \; > /dev/null 2>&1
set -e

sudo chroot "${PUR}" ${PTLS}/bin/env -i      			\
		HOME=/root					\
		TERM="${TERM}"					\
		PS1='\u:\w (chroot) \$ '			\
		PS4="${PS4}"					\
		PATH=/bin:/usr/bin:/sbin:/usr/sbin		\
		GCCVER=${GCCVER}				\
		VIMVER=${VIMVER}				\
		MAKEFLAGS="${MAKEFLAGS}"			\
		${PTLS}/bin/bash +h /chrootboot-stage2.sh

touch ${PUR}/chrootboot3.success

sudo umount -l ${PUR}/{run,sys,proc,dev} > /dev/null 2>&1

rm -f ${PSRC}/pur_src.${PUR_RLS}${RLS_MOD}.tar.xz{,.sha256}
