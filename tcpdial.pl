#!/usr/bin/perl
#
# tcpdial: Act a bit like a Hayes modem. Listen on a local port. When
# we get an ATDT command plus a number, find a match for that number
# and make a TCP connection to the relevant remote host. Then copy
# data between the local port and the remote host. Example:
#
# $ tcpdial.pl -p 4000 \
#	-n 5551234:simh.tuhs.org:5000 -n 5556789:minnie.tuhs.org:5000
#
# will listen on localhost port 4000. An ATDT5551234 will connect to
# simh.tuhs.org port 5000. An ATDT5556789 will connect to
# minnie.tuhs.org port 5000
#
# (c) 2017, BSD 3-Clause License, Warren Toomey wkt@tuhs.org

use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;
use Sys::Syslog qw(:standard :macros);
use Proc::Daemon;
use Getopt::Long;
use Data::Dumper;

# flush after every write
$| = 1;

sub usage() {
    print( STDERR
          "Usage: $0 [-d] -p port -n number:remotesite:remoteport [ -n ...]\n"
    );
    exit(1);
}

# Get the command-line options
my $listenport = 0;
my $debug      = 0;
my @numberlist;

usage() if ( @ARGV < 1 );
GetOptions( "d" => \$debug, "p=i" => \$listenport, "n=s" => \@numberlist )
  or usage();
usage() if ( $listenport == 0 );
usage() if ( @numberlist == 0 );

# If we are not debugging, turn into a daemon and check that it worked
if ( !$debug ) {

    # Open the syslog
    openlog( "tcpdial", "pid", LOG_LOCAL0 );

    my $daemon = Proc::Daemon->new(
        work_dir => '/tmp',
        pid_file => 'tcpdial.pid'
    );

    $daemon->Init;
    my $pid = $daemon->Status(undef);

    if ( !$pid ) {
        Log( LOG_ERR, "Unable to start as a daemon, exiting" );
        exit(1);
    }
    Log( LOG_INFO, "Daemon started successfully" );
}

# Bind to the listenport
my $listensocket = new IO::Socket::INET(
    LocalHost => '127.0.0.1',
    LocalPort => $listenport,
    Proto     => 'tcp',
    Listen    => 5,
    Reuse     => 1
) or die "Cannot listen on TCP port $listenport: $!\n";

while (1) {

    # Wait for a new local connection
    Log( LOG_INFO, "Waiting for a local connection on port $listenport" );
    my $acceptsocket = $listensocket->accept();
    Log( LOG_INFO, "Accepted local connection on port $listenport" );

    # Fork a child to deal with the new request
    if (!fork()) {
      Log( LOG_INFO, "Forked a child to deal with the request" );
      handle_dial_request($acceptsocket); exit(0);
    }

    # Otherwise, go back and wait for a new local connection
    $acceptsocket->close();
}
exit(0);

# Copyloop: copy data from one socket to the other. Return when
# the connection is closed.
sub copyloop {
    my ( $port1, $port2 ) = @_;
    my $data;

    # Add the two sockets to a select object
    my $sel = IO::Select->new();
    $sel->add($port1);
    $sel->add($port2);

    while (1) {
        while ( my @ready = $sel->can_read ) {
            goto end if ( !$port1->connected() || !$port2->connected() );

            foreach my $fh (@ready) {
                if ( $fh == $port1 ) {

                    #print( STDERR "Reading from remote host\n" ) if ($debug);
                    $fh->recv( $data, 1024 );
                    goto end if ( $data eq '');
                    $port2->send($data);
                } else {

                    #print( STDERR "Reading from local port\n" ) if ($debug);
                    $fh->recv( $data, 1024 );
                    goto end if ( $data eq '');
                    $port1->send($data);
                }
            }
        }
    }

  end:
    $port1->close(); $port2->close(); return;
}

# Get_dial_command: get an ATDT line ending with CR from the local port
# Find the host and port that matches the given number and return it.
# Otherwise return undefs.
sub get_dial_command {
    my $port = shift;
    my $data = "";
    Log( LOG_INFO, "Waiting to get dial command from local SimH" );

    while (1) {
	#print(STDERR ".") if ($debug);

        # Get any new data, return if connection lost
        my $newdata;
        $port->recv( $newdata, 1024 );
	if ($newdata eq '') {
	  Log( LOG_INFO, "Lost local connection waiting for dial command");
	  $port->close(); return ( undef, undef );
	}

        # Drop any high bits to get plain ASCII
        $newdata =~ tr [\200-\377] [\000-\177];
        $data = $data . $newdata;

        #print(STDERR "newdata: " .  Dumper(\$newdata) ) if ($debug);
        #print(STDERR "data: " . Dumper( \$data ) ) if ($debug);

        # See if we have an ATDT command and parse it.
        # The regexp is general enough to allow, e.g. ATDSfreddo
        if ( $data =~ m{ATD[A-Z](.+)\r} ) {
            my $desirednum = $1;
            Log( LOG_INFO, "Trying to dial $desirednum" );
            foreach my $n (@numberlist) {
                my ( $num, $host, $port ) = split( /:/, $n );
                if ( $num eq $desirednum ) { return ( $host, $port ); }
            }

	    # No matching number, so give up
            Log( LOG_WARNING, "Unrecognised number/system $desirednum" );
            $port->close(); return ( undef, undef );
        }

        # Just accept other AT commands, toss this data out
        if ( $data =~ m{AT.*\r} ) {
            print( $port "OK\r\n" ); $data = "";
        }
    }
}

# Send log messages to stderr or syslog
sub Log {
    my ( $level, $mesg ) = @_;
    if ($debug) {
        print( STDERR $mesg . "\n" );
    } else {
        syslog( $level, $mesg );
    }
}

# As a child, get the dial command, place the call, copy the data
# and then exit. This function must not return!
sub handle_dial_request
{
    my $acceptsocket= shift;

    # Get the remote host and port, exit if none
    my ( $remotehost, $remoteport ) = get_dial_command($acceptsocket);
    exit(0) if ( !defined($remotehost) );

    # Try to connect to the remote host
    my $clientsocket = new IO::Socket::INET(
        PeerHost => $remotehost,
        PeerPort => $remoteport,
        Proto    => 'tcp',
    );

    # Could not connect, so close the local connection
    if ( !defined($clientsocket) ) {
        LOG( LOG_ERR, "Could not connect to $remotehost:$remoteport" );
        $acceptsocket->close();
        exit(0);
    }

    # Connected, tell the local dialer, then loop copying the data
    Log( LOG_INFO, "Connected to $remotehost:$remoteport" );
    print( $acceptsocket "CONNECT\r\n" );
    copyloop( $acceptsocket, $clientsocket );
    Log( LOG_INFO, "Connection to $remotehost:$remoteport closed" );
    exit(0);
}
