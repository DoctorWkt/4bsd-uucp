# Extra Software for 4.3 BSD Systems

*(this comes from Bill Pechter)*

I set up an [anonymous ftp site](ftp://lakewoodmicro.com/pub) on a
Digital Ocean droplet running
FreeBSD. I figured that's a historic way of distributing historic
software.  I'm working on getting more available.

I found a lot of stuff which was built for 4.3-BSD-Uwisc.  I played
with Reno and it was much nicer than straight 4.3.  It had things like
*find -ctime* and *xargs* -- which I've always seen on SysV and some of my
scripts depend on it.

I'm looking to put up a downloadable ra81 image -- but first
I need to see if it can compile itself as a verification that it's
all good on the image.

The Gunkies site below has got more software ready to go on *.taps* than I did.
He hit some of the same issues.  I saw Reno had *stddef.h*, *stdlib.h* and
*unistd.h*.  *(I think these were post 4.3)*

BSD and SIMH files (including ported software):
<https://sourceforge.net/projects/bsd42/files/>,
<http://gunkies.org/wiki/4.3_BSD_NFS_Wisconsin_Unix> (includes i386
Simh and 4.3Uwisc disk image)

## How do I get this to run?!

You can download the tape pieces from any TUHS archive spot from
the following path */4BSD/Distributions/thirdparty/UWisc4.3/*

Installation instructions for 4.3 BSD +NFS Wisconsin Unix can be
found here: <http://gunkies.org/wiki/Installing_4.3_BSD+NFS_Wisconsin_Unix>

## What Runs?

For its age, an amazing amount of software will compile and run on
this platform.

 - bash 1.14.7 <http://gunkies.org/wiki/Bash>
 - bash 2.0 <http://gunkies.org/wiki/Bash>
 - binutils 2.8.1 <http://gunkies.org/wiki/Binutils>
 - bison 1.25 <http://gunkies.org/wiki/Bison>
 - flex 2.5.4 <http://gunkies.org/w/index.php?title=Flex&action=edit&redlink=1>
 - gcc 1.42 <http://gunkies.org/wiki/Gcc>
 - gcc 2.4.5 <http://gunkies.org/wiki/Gcc>
 - gcc 2.5.8 <http://gunkies.org/wiki/Gcc>
 - gcc 2.7.2.2 <http://gunkies.org/wiki/Gcc>
 - gdb 3.1 <http://gunkies.org/wiki/Gdb>
 - gzip  1.2.4 <http://gunkies.org/wiki/Gzip>
 - hack 1.0.3 <http://gunkies.org/wiki/Hack>
 - irc  2.8.21 <http://gunkies.org/wiki/Irc>
 - ircii 4.4 <http://gunkies.org/wiki/Ircii>
 - lynx 2.8.2 <http://gunkies.org/wiki/Lynx>
 - GNUmake 3.75 <http://gunkies.org/w/index.php?title=GNUmake&action=edit&redlink=1>
 - pine 3.87 <http://gunkies.org/w/index.php?title=Pine&action=edit&redlink=1>
 - screen 3.7.1 <http://gunkies.org/wiki/Screen>
 - top 3.2 <http://gunkies.org/wiki/Top>
 - unzip 522 <http://gunkies.org/wiki/Unzip>
