package ZenNet::Initializers::Router;

use strict;
use warnings;

sub main {

    my ( $self, $r ) = @_;

    $r -> get( '/' ) -> to( 'index#index' );
    $r -> get( '/i' ) -> to( 'index#real_index' );
    $r -> get( '/logout' ) -> to( 'index#logout' );

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

    $r -> get( '/blog' ) -> to(
        controller => 'Blog::Page',
        action => 'list'
    );

    $r -> get( '/blog/u/:page' ) -> to(
        controller => 'Blog::Page',
        action => 'list'
    );

    $r -> get( '/blog/t/#tag' ) -> to(
        controller => 'Blog::Page',
        action => 'list_by_tag'
    );

    $r -> get( '/blog/p/:id' ) -> to(
        controller => 'Blog::Post',
        action => 'open'
    );

    $r -> post( '/blog/e/:id' ) -> to(
        controller => 'Blog::Post',
        action => 'edit'
    );

    $r -> post( '/blog/new' ) -> to(
        controller => 'Blog::Post',
        action => 'create'
    );

    return;
}

1;

__END__
