angular.module( 'zenNetSRPInternals', [] )

.factory( 'SRPInternalHTTP', function( $http ) {

    var build_params = function( params ) {

        var arr = [];

        for( var key in params ) {

            arr.push( key + '=' + encodeURIComponent( params[ key ] ) );
        }

        return arr.join( '&' );
    };

    var post = function( _url, _params ) {

        return $http( {
            method: 'POST',
            url: _url,
            data: build_params( _params ),
            headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF8' }
        } );
    };

    return {
        'build_params': build_params,
        'post': post
    };
} )

;
