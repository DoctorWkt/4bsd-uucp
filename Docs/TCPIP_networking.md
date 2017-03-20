# Setting up NAT on 4.3BSD with SimH

The whole point of this project is to rebuild a uucp network. That said,
it's easier to move things in and out of your simulated 4.3BSD system
with a TCP/IP tool. Here's how to do it.

In your SimH .ini file, add these lines near the top:

```
set xu enable
att xu nat:
```

to set up an `xu` device and run it in NAT mode. This will provide
you with a limited set of internal IP addresses. See the SimH
documentation for more details.

In your 4.3BSD system's `/etc/rc.local`, add these lines:

```
/etc/ifconfig en0 `hostname`		# Line already there
/etc/ifconfig de0 10.0.2.4 netmask 255.255.255.0
/etc/route add net 0.0.0.0 10.0.2.2 1
```

Now you have a working Ethernet interface; pings don't work however.

Using the tape method, download an ftp client with PASV mode from
<http://www.tuhs.org/Uucp/43BSD_Apps/Historical/pasv_ftp_client.tar.gz>,
build and install it.

In your simulated 4.3BSD, you might want to add some hostnames to your
`/etc/hosts` file, e.g.

```
10.10.1.8       fred fred.local.net
```

Now set up an ftp server on your host machine. I used vsftp. I
changed a few config lines in `/etc/vsftpd.conf`:

```
local_enable=YES
write_enable=YES
```

Here's a capture of the working ftp session:

```
$ ftp mythbox
Connected to mythbox.
220 (vsFTPd 2.3.5)
Name (mythbox:wkt): 
331 Please specify the password.
Password:
230 Login successful.
ftp> dir
227 Entering Passive Mode (10,10,1,8,127,33).
150 Here comes the directory listing.
drwxrwxr-x    5 1000     1000         4096 Mar 20 21:31 4bsd-uucp
drwxr-xr-x    2 1000     1000         4096 Oct 01 20:50 Desktop
...
-rw-r--r--    1 1000     1000         1413 Mar 20 22:43 id.c
226 Directory send OK.
924 bytes received in 0.0069 seconds (1.3e+02 Kbytes/s)
ftp> get id.c
227 Entering Passive Mode (10,10,1,8,105,30).
150 Opening BINARY mode data connection for id.c (1413 bytes).
226 Transfer complete.
local: id.c remote: id.c
1413 bytes received in 0.014 seconds (99 Kbytes/s)
ftp> quit
221 Goodbye.
```
