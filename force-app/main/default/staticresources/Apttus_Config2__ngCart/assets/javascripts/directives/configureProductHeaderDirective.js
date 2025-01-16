(function() {
  var ConfigureProductHeader, ConfigureProductHeaderCtrl, configureProductHeaderLink;

  configureProductHeaderLink = function(scope, elem, attrs) {};

  ConfigureProductHeaderCtrl = function($stateParams, Configure, baseFileUrl) {
    var lineItemSO;
    this.config = Configure;
    this.lineItem = this.config.lineItem;
    lineItemSO = this.lineItem.data.chargeLines[0].lineItemSO;
    this.productDescription = lineItemSO.ProductId__r.Description;
    this.quantity = lineItemSO.Quantity__c;
    this.term = lineItemSO.SellingTerm__c;
    this.frequency = lineItemSO.SellingFrequency__c;
    return this.img_url = "" + baseFileUrl + lineItemSO.ProductId__r.IconId__c;
  };

  ConfigureProductHeaderCtrl.$inject = ['$stateParams', 'ConfigureService', 'baseFileUrl'];

  ConfigureProductHeader = function(baseUrl) {
    return {
      restrict: 'AE',
      templateUrl: baseUrl + "/templates/directives/configure-product-header.html",
      controller: ConfigureProductHeaderCtrl,
      controllerAs: 'configureProductHeader',
      link: configureProductHeaderLink,
      bindToController: true
    };
  };

  ConfigureProductHeader.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('configureProductHeader', ConfigureProductHeader);

}).call(this);
