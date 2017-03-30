# Running UUCP Over TCP

While the goal of this project is to build a retro-simulation of the uucp
network as it stood in the mid-1980s (with dialup lines), it turns out that
the transfer speeds bewteen sites is very low. One reason is that the 'g'
protocol maxes out at around 9,600 bps, according to
[http://minnie.tuhs.org/cgi-bin/utree.pl?file=4.3BSD/usr/src/usr.bin/uucp/README.TCP](this documentation).

Therefore, while we still want to have sites "dialling" other sites
directly, we can do this by running the 4.3BSD uucp links over TCP.

# Setting Up UUCP Over TCP

Assume you have two 4.3BSD uucp sites, *site5* and *site6*. They are running
as guests on these host machines:

- site5 running on host 5.5.5.5
- site6 running on host 6.6.6.6

Edit the SimH .ini files for both. Change the "attach xu nat" line to say:

```
  attach xu nat:tcp=5400:10.0.2.4:540
```

This forwards the 4.3BSD TCP port 540 out to be visible as port 5400 on the
host. I'm using 5400 not 540 so I don't have to run SimH as root.

Restart both *site5* and *site6* in SimH. Go into `/dev` and make some ptys:

```
  sh MAKEDEV pty0
  sh MAKEDEV pty1
```

Edit `/etc/inetd.conf` and uncomment the uucpd line:

```
  # Run as user "uucp" if you don't want uucpd's wtmp entries.
  uucp    stream  tcp     nowait  root    /etc/uucpd      uucpd
```
Restart `/etc/inetd`:

```
  kill <inetd's pid>
  /etc/inetd
```

In each site's `/etc/host`, add entries for the other site:

```
  5.5.5.5      site5
```

and

```
  6.6.6.6      site6
```

At this point, you should be able to *telnet* to the uucpd on the other site,
e.g.

```
  # On site5
  telnet site5 5400
```

and you will get a *login:* prompt. Use *ctrl-] q* to exit *telnet*.

In each site's `L.sys` file, change the line that describes the other site:

```
  site6 Any TCP 5400 site6 ogin:--ogin:--ogin: uucp ssword: uucp
```

and

```
  site5 Any TCP 5400 site5 ogin:--ogin:--ogin: uucp ssword: uucp
```
    
That's it. You should now be able to run *uucico* and exchange uucp files:
    
```
  # On site5
  echo hello | mail site6\!root

  uucico -r1 -x7 -ssite6
  root site6 (3/28-22:16-241) DEBUG (Local Enabled)
  finds (site6) called
  getto: call no. site6 for sys site6
  Using TCP to call
  bsdtcpopn host site6, port 5406
  login called
  wanted "ogin:"
  login:got: that
  send "uucp"
  wanted "ssword:"
   Password:got: that
  send "uucp"
  root site6 (3/28-22:16-241) SUCCEEDED (call to site6 )
  TCPIP connection -- ioctl-s disabled
  imsg looking for SYNC< \20>
  ...
  Rmtname site6, Role MASTER,  Ifn - 5, Loginuser - root
  rmesg - 'P' imsg looking for SYNC<\20>
  imsg input<Ptfg\0>got 4 characters
  got Ptfg
  wmesg 'U' t
  omsg <Ut>
  Proto started t
  protocol t
  root site6 (3/28-22:16-241) OK (startup)
  ...
  daemon site6 (3/28-22:16-241) OK (conversation complete)
  send OO 0,omsg <OOOOOO>
  imsg looking for SYNC<\20>
  imsg input<OOOOOO\0>got 6 characters
  TCP CLOSE called
  closed fd 5
```
