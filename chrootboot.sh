#!/tools/bin/bash

env -i HOME=${HOME} TERM=${TERM} PS1='\u:\w\$ ' > /dev/null 2>&1
set +h
umask 022 
echo
set +h

set -e
if [ "${PS4}" == 'Line ${LINENO}: ' ];
then
        set -x
fi

MAKEFLAGS_LOG=${MAKEFLAGS}

PUR="/"
PSRC="/sources"
PTLS="/tools"
PCNTRB="/contrib"
export PUR PSRC PCNTRB PTLS

ulimit -n 512

# /dev will be handled by eudev. -bts 
echo "Making directory tree..."
mkdir -p /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
mkdir -p /{media/{floppy,cdrom},sbin,srv,var}
install -d -m 0750 /root
install -d -m 1777 /tmp /var/tmp
mkdir -p /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -p /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -p /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -p /usr/libexec
mkdir -p /usr/{,local/}share/man/man{1..8}

case $(uname -m) in
	x86_64) ln -sf lib /lib64
		ln -sf lib /usr/lib64
		ln -sf lib /usr/local/lib64 ;;
esac
mkdir -p /var/{log,mail,spool}
ln -sf /run /var/run
ln -sf /run/lock /var/lock
mkdir -p /var/{opt,cache,lib/{color,misc,locate},local}

ln -sf ${PTLS}/bin/{bash,cat,echo,pwd,stty} /bin
ln -sf ${PTLS}/bin/perl /usr/bin
ln -sf ${PTLS}/lib/libgcc_s.so{,.1} /usr/lib
ln -sf ${PTLS}/lib/libstdc++.so{,.6} /usr/lib
sed -e "s@${PTLS}@/usr@" ${PTLS}/lib/libstdc++.la > /usr/lib/libstdc++.la
ln -sf bash /bin/sh

ln -sf /proc/self/mounts /etc/mtab

cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
nogroup:x:99:
users:x:999:
EOF

touch /var/log/{btmp,lastlog,wtmp}
chgrp utmp /var/log/lastlog
chmod 664 /var/log/lastlog
chmod 600 /var/log/btmp

PLOGS=/var/log/pur_install
rm -rf ${PLOGS}
mkdir -p ${PLOGS}

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


# linux headers
echo "[Kernel] Cleaning sources for headers..."
coresrc_prep linux
make mrproper > ${PLOGS}/kernel-headers_clean.1 2>&1

echo "[Kernel] Building headers..."
make INSTALL_HDR_PATH=dest headers_install > ${PLOGS}/kernel-headers_make.1 2>&1
find dest/include \( -name .install -o -name ..install.cmd \) -delete > /dev/null 2>&1
cp -r dest/include/* /usr/include
coresrc_clean linux


# man pages
echo "[Man pages] Installing..."
coresrc_prep man-pages
make install > ${PLOGS}/man_make.1 2>&1
coresrc_clean man-pages


# glibc
echo "[GLibC] Configuring..."
coresrc_prep2 glibc
../configure		\
	--prefix=/usr		\
	--disable-profile	\
	--enable-kernel=2.6.32	\
	--enable-obsolete-rpc > ${PLOGS}/glibc_configure.1 2>&1

echo "[GLibC] Building..."
make > ${PLOGS}/glibc_make.1 2>&1
# the LFS handbook makes a WHOA OMG SUPAR BIG DEAL out of running the tests even though some are guaranteed to fail, so...
echo "[GLibC] Running tests..."
set +e
make check > ${PLOGS}/glibc_check.1 2>&1
set -e
touch /etc/ld.so.conf
make install >> ${PLOGS}/glibc_make.1 2>&1
cp ../nscd/nscd.conf /etc/nscd.conf
mkdir -p /var/cache/nscd
mkdir -p /usr/lib/locale
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
# this would install all locale defs...
#make localedata/install-locales >> ${PLOGS}/glibc_make.1 2>&1

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf
passwd: files
group: files
shadow: files
hosts: files dns
networks: files
protocols: files
services: files
ethers: files
rpc: files
# End /etc/nsswitch.conf
EOF
coresrc_clean glibc

# timezone data
echo "Timezone data..."
coresrc_prep tzdata
ZONEINFO=/usr/share/zoneinfo
mkdir -p ${ZONEINFO}/{posix,right}
for tz in etcetera southamerica northamerica europe africa antarctica asia australasia backward pacificnew systemv;
do
	zic -L /dev/null -d ${ZONEINFO} -y "sh yearistype.sh" ${tz}
	zic -L /dev/null -d ${ZONEINFO}/posix -y "sh yearistype.sh" ${tz}
	zic -L leapseconds -d ${ZONEINFO}/right -y "sh yearistype.sh" ${tz}
done
# And set the timezone. UNIX philosophy suggests UTC by default.
cp zone.tab zone1970.tab iso3166.tab ${ZONEINFO}
zic -d ${ZONEINFO} -p UTC
unset ZONEINFO
ln -sf /usr/share/zoneinfo/UTC /etc/localtime


# dynamic loader config
echo "Configuring the dynamic loader..."
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib
EOF
cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf
EOF
mkdir -p /etc/ld.so.conf.d


# toolchain modifications...
echo "Modifying the toolchain..."
mv ${PTLS}/bin/{ld,ld-old}
mv ${PTLS}/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
mv ${PTLS}/bin/{ld-new,ld}
ln -s ${PTLS}/bin/ld ${PTLS}/$(uname -m)-pc-linux-gnu/bin/ld
gcc -dumpspecs | sed -e "s@${PTLS}@@g" -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' > $(dirname $(gcc --print-libgcc-file-name))/specs
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep -q ': /lib'
if [ "${?}" != '0' ];
then
	echo "GCC failed! Bailing out..."
	exit 1
fi
linecnt=$(grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log | wc -l)
if [ "${linecnt}" != '3' ];
then
	echo "GCC using incorrect startfiles! Bailing out..."
	exit 1
fi

grep -B1 '^ /usr/include' dummy.log | egrep -Eq '^#include <...> search starts here:[[:space:]]*$'
if [ "${?}" != '0' ];
then
	echo "Compiler searching for wrong header files! Bailing out..."
	exit 1
fi
linecnt=$(grep 'SEARCH.*/usr/lib' dummy.log | sed -e 's|; |\n|g' | egrep -Ec '^(SEARCH_DIR\("/usr/lib"\)|SEARCH_DIR\("/lib"\))[[:space:]]*$')
if [ "${linecnt}" != '2' ];
then
	echo "Linker using incorrect search paths! Bailing out..."
	exit 1
fi
egrep -E '/lib(64|32)?/libc\.so\.6 ' dummy.log | egrep -q 'attempt to open /lib(32|64)?/libc\.so\.6 succeeded'
if [ "${?}" != '0' ];
then
	"Incorrect LibC being used! Bailing out..."
	exit 1
fi
grep found dummy.log | egrep -Eq '^found ld-linux-[ix]6?86(-64)?\.so\.2 at /lib(32|64)?/ld-linux-[xi]6?86(-64)?\.so\.2[[:space:]]*$'
if [ "${?}" != '0' ];
then
	# per LFS 7.8, p.97, "If the output does not appear [as we check for it], then something is seriously wrong." thanks!
	echo "Something is 'seriously wrong'. Bailing out..."
	exit 1
fi
rm dummy.c a.out dummy.log
coresrc_clean tzdata


# zlib
coresrc_prep zlib
echo "[Zlib] Configuring..."
./configure --prefix=/usr > ${PLOGS}/zlib_configure.1 2>&1

echo "[Zlib] Building..."
make > ${PLOGS}/zlib_make.1 2>&1
make install >> ${PLOGS}/zlib_make.1 2>&1
mv /usr/lib/libz.so.* /lib
ln -sf ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
coresrc_clean zlib

# file
coresrc_prep file
echo "[File] Configuring..."
./configure --prefix=/usr > ${PLOGS}/file_configure.1 2>&1

echo "[File] Building..."
make > ${PLOGS}/file_make.1 2>&1
make install > ${PLOGS}/file_make.1 2>&1
coresrc_clean file

# binutils
expect -c "spawn ls" | egrep -Eq '^spawn ls[[:space:]]*$'
if [ "${?}" != '0' ];
then
	echo "Your PTY allocation is failing. Bailing out..."
	exit 1
fi
coresrc_prep2 binutils
echo "[Binutils] Configuring..."
../configure --prefix=/usr		\
			--enable-shared \
			--disable-werror > ${PLOGS}/binutils_configure.1 2>&1

echo "[Binutils] Building..."
make tooldir=/usr > ${PLOGS}/binutils_make.1 2>&1
set +e
#make check > ${PLOGS}/binutils_check.1 2>&1
set -e
make tooldir=/usr install >> ${PLOGS}/binutils_make.1 2>&1
coresrc_clean binutils


# GMP
coresrc_prep gmp
echo "[GMP] Configuring..."
./configure --prefix=/usr	\
	--enable-cxx		\
	--disable-static	\
	--docdir=/usr/share/doc/gmp > ${PLOGS}/gmp_configure.1 2>&1

echo "[GMP] Building..."
make > ${PLOGS}/gmp_make.1 2>&1
# keeps failing...??
make html >> ${PLOGS}/gmp_make.1 2>&1
echo "[GMP] Running tests..."
make check > ${PLOGS}/gmp_check.1 2>&1
linecnt=$(awk '/tests passed/{total+=$2} ; END{print total}' ${PLOGS}/gmp_check.1 | wc -l)
if [ -z "${linecnt}" ];
then
	echo "GMP test failed; bailing out..."
	exit 1
fi
make install >> ${PLOGS}/gmp_make.1 2>&1
make install-html >> ${PLOGS}/gmp_make.1 2>&1
coresrc_clean gmp


# MPFR
coresrc_prep mpfr
echo "[MPFR] Configuring..."
./configure --prefix=/usr	\
	--disable-static	\
	--enable-thread-safe	\
	--docdir=/usr/share/doc/mpfr > ${PLOGS}/mpfr_configure.1 2>&1

echo "[MPFR] Building..."
make > ${PLOGS}/mpfr_make.1 2>&1
# gorram it.
make html >> ${PLOGS}/mpfr_make.1 2>&1
#make check > ${PLOGS}/mpfr_check.1 2>&1
make install >> ${PLOGS}/mpfr_make.1 2>&1
make install-html >> ${PLOGS}/mpfr_make.1 2>&1
coresrc_clean mpfr


# MPC
coresrc_prep mpc
echo "[MPC] Configuring..."
./configure --prefix=/usr	\
	--disable-static	\
	--docdir=/usr/share/doc/mpc > ${PLOGS}/mpc_configure.1 2>&1

echo "[MPC] Building..."
make > ${PLOGS}/mpc_make.1 2>&1
make html >> ${PLOGS}/mpc_make.1 2>&1
#make check > ${PLOGS}/mpc_check.1 2>&1
make install >> ${PLOGS}/mpc_make.1 2>&1
make install-html >> ${PLOGS}/mpc_make.1 2>&1
coresrc_clean mpc


# GCC
coresrc_prep2 gcc
#make distclean > ${PLOGS}/gcc_clean.1 2>&1
echo "[GCC] Configuring..."
SED=sed
../configure --prefix=/usr		\
	--enable-languages=c,c++	\
	--disable-multilib		\
	--disable-bootstrap		\
	--with-system-zlib > ${PLOGS}/gcc_configure.1 2>&1

echo "[GCC] Building..."
make > ${PLOGS}/gcc_make.1 2>&1
# gorram gcc. might not be necessary, but we're "inside" the PUR root at this point, so...
ulimit -s 32768
set +e
#make -k check > ${PLOGS}/gcc_check.1 2>&1
set -e
../contrib/test_summary >> ${PLOGS}/gcc_check.1 2>&1
make install >> ${PLOGS}/gcc_make.1 2>&1
ln -s /usr/bin/cpp /lib
ln -s gcc /usr/bin/cc
install -dm755 /usr/lib/bfd-plugins
ln -sf ../../libexec/gcc/$(gcc -dumpmachine)/${GCCVER}/liblto_plugin.so /usr/lib/bfd-plugins/
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log

echo "[GCC] Running sanity checks..."
if readelf -l a.out | grep ': /lib' | egrep -Eq '[Requesting program interpreter: /lib(64)?/ld-linux(-(x86_64|i686))?.so.2]';
then
	echo "Interpreter OK; continuing..."
else
	echo "Interpreter failed; bailing out."
	exit 1
fi

if grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log | egrep -Eq "^/usr/lib(64|32)?/(gcc/)?$(uname -m).*(lib(64|32)?/)?crt[1in]\.o\ succeeded$";
then
	echo "Startup files correct; continuing..."
else
	echo "Startup files incorrect; bailing out."
	exit 1
fi

if grep -B4 '^ /usr/include' dummy.log | egrep -Eq "/usr/(lib/gcc/$(uname -m).*/${GCCVER}/include(-fixed)?|(local/)?include)";
then
	echo "Header files correct; continuing..."
else
	echo "Header files incorrect; bailing out..."
	exit 1
fi

if grep 'SEARCH.*/usr/lib' dummy.log | sed 's|; |\n|g' | egrep -Eq '^SEARCH_DIR\("/usr/lib(64|32)?"\)';
then
	echo "Paths correct; continuing..."
else
	echo "Paths incorrect; bailing out..."
	exit 1
fi

if grep "/lib.*/libc.so.6 " dummy.log | egrep -Eq '^attempt\ to\ open\ /lib(32|64)?/libc\.so\.6\ succeeded$';
then
	echo "Correct LIBC being used; continuing..."
else
	echo "Incorrect libc being used; bailing out..."
	exit 1
fi

if grep found dummy.log | egrep -q '^found ld-linux-x86-64.so.2 at /lib64/ld-linux-x86-64.so.2$';
then
	echo "Correct dynamic linker being used; continuing..."
else
	echo "Incorrect dynamic linker being used; bailing out..."
	exit 1
fi

rm dummy.c a.out dummy.log
mkdir -p /usr/share/gdb/auto-load/usr/lib
mv /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
coresrc_clean gcc

# Bzip2
coresrc_prep bzip2
sed -i -re 's@(ln -s -f )$\(PREFIX\)/bin/@\1@' Makefile
sed -i -e "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

echo "[Bzip2] Building..."
make -f Makefile-libbz2_so > ${PLOGS}/bzip2_make.1 2>&1
make clean >> ${PLOGS}/bzip2_make.1 2>&1
make >> ${PLOGS}/bzip2_make.1 2>&1
make PREFIX=/usr install >> ${PLOGS}/bzip2_make.1 2>&1
cp bzip2-shared /bin/bzip2
cp -a libbz2.so* /lib
ln -s ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm /usr/bin/{bunzip2,bzcat,bzip2}
ln -s bzip2 /bin/bunzip2
ln -s bzip2 /bin/bzcat
coresrc_clean bzip2


# Pkg-config
coresrc_prep pkg-config
echo "[Pkg-config] Configuring..."
./configure --prefix=/usr	\
	--with-internal-glib	\
	--disable-host-tool	\
	--docdir=/usr/share/doc/pkg-config > ${PLOGS}/pkg-config_configure.1 2>&1

echo "[Pkg-config] Building..."
make > ${PLOGS}/pkg-config_make.1 2>&1
#make check > ${PLOGS}/pkg-config_check.1 2>&1
make install >> ${PLOGS}/pkg-config_make.1 2>&1
coresrc_clean pkg-config


# nCurses
coresrc_prep ncurses
echo "[nCurses] Configuring..."
sed -i -e '/LIBTOOL_INSTALL/d' c++/Makefile.in
./configure --prefix=/usr	\
	--mandir=/usr/share/man	\
	--with-shared		\
	--without-debug		\
	--without-normal	\
	--enable-pc-files	\
	--enable-widec > ${PLOGS}/ncurses_configure.1 2>&1

echo "[nCurses] Building..."
make > ${PLOGS}/ncurses_make.1 2>&1
make install >> ${PLOGS}/ncurses_make.1 2>&1
mv /usr/lib/libncursesw.so.6* /lib
ln -sf /lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
for lib in ncurses form panel menu;
do
	rm -f /usr/lib/lib${lib}.so
	echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
	ln -sf ${lib}w.pc /usr/lib/pkgconfig/${lib}.pc
done
rm -f /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sf libncurses.so /usr/lib/libcurses.so
coresrc_clean ncurses


# attr
coresrc_prep attr
echo "[Attr] Configuring..."
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
sed -i -e "/SUBDIRS/s|man[25]||g" man/Makefile
./configure --prefix=/usr	\
	--bindir=/bin		\
	--disable-static > ${PLOGS}/attr_configure.1 2>&1

echo "[Attr] Building..."
make > ${PLOGS}/attr_make.1 2>&1
# the tests will fail horribly if we aren't on an ext(2|3|4) filesystem...
set +e
make -j1 tests root-tests > ${PLOGS}/attr_check.1 2>&1
set -e
make install install-dev install-lib >> ${PLOGS}/attr_make.1 2>&1
chmod 755 /usr/lib/libattr.so
mv /usr/lib/libattr.so.* /lib
ln -sf /lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
coresrc_clean attr


# Acl
coresrc_prep acl
echo "[Acl] Configuring..."
sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
sed -i -e 's:| sed.*::g' test/{sbits-restore,cp,misc}.test
sed -i -e '/TABS-1;/a if (x > (TABS-1)) x = (TABS-1);' libacl/__acl_to_any_text.c
./configure --prefix=/usr	\
	--bindir=/bin		\
	--disable-static	\
	--libexecdir=/usr/lib > ${PLOGS}/acl_configure.1 2>&1

echo "[Acl] Building..."
make > ${PLOGS}/acl_make.1 2>&1
make install install-dev install-lib >> ${PLOGS}/acl_make.1 2>&1
chmod 755 /usr/lib/libacl.so
mv /usr/lib/libacl.so.* /lib
ln -sf /lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
coresrc_clean acl


# Libcap
coresrc_prep libcap
echo "[LibCap] Building..."
sed -i -e '/install.*STALIBNAME/d' libcap/Makefile
make > ${PLOGS}/libcap_make.1 2>&1
make RAISE_SETFCAP=no prefix=/usr install >> ${PLOGS}/libcap_make.1 2>&1
chmod 755 /usr/lib/libcap.so
mv /usr/lib/libcap.so.* /lib
ln -sf /lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so
coresrc_clean libcap


# Sed
coresrc_prep sed
echo "[Sed] Configuring..."
./configure --prefix=/usr --bindir=/bin --htmldir=/usr/share/doc/sed > ${PLOGS}/sed_configure.1 2>&1

echo "[Sed] Building..."
make > ${PLOGS}/sed_make.1 2>&1
set +e
make html >> ${PLOGS}/sed_make.1 2>&1
set -e
#make check > ${PLOGS}/sed_check.1 2>&1
make install >> ${PLOGS}/sed_make.1 2>&1
set +e
make -C doc install-html >> ${PLOGS}/sed_make.1 2>&1
set -e
coresrc_clean sed


# Shadow
coresrc_prep shadow
echo "[Shadow] Configuring..."
sed -i -e 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' -e 's@/var/spool/mail@/var/mail@' -e 's@DICTPATH.*@DICTPATH\t/lib/cracklib/pw_dict@' etc/login.defs
sed -i 's/1000/999/' etc/useradd
./configure --sysconfdir=/etc --with-group-name-max-length=32 > ${PLOGS}/shadow_configure.1 2>&1

echo "[Shadow] Building..."
make > ${PLOGS}/shadow_make.1 2>&1
make install ${PLOGS}/shadow_make.1 2>&1
mv /usr/bin/passwd /bin
pwconv >> ${PLOGS}/shadow_configure.1 2>&1
grpconv >> ${PLOGS}/shadow_configure.1 2>&1
sed -i -e 's/1000/100/g' /etc/default/useradd
passwd -e root
coresrc_clean shadow


# Psmisc
coresrc_prep psmisc
echo "[PSmisc] Configuring..."
./configure --prefix=/usr > ${PLOGS}/psmisc_configure.1 2>&1

echo "[PSmisc] Building..."
make > ${PLOGS}/psmisc_make.1 2>&1
make install >> ${PLOGS}/psmisc_make.1 2>&1
mv /usr/bin/fuser /bin
mv /usr/bin/killall /bin
coresrc_clean psmisc


# Procps-NG
coresrc_prep procps-ng
echo "[ProcPS-NG] Configuring..."
./configure --prefix=/usr				\
	--exec-prefix=					\
	--libdir=/usr/lib				\
	--docdir=/usr/share/doc/procps-ng		\
	--disable-static				\
	--disable-kill > ${PLOGS}/procps-ng_configuring.1 2>&1

echo "[ProcPS-NG] Building..."
make > ${PLOGS}/procps-ng_make.1 2>&1
sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
#make check > ${PLOGS}/procps-ng_check.1 2>&1
make install >> ${PLOGS}/procps-ng_make.1 2>&1
mv /usr/lib/libprocps.so.* /lib
ln -sf /lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
coresrc_clean procps-ng


# e2fsprogs
coresrc_prep2 e2fsprogs
echo "[E2fsprogs] Configuring..."
LIBS=-L${PTLS}/lib			\
CFLAGS=-I${PTLS}/include			\
PKG_CONFIG_PATH=${PTLS}/lib/pkgconfig	\
../configure --prefix=/usr		\
             --bindir=/bin		\
             --with-root-prefix=""	\
             --enable-elf-shlibs	\
             --disable-libblkid		\
             --disable-libuuid		\
             --disable-uuidd		\
             --disable-fsck > ${PLOGS}/e2fsprogs_configure.1 2>&1

echo "[E2fsprogs] Building..."
make > ${PLOGS}/e2fsprogs_make.1 2>&1
ln -sf ${PTLS}/lib/lib{blk,uu}id.so.1 lib
#make LD_LIBRARY_PATH=${PTLS}/lib check > ${PLOGS}/e2fsprogs_check.1 2>&1
make install >> ${PLOGS}/e2fsprogs_make.1 2>&1
make install-libs >> ${PLOGS}/e2fsprogs_make.1 2>&1
chmod u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo
install -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
coresrc_clean e2fsprogs


# IANA-etc
coresrc_prep iana-etc
echo "[IANA-Etc] Building..."
make > ${PLOGS}/iana-etc_make.1 2>&1
make install >> ${PLOGS}/iana-etc_make.1 2>&1
coresrc_clean iana-etc


# M4
coresrc_prep m4
echo "[M4] Configuring..."
./configure --prefix=/usr > ${PLOGS}/m4_configure.1 2>&1

echo "[M4] Building..."
make > ${PLOGS}/m4_make.1 2>&1
# might unnecessarily fail on the "test-update-copyright.sh" test
set +e
#make check > ${PLOGS}/m4_check.1 2>&1
set -e
make install >> ${PLOGS}/m4_make.1 2>&1
coresrc_clean m4


# Bison
coresrc_prep bison
echo "[Bison] Configuring..."
./configure --prefix=/usr --docdir=/usr/share/doc/bison > ${PLOGS}/bison_configure.1 2>&1

echo "[Bison] Building..."
make > ${PLOGS}/bison_make.1 2>&1
make install >> ${PLOGS}/bison_make.1 2>&1
coresrc_clean bison


# Flex
coresrc_prep flex
echo "[Flex] Configuring..."
./configure --prefix=/usr --docdir=/usr/share/doc/flex > ${PLOGS}/flex_configuring.1 2>&1

echo "[Flex] Building..."
make > ${PLOGS}/flex_make.1 2>&1
#make check > ${PLOGS}/flex_check.1 2>&1
make install >> ${PLOGS}/flex_make.1 2>&1
ln -s /usr/bin/flex /usr/bin/lex
coresrc_clean flex


# Grep
coresrc_prep grep
echo "[Grep] Configuring..."
./configure --prefix=/usr --bindir=/bin > ${PLOGS}/grep_configure.1 2>&1

echo "[Grep] Building..."
make > ${PLOGS}/grep_make.1 2>&1
#make check > ${PLOGS}/grep_check.1 2>&1
make install >> ${PLOGS}/grep_make.1 2>&1
coresrc_clean grep


# Readline
coresrc_prep readline
echo "[Readline] Configuring..."
sed -i -e '/MV.*old/d' Makefile.in
sed -i -e '/{OLDSUFF}/c:' support/shlib-install
./configure --prefix=/usr	\
	--disable-static	\
	--docdir=/usr/share/doc/readline > ${PLOGS}/readline_configure.1 2>&1

echo "[Readline] Building..."
make SHLIB_LIBS=-lncurses install > ${PLOGS}/readline_make.1 2>&1
mv /usr/lib/lib{readline,history}.so.* /lib
ln -sf /lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sf /lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
install -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline
coresrc_clean readline


# Bash
coresrc_prep bash
echo "[Bash] Configuring..."
./configure --prefix=/usr			\
	--docdir=/usr/share/doc/		\
	--without-bash-malloc			\
	--with-installed-readline > ${PLOGS}/bash_configure.1 2>&1

echo "[Bash] Building..."
make > ${PLOGS}/bash_make.1 2>&1
chown -R nobody .
su nobody -s /bin/bash -c "PATH=${PATH} make tests" > ${PLOGS}/bash_check.1 2>&1
make install >> ${PLOGS}/bash_make.1 2>&1
mv -f /usr/bin/bash /bin
# the following will spawn an interactive shell.
# Do we need to create a second script and bash -c that with the new bash,
# or can we continue using this bash?
#exec /bin/bash --login +h
coresrc_clean bash


# Bc
coresrc_prep bc
echo "[BC] Configuring..."
./configure --prefix=/usr	\
	--with-readline		\
	--mandir=/usr/share/man \
	--infodir=/usr/share/info > ${PLOGS}/bc_configure.1 2>&1

echo "[BC] Building..."
make > ${PLOGS}/bc_make.1 2>&1
#echo "quit" | ./bc/bc -l Test/checklib.b > ${PLOGS}/bc_check.1 2>&1
make install >> ${PLOGS}/bc_make.1 2>&1
coresrc_clean bc


# Libtool
coresrc_prep libtool
echo "[Libtool] Configuring..."
./configure --prefix=/usr > ${PLOGS}/libtool_configure.1 2>&1

echo "[Libtool] Building..."
make > ${PLOGS}/libtool_make.1 2>&1
#make check > ${PLOGS}/libtool_check.1 2>&1
make install >> ${PLOGS}/libtool_make.1 2>&1
coresrc_clean libtool


# GDBM
coresrc_prep gdbm
echo "[GDBM] Configuring..."
./configure --prefix=/usr	\
	--disable-static	\
	--enable-libgdbm-compat > ${PLOGS}/gdbm_configure.1 2>&1

make > ${PLOGS}/gdbm_make.1 2>&1
#make check > ${PLOGS}/gdbm_check.1 2>&1
make install >> ${PLOGS}/gdbm_make.1 2>&1
coresrc_clean gdbm


# Expat
coresrc_prep expat
echo "[Expat] Configuring..."
./configure --prefix=/usr --disable-static > ${PLOGS}/expat_configure.1 2>&1
echo "[Expat] Building..."
make > ${PLOGS}/expat_make.1 2>&1
#make check > ${PLOGS}/expat_check.1 2>&1
make install >> ${PLOGS}/expat_make.1 2>&1
install -dm755 /usr/share/doc/expat
install -m644 doc/*.{html,png,css} /usr/share/doc/expat
coresrc_clean expat


# INetUtils
coresrc_prep inetutils
echo "[InetUtils] Configuring..."
./configure --prefix=/usr	\
	--localstatedir=/var	\
	--disable-logger	\
	--disable-whois		\
	--disable-rcp		\
	--disable-rexec		\
	--disable-rlogin	\
	--disable-rsh		\
	--disable-servers > ${PLOGS}/inetutils_configure.1 2>&1

echo "[InetUtils] Building..."
make > ${PLOGS}/inetutils_make.1 2>&1
#make check > ${PLOGS}/inetutils_check.1 2>&1
make install >> ${PLOGS}/inetutils_make.1 2>&1
mv /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv /usr/bin/ifconfig /sbin
coresrc_clean inetutils


# Perl
coresrc_prep perl
echo "127.0.0.1 localhost localhost.localdomain" > /etc/hosts
export BUILD_ZLIB=False
export BUILD_BZIP2=0
echo "[Perl] Configuring..."
sh Configure -des -Dprefix=/usr		\
	-Dvendorprefix=/usr		\
	-Dman1dir=/usr/share/man/man1	\
	-Dman3dir=/usr/share/man/man3	\
	-Dpager="/usr/bin/less -isR"	\
	-Duseshrplib > ${PLOGS}/perl_configure.1 2>&1

echo "[Perl] Building..."
make > ${PLOGS}/perl_make.1 2>&1
#make -k test > ${PLOGS}/perl_check.1 2>&1
make install > ${PLOGS}/perl_make.1 2>&1
unset BUILD_ZLIB BUILD_BZIP2
coresrc_clean perl


# XML::Parser
coresrc_prep XML-Parser
echo "[PERL: XML::Parser] Configuring..."
perl Makefile.PL > ${PLOGS}/xml-parser_configure.1 2>&1

echo "[PERL: XML::Parser] Building..."
make > ${PLOGS}/xml-parser_make.1 2>&1
#make test > ${PLOGS}/xml-parser_check.1 2>&1
make install >> ${PLOGS}/xml-parser_make.1 2>&1
coresrc_clean XML-Parser


# Autoconf
coresrc_prep autoconf
echo "[Autoconf] Configuring..."
./configure --prefix=/usr > ${PLOGS}/autoconf_configure.1 2>&1

echo "[Autoconf] Building..."
make > ${PLOGS}/autoconf_make.1 2>&1
#make check > ${PLOGS}/autoconf_check.1 2>&1
make install >> ${PLOGS}/autoconf_make.1 2>&1
coresrc_clean autoconf


# Automake
coresrc_prep automake
echo "[Automake] Configuring..."
sed -i 's:/\\\${:/\\\$\\{:' bin/automake.in
./configure --prefix=/usr --docdir=/usr/share/doc/automake > ${PLOGS}/automake_configure.1 2>&1

echo "[Automake] Building..."
make > ${PLOGS}/automake_make.1 2>&1
sed -i "s:./configure:LEXLIB=/usr/lib/libfl.a &:" t/lex-{clean,depend}-cxx.sh
#make -j4 check > ${PLOGS}/automake_check.1 2>&1
make install >> ${PLOGS}/automake_make.1 2>&1
coresrc_clean automake


# Coreutils
coresrc_prep coreutils
echo "[Coreutils] Configuring..."
FORCE_UNSAFE_CONFIGURE=1 ./configure	\
            --prefix=/usr		\
            --enable-no-install-program=kill,uptime > ${PLOGS}/coreutils_configure.1 2>&1

echo "[Coreutils] Building..."
FORCE_UNSAFE_CONFIGURE=1 make > ${PLOGS}/coreutils_make.1 2>&1 # FUCK THA PO-LICE
make install >> ${PLOGS}/coreutils_make.1 2>&1
mv /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv /usr/bin/chroot /usr/sbin
mv /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i -e 's/\"1\"/\"8\"/1' /usr/share/man/man8/chroot.8
mv /usr/bin/{head,sleep,nice,test,\[} /bin
coresrc_clean coreutils


# Diffutils
coresrc_prep diffutils
sed -i 's:= @mkdir_p@:= /bin/mkdir -p:' po/Makefile.in.in
echo "[Diffutils] Configuring..."
./configure --prefix=/usr > ${PLOGS}/diffutils_configure.1 2>&1

echo "[Diffutils] Building..."
make > ${PLOGS}/diffutils_make.1 2>&1
#make check > ${PLOGS}/diffutils_check.1 2>&1
make install >> ${PLOGS}/diffutils_make.1 2>&1
coresrc_clean diffutils


# Gawk
coresrc_prep gawk
echo "[Gawk] Configuring..."
./configure --prefix=/usr > ${PLOGS}/gawk_configure.1 2>&1

echo "[Gawk] BUilding..."
make > ${PLOGS}/gawk_make.1 2>&1
#make check > ${PLOGS}/gawk_check.1 2>&1
make install >> ${PLOGS}/gawk_make.1 2>&1
mkdir /usr/share/doc/gawk
cp doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk
coresrc_clean gawk


# Findutils
coresrc_prep findutils
echo "[Findutils] Configuring..."
./configure --prefix=/usr --localstatedir=/var/lib/locate > ${PLOGS}/findutils_configure.1 2>&1

echo "[Findutils] Building..."
make > ${PLOGS}/findutils_make.1 2>&1
#make check > ${PLOGS}/findutils_check.1 2>&1
make install >> ${PLOGS}/findutils_make.1 2>&1
mv /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
coresrc_clean findutils


# Gettext
coresrc_prep gettext
echo "[Gettext] Configuring..."
./configure --prefix=/usr	\
	--disable-static	\
	--docdir=/usr/share/doc/gettext > ${PLOGS}/gettext_configure.1 2>&1

echo "[Gettext] Building..."
make > ${PLOGS}/gettext_make.1 2>&1
#make check > ${PLOGS}/gettext_check.1 2>&1
make install >> ${PLOGS}/gettext_make.1 2>&1
chmod 0755 /usr/lib/preloadable_libintl.so
coresrc_clean gettext


# Intltool
coresrc_prep intltool
echo "[Intltool] Configuring..."
sed -i 's:\\\${:\\\$\\{:' intltool-update.in
./configure --prefix=/usr > ${PLOGS}/intltool_configure.1 2>&1

echo "[Intltool] Building..."
make > ${PLOGS}/intltool_make.1 2>&1
#make check > ${PLOGS}/intltool_check.1 2>&1
make install >> ${PLOGS}/intltool_make.1 2>&1
install -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool/I18N-HOWTO
coresrc_clean intltool


# Gperf
coresrc_prep gperf
echo "[Gperf] Configuring..."
./configure --prefix=/usr --docdir=/usr/share/doc/gperf > ${PLOGS}/gperf_configure.1 2>&1

echo "[Gperf] Building..."
make > ${PLOGS}/gperf_make.1 2>&1
#make -j1 check > ${PLOGS}/gperf_check.1 2>&1
make install >> ${PLOGS}/gperf_make.1 2>&1
coresrc_clean gperf


# Groff
coresrc_prep groff
echo "[Groff] Configuring..."
PAGE=letter ./configure --prefix=/usr > ${PLOGS}/groff_configure.1 2>&1

echo "[Groff] Building..."
# keeps failing..
MAKEFLAGS=''
make -j 1 > ${PLOGS}/groff_make.1 2>&1
make install >> ${PLOGS}/groff_make.1 2>&1
MAKEFLAGS=${MAKEFLAGS_LOC}
coresrc_clean groff


# Xz
coresrc_prep xz
echo "[Xz] Configuring..."
sed -i -e '/mf\.buffer = NULL/a next->coder->mf.size = 0;' src/liblzma/lz/lz_encoder.c
./configure --prefix=/usr	\
	--disable-static	\
	--docdir=/usr/share/doc/xz > ${PLOGS}/xz_configure.1 2>&1

echo "[Xz] Building..."
make > ${PLOGS}/xz_make.1 2>&1
#make check > ${PLOGS}/xz_check.1 2>&1
make install >> ${PLOGS}/xz_make.1 2>&1
mv /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv /usr/lib/liblzma.so.* /lib
ln -sf /lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
coresrc_clean xz


# Grub
coresrc_prep grub
echo "[Grub] Configuring..."
./configure --prefix=/usr	\
	--sbindir=/sbin		\
	--sysconfdir=/etc	\
	--disable-grub-emu-usb	\
	--disable-efiemu	\
	--disable-werror > ${PLOGS}/grub_configure.1 2>&1

echo "[Grub] Building..."
make > ${PLOGS}/grub_make.1 2>&1
make install >> ${PLOGS}/grub_make.1 2>&1
coresrc_clean grub


# Less
coresrc_prep less
echo "[Less] Configuring..."
./configure --prefix=/usr --sysconfdir=/etc > ${PLOGS}/less_configure.1 2>&1

echo "[Less] Building..."
make > ${PLOGS}/less_make.1 2>&1
make install >> ${PLOGS}/less_make.1 2>&1
coresrc_clean less


# Gzip
coresrc_prep gzip
echo "[Gzip] Configuring..."
./configure --prefix=/usr --bindir=/bin > ${PLOGS}/gzip_configure.1 2>&1

echo "[Gzip] Building..."
make > ${PLOGS}/gzip_make.1 2>&1
#make check > ${PLOGS}/gzip_check.1 2>&1
make install >> ${PLOGS}/gzip_make.1 2>&1
mv /bin/{gzexe,uncompress,zcmp,zdiff,zegrep} /usr/bin
mv /bin/{zfgrep,zforce,zgrep,zless,zmore,znew} /usr/bin
coresrc_clean gzip


# IPRoute2
coresrc_prep iproute2
echo "[IPRoute2] Building..."
sed -i -e '/ARPD/d' Makefile
sed -i -e 's/arpd.8//' man/man8/Makefile
rm doc/arpd.sgml
make > ${PLOGS}/iproute2_make.1 2>&1
make DOCDIR=/usr/share/doc/iproute2 install >> ${PLOGS}/iproute2_make.1 2>&1
coresrc_clean iproute2


# Kbd
coresrc_prep kbd
echo "[Kbd] Configuring..."
sed -i -e 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i -e 's/resizecons.8 //' docs/man/man8/Makefile.in
PKG_CONFIG_PATH=${PTLS}/lib/pkgconfig ./configure --prefix=/usr --disable-vlock > ${PLOGS}/kbd_configure.1 2>&1

echo "[Kbd] Building..."
make > ${PLOGS}/kbd_make.1 2>&1
#make check > ${PLOGS}/kbd_check.1 2>&1
make install >> ${PLOGS}/kbd_make.1 2>&1
mkdir /usr/share/doc/kbd
cp -R docs/doc/* /usr/share/doc/kbd
coresrc_clean kbd


# Kmod
coresrc_prep kmod
echo "[Kmod] Configuring..."
./configure --prefix=/usr	\
	--bindir=/bin		\
	--sysconfdir=/etc	\
	--with-rootlibdir=/lib	\
	--with-xz		\
	--with-zlib > ${PLOGS}/kmod_configure.1 2>&1

echo "[Kmod] Building..."
make > ${PLOGS}/kmod_make.1 2>&1
make install >> ${PLOGS}/kmod_make.1 2>&1
for target in depmod insmod lsmod modinfo modprobe rmmod;
do
  ln -s /bin/kmod /sbin/${target}
done
ln -s kmod /bin/lsmod
coresrc_clean kmod


# Libpipeline
coresrc_prep libpipeline
echo "[LibPipeline] Configuring..."
PKG_CONFIG_PATH=${PTLS}/lib/pkgconfig ./configure --prefix=/usr > ${PLOGS}/libpipeline_configure.1 2>&1

echo "[LibPipeline] Building..."
make > ${PLOGS}/libpipeline_make.1 2>&1
#make check > ${PLOGS}/libpipeline_check.1 2>&1
make install >> ${PLOGS}/libpipeline_make.1 2>&1
coresrc_clean libpipeline


# Make
coresrc_prep make
echo "[Make] Configuring..."
./configure --prefix=/usr > ${PLOGS}/make_configure.1 2>&1

echo "[Make] Building..."
make > ${PLOGS}/make_make.1 2>&1
#make check > ${PLOGS}/make_check.1 2>&1
make install >> ${PLOGS}/make_make.1 2>&1
coresrc_clean make


# Patch
coresrc_prep patch
echo "[Patch] Configuring..."
./configure --prefix=/usr > ${PLOGS}/patch_configure.1 2>&1

echo "[Patch] Building..."
make > ${PLOGS}/patch_make.1 2>&1
#make check > ${PLOGS}/patch_check.1 2>&1
make install >> ${PLOGS}/patch_make.1 2>&1
coresrc_clean patch


# Sysklogd
coresrc_prep sysklogd
echo "[Sysklogd] Building..."
sed -i -e '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
make > ${PLOGS}/sysklogd_make.1 2>&1
make BINDIR=/sbin install >> ${PLOGS}/sysklogd_make.1 2>&1
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF
coresrc_clean sysklogd


# SysVInit skipped because using RC...?


# Tar
coresrc_prep tar
echo "[Tar] Configuring..."
FORCE_UNSAFE_CONFIGURE=1	\
./configure --prefix=/usr	\
	--bindir=/bin > ${PLOGS}/tar_configure.1 2>&1

echo "[Tar] Building..."
make > ${PLOGS}/tar_make.1 2>&1
#make check > ${PLOGS}/tar_check.1 2>&1
make install >> ${PLOGS}/tar_make.1 2>&1
set +e
make -C doc install-html docdir=/usr/share/doc/tar >> ${PLOGS}/tar_make.1 2>&1
set -e
coresrc_clean tar


# Texinfo
coresrc_prep texinfo
echo "[Texinfo] Configuring..."
./configure --prefix=/usr --disable-static > ${PLOGS}/texinfo_configure.1 2>&1

echo "[Texinfo] Building..."
make > ${PLOGS}/texinfo_make.1 2>&1
#make check > ${PLOGS}/texinfo_check.1 2>&1
make install >> ${PLOGS}/texinfo_make.1 2>&1
make TEXMF=/usr/share/texmf install-tex >> ${PLOGS}/texinfo_make.1 2>&1
coresrc_clean texinfo


# Eudev
coresrc_prep eudev
echo "[Eudev] Configuring..."
sed -i -re 's|/usr(/bin/test)|\1|' test/udev-test.pl
cat > config.cache << "EOF"
HAVE_BLKID=1
BLKID_LIBS="-lblkid"
BLKID_CFLAGS="-I${PTLS}/include"
EOF
# needed if building from git release tarball, but fails because xsltproc
#./autogen.sh > ${PLOGS}/eudev_configure.1 2>&1
./configure --prefix=/usr	\
	--bindir=/sbin		\
	--sbindir=/sbin		\
	--libdir=/usr/lib	\
	--sysconfdir=/etc	\
	--libexecdir=/lib	\
	--with-rootprefix=	\
	--with-rootlibdir=/lib	\
	--enable-manpages	\
	--disable-static	\
	--config-cache > ${PLOGS}/eudev_configure.1 2>&1

echo "[Eudev] Building..."
LIBRARY_PATH=${PTLS}/lib make > ${PLOGS}/eudev_make.1 2>&1
mkdir -p /lib/udev/rules.d
mkdir -p /etc/udev/rules.d
# these tests.. may fail, since we're in a chroot.
set +e
make LD_LIBRARY_PATH=${PTLS}/lib check > ${PLOGS}/eudev_check.1 2>&1
set -e
make LD_LIBRARY_PATH=${PTLS}/lib install >> ${PLOGS}/eudev_make.1 2>&1
cp -a ${PSRC}/pur_src/core/udev-lfs .
# ugh. ugly. tsk, tsk!
find udev-lfs/ -type f -exec sed -i -e 's/-$(VERSION)//g' '{}' \;
make -f udev-lfs/Makefile.lfs install >> ${PLOGS}/eudev_make.1 2>&1
LD_LIBRARY_PATH=${PTLS}/lib udevadm hwdb --update >> ${PLOGS}/eudev_configure.1 2>&1
coresrc_clean eudev


# Util-Linux
coresrc_prep util-linux
echo "[Util-Linux] Configuring..."
mkdir -p /var/lib/hwclock
./configure ADJTIME_PATH=/var/lib/hwclock/adjtime	\
	--docdir=/usr/share/doc/util-linux		\
	--disable-chfn-chsh				\
	--disable-login					\
	--disable-nologin				\
	--disable-su					\
	--disable-setpriv				\
	--disable-runuser				\
	--disable-pylibmount				\
	--disable-static				\
	--without-python				\
	--without-systemd				\
	--without-systemdsystemunitdir > ${PLOGS}/util-linux_configure.1 2>&1

echo "[Util-Linux] Building..."
make > ${PLOGS}/util-linux_make.1 2>&1
make install >> ${PLOGS}/util-linux_make.1 2>&1
coresrc_clean util-linux


# Man-DB
coresrc_prep man-db
echo "[Man-DB] Configuring..."
./configure --prefix=/usr			\
	--docdir=/usr/share/doc/man-db		\
	--sysconfdir=/etc			\
	--disable-setuid			\
	--with-browser=/usr/bin/lynx		\
	--with-vgrind=/usr/bin/vgrind		\
	--with-grap=/usr/bin/grap > ${PLOGS}/man-db_configure.1 2>&1

echo "[Man-DB] Building..."
make > ${PLOGS}/man-db_make.1 2>&1
#make check > ${PLOGS}/man-db_check.1 2>&1
make install >> ${PLOGS}/man-db_make.1 2>&1
coresrc_clean man-db


# Vim
coresrc_prep vim
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
echo "[Vim] Configuring..."
./configure --prefix=/usr > ${PLOGS}/vim_configure.1 2>&1

echo "[Vim] Building..."
make > ${PLOGS}/vim_make.1 2>&1
#make -j1 test > ${PLOGS}/vim_check.1 2>&1
make install >> ${PLOGS}/vim_make.1 2>&1
ln -s vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1;
do
    ln -s vim.1 $(dirname $L)/vi.1
done
mv /usr/share/vim/vim${VIMVER}/doc /usr/share/doc/vim
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

set nocompatible
set backspace=2
syntax on
if (&term == "iterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
coresrc_clean vim
