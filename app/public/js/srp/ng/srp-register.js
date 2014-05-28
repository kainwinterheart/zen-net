angular.module( 'zenNetSRPRegister', [ 'zenNetSRPInternals', 'zenNetSRPClient' ] )

.factory( 'SRPRegisterAPIURLs', function() {

    return {
        salt: '/srp/register/salt',
        user: '/srp/register/user'
    };
} )

.factory( 'SRPRegisterAPI', function( SRPRegisterAPIURLs, SRPInternalHTTP ) {

    var post = SRPInternalHTTP.post;

    return {
        salt: function( I ) {

            return post( SRPRegisterAPIURLs.salt, {
                'I': I
            } );
        },
        user: function( v ) {

            return post( SRPRegisterAPIURLs.user, {
                'v': v
            } );
        }
    };
} )

.factory( 'SRPRegisterService', function( SRPRegisterAPI, SRPClient, $q ) {

    var salt = function( I ) {

        return SRPRegisterAPI.salt( I );
    };

    var user = function( v ) {

        return SRPRegisterAPI.user( v );
    };

    return function( I, p, bits ) {

        var srp = SRPClient( I, p, bits );

        var deferred = $q.defer();

        salt( I )
            .success( function( data ) {

                if( data.error ) return deferred.reject( data.error );

                var v = srp.calculateV( data.salt );

                user( v.toString( 16 ) )
                    .success( function( data ) {

                        if( data.error ) {

                            deferred.reject( data.error );

                        } else {

                            deferred.resolve();
                        }
                    } )
                    .error( function() {

                        deferred.reject( 'Internal error' );
                    } )
                ;
            } )
            .error( function() {

                deferred.reject( 'Internal error' );
            } )
        ;

        return deferred.promise;
    };
} )

;
