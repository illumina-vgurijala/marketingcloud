(function() {
  angular.module('ngCPQ').service('SFCache', [
    '$cacheFactory', function($cacheFactory) {
      return $cacheFactory('SalesForce');
    }
  ]);

}).call(this);
