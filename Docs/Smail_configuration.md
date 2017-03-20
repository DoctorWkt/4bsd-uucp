# Installing and Configuring Pathalias and Smail 2.5

*Smail* and *pathalias* allow you to send email without long bangpaths.
You can do `echo hello | mail munnari!wkt` instead of
`echo hello | mail philabs!decvax!munnari!wkt`

# Installing Pathalias

Download *pathalias_src_bins.tar.gz* and *smail2.5_src_bins.tar.gz*
from <http://www.tuhs.org/Uucp/43BSD_Apps/Historical/>.
Use *mktape* on the outside, then *mt rew* and *tar vxf /dev/rmt12*
on the inside to get them into your 4.3BSD system.

Go into the *pathalias/* directory and do:

```
cp pathalias makedb /usr/local/bin
cp pathalias.1 /usr/man/manl/pathalias.l
```

# Installing Smail

You will have to edit some config files here, so don't just run the
commands below.

Go into the *smail2.5* directory. Move and replace some binaries:

```sh
cp smail /bin/smail
cp pathproc lcasep /usr/local/bin
cp smail.8 lcasep.8 pathproc.8 paths.8 /usr/man/man8
mv /bin/rmail /bin/OLDrmail
ln /bin/smail /bin/rmail
```

Edit the *sendmail.cf* file and put in your uucp site's name and the
list of machines that you can directly connect with uucp. Below are
the lines for site *seismo*.

```
...
# $A is another domain for which this host is 'authoritative'
# it will will be turned into $D.

Dwseismo
DDuucp
CDUUCP seismo.uucp

# Preemptive ether connections.  We prefer these connections
...
```

Also fix up the *Mlocal* line as follows:

```
Mlocal, P=/bin/mail, F=rlsDFMmn, S=10, R=20, A=mail -d $u
Mprog,  P=/bin/sh,   F=lsDFMe,   S=10, R=20, A=sh -c $u
```

Now replace the existing *sendmail.cf* with this one, keeping a
copy just in case:

```
cp /usr/lib/sendmail.cf /usr/lib/OLDsendmail.cf
cp sendmail.cf /usr/lib/NEWsendmail.cf
cp sendmail.cf /usr/lib/sendmail.cf
```

# Running Pathalias and Pathproc

Download the *uucp.map* file from
<https://github.com/DoctorWkt/4bsd-uucp/blob/4.3BSD/uucp.map>.
You can either do the *mktape, mt rew tar xf* dance, or you can just 
manually save a text file with the lines without hashes. For example,
you might have a */tmp/map* file that looks like this:

```
seismo  cmcl2(DIRECT), philabs(DIRECT), mcvax(DIRECT)
decvax  ihnp4(DIRECT), philabs(DIRECT), ucbvax(DIRECT), mcvax(DIRECT)
ucbvax  decvax(DIRECT)
ihnp4   decvax(DIRECT), cbosgd(DIRECT)
philabs decvax(DIRECT), mcvax(DIRECT), seismo(DIRECT)
munnari decvax(DIRECT)
cmcl2   seismo(DIRECT), lanl(DIRECT)
lanl    cmcl2(DIRECT)
mcvax   ukc(DIRECT), decvax(DIRECT), philabs(DIRECT), seismo(DIRECT)
ukc     mcvax(DIRECT)
```

It doesn't matter if the file has blank lines or not. Now, determine
the best paths to all remote sites with *pathalias*, post-process this
with *pathproc* and save the file:

```
pathalias -c /tmp/map | sh /usr/local/bin/pathproc > /usr/lib/uucp/paths
```

Using the above */tmp/map* file on uucp site *seismo*, the
*/usr/lib/uucp/paths* file looks like:

```
cbosgd  mcvax!decvax!ihnp4!cbosgd!%s    800
cmcl2   cmcl2!%s        200
decvax  mcvax!decvax!%s 400
ihnp4   mcvax!decvax!ihnp4!%s   600
lanl    cmcl2!lanl!%s   400
mcvax   mcvax!%s        200
munnari mcvax!decvax!munnari!%s 30000400
philabs philabs!%s      200
seismo  %s      0
ucbvax  mcvax!decvax!ucbvax!%s  600
ukc     mcvax!ukc!%s    400
```

# Sending E-mail

You should now be able to send e-mail to someone on a remote uucp site:

```sh
echo hello | mail munnari!wkt
```

and your `uuq -l` should show the mail going through a locally-connected
site to reach the destination:

```
# uuq -l
mcvax: 1 job, 431 bytes, 0.1 minutes (@ effective baudrate of 840)
00x4  2 wkt     431  0.1 Mar 18 15:09 S rmail decvax!munnari!wkt
```

# Bugs

There seems to be a bug in *pathalias* which makes it produce huge cost values (in the order or millions). This causes *smail* to think that the remote site is unreachable. If you see a very large cost in `/usr/lib/uucp/paths`, then edit it back down to 1000.

`/usr/local/bin/pathproc` is a shell script with a pipeline across multiple lines.
It needs some backslash (\) characters on a couple of lines to join the lines up.
