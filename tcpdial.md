# Running Outbound Connections to Many Sites
If you have many outbound uucp conections, here is a solution which
lets you do this with only a single TCP connection. The idea is to have
a local daemon, *tcpdial*, which your simulated system connects to. 
*tcpdial* acts as a modem. Your system "dials" a specified number, *tcpdial*
interprets this number and then makes the matching TCP connection to the
remote uucp site.

Here is an example. Let's run *tcpdial* in debug (*-d*) mode, listening on
localhost port 4000, with two remote systems *decvax* and *ihnp4*:

```sh
$ tcpdial.pl -d -p 4000 -n 5551234:simh.tuhs.org:5000 -n 5556789:minnie.tuhs.org:5000
```

*decvax* is actually simh.tuhs.org:5000, so now its phone number is 5551234.
*ihnp4* is actually minnie.tuhs.org:5000, so now its phone number is 5556789.

In the SimH .ini file, we change our outbound connections to just one
which connects to *tcpdial*:

```sh
attach dz line=0,Connect=localhost:4000
```

and this corresponds to */dev/tty00* in the simulated 4.3BSD system.

Down in the 4.3BSD system in */usr/lib*, edit your *L.sys* file to have these
entries:

```sh
#System  Times  Caller  Class  Device/Phone_Number      [Expect  Send]....
decvax Any;1 DIR 9600 tty00  "" "ATDT5551234\r" CONNECT "" ogin:--ogin:--ogin: u
ucp ssword: uucp
ihnp4 Any;1 DIR 9600 tty00  "" "ATDT5556789\r" CONNECT "" ogin:--ogin:--ogin: uu
cp ssword: uucp
```

Both *decvax* and *ihnp4* will be dialed using the directly-connected
*/dev/tty00*. When we phone *decvax* it will send *ATDT5551234* to *tcpdial*
and expect to see *CONNECT* back. Similarly, phoning *ihnp4* will
send *ATDT5556789* and expect to see *CONNECT* back.

At the *tcpdial* end, when it sees a matching ATDT and number, it will
make the TCP connection to the relevant Internet host and then copy the
data between the local port and the connection to the remote host.

# Running as a Daemon
If you don't use the *-d* option, *tcpdial* will run as a daemon and log
to syslog using LOG_LOCAL0.

# String Option
Given that *tcpdial.pl* isn't a real modem, we can make it easier for humans.
You can now do:

```sh
$ tcpdial.pl -p 4000 -n decvax:simh.tuhs.org:5000 -n ihnp4:minnie.tuhs.org:5000
```

and in *L.sys* you can have:

```sh
#System  Times  Caller  Class  Device/Phone_Number      [Expect  Send]....
decvax Any;1 DIR 9600 tty00  "" "ATDSdecvax\r" CONNECT "" ogin:--ogin:--ogin: u
ucp ssword: uucp
ihnp4 Any;1 DIR 9600 tty00  "" "ATDSihnp4\r" CONNECT "" ogin:--ogin:--ogin: uu
cp ssword: uucp
```

The *S* in *ATDS* stands for "string".

# Status

As at 12th March 2017, the *tcpdial.pl* program is probably still fragile
and it needs some more error checking. I have added a daemon mode and
syslogging. I still think that it needs better checking for when one
end closes the connection.

Author: Warren Toomey
