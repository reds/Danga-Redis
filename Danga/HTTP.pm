use common::sense;

my $t = Danga::HTTP->new;

$t->get ( "/twitter", { a => 'b', b => 'jfidf jfidf omfodf' } );

package Danga::HTTP;
use Danga::Socket;
use base ( 'Danga::Socket' );
use fields ();
use URI;
use HTTP::Request;

sub new {
    my $self = shift;
    my $sock = shift;
    $self = fields::new ( $self ) unless ref $self;
#    $self->SUPER::new ( $sock );
#    $self->watch_read ( 1 );
    return $self;
}

sub get {
    my ( $self, $uri, $args, $headers ) = @_;
    my $u = URI->new ( $uri );
    $u->query_form ( $args );
    my @headers = ( 'Host', 'twitter.com', 'User-Agent', 'Danga::HTTP 0.1', 'Accept', '*/*' );
    if ( ref $headers eq 'HASH' ) {
	foreach ( keys %$headers ) {
	    push @headers, $_, $headers->{$_};
	}
    }

    my $r = HTTP::Request->new( 'GET', $u, \@headers );
    say "uri: ", $r->as_string;
}

sub post {
    my ( $self, $uri, $args, $headers, $content ) = @_;
    my $u = URI->new ( $uri );
    $u->query_form ( $args );
    my $s = $u->as_string;
    my $r = HTTP::Request->new( 'GET', $uri, $headers, $content );
    say "uri: ", $r->as_string;
}

