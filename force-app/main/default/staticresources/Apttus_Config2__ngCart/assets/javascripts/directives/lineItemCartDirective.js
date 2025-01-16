(function() {
  var LineItemCart, lineItemCartCtrl, lineItemCartLink;

  lineItemCartLink = function(scope, elem, attrs) {
    var lineItem;
    lineItem = elem[0];
  };

  lineItemCartCtrl = function(CartService, ngCPQLabels) {
    var vm;
    vm = this;
    console.log(this.item);
    vm.getColumnData = function(columnField) {
      return vm.item.lineItemSO[columnField];
    };
    CartService.getCartColumns().then(function(columns) {
      return vm.columnKeys = columns.map(function(element) {
        var replace_r;
        if (element.FieldType === 'REFERENCE') {
          replace_r = element.FieldName.replace('__c', '__r');
          element.FieldName = replace_r;
        }
        if (element.FieldName.indexOf('ProductId__r') > -1) {
          element.FieldType = 'DETAIL';
        }
        return element;
      });
    });
    vm.labels = ngCPQLabels.labels;

    /*
    
      Line Item Field Types
        
        PERCENT - In SFDC platform this type of field allows users to enter a number and the system automatically displays the number with percent symbol
        REFERENCE - This is a look up field
        PICKLIST - Allows users to select a value from a list of drop down list
        DOUBLE - This is the type for all number fields
        DATE - Date fields should be displayed based on user locale, available as angular constants
        CURRENCY - Currency field should be formatted based on service filter function for currency
     */
    vm.toggleExpanded = function(lineItem) {
      if (!lineItem.isExpanded) {
        lineItem.isExpanded = false;
      }
      return lineItem.isExpanded = !lineItem.isExpanded;
    };
    return vm;
  };

  lineItemCartCtrl.$inject = ['CartService', 'ngCPQLabels', '$compile'];

  LineItemCart = function(baseUrl) {
    var directive;
    directive = {
      restrict: 'AE',
      scope: {
        item: '='
      },
      link: lineItemCartLink,
      templateUrl: baseUrl + '/templates/directives/cart-line-item-tr.html',
      controller: lineItemCartCtrl,
      controllerAs: 'lineItemCart',
      bindToController: true
    };
    return directive;
  };

  LineItemCart.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('lineItemCart', LineItemCart);

}).call(this);
