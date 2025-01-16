(function() {
  angular.module('ngCPQ').service('ProductDataService', [
    'ApiUtils', function(ApiUtils) {
      var _productsInSearchCategory;
      this.searchProducts = function(categoryIds, searchText, filters) {
        if ((searchText != null ? searchText.length : void 0) > 0) {
          return ApiUtils.getStaticJson('product_search').then(function(res) {
            return res.data;
          });
        } else {
          return ApiUtils.getStaticJson('productsv2').then(function(res) {
            return res.data.products;
          });
        }
      };
      _productsInSearchCategory = function(categoryID, products) {
        return products.filter(function(product, index) {
          if (product.categoryIds.indexOf(categoryID) >= 0) {
            return product;
          }
        });
      };
      return this;
    }
  ]);

}).call(this);
