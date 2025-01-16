(function() {
  angular.module('ngCPQ').service('PageSettingsDataService', [
    'ApiUtils', function(ApiUtils) {
      this.getPageSettings = function() {
        return ApiUtils.getStaticJson('page_settings').then((function(_this) {
          return function(resp) {
            return resp.data;
          };
        })(this));
      };
      return this;
    }
  ]);

}).call(this);
