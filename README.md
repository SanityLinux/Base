# P-r-Linux
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
