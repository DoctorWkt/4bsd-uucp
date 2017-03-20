# Monitoring and Debugging your UUCP and News Services

*This is just a grab-bag of things that you can look at and do. If anybody
else has good things to add, feel free to add them or do a pull request*

# Monitoring Commands

Do `uuq -l` to look at the current list of queued uucp jobs. 

Do `mailq` to look at any queued mail jobs.

What about the news system?

# Log Files

Look at:
- `/usr/spool/uucp/LOGFILE` for uucp logs. Look for FAILED connections.
- `/usr/spool/uucp/SYSLOG` for system logs
- `/usr/spool/mqueue/syslog` for mail logs (?)
- `/usr/adm` seems to be the old equivalent of `/var/log`
- What to look at for news events?

# Debug Commands

You can do `/usr/lib/uucp/uucico -r1 -ssystem -x7` to run a uucp connection to
the *system* uucp site and see what happens.

I've found that you are not allowed to redial the system until a set time,
look in the `/usr/spool/uucp/STST` directory and delete the relevant file.

You can force a uucp dial, I think as an ordinary user, by doing
`uupoll system`, which runs `uucico -r1 -ssystem`.

The `sa` commands looks useful, I need to work out how to use it.

`ps auxw` is obviously a command to do to see what processes are running.

More commands etc. needed here.
