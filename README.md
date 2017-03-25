# 4bsd-uucp
This is a script and a set of template files which customises a generic 4.3BSD
SimH disk image so that it acts as a uucp node and connects to other uucp
nodes via TCP links.

# Installation
You will need the *bsdtar* program installed so that tarballs compatible with
4.3BSD can be installed. On Ubuntu, `sudo apt-get install bsdtar`. *Can someone
add instructions for other systems? The source for bsdtar is at
<http://www.libarchive.org/>*

You will also need a recent version of SimH: 4.0; version 3.9 doesn't work.
You can download the SimH Github repository at <https://github.com/simh/simh>.
In your local copy, build a vax780 SimH binary and copy the resulting binary
somewhere useful:

```
make vax780
sudo cp BIN/vax780 /usr/local/bin
```

Download this Github repository. In this repository, compile the mktape
program:

```
cc -o mktape mktape.c
```

You will see the generic 4.3BSD SimH image, `rq.dsk.gz`. The `buildimg` script
builds a tarball for each uucp system with the specific changes for that
system.

As an example, look at the `site_generate` script:

```
# An example of three uucp sites connected in series
#
#    site5 ----- site6 ----- site7
#
./buildimg site5:5000 site6:localhost:6000
./buildimg site6:6000 site5:localhost:5000 site7:localhost:7000
./buildimg site7:7000 site6:localhost:6000
```

*site5* allows you to telnet in on TCP port 5000. Ditto *site6* and TCP
port 6000, and *site7* and TCP port 7000.

*site5* has a (simulated) hard-wired serial connection to *site6* through
TCP port 6000. The syntax allows *site6* to be on a remote computer, e.g.
available through www.somewhere.com:6000.

*site6* has a (simulated) hard-wired serial connection to *site5* and *site7*.
Finally *site7* has a (simulated) hard-wired serial connection to *site6*.
This means that each site can initiate a connection to another site; they
don't have to wait for the other site to dial in.

For each site, there are two files generated:
* `siteX.ini` is the SimH config file to run this system
* `siteX.tap` is a tarball in *tap* format with the customisations

We also need to copy the generic disk image `rq.dsk.gz` to be the disk
for each site:

```
zcat rq.dsk.gz | dd conv=sparse > site5.dsk
zcat rq.dsk.gz | dd conv=sparse > site6.dsk
zcat rq.dsk.gz | dd conv=sparse > site7.dsk
```

I prefer to use `dd conv=sparse` because a lot of the disk image is empty
and this saves disk space for these files.

# Customising each System

Once you have a disk, a config file and the customisation tape, here is
how you customise the system. Boot up the system:

```
vax780 site5.ini
```

At the `login:` prompt, login as *root* with no password. At the shell prompt,
read in and unpack the tarball, and run a script which sets appropriate
file permissions:

```
myname# tar xf /dev/rmt12
tar: blocksize = 1
myname# ./mkdirs
29 password entries, maximum length 93
Type ctrl-D at the # prompt to restart things
erase ^?, kill ^U, intr ^C
#
```

Type a ctrl-D to restart in multi-user mode and login as *root*.
Your system now has a hostname:

```
login: root
Last login: Wed Mar  7 10:52:10 on console
You have mail.
Don't login as root, use su
site5#
```

Repeat the process for the other sites, e.g. *site6* and *site7*.
**SET ROOT PASSWORDS NOW!!** It is a good idea to reboot your simulated
system, as this will pick up the new kernel from the tarball.

# Sending E-mail

On *site5* you can send e-mail to `site6!root` and `site6!site7!root`.
Watch out for escaping the bang characters as the shell is *csh*, e.g.

```
echo Hello there | mail site6\!site7\!root
```

You should be able to work out the bangpaths to send e-mails on the other
systems.

# Testing Your Serial Links

Your mail is now sitting on your system waiting to be delivered over uucp.
Before you try to do a uucp connection, you can check if you have a working
serial link with a remote uucp site. In your simulated 4.3BSD system, edit
the *dialer* line in */etc/remote* to say:

```
dialer:dv=/dev/tty00:br#9600:
```

Now try:

```
# tip dialer
```

which should connect out over */dev/tty00* to the remote uucp site via the
TCP connection. Hit Return a few times to see if there is any response. On your
host system, do `netstat -a | grep ESTAB` and see if there is a TCP connection
to the remote system. To get out of *tip*, type in the two characters `~.`

# Performing UUCP Connections

Here is how to perform a manual uucp connection. On *site5*, to call *site6*:

```
# /usr/lib/uucp/uucico -r1 -ssite6 -x7
root site6 (3/9-06:27-166) DEBUG (Local Enabled)
finds (site6) called
getto: call no. tty00 for sys site6
Using DIR to call
Opening /dev/tty00
login called
wanted """"
got: that
. . .
Password:got: that
send "uucp"
root site6 (3/9-06:27-166) SUCCEEDED (call to site6 )
imsg looking for SYNC<
\20>
imsg input<Shere=site6\0>got 11 characters
omsg <Ssite5 -Q0 -x7>
imsg looking for SYNC<
. . .
Proto started g
protocol g
root site6 (3/9-06:27-166) OK (startup tty00 9600 baud)
*** TOP ***  -  role=MASTER
daemon site6 (3/9-06:27-166) REQUEST (S D.site5B00D2 D.site5S00D2 daemon)
. . .
PROCESS: msg - SY
SNDFILE:
send 0221
send 0231
send 0241
rec h->cntl 042
state - 010
. . .
daemon site6 (3/9-06:27-166) OK (conversation complete)
send OO 0,omsg <OOOOOO>
imsg looking for SYNC<\0\0\20>
imsg input<     \5*%\3\20>
imsg input<     "*\10   \20>
imsg input<     "*\10   \20>
imsg input<OOOOOO\0>got 6 characters
site5#
```

The `-x7` flag turns on debugging; it's not normally used in production.
Now go to *site6* and run a similar command to forward the e-mail to
*site7*:

```
# /usr/lib/uucp/uucico -r1 -ssite7 -x7
```

On *site7*, you can now read your e-mail:

```
site7# mail
Mail version 2.18 5/19/83.  Type ? for help.
"/usr/spool/mail/root": 3 messages 3 new
>N  1 MAILER-DAEMON Sat Jul  9 23:21  35/1191 "Returned mail: Host unknown"
 N  2 MAILER-DAEMON Sat Jul  9 23:22  33/986 "Returned mail: Host unknown"
 N  3 site5!root Wed Mar  7 11:02  14/422
& 3
Message  3:
From site6!site5!root Wed Mar  7 11:02:14 1984
Received: by site7.ARPA (4.12/4.7)
        id AA00173; Wed, 7 Mar 84 11:02:14 pst
Received: by site6.ARPA (4.12/4.7)
        id AA00168; Wed, 7 Mar 84 10:58:33 pst
Received: by site5.ARPA (4.12/4.7)
        id AA00170; Wed, 7 Mar 84 10:55:27 pst
Date: Wed, 7 Mar 84 10:55:27 pst
From: site6!site5!root (Charlie Root)
Message-Id: <8403071855.AA00170@site5.ARPA>
To: site6!site7!root
Status: R

Hello there

&
```

# Automating uucp Connections

You can edit `/usr/lib/crontab` to have entries that run *uucico* for each site
that you connection to. Here is an example line that connects to *site6*
every minute:

```
* * * * * uucp /usr/lib/uucp/uucico -r1 -ssite6
```

# Dealing with Multiple Outbound Connections

The system has to dedicate a */dev/tty0x* device for each outbound uucp
connection. If you have this situation, read through the 
[tcpdial](Docs/Tcpdial.md) documentation for a solution.

# Setting up News

The *buildimg* script will configure your system to be ready to run C News,
but you need to set up some cron jobs to actually make it happen. Read
through the [C News documentation](Docs/Cnews_setup.md) to see how to do this.

# Other Applications
If you want to install other applications, you'll have to find them, compile them
and install them. There is an archive of applications already configured at
<http://www.tuhs.org/Uucp/43BSD_Apps>. You might also want to look at an archive of
the [http://ftp.acc.umu.se/mirror/archive/ftp.sunet.se/pub/doc/usenet/ftp.uu.net/comp.sources.unix/](comp.sources.unix) Usenet postings.

# Security
The *tty* lines are exposed to the Internet through the bound TCP port, so
you may want to implement some firewall rules to only allow connections from
specific IP addresses.

The tty lines are set as insecure in the 4.3BSD `/etc/ttys`, so they won't
allow root logins. You can only login as root on the console, i.e. the place
where you ran `vax780 system.ini`. You should probably do this in a *tmux*
or *screen* session, so that you can get back to the 4.3BSD console easily.

It is a good idea to add a non-root user
so that you can telnet in on the TCP port: *only do this on localhost, as
the telnet session is not encrypted*. If you add this non-root user to the
group *wheel* (in `/etc/group`), then you can `su` and become root.

Make sure that you are running the kernel from the *buildimg*-created tarball:
you will see *munnari ... 2017* as the kernel boots. The *tty* lines in the
new kernel are set to kill off running shells when an incoming telnet
session is closed or disconnects unexpectedly.

# Disabling the Telnet Protocol

If you are running a SimH site which accepts connections from non-SimH uucp sites
(or vice versa), then there can be a problem because SimH uses the Telnet protocol
on the TCP port to, for example, know when to echo/not echo text (think: passwords).
This can cause uucp protocol problems, as the Telnet can interpret the incoming uucp
data, which screws up the uucp protocol.

If you have this situation, you can set up an incoming TCP port with Telnet disabled.
You will still want some of your simulated tty lines doing Telnet, so that you can log
into your simulated 4.3BSD system and have your password hidden. Here is an example
SimH configuration file with Telnet disabled.

```
# Set up eight DZ serial ports in 8-bit mode.
# Connect to a remote uucp site on 127.0.0.1:6000
# Listen on TCP port 5001 with Telnet disabled
# All other DZ lines will listen on port 5000 with Telnet enabled
set dz lines=8
set dz 8b
attach dz -a -m line=0,Connect=127.0.0.1:6000
attach dz -a -m line=1,5001;notelnet
attach dz -a -m 5000
```
# Dealing with Long Bangpaths

As it stands, the image has a vanilla mail over uucp configuration. This
means that, if you want to send e-mail to someone six uucp hops away, you
have to send e-mail to `site1!site2!site3!site4!site5!site6!user`.

The *smail* and *pathalias* extensions help you overcome this problem, but
you need to do a bit of configuration. Most importantly, you need to
import the [uucp.map](uucp.map) file into your system. Read through the
[Smail and Pathalias](Docs/Smail_configuration.md) for more details.


# Notes and Gotchas

At present, none!

# Joining the Growing UUCP Network

If you are interested in joining this simulation of the 1980s *uucp* network,
then send some e-mail to Warren Toomey. Indicate what historical *uucp*
site(s) you want to run and which other sites you want to connect to.

If you don't know what historical site to choose, have a look at the maps here:
<http://www.redace.org/html/logical_usenet_map_1984.html>

If you have a specific historical site in mind, do a search on the site's
name, e.g. "#N decvax", and include the double quotes; add the *uucp* keyword
as well if you like. Look for the lines after the "#N decvax" without hash
characters: they show you the connectivity that this site used to have.
An example for *decvax*:

```
#N	decvax, decvax.dec.com
#S	Vax 8300; Ultrix 32 V2.2
#O	Digital Equipment Corp.
#C	Larry Palmer
#E	decvax!lp
#T	(603)8848385
#P	MK2-1/H10 Continental Blvd, Merrimack, NH 03054
#L	42 49 N / 71 31 W
#R	
#W	
#U	bellcore cca mandrill dartvax decwrl genrad gsg harpo ichaya 
#U	linus mcnc savax tektronix ucbvax vortex yale
#R	decvax has moved to a new location - an update is expected soon... -jj
#
# local calls
decvax	bu-tyng(DIRECT), ichaya(DIRECT), savax(DIRECT), sequitor(DIRECT), 
	shaman(DIRECT), sii(DIRECT), skippy(DIRECT), stellar(DIRECT)
# Internet
decvax  decwrl(DEDICATED), ucbvax(DEDICATED)
#
# frequent calls
decvax	bellcore(HOURLY), cca(HOURLY), cg-atla(HOURLY), mandrill(HOURLY), 
	deceds(HOURLY), decuac(HOURLY), genrad(HOURLY), granite(HOURLY), 
	hanauma(HOURLY), ihnp4(HOURLY), lafite(HOURLY), 
	linus(HOURLY), mcnc(HOURLY), mit-athena(HOURLY), netrix(HOURLY), 
	tektronix(HOURLY), vortex(HOURLY), yale(HOURLY)
#
# non-prime time calls
decvax	allegra(EVENING), astrovax(EVENING), bobo(EVENING), brunix(EVENING),
	bunker(EVENING), cbosg(EVENING), cbosgd(EVENING), cincy(EVENING),
	cornell(EVENING), cray(EVENING), duke(EVENING), emory(EVENING), 
	encore(EVENING), esquire(EVENING), farance(EVENING), freeport(EVENING),
	gatech(EVENING), hcr(EVENING), hermix(EVENING), hjuxa(EVENING), 
	hplabs(EVENING), idis(EVENING), ima(EVENING),
	masscomp(EVENING), microsoft(EVENING), mit-vax(EVENING), 
	mtxinu(EVENING), netword(EVENING), philabs(EVENING), pur-ee(EVENING), 
	purdue(EVENING), randvax(EVENING), research(EVENING), 
	rochester(EVENING), sdcsvax(EVENING), sickkids(EVENING), std(EVENING), 
	stolaf(EVENING), sun(EVENING), trwrb(EVENING), ucf-cs(EVENING), 
	ulysses(EVENING), usenix(EVENING), utah-cs(EVENING), utzoo(EVENING), 
	uw-beaver(EVENING), vax135(EVENING), watmath(EVENING)
#
# very long distance calls
decvax	mulga(DAILY)
#
# incoming calls
decvax	apollo(POLLED), attunix(POLLED), bbn(POLLED), bhjat(POLLED), 
	brl-smoke(POLLED), chaos(POLLED), cvbnet(POLLED), dartvax(POLLED),
	elrond(POLLED), epiwrl(POLLED), flkvax(POLLED), 
	frog(POLLED), gsg(POLLED), harpo(POLLED), howtek(POLLED), 
	humus(POLLED), jaxlab(POLLED), ll-xn(POLLED), mindcrft(POLLED), 
	mkunix(POLLED), necntc(POLLED), nicmad(POLLED), noao(POLLED), 
	nrl-css(POLLED), plato(POLLED), raster(POLLED), stcvax(POLLED), 
	sunybcs(POLLED), tifsie(POLLED), unh(POLLED), virgin(POLLED), 
	wang(POLLED)
```

For central sites (like *decvax*) that had a lot of connectivity, you will be
expected to run them continuously. For edge sites which only dial in to one
other site to exchange news and e-mail, you can run them whenever you want.
