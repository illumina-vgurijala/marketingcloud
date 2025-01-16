(function() {
  var RefineSearch, refineSearchCtrl;

  refineSearchCtrl = function(Category, ngCPQLabels) {
    this.labels = ngCPQLabels.labels;
    this.category = Category;
    return this;
  };

  refineSearchCtrl.$inject = ['CategoryService', 'ngCPQLabels'];

  RefineSearch = function(baseUrl) {
    return {
      templateUrl: baseUrl + "/templates/directives/refine-search.html",
      controller: refineSearchCtrl,
      controllerAs: 'refineSearch',
      bindToController: true
    };
  };

  RefineSearch.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('refineSearch', RefineSearch);

}).call(this);
