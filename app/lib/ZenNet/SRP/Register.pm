package ZenNet::SRP::Register;

use Mojo::Base 'Mojolicious::Controller';

use ZenNet::SRP::Utils ();

use Email::Valid ();

use Encode 'decode_utf8';


sub salt {

    my ( $self ) = @_;

    my $login = lc( decode_utf8( $self -> param( 'I' ) ) );

    unless( Email::Valid -> address( $login ) ) {

        return $self -> error( 'Invalid email' );
    }

    my $model = $self -> model( 'users.list' );
    my $salt  = undef;

    if( defined( my $user = $model -> find_one( { email => $login } ) ) ) {

        if( exists $user -> { 'verifier' } ) {

            return $self -> error( 'Login is already taken' );

        } else {

            $salt = $user -> { 'salt' };
        }
    }

    unless( $salt ) {

        $salt = ZenNet::SRP::Utils -> salt();

        $model -> insert( {
                email => $login,
                salt => $salt,
                created => time(),
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

    return $self -> render( json => {} );
}

sub error {

    my ( $self, $msg ) = @_;

    return $self -> render( json => { error => $msg } );
}

1;

__END__
