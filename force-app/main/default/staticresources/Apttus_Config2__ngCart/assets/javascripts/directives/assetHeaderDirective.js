(function() {

  var AssetHeader, assetHeaderCtrl;

  assetHeaderCtrl = function(ngCPQLabels) {
    console.log("in AssetHeaderController");
    return this.labels = ngCPQLabels.labels;
  };

  assetHeaderCtrl.$inject = ['ngCPQLabels'];

  AssetHeader = function(baseUrl) {
    var directive;
    directive = {
      restrict: 'E',
      templateUrl: baseUrl + '/templates/directives/asset-header.html',
      controller: assetHeaderCtrl,
      controllerAs: 'headerCtrl',
      bindToController: true
    };
    return directive;
  };

  AssetHeader.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('assetHeader', AssetHeader);

}).call(this);