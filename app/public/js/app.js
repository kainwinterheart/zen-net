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
            templateUrl: '/blog_page.html'
        } )
        .when( '/blog/u/:page', {
            controller: 'BlogPageController',
            templateUrl: '/blog_page.html'
        } )
        .when( '/blog/t/:tag', {
            controller: 'BlogPageController',
            templateUrl: '/blog_page.html'
        } )
        .when( '/blog/p/:id', {
            controller: 'BlogOpenPostController',
            templateUrl: '/blog_open_post.html'
        } )
        .when( '/blog/e/:id', {
            controller: 'BlogEditPostController',
            templateUrl: '/blog_edit_post.html'
        } )
        .when( '/blog/new', {
            controller: 'BlogNewPostController',
            templateUrl: '/blog_edit_post.html'
        } )
        .otherwise( {
            controller: 'IndexPage',
            templateUrl: '/index.html'
        } )
    ;
} )

.controller( 'IndexPage', function( $scope, $http, GlobalState, Notification ) {

    $scope.tags = [];

    $http( {
        method: 'GET',
        url: '/i'
    } )
        .success( function( data ) {

            $scope.tags = data.tags;
            GlobalState.logged_in = data.logged_in;
        } )
        .error( function() {

            Notification.error( 'Internal error' );
        } )
    ;
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
