angular.module('zenNetAppsFiolentMysApp', ['ui.bootstrap', 'ui-notification', 'zenNetGlobalState', 'ui.tinymce', 'fileUpload'])

.factory('FiolentMysPageLoader', function($http, $q, Notification) {
    return function($routeParams) {
        var deferred = $q.defer();

        $http({
            method: 'GET',
            url: '/app/fiolentmys/page/edit?page=' + encodeURIComponent($routeParams.page)
        })
            .success(function(data) {
                deferred.resolve(function(ctx) {
                    ctx.GlobalState.logged_in = data.logged_in;

                    for(var i = 0; i < data.content.length; ++i) {
                        var node = data.content[i];

                        ctx.$scope.add_block(node[0], undefined, node[2]);
                    }

                    ctx.$scope.page = data.page;
                });
            })
            .error(function() {
                Notification.error('Internal error');
                deferred.reject();
            })
        ;

        return deferred.promise;
    };
})

.factory('FiolentMysBuildParams', function() {
    return function(params) {
        var arr = [];

        for(var key in params) {
            if(Array.isArray(params[key])) {
                for(var i in params[key]) {
                    arr.push(key + '=' + encodeURIComponent(params[key][i]));
                }

            } else {
                arr.push(key + '=' + encodeURIComponent(params[key]));
            }
        }

        return arr.join('&');
    };
})

.controller('FiolentMysEditPage', function(Notification, $interval, $http, $scope, GlobalState, pageData, FiolentMysBuildParams) {
    if(!GlobalState.logged_in) {
        $location.path('/');
        return;
    }

    var pinger = $interval(function() {
        $http({
            method: 'GET',
            url: '/ping'
        })
            .success(function(data) {
                GlobalState.logged_in = data.logged_in;

                if(!GlobalState.logged_in) {
                    Notification.error('Your session has expired, please log in again');
                }
            })
            .error(function() {
                console.log("ping failed");
            })
        ;
    }, 60000);

    $scope.$on('$destroy', function() {
        $interval.cancel(pinger);
    });

    $scope.serial = 0;
    $scope.blocks = [];
    $scope.data = {};
    $scope.page = '';

    $scope.tinymceOptions = {
        height: 500,
        plugins: [
            'advlist autolink lists link image charmap print preview anchor',
            'searchreplace visualblocks code fullscreen',
            'insertdatetime media table contextmenu paste code'
        ],
        toolbar: 'undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link'
    };

    $scope.add_block = function(type, after, data) {
        var id = ++ $scope.serial;

        if((type == 'gallery') && Array.isArray(data)) {
            data = data.join("\n"); // TODO
        }

        $scope.data[id] = [type, data];

        if(after === undefined) {
            $scope.blocks.push(id);

        } else {
            var new_blocks = $scope.blocks.splice(0, after + 1).concat([id]).concat($scope.blocks);

            $scope.blocks.splice(0);

            while(new_blocks.length > 0) {
                $scope.blocks.push(new_blocks.shift());
            }
        }
    };

    $scope.remove_block = function(index) {
        var new_blocks = $scope.blocks.splice(0, index).concat($scope.blocks.splice(1));

        $scope.blocks.splice(0);

        while(new_blocks.length > 0) {
            $scope.blocks.push(new_blocks.shift());
        }
    };

    $scope.save = function() {
        var data = [];

        for(var i = 0; i < $scope.blocks.length; ++i) {
            var node = $scope.data[$scope.blocks[i]];
            var _data = node[1];

            if(node[0] == 'gallery') {
                _data = _data.replace(/^\s+|\s+$/g, '').split(/\n/); // TODO
            }

            data.push([node[0], i, _data]);
        }

        $http({
            method: 'POST',
            url: '/app/fiolentmys/page/save',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF8' },
            data: FiolentMysBuildParams({
                page: $scope.page,
                data: JSON.stringify(data)
            })
        })
            .success(function(data) {
                GlobalState.logged_in = data.logged_in;

                if(GlobalState.logged_in) {
                    if(data.page == $scope.page) {
                        Notification.info('Success');

                    } else {
                        Notification.error('Something went wrong');
                    }

                } else {
                    Notification.error('Your session has expired, please log in again');
                }
            })
            .error(function() {
                if(GlobalState.logged_in) {
                    Notification.error('Internal error');

                } else {
                    Notification.error('Your session has expired, please log in again');
                }
            })
        ;
    };

    pageData({
        '$scope': $scope,
        'GlobalState': GlobalState
    });
})

.controller('FiolentMysUploadFile', function($scope, GlobalState, $location) {
    if(!GlobalState.logged_in) {
        $location.path('/');
        return;
    }

    $scope.__userFiles = [];

    $scope.url_or_error = function(data) {
        if(((data.status || {}).response || '').length == 0) {
            return 'Still loading...';
        }

        try {
            data = JSON.parse(data.status.response);

        } catch(e) {
            return 'Internal error';
        }

        if(data.hasOwnProperty('error')) {
            return data.error;

        } else {
            return data.url;
        }
    };
})

;
