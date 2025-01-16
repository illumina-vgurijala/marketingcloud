(function() {
  var LineItemOptionCart, lineItemOptionCartCtrl;

  lineItemOptionCartCtrl = function(CartService) {
    var vm;
    vm = this;
    vm.getColumnData = function(columnField) {
      return vm.item.lineItemSO[columnField];
    };
    return CartService.getCartColumns().then(function(columns) {
      return vm.optionsColumns = columns;
    });
  };

  lineItemOptionCartCtrl.$inject = ['CartService'];

  LineItemOptionCart = function(baseUrl) {
    var directive;
    directive = {
      scope: {
        item: '='
      },
      templateUrl: baseUrl + '/templates/directives/cart-line-item-option.html',
      controller: lineItemOptionCartCtrl,
      controllerAs: 'lineItemOption',
      bindToController: true
    };
    return directive;
  };

  LineItemOptionCart.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('lineItemOptionCart', LineItemOptionCart);

}).call(this);
