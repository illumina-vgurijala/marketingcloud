(function() {
  angular.module('ngCPQ').service('ConfigureService', [
    'CartDataService', 'LineItemService', 'ConfigurationDataService', function(CartData, LineItem, ConfigurationDataService) {
      this.setLineitemToConfigure = function(txnPrimaryLineNumber) {
        return CartData.getLineItem(txnPrimaryLineNumber).then((function(_this) {
          return function(lineItemData) {
            return LineItem.create(lineItemData).then(function(lineItem) {
              _this.lineItem = lineItem;
              return ConfigurationDataService.getCustomSettings().then(function(settings) {
                return _this.pageSettings = settings;
              });
            });
          };
        })(this));
      };
      this.save = function() {
        return CartData.addToCart(this.lineItem, true);
      };
      return this;
    }
  ]);

}).call(this);
