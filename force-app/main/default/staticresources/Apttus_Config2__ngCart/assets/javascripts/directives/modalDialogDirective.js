(function() {
  var ModalDialog, ModalDialogCtrl;

  ModalDialogCtrl = function(_, $scope, Messenger, ProductDataService) {
    this.visible = false;
    this.close = function() {
      this.visible = false;
      return Messenger.messages.prompt.shift();
    };
    this.open = function() {
      return this.visible = true;
    };
    this.selectedProducts = [];
    this.prompt = function() {
      return Messenger.messages.prompt[0];
    };
    this.minSelected = function() {
      if (this.prompt()) {
        return this.selectedProducts.length >= this.prompt().RequiredMin__c;
      } else {
        return false;
      }
    };
    this.toggleProduct = function(product) {
      if (_.includes(this.selectedProducts, product)) {
        return _.pull(this.selectedProducts, product);
      } else {
        return this.selectedProducts.push(product);
      }
    };
    $scope.$watch((function(_this) {
      return function() {
        return _this.prompt();
      };
    })(this), (function(_this) {
      return function(newValue, oldValue) {
        var options, ref, ref1;
        if (newValue) {
          options = ((ref = _this.prompt()) != null ? (ref1 = ref.ActionProductIds__c) != null ? ref1.split(/,\W*/) : void 0 : void 0) || [];
          // return ProductDataService.searchProducts(null, options).then(function(resp) {
          return ProductDataService.getProductsById(options).then(function(resp) {
            _this.promptOptions = resp.products;
            return _this.open();
          });
        } else {
          return _this.close();
        }
      };
    })(this));
    return this;
  };

  ModalDialogCtrl.$inject = ['lodash', '$scope', 'messenger', 'ProductDataService'];

  ModalDialog = function(baseUrl) {
    return {
      restrict: 'AE',
      templateUrl: baseUrl + "/templates/directives/modal-dialog.html",
      controller: ModalDialogCtrl,
      controllerAs: 'modalDialog',
      bindToController: true
    };
  };

  ModalDialog.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('modalDialog', ModalDialog);

}).call(this);
