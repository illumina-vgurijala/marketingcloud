(function() {
  var OptionGroups, OptionGroupsCtrl;

  OptionGroupsCtrl = function(Configure) {
    this.config = Configure;
    this.getLevel = function() {
      return parseInt(this.level);
    };
    this.hasAttrConfig = function() {
      return this.lineItem.hasAttrs() && !this.lineItem.isTopLevel();
    };
    return this;
  };

  OptionGroupsCtrl.$inject = ['ConfigureService'];

  OptionGroups = function(baseUrl) {
    return {
      scope: {
        lineItem: '=',
        level: '@'
      },
      templateUrl: baseUrl + "/templates/directives/options/option-groups.html",
      controller: OptionGroupsCtrl,
      controllerAs: 'groups',
      bindToController: true,
      restrict: 'E'
    };
  };

  OptionGroups.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('optionGroups', OptionGroups);

}).call(this);
