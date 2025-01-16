;(function() {
	angular.module('ngCPQ')
		.controller('CartController', CartController);
	
	CartController.$inject = ['$scope', 'CartDataService'];
		
	function CartController($scope, CartDataService) {
		var cartCtrl = this;
		cartCtrl.saveCart = saveCart;
		cartCtrl.removeFromCart = removeFromCart;
		cartCtrl.columns = []

		cartCtrl.lineItems = [];
		cartCtrl.adjTypes = [
			{name: "% Discount", value: "% Discount"},
			{name: "Discount Amount", value: "Discount Amount"},
			{name: "% Markup", value: "% Markup"},
			{name: "Markup Amount", value: "Markup Amount"},
			{name: "Price Override", value: "Price Override"},
			{name: "Base Price Override", value: "Base Price Override"},
			{name: "Price Factor", value: "Price Factor"}
		];

		/**
		 *  saves cart data
		 */
		function saveCart() {
			CartDataService.updateCartLineItems($scope.lineItemList).then(
				function (result){
					cartCtrl.lineItems = result;

				},
				function (error) {
					console.log('Save Error: ', error);
					loadCartLineItems();
				}
			);
			
		}

		/**
		 *  Remove a line item from cart
		 */
		function removeFromCart(lineItem) {
			var lineItemList = [lineItem];
			CartDataService.removeFromCart(lineItemList).then(function(result){
				cartCtrl.lineItems = result;

			},
			function (error) {
				console.log(error);
			});
			
		}
				
		/**
		 *  saves cart data
		 */
		function loadCartLineItems () {
			CartDataService.getCartLineItems().then(
				function (result){
					cartCtrl.lineItems = result;
				},
				function (error) {
					console.log('Load Error: ', error);
					loadCartLineItems();

				}
			);

		}

		function loadColumns() {
			CartDataService.getCartColumns().then(function (result) {
				cartCtrl.columns = result;
			});
		}
		
		function init() {
			loadColumns();
			loadCartLineItems();
			
		}
		init();
		
	}

})();

	