package ZenNet::Initializers::Router;

use strict;
use warnings;

sub main {

    my ( $self, $r ) = @_;

    $r -> get( '/' ) -> to( 'example#welcome' );
    $r -> post( '/' ) -> to( 'example#post' );

    $r -> get( '/srp/register/salt' ) -> to(
        controller => 'SRP::Register',
        action => 'salt'
    );

    $r -> get( '/srp/register/user' ) -> to(
        controller => 'SRP::Register',
        action => 'user'
    );

    $r -> get( '/srp/handshake' ) -> to(
        controller => 'SRP::Authenticate',
        action => 'handshake'
    );

    $r -> get( '/srp/authenticate' ) -> to(
        controller => 'SRP::Authenticate',
        action => 'authenticate'
    );

    return;
}

1;

__END__
