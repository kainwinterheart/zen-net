angular.module( 'zenNetBlogApp', [ 'ui.bootstrap', 'xeditable', 'ngRoute', 'ngTagsInput', 'zenNetGlobalState', 'ui-notification' ] )

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

.factory( 'BlogPagePostsLoader', function( $http, $q, $timeout, Notification ) {

    return function( $routeParams ) {
        var deferred = $q.defer();

        $http( {
            method: 'GET',
            url: '/blog' +
                ( $routeParams.page ? '/u/' + encodeURIComponent( $routeParams.page ) : '' ) +
                ( $routeParams.tag ? '/t/' + encodeURIComponent( $routeParams.tag ) : '' ) +
                ( $routeParams.subtags ? '/' + encodeURIComponent( $routeParams.subtags ) : '' )
        } )
            .success( function( data ) {

                deferred.resolve( function( ctx ) {

                    ctx.$scope.tags = ( data.tags || [] ).map( function( el ) {

                        return { id: el, name: el.split( /\// ).pop() };
                    } );

                    ctx.$scope.posts = data.posts.map( function( el ) {
                        return ctx.transform_post( el );
                    } );

                    ctx.$scope.next_page_from = data.next_page_from;
                    ctx.$scope.only_this_blog = data.only_this_blog;

                    if( data.only_this_tag ) {

                        var only_this_tag = data.only_this_tag.split( /\// );
                        var prev_tags = [];

                        ctx.$scope.only_this_tag = only_this_tag.map( function( el ) {

                            prev_tags.push( el );

                            return {
                                name: el,
                                id: prev_tags.join( '/' )
                            };
                        } );

                    } else {

                        ctx.$scope.only_this_tag = data.only_this_tag;
                    }

                    ctx.GlobalState.logged_in = data.logged_in;

                    ctx.$scope.prettyPrint();
                } );

            } )
            .error( function() {

                deferred.resolve( function() {
                    Notification.error( 'Internal error' );
                } );
            } )
        ;

        return deferred.promise;
    };
} )

.factory( 'BlogOpenPostLoader', function( $http, $q, $timeout, Notification ) {

    return function( $routeParams ) {
        var deferred = $q.defer();

        $http( {
            method: 'GET',
            url: '/blog/p/' + encodeURIComponent( $routeParams.id )
        } )
            .success( function( data ) {

                deferred.resolve( function( ctx ) {

                    ctx.GlobalState.logged_in = data.logged_in;
                    delete data[ 'logged_in' ];

                    ctx.$scope.post = data;
                    ctx.$scope.prettyPrint();
                } );
            } )
            .error( function() {

                Notification.error( 'Internal error' );
            } )
        ;

        return deferred.promise;
    };
} )

.controller( 'BlogPageController', function( $scope, $routeParams, $http, $location, GlobalState, Notification, $timeout, initialPosts ) {

    $scope.posts = [];
    $scope.next_page_from = undefined;
    $scope.only_this_blog = undefined;
    $scope.only_this_tag = undefined;

    $scope.prettyPrint = function() {

        $timeout( window.prettyPrint, 150 );
    };

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

                $scope.prettyPrint();
            } )
            .error( function() {

                Notification.error( 'Internal error' );
            } )
        ;
    };

    function transform_post( post ) {

        if( post.trimmed ) {

            post.text += '...';
        }

        return post;
    }

    initialPosts( {
        '$scope': $scope,
        'GlobalState': GlobalState,
        'transform_post': transform_post
    } );
} )

.controller( 'BlogOpenPostController', function( $scope, GlobalState, $timeout, initialPost ) {

    $scope.post = {};
    $scope.prettyPrint = function() {

        $timeout( window.prettyPrint, 150 );
    };

    initialPost( {
        '$scope': $scope,
        'GlobalState': GlobalState
    } );
} )

.controller( 'BlogEditPostController', function( $scope, $controller, $location, BlogBuildParams, $http, GlobalState, Notification, $timeout, initialPost ) {

    if( ! GlobalState.logged_in ) {

        $location.path( '/' );
        return;
    }

    $scope.tags = [];
    $scope.$watch( 'post.tags', function( list ) {

        $scope.tags = ( list || [] );
    } );

    $controller( 'BlogOpenPostController', {
        '$scope' : $scope,
        'GlobalState': GlobalState,
        '$timeout': $timeout,
        'initialPost': initialPost
    } );

    $scope.save = function() {

        $http( {
            method: 'POST',
            url: '/blog/e/' + encodeURIComponent( $scope.post.id ),
            headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF8' },
            data: BlogBuildParams( {
                text: $scope.post.text,
                tag: angular.toJson( $scope.tags ),
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
                tag: angular.toJson( $scope.tags ),
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

.directive( 'tagsTree', function( $compile ) {

    return {
        templateUrl: 'tags_tree.html?' + zenNetRev,
        restrict: 'E',
        scope: {
            tags: '=',
            sourceTag: '='
        },
        /* is magic recursion implementation */
        compile: function( tElement, tAttrs, transclude ) {

            var contents = tElement.contents().remove();
            var compiledContents = undefined;

            return function( scope, element, attrs ) {

                if( ! compiledContents ) {

                    compiledContents = $compile( contents, transclude );
                }

                compiledContents( scope, function( clone, scope ) {

                    element.append( clone );
                } );
            };
        }
    };
} )

.directive( 'tagsDisplay', function( $compile ) {

    return {
        templateUrl: 'tags_display.html?' + zenNetRev,
        restrict: 'E',
        scope: {
            tags: '=',
            sourceTag: '='
        },
        /* is magic recursion implementation */
        compile: function( tElement, tAttrs, transclude ) {

            var contents = tElement.contents().remove();
            var compiledContents = undefined;

            return function( scope, element, attrs ) {

                if( ! compiledContents ) {

                    compiledContents = $compile( contents, transclude );
                }

                compiledContents( scope, function( clone, scope ) {

                    element.append( clone );
                } );
            };
        }
    };
} )

;
