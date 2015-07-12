angular.module( 'zenNetSRPApp', [ 'zenNetSRPAuth', 'zenNetSRPRegister', 'zenNetGlobalState', 'ui-notification' ] )

.constant( 'SRPBits', 4096 )

.factory( 'SRPAuthMethod', function( SRPAuthService, GlobalState, $location, Notification ) {

    return function() {

        SRPAuthService
            .apply( SRPAuthService, arguments )
            .then(
                function() {

                    GlobalState.logged_in = 1;
                    $location.path( '/' );
                },
                function( str ) {

                    Notification.error( str );
                }
            )
        ;
    };
} )

.factory( 'SRPRegisterMethod', function( SRPAuthMethod, SRPRegisterService, Notification ) {

    return function() {

        var _arguments = arguments;

        SRPRegisterService
            .apply( SRPRegisterService, _arguments )
            .then(
                function() {

                    SRPAuthMethod.apply( SRPAuthMethod, _arguments );
                },
                function( str ) {

                    Notification.error( str );
                }
            )
        ;
    };
} )

.controller( 'SRPController', function( $scope, SRPBits, SRPAuthMethod, SRPRegisterMethod ) {

    $scope.username = undefined;
    $scope.password = undefined;

    $scope.reset = function() {

        $scope.username = undefined;
        $scope.password = undefined;
    };

    var proto = function( method ) {

        return function() {

            var I = $scope.username;
            var p = $scope.password;

            $scope.reset();

            method( I, p, SRPBits );

            return false;
        };
    };

    $scope.login = proto( SRPAuthMethod );
    $scope.register = proto( SRPRegisterMethod );
} )

;
