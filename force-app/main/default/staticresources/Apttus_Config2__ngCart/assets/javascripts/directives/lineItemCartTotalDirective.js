(function() {
  var LineItemCartTotal, lineItemCartTotalCtrl, lineItemCartTotalLink;

  lineItemCartTotalLink = function(scope, elem, attrs) {
    var lineItem;
    lineItem = elem[0];
  };

  lineItemCartTotalCtrl = function(CartService) {
    var vm;
    vm = this;
    vm.getSummaryItem = function(key) {
      if (vm.item.summaryGroupSO[key]) {
        return vm.item.summaryGroupSO[key];
      } else {

      }
    };
    return CartService.getCartTotalSummaryColumns().then(function(res) {
      return vm.displayColumns = res;
    });
  };

  lineItemCartTotalCtrl.$inject = ['CartService', 'ngCPQLabels', '$compile'];

  LineItemCartTotal = function(baseUrl) {
    var directive;
    directive = {
      scope: {
        item: '='
      },
      link: lineItemCartTotalLink,
      templateUrl: baseUrl + '/templates/directives/cart-line-item-total.html',
      controller: lineItemCartTotalCtrl,
      controllerAs: 'lineItemCartTotal',
      bindToController: true
    };
    return directive;
  };

  LineItemCartTotal.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('lineItemCartTotal', LineItemCartTotal);

}).call(this);
