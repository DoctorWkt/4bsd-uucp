# Instructions for configuring Taylor UUCP and INN to connect to a 4.3BSD site

Here is how to connect your Linux (or other) box running Taylor UUCP and INN
to a 4.3BSD SimH instance running uucp and C News.

Ask the remote site administrator to authorize your site and provide login and
password information.  Then add this to your Taylor UUCP configuration files
(e.g. for remote site *decvax*, which is at *simh.tuhs.org* port 5001):

```
/etc/uucp/sys

    system decvax
    call-login *
    call-password *
    time any
    chat "" \d\d\r\c ogin: \d\L word: \P
    address simh.tuhs.org
    port TCP
    protocol g
```

```
/etc/uucp/port

    port TCP
    type tcp
    service 5001
```

```
/etc/uucp/call

    decvax    <login>    <password>
```

```
/etc/uucp/crontab

    01 * * * * /usr/sbin/uucico -r1 -Sdecvax
```

Sending email can be done with

```
$ cat file | uux - 'decvax!rmail' '(path!to|recipient)'
```

You can also push the *uucp* queue with

```
$ sudo uupoll decvax
```

# Configuring News with INN

Make changes to these config files:

```
/etc/news/newsfeeds

    decvax:*:Tf,Wnb,B4096/1024:
```

```
/etc/news/send-uucp.cf

    decvax         none            1048576
```

You now need to tell *inn* to begin sending news to *decvax*:

```
$ sudo ctlinnd begin decvax
```

Use a news reader like *trn* to create some news. Then you can queue
the news and actually transmit the news with:

```
$ sudo /usr/lib/news/bin/send-uucp.pl decvax
$ sudo uupoll decvax
```

I haven't done this yet, but I'm guessing entries like this should be ok:

```
0 *    * * *   news	/usr/lib/news/bin/send-uucp.pl decvax
3 *    * * *   uucp	/usr/sbin/uucico -r1 -sdecvax
```
