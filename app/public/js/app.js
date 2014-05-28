angular.module( 'zenNet', [ 'ngRoute', 'angular-loading-bar', 'zenNetSRPApp' ] )

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
        .otherwise( {
            templateUrl: '/index.html'
        } )
    ;
} )

;
