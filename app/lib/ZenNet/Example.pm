package ZenNet::Example;

use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub welcome {

    my ( $self ) = @_;

    my $xml = $self -> new_xml( 'root' => 'asd' );

    $self -> render_xml( $xml );
    # Render template "example/welcome.html.ep" with message
    # $self -> render( msg => 'Welcome to the Mojolicious real-time web framework!' );
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
