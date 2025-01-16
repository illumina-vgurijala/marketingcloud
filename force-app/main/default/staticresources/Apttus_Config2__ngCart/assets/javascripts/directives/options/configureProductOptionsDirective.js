(function() {
  var ConfigureProductOptions, ConfigureProductOptionsCtrl;

  ConfigureProductOptionsCtrl = function(_, Configure) {
    this.lineItem = Configure.lineItem;
    return this;
  };

  ConfigureProductOptionsCtrl.$inject = ['lodash', 'ConfigureService'];

  ConfigureProductOptions = function(baseUrl) {
    return {
      restrict: 'E',
      templateUrl: baseUrl + "/templates/directives/options/configure-product-options.html",
      controller: ConfigureProductOptionsCtrl,
      controllerAs: 'options',
      bindToController: true
    };
  };

  ConfigureProductOptions.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('configureProductOptions', ConfigureProductOptions);

}).call(this);
