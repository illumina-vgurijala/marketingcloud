(function() {
  angular.module('ngCPQ').service('ProductFilterDataService', [
    'ApiUtils', function(ApiUtils) {
      this.getFiltersFor = function(categoryID) {
        return ApiUtils.getStaticJson('product_filter').then((function(_this) {
          return function(resp) {
            return resp.data.productFilters;
          };
        })(this));
      };
      return this;
    }
  ]);

}).call(this);
