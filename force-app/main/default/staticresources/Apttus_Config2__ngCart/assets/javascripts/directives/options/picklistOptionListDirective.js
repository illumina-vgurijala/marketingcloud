(function() {
  var PicklistOptionList, PicklistOptionListCtrl;

  PicklistOptionListCtrl = function(Configure) {
    var i, len, option, ref, ref1, ref2, ref3, ref4, ref5, ref6;
    this.hasChildren = function() {
      return this.selected && (this.nextLevel() < 4) && this.selected.optionLine.hasOptions();
    };
    this.getLevel = function() {
      return parseInt(this.level);
    };
    this.nextLevel = function() {
      return this.getLevel() + 1;
    };
    this.price = function() {
      var ref;
      return ((ref = this.selected) != null ? ref.price() : void 0) || '-';
    };
    this.selectOption = function(option) {
      var ref;
      if (!option) {
        return;
      }
      this.quantity = ((ref = option.optionLine.chargeLines) != null ? ref[0].lineItemSO.Quantity__c : void 0) || option.data.DefaultQuantity__c;
      return option.toggleSelected().then((function(_this) {
        return function() {
          return _this.selected = option;
        };
      })(this));
    };
    ref = this.group.options;
    for (i = 0, len = ref.length; i < len; i++) {
      option = ref[i];
      if (option.isSelected()) {
        this.selected = option;
      }
    }
    this.quantity = ((ref1 = this.selected) != null ? (ref2 = ref1.optionLine) != null ? (ref3 = ref2.chargeLines) != null ? (ref4 = ref3[0].lineItemSO) != null ? ref4.Quantity__c : void 0 : void 0 : void 0 : void 0) || ((ref5 = this.selected) != null ? (ref6 = ref5.data) != null ? ref6.DefaultQuantity__c : void 0 : void 0);
    return this;
  };

  PicklistOptionListCtrl.$inject = ['ConfigureService'];

  PicklistOptionList = function(baseUrl, $compile) {
    var addSubGroup, picklistLink, removeSubGroup;
    addSubGroup = function(scope, element) {
      var compiler, newElement;
      newElement = angular.element(document.createElement('option-groups'));
      newElement.attr('level', "" + (scope.list.nextLevel()));
      newElement.attr('line-item', 'list.selected.optionLine');
      compiler = $compile(newElement);
      return compiler(scope, (function(_this) {
        return function(cloned, scope) {
          return element.append(cloned);
        };
      })(this));
    };
    removeSubGroup = function(element) {
      return element.find('option-groups').remove();
    };
    picklistLink = function(scope, element, attrs) {
      return scope.$watch('list.selected', function(newValue, oldValue) {
        removeSubGroup(element);
        if (scope.list.hasChildren()) {
          return addSubGroup(scope, element);
        }
      });
    };
    return {
      scope: {
        group: '=',
        optionLines: '=',
        level: '@'
      },
      link: picklistLink,
      templateUrl: baseUrl + "/templates/directives/options/picklist-option-list.html",
      controller: PicklistOptionListCtrl,
      controllerAs: 'list',
      bindToController: true
    };
  };

  PicklistOptionList.$inject = ['baseUrl', '$compile'];

  angular.module('ngCPQ').directive('picklistOptionList', PicklistOptionList);

}).call(this);
