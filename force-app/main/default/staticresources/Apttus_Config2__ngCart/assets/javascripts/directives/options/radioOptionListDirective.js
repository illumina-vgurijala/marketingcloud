(function() {
  var RadioOptionList, RadioOptionListCtrl;

  RadioOptionListCtrl = function() {
    this.getLevel = function() {
      return parseInt(this.level);
    };
    return this;
  };

  RadioOptionListCtrl.$inject = [];

  RadioOptionList = function(baseUrl) {
    return {
      scope: {
        group: '=',
        level: '@'
      },
      templateUrl: baseUrl + "/templates/directives/options/radio-option-list.html",
      controller: RadioOptionListCtrl,
      controllerAs: 'list',
      bindToController: true
    };
  };

  RadioOptionList.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('radioOptionList', RadioOptionList);

}).call(this);
