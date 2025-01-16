(function() {
  var MiniCart, miniCartCtrl, miniCartLink;

  miniCartLink = function(scope, elem, attrs) {
    var clickOutside, dropdown;
    dropdown = elem[0].querySelector('.mini-cart__display');
    clickOutside = document.querySelector('html');
    clickOutside.addEventListener('click', function() {
      return elem.removeClass('is--open');
    });
    elem[0].addEventListener('click', function(e) {
      return e.stopPropagation();
    });
    return dropdown.addEventListener('click', function(e) {
      if (elem.hasClass('is--open')) {
        return elem.removeClass('is--open');
      } else {
        return elem.addClass('is--open');
      }
    });
  };

  miniCartCtrl = function(CartService) {
    var activate, miniCart;
    miniCart = this;
    activate = function() {
      return CartService.getCartLineItems().then(function(lineItems) {
        miniCart.cart = lineItems;
        return miniCart.cartTotal = lineItems.total;
      });
    };
    this.removeFromCart = function(lineItem) {
      return CartService.removeFromCart(lineItem);
    };
    activate();
    return miniCart.removeFromCart = function(lineItem) {
      return CartService.removeFromCart(lineItem);
    };
  };

  miniCartCtrl.$inject = ['CartService'];

  MiniCart = function(baseUrl) {
    var directive;
    directive = {
      link: miniCartLink,
      controller: miniCartCtrl,
      controllerAs: 'miniCart',
      bindToController: true
    };
    return directive;
  };

  angular.module('ngCPQ').directive('miniCart', MiniCart);

}).call(this);
