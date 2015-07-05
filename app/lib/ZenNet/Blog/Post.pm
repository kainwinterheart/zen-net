package ZenNet::Blog::Post;

use Mojo::Base 'ZenNet::BaseController';

use Encode 'decode_utf8';
use DateTime ();
use MongoDB::OID ();

use constant {

    MAX_POST_SIZE => 10 * 1024 * 1024,
    MAX_TAGS_SIZE => 2 * 1024 * 1024,
};


sub create {

    my ( $self ) = @_;
    my $uid = $self -> session( 'uid' );

    return $self -> error( 'Only for registered users' ) unless $uid;

    ( my $text = decode_utf8( $self -> req() -> param( 'text' ) // '' ) ) =~ s/^\s+|\s+$//g;

    if( $text eq '' ) {

        return $self -> error( 'No text' );
    }

    if( bytes::length( $text ) > MAX_POST_SIZE ) {

        return $self -> error( 'Text is too big' );
    }

    my @tags = grep( { $_ ne '' } map( { $_ =~ s/^\s+|\s+$//g; lc( decode_utf8( $_ ) ) }
        @{ $self -> req() -> every_param( 'tag' ) // [] } ) );

    if( bytes::length( join( '', @tags ) ) > MAX_TAGS_SIZE ) {

        return $self -> error( 'Too much tags' );
    }

    my $now = DateTime -> now();
    my $post_id = $self -> model( 'blog.posts' ) -> insert( {
        created => $now,
        updated => $now,
        text => $text,
        tags => \@tags,
        uid => $uid,
        version => 1,

    }, { safe => 1 } ) -> value();

    $self -> update_tags( $post_id, \@tags ) if( scalar( @tags ) > 0 );

    return $self -> render( json => { id => $post_id } );
}

sub edit {

    my ( $self ) = @_;
    my $uid = $self -> session( 'uid' );

    return $self -> error( 'Only for registered users' ) unless $uid;

    my $post_id = ( $self -> param( 'id' ) // '' );

    return $self -> error( 'No post id specified' ) unless $post_id;

    ( my $text = decode_utf8( $self -> req() -> param( 'text' ) // '' ) ) =~ s/^\s+|\s+$//g;

    if( $text eq '' ) {

        return $self -> error( 'No text' );
    }

    if( bytes::length( $text ) > MAX_POST_SIZE ) {

        return $self -> error( 'Text is too big' );
    }

    my @tags = grep( { $_ ne '' } map( { $_ =~ s/^\s+|\s+$//g; lc( decode_utf8( $_ ) ) }
        @{ $self -> req() -> every_param( 'tag' ) // [] } ) );

    if( bytes::length( join( '', @tags ) ) > MAX_TAGS_SIZE ) {

        return $self -> error( 'Too much tags' );
    }

    my $oid = MongoDB::OID -> new( value => $post_id );
    my $version = int( $self -> param( 'version' ) // 0 );
    my $model = $self -> model( 'blog.posts' );
    my $prev = $model -> find_one( { _id => $oid, uid => $uid, version => $version } );

    return $self -> error( 'No such post' ) unless defined $prev;

    delete( $prev -> { '_id' } );
    $prev -> { 'post_id' } = $post_id;

    $self -> model( 'archive.posts' ) -> insert( $prev );

    $model -> update( { _id => $oid, uid => $uid, version => $version }, {
        '$set' => {
            version => ( $version + 1 ),
            text => $text,
            tags => \@tags,
            updated => DateTime -> now(),
        },
    }, { safe => 1 } );

    my %new_tags = map( { $_ => 1 } @tags );
    my @delete_tags = grep( { ! exists $new_tags{ $_ } } @{ $prev -> { 'tags' } // [] } );

    my %old_tags = map( { $_ => 1 } @{ $prev -> { 'tags' } // [] } );
    my @add_tags = grep( { ! exists $old_tags{ $_ } } @tags );

    $self -> update_tags( $post_id, \@add_tags ) if( scalar( @add_tags ) > 0 );

    if( scalar( @delete_tags ) > 0 ) {

        $self -> model( 'tags.posts' ) -> remove( {
            tag => { '$in' => \@delete_tags },
            post => $post_id,

        }, { safe => 1 } );

        my $op = $self -> model( 'tags.tags' ) -> initialize_unordered_bulk_op();

        foreach my $tag ( @delete_tags ) {

            $op -> find( { _id => $tag } ) -> update_one( { '$inc' => { c => -1 } } );
        }

        $op -> execute();
    }

    return $self -> render( json => { id => $post_id } );
}

sub open {

    my ( $self ) = @_;
    my $uid = ( $self -> session( 'uid' ) // '' );
    my $post_id = ( $self -> param( 'id' ) // '' );
    my $post = $self -> model( 'blog.posts' ) -> find_one(
        { _id => MongoDB::OID -> new( value => $post_id ) } );

    return $self -> error( 'No such post' ) unless defined $post;

    my $user = $self -> model( 'users.list' ) -> find_one(
        { _id => MongoDB::OID -> new( value => $post -> { 'uid' } ) } );

    my $updated = $post -> { 'updated' };

    return $self -> render( json => {
        id => $post_id,
        map( { $_ => $post -> { $_ } } ( 'text', 'tags', 'version' ) ),
        updated => ( $updated -> ymd( '-' ) . ' ' . $updated -> hms( ':' ) ),
        blog => $user -> { 'blog_pageid' },
        can_edit => ( $uid eq $post -> { 'uid' } ),
    } );
}

sub update_tags {

    my ( $self, $post_id, $tags ) = @_;

    my $op = $self -> model( 'tags.tags' ) -> initialize_unordered_bulk_op();

    foreach my $tag ( @$tags ) {

        $op -> find( { _id => $tag } ) -> upsert() -> update_one( { '$inc' => { c => 1 } } );
    }

    $op -> execute();

    $self -> model( 'tags.posts' ) -> batch_insert(
        [ map( { { tag => $_, post => $post_id }; } @$tags ) ], { safe => 1 } );

    return;
}


1;

__END__
