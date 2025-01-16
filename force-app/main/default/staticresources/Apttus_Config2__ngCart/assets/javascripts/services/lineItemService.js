(function() {
  angular.module('ngCPQ').service('LineItemService', [
    '$q', 'lodash', 'AttributeDataService', 'CartDataService', 'OptionDataService', 'OptionGroupService', function($q, _, AttributeData, CartData, OptionData, OptionGroup) {
      var LineItem;
      return LineItem = (function() {
        LineItem.create = function(data, optionData, parentItem) {
          var newItem;
          this.data = data;
          this.optionData = optionData;
          this.parentItem = parentItem;
          newItem = new this(this.data, this.optionData, this.parentItem);
          return newItem.init();
        };

        function LineItem(data, optionData, parentItem) {
          this.data = data;
          this.optionData = optionData;
          this.parentItem = parentItem;
        }

        LineItem.prototype.init = function() {
          return $q((function(_this) {
            return function(resolve, reject) {
              var promises;
              promises = {};
              if (_this.hasAttrs()) {
                promises.attrGroups = _this._getAttributeGroups();
                promises.fields = _this._getAttributeFields();
              }
              if (_this.hasOptions()) {
                _this.subItems = [];
                promises.optionGroups = _this._getOptionGroups();
              }
              return $q.all(promises).then(function(results) {
                _this.attrGroups = results.attrGroups;
                _this.fields = results.fields;
                if (results.optionGroups) {
                  _this.optionGroups = [];
                  return _this._buildSubItems(results.optionGroups).then(function() {
                    return resolve(_this);
                  });
                } else {
                  return resolve(_this);
                }
              });
            };
          })(this));
        };

        LineItem.prototype.isTopLevel = function() {
          return this.data.chargeLines[0].lineItemSO.LineType__c !== 'Option';
        };

        LineItem.prototype.addOption = function(option) {
          return this._newLineItemFromProductOption(option).then((function(_this) {
            return function(optionLine) {
              _this._restrictLevel(optionLine);
              return LineItem.create(optionLine, option, _this).then(function(lineItem) {
                _this.data.optionLines.push(lineItem.data);
                _this.subItems.push(lineItem);
                return lineItem;
              });
            };
          })(this));
        };

        LineItem.prototype.remove = function() {
          var ref;
          return (ref = this.parentItem) != null ? ref.removeOptionLine(this) : void 0;
        };

        LineItem.prototype.removeOptionLine = function(optionLine) {
          var i, j, len, ref, results1, subItem;
          ref = this.subItems;
          results1 = [];
          for (i = j = 0, len = ref.length; j < len; i = ++j) {
            subItem = ref[i];
            if (subItem === optionLine) {
              this.subItems.splice(i, 1);
              results1.push(this.data.optionLines.splice(i, 1));
            } else {
              results1.push(void 0);
            }
          }
          return results1;
        };

        LineItem.prototype.topLineTotal = function() {
          var charge, j, len, ref, total;
          total = 0;
          ref = this.data.chargeLines;
          for (j = 0, len = ref.length; j < len; j++) {
            charge = ref[j];
            total += charge.lineItemSO.NetPrice__c;
          }
          return total;
        };

        LineItem.prototype.hasAttrs = function() {
          return this.lineItemSO().HasAttributes__c;
        };

        LineItem.prototype.hasOptions = function() {
          return this.lineItemSO().HasOptions__c;
        };

        LineItem.prototype.lineType = function() {
          return this.lineItemSO().LineType__c;
        };

        LineItem.prototype.productID = function() {
          var node;
          node = this.lineType() === 'Option' ? 'OptionId__c' : 'ProductId__c';
          return this.lineItemSO()[node];
        };

        LineItem.prototype.productName = function() {
          return this.lineItemSO().ProductId__r.Name;
        };

        LineItem.prototype.lineItemSO = function() {
          return this.data.chargeLines[0].lineItemSO;
        };

        LineItem.prototype.attrSO = function() {
          return this.lineItemSO().AttributeValueId__r;
        };

        LineItem.prototype.quantity = function() {
          return this.lineItemSO().Quantity__c;
        };

        LineItem.prototype._getAttributeGroups = function() {
          return AttributeData.getAttributeGroups(this.productID());
        };

        LineItem.prototype._getAttributeFields = function() {
          return AttributeData.getAttributeFields();
        };

        LineItem.prototype._getOptionGroups = function() {
          return OptionData.getOptionGroups(this.productID());
        };

        LineItem.prototype._buildSubItems = function(optionGroups) {
          var group, j, k, l, len, len1, len2, option, optionID, optionLine, promises, ref, ref1;
          promises = [];
          for (j = 0, len = optionGroups.length; j < len; j++) {
            group = optionGroups[j];
            ref = group.options;
            for (k = 0, len1 = ref.length; k < len1; k++) {
              option = ref[k];
              ref1 = this.data.optionLines;
              for (l = 0, len2 = ref1.length; l < len2; l++) {
                optionLine = ref1[l];
                optionID = optionLine.chargeLines[0].lineItemSO.OptionId__c;
                if (optionID === option.ComponentProductId__c) {
                  promises.push(LineItem.create(optionLine, option, this));
                }
              }
            }
          }
          return $q.all(promises).then((function(_this) {
            return function(results) {
              var len3, m, optionGroup, results1;
              _this.subItems = results;
              results1 = [];
              for (m = 0, len3 = optionGroups.length; m < len3; m++) {
                group = optionGroups[m];
                optionGroup = new OptionGroup(group, _this);
                results1.push(_this.optionGroups.push(optionGroup));
              }
              return results1;
            };
          })(this));
        };

        LineItem.prototype._newLineItemFromProductOption = function(option) {
          return CartData.newLineItemFromProductOption(option.data);
        };

        LineItem.prototype._restrictLevel = function(optionLine) {
          var level, parent;
          level = 1;
          parent = this.parentItem;
          while (parent) {
            level += 1;
            parent = parent.parentItem;
          }
          if (level >= 3) {
            return optionLine.optionLines = [];
          }
        };

        return LineItem;

      })();
    }
  ]);

}).call(this);
