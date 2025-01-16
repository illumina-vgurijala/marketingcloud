(function() {
  angular.module('ngCPQ').service('CartDataService', [
    '$q', 'ApiUtils', 'messenger', function($q, ApiUtils, Messenger) {
      this.addToCart = function(lineItemList, showConstraint) {
        if (showConstraint == null) {
          showConstraint = false;
        }
        return ApiUtils.getStaticJson('cart').then((function(_this) {
          return function(cartResponse) {
            if (showConstraint) {
              return ApiUtils.getStaticJson('rule_message_prompt').then(function(res) {
                var rule_res;
                rule_res = res.data.ruleActions;
                Messenger.notify(rule_res);
                return $q.reject('Rules');
              });
            } else {
              return cartResponse.data.lineItems;
            }
          };
        })(this));
      };
      this.getCartColumns = function() {
        return ApiUtils.getStaticJson('display-columns-qa').then((function(_this) {
          return function(resp) {
            return resp.data.displayColumns.cartLineItemColumns;
          };
        })(this));
      };
      this.getCartLineItemsNew = function() {
        return ApiUtils.getStaticJson('several-rack-server-line-items').then((function(_this) {
          return function(cartResponse) {
            return cartResponse.data;
          };
        })(this));
      };
      this.getCartLineItems = function() {
        return ApiUtils.getStaticJson('cart').then((function(_this) {
          return function(cartResponse) {
            return cartResponse.data.lineItems;
          };
        })(this));
      };
      this.getCartTotalSummaryColumns = function() {
        return ApiUtils.getStaticJson('DisplayColumns').then((function(_this) {
          return function(cartTotalColumns) {
            return cartTotalColumns.data.displayColumns.cartTotalItemColumns;
          };
        })(this));
      };
      this.getLineItem = function(txnPrimaryLineNumber) {
        return ApiUtils.getStaticJson('line_item').then((function(_this) {
          return function(resp) {
            return resp.data;
          };
        })(this));
      };
      this.getDisplayActions = function() {
        return ApiUtils.getStaticJson('attribute_page_actions').then((function(_this) {
          return function(resp) {
            return resp.data.displayActions.attributePageActions;
          };
        })(this));
      };
      this.getCartTotalsDisplayData = function() {
        return ApiUtils.getStaticJson('CartTotals').then((function(_this) {
          return function(resp) {
            return resp.data.totalItems;
          };
        })(this));
      };
      this.getCartHeader = function() {
        return ApiUtils.getStaticJson('cartso').then((function(_this) {
          return function(resp) {
            return resp.data.cart;
          };
        })(this));
      };
      this.getQuoteSummary = function(id) {
        return ApiUtils.getStaticHTML('quote').then((function(_this) {
          return function(resp) {
            return resp;
          };
        })(this));
      };
      this.newLineItemFromProductOption = function(productOption) {
        return ApiUtils.getStaticJson('line_item').then((function(_this) {
          return function(resp) {
            var index, lineItem, optionID;
            index = productOption.ComponentProductId__r.HasOptions__c ? 1 : 0;
            lineItem = resp.data.optionLines[index];
            optionID = productOption.ComponentProductId__c;
            lineItem.chargeLines[0].lineItemSO.OptionId__c = optionID;
            return lineItem;
          };
        })(this));
      };
      this.removeFromCart = function(lineItemList) {
        return ApiUtils.getStaticJson('cart').then((function(_this) {
          return function(resp) {
            cartResponse.data.lineItems.shift();
            return cartResponse.data.lineItems;
          };
        })(this));
      };
      return this;
    }
  ]);

}).call(this);
