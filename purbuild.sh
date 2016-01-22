#!/bin/bash
set -e
## For moar debugging, you can add set -x below this line and in your shell, before you run the script, run
## 	export PS4='Line ${LINENO}: '
## That prints the line number of the current command (and with set -x, the actual command) for the script
## being run.-bts,Tue Jan 19 07:29:38 EST 2016
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
Pür Linux Version $Year.$Month-RELEASE

You should have received a License file, if you cloned from Github.
If not, please see https://github.com/RainbowHackz/Pur-Linux/blob/master/LICENSE
This script is released under a Simplified 2-Clause BSD license. Support 
truely Free software, and use a BSD license for your projects. 
GPL restrictions just make it Open, not Free.

LFS was originally used for reference, and to bootstrap the project.
FreeBSD inspired this project.
PkgSrc from NetBSD is used as the primary package management utility.
Instead of donating to Pür, go donate to LFS, the FreeBSD project, or NetBSD.
We're a small project, and currently have enough resources to do the needful.
Your money is better spent with the aforementioned projects.

This is the first half of the Pür Linux build process, which occurrs within 
the host environment. At the end, another script is called, and run within a chroot.

EOT
}

purlogo

#Deps list:
# GCC
# G++
# GNU Make
# libgmp-dev, libmpfr-dev and libmpc-dev
# gawk
# GNU 'bison' 2.7 or later
# patch
# wget or curl

#Uncomment the following Line for Debian 8
# apt-get install gcc g++ make libgmp-dev libmpfr-dev libmpc-dev gawk bison patch sudo texinfo file flex xz-utils

#Important: Key Verification of packages is being implemented in an automated method,
# where this script will fail and print to your screen if a key fails. It requires GPG to be installed
# and may not be implemented for every package yet.

# Build tests are commented out in some places. Automated Stopping upon critical errors will be added in a future version of this script

# Check to make sure sh is a link to bash
if [ "$(sha256sum $(which sh) | awk '{print $1}')" \
!= "$(sha256sum $(which bash) | awk '{print $1}')" ]
then
	echo " /!\ /!\ /!\ WARNING WARNING WARNING /!\ /!\ /!\ /!\ "
        echo " Your $(which sh) is NOT linked to $(which bash)!!   "
	echo " Please fix this (i.e. via: ln -sf $(which bash) $(which sh)"
        echo "/!\ /!\ /!\ WARNING WARNING WARNING /!\ /!\ /!\ /!\ "
        exit 1
fi

if whoami | grep -q "root"; then
        echo " /!\ /!\ /!\ WARNING WARNING WARNING /!\ /!\ /!\ /!\ "
        echo " Don't run me as root. Create a new user!!      "
        echo "/!\ /!\ /!\ WARNING WARNING WARNING /!\ /!\ /!\ /!\ "
        exit 1
fi

echo

# Are we using curl or wget?
if ! type curl > /dev/null 2>&1; then
        fetch_cmd="$(which wget) -cq --tries=5 --waitretry 3 -a /tmp/fetch.log"
else
        fetch_cmd="$(which curl) -LOsSf --retry 5 --retry-delay 3 -C -"
fi


# Setting up ENV
echo "Setting up the environment and cleaning results from previous runs if necessary..."
env -i HOME=${HOME} TERM=${TERM} PS1='\u:\w\$ ' > /dev/null 2>&1
set +h
umask 022

echo

# Scrub/create paths
#rm -rf ${HOME}/purroot
mkdir -p ${HOME}/purroot
PUR=${HOME}/purroot
export PUR
PLOGS=${PUR}/logs
rm -rf ${PLOGS}
mkdir -p ${PLOGS}

rm -rf ${PUR}/tools
mkdir -p ${PUR}/tools
mkdir -p ${PUR}/sources
#rm -rf ${PUR}/sources
find ${PUR}/sources/. -maxdepth 1 -ignore_readdir_race -type d -exec rm -rf '{}' \; > /dev/null 2>&1
PSRC=${PUR}/sources
LC_ALL=POSIX
PUR_TGT="$(uname -m)-pur-linux-gnu"
sudo rm -rf /tools
sudo ln -s ${PUR}/tools /tools

PTLS=${PUR}/tools
export PTLS
rm -rf ${PTLS}/include
mkdir -p ${PTLS}/include
PATH=${PTLS}/bin:/usr/local/bin:/bin:/usr/bin
export LC_ALL PUR_TGT PATH PBLD
GLIBCVERS=2.22
HOSTGLIBCVERS=2.11
export GLIBCVERS HOSTGLIBCVERS

rm -rf ${HOME}/specs
mkdir -p ${HOME}/specs
sudo ln -s ${HOME}/specs /specs
# Uncomment the next line and modify as needed for multicore systems.
export MAKEFLAGS='-j 5'

#Eventually, I'll move hardcoded file locations to use variables instead
#Variables will be set below here, so it'll fetch ftp://blahblah.blah/$bash.tar.gz
#instead of hunting and replacing each line. 

#Wgetting everything. Move untarring up here at some point too.
cd ${PSRC}
echo "Fetching source tarballs (if necessary). This may take a while..."
echo "If you have curl installed, errors will display on STDERR. Otherwise if using wget, errors will be logged to /tmp/fetch.log"
${fetch_cmd} http://www.mpfr.org/mpfr-current/mpfr-3.1.3.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/binutils/binutils-2.25.tar.gz
${fetch_cmd} ftp://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz
${fetch_cmd} http://mirrors.concertpass.com/gcc/releases/gcc-5.3.0/gcc-5.3.0.tar.gz
${fetch_cmd} https://gmplib.org/download/gmp/gmp-6.1.0.tar.bz2
${fetch_cmd} https://www.busybox.net/downloads/busybox-1.24.1.tar.bz2
${fetch_cmd} https://www.kernel.org/pub/linux/kernel/v4.x/linux-4.4.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/coreutils/coreutils-8.24.tar.xz
${fetch_cmd} ftp://ftp.cwru.edu/pub/bash/bash-4.3.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/glibc/glibc-2.22.tar.gz
${fetch_cmd} http://downloads.sourceforge.net/tcl/tcl8.6.4-src.tar.gz
${fetch_cmd} http://prdownloads.sourceforge.net/expect/expect5.45.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/dejagnu/dejagnu-1.5.3.tar.gz
${fetch_cmd} http://sourceforge.net/projects/check/files/check/0.10.0/check-0.10.0.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu//ncurses/ncurses-6.0.tar.gz
${fetch_cmd} http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/diffutils/diffutils-3.3.tar.xz
${fetch_cmd} ftp://ftp.astron.com/pub/file/file-5.25.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/findutils/findutils-4.6.0.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/gawk/gawk-4.1.3.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/gettext/gettext-latest.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/grep/grep-2.22.tar.xz
${fetch_cmd} http://ftp.gnu.org/gnu/gzip/gzip-1.6.tar.xz
${fetch_cmd} http://ftp.gnu.org/gnu/m4/m4-latest.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/make/make-4.1.tar.gz
${fetch_cmd} http://www.cpan.org/src/5.0/perl-5.22.1.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/patch/patch-2.7.5.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/sed/sed-4.2.2.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/tar/tar-latest.tar.gz
${fetch_cmd} http://ftp.gnu.org/gnu/texinfo/texinfo-6.0.tar.gz
${fetch_cmd} https://www.kernel.org/pub/linux/utils/util-linux/v2.27/util-linux-2.27.1.tar.gz
${fetch_cmd} http://tukaani.org/xz/xz-5.2.2.tar.gz
${fetch_cmd} http://fishshell.com/files/2.2.0/fish-2.2.0.tar.gz
${fetch_cmd} ftp://ftp.astron.com/pub/tcsh/tcsh-6.19.00.tar.gz

echo

############################################
# BUILDING BOOTSTRAP ENVIRONMENT IN /TOOLS #
############################################

#binutils first build
echo "Binutils - first pass."
mkdir -v /tools/lib
case $(uname -m) in
  x86_64) ln -sv /tools/lib /tools/lib64 ;;
esac
cd ${PSRC}
tar xfz binutils-2.25.tar.gz
cd binutils-2.25
echo "[Binutils] Configuring..."
./configure --prefix=/tools     \
    --with-sysroot=$PUR                 \
    --with-lib-path=/tools/lib  \
    --target=$PUR_TGT                   \
    --disable-nls                               \
    --disable-werror > ${PLOGS}/binutils_configure.1 2>&1

echo "[Binutils] Building..."
make > ${PLOGS}/binutils_make.1 2>&1
make install >> ${PLOGS}/binutils_make.1 2>&1

## building GCC first run.
echo "GCC - first pass."
#GCC DEPS
# May want to consider this in the future, just for keeping compat with GCC's suggested practices:
# Using  ./contrib/download_prerequisites instead of manually grabbing

# building MPFR
echo "[GCC] MPFR"
cd ${PSRC}
tar xfz gcc-5.3.0.tar.gz
cd gcc-5.3.0
tar xfz ../mpfr-3.1.3.tar.gz
mv -v mpfr-3.1.3 mpfr

# MPC
echo "[GCC] MPC"
tar xfz ../mpc-1.0.3.tar.gz
mv -v mpc-1.0.3 mpc

#GMP
echo "[GCC] GMP"
tar xfj ../gmp-6.1.0.tar.bz2
mv -v gmp-6.1.0 gmp

#GCC TIME BABY OH YEAH
echo "[GCC] Configuring..."
for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv ${file}{,.orig}
  sed -re 's@/lib(64)?(32)?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' ${file}.orig > ${file}
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> ${file}
  touch ${file}.orig
done
mkdir -v ../gcc-build
cd ../gcc-build
${PWD}/../gcc-5.3.0/configure                                                \
    --target=$PUR_TGT                              \
    --prefix=/tools                                \
    --with-glibc-version=$HOSTGLIBCVERS            \
    --with-sysroot=$PUR                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++ > ${PLOGS}/gcc_configure.1 2>&1

echo "[GCC] Building..."
make > ${PLOGS}/gcc_make.1 2>&1
make install >> ${PLOGS}/gcc_make.1 2>&1

## Grabbing latest kernel headers
echo "[Kernel] Making and installing headers..."
cd ${PSRC}
tar xfz linux-4.4.tar.gz
cd linux-4.4
make mrproper > ${PLOGS}/kernel-headers_make.1 2>&1
make INSTALL_HDR_PATH=dest headers_install >> ${PLOGS}/kernel-headers_make.1 2>&1
cp -rv dest/include/* /tools/include

# Building glibc - first pass
echo "GlibC - first pass."
cd ${PSRC}
tar xfz glibc-${GLIBCVERS}.tar.gz
mkdir ${PSRC}/glibc-build
cd glibc-build
echo "[GlibC] Configuring..."
../glibc-2.22/configure                                   \
      --prefix=/tools                                     \
      --host=$PUR_TGT                                     \
      --build=$(../glibc-$GLIBCVERS/scripts/config.guess) \
      --disable-profile                                   \
      --enable-kernel=2.6.32                              \
      --enable-obsolete-rpc                               \
      --with-headers=/tools/include                       \
      --with-pkgversion='Pür Linux glibc 2.22'            \
      libc_cv_forced_unwind=yes                           \
      libc_cv_ctors_header=yes                            \
      libc_cv_c_cleanup=yes > ${PLOGS}/glibc_configure.1 2>&1

echo "[GlibC] Building..."
make > ${PLOGS}/glibc_make.1 2>&1
make install >> ${PLOGS}/glibc_make.1 2>&1

# Testing!
echo -n "Runnning tests before continuing... "
echo 'int main(){}' > dummy.c
${PUR_TGT}-gcc dummy.c
if readelf -l a.out | grep ': /tools' \
| grep -q ld-linux-x86-64.so.2;
then
	echo "Test passed."
	rm -v dummy.c a.out
else
	echo "Test Failed. Now Exiting, post glibc build."
	rm -v dummy.c a.out
	exit 1
fi

#libstc++
echo "LibstdC++ - first pass."
cd $PSRC/gcc-build
echo "[LibstdC++] Configuring..."
../gcc-5.3.0/libstdc++-v3/configure \
    --host=$PUR_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/${PUR_TGT}/include/c++/5.3.0 > ${PLOGS}/libstdc++_configure.1 2>&1

echo "[LibstdC++] Building..."
make > ${PLOGS}/libstdc++_make.1 2>&1
make install >> ${PLOGS}/libstdc++_make.1 2>&1


##############################
# BUILDING TOOLKIT IN /TOOLS #
##############################

# binutils pass 2
echo "Binutils - second pass."
mkdir -pv ${PSRC}/binutils-build
echo "[Binutils] Cleaning from first pass..."
#cd ${PSRC}/binutils-2.25
#make distclean > ${PLOGS}/binutils_pre-clean.2 2>&1 ## fuck this shit. keeps throwing an error. let's just start from scratch.
rm -rf ${PSRC}/binutils-2.25
cd ${PSRC}
tar xfz binutils-2.25.tar.gz
cd binutils-2.25
cd ${PSRC}/binutils-build
echo "[Binutils] Configuring..."
CC=${PUR_TGT}-gcc                \
AR=${PUR_TGT}-ar                 \
RANLIB=${PUR_TGT}-ranlib         \
../binutils-2.25/configure     \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot > ${PLOGS}/binutils_configure.2 2>&1

echo "[Binutils] Building..."
make > ${PLOGS}/binutils_make.2 2>&1
make install >> ${PLOGS}/binutils_make.2 2>&1
#fiddly bits
make -C ld clean > ${PLOGS}/binutils_post-tweaks.2 2>&1
make -C ld LIB_PATH=/usr/lib:/lib >> ${PLOGS}/binutils_post-tweaks.2 2>&1
cp -v ld/ld-new /tools/bin

# GCC round 2
echo "GCC - second pass."
cd ${PUR}/tools/lib
cat gcc/${PUR_TGT}/5.3.0/plugin/include/limitx.h\
 gcc/${PUR_TGT}/5.3.0/plugin/include/glimits.h\
 gcc/${PUR_TGT}/5.3.0/plugin/include/limity.h > \
  $(dirname $(${PUR_TGT}-gcc -print-libgcc-file-name))/include-fixed/limits.h
for file in \
 $(find gcc/${PUR_TGT}/5.3.0/plugin/include/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv ${file}{,.orig}
  sed -re 's@/lib(64)?(32)?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' ${file}.orig > ${file}
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch ${file}.orig
done
cd ${PSRC}/gcc-build
make distclean > ${PLOGS}/gcc_pre-clean.2 2>&1
cd ${PSRC}/gcc-5.3.0
echo "[GCC] MPFR"
tar xfz ../mpfr-3.1.3.tar.gz
mv -v mpfr-3.1.3 mpfr
# MPC
echo "[GCC] MPC"
tar xfz ../mpc-1.0.3.tar.gz
mv -v mpc-1.0.3 mpc
#GMP
echo "[GCC] GMP"
tar xfj ../gmp-6.1.0.tar.bz2
mv -v gmp-6.1.0 gmp
mkdir -pv ../gcc-build
cd ../gcc-build
find ./ -name 'config.cache' -exec rm -rf '{}' \;
echo "[GCC] Configuring..."
CC=$PUR_TGT-gcc                                    \
CXX=$PUR_TGT-g++                                   \
AR=$PUR_TGT-ar                                     \
RANLIB=$PUR_TGT-ranlib                             \
../gcc-5.3.0/configure                             \
    --prefix=/tools                                \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --enable-languages=c,c++                       \
    --disable-libstdcxx-pch                        \
    --disable-multilib                             \
    --disable-bootstrap                            \
    --disable-libgomp > ${PLOGS}/gcc_configure.2 2>&1

echo "[GCC] Building..."
make > ${PLOGS}/gcc_make.2 2>&1
make install >> ${PLOGS}/gcc_make.2 2>&1
ln -sv gcc /tools/bin/cc

#testing again
echo -n "Runnning tests before continuing... "
echo 'int main(){}' > dummy.c
$PUR_TGT-gcc dummy.c
if readelf -l a.out | grep ': /tools' \
| grep -q ld-linux;
then
	echo "Test passed."
	rm -v dummy.c a.out
else
	echo "Test Failed. Now Exiting, post GCC Round 2 build"
        rm -v dummy.c a.out
        exit 1
fi


## Tests
echo "Running further tests..."
# TCL
cd ${PSRC}
tar xfz tcl8.6.4-src.tar.gz
cd tcl8.6.4
cd unix
echo "[TCL] Configuring..."
./configure --prefix=/tools > ${PLOGS}/tcl_configure.1 2>&1
echo "[TCL] Building..."
make > ${PLOGS}/tcl_make.1 2>&1
TZ=UTC make test >> ${PLOGS}/tcl_test.1 2>&1
make install >> ${PLOGS}/tcl_test.1 2>&1
chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers >> ${PLOGS}/tcl_test.1 2>&1
ln -sv tclsh8.6 /tools/bin/tclsh

#Expect
cd ${PSRC}
tar xfz expect5.45.tar.gz
cd expect5.45
cp -v configure{,.orig}
echo "[Expect] Configuring..."
sed -e 's:/usr/local/bin:/bin:' configure.orig > configure
./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include > ${PLOGS}/expect_configure.1 2>&1

echo "[Expect] Building..."
make > ${PLOGS}/expect_make.1 2>&1
make tests >> ${PLOGS}/expect_make.1 2>&1
make SCRIPTS="" install >> ${PLOGS}/expect_make.1 2>&1

#DejaGNU
cd ${PSRC}
tar xfz dejagnu-1.5.3.tar.gz
cd dejagnu-1.5.3
echo "[DejaGNU] Configuring..."
./configure --prefix=/tools > ${PLOGS}/dejagnu_configure.1 2>&1

echo "[DejaGNU] Building..."
make install > ${PLOGS}/dejagnu_make.1 2>&1
make check >> ${PLOGS}/dejagnu_make.1 2>&1

#check
cd ${PSRC}
tar xfz check-0.10.0.tar.gz
cd check-0.10.0
echo "[Check] Configuring..."
PKG_CONFIG='' ./configure --prefix=/tools > ${PLOGS}/check_configure.1 2>&1

echo "[Check] Building..."
make > ${PLOGS}/check_make.1 2>&1
make check >> ${PLOGS}/check_make.1 2>&1
make install >> ${PLOGS}/check_make.1 2>&1

#ncurses
cd ${PSRC}
tar xfz ncurses-6.0.tar.gz
cd ncurses-6.0
echo "[nCurses] Configuring..."
sed -i -e 's/mawk//' configure
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite > ${PLOGS}/ncurses_configure.1 2>&1

echo "[nCurses] Building..."
make > ${PLOGS}/ncurses_make.1 2>&1
make install >> ${PLOGS}/ncurses_make.1 2>&1

#bash
cd ${PSRC}
tar xfz bash-4.3.tar.gz
cd bash-4.3
echo "[Bash] Configuring..."
./configure --prefix=/tools --without-bash-malloc > ${PLOGS}/bash_configure.1 2>&1

echo "[Bash] Building..."
make > ${PLOGS}/bash_make.1 2>&1
# make tests >> ${PLOGS}/bash_make.1 2>&1
make install >> ${PLOGS}/bash_make.1 2>&1
ln -sv bash /tools/bin/sh

#Bzip2
cd ${PSRC}
tar xfz bzip2-1.0.6.tar.gz
cd bzip2-1.0.6
echo "[Bzip2] Building..."
make > ${PLOGS}/bzip2_make.1 2>&1
make PREFIX=/tools install >> ${PLOGS}/bzip2_make.1 2>&1

#Coreutils
cd ${PSRC}
tar xfJ coreutils-8.24.tar.xz
cd coreutils-8.24
echo "[Coreutils] Configuring..."
./configure --prefix=/tools --enable-install-program=hostname > ${PLOGS}/coreutils_configure.1 2>&1

echo "[Coreutils] Building..."
make > ${PLOGS}/coreutils_make.1 2>&1
# make RUN_EXPENSIVE_TESTS=yes check >> ${PLOGS}/coreutils_make.1 2>&1
make install >> ${PLOGS}/coreutils_make.1 2>&1

#Diffutils
cd ${PSRC}
tar xfJ diffutils-3.3.tar.xz
cd diffutils-3.3
echo "[Diffutils] Configuring..."
./configure --prefix=/tools > ${PLOGS}/diffutils_configure.1 2>&1

echo "[Diffutils] Building..."
make > ${PLOGS}/diffutils_make.1 2>&1
make check >> ${PLOGS}/diffutils_make.1 2>&1
make install >> ${PLOGS}/diffutils_make.1 2>&1

# File
cd ${PSRC}
tar xfz file-5.25.tar.gz
cd file-5.25
echo "[File] Configuring..."
./configure --prefix=/tools > ${PLOGS}/file_configure.1 2>&1

echo "[File] Building..."
make > ${PLOGS}/file_make.1 2>&1
make check >> ${PLOGS}/file_make.1 2>&1
make install >> ${PLOGS}/file_make.1 2>&1

# Findutils
cd ${PSRC}
tar xfz findutils-4.6.0.tar.gz
cd findutils-4.6.0
echo "[Findutils] Configuring..."
./configure --prefix=/tools > ${PLOGS}/findutils_configure.1 2>&1

echo "[Findutils] Building..."
make > ${PLOGS}/findutils_makee.1 2>&1
make check >> ${PLOGS}/findutils_makee.1 2>&1
make install >> ${PLOGS}/findutils_makee.1 2>&1

# GAWK
cd ${PSRC}
tar xfz gawk-4.1.3.tar.gz
cd gawk-4.1.3
echo "[Gawk] Configuring..."
./configure --prefix=/tools > ${PLOGS}/gawk_configure.1 2>&1

echo "[Gawk] Building..."
make > ${PLOGS}/gawk_make.1 2>&1
make check >> ${PLOGS}/gawk_make.1 2>&1
make install >> ${PLOGS}/gawk_make.1 2>&1

#gettext
cd ${PSRC}
tar xfz gettext-latest.tar.gz
cd gettext-*
cd gettext-tools
echo "[Gettext] Configuring..."
EMACS="no" ./configure --prefix=/tools --disable-shared > ${PLOGS}/gettext_configure.1 2>&1

echo "[Gettext] Building..."
make -C gnulib-lib > ${PLOGS}/gettext_make.1 2>&1
make -C intl pluralx.c >> ${PLOGS}/gettext_make.1 2>&1
make -C src msgfmt >> ${PLOGS}/gettext_make.1 2>&1
make -C src msgmerge >> ${PLOGS}/gettext_make.1 2>&1
make -C src xgettext >> ${PLOGS}/gettext_make.1 2>&1
cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin

# GNU Grep
cd ${PSRC}
tar xfJ grep-2.22.tar.xz
cd grep-2.22
echo "[Grep] Configuring..."
./configure --prefix=/tools > ${PLOGS}/grep_configure.1 2>&1

echo "[Grep] Building..."
make > ${PLOGS}/grep_make.1 2>&1
make check >> ${PLOGS}/grep_make.1 2>&1
make install >> ${PLOGS}/grep_make.1 2>&1

# GNU GZip
cd ${PSRC}
tar xfJ gzip-1.6.tar.xz
cd gzip-1.6
echo "[Gzip] Configuring..."
./configure --prefix=/tools > ${PLOGS}/gzip_configure.1 2>&1

echo "[Gzip] Building..."
make > ${PLOGS}/gzip_make.1 2>&1
make check >> ${PLOGS}/gzip_make.1 2>&1
make install >> ${PLOGS}/gzip_make.1 2>&1

# M4
cd ${PSRC}
tar xfz m4-latest.tar.gz
cd m4-*
echo "[M4] Configuring..."
./configure --prefix=/tools > ${PLOGS}/m4_configure.1 2>&1

echo "[M4] Building..."
make > ${PLOGS}/m4_make.1 2>&1
make check >> ${PLOGS}/m4_make.1 2>&1
make install >> ${PLOGS}/m4_make.1 2>&1

# GNU Make
cd ${PSRC}
tar xfz make-4.1.tar.gz
cd make-4.1
echo "[Make] Configuring..."
./configure --prefix=/tools --without-guile > ${PLOGS}/make_configure.1 2>&1

echo "[Make] Building..."
make > ${PLOGS}/make_make.1 2>&1
make check >> ${PLOGS}/make_make.1 2>&1
make install >> ${PLOGS}/make_make.1 2>&1

#GNU Patch
cd ${PSRC}
tar xfz patch-2.7.5.tar.gz
cd patch-2.7.5
echo "[Patch] Configuring..."
./configure --prefix=/tools > ${PLOGS}/patch_configure.1 2>&1

echo "[Patch] Building..."
make > ${PLOGS}/patch_make.1 2>&1
make check >> ${PLOGS}/patch_make.1 2>&1
make install >> ${PLOGS}/patch_make.1 2>&1

# Perl (Will be removed from Base eventually)
cd ${PSRC}
tar xfz perl-5.22.1.tar.gz
cd perl-5.22.1
echo "[Perl] Configuring..."
sh Configure -des -Dprefix=/tools -Dlibs=-lm > ${PLOGS}/perl_configure.1 2>&1

echo "[Perl] Building..."
make > ${PLOGS}/perl_make.1 2>&1
cp -v perl cpan/podlators/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.22.0
cp -Rv lib/* /tools/lib/perl5/5.22.0

#GNU Sed
cd ${PSRC}
tar xfz sed-4.2.2.tar.gz
cd sed-4.2.2
echo "[Sed] Configuring..."
./configure --prefix=/tools > ${PLOGS}/sed_configure.1 2>&1

echo "[Sed] Building..."
make > ${PLOGS}/sed_make.1 2>&1
make check >> ${PLOGS}/sed_make.1 2>&1
make install >> ${PLOGS}/sed_make.1 2>&1

#GNU Tar
cd ${PSRC}
tar xfz tar-latest.tar.gz
cd tar-*
echo "[Tar] Configuring..."
./configure --prefix=/tools > ${PLOGS}/tar_configure.1 2>&1

echo "[Tar] Building..."
make > ${PLOGS}/tar_make.1 2>&1
make check >> ${PLOGS}/tar_make.1 2>&1
make install >> ${PLOGS}/tar_make.1 2>&1

#GNU Texinfo
cd ${PSRC}
tar xfz texinfo-6.0.tar.gz
cd texinfo-6.0
echo "[Texinfo] Configuring..."
./configure --prefix=/tools > ${PLOGS}/texinfo_configure.1 2>&1

echo "[Texinfo] Building..."
make > ${PLOGS}/texinfo_make.1 2>&1
make check >> ${PLOGS}/texinfo_make.1 2>&1
make install >> ${PLOGS}/texinfo_make.1 2>&1

# Util-Linux
cd ${PSRC}
tar xfz util-linux-2.27.1.tar.gz
cd util-linux-2.27.1
echo "[Util-Linux] Configuring..."
./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            PKG_CONFIG="" > ${PLOGS}/util-linux_configure.1 2>&1

echo "[Util-Linux] Building..."
make > ${PLOGS}/util-linux_make.1 2>&1
make install >> ${PLOGS}/util-linux_make.1 2>&1

#Xz
cd ${PSRC}
tar xfz xz-5.2.2.tar.gz
cd xz-5.2.2
echo "[Xz] Configuring..."
./configure --prefix=/tools > ${PLOGS}/xz_configure.1 2>&1

echo "[Xz] Building..."
make > ${PLOGS}/xz_make.1 2>&1
make check >> ${PLOGS}/xz_make.1 2>&1
make install >> ${PLOGS}/xz_make.1 2>&1


# Stripping bootstrap env
strip --strip-debug /tools/lib/*
/usr/bin/strip --strip-unneeded /tools/{,s}bin/*
rm -rf /tools/{,share}/{info,man,doc}

# CHOWNing Bootstrap
sudo chown -R root:root ${PUR}/tools


############################################
# PREPPING CHROOT                          #
############################################

#Device Nodes
sudo mkdir -pv ${PUR}/{dev,proc,sys,run}
sudo mknod -m 600 ${PUR}/dev/console c 5 1
sudo mknod -m 666 ${PUR}/dev/null c 1 3
# Temporary workaround? Either going with eudev or the old static way, not sure yet! Wheee putting off decisions!
# I vote for eudev, personally. It'll give us way better hardware detection/hotplugging/etc. support. -bts. Thu Jan 21 09:14:51 EST 2016
sudo mount -v --bind /dev ${PUR}/dev
sudo mount -vt devpts devpts ${PUR}/dev/pts -o gid=5,mode=620
sudo mount -vt proc proc ${PUR}/proc
sudo mount -vt sysfs sysfs ${PUR}/sys
sudo mount -vt tmpfs tmpfs ${PUR}/run
if [ -h ${PUR}/dev/shm ];
then
	sudo mkdir -pv ${PUR}/$(readlink ${PUR}/dev/shm)
fi
# Entering chroot 
cd ${PUR}
${fetch_cmd} https://raw.githubusercontent.com/RainbowHackz/Pur-Linux/master/chrootboot.sh
chmod +x chrootboot.sh
echo "ENTERING CHROOT"
chroot ./ /chrootboot.sh
