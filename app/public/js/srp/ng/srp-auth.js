angular.module( 'zenNetSRPAuth', [ 'zenNetSRPInternals', 'zenNetSRPClient' ] )

.factory( 'SRPAuthAPIURLs', function() {

    return {
        handshake: '/srp/handshake',
        authenticate: '/srp/authenticate'
    };
} )

.factory( 'SRPAuthAPI', function( SRPAuthAPIURLs, SRPInternalHTTP ) {

    var post = SRPInternalHTTP.post;

    return {
        handshake: function( I, A ) {

            return post( SRPAuthAPIURLs.handshake, {
                'I': I,
                'A': A
            } );
        },
        authenticate: function( M ) {

            return post( SRPAuthAPIURLs.authenticate, {
                'M': M
            } );
        }
    };
} )

.factory( 'SRPAuthService', function( SRPAuthAPI, SRPClient, $q ) {

    var authenticate = function( M ) {

        return SRPAuthAPI.authenticate( M );
    };

    var handshake = function( I, A ) {

        return SRPAuthAPI.handshake( I, A );
    };

    return function( I, p, bits ) {

        var srp = SRPClient( I, p, bits );

        var a = srp.srpRandom();
        var A = srp.calculateA( a );
        var Astr = A.toString( 16 );

        var deferred = $q.defer();

        handshake( I, Astr )
            .success( function( data ) {

                if( data.error ) return deferred.reject( data.error );

                var B = new BigInteger( data.B, 16 );
                var s = data.s;

                var M1 = undefined

                try {
                    M1 = srp.calculateM1( A, B, s, a );

                } catch( e ) {

                    return deferred.reject( e );
                }

                authenticate( M1 )
                    .success( function( data ) {

                        if( data.error ) return deferred.reject( data.error );

                        if( data.M == srp.calculateM2( A, B, s, a ) ) {

                            deferred.resolve();

                        } else {

                            deferred.reject( 'Server key mismatch' );
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
