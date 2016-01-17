#!/bin/sh
# This script resides in /usr/bin and bootstraps pkgsrc on Pür Linux.
# Please be aware this script does some non-standard things, by renaming pkgsrc to ports in the
# directory tree and overall using a more FreeBSD-based layout.
# bmake is installed in /usr/local/bin
# Possible plans include symlinking it to make. GNU Make, part of the base system, would be moved to gmake.
# For now, it sits at bmake, however, and Ports must be invoked with bmake.

echo "Bootstrapping PürPorts (NetBSD Pkgsrc)"
cd /usr
cvs -danoncvs@anoncvs.netbsd.org:/cvsroot checkout pkgsrc
mv /usr/pkgsrc ./usr/ports
/usr/ports/bootstrap/bootstrap --prefix /usr/local
