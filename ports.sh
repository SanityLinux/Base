#!/bin/sh
# This script resides in /usr/bin as /usr/bin/ports and bootstraps pkgsrc on Pür Linux.
# It is meant to be run at first boot and auto-removes itself, similar to the pkg bootstrapper in FreeBSD.
# Please be aware this script does some non-standard things, by renaming pkgsrc to ports in the
# directory tree and overall using a more FreeBSD-based layout.
# bmake is installed in /usr/local/bin
# Possible plans include symlinking it to make. GNU Make, part of the base system, would be moved to gmake.
# For now, it sits at bmake, however, and Ports must be invoked with bmake.

echo "Bootstrapping PürPorts (NetBSD Pkgsrc)"
cd /usr
cvs -q -z2 -d anoncvs@anoncvs.NetBSD.org:/cvsroot checkout -r pkgsrc-2015Q4 -P pkgsrc
mv /usr/pkgsrc /usr/ports
/usr/ports/bootstrap/bootstrap --prefix /usr/local
echo "Ports Bootstrapped. Now Moving Bootstrapper to /usr/bin/bootstrapped"
mv /usr/bin/ports /usr/bin/bootstrapped
chmod -x /usr/bin/bootstrapped
echo "Go ahead! Try it out! Example: cd /usr/ports/shells/fish && bmake install clean"
echo "More information on Pkgsrc is available at http://www.pkgsrc.org/ "
