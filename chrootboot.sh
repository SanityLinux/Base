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

PLOGS=/var/logs/pur_install
rm -rf ${PLOGS}
mkdir -p ${PLOGS}


