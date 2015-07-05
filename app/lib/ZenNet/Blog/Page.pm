package ZenNet::Blog::Page;

use Mojo::Base 'ZenNet::BaseController';

use constant {

    POSTS_ON_PAGE => 10,
    MAX_PREVIEW_SIZE => 1024,
};

sub list {

    my ( $self ) = @_;
    my $uid = ( $self -> session( 'uid' ) // '' );
    my $pageid = ( $self -> param( 'page' ) // '' );
    my $from_id = ( $self -> req() -> param( 'from' ) // '' );
    my $user = ( ( $pageid eq '' ) ? undef : $self -> model( 'users.list' ) -> find_one( {
        blog_pageid => $pageid,
    } ) );

    my @list = $self -> model( 'blog.posts' ) -> find( {
        ( defined $user ? ( uid => $user -> { '_id' } -> value() ) : () ),
        ( ( $from_id eq '' ) ? () : ( _id => { '$lte' => MongoDB::OID -> new( value => $from_id ) } ) ),

    } ) -> sort( { _id => -1 } ) -> limit( POSTS_ON_PAGE + 1 ) -> all();

    undef $from_id;

    if( scalar( @list ) > POSTS_ON_PAGE ) {

        $from_id = $list[ $#list ] -> { '_id' } -> value();
        pop( @list );
    }

    my %users = map( { $_ -> { '_id' } -> value() => $_ -> { 'blog_pageid' } }
        $self -> model( 'users.list' ) -> find(
            { _id => { '$in' => [ map( { MongoDB::OID -> new( value => $_ -> { 'uid' } ) }
                @list ) ] } } ) -> all() );

    return $self -> render( json => {
        posts => [ map( { my $post = $_; my $updated = $post -> { 'updated' }; {
            id => $post -> { '_id' } -> value(),
            map( { $_ => $post -> { $_ } } ( 'tags' ) ),
            updated => ( $updated -> ymd( '-' ) . ' ' . $updated -> hms( ':' ) ),
            blog => $users{ $post -> { 'uid' } },
            text => ( ( length( $post -> { 'text' } ) > ( MAX_PREVIEW_SIZE + 128 ) )
                ? ( substr( $post -> { 'text' }, 0, MAX_PREVIEW_SIZE ) . '...' )
                : $post -> { 'text' }
            ),
            can_edit => ( $uid eq $post -> { 'uid' } ),
        }; } @list ) ],
        ( defined $from_id ? ( next_page_from => $from_id ) : () ),
        ( defined $user ? ( only_this_blog => $user -> { 'blog_pageid' } ) : () ),
    } );
}

1;

__END__
