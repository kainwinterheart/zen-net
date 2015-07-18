package ZenNet::Index;

use Mojo::Base 'ZenNet::BaseController';

use constant {

    TAGS_ON_PAGE => 100,
};

# This action will render a template
sub index {

    my ( $self ) = @_;

    $self -> stash( logged_in => ( $self -> session( 'uid' ) ? 1 : 0 ) );
    $self -> stash( rev => $self -> app() -> cget( 'rev' ) );

    return $self -> render();
}

sub real_index {

    my ( $self ) = @_;

    my @list = $self -> model( 'tags.tags' ) -> find( {
        c => { '$gt' => 0 },
        l => 0,

    } ) -> sort( { c => -1 } ) -> limit( TAGS_ON_PAGE ) -> all();

    return $self -> render( json => {
        tags => [ map( { $_ -> { '_id' } } @list ) ],
        logged_in => !! $self -> session( 'uid' ),
    } );
}

sub logout {

    my ( $self ) = @_;

    delete( $self -> session() -> { 'uid' } );

    return $self -> redirect_to( '/' );
}

1;

__END__
