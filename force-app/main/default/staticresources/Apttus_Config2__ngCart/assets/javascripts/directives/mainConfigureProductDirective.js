(function() {
  var MainConfigureProduct, MainConfigureProductController;

  MainConfigureProductController = function($stateParams, CartService, Configure, Labels) {
    this.lineItem = Configure.lineItem;
    this.view = $stateParams.step ? $stateParams.step : this.lineItem.hasAttrs() ? 'attributes' : 'options';
    this.labelFor = (function(_this) {
      return function(button) {
        return Labels[button.ActionLabelName] || button.ActionLabelName;
      };
    })(this);
    return CartService.getLineItem($stateParams.txnPrimaryLineNumber).then((function(_this) {
      return function(data) {
        return CartService.getDisplayActions().then(function(buttons) {
          return _this.buttons = buttons;
        });
      };
    })(this));
  };

  MainConfigureProductController.$inject = ['$stateParams', 'CartService', 'ConfigureService', 'ngCPQLabels'];

  MainConfigureProduct = function(baseUrl) {
    return {
      controller: MainConfigureProductController,
      controllerAs: 'config',
      bindToController: true
    };
  };

  MainConfigureProduct.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('mainConfigureProduct', MainConfigureProduct);

}).call(this);
