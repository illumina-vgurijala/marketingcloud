(function() {
  var SearchProductListingCtrl;

  SearchProductListingCtrl = function(_, $stateParams, CatalogService, Category) {
    var catalog, searchedTerm, searchedTermCategory;
    catalog = this;
    searchedTerm = $stateParams.term;
    searchedTermCategory = $stateParams.category;
    CatalogService.searchProducts(searchedTermCategory, searchedTerm, Category.filters).then(function(res) {
      catalog.categories = res.categories;
      return catalog.products = res.products;
    });
    return catalog;
  };

  SearchProductListingCtrl.$inject = ['lodash', '$stateParams', 'CatalogService', 'CategoryService'];

  angular.module('ngCPQ').controller('searchProductListingCtrl', SearchProductListingCtrl);

}).call(this);
