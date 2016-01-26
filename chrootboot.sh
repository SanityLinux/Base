#!/tools/bin/bash

set -e

# /dev will be handled by eudev. -bts 
echo "Making directory tree..."
mkdir -p /{bin,boot,etc/opt,home,lib/firmware,mnt,opt}
mkdir -p /{media/{floppy,cdrom},sbin,srv,var}
install -d -m 0750 /root
install -d -m 1777 /tmp /var/tmp
mkdir -p /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -p /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir /usr/libexec
mkdir -p /usr/{,local/}share/man/man{1..8}

case $(uname -m) in
	x86_64) ln -s lib /lib64
		ln -s lib /usr/lib64
		ln -s lib /usr/local/lib64 ;;
esac
mkdir /var/{log,mail,spool}
ln -s /run /var/run
ln -s /run/lock /var/lock
mkdir -p /var/{opt,cache,lib/{color,misc,locate},local}

ln -s /tools/bin/{bash,cat,echo,pwd,stty} /bin
ln -s /tools/bin/perl /usr/bin
ln -s /tools/lib/libgcc_s.so{,.1} /usr/lib
ln -s /tools/lib/libstdc++.so{,.6} /usr/lib
sed -e 's/tools/usr/' /tools/lib/libstdc++.la > /usr/lib/libstdc++.la
ln -s bash /bin/sh

ln -s /proc/self/mounts /etc/mtab

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



# linux headers
echo "[Kernel] Cleaning sources for headers..."
cd /sources/linux-4.4
make mrproper > ${PLOGS}/kernel-headers_clean.1 2>&1

echo "[Kernel] Building headers..."
make INSTALL_HDR_PATH=dest headers_install > ${PLOGS}/kernel-headers_make.1 2>&1
find dest/include \( -name .install -o -name ..install.cmd \) -delete > /dev/null 2>&1
cp -r dest/include/* /usr/include
cd ..


# man pages
echo "[Man pages] Installing..."
tar -Jxf man-db-2.7.5.tar.xz
cd man-db-2.7.5
make install > ${PLOGS}/man_make.1 2>&1
cd ..


# glibc
echo "[GLibC] Configuring..."
rm -rf glibc-build
mkdir glibc-build
cd glibc-build
../glibc-2.22/configure			\
		prefix=/usr		\
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
cp ../glibc-2.22/nscd/nscd.conf /etc/nscd.conf
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


# timezone data
echo "Timezone data..."
tar -xf ../tzdata2015g.tar.gz
ZONEINFO=/usr/share/zoneinfo
mkdir -p ${ZONEINFO}/{posix,right}
for tz in etcetera southamerica northamerica europe africa antarcticaasia australasia backward pacificnew systemv;
do
	zic -L /dev/null
	-d ${ZONEINFO}
	-y "sh yearistype.sh" ${tz}
	zic -L /dev/null
	-d ${ZONEINFO}/posix -y "sh yearistype.sh" ${tz}
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
mv /tools/bin/{ld,ld-old}
mv /tools/$(gcc -dumpmachine)/bin/{ld,ld-old}
mv /tools/bin/{ld-new,ld}
ln -s /tools/bin/ld /tools/$(gcc -dumpmachine)/bin/ld
gcc -dumpspecs | sed -e 's@/tools@@g'			    \
	-e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
	-e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' > \
	$(dirname $(gcc --print-libgcc-file-name))/specs
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
linecnt=$(grep 'SEARCH.*/usr/lib' dummy.log | sed -e 's|; |\n|g' | egrep -Ec '^(SEARCH_DIR\("/usr/lib"\)|SEARCH_DIR\("/lib"\);[[:space:]]*$')
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
grep found dummy.log | egrep -Eq '^found ld-linux\.so\.2 at /lib(32|64)?/ld-linux\.so\.2[[:space:]]*$'
if [ "${?}" != '0' ];
then
	# per LFS 7.8, p.97, "If the output does not appear [as we check for it], then something is seriously wrong." thanks!
	echo "Something is 'seriously wrong'. Bailing out..."
	exit 1
fi
rm dummy.c a.out dummy.log
cd ..
