(function() {
  var BreadcrumbTrail, breadcrumbCtrl;

  breadcrumbCtrl = function(baseUrl, CatalogService, $stateParams) {
    var vm;
    vm = this;
    return CatalogService.getBreadcrumb($stateParams.catID).then(function(res) {
      vm.trail = res;
      return vm.currentCategory = vm.trail.pop();
    });
  };

  breadcrumbCtrl.$inject = ['baseUrl', 'CatalogService', '$stateParams'];

  BreadcrumbTrail = function(baseUrl) {
    var directive;
    directive = {
      restrict: 'AE',
      controllerAs: 'crumb',
      bindToController: true,
      controller: breadcrumbCtrl,
      templateUrl: baseUrl + '/templates/directives/breadcrumb-block.html'
    };
    return directive;
  };

  angular.module('ngCPQ').directive('breadcrumbTrail', BreadcrumbTrail);

}).call(this);
