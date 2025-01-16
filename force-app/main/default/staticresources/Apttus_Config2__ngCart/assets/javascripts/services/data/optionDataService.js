(function() {
  angular.module('ngCPQ').service('OptionDataService', [
    'ApiUtils', function(ApiUtils) {
      this.getOptionGroups = function(productID) {
        var file;
        file = (function() {
          switch (productID) {
            case '01ti0000006eXrWAAU':
              return 'option_groups_rack_server';
            case '01ti0000006eXtrAAE':
              return 'option_groups_x3450';
            case '01ti0000006eXuLAAU':
              return 'option_groups_4gb_memory';
            default:
              return 'option_groups';
          }
        })();
        return ApiUtils.getStaticJson(file).then((function(_this) {
          return function(resp) {
            return resp.data;
          };
        })(this));
      };
      return this;
    }
  ]);

}).call(this);
