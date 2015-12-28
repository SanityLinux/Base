# Pür Linux
Pür Linux is a Linux distribution consisting entirely of Upstream code. No wonky distro-specific changes, no unneeded packages in base, and best of all, no SystemD. 

Pür Linux (Pronounced Pure Linux) consists of a base system comprised of upstream pure code (GNU utils you'd expect on a Linux system, the latest vanilla Linux kernel upon packaging), and the Linux port of pkgsrc from NetBSD for ports.

Unlike other Linux distrobutions, Pür Linux uses a Base/Ports paradigm, similar to FreeBSD, wherein the base operating system is updated and maintained separately from user-installed packages. This means you can update them independantly, and package updates won't bork your OS.

Pür Linux will be distributed via Tarball in a quarterly release schedule, starting sometime in 2016.
Installation will be as simple as untarring and running setup.sh
Updating is as simple as untarring and replacing, while booted into a rescue distribution such as RIP or Finnix.

All configurations are done via plaintext files, or shell scripts.

Shells included are zsh, csh, ksh, and fish. Zsh is bash-compatible, however bash will be available via pkgsrc.

## Plans

Pür Linux will use an rc-style init system, similar to Slackware, rather than sysvinit or SystemD. We strongly encourage against infecting your system with the SystemD malware. /dev will likely be populated via eudev, Gentoo's udev fork.
While we would like to include Clang/LLVM, due to the Linux kernel being reliant on GCC-specific tweaks right now, we will be including GCC in base, with Clang available via pkgsrc. Plans will be made to transition to Clang in base as soon as is feasible.

## Installation notes
Pür Linux works great on most systems.
Please be aware of the following caveats:
As much as I'd like to include support for ZFS, the goal of Pür Linux is to be untouched from upstream.
As such, ZFS support will remain as something you can compile in yourself.
We may look at making minor changes to this policy in the future, or possibly including the support as an LKM.
If so, we will begin including the zpool and zfs management tools in Base.

As we are using pkgsrc for installed packages, Pür Linux will be placing all installed packages inside the /usr/local directory, similar to FreeBSD. /bin, /sbin, /etc, /usr/bin, and /usr/sbin will only be used for Base utilities.
As such, some scripts you download may require tweaking (We always suggest using the #!/usr/bin/env $shell shebang over hardcoded paths) to work on Pür Linux.

Pür Linux will work GREAT on Linode! Since it's just a tarball, boot into Rescue Mode and untar to the disk you created in the Linode Manager. Feel free to use the Linode kernel, rather than the kernel on disk.
