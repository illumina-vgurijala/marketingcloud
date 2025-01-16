(function() {
  var CartLabel, cartLabelLink;

  cartLabelLink = function(scope, elem, attr) {
    var cart, globalHeader, header, processTrail, scrollHandler;
    header = document.querySelector('.cart-header');
    globalHeader = document.querySelector('.header-global');
    processTrail = document.querySelector('.process-trail');
    scrollHandler = function() {
      if (angular.element(cart).hasClass('main-cart-wrapper--header-fixed')) {
        return elem.css({
          'top': header.getBoundingClientRect().height - cart.getBoundingClientRect().top - 16 + 'px'
        });
      } else {
        return elem.css({
          'top': '0'
        });
      }
    };
    cart = document.querySelector('.main-cart-wrapper');
    return window.addEventListener('scroll', scrollHandler);
  };

  CartLabel = function() {
    var directive;
    directive = {
      link: cartLabelLink
    };
    return directive;
  };

  angular.module('ngCPQ').directive('cartLabelField', CartLabel);

}).call(this);
