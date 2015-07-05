angular.module( 'zenNetSRPApp', [ 'zenNetSRPAuth', 'zenNetSRPRegister' ] )

.constant( 'SRPBits', 4096 )

.factory( 'SRPAuthMethod', function( SRPAuthService ) {

    return function() {

        SRPAuthService
            .apply( SRPAuthService, arguments )
            .then(
                function() {

                    alert( 'auth ok' );
                },
                function( str ) {

                    alert( 'auth: ' + str );
                }
            )
        ;
    };
} )

.factory( 'SRPRegisterMethod', function( SRPAuthMethod, SRPRegisterService ) {

    return function() {

        var _arguments = arguments;

        SRPRegisterService
            .apply( SRPRegisterService, _arguments )
            .then(
                function() {

                    SRPAuthMethod.apply( SRPAuthMethod, _arguments );
                },
                function( str ) {

                    alert( 'register: ' + str );
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
