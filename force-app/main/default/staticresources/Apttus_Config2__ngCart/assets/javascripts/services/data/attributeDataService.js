(function() {
  angular.module('ngCPQ').service('AttributeDataService', [
    'ApiUtils', function(ApiUtils) {
      this.getAttributeGroups = function(productID) {
        var file;
        file = (function() {
          switch (productID) {
            case '01ti0000006eXrWAAU':
              return 'attribute_groups_rack_server';
            case '01ti0000006eXuLAAU':
              return 'attribute_groups_4gb';
            default:
              return 'attribute_groups';
          }
        })();
        return ApiUtils.getStaticJson(file).then((function(_this) {
          return function(resp) {
            return resp.data;
          };
        })(this));
      };
      this.getAttributeFields = function(productID) {
        return ApiUtils.getStaticJson('attribute_fields').then((function(_this) {
          return function(resp) {
            return resp.data.attributeFields;
          };
        })(this));
      };
      this.getAttributeValueSO = function(productID) {
        return ApiUtils.getStaticJson('attribute_value_so').then((function(_this) {
          return function(resp) {
            return resp.data;
          };
        })(this));
      };
      return this;
    }
  ]);

}).call(this);
