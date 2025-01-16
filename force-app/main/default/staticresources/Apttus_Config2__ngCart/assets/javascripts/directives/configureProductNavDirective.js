(function() {
  var ConfigureProductNav, ConfigureProductNavCtrl, configureProductNavLink;

  configureProductNavLink = function(scope, elem, attrs) {};

  ConfigureProductNavCtrl = function($state, $stateParams, Configure) {
    this.config = Configure;
    return this.changeView = function(newView) {
      var tpln;
      tpln = $stateParams.txnPrimaryLineNumber;
      return $state.go('configure', {
        txnPrimaryLineNumber: tpln,
        step: newView
      });
    };
  };

  ConfigureProductNavCtrl.$inject = ['$state', '$stateParams', 'ConfigureService'];

  ConfigureProductNav = function(baseUrl) {
    return {
      templateUrl: baseUrl + "/templates/directives/configure-product-nav.html",
      controller: ConfigureProductNavCtrl,
      controllerAs: 'nav',
      link: configureProductNavLink,
      bindToController: true,
      scope: {
        view: '='
      }
    };
  };

  ConfigureProductNav.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('configureProductNav', ConfigureProductNav);

}).call(this);
