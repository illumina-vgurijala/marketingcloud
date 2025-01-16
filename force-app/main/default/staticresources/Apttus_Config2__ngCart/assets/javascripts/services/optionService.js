(function() {
  angular.module('ngCPQ').service('OptionService', [
    '$q', 'lodash', function($q, _) {
      var Option;
      return Option = (function() {
        function Option(data, group, optionLine, customColumns) {
          this.data = data;
          this.group = group;
          this.optionLine = optionLine;
          this.customColumns = customColumns;
          this;
        }

        Option.prototype.isSelected = function() {
          return !!this.optionLine;
        };

        Option.prototype.customData = function(number) {
          var column;
          if (this.customColumns) {
            column = this.customColumns[number];
            return this.data.ComponentProductId__r[columnName];
          }
        };

        Option.prototype.toggleSelected = function() {
          return $q((function(_this) {
            return function(resolve, reject) {
              return _this.group.toggleOption(_this).then(function(item) {
                return _this.optionLine = item;
              });
            };
          })(this));
        };

        Option.prototype.name = function() {
          return this.data.ComponentProductId__r.Name;
        };

        Option.prototype.price = function() {
          var ref;
          return (ref = this.data.ComponentProductId__r.PriceLists__r) != null ? ref[0].ListPrice__c : void 0;
        };

        return Option;

      })();
    }
  ]);

}).call(this);
