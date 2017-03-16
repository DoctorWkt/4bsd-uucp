# Setting up C-News

**Note: This setup has now been merged into the underlying disk image, so you don't need to do this any more. However, the testing section is still useful. -- Warren**

This assumes that you have downloaded the 4.3BSD system from Github,
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

# Example Config Files

John Floren writes: Here are my config files:

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
