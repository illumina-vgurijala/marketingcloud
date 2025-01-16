(function() {
  angular.module('ngCPQ').service('CategoryDataService', [
    'ApiUtils', function(ApiUtils) {
      this.getCategory = function(categoryID) {
        return ApiUtils.getStaticJson('categories').then((function(_this) {
          return function(resp) {
            return resp.data.categories[0];
          };
        })(this));
      };
      this.getCategories = function(options) {
        return ApiUtils.getStaticJson('categoriesv2').then((function(_this) {
          return function(resp) {
            return resp.data.categories;
          };
        })(this));
      };
      return this;
    }
  ]);

}).call(this);
