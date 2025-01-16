(function() {
  var ProposalSelect, ProposalSelectCtrl;

  ProposalSelectCtrl = function(CartService) {
    CartService.getCartHeader().then((function(_this) {
      return function(headerData) {
        _this.headerData = headerData;
        return CartService.getQuoteSummary(_this.headerData.BusinessObjectId__c).then(function(quoteData) {
          return _this.quoteData = quoteData;
        });
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
    this.businessObjectType = function() {
      var ref;
      return (ref = this.headerData) != null ? ref.BusinessObjectType__c : void 0;
    };
    return this.tabTitle = function() {
      return (this.businessObjectType()) + " " + (this.opportunityID());
    };
  };

  ProposalSelectCtrl.$inject = ['CartService'];

  ProposalSelect = function(baseUrl) {
    var proposalSelectLink;
    proposalSelectLink = function(scope, elem, attrs, ctrl) {
      var clickOutside, dropdown, proposal;
      dropdown = elem[0].querySelector('.proposal-select__display');
      clickOutside = document.querySelector('html');
      proposal = elem[0].querySelector('.proposal-select__proposal');
      scope.$watch('proposal.quoteData', (function(_this) {
        return function(html) {
          return angular.element(proposal).html(html);
        };
      })(this));
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
    return {
      bindToController: true,
      controller: ProposalSelectCtrl,
      controllerAs: 'proposal',
      restrict: 'AE',
      link: proposalSelectLink,
      templateUrl: baseUrl + "/templates/directives/proposal-select.html"
    };
  };

  ProposalSelect.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('proposalSelect', ProposalSelect);

}).call(this);
