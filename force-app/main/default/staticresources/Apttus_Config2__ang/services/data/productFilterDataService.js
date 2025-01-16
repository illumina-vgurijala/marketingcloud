;(function() {
	angular.module('ngCPQ')
		.service('ProductFilterDataService', ProductFilterDataService); 
			
	ProductFilterDataService.$inject = ['CatalogDataService'];

	function ProductFilterDataService(CatalogDataService) {
		var service = this;

		service.getFiltersFor = CatalogDataService.getProductFiltersForCategory;
	
	}

})();