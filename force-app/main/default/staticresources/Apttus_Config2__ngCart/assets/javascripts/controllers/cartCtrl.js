(function() {
  var CartCtrl;

  CartCtrl = function($scope, CartService) {
    var mainCart;
    mainCart = this;
    $scope.cartState = 'detailed-view';
    $scope.changeCartState = function(changeTo) {
      return $scope.cartState = changeTo;
    };
    $scope.isChecked = function() {
      if ($scope.checkedItems > 0) {
        return true;
      } else {
        return false;
      }
    };
    CartService.getCartLineItems().then(function(res) {
      return mainCart.cartLineItems = res;
    });
    $scope.productChecks = [
      {
        'id': 1,
        'name': 'cpq-1.0',
        'checked': false,
        'expanded': true
      }, {
        'id': 2,
        'name': 'cpq-master',
        'checked': false,
        'expanded': true
      }, {
        'id': 3,
        'name': 'echosign-cpq',
        'checked': false
      }, {
        'id': 4,
        'name': 'echosign-cpq-2',
        'checked': false
      }, {
        'id': 5,
        'name': 'cpq-admin',
        'checked': false
      }, {
        'id': 6,
        'name': 'cpq-installation',
        'checked': false
      }, {
        'id': 7,
        'name': 'rack-server',
        'checked': false
      }, {
        'id': 8,
        'name': 'dell-storage-center',
        'checked': false
      }
    ];
    $scope.cartCols = {
      "overview": [
        {
          name: 'service-level',
          label: 'Service Level'
        }, {
          name: 'quantity',
          label: 'Qty'
        }, {
          name: 'date-range',
          label: 'Date Range'
        }, {
          name: 'adjustment-type',
          label: 'Adjustment Type'
        }, {
          name: 'amount',
          label: 'Amount'
        }, {
          name: 'net-price',
          label: 'Net Price'
        }
      ],
      "detailed-view": [
        {
          name: 'level',
          label: 'Level'
        }, {
          name: 'list-price',
          label: 'List Price'
        }, {
          name: 'base-price',
          label: 'Base Price'
        }, {
          name: 'quantity',
          label: 'Qty'
        }, {
          name: 'dates',
          label: 'Dates'
        }, {
          name: 'base-ext-price',
          label: 'Base Ext Price'
        }, {
          name: 'options',
          label: 'Options'
        }, {
          name: 'ext-price',
          label: 'Ext Price'
        }, {
          name: 'adjustment',
          label: 'Adjustment'
        }, {
          name: 'adj-price',
          label: 'Adj Price'
        }, {
          name: 'net-price',
          label: 'Net Price'
        }
      ]
    };
    $scope.toggleExpanded = function(id) {
      return $scope.productChecks[id].expanded = !$scope.productChecks[id].expanded;
    };
    $scope.$watch('productChecks', (function(checks) {
      $scope.checkedItems = 0;
      angular.forEach(checks, function(check) {
        if (check.checked) {
          $scope.checkedItems += 1;
        }
      });
    }), true);
    $scope.checkAll = function() {
      if ($scope.checkedItems > 0) {
        return angular.forEach($scope.productChecks, function(check) {
          return check.checked = false;
        });
      } else {
        return angular.forEach($scope.productChecks, function(check) {
          return check.checked = true;
        });
      }
    };
    $scope.addToCart = function(product) {
      var lineItemList;
      lineItemList = [
        {
          lineItemSO: {
            ProductId__c: product.productSO.Id,
            Quantity__c: product.quantity || 1,
            ProductId__r: {
              Name: product.productSO.Name
            }
          },
          sequence: CartService.itemsInCart + 1
        }
      ];
      return CartService.addToCart(lineItemList).then(function(lineItems) {
        $scope.cart = lineItems;
        return $scope.total = lineItems.total;
      });
    };
    $scope.removeFromCart = function(lineItem) {
      var lineItemList;
      lineItemList = [
        lineItem.lineItemSO, {
          sequence: CartService.itemsInCart + 1
        }
      ];
      return CartService.removeFromCart(lineItemList).then(function(lineItems) {
        console.log(lineItems);
        $scope.cart = lineItems;
        return $scope.cartTotal = lineItems.total;
      });
    };
    return mainCart;
  };

  CartCtrl.$inject = ['$scope', 'CartService'];

  angular.module('ngCPQ').controller('cartCtrl', CartCtrl);

}).call(this);
