(function() {
  var CartHeader, cartHeaderCtrl;

  cartHeaderCtrl = function(CartService, ngCPQLabels, $scope) {
    var vm;
    vm = this;
    vm.allSelected = false;
    vm.labels = ngCPQLabels.labels;
    vm.canDupe = function() {
      return CartService.canDupe;
    };
    vm.canRemove = function() {
      return CartService.canRemove;
    };
    vm.isSelected = function() {
      var checkModels, size;
      if (!CartService.cartCheckBoxModels) {

      } else {
        checkModels = CartService.cartCheckBoxModels.all;
        size = Object.keys(CartService.cartCheckBoxModels.lineItems).length;
        return vm.allSelected = CartService.getCheckedCount(checkModels) >= size;
      }
    };
    vm.checkAll = function() {
      var checkModels, k, topLevelIds, v;
      checkModels = CartService.cartCheckBoxModels.all;
      topLevelIds = CartService.cartCheckBoxModels.lineItems;
      for (k in topLevelIds) {
        v = topLevelIds[k];
        if (checkModels[v]) {
          checkModels[v].selected = !vm.allSelected;
        }
      }
      vm.allSelected = !vm.allSelected;
      if (CartService.getCheckedCount(checkModels) > 0) {
        return CartService.canDupe = CartService.canRemove = true;
      } else {
        return CartService.canDupe = CartService.canRemove = false;
      }
    };
    vm.createDupe = function(lineItems) {
      return console.log('create dupe');
    };
    vm.removeFromCart = function(lineItems) {
      return console.log('remove from cart');
    };
    return vm.changeCartState = function() {
      return console.log('change state');
    };
  };

  cartHeaderCtrl.$inject = ['CartService', 'ngCPQLabels', '$scope'];

  CartHeader = function(baseUrl) {
    var directive;
    directive = {
      templateUrl: baseUrl + '/templates/directives/cart-header.html',
      controller: cartHeaderCtrl,
      controllerAs: 'cartHeader',
      bindToController: true
    };
    return directive;
  };

  CartHeader.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('cartHeader', CartHeader);

}).call(this);
