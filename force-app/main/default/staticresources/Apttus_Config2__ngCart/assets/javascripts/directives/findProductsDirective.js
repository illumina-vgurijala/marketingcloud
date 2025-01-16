(function() {
  var FindProducts, findProductsLink, findProductsLinkCtrl;

  findProductsLink = function(scope, elem, attrs, ctrl) {
    var input;
    input = elem.find('input');
    return input.on('keypress', function(e) {
      var key;
      key = e.which || e.keyCode;
      if (key === 13) {
        return ctrl.goToState(input[0].value);
      }
    });
  };

  findProductsLinkCtrl = function($state) {
    var fp;
    fp = this;
    return fp.goToState = function(searchTerm) {
      return $state.go('search', {
        term: searchTerm
      });
    };
  };

  findProductsLinkCtrl.$inject = ['$state'];

  FindProducts = function(baseUrl, $state) {
    var directive;
    directive = {
      scope: {},
      templateUrl: baseUrl + '/templates/directives/find-products-block.html',
      controller: findProductsLinkCtrl,
      controllerAs: 'fp',
      link: findProductsLink,
      bindToController: true
    };
    return directive;
  };

  FindProducts.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('findProducts', FindProducts);

}).call(this);
