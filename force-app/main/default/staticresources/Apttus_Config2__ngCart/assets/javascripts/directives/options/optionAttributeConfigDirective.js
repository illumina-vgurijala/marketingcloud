(function() {
  var OptionAttrConfigCtrl, OptionAttributeConfig;

  OptionAttrConfigCtrl = function(_, Configure) {
    this.valuesForAttr = function(attr) {
      var ref;
      return ((ref = this.lineItem.fields[attr]) != null ? ref.pickListEntries : void 0) || [];
    };
    this.attributeLabel = function(attr) {
      var ref;
      return (ref = this.lineItem.fields[attr]) != null ? ref.Label : void 0;
    };
    this.attributeHelp = function(attr) {
      var ref;
      return (ref = this.lineItem.fields[attr]) != null ? ref.inlineHelpText : void 0;
    };
    this.isPicklist = function(attr) {
      var ref;
      return ((ref = this.lineItem.fields[attr]) != null ? ref.FieldType : void 0) === 'PICKLIST';
    };
    this.isTextArea = function(attr) {
      var ref;
      return _.includes(['TEXTAREA', 'DOUBLE'], (ref = this.lineItem.fields[attr]) != null ? ref.FieldType : void 0);
    };
    this.isMultiPickList = function(attr) {
      var ref;
      return ((ref = this.lineItem.fields[attr]) != null ? ref.FieldType : void 0) === 'MULTIPICKLIST';
    };
    this.attrSO = function() {
      return this.lineItem.attrSO();
    };
    return this;
  };

  OptionAttrConfigCtrl.$inject = ['lodash', 'ConfigureService'];

  OptionAttributeConfig = function(baseUrl) {
    return {
      scope: {
        lineItem: '='
      },
      templateUrl: baseUrl + "/templates/directives/options/option-attribute-config.html",
      controller: OptionAttrConfigCtrl,
      controllerAs: 'attrs',
      bindToController: true,
      restrict: 'E'
    };
  };

  OptionAttributeConfig.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('optionAttributeConfig', OptionAttributeConfig);

}).call(this);
