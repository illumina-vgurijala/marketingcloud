(function() {
  var CheckboxOptionList, CheckboxOptionListCtrl;

  CheckboxOptionListCtrl = function() {
    this.getLevel = function() {
      return parseInt(this.level);
    };
    return this;
  };

  CheckboxOptionListCtrl.$inject = [];

  CheckboxOptionList = function(baseUrl) {
    return {
      scope: {
        group: '=',
        level: '@'
      },
      templateUrl: baseUrl + "/templates/directives/options/checkbox-option-list.html",
      controller: CheckboxOptionListCtrl,
      controllerAs: 'list',
      bindToController: true
    };
  };

  CheckboxOptionList.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('checkboxOptionList', CheckboxOptionList);

}).call(this);
