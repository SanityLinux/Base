#!/bin/bash
set -e
## for moar debugging, you can add set -x below this line and in your shell, before you run the script, run "export PS4='Line ${LINENO}: '"- that'll print the line number of the current command (and with set -x, the actual command)
## for the script being run.-bts,Tue Jan 19 07:29:38 EST 2016
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

# If Debian, please rm /bin/sh and ln -s /bin/bash /bin/sh

#Uncomment the following Line for Debian 8
# apt-get install gcc g++ make libgmp-dev libmpfr-dev libmpc-dev gawk bison patch sudo texinfo file flex xz-utils

#Important: Key Verification of packages is being implemented in an automated method,
# where this script will fail and print to your screen if a key fails. It requires GPG to be installed
# and may not be implemented for every package yet.

# Build tests are commented out in some places. Automated Stopping upon critical errors will be added in a future version of this script



if whoami | grep -q "root"; then
	echo " /!\ /!\ /!\ WARNING WARNING WARNING /!\ /!\ /!\ /!\ "
	echo " Don't run me as root. Create a new user!!      "
	echo "/!\ /!\ /!\ WARNING WARNING WARNING /!\ /!\ /!\ /!\ "
	exit 1
fi

if ! type curl > /dev/null 2>&1; then
	fetch_cmd="$(which wget)"
else
	fetch_cmd="$(which curl) -LO"
fi

# Setting up ENV
env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ '
set +h
umask 022
rm -rf $HOME/purroot ; mkdir -p $HOME/purroot
PUR=$HOME/purroot
export PUR
rm -rf $PUR/tools ; mkdir -p $PUR/tools
rm -rf $PUR/sources ; mkdir -p $PUR/sources
PSRC=$PUR/sources
LC_ALL=POSIX
PUR_TGT=$(uname -m)-pur-linux-gnu
sudo rm -rf /tools
sudo ln -s $PUR/tools /tools
PTLS=$PUR/tools
export PTLS
rm -rf $PTLS/include ; mkdir -p $PTLS/include
PATH=$PTLS/bin:/usr/local/bin:/bin:/usr/bin
export LC_ALL PUR_TGT PATH PBLD
GLIBCVERS=2.22
HOSTGLIBCVERS=2.11
export GLIBCVERS HOSTGLIBCVERS
rm -rf $HOME/specs ; mkdir -p $HOME/specs
sudo ln -s $HOME/specs /specs
# Uncomment the next line and modify as needed for multicore systems.
# export MAKEFLAGS='-j 2'

#Eventually, I'll move hardcoded file locations to use variables instead
#Variables will be set below here, so it'll fetch ftp://blahblah.blah/$bash.tar.gz
#instead of hunting and replacing each line. 

#Wgetting everything. Move untarring up here at some point too.
cd $PSRC
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
# ${fetch_cmd} http://fishshell.com/files/2.2.0/fish-2.2.0.tar.gz
# ${fetch_cmd} ftp://ftp.astron.com/pub/tcsh/tcsh-6.19.00.tar.gz
# Can't seem to grab ksh93 tarball right now.

############################################
# BUILDING BOOTSTRAP ENVIRONMENT IN /TOOLS #
############################################

#binutils first build
mkdir -v /tools/lib
case $(uname -m) in
  x86_64) ln -sv /tools/lib /tools/lib64 ;;
esac
cd $PSRC
tar xvfz binutils-2.25.tar.gz
cd binutils-2.25
./configure --prefix=/tools 	\
    --with-sysroot=$PUR 		\
    --with-lib-path=/tools/lib 	\
    --target=$PUR_TGT 			\
    --disable-nls 				\
    --disable-werror

make
make install

# building GCC first run.

#GCC DEPS

# May want to consider this in the future, just for keeping compat with GCC's suggested practices:
# Using  ./contrib/download_prerequisites instead of manually grabbing

# building MPFR

cd $PSRC
tar xvfz gcc-5.3.0.tar.gz
cd gcc-5.3.0
tar xvfz ../mpfr-3.1.3.tar.gz
mv -v mpfr-3.1.3 mpfr

# MPC
tar xvfz ../mpc-1.0.3.tar.gz
mv -v mpc-1.0.3 mpc

#GMP
tar xvfj ../gmp-6.1.0.tar.bz2
mv -v gmp-6.1.0 gmp

#GCC TIME BABY OH YEAH
for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done
mkdir -v ../gcc-build
cd ../gcc-build
$PWD/../gcc-5.3.0/configure						   \
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
    --enable-languages=c,c++
make
make install

# Grabbing latest kernel headers
cd $PSRC
tar xvfz linux-4.4.tar.gz
cd linux-4.4
make mrproper
make INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* /tools/include

# Building glibc
cd $PSRC
tar xvfz glibc-$GLIBCVERS.tar.gz
mkdir $PSRC/glibc-build
cd glibc-build
../glibc-2.22/configure                      		      \
      --prefix=/tools                         		      \
      --host=$PUR_TGT                             		  \
      --build=$(../glibc-$GLIBCVERS/scripts/config.guess) \
      --disable-profile                   		          \
      --enable-kernel=2.6.32           		          	  \
      --enable-obsolete-rpc            		              \
      --with-headers=/tools/include   		              \
      --with-pkgversion='Pür Linux glibc 2.22'            \
      libc_cv_forced_unwind=yes       		              \
      libc_cv_ctors_header=yes        		              \
      libc_cv_c_cleanup=yes
make
make install

# Testing!
echo 'int main(){}' > dummy.c
$PUR_TGT-gcc dummy.c
if readelf -l a.out | grep ': /tools' | grep -q ld-linux-x86-64.so.2 ;then
	echo "test passed"
	rm -v dummy.c a.out
else echo "Test Failed. Now Exiting, post glibc build"
	rm -v dummy.c a.out
	exit 1
fi

#libstc++
cd $PSRC/gcc-build
../gcc-5.3.0/libstdc++-v3/configure \
    --host=$PUR_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$PUR_TGT/include/c++/5.3.0
make
make install

# binutils pass 2
# mkdir -v $PSRC/binutils-build ## extraneous mkdir
cd $PSRC/binutils-2.25
make distclean ## Maybe I didn't read over binutils README well enough, but any reason we're adding this?
cd $PSRC/binutils-build
CC=$PUR_TGT-gcc                \
AR=$PUR_TGT-ar                 \
RANLIB=$PUR_TGT-ranlib         \
../binutils-2.25/configure     \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot
make
make install

#fiddly bits
make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin

# GCC round 2
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($PUR_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h
for file in \
 $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done
tar xvfz ../mpfr-3.1.3.tar.gz
mv -v mpfr-3.1.3 mpfr
# MPC
tar xvfz ../mpc-1.0.3.tar.gz
mv -v mpc-1.0.3 mpc
#GMP
tar xvfj ../gmp-6.1.0.tar.bz2
mv -v gmp-6.1.0 gmp
mkdir -v ../gcc-build
cd ../gcc-build
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
    --disable-libgomp
make
make install
ln -sv gcc /tools/bin/cc

#testing again
echo 'int main(){}' > dummy.c
$PUR_TGT-gcc dummy.c
if readelf -l a.out | grep ': /tools' | grep -q ld-linux ;then
	echo "test passed"
	rm -v dummy.c a.out
else echo "Test Failed. Now Exiting, post GCC Round 2 build"
	rm -v dummy.c a.out
	exit 1
fi

# Tests
# TCL
cd $PSRC
tar xvfz tcl8.6.4-src.tar.gz
cd tcl8.6.4-src
cd unix
./configure --prefix=/tools
make
TZ=UTC make test
make install
chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers
ln -sv tclsh8.6 /tools/bin/tclsh

#Expect
cd $PSRC
tar xvfz expect5.45.tar.gz
cd expect5.45
cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure
./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include
make
make tests
make SCRIPTS="" install

#DejaGNU
cd $PSRC
tar xvfz dejagnu-1.5.3.tar.gz
cd dejagnu-1.5.3
./configure --prefix=/tools
make install
make check

#check
cd $PSRC
tar xvfz check-0.10.0.tar.gz
cd check-0.10.0
PKG_CONFIG= ./configure --prefix=/tools
make
make check
make install

#ncurses
cd $PSRC
tar xvfz ncurses-6.0.tar.gz
cd ncurses-6.0
sed -i s/mawk// configure
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite
make
make install

#bash
cd $PSRC
tar xvfz bash-4.3.tar.gz
cd bash-4.3
./configure --prefix=/tools --without-bash-malloc
make
# make tests
make install
ln -sv bash /tools/bin/sh

#Bzip2
cd $PSRC
tar xvfz bzip2-1.0.6.tar.gz
cd bzip2-1.0.6
make
make PREFIX=/tools install


#Coreutils
cd $PSRC
tar xvfJ coreutils-8.24.tar.xz
cd coreutils-8.24
./configure --prefix=/tools --enable-install-program=hostname
make
# make RUN_EXPENSIVE_TESTS=yes check
make install


#Diffutils
cd $PSRC
tar xvfJ diffutils-3.3.tar.xz
cd diffutils-3.3
./configure --prefix=/tools
make
make check
make install


# File
cd $PSRC
tar xvfz file-5.25.tar.gz
cd file-5.25
./configure --prefix=/tools
make
make check
make install

# Findutils
cd $PSRC
tar xvfz findutils-4.6.0.tar.gz
cd findutils-4.6.0
./configure --prefix=/tools
make
make check
make install

# GAWK
cd $PSRC
tar xvfz gawk-4.1.3.tar.gz
cd gawk-4.1.3
./configure --prefix=/tools
make
make check
make install

#gettext
cd $PSRC
tar xvfz gettext-latest.tar.gz
cd gettext-*
cd gettext-tools
EMACS="no" ./configure --prefix=/tools --disable-shared
make -C gnulib-lib
make -C intl pluralx.c
make -C src msgfmt
make -C src msgmerge
make -C src xgettext
cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin

# GNU Grep
cd $PSRC
tar xvfJ grep-2.22.tar.xz
cd grep-2.22
./configure --prefix=/tools
make
make check
make install

# GNU GZip
cd $PSRC
tar xvfJ gzip-1.6.tar.xz
cd gzip-1.6
./configure --prefix=/tools
make
make check
make install

# M4
cd $PSRC
tar xvfz m4-latest.tar.gz
cd m4-*
./configure --prefix=/tools
make
make check
make install

# GNU Make
cd $PSRC
tar xvfz make-4.1.tar.gz
cd make-4.1
./configure --prefix=/tools --without-guile
make
make check
make install

#GNU Patch
cd $PSRC
tar xvfz patch-2.7.5.tar.gz
cd patch-2.7.5
./configure --prefix=/tools
make
make check
make install

# Perl (Will be removed from Base eventually)
cd $PSRC
tar xvfz perl-5.22.1.tar.gz
cd perl-5.22.1
sh Configure -des -Dprefix=/tools -Dlibs=-lm
make
cp -v perl cpan/podlators/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.22.0
cp -Rv lib/* /tools/lib/perl5/5.22.0

#GNU Sed
cd $PSRC
tar xvfz sed-4.2.2.tar.gz
cd sed-4.2.2
./configure --prefix=/tools
make
make check
make install

#GNU Tar
cd $PSRC
tar xvfz tar-latest.tar.gz
cd tar-*
./configure --prefix=/tools
make
make check
make install

#GNU Texinfo
cd $PSRC
tar xvfz texinfo-6.0.tar.gz
cd texinfo-6.0
./configure --prefix=/tools
make
make check
make install

# Util-Linux
cd $PSRC
tar xvfz util-linux-2.27.1.tar.gz
cd util-linux-2.27.1
./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            PKG_CONFIG=""
make
make install

#Xz
cd $PSRC
tar xvfz xz-5.2.2.tar.gz
cd xz-5.2.2
./configure --prefix=/tools
make
make check
make install

# Stripping bootstrap env
strip --strip-debug /tools/lib/*
/usr/bin/strip --strip-unneeded /tools/{,s}bin/*
rm -rf /tools/{,share}/{info,man,doc}

# CHOWNing Bootstrap
sudo chown -R root:root $PUR/tools

############################################
# PREPPING CHROOT                          #
############################################

#Device Nodes
sudo mkdir -pv $PUR/{dev,proc,sys,run}
sudo mknod -m 600 $PUR/dev/console c 5 1
sudo mknod -m 666 $PUR/dev/null c 1 3
# Temporary workaround? Either going with eudev or the old static way, not sure yet! Wheee putting off decisions!
sudo mount -v --bind /dev $PUR/dev
sudo mount -vt devpts devpts $PUR/dev/pts -o gid=5,mode=620
sudo mount -vt proc proc $PUR/proc
sudo mount -vt sysfs sysfs $PUR/sys
sudo mount -vt tmpfs tmpfs $PUR/run
if [ -h $PUR/dev/shm ]; then
  sudo mkdir -pv $PUR/$(readlink $PUR/dev/shm)
fi
# Entering chroot 
cd $PUR
${fetch_cmd} https://raw.githubusercontent.com/RainbowHackz/Pur-Linux/master/chrootboot.sh
chmod +x chrootboot.sh
echo "ENTERING CHROOT"
chroot ./ /chrootboot.sh
