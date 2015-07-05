angular.module( 'zenNetBlogApp', [ 'ui.bootstrap', 'xeditable', 'ngRoute', 'ngTagEditor' ] )

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

.controller( 'BlogPageController', function( $scope, $routeParams, $http, $location ) {

    $scope.posts = [];
    $scope.next_page_from = undefined;
    $scope.only_this_blog = undefined;

    $http( {
        method: 'GET',
        url: '/blog' + ( $routeParams.page ? '/u/' + encodeURIComponent( $routeParams.page ) : '' ),
    } )
        .success( function( data ) {

            $scope.posts = data.posts;
            $scope.next_page_from = data.next_page_from;
            $scope.only_this_blog = data.only_this_blog;
        } )
        .error( function() {

            alert( 'Internal error' );
        } )
    ;

    $scope.new_post = function() {

        $location.path( '/blog/new' );
    };

    $scope.next_page = function() {

        $http( {
            method: 'GET',
            url: '/blog' + ( $routeParams.page ? '/u/' + encodeURIComponent( $routeParams.page ) : '' ),
            params: {
                from: $scope.next_page_from
            }
        } )
            .success( function( data ) {

                var list = $scope.posts;

                while( data.posts.length > 0 ) {

                    list.push( data.posts.shift() );
                }

                $scope.next_page_from = data.next_page_from;
            } )
            .error( function() {

                alert( 'Internal error' );
            } )
        ;
    };

    $scope.back_to_all = function() {

        if( $scope.only_this_blog !== undefined ) {

            $location.path( '/blog' );
        }
    };
} )

.controller( 'BlogOpenPostController', function( $scope, $routeParams, $http ) {

    $scope.post = {};

    $http( {
        method: 'GET',
        url: '/blog/p/' + encodeURIComponent( $routeParams.id )
    } )
        .success( function( data ) {

            $scope.post = data;
        } )
        .error( function() {

            alert( 'Internal error' );
        } )
    ;
} )

.controller( 'BlogEditPostController', function( $scope, $routeParams, $controller, $location, BlogBuildParams, $http ) {

    $scope.tags = [];
    $scope.$watch( 'post.tags', function( list ) {

        $scope.tags = ( list || [] ).map( function( tag ) {
            return { name: tag };
        } );
    } );

    $controller( 'BlogOpenPostController', { '$scope' : $scope, '$routeParams': $routeParams, '$http': $http } );

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

                    alert( data.error );

                } else {

                    $location.path( '/blog/p/' + encodeURIComponent( data.id ) );
                }
            } )
            .error( function() {

                alert( 'Internal error' );
            } )
        ;
    };

    $scope.cancel = function() {

        $location.path( '/blog' );
    };
} )

.controller( 'BlogNewPostController', function( $scope, $location, BlogBuildParams, $http ) {

    $scope.tags = [];
    $scope.post = {
        text: 'Click here to write some text'
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

                    alert( data.error );

                } else {

                    $location.path( '/blog/p/' + encodeURIComponent( data.id ) );
                }
            } )
            .error( function() {

                alert( 'Internal error' );
            } )
        ;
    };

    $scope.cancel = function() {

        $location.path( '/blog' );
    };
} )

.filter( 'markdown', function ( $sce )
{
    var converter = new Showdown.converter({
        extensions: [
            'table',
            'prettify'
        ]
    });

    return function ( value )
    {
        var html = converter.makeHtml( ( value || '' ).replace( />/g, '&gt;' ).replace( /</g, '&lt;' ) );

        return $sce.trustAsHtml( html );
    };
} )

;
