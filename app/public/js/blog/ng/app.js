angular.module( 'zenNetBlogApp', [ 'ui.bootstrap', 'xeditable', 'ngRoute', 'ngTagEditor', 'zenNetGlobalState', 'ui-notification' ] )

.run( function( editableOptions )
{
    editableOptions.theme = 'bs3';
} )

.factory( 'BlogBuildParams', function() {

    return function( params ) {

        var arr = [];

        for( var key in params ) {

            if( Array.isArray( params[ key ] ) ) {

                for( var i in params[ key ] ) {

                    arr.push( key + '=' + encodeURIComponent( params[ key ][ i ] ) );
                }

            } else {

                arr.push( key + '=' + encodeURIComponent( params[ key ] ) );
            }
        }

        return arr.join( '&' );
    };
} )

.controller( 'BlogPageController', function( $scope, $routeParams, $http, $location, GlobalState, Notification, $timeout ) {

    $scope.posts = [];
    $scope.next_page_from = undefined;
    $scope.only_this_blog = undefined;
    $scope.only_this_tag = undefined;

    $http( {
        method: 'GET',
        url: '/blog' +
            ( $routeParams.page ? '/u/' + encodeURIComponent( $routeParams.page ) : '' ) +
            ( $routeParams.tag ? '/t/' + encodeURIComponent( $routeParams.tag ) : '' )
    } )
        .success( function( data ) {

            $scope.posts = data.posts.map( function( el ) { return transform_post( el ) } );
            $scope.next_page_from = data.next_page_from;
            $scope.only_this_blog = data.only_this_blog;
            $scope.only_this_tag = data.only_this_tag;
            GlobalState.logged_in = data.logged_in;

            $timeout( window.prettyPrint, 150 );
        } )
        .error( function() {

            Notification.error( 'Internal error' );
        } )
    ;

    $scope.next_page = function() {

        $http( {
            method: 'GET',
            url: '/blog' +
                ( $routeParams.page ? '/u/' + encodeURIComponent( $routeParams.page ) : '' ) +
                ( $routeParams.tag ? '/t/' + encodeURIComponent( $routeParams.tag ) : '' ),
            params: {
                from: $scope.next_page_from
            }
        } )
            .success( function( data ) {

                while( data.posts.length > 0 ) {

                    $scope.posts.push( transform_post( data.posts.shift() ) );
                }

                $scope.next_page_from = data.next_page_from;
                GlobalState.logged_in = data.logged_in;

                $timeout( window.prettyPrint, 150 );
            } )
            .error( function() {

                Notification.error( 'Internal error' );
            } )
        ;
    };

    $scope.back_to_all = function() {

        if( ( $scope.only_this_blog !== undefined ) || ( $scope.only_this_tag !== undefined ) ) {

            $location.path( '/blog' );
        }
    };

    function transform_post( post ) {

        if( post.trimmed ) {

            post.text += '...';
        }

        return post;
    }
} )

.controller( 'BlogOpenPostController', function( $scope, $routeParams, $http, GlobalState, Notification, $timeout ) {

    $scope.post = {};
    $scope.prettyPrint = function() {

        $timeout( window.prettyPrint, 150 );
    };

    $http( {
        method: 'GET',
        url: '/blog/p/' + encodeURIComponent( $routeParams.id )
    } )
        .success( function( data ) {

            GlobalState.logged_in = data.logged_in;
            delete data[ 'logged_in' ];

            $scope.post = data;
            $scope.prettyPrint();
        } )
        .error( function() {

            Notification.error( 'Internal error' );
        } )
    ;
} )

.controller( 'BlogEditPostController', function( $scope, $routeParams, $controller, $location, BlogBuildParams, $http, GlobalState, Notification, $timeout ) {

    if( ! GlobalState.logged_in ) {

        $location.path( '/' );
        return;
    }

    $scope.tags = [];
    $scope.$watch( 'post.tags', function( list ) {

        $scope.tags = ( list || [] ).map( function( tag ) {
            return { name: tag };
        } );
    } );

    $controller( 'BlogOpenPostController', {
        '$scope' : $scope,
        '$routeParams': $routeParams,
        '$http': $http,
        'GlobalState': GlobalState,
        '$timeout': $timeout
    } );

    $scope.save = function() {

        $http( {
            method: 'POST',
            url: '/blog/e/' + encodeURIComponent( $scope.post.id ),
            headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF8' },
            data: BlogBuildParams( {
                text: $scope.post.text,
                tag: $scope.tags.map( function( tag ) {
                    return tag.name;
                } ),
                id: $scope.post.id,
                version: $scope.post.version
            } )
        } )
            .success( function( data ) {

                if( data.error ) {

                    Notification.error( data.error );

                } else {

                    $location.path( '/blog/p/' + encodeURIComponent( data.id ) );
                }
            } )
            .error( function() {

                Notification.error( 'Internal error' );
            } )
        ;
    };

    $scope.cancel = function() {

        $location.path( '/blog' );
    };
} )

.controller( 'BlogNewPostController', function( $scope, $location, BlogBuildParams, $http, Notification, GlobalState, $timeout ) {

    if( ! GlobalState.logged_in ) {

        $location.path( '/' );
        return;
    }

    $scope.tags = [];
    $scope.post = {
        text: "Demo\n====\n\nClick here to edit content\n\nCode sample\n---\n\n```\nint main()\n{\n\treturn 0;\n}\n```\n\nTable sample\n---\n\n| head 1 | head 2 |\n| === | === |\n| text 1 | text 2 |\n\nStuff\n---\n\n* **bold**\n* *italic*\n* [URL](http://autumncoffee.com/)\n\nNumbered list\n---\n\n1. first\n2. second\n3. third\n"
    };

    $scope.save = function() {

        $http( {
            method: 'POST',
            url: '/blog/new',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF8' },
            data: BlogBuildParams( {
                text: $scope.post.text,
                tag: $scope.tags.map( function( tag ) {
                    return tag.name;
                } ),
            } )
        } )
            .success( function( data ) {

                if( data.error ) {

                    Notification.error( data.error );

                } else {

                    $location.path( '/blog/p/' + encodeURIComponent( data.id ) );
                }
            } )
            .error( function() {

                Notification.error( 'Internal error' );
            } )
        ;
    };

    $scope.cancel = function() {

        $location.path( '/blog' );
    };

    $scope.prettyPrint = function() {

        $timeout( window.prettyPrint, 150 );
    };

    $scope.prettyPrint();
} )

.filter( 'markdown', function( $sce ) {

    var converter = new Showdown.converter({
        extensions: [
            'table',
            'prettify'
        ]
    });

    return function( value ) {

        var html = converter.makeHtml( ( value || '' ).replace( />/g, '&gt;' ).replace( /</g, '&lt;' ) );

        return $sce.trustAsHtml( html );
    };
} )

;
