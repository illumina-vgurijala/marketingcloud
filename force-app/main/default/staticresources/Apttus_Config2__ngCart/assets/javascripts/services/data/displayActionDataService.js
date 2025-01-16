(function() {
  angular.module('ngCPQ').service('DisplayActionDataService', [
    'ApiUtils', function(ApiUtils) {

      /*
        attributePageActions
        cartPageActions
        catalogPageActions
        optionPageActions
       */
      this.getDisplayActions = function(actionGroupType) {
        return ApiUtils.getStaticJson('DisplayActions').then((function(_this) {
          return function(resp) {
            return resp.data.displayActions[actionGroupType];
          };
        })(this));
      };
      return this;
    }
  ]);

}).call(this);
