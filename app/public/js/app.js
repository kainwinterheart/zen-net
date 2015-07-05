angular.module( 'zenNet', [ 'ngRoute', 'angular-loading-bar', 'zenNetSRPApp', 'zenNetBlogApp' ] )

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
            templateUrl: '/index.html'
        } )
    ;
} )

;
