 ;(function() {
	angular.module('ngCPQ')
		.directive('minicart', Minicart);
	
	Minicart.$inject = ['baseUrl'];
	MinicartController.$inject = ['$scope', 'CartDataService'];

	function Minicart(baseUrl) {
		var directive;
		directive = {
			restrict: 'AE',
			templateUrl: baseUrl + '/views/minicart.html',
			scope: {},
			controller: MinicartController,
			controllerAs: 'MinicartCtrl',
			bindToController: true
		};
		return directive;

	}

	function MinicartController($scope, CartDataService) {
		var MinicartCtrl = this;
		MinicartCtrl.lineItems = [];

		/**
		 * Get cart line items, set page info.
		 */
		function loadCartLineItems () {
			CartDataService.getCartLineItems().then(function(result) {
				MinicartCtrl.lineItems = result;
				MinicartCtrl.numberOfItems = result.length;

			},
			function (error) {
				console.log(error);
			});
		}
		
		var init = function () {
			loadCartLineItems();
			
		};

		//Run initialization
		init();
		
	}
	
})();

	