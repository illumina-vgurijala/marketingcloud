(function() {
  angular.module('ngCPQ').controller('orgCtrl', [
    '$scope', 'SalesForce', function($scope, SalesForce) {
      return $scope.companyName = SalesForce.companyName;
    }
  ]);

}).call(this);
