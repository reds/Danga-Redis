package Danga::Redis;
use common::sense;
use Danga::Socket;
use base ( 'Danga::Socket' );
use fields ( 'cmds', 'leftover' );
use IO::Socket;

1;

sub cmd_done {
    my ( $self ) = @_;
}

sub ping {
    my ( $self, $cb ) = @_;
    push @{$self->{cmds}}, { type => 'ping', cb => $cb || \&cmd_done };
    $self->write ( "ping\r\n" );
}

sub set {
    my ( $self, $key, $val, $cb ) = @_;
    return unless $self && $key && $val;
    my $l = length $val;
    push @{$self->{cmds}}, { type => 'set', cb => $cb || \&cmd_done };
    $self->write ( "set $key $l\r\n$val\r\n" );
}

sub get {
    my ( $self, $key, $cb, $cb_notset ) = @_;
    push @{$self->{cmds}}, { type => 'get', key => $key,
			     cb => $cb || \&cmd_done };
    $self->write ( "get $key\r\n" );
}

sub new {
    my ( $self, $host, $port ) = @_;
    $self = fields::new ( $self ) unless ref $self;
    $host = '127.0.0.1' unless $host;
    $port = 6379 unless $port;
    my $sock = IO::Socket::INET->new ( PeerAddr => "$host:$port" );
    $self->{leftover} = '';
    $self->SUPER::new ( $sock );
    $self->watch_read ( 1 );
    return $self;
}

sub event_err { my $self = shift; $self->close ( 'err' ); }
sub event_hub { my $self = shift; $self->close ( 'hub' ); }
sub event_write { my $self = shift; $self->close ( 'write' ); }
sub event_read { 
    my $self = shift; 
    my $r = $self->read ( 1024 * 1024 );
    my $buf = $self->{leftover} . $$r;
    $self->{leftover} = '';
    unless ( $$r ) {
	$self->close ( "read" );
	return;
    } else {
	while ( $buf ) {
	    my ( $r, $line, $rest ) = $buf =~ /(.)([^\r]+)\r\n(.*)/sm;
	    my $eat = 0;
	    my $cmd = shift @{$self->{cmds}};
	    given ( $r ) {
		when ( '-' ) {
		    # error
		    # single line
		    $eat += length ( $line ) + 3;
		}
		when ( '+' ) {
		    # single line
		    $eat += length ( $line ) + 3;
		}
		when ( ':' ) {
		    # integer
		    # single line
		    $eat += length ( $line ) + 3;
		}
		when ( '$' ) {
		    # bulk
		    if ( $line == -1 ) {
			$eat += length ( $line ) + 3;
		    } else {
			$eat += length ( $line ) + 3 + $line + 2;
			my $val = substr $rest, 0, $line;
			if ( $cmd->{type} eq 'get' && $cmd->{cb} ) {
			    $cmd->{cb} ( $cmd->{key}, $val );
			}
		    }
		}
		when ( '*' ) {
		    # bulk multi
		    if ( $line == -1 ) {
			$eat += length ( $line ) + 3;
		    } else {
			while ( $line-- ) {
			}
		    }
		}
	    }
	    $buf = substr $buf, $eat;
	}
    }
}
