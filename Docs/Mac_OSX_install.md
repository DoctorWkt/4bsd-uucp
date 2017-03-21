# Bring up a 4.3BSD system on Mac OSX

John Labovitz spent some time bringing a 4.3BSD system up on Mac OS X.
Here are his notes.

I’m using macOS, and have noticed a couple of small things you might want to
note in the docs.

First, *zcat* for some reason complains about reading *rq.dsk.gz* as an
argument, but works fine if told to read from stdin. I suppose it’s being too
smart about guessing filenames.

Second, the version of *bsdtar* that comes with macOS is too old (of course),
and doesn’t support the *—uid* etc. flags that it's being called with in the
Perl script. The version in Homebrew (from *libarchive*) does work, but as it
could conflict with the system version, Homebrew doesn’t install it — so I use
a custom `$PATH` setting to read the correct version.

Below is a small shell script that I built which incorporates these
changes, and automates my experimentation a bit.

```
#!/bin/sh

# brew install libarchive

set -e
set -x

HOST=sly

rm -f $HOST.{dsk,ini,tap}
zcat < rq.dsk.gz | dd conv=sparse > $HOST.dsk
PATH="/usr/local/opt/libarchive/bin:$PATH" ./buildimg $HOST:5000

cat <<EOF

# on simulated system:

# set password for root
passwd

# install files
tar xf /dev/rmt12 && ./mkdirs

EOF

vax780 $HOST.ini
```
