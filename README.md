# Pür Linux
Pür Linux is a Linux distribution consisting entirely of the latest Upstream code. No wonky distro-specific changes, no unneeded packages in base, and best of all (in our opinion), no systemd. You don't get bleedinger-edged than this.

## About Pür
Pür Linux (Pronounced Pure Linux) consists of a base system comprised of upstream pure code (GNU utils you'd expect on a Linux system, the latest vanilla Linux kernel upon packaging), and the Linux port of pkgsrc from NetBSD for ports.

Pür Linux is not a fork, nor respin of any pre-existing Linux Distribution.
The only relation to any other distro is that right now, we use an Arch Linux box for building the environment that gets tar'd.

Unlike other Linux distributions, Pür Linux uses a Base/Ports paradigm, similar to FreeBSD, wherein the base operating system is updated and maintained separately from user-installed packages. This means you can update them independently, and package updates won't bork your OS.

Pür Linux will be distributed via Tarball in a quarterly release schedule, starting sometime in 2016.
Installation will be as simple as untarring and running setup.sh
Updating is as simple as untarring and replacing, while booted into a rescue distribution such as RIP or Finnix.
Security patches will be released as needed, via the same format.
There are tentative plans for a tool, similar to freebsd-update, that will allow in-place upgrades and security updates.
Please be aware this tool is not yet on our roadmap.

All configurations are done via plaintext files, or shell scripts.

Shells included are bash, csh, ksh, and fish.

We are also the very FIRST Linux Distribution with plans to ship NTPsec rather than classic NTP or OpenNTP by default!
https://www.ntpsec.org/

## The Pür Linux Team
* Rainbow - Project Director, BASE team lead, Packages Maintainer
* Brent Saner - Git Wizard, Architecture Engineer, BASE Developer
* James Stewart - Documentation team lead

##Benefits of using Pür
* No weird distro-specific changes to the file-system hierarchy: we use a standardized filesystem layout, similar to FreeBSD and traditional UNIX.
* No binary logs or incomprehensible configuration formats: We're not using systemd. Everything is logged to plaintext. Configuration files are the same, unless otherwise specified by upstream, which brings us to:
* 100% Upstream code: everything is build from upstream code. Everything works as the programmers intended, and all documentation is correct (or as correct as the programmer wrote) for the version installed.
* Latest code: Pür's goal is to provide the latest stable code releases from the programmers and teams involved. You won't find a 3 year out of date version of something here. Every release is completely comprised of the newest stable releases, unless otherwise specified in the Changelog/Errata Notification
* No new tools to learn: If you know UNIX, you know Pür Linux. Releases are installed and updated as tarballs you simply extract and overwrite with. Wanna copy your configuration to a whole new system? Tar up /etc and /usr/local, and extract onto a new disk or partition along with the latest Pür Linux release tarball. Done!
* "Cloud" Support: We support the Linode** platform right out of the box. Boot into Rescue Mode, untar Pür to the disk you created in the Linode Manager, and boot with the latest Linode kernel!
* Releases are synced with the latest stable snapshot of the NetBSD pkgsrc tree, and via pkgin and pkgsrc's automated building framework, binary packages are also available, in addition to the standard From Source methodology provided by pkgsrc
* ZFS is a supported Filesystem, and will be included as a Loadable Kernel Module compiled against the current upstream stable Linux kernel.

** DISCLAIMER: Pür Linux is not endorsed by Linode, LLC. The project is not officially affiliated with Linode, LLC.
Pür Linux is, however, maintained by an existing Linode employee, on their own time.

## Plans

Pür Linux will use an rc-style init system, similar to Slackware, rather than sysvinit or SystemD. /dev will likely be populated via eudev, Gentoo's udev fork.
While we would like to include Clang/LLVM, due to the Linux kernel being reliant on GCC-specific tweaks right now, we will be including GCC in base, with Clang available via pkgsrc. Plans will be made to transition to Clang in base as soon as is feasible.

### Project Roadmap
* Spring 2016 - Initial Stable release, version 2016.04-RELEASE

## Development Branches
Similar to FreeBSD, we currently maintain multiple branches. 
* CURRENT - Bleeding edge. Where most of the work occurs.
* STABLE - Pür Linux's Stable branch is where we stage work for release candidates, and is branched off of CURRENT roughly a month prior to the next RELEASE.
* RELEASE - The current stable release of Pür Linux. Releases are formatted as Year.Month-RELEASE. Security updates are tagged with a U. For example, 2016.07-RELEASE-U1 would be the first security update for 2016.07-RELEASE

Due to the release schedule, Security Updates will only be supplied for a version until the next major version release.
This means each major version has a 3 month lifecycle until EOL. You will not recieve any help for running an EOL version.

## Installation notes
Pür Linux works great on most systems.

Please be aware of the following caveats:

As we are using pkgsrc for installed packages, Pür Linux will be placing all installed packages inside the /usr/local directory, similar to FreeBSD. /bin, /sbin, /etc, /usr/bin, and /usr/sbin will only be used for Base utilities.
As such, some scripts you download may require tweaking (We always suggest using the #!/usr/bin/env $shell shebang over hardcoded paths) to work on Pür Linux.

Pür Linux will work GREAT on Linode! Since it's just a tarball, boot into Rescue Mode and untar to the disk you created in the Linode Manager. Feel free to use the Linode kernel, rather than the kernel on disk.

## FAQ

Q: So does pkgsrc update the whole system?

A: Nope! Pür Linux breaks the traditional Linux paradigm of EVERYTHING IS A PACKAGE. I'm a FreeBSD sysadmin, and I really enjoy the separation between the Base system and 3rd party packages. While Pür Linux won't be developed in a single source tree like FreeBSD (Not much to develop folks. The goal is building and distributing Upstream code, remember?) there's still going to be separation between the Base OS (Pür Linux) and Ports (using pkgsrc)


Q: You're just trying to make Linux like $BSD

A: Yup. That's the world I come from. I started out as a Linux admin originally, but all the lack of standardization between distros made me tear my hair out. Not to mention the problems with the everything is a package way of doing things.
I like having an OS be stable and secure and regularly released, with other packages being taken care of separately.


Q: How are we sure no one tampered with anything?

A: Well, as far as the distro itself, you have to trust me. Thing is, you do that with Ubuntu/CentOS/Slackware/Gentoo already anyway. As far as releases go, each tarball will be signed, and checksummed.


Q: Can I build this from source? / Where the heck is your source code?

A: Pür Linux is built entirely from upstream! This means we won't be mirroring anything except tarballs, buildscripts, and if we absolutely have to, specific changes.
This repository will have a shellscript uploaded along with the first release, to assist you in automating the process.
As URLs change, it'll be checked for accuracy and updated with each version of Pür Linux.
This is the same shell script we use for builds.

Q: I wanna send you a message. Wat Do.

A: Email rainbow@purlinux.org

My PGP key is 0x5F94763A

You can also just hit me up on Twitter. I'm Hacker_Horse there.

You can also follow @PurLinux or email info@purlinux.org

Q: IRC?

A: #purlinux on irc.freenode.net 
Come say hi!

Q: Primary Project Master repo?

A: On Github, the primary master repo is at https://github.com/PurLinux/Base

The original repo was located at https://github.com/RainbowHackerHorse/Pur-Linux/ now https://github.com/RainbowHackerHorse/Pur-Linux-Base/tree/Legacy
Legacy will not be updated, however https://github.com/RainbowHackerHorse/Pur-Linux-Base/ is where my (Rainbow's) contributions are developed before being merged into the upstream Base repo.

Other people may have forks. 
