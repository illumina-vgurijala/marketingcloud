(function() {
  var DropdownList, dropdownListCtrl;

  dropdownListCtrl = function() {

    /*
    for test purposes only
    vm.optionsStatic = [
        {
          "active": true,
          "defaultValue": false,
          "label": "License Fee",
          "value": "License Fee"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "Subscription Fee",    
          "value": "Subscription Fee"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "Implementation Fee",
          "value": "Implementation Fee"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "Installation Fee",
          "value": "Installation Fee"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "Maintenance Fee",
          "value": "Maintenance Fee"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "License",
          "value": "License"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "Monthly Support Fee",
          "value": "Monthly Support Fee"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "Adjustment",
          "value": "Adjustment"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "Sales Tax",
          "value": "Sales Tax"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "Shipping & Handling",
          "value": "Shipping & Handling"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "Perpetual Site",
          "value": "Perpetual Site"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "Perpetual Workstation",
          "value": "Perpetual Workstation"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "Site Term 12 Month",
          "value": "Site Term 12 Month"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "Site Subscription 12 Month",
          "value": "Site Subscription 12 Month"
        },
        {
          "active": true,
          "defaultValue": false,
          "label": "Standard Price",
          "value": "Standard Price"
        }
      ]
     */
  };

  DropdownList = function(baseUrl) {
    var directive;
    directive = {
      scope: {
        options: '=',
        model: '='
      },
      template: '<div class="select-override"> <select ng-model="dropdownList.model" ng-options="value.value as value.label for value in dropdownList.options"></select> </div>',
      controller: dropdownListCtrl,
      controllerAs: 'dropdownList',
      bindToController: true
    };
    return directive;
  };

  angular.module('ngCPQ').directive('dropdownList', DropdownList);


  /*
  
  <div class="select-override">
        <select ng-model="config.groups.lineItems[0].attributeValueSO[attr.Field__c]" ng-options="value.value as value.label for value in config.valuesForAttr(attr.Field__c)" class="ng-pristine ng-untouched ng-valid"><option value="0" selected="selected" label="Black">Black</option><option value="1" label="Red">Red</option><option value="2" label="Pink">Pink</option></select>
      </div>
   */

}).call(this);
