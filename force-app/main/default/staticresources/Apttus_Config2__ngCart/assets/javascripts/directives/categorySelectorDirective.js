(function() {
  var CategorySelector, categorySelectorCtrl;

  categorySelectorCtrl = function($stateParams, CatalogService, ngCPQLabels) {
    var self;
    self = this;
    self.dropdownLabel = 'Choose a category';
    self.depth = 0;
    self.labels = ngCPQLabels.labels;
    return CatalogService.getCategories().then(function(res) {
      var categoriesDepth, categoryLineage;
      self.categories = res;
      categoryLineage = CatalogService.getAncestors($stateParams.catID, res);
      categoriesDepth = categoryLineage.length;
      if (categoriesDepth <= 1 && categoryLineage[0]) {
        return self.dropdownLabel = categoryLineage[0].label;
      } else if (categoriesDepth >= 1) {
        return self.dropdownLabel = categoryLineage[1].label;
      }
    });
  };

  categorySelectorCtrl.$inject = ['$stateParams', 'CatalogService', 'ngCPQLabels'];

  CategorySelector = function(baseUrl) {
    return {
      scope: {},
      bindToController: true,
      controller: categorySelectorCtrl,
      controllerAs: 'catSelect',
      templateUrl: baseUrl + '/templates/directives/category-selector-block.html'
    };
  };

  CategorySelector.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('categorySelector', CategorySelector);

}).call(this);
