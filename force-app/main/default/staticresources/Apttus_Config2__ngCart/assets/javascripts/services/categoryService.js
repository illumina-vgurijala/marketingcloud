(function() {
  angular.module('ngCPQ').service('CategoryService', [
    'CatalogService', 'CategoryDataService', 'ProductDataService', 'ProductFilterDataService', 'messenger', function(CatalogService, CategoryDataService, ProductData, ProductFilterDataService, Messenger) {
      this.setCurrentCategory = function(categoryID) {
        this.id = categoryID;
        return CategoryDataService.getCategory(categoryID).then((function(_this) {
          return function(category) {
            _this.current = category;
            return ProductFilterDataService.getFiltersFor(categoryID).then(function(filters) {
              _this.filters = filters;
              return _this.updateProducts();
            });
          };
        })(this));
      };
      this.updateProducts = function() {
        return ProductData.searchProducts(this.id, this.searchText, this.filters).then((function(_this) {
          return function(result) {
            return _this.products = result.products;
          };
        })(this));
      };
      return this;
    }
  ]);

}).call(this);
