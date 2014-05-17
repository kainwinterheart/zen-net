package ZenNet;

use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {

    my ( $self ) = @_;

    $self -> plugin( 'mongodb' => {
        host => 'mongodb://127.0.0.1:27017'
    } );

    # Router
    my $r = $self -> routes();

    # Normal route to controller
    $r -> get( '/' ) -> to( 'example#welcome' );
    $r -> post( '/' ) -> to( 'example#post' );
}

1;

__END__
