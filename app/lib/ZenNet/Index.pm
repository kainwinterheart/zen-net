package ZenNet::Index;

use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub index {

    my ( $self ) = @_;

    return $self -> render();
}

sub post {

    my ( $self ) = @_;

    my $json = $self -> req() -> json();

    my $id = $self -> model( 'test.test' ) -> insert(
        { text => $json -> { 'text' } }, { safe => 1 }
    );

    $self -> render( json => { id => $id -> value() } );
}

1;

__END__
