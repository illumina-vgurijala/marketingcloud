 ;(function() {
	angular.module('ngCPQ')
		.controller('MiniCartController', MiniCartController);
	
	MiniCartController.$inject = ['$scope', 'CartDataService'];

	function MiniCartController($scope, , CartDataService) {
		$scope.lineItems = [];
		
		//paginator data
		$scope.pageStart = 0;
		$scope.pageSize = 10;

		/**
		 * Get cart line items, set page info.
		 */
		function loadCartLineItems () {
			CartDataService.getCartLineItems().then(function(result) {
				$scope.lineItems = result;

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

	