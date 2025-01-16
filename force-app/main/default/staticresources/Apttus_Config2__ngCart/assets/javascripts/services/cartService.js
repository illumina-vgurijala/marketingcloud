(function() {
  angular.module('ngCPQ').service('CartService', [
    '$http', 'CartDataService', function($http, CartData) {
      var _cartColumnDetailAsFirstNode, _cartColumnsWithTypeClassNames, _checkBoxIdsToModels, _flattenOpts, _getCartTotal, _getLineItemIds, _getLineItemOptionLines, _getOptionsIds, _getlineItemsWithOptions, _setNullFieldTypes;
      this.canDupe = false;
      this.canRemove = false;
      this.getCartHeader = function() {
        return CartData.getCartHeader().then((function(_this) {
          return function(data) {
            return data.cartSO;
          };
        })(this));
      };
      this.getQuoteSummary = function(id) {
        return CartData.getQuoteSummary(id);
      };
      this.getCartLineItemsNew = function() {
        return CartData.getCartLineItemsNew().then((function(_this) {
          return function(lineItems) {
            lineItems.total = _getCartTotal(lineItems);
            return lineItems;
          };
        })(this));
      };
      this.getCartLineItems = function() {
        return CartData.getCartLineItems().then((function(_this) {
          return function(lineItems) {
            lineItems.total = _getCartTotal(lineItems);
            return lineItems;
          };
        })(this));
      };
      this.getLineItem = function(lineItemId) {
        return CartData.getLineItem(lineItemId).then((function(_this) {
          return function(lineItem) {
            return lineItem;
          };
        })(this));
      };
      this.getDisplayActions = function(type) {
        return CartData.getDisplayActions(type).then((function(_this) {
          return function(displayActions) {
            return displayActions;
          };
        })(this));
      };
      this.getCartTotalsDisplayData = function() {
        return CartData.getCartTotalsDisplayData().then((function(_this) {
          return function(data) {
            return data;
          };
        })(this));
      };
      this.addToCart = function(lineItemList) {
        return CartData.addToCart(lineItemList).then((function(_this) {
          return function(lineItems) {
            lineItems.total = _getCartTotal(lineItems);
            return lineItems;
          };
        })(this));
      };
      this.updateCartLineItems = function(lineItemList) {
        return CartData.updateCartLineItems(lineItemList).then((function(_this) {
          return function(lineItems) {
            lineItems.total = _getCartTotal(lineItems);
            return lineItems;
          };
        })(this));
      };
      this.configureCartLineItems = function(lineItemList) {
        return CartData.configureCartLineItems(lineItemList).then((function(_this) {
          return function(lineItems) {
            lineItems.total = _getCartTotal(lineItems);
            return lineItems;
          };
        })(this));
      };
      this.removeFromCart = function(lineItemList) {
        return CartData.removeFromCart(lineItemList).then((function(_this) {
          return function(lineItems) {
            lineItems.total = _getCartTotal(lineItems);
            return lineItems;
          };
        })(this));
      };
      this.getCartColumns = function() {
        return CartData.getCartColumns().then((function(_this) {
          return function(cartColumns) {
            return _setNullFieldTypes(_cartColumnDetailAsFirstNode(cartColumns));
          };
        })(this));
      };
      this.getCartTotalSummaryColumns = function() {
        return CartData.getCartTotalSummaryColumns().then((function(_this) {
          return function(resp) {
            return resp;
          };
        })(this));
      };
      this.selectAllLineItems = function() {
        return console.log('selecting all products');
      };
      this.getCheckboxModels = function() {
        return CartData.getCartLineItemsNew().then((function(_this) {
          return function(lineItems) {
            var checkboxModels, lineItemIds, lineItemsOptionLineIds;
            lineItemIds = lineItems.map(_getLineItemIds);
            lineItemsOptionLineIds = _getOptionsIds(lineItems.filter(_getlineItemsWithOptions).map(_getLineItemOptionLines).reduce(_flattenOpts, []));
            checkboxModels = {
              lineItems: lineItemIds,
              options: lineItemsOptionLineIds,
              all: _checkBoxIdsToModels([lineItemIds, lineItemsOptionLineIds].reduce(_flattenOpts, []))
            };
            _this.cartCheckBoxModels = checkboxModels;
            checkboxModels;
            return _this.getCheckedCount = function(list) {
              var k, totalChecked, v;
              totalChecked = 0;
              for (k in list) {
                v = list[k];
                totalChecked += v.selected;
              }
              return totalChecked;
            };
          };
        })(this));
      };
      _setNullFieldTypes = function(columns) {
        var removedNulls;
        removedNulls = columns.map(function(elem) {
          if (!elem.FieldType) {
            elem.FieldType = 'UNDEFINED';
          }
          return elem;
        });
        return removedNulls;
      };
      _cartColumnsWithTypeClassNames = function(columns) {
        var columnsWithClassNames;
        columnsWithClassNames = columns.map(function(elem) {
          if (elem.FieldName.indexOf('ProductId') > -1) {
            elem.columnClassName = 'detail';
          } else if (elem.FieldType) {
            elem.columnClassName = elem.FieldType.toLowerCase();
          } else {
            elem.columnClassName = 'undefined';
          }
          return elem;
        });
        return columnsWithClassNames;
      };
      _cartColumnDetailAsFirstNode = function(columns) {
        var detailColumnObj;
        columns = _cartColumnsWithTypeClassNames(columns);
        detailColumnObj = columns.filter(function(elem, index, columns) {
          if (elem.FieldName && elem.FieldName.indexOf('ProductId') > -1) {
            columns.splice(index, 1);
            return elem;
          }
        });
        columns.unshift(detailColumnObj[0]);
        return columns;
      };
      _getCartTotal = function(lineItems) {
        var i, item, len, total;
        total = 0;
        if (lineItems.length > 0) {
          for (i = 0, len = lineItems.length; i < len; i++) {
            item = lineItems[i];
            total += item.lineItemSO.NetPrice__c * item.lineItemSO.Quantity__c;
          }
        }
        return total;
      };
      _getlineItemsWithOptions = function(lineItem) {
        return lineItem.optionLines;
      };
      _getLineItemOptionLines = function(lineItem) {
        return lineItem.optionLines;
      };
      _getLineItemIds = function(lineItem) {
        return lineItem.lineItemSO.ProductId__r.Id + lineItem.txnPrimaryLineNumber;
      };
      _flattenOpts = function(a, b) {
        return a.concat(b);
      };
      _getOptionsIds = function(options) {
        var ids, recurseOptions;
        ids = [];
        recurseOptions = function(options) {
          var option, remOpts;
          if (!(options != null ? options.length : void 0)) {
            return;
          }
          option = options[0];
          remOpts = options.slice(1);
          ids.push(option.lineItemSO.OptionId__r.Id + option.txnPrimaryLineNumber);
          if (option.optionLines) {
            return recurseOptions(option.optionLines);
          }
          if (remOpts.length > 0) {
            return recurseOptions(remOpts);
          } else {
            return ids;
          }
        };
        return recurseOptions(options);
      };
      _checkBoxIdsToModels = function(ids) {
        var model, setupModels;
        model = {};
        setupModels = function(ids) {
          var id, remainIds;
          id = ids[0];
          remainIds = ids.slice(1);
          model[id] = {};
          model[id].selected = false;
          if (remainIds.length > 0) {
            return setupModels(remainIds);
          } else {
            return model;
          }
        };
        return setupModels(ids);
      };
      return this;
    }
  ]);

}).call(this);
