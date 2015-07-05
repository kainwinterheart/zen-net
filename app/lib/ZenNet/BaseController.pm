package ZenNet::BaseController;

use Mojo::Base 'Mojolicious::Controller';

sub error {

    my ( $self, $msg ) = @_;

    return $self -> render( json => { error => $msg } );
}

1;

__END__
