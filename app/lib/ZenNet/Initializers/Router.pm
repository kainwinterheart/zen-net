package ZenNet::Initializers::Router;

use strict;
use warnings;

sub main {

    my ( $self, $r ) = @_;

    $r -> get( '/' ) -> to( 'index#index' );
    $r -> post( '/' ) -> to( 'index#post' );

    $r -> post( '/srp/register/salt' ) -> to(
        controller => 'SRP::Register',
        action => 'salt'
    );

    $r -> post( '/srp/register/user' ) -> to(
        controller => 'SRP::Register',
        action => 'user'
    );

    $r -> post( '/srp/handshake' ) -> to(
        controller => 'SRP::Authenticate',
        action => 'handshake'
    );

    $r -> post( '/srp/authenticate' ) -> to(
        controller => 'SRP::Authenticate',
        action => 'authenticate'
    );

    return;
}

1;

__END__
