(function() {
  var ConfigurationSummary, ConfigurationSummaryCtrl;

  ConfigurationSummaryCtrl = function($state, Configure, ngCPQLabels) {
    this.standardPrice = function(chargeLine) {
      return chargeLine.lineItemSO.NetPrice__c;
    };
    this.multiplyTotal = function() {
      return this.lineItem.topLineTotal();
    };
    this.labels = ngCPQLabels.labels;
    this.lineItem = Configure.lineItem;
    return this;
  };

  ConfigurationSummaryCtrl.$inject = ['$state', 'ConfigureService', 'ngCPQLabels'];

  ConfigurationSummary = function(baseUrl) {
    return {
      templateUrl: baseUrl + "/templates/directives/configuration-summary.html",
      controller: ConfigurationSummaryCtrl,
      controllerAs: 'summary',
      bindToController: true
    };
  };

  ConfigurationSummary.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('configurationSummary', ConfigurationSummary);

}).call(this);
