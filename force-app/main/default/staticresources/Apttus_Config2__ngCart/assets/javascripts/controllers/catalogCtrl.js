(function() {
  var CatalogCtrl;

  CatalogCtrl = function(baseFileUrl, CatalogService) {
    var catalog;
    catalog = this;
    this.baseFileUrl = baseFileUrl;
    CatalogService.getCategories().then(function(res) {
      return catalog.categories = res;
    });
    return catalog;
  };

  CatalogCtrl.$inject = ['baseFileUrl', 'CatalogService', 'ngCPQLabels'];

  angular.module('ngCPQ').controller('catalogCtrl', CatalogCtrl);

}).call(this);
