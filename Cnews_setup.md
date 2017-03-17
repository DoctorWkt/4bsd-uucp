# Setting up C-News

C News has now been merged into the underlying SimH disk image. If you have
run *buildimg* to create a 4.3BSD SimH image, then the remote sites you
listed on the command line will be the remote sites that you send news to.

On your SimH system, look at `/usr/lib/news/sys`, at the bottom it should
have a *ME* entry for your system, then the list of remote sites, e.g.

```sh
ME:all/all::
munnari:all/all:f:
ihnp4:all/all:f:
philabs:all/all:f:
nocrew:all/all:f:
ucbvax:all/all:f:
tektronix:all/all:f:
mcvax:all/all:f:
decwrl:all/all:f:
site5:all/all:f:
```

If you need to add other uucp sites to send news, you need to add an
entry to the above file, and also make directories in
`/usr/spool/news/out.going` for each site, owned by *news.news*, e.g.:

```
drwxrwxr-x  2 news     news          512 Mar 14  1984 decwrl
drwxrwxr-x  2 news     news          512 Mar 16 20:27 ihnp4
drwxrwxr-x  2 news     news          512 Mar 14  1984 mcvax
drwxrwxr-x  2 news     news          512 Mar 16 20:27 munnari
drwxrwxr-x  2 news     news          512 Mar 14  1984 nocrew
drwxrwxr-x  2 news     news          512 Mar 16 20:27 philabs
drwxrwxr-x  2 news     news          512 Mar 14  1984 site5
drwxrwxr-x  2 news     news          512 Mar 14  1984 tektronix
drwxrwxr-x  2 news     news          512 Mar 16 20:27 ucbvax
```

# Speeding Up News Processing

In `/usr/lib/newsbin/input/newsrun` there is a `sleep 45`. On our systems
with few users, this can be reduced. I've set it to `sleep 5`.

# Some Useful Scripts

The *decvax* system has a lot of remote sites that it sends e-mail and news to.
I've setup *cron* with a few scripts. Here they are; you might find them
useful.

```sh
# /usr/lib/crontab
1,6,11,16,21,26,31,36,41,46,51,56 * * * * uucp /usr/lib/uucp/00calls
7,17,27,37,47,57                  * * * * news /usr/lib/newsbin/runandbatch
```

```sh
#!/bin/sh
# /usr/lib/uucp/00calls
#
# Call the systems connected on /dev/tty00
# but only if they have jobs to send
for i in ihnp4 philabs ucbvax
do  /usr/bin/uuq -h -s$i | grep -s job
    if [ "$?" -eq "0" ]
    then /usr/lib/uucp/uucico -r1 -s$i $*
    fi
done
exit 0
```

```sh
#!/bin/sh
# /usr/lib/newsbin/runandbatch
#
/usr/lib/newsbin/input/newsrun
for i in munnari ihnp4 philabs ucbvax
do /usr/lib/newsbin/batch/sendbatches $i
done
exit 0
```

# Testing News

To test that news works (on machines lanl-a and decvax):

```sh
lanl-a# setenv EDITOR `which vi`
lanl-a# postnews
	.... write a post in tuhs.test

lanl-a# su news -c /usr/lib/newsbin/input/newsrun
lanl-a# su news -c /usr/lib/newsbin/batch/sendbatches decvax
lanl-a# /usr/lib/uucp/uucico -r1 -sdecvax -x7

decvax# su news -c /usr/lib/newsbin/input/newsrun
decvax# readnews -n tuhs.test
```

# Original Configuration Procedure

*These were the original instructions when C News wasn't included 
on the SimH image. I'm leaving them here in case they help people
who are rolling things themselves.*


This procedure assumes that you have downloaded the 4.3BSD system from Github,
configured it for uucp, and confirmed that you can send e-mail between
two systems.


```sh
# Change the path in L.cmds
vi /usr/lib/uucp/L.cmds
(and change the top line to say)
PATH=/bin:/usr/bin:/usr/ucb:/usr/new:/usr/lib/newsbin/input:/usr/lib/newsbin

# Go into the news config directory
cd /usr/lib/news
vi whoami		# Change to your uucp sitename
vi organization		# Description of your site
vi mailname		# Change to your uucp sitename

# Set up the list of machines we exchange news with, e.g. decvax
cat > sys
ME:all/all::
decvax:all/all:f:
			ctrl-D to exit cat
chown news.news sys
```

(or edit the sys file, comment out all lines and add the ones
above. Replace decvax with the name(s) of the other systems)

```sh
# For each remote site, create /usr/spool/news/out.going/<sitename>
# and chmod it to news
mkdir /usr/spool/news/out.going/decvax
chown news.news /usr/spool/news/out.going/decvax
```

# Example Config Files

John Floren writes: Here are my C News config files:

```sh
************** active **************
control 0000000000 00001 y
junk 0000000000 00001 y
news.announce.newusers 0000000000 00001 m
tuhs.test 0000000004 00001 y
```

```sh
************** explist **************
all     x       14      -
```

```sh
************** sys **************
ME:all/all::
decvax:all/all:f:
```
