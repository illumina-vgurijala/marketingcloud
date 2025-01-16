(function() {
  angular.module('ngCPQ').service('OptionGroupService', [
    '$q', 'lodash', 'OptionService', function($q, _, Option) {
      var OptionGroup;
      return OptionGroup = (function() {
        function OptionGroup(data, lineItem) {
          var j, len, newOption, option, ref, selected;
          this.data = data;
          this.lineItem = lineItem;
          this.options = [];
          ref = this.data.options;
          for (j = 0, len = ref.length; j < len; j++) {
            option = ref[j];
            selected = this.findOptionSelection(option);
            newOption = new Option(option, this, selected);
            this.options.push(newOption);
          }
          this;
        }

        OptionGroup.prototype.isPicklist = function() {
          return this.data.isPicklist;
        };

        OptionGroup.prototype.isRadio = function() {
          return (!this.isPicklist()) && (this.data.maxOptions === 1);
        };

        OptionGroup.prototype.isCheckbox = function() {
          return (!this.isPicklist()) && (this.data.maxOptions !== 1);
        };

        OptionGroup.prototype.hasNoneOption = function() {
          return this.data.minOptions === 0;
        };

        OptionGroup.prototype.hasNoneSelected = function(optionLines) {
          var j, len, noneSelected, option, ref;
          noneSelected = true;
          ref = this.data.options;
          for (j = 0, len = ref.length; j < len; j++) {
            option = ref[j];
            if (this.findOptionSelection(option, optionLines)) {
              noneSelected = false;
            }
          }
          return noneSelected;
        };

        OptionGroup.prototype.findOptionSelection = function(option) {
          var found, j, len, ref, subItem;
          found = false;
          ref = this.lineItem.subItems;
          for (j = 0, len = ref.length; j < len; j++) {
            subItem = ref[j];
            if (subItem.productID() === option.ComponentProductId__c) {
              found = subItem;
            }
          }
          return found;
        };

        OptionGroup.prototype.optionLinesFromGroup = function() {
          var j, len, option, ref, selected;
          selected = [];
          ref = this.options;
          for (j = 0, len = ref.length; j < len; j++) {
            option = ref[j];
            if (option.isSelected()) {
              selected.push(option.optionLine);
            }
          }
          return selected;
        };

        OptionGroup.prototype.selectNone = function(optionItems) {
          var index, j, len, option, ref, results, subItem;
          ref = this.data.options;
          results = [];
          for (j = 0, len = ref.length; j < len; j++) {
            option = ref[j];
            results.push((function() {
              var k, len1, results1;
              results1 = [];
              for (index = k = 0, len1 = optionItems.length; k < len1; index = ++k) {
                subItem = optionItems[index];
                if (subItem.productID() === option.ComponentProductId__c) {
                  results1.push(optionItems.slice(i, 1));
                } else {
                  results1.push(void 0);
                }
              }
              return results1;
            })());
          }
          return results;
        };

        OptionGroup.prototype.toggleOption = function(option) {
          return $q((function(_this) {
            return function(resolve, reject) {
              var j, len, otherOption, ref;
              if (_this.isPicklist() || _this.isRadio()) {
                if (option.isSelected()) {
                  return resolve(option.optionLine);
                } else {
                  ref = _this.options;
                  for (j = 0, len = ref.length; j < len; j++) {
                    otherOption = ref[j];
                    if (otherOption.isSelected()) {
                      otherOption.optionLine.remove();
                      otherOption.optionLine = false;
                    }
                  }
                  return _this.lineItem.addOption(option).then(function(newItem) {
                    return resolve(newItem);
                  });
                }
              } else {
                if (option.isSelected()) {
                  option.optionLine.remove();
                  return resolve(void 0);
                } else {
                  return _this.lineItem.addOption(option).then(function(newItem) {
                    return resolve(newItem);
                  });
                }
              }
            };
          })(this));
        };

        return OptionGroup;

      })();
    }
  ]);

}).call(this);
