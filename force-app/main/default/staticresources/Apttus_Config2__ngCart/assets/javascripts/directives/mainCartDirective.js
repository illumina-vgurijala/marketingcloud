(function() {
  var MainCart, mainCartCtrl, mainCartLink;

  mainCartCtrl = function(CartService, $q, $stateParams) {
    var activate, mainCart;
    mainCart = this;
    mainCart.view = $stateParams.view;
    activate = function() {
      return $q.all([CartService.getCartLineItemsNew(), CartService.getCartColumns(), CartService.getCheckboxModels()]).then(function(res) {
        var columns;
        mainCart.cartLineItems = res[0];
        columns = res[1];
        mainCart.checkBoxes = CartService.cartCheckBoxModels;
        mainCart.columnTypes = columns.map(function(element) {
          var replace_r;
          if (element.FieldType === 'REFERENCE') {
            replace_r = element.FieldName.replace('__c', '__r');
            element.FieldName = replace_r;
          }
          if (element.FieldName.indexOf('ProductId__r') > -1) {
            element.FieldType = 'DETAIL';
          } else if (element.FieldName.indexOf('ChargeType') > -1) {
            element.FieldType = 'CHARGETYPE';
            mainCart.chargeKey = element.FieldName;
          } else if (element.FieldName.indexOf('Quantity') > -1) {
            element.FieldType = 'QUANTITY';
          }
          return element;
        });
        mainCart.tableColumns = mainCart.columnTypes.filter(function(element) {
          if (element.FieldName.indexOf('ChargeType') <= -1) {
            return true;
          }
        });
        return mainCart.columns;
      });
    };
    activate();
    mainCart.getColumnData = function(columnField) {
      return mainCart.item.lineItemSO[columnField];
    };
    mainCart.checkBoxSelected = function() {
      return console.log('checked');
    };
    mainCart.enableActions = function() {
      return console.log('input clicked');
    };
    return mainCart.enableActions = function(itemId) {
      if (CartService.getCheckedCount(CartService.cartCheckBoxModels.all) > 0) {
        return CartService.canDupe = CartService.canRemove = true;
      } else {
        return CartService.canDupe = CartService.canRemove = false;
      }
    };
  };

  mainCartCtrl.$inject = ['CartService', '$q', '$stateParams'];

  mainCartLink = function(scope, elem, attr) {
    var body, globalHeader, header, processTrail, scrollHandler;
    body = elem[0];
    header = body.querySelector('cart-header');
    globalHeader = document.querySelector('.header-global');
    processTrail = document.querySelector('.process-trail');
    scrollHandler = function(ev) {
      var bodyRect, globalHeaderRect, headerRect, processTrailRect;
      bodyRect = body.getBoundingClientRect();
      headerRect = header.getBoundingClientRect();
      globalHeaderRect = globalHeader.getBoundingClientRect();
      processTrailRect = processTrail.getBoundingClientRect();
      if (bodyRect.top + 16 <= globalHeaderRect.height + processTrailRect.height) {
        body.classList.add('main-cart-wrapper--header-fixed');
        return angular.element(header.querySelector('.cart-header')).css({
          'top': '6rem'
        });
      } else {
        return body.classList.remove('main-cart-wrapper--header-fixed');
      }
    };
    return window.addEventListener('scroll', scrollHandler);
  };

  MainCart = function(baseUrl) {
    var directive;
    directive = {
      link: mainCartLink,
      controller: mainCartCtrl,
      controllerAs: 'mainCart',
      bindToController: true
    };
    return directive;
  };

  MainCart.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('mainCart', MainCart);

}).call(this);
