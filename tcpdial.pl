#!/usr/bin/perl
#
# tcpdial: Act a bit like a Hayes modem. Listen on a local port. When
# we get an ATDT command plus a number, find a match for that number
# and make a TCP connection to the relevant remote host. Then copy
# data between the local port and the remote host. Example:
#
# $ tcpdial.pl -p 4000 -n 5551234:simh.tuhs.org:5000 -n 5556789:minnie.tuhs.org:5000
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
use Getopt::Long;
use Data::Dumper;

# flush after every write
$| = 1;

sub usage() {
    print( STDERR
          "Usage: $0 -p port -n number:remotesite:remoteport [ -n ...]\n" );
    exit(1);
}

# Get the command-line options
my $listenport = 0;
my @numberlist;

usage() if ( @ARGV < 1 );
GetOptions( "p=i" => \$listenport, "n=s" => \@numberlist ) or usage();
usage() if ( $listenport == 0 );
usage() if ( @numberlist == 0 );

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
    my $acceptsocket = $listensocket->accept();
    print( STDERR "Accepted local connection on port $listenport\n" );

    # Get the remote host and port, Loop back if none
    my ( $remotehost, $remoteport ) = get_dial_command($acceptsocket);
    next if ( !defined($remotehost) );

    # Try to connect to the remote host
    my $clientsocket = new IO::Socket::INET(
        PeerHost => $remotehost,
        PeerPort => $remoteport,
        Proto    => 'tcp',
    );

    # Could not connect, so close the local connection
    if ( !defined($clientsocket) ) {
        print( STDERR "Could not connect to $remotehost:$remoteport\n" );
        $acceptsocket->close();
        next;
    }

    # Connected, tell the local dialer, then loop copying the data
    print( STDERR "Connected to $remotehost:$remoteport\n" );
    print( $acceptsocket "CONNECT\r\n" );
    copyloop( $acceptsocket, $clientsocket );
    print( STDERR "Connection closed\n" );
}
exit(0);

# Copyloop: copy data from one socket to the other. Return when
# the connection is closed.
sub copyloop {
    my ( $port1, $port2 ) = @_;

    # Add the two sockets to a select object
    my $sel = IO::Select->new();
    $sel->add($port1);
    $sel->add($port2);
    my $data;

    while (1) {
        while ( my @ready = $sel->can_read ) {
            goto end if ( !$port1->connected() || !$port2->connected() );

            foreach my $fh (@ready) {
                if ( $fh == $port1 ) {

                    #print( STDERR "Reading from remote host\n" );
                    $fh->recv( $data, 1024 );
                    $port2->send($data);
                    goto end if ( $data =~
			m{Disconnected from the VAX 11/780 simulator} );
                }
                else {

                    #print( STDERR "Reading from local port\n" );
                    $fh->recv( $data, 1024 );
                    $port1->send($data);
                    goto end if ($data =~
			m{Disconnected from the VAX 11/780 simulator} );
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
    print( STDERR "Waiting to get dial command\n" );

    while (1) {

        # Get any new data, return if connection lost
        my $newdata;
        $port->recv( $newdata, 1024 );

        # Drop any high bits to get plain ASCII
        $newdata =~ tr [\200-\377] [\000-\177];

        #print(STDERR "newdata: " . Dumper(\$newdata) );
        if ( !defined($newdata) ) { return ( undef, undef ); }

        $data = $data . $newdata;
        #print( STDERR "data: " . Dumper( \$data ) );

	# Deal with disconnections from the local SimH system
        if ( $data =~ m{Disconnected from the VAX 11/780 simulator} ) {
	    $port->close(); return ( undef, undef );
        }

        # See if we have an ATDT command and parse it.
	# The regexp is general enough to allow, e.g. ATDSfreddo
        if ( $data =~ m{ATD[A-Z](.*+)\r} ) {
            my $desirednum = $1;
            print( STDERR "Trying to dial $desirednum\n" );
            foreach my $n (@numberlist) {
                my ( $num, $host, $port ) = split( /:/, $n );
                if ( $num eq $desirednum ) { return ( $host, $port ); }
            }
	    $port->close();
            return ( undef, undef );
        }

        # Just accept other AT commands, toss this data out
        if ( $data =~ m{AT.*\r} ) {
            print( $port "OK\r\n" );
            $data = "";
        }
    }
}
