(function() {
	angular.module('ngCPQ')
		.directive('cartLineItem', cartLineItem);
	
	cartLineItem.$inject = ['baseUrl'];
	CartLineItemCtrl.$inject = ['CartDataService', '$rootScope'];

	function CartLineItemCtrl(CartDataService, $rootScope) {
		var cartLineItem = this;
		cartLineItem.removeFromCart = removeFromCart;
		cartLineItem.getLineNumber = getLineNumber;
		cartLineItem.getDisabled = getDisabled;
		cartLineItem.modifyLineItem = modifyLineItem;
		cartLineItem.getIsOption = getIsOption;
		cartLineItem.getFieldByReference = getFieldByReference;

		//Should be dynamic
		cartLineItem.adjTypes = [
			{name: "% Discount", value: "% Discount"},
			{name: "Discount Amount", value: "Discount Amount"},
			{name: "% Markup", value: "% Markup"},
			{name: "Markup Amount", value: "Markup Amount"},
			{name: "Price Override", value: "Price Override"},
			{name: "Base Price Override", value: "Base Price Override"},
			{name: "Price Factor", value: "Price Factor"}
		];

		cartLineItem.styleClass = {
			"strikethrough": false
		};

	  function getLineNumber() {
			return cartLineItem.lineItem.lineItemSO.LineNumber__c;

		}

		function getDisabled() {
			var isDisabled = cartLineItem.lineItem.lineAction === 'delete';
			cartLineItem.styleClass.strikethrough = isDisabled;
			return isDisabled;

		}


		function getIsOption() {
			return cartLineItem.lineItem.lineItemSO.LineType__c === 'Option';

		}

		function modifyLineItem() {
			CartDataService.updateCartLineItems(cartLineItem.lineItem);

		}

		function getFieldByReference(fieldName) {
			var fieldRef = fieldName.replace('__c', '__r');
			return cartLineItem.lineItem.chargeLines[0].lineItemSO[fieldRef].Name;

		}

		/**
		 *  Remove a line item from cart
		 */
		function removeFromCart() {
			var lineItemList = [cartLineItem.lineItem];
			CartDataService.removeFromCart(lineItemList);
		
		}

	}

	function cartLineItem(baseUrl) {
		var directive;
		directive = {
			restrict: 'AE',
			scope: {
				lineItem: '=',
				displayColumns: '='
			},
			templateUrl: baseUrl + '/views/cart-line-item.html',
			controller: CartLineItemCtrl,
			controllerAs: 'cartLineItem',
			bindToController: true
		};
		return directive;
	}

})();
