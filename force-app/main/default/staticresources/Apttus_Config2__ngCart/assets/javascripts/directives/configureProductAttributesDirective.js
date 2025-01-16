(function() {
  var ConfigureProductAttributes, ConfigureProductAttributesCtrl;

  ConfigureProductAttributesCtrl = function(_, ConfigureService) {
    this.configure = ConfigureService;
    this.valuesForAttr = function(attr) {
      var ref, ref1, ref2, ref3;
      //console.log('values', attr, (ref = this.configure.lineItem.fields) != null ? (ref1 = ref[attr]) != null ? ref1.pickListEntries : void 0 : void 0);
      return ((ref2 = this.configure.lineItem.fields) != null ? (ref3 = ref2[attr]) != null ? ref3.pickListEntries : void 0 : void 0) || [];
    };
    this.attributeLabel = function(attr) {
      var ref, ref1;
      return (ref = this.configure.lineItem.fields) != null ? (ref1 = ref[attr]) != null ? ref1.Label : void 0 : void 0;
    };
    this.attributeHelp = function(attr) {
      var ref, ref1;
      return (ref = this.configure.lineItem.fields) != null ? (ref1 = ref[attr]) != null ? ref1.inlineHelpText : void 0 : void 0;
    };
    this.isPicklist = function(attr) {
      var ref, ref1;
      return ((ref = this.configure.lineItem.fields) != null ? (ref1 = ref[attr]) != null ? ref1.FieldType : void 0 : void 0) === 'PICKLIST';
    };
    this.isTextArea = function(attr) {
      var ref, ref1;
      return _.includes(['TEXTAREA', 'DOUBLE'], (ref = this.configure.lineItem.fields) != null ? (ref1 = ref[attr]) != null ? ref1.FieldType : void 0 : void 0);
    };
    this.isMultiPickList = function(attr) {
      var ref, ref1;
      return ((ref = this.configure.lineItem.fields) != null ? (ref1 = ref[attr]) != null ? ref1.FieldType : void 0 : void 0) === 'MULTIPICKLIST';
    };
    return this.attrSO = function() {
      return this.configure.lineItem.attrSO();
    };
  };

  ConfigureProductAttributesCtrl.$inject = ['lodash', 'ConfigureService'];

  ConfigureProductAttributes = function(baseUrl) {
    return {
      restrict: 'AE',
      templateUrl: baseUrl + "/templates/directives/configure-product-attributes.html",
      controller: ConfigureProductAttributesCtrl,
      controllerAs: 'config',
      bindToController: true
    };
  };

  ConfigureProductAttributes.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('configureProductAttributes', ConfigureProductAttributes);

}).call(this);
