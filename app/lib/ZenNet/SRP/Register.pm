package ZenNet::SRP::Register;

use Mojo::Base 'ZenNet::BaseController';

use ZenNet::SRP::Utils ();

use Encode 'decode_utf8';
use DateTime ();
use Email::Valid ();


sub salt {

    my ( $self ) = @_;
    my $invite = $self -> model( 'users.invites' ) -> find_one( {
        _id => lc( decode_utf8( $self -> param( 'invite' ) ) ),
    } );

    unless( defined $invite ) {

        return $self -> error( 'Invalid invitation code' );
    }

    my $login = lc( decode_utf8( $self -> param( 'I' ) ) );

    unless( Email::Valid -> address( $login ) ) {

        return $self -> error( 'Invalid email' );
    }

    my $model = $self -> model( 'users.list' );
    my $salt  = undef;

    if( defined( my $user = $model -> find_one( { email => $login } ) ) ) {

        if(
            exists $user -> { 'verifier' }
            || ( $user -> { 'invite' } ne $invite -> { '_id' } )
        ) {

            return $self -> error( 'Login is already taken' );

        } else {

            $salt = $user -> { 'salt' };
        }
    }

    unless( $salt ) {

        $salt = ZenNet::SRP::Utils -> salt();

        my $now = DateTime -> now();
        my $pid_model = $self -> model( 'blog.pageid' );
        my $pid = $pid_model -> insert( { time => $now } ) -> value();

        $model -> insert( {
            email => $login,
            salt => $salt,
            created => $now,
            blog_pageid => $pid,
            invite => $invite -> { '_id' },

        }, { safe => 1 } );
    }

    $self -> session( srp_login => $login );
    $self -> session( srp_salt => $salt );

    return $self -> render( json => { salt => $salt } );
}

sub user {

    my ( $self ) = @_;

    my $verifier = $self -> param( 'v' );

    unless( $verifier ) {

        return $self -> error( 'Invalid verifier' );
    }

    my $login = $self -> session( 'srp_login' );
    my $salt = $self -> session( 'srp_salt' );

    my $model = $self -> model( 'users.list' );

    my $user = $model -> find_one( { email => $login, salt => $salt } );

    unless( defined $user ) {

        return $self -> error( 'No such user' );
    }

    if( exists $user -> { 'verifier' } ) {

        return $self -> error( 'Login is already taken' );
    }

    $model -> update(
        { _id => $user -> { '_id' } },
        { '$set' => { verifier => $verifier } },
        { safe => 1 }
    );

    delete $self -> session() -> { 'srp_login' };
    delete $self -> session() -> { 'srp_salt' };

    $self -> model( 'users.invites' ) -> remove( {
        _id => $user -> { 'invite' },

    }, { safe => 1 } );

    return $self -> render( json => {} );
}

1;

__END__
