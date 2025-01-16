;(function() {
	angular.module('ngCPQ')
		.service('ProductDataService', ProductDataService); 
			
	ProductDataService.$inject = ['CatalogDataService'];

	function ProductDataService(CatalogDataService) {
		var service = this;

		service.searchProducts = CatalogDataService.searchProducts;
		service.getProductsById = CatalogDataService.getProductsById;
		
	}

})();