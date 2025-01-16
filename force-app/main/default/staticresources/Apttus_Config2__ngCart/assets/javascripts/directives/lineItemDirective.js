(function() {
  var LineItem, lineItemCtrl;

  lineItemCtrl = function($state, baseUrl, baseFileUrl, CartService, ngCPQLabels) {
    this.baseFileUrl = baseFileUrl;
    this.labels = ngCPQLabels.labels;
    this.addToCart = function() {
      return CartService.addToCart(this.product);
    };
    this.updateQuantity = function(lineItem) {
      return console.log('updating quantity');
    };
    return this.configure = function() {
      return this.addToCart().then((function(_this) {
        return function(lineItems) {
          var tpln;
          tpln = lineItems[lineItems.length - 1].txnPrimaryLineNumber;
          return $state.go('configure', {
            txnPrimaryLineNumber: tpln
          });
        };
      })(this));
    };
  };

  lineItemCtrl.$inject = ['$state', 'baseUrl', 'baseFileUrl', 'CartService', 'ngCPQLabels'];

  LineItem = function(baseUrl) {
    return {
      scope: {
        product: '='
      },
      templateUrl: baseUrl + "/templates/directives/product-line-item.html",
      controller: lineItemCtrl,
      controllerAs: 'lineItem',
      bindToController: true,
      restrict: 'E'
    };
  };

  LineItem.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('lineItem', LineItem);

}).call(this);
