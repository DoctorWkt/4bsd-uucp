## Instructions for configuring Taylor UUCP to connect to decvax.

Ask the decvax administrator to authorize your site and provide login
and password information.  Then add this to your configuration files:

/etc/uucp/sys

    system decvax
    call-login *
    call-password *
    time any
    chat "" \d\d\r\c ogin: \d\L word: \P
    address simh.tuhs.org
    port TCP
    protocol g

/etc/uucp/port

    port TCP
    type tcp
    service 5001

/etc/uucp/call

    decvax    <login>    <password>

/etc/uucp/crontab

    01 * * * * /usr/sbin/uucico -r1 -Sdecvax

Sending email can be done with

    cat file | uux - 'decvax!rmail' '(path!to|recipient)'
