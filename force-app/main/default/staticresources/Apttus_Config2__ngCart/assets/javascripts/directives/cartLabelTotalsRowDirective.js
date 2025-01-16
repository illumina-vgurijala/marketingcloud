(function() {
  var CartLabelTotals, CartLabelTotalsCtrl;

  CartLabelTotalsCtrl = function(CartService) {
    var vm;
    vm = this;
    return CartService.getCartTotalSummaryColumns().then(function(res) {
      return vm.displayColumns = res;
    });
  };

  CartLabelTotalsCtrl.$inject = ['CartService'];

  CartLabelTotals = function(baseUrl) {
    var directive;
    directive = {
      scope: {
        item: '='
      },
      templateUrl: baseUrl + '/templates/directives/cart-label-total-row.html',
      controller: CartLabelTotalsCtrl,
      controllerAs: 'cartLabelTotals',
      bindToController: true
    };
    return directive;
  };

  CartLabelTotals.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('cartLabelTotals', CartLabelTotals);

}).call(this);
