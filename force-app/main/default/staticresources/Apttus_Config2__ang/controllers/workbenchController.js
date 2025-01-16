;(function() {
	angular.module('ngCPQ')
		.controller('WorkbenchController', WorkbenchController);
		
	WorkbenchController.$inject = ['$scope','$filter', 'CatalogDataService', 'CartDataService'];
	
	function WorkbenchController($scope, $filter, CatalogDataService, CartDataService) {

		//Data
		$scope.resultJSON = '';
		$scope.requestJSON = '';
		$scope.categories = [];
		$scope.products = [];
		$scope.treeData = {
			root: true,
			label: 'Categories',
			childCategories: $scope.categories
		};
		$scope.timeAverage = 0;
		$scope.timeLogGrid = {
			enableFiltering: false,
			columnDefs: [
				{ 
					field:'completed', 
					cellFilter: "date:'HH:mm:ss'"
				},
				{
					field: 'timeTaken',
				}
			],
			data: []
		};

		//Options
		$scope.searchText = '';
		$scope.includeParamsOptions = [
			{name: 'prices', checked: false},
			{name: 'defaultOptionProducts', checked: false},
			{name: 'productFilters', checked: false},
			{name: 'categories', checked: false}
		];

		function getSelectedIncludeParams() {
			var selectedIncludeParams = [];
			$scope.includeParamsOptions.forEach(function(item) {
				if (item.checked) {
					selectedIncludeParams.push(item.name);
				}
			});
			return selectedIncludeParams;
		}

		//Log a result's time taken
		function logJSON(requestHistory) {
			var result = requestHistory.response;
			var request = requestHistory.request;
			var resultTimeTaken = 'N/A';
			if (result.hasOwnProperty('timeTaken')) {
				resultTimeTaken = Number(result.timeTaken);
				var qt = $scope.timeLogGrid.data.length;
				$scope.timeAverage = (($scope.timeAverage*qt) + resultTimeTaken)/(qt + 1);
			}
			$scope.timeLogGrid.data.push({
				completed: new Date(),
				timeTaken: resultTimeTaken
			});
			$scope.resultJSON = JSON.stringify(result, null, 1);
			$scope.requestJSON = JSON.stringify(request, null, 1);

		}

		$scope.clearTimeLog = function() {
			$scope.timeAverage = 0;
			$scope.timeLogGrid.data = [];
		};

		$scope.getCategories = function() {
			CatalogDataService.getCategories()
				.then(function(result) {
					logJSON(CatalogDataService.transactionJSON);
					$scope.categories = result;
					$scope.treeData.childCategories = result;
				},
				function(error) {
					//Just logging, could throw
					//console.log('Error: could not get categories.');
				});
		};

		$scope.getProducts = function() {	
			var selectedIncludeParams = getSelectedIncludeParams();
			CatalogDataService.getProducts($scope.selectedCategory.nodeId, selectedIncludeParams)
				.then(function(result) {
					logJSON(CatalogDataService.transactionJSON);
					$scope.products = result;
				},
				function(error) {
					//Just logging, could throw
					//console.log('Error: could not get products.');
				});
		};
		
		$scope.searchProducts = function() {	
			var selectedIncludeParams = getSelectedIncludeParams();
			CatalogDataService.searchProducts($scope.selectedCategory.nodeId, $scope.searchText, selectedIncludeParams )
				.then(function(result) {
					logJSON(CatalogDataService.transactionJSON);
					$scope.products = result.products;
				},
				function(error) {
					//Just logging, could throw
					//console.log('Error: could not search products.');
				});
		};

		$scope.getSampleRequest = function() {
			var selectedIncludeParams = getSelectedIncludeParams();
			request = CatalogDataService.createCatalogRequestDO($scope.selectedCategory,
							$scope.searchText, 
							null, 
							selectedIncludeParams);
			$scope.resultJSON = '';
			$scope.requestJSON = JSON.stringify(request, null, 1);
		};


		$scope.getCartLineItems = function() {	
			//var selectedIncludeParams = getSelectedIncludeParams();
			CartDataService.getCartLineItems()
				.then(function(result) {
					logJSON(CartDataService.transactionJSON);
					$scope.lineItems = result;
				},
				function(error) {
					//Just logging, could throw
					//console.log('Error: could not search products.');
				});
		};

		$scope.resetCart = function() {	
			//var selectedIncludeParams = getSelectedIncludeParams();
			CartDataService.resetCart();
			$scope.lineItems = null;
		};
		

		function logFunctionCall(functionName, input, output) {
			$scope.requestJSON = functionName + ' --> \n' + JSON.stringify(input, null, 1);
			$scope.resultJSON = JSON.stringify(output, null, 1);

		}

		$scope.testFunctionNames = [
			'getCategories',
			'getCatById',
			'searchProductsEmpty',
			'searchProductsCat',
			'searchProductsCatText',
			'getProductFilters',
			'searchProductsCatFilter',
			'getCartLineItems',
			'getCartColumns'
		];
		$scope.testFunctions = {
			getCategories: function () {
				var input = [];
				CatalogDataService.getCategories().then(function (result) {
					$scope.categories = result;
					logFunctionCall("getCategories", input, result);

				});

			},
			getCatById: function () {
				var catId = $scope.categories[0].nodeId;
				var input = [catId];
				CatalogDataService.getCatById(catId).then(function (result) {
					logFunctionCall("getCatById", input, result);

				});
				
			},
			searchProductsEmpty: function () {
				var input = [null, null, null];
				CatalogDataService.searchProducts().then(function (result) {
					logFunctionCall("searchProducts", input, result);

				});
				
			},
			searchProductsCat: function () {
				var catId = $scope.categories[0].nodeId;
				var input = [catId, null, null];

				CatalogDataService.searchProducts(catId).then(function (result) {
					logFunctionCall("searchProducts", input, result);

				});
				
			},
			searchProductsCatText: function () {
				var catId = $scope.categories[0].nodeId;
				var input = [catId, 'Bundle', null];
				CatalogDataService.searchProducts(catId, 'Bundle', null).then(function (result) {
					logFunctionCall("searchProducts", input, result);

				});
				
			},
			getProductFilters: function () {
				var catId = $scope.categories[0].nodeId;
				var input = [catId];
				CatalogDataService.getProductFiltersForCategory(catId).then(function (result) {
					$scope.productFilters = result;
					logFunctionCall("getProductFiltersForCategory", input, result);

				});
				
			},
			searchProductsCatFilter: function () {
				var catId = $scope.categories[0].nodeId;
				var filters = $scope.productFilters;
				filters[0].filterFieldValues[0].isSelected = true;
				var input = [catId, null, filters];
				CatalogDataService.searchProducts(catId, null, filters).then(function (result) {
					logFunctionCall("searchProducts", input, result);

				});
				
			},
			getCartLineItems: function () {
				var input = [];
				CartDataService.getCartLineItems().then(function (result) {
					logFunctionCall("getCartLineItems", input, result);

				});
				
			},
			getCartColumns: function () {
				var input = [];
				CartDataService.getCartColumns().then(function (result) {
					logFunctionCall("getCartColumns", input, result);

				});
				
			}
		};

	}
	
})();