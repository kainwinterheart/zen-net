package ZenNet::Blog::Post;

use Mojo::Base 'ZenNet::BaseController';

use utf8;
use boolean;

use JSON 'decode_json';
use Encode 'decode_utf8';
use DateTime ();
use MongoDB::OID ();
use Salvation::TC ();

use Salvation::TC::Utils;

subtype 'BlogPostTagsTree',
    as 'ArrayRef[HashRef( ! Str{1,} :name!, ArrayRef :tags )]',
    where {
        Salvation::TC -> is( $_, 'ArrayRef[HashRef( BlogPostTagsTree :tags )]' )
    };

no Salvation::TC::Utils;

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

    my $tags = ( $self -> get_tags() // [] );

    return $self -> error( $tags ) unless ref( $tags );

    my $now = DateTime -> now();
    my $post_id = $self -> model( 'blog.posts' ) -> insert( {
        created => $now,
        updated => $now,
        text => $text,
        tags => $tags,
        uid => $uid,
        version => 1,

    }, { safe => 1 } ) -> value();

    $self -> update_tags( $post_id, $tags ) if( scalar( @$tags ) > 0 );

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

    my $tags = ( $self -> get_tags() // [] );

    return $self -> error( $tags ) unless ref( $tags );

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
            tags => $tags,
            updated => DateTime -> now(),
        },
    }, { safe => 1 } );

    if( Salvation::TC -> is( $prev -> { 'tags' }, 'ArrayRef[Str]' ) ) {

        undef( $prev -> { 'tags' } );
    }

    my $tag_changes = $self -> compare_tags(
        old => ( $prev -> { 'tags' } // [] ),
        new => $tags,
    );

    $self -> update_tags( $post_id, $tag_changes ) if defined $tag_changes;

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
        logged_in => !! $uid,
    } );
}

sub update_tags {

    my ( $self, $post_id, $tags ) = @_;

    my $tags_op = $self -> model( 'tags.tags' ) -> initialize_unordered_bulk_op();
    my $posts_op = $self -> model( 'tags.posts' ) -> initialize_unordered_bulk_op();

    $self -> add_tags(
        post_id => $post_id,
        tags => $tags,
        tags_op => $tags_op,
        posts_op => $posts_op,
        id_prefix => undef,
        tag_level => 0,
    );

    $_ -> execute() for $tags_op, $posts_op;

    return;
}

sub add_tags {

    my ( $self, %args ) = @_;
    my ( $post_id, $tags, $tags_op, $posts_op, $id_prefix, $tag_level ) =
        @args{ 'post_id', 'tags', 'tags_op', 'posts_op', 'id_prefix', 'tag_level' };

    my @stack = ( $tags );

    while( defined( my $node = shift( @stack ) ) ) {

        my $ref = ref( $node );

        if( $ref eq 'CODE' ) {

            unshift( @stack, $node -> () );

        } elsif( $ref eq 'ARRAY' ) {

            foreach my $tag ( @$node ) {

                my $id = ( ( defined $id_prefix ? "${id_prefix}/" : '' ) . $tag -> { 'name' } );

                $tags_op -> find( { _id => $id } ) -> upsert() -> update_one( {
                    '$inc' => { c => 1 },
                    '$set' => {
                        l => $tag_level,
                        ( defined $id_prefix ? ( p => $id_prefix ) : () ),
                    },
                } );

                $posts_op -> find( { _id => "${post_id}/${id}" } ) -> upsert() -> update_one( {
                    '$set' => {
                        post => MongoDB::OID -> new( value => $post_id ),
                        tag => $id,
                    },
                } );

                if( exists $tag -> { 'tags' } ) {

                    $self -> add_tags(
                        post_id => $post_id,
                        tags => $tag -> { 'tags' },
                        tags_op => $tags_op,
                        posts_op => $posts_op,
                        id_prefix => $id,
                        tag_level => ( $tag_level + 1 ),
                    );
                }
            }

        } elsif( $ref eq 'HASH' ) {

            if( exists $node -> { 'removed' } ) {

                $self -> remove_tags(
                    post_id => $post_id,
                    tags => $node -> { 'removed' },
                    tags_op => $tags_op,
                    posts_op => $posts_op,
                    id_prefix => $id_prefix,
                    tag_level => $tag_level,
                );
            }

            if( exists $node -> { 'added' } ) {

                push( @stack, $node -> { 'added' } );
            }

            if( exists $node -> { 'modified' } ) {

                foreach my $tag ( @{ $node -> { 'modified' } } ) {

                    $self -> add_tags(
                        post_id => $post_id,
                        tags => $tag -> { 'tags' },
                        tags_op => $tags_op,
                        posts_op => $posts_op,
                        id_prefix => (
                            ( defined $id_prefix ? "${id_prefix}/" : '' )
                            . $tag -> { 'name' }
                        ),
                        tag_level => ( $tag_level + 1 ),
                    );
                }
            }
        }
    }

    return;
}

sub remove_tags {

    my ( $self, %args ) = @_;
    my ( $post_id, $tags, $tags_op, $posts_op, $id_prefix, $tag_level ) =
        @args{ 'post_id', 'tags', 'tags_op', 'posts_op', 'id_prefix', 'tag_level' };

    my @stack = ( $tags );

    while( defined( my $node = shift( @stack ) ) ) {

        my $ref = ref( $node );

        if( $ref eq 'CODE' ) {

            unshift( @stack, $node -> () );

        } elsif( $ref eq 'ARRAY' ) {

            foreach my $tag ( @$node ) {

                my $id = ( ( defined $id_prefix ? "${id_prefix}/" : '' ) . $tag -> { 'name' } );

                $tags_op -> find( { _id => $id } ) -> upsert() -> update_one( {
                    '$inc' => { c => -1 },
                    ( defined $id_prefix ? (
                        '$set' => {
                            l => $tag_level,
                            p => $id_prefix,
                        },
                    ) : () ),
                } );

                $posts_op -> find( { _id => "${post_id}/${id}" } ) -> remove_one();

                if( exists $tag -> { 'tags' } ) {

                    $self -> remove_tags(
                        post_id => $post_id,
                        tags => $tag -> { 'tags' },
                        tags_op => $tags_op,
                        posts_op => $posts_op,
                        id_prefix => $id,
                        tag_level => ( $tag_level + 1 ),
                    );
                }
            }

        } elsif( $ref eq 'HASH' ) {

            if( exists $node -> { 'removed' } ) {

                push( @stack, $node -> { 'removed' } );
            }

            foreach my $key ( 'added', 'modified' ) {

                if( exists $node -> { $key } ) {

                    $self -> add_tags(
                        post_id => $post_id,
                        tags => $node -> { $key },
                        tags_op => $tags_op,
                        posts_op => $posts_op,
                        id_prefix => $id_prefix,
                        tag_level => $tag_level,
                    );
                }
            }
        }
    }

    return;
}

sub get_tags {

    my ( $self ) = @_;

    ( my $tags = ( $self -> req() -> param( 'tag' ) // '' ) ) =~ s/^\s+|\s+$//g;

    if( bytes::length( $tags ) > MAX_TAGS_SIZE ) {

        return 'Too much tags';
    }

    if( length( $tags ) > 0 ) {

        $tags = eval{ decode_json( $tags ) };

        if( $@ || ! Salvation::TC -> is( $tags, 'BlogPostTagsTree' ) ) {

            return 'Invalid tags';
        }

    } else {

        undef( $tags );
    }

    if( defined $tags ) {

        my @stack = ( $tags );

        while( defined( my $node = shift( @stack ) ) ) {

            $self -> preprocess_tags( $node );

            foreach my $node ( @$node ) {

                if( exists $node -> { 'tags' } ) {

                    push( @stack, $node -> { 'tags' } );
                }
            }
        }
    }

    return $tags;
}

sub preprocess_tags {

    my ( $self, $list ) = @_;
    my $i = 0;
    my %seen = ();

    foreach my $node ( @$list ) {

        ( $node -> { 'name' } = decode_utf8( $node -> { 'name' } ) ) =~ s/^\s+|\s+$|\///g;

        next if ( $node -> { 'name' } eq '' );

        my $dest = $seen{ $node -> { 'name' } } //= { tags => [], pos => $i++ };

        push( @{ $dest -> { 'tags' } }, @{ $node -> { 'tags' } // [] } );
    }

    while( my ( $name, $data ) = each( %seen ) ) {

        my $dest = $list -> [ $data -> { 'pos' } ];

        $dest -> { 'name' } = $name;

        if( scalar( @{ $data -> { 'tags' } } ) > 0 ) {

            @{ $dest -> { 'tags' } //= [] } = @{ $data -> { 'tags' } };

        } else {

            delete( $dest -> { 'tags' } );
        }
    }

    splice( @$list, $i );

    return;
}

sub compare_tags {

    my ( $self, %args ) = @_;
    my ( $old_tags, $new_tags ) = @args{ 'old', 'new' };
    my %out = ();

    foreach my $new_tag ( @$new_tags ) {

        my $is_new = true;
        my $subtags = undef;

        foreach my $old_tag ( @$old_tags ) {

            if( $old_tag -> { 'name' } eq $new_tag -> { 'name' } ) {

                if( exists $old_tag -> { 'tags' } ) {

                    if( exists $new_tag -> { 'tags' } ) {

                        $subtags = $self -> compare_tags(
                            old => $old_tag -> { 'tags' },
                            new => $new_tag -> { 'tags' },
                        );

                    } else {

                        $subtags = { removed => $old_tag -> { 'tags' } };
                    }

                } else {

                    if( exists $new_tag -> { 'tags' } ) {

                        $subtags = { added => $new_tag -> { 'tags' } };
                    }
                }

                $is_new = false;
                last;
            }
        }

        if( $is_new ) {

            push( @{ $out{ 'added' } }, $new_tag );

        } else {

            if( defined $subtags ) {

                push( @{ $out{ 'modified' } }, {
                    name => $new_tag -> { 'name' },
                    tags => $subtags,
                } );
            }
        }
    }

    foreach my $old_tag ( @$old_tags ) {

        my $is_removed = true;

        foreach my $new_tag ( @$new_tags ) {

            if( $old_tag -> { 'name' } eq $new_tag -> { 'name' } ) {

                $is_removed = false;
                last;
            }
        }

        if( $is_removed ) {

            push( @{ $out{ 'removed' } }, $old_tag );
        }
    }

    return ( ( scalar( keys( %out ) ) > 0 ) ? \%out : undef );
}


1;

__END__
