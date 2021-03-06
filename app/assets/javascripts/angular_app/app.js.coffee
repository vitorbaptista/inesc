angular.module('InescApp', ['ui.bootstrap'])
  .constant('_START_REQUEST_', '_START_REQUEST_')
  .constant('_END_REQUEST_', '_END_REQUEST_')
  .constant('_FAILED_REQUEST_', '_FAILED_REQUEST_')
  .config(['$httpProvider', ($httpProvider) ->
    interceptor = ['_START_REQUEST_', '_END_REQUEST_', '_FAILED_REQUEST_', '$q', '$injector', (_START_REQUEST_, _END_REQUEST_, _FAILED_REQUEST_, $q, $injector) ->
      $rootScope = $injector.get('$rootScope')
      $http = undefined

      success = (response) ->
        $http ||= $injector.get('$http')
        if $http.pendingRequests.length < 1
          $rootScope.$broadcast(_END_REQUEST_)
        response

      error = (response) ->
        response = success(response)
        $rootScope.$broadcast(_FAILED_REQUEST_)
        $q.reject(response)

      (promise) ->
        $rootScope.$broadcast(_START_REQUEST_)
        promise.then(success, error)
    ]

    $httpProvider.responseInterceptors.push(interceptor)
  ])
