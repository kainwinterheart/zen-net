package ZenNet::Blog::Page;

use Mojo::Base 'ZenNet::BaseController';

use JSON ();
use Encode 'decode_utf8';
use MongoDB::OID ();

use constant {

    TAGS_ON_PAGE => 100,
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

    return $self -> render( json => {
        posts => $self -> render_posts( $uid, \@list ),
        ( defined $from_id ? ( next_page_from => $from_id ) : () ),
        ( defined $user ? ( only_this_blog => $user -> { 'blog_pageid' } ) : () ),
        logged_in => !! $uid,
    } );
}

sub list_by_tag {

    my ( $self ) = @_;
    my $uid = ( $self -> session( 'uid' ) // '' );
    ( my $tag = lc( decode_utf8( $self -> param( 'tag' ) // '' ) ) ) =~ s/^\s+|\s+$|\///g;
    ( my $subtags = lc( decode_utf8( $self -> param( 'subtags' ) // '' ) ) ) =~ s/^\s+|\s+$//g;
    my $from_id = ( $self -> req() -> param( 'from' ) // '' );

    $subtags =~ s/\/{2,}/\//g;
    $tag .= "/${subtags}" if length( $subtags ) > 0;

    my @list = $self -> model( 'tags.posts' ) -> find( {
        tag => $tag,
        ( ( $from_id eq '' ) ? () : ( post => { '$lte' => MongoDB::OID -> new( value => $from_id ) } ) ),

    } ) -> sort( { post => -1 } ) -> limit( POSTS_ON_PAGE + 1 ) -> all();

    undef $from_id;

    if( scalar( @list ) > POSTS_ON_PAGE ) {

        $from_id = $list[ $#list ] -> { 'post' } -> value();
        pop( @list );
    }

    @list = $self -> model( 'blog.posts' ) -> find( {
        _id => { '$in' => [ map( { $_ -> { 'post' } } @list ) ] },

    } ) -> sort( { _id => -1 } ) -> all();

    my $tags_model = $self -> model( 'tags.tags' );
    my @tags = $tags_model -> find( {
        c => { '$gt' => 0 },
        l => ( $tags_model -> find_one( { _id => $tag } ) -> { 'l' } + 1 ),
        p => $tag,

    } ) -> sort( { c => -1 } ) -> limit( TAGS_ON_PAGE ) -> all();

    return $self -> render( json => {
        posts => $self -> render_posts( $uid, \@list ),
        tags => [ map( { $_ -> { '_id' } } @tags ) ],
        ( defined $from_id ? ( next_page_from => $from_id ) : () ),
        only_this_tag => $tag,
        logged_in => !! $uid,
    } );
}

sub render_posts {

    my ( $self, $uid, $list ) = @_;

    my %users = map( { $_ -> { '_id' } -> value() => $_ -> { 'blog_pageid' } }
        $self -> model( 'users.list' ) -> find(
            { _id => { '$in' => [ map( { MongoDB::OID -> new( value => $_ -> { 'uid' } ) }
                @$list ) ] } } ) -> all() );

    return [ map( {
        my $post = $_;
        my $updated = $post -> { 'updated' };
        my $trimmed = 0;

        if( length( $post -> { 'text' } ) > ( MAX_PREVIEW_SIZE + 128 ) ) {

            $post -> { 'text' } = substr( $post -> { 'text' }, 0, MAX_PREVIEW_SIZE );
            $trimmed = 1;
        }

        {
            id => $post -> { '_id' } -> value(),
            map( { $_ => $post -> { $_ } } ( 'tags' ) ),
            updated => ( $updated -> ymd( '-' ) . ' ' . $updated -> hms( ':' ) ),
            blog => $users{ $post -> { 'uid' } },
            text => $post -> { 'text' },
            can_edit => ( $uid eq $post -> { 'uid' } ),
            trimmed => $trimmed,
        };

    } @$list ) ];
}

1;

__END__
