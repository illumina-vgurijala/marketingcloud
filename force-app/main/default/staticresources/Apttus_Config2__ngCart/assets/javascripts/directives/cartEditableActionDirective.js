(function() {
  var CartEditableAction, cartEditableActionCtrl;

  cartEditableActionCtrl = function(CartService, ngCPQLabels) {
    return this.labels = ngCPQLabels.labels;
  };

  cartEditableActionCtrl.$inject = ['CartService', 'ngCPQLabels'];

  CartEditableAction = function(baseUrl) {
    var directive;
    directive = {
      restrict: 'AEC',
      templateUrl: baseUrl + '/templates/directives/cart-editable-action.html',
      controller: cartEditableActionCtrl,
      controllerAs: 'cartEditableAction',
      bindToController: true
    };
    return directive;
  };

  CartEditableAction.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('cartEditableAction', CartEditableAction);

}).call(this);
