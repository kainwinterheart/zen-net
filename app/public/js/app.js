angular.module( 'zenNet', [ 'ngRoute', 'angular-loading-bar', 'zenNetSRPApp', 'zenNetBlogApp', 'zenNetGlobalState', 'ui-notification' ] )

.config( function( $routeProvider, cfpLoadingBarProvider ) {

    cfpLoadingBarProvider.includeSpinner = false;

    $routeProvider
        .when( '/register', {
            controller: 'SRPController',
            templateUrl: '/register.html'
        } )
        .when( '/login', {
            controller: 'SRPController',
            templateUrl: '/login.html'
        } )
        .when( '/blog', {
            controller: 'BlogPageController',
            templateUrl: '/blog_page.html',
            resolve: {
                initialPosts: function( BlogPagePostsLoader, $route ) {
                    return BlogPagePostsLoader( $route.current.params );
                }
            }
        } )
        .when( '/blog/u/:page', {
            controller: 'BlogPageController',
            templateUrl: '/blog_page.html',
            resolve: {
                initialPosts: function( BlogPagePostsLoader, $route ) {
                    return BlogPagePostsLoader( $route.current.params );
                }
            }
        } )
        .when( '/blog/t/:tag', {
            controller: 'BlogPageController',
            templateUrl: '/blog_page.html',
            resolve: {
                initialPosts: function( BlogPagePostsLoader, $route ) {
                    return BlogPagePostsLoader( $route.current.params );
                }
            }
        } )
        .when( '/blog/p/:id', {
            controller: 'BlogOpenPostController',
            templateUrl: '/blog_open_post.html',
            resolve: {
                initialPost: function( BlogOpenPostLoader, $route ) {
                    return BlogOpenPostLoader( $route.current.params );
                }
            }
        } )
        .when( '/blog/e/:id', {
            controller: 'BlogEditPostController',
            templateUrl: '/blog_edit_post.html',
            resolve: {
                initialPost: function( BlogOpenPostLoader, $route ) {
                    return BlogOpenPostLoader( $route.current.params );
                }
            }
        } )
        .when( '/blog/new', {
            controller: 'BlogNewPostController',
            templateUrl: '/blog_edit_post.html'
        } )
        .otherwise( {
            controller: 'IndexPage',
            templateUrl: '/index.html',
            resolve: {
                initialState: function( IndexPageLoader, $route ) {
                    return IndexPageLoader( $route.current.params );
                }
            }
        } )
    ;
} )

.factory( 'IndexPageLoader', function( $http, $q, $timeout, Notification ) {

    return function() {

        var deferred = $q.defer();

        $http( {
            method: 'GET',
            url: '/i'
        } )
            .success( function( data ) {

                deferred.resolve( function( ctx ) {

                    ctx.$scope.tags = data.tags;
                    ctx.GlobalState.logged_in = data.logged_in;
                } );
            } )
            .error( function() {

                Notification.error( 'Internal error' );
            } )
        ;

        return deferred.promise;
    };
} )

.controller( 'IndexPage', function( $scope, GlobalState, initialState ) {

    $scope.tags = [];

    initialState( {
        '$scope': $scope,
        'GlobalState': GlobalState
    } );
} )

.controller( 'AppHeader', function( $scope, GlobalState, $location ) {

    $scope.gs = GlobalState;

    $scope.$on( '$locationChangeSuccess', function() {

        $scope.is_in_blog = /\/blog/.test( $location.path() );
    } );
} )

.filter( 'for_url', function() {

    return function( value ) {

        return encodeURIComponent( value );
    };
} )

;
