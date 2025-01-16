(function() {
  var GlobalHeader, HeaderCtrl;

  HeaderCtrl = function(CartService) {
    CartService.getCartHeader().then((function(_this) {
      return function(headerData) {
        return _this.headerData = headerData;
      };
    })(this));
    this.customerName = function() {
      var ref, ref1;
      return (ref = this.headerData) != null ? (ref1 = ref.AccountId__r) != null ? ref1.Name : void 0 : void 0;
    };
    this.opportunityName = function() {
      var ref, ref1, ref2;
      return (ref = this.headerData) != null ? (ref1 = ref.Proposald__r) != null ? (ref2 = ref1.Apttus_Proposal__Opportunity__r) != null ? ref2.Name : void 0 : void 0 : void 0;
    };
    this.opportunityID = function() {
      var ref, ref1;
      return (ref = this.headerData) != null ? (ref1 = ref.Proposald__r) != null ? ref1.Name : void 0 : void 0;
    };
    return this.businessObjectType = function() {
      var ref;
      return (ref = this.headerData) != null ? ref.BusinessObjectType__c : void 0;
    };
  };

  HeaderCtrl.$inject = ['CartService'];

  GlobalHeader = function(baseUrl) {
    return {
      templateUrl: baseUrl + "/templates/directives/global-header.html",
      controller: HeaderCtrl,
      controllerAs: 'header',
      bindToController: true
    };
  };

  GlobalHeader.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('globalHeader', GlobalHeader);

}).call(this);
