;(function() {
	angular.module('ngCPQ')
		.controller('CatalogController', CatalogController);
	
	CatalogController.$inject = ['$scope',
								 'CPQLabels',
								 'CatalogDataService',
								 'CartDataService'];
	

	function CatalogController($scope, CPQLabels, CatalogDataService, CartDataService) {
		$scope.bundleList = [];
		$scope.productFilters = [];
		$scope.textFilter = {
			productSO: {
				$: ''
			}
		};
		$scope.labels = CPQLabels.labels; 
		$scope.isSearching = false;
		$scope.filterCategory = undefined;
		$scope.categoryTree = {
			label: 'All Categories',
			expanded: true,
			childCategories: []
		};

		//paginator data
		$scope.currentPage = 1;
		$scope.pageSize = 20;
		$scope.numberOfPages = 1;

		$scope.filterByCategory = filterByCategory;
		$scope.reloadCatalog = reloadCatalog;
		$scope.addProductToCart = addProductToCart;
		$scope.searchProducts = searchProducts;

		function filterByCategory(categoryId) {
			// console.log('*** Category Id ***'+categoryId);
			$scope.filterCategory = categoryId;
			loadBundles();

		}

		function getBreadcrumb() {
			if (!$scope.filterCategory) {
				$scope.breadcrumb = undefined;
				return;

			}
			$scope.breadcrumb = CatalogDataService.getAncestors($scope.filterCategory);
			
			//var catList = [$scope.filterCategory];
			// return CatalogDataService.getCategoryIdsForLeaves(catList).then(function(result) {
			// 	$scope.breadcrumb = Object.keys(result);
			// 	return result;
			// });


		}


		/**
		 * reload catalog data
		 */
		function reloadCatalog() {
			loadBundles();
		}
				
		/*
		 * loads bundle products
		 */
		function loadBundles() {
			$scope.isSearching = true;
			$scope.bundleList = [];
			// var categoryIds = [];
			// if ($scope.filterCategory) {
			// 	categoryIds.push($scope.filterCategory);
			
			// }
			// var productResponse = CatalogDataService.getProductsResponse($scope.filterCategory);
			// if (productResponse.immediate && productResponse.immediate.length > 0) {
			// 	$scope.bundleList = productResponse.immediate;
			// 	$scope.isSearching = false;

			// }
			// productResponse.promise.then(function(result){
			CatalogDataService.searchProducts($scope.filterCategory).then(function (result) {
					$scope.bundleList = result.products;
				},
				function (error) {
					console.log('Load error: ' + error);
				})
				.finally(function(){
					$scope.isSearching = false;					
				})
				.then(function(){
					return getBreadcrumb();
				})
				.then(function() {
					return getProductFilters();
				});
		}

		function searchProducts() {
			$scope.isSearching = true;
			$scope.bundleList = [];
			var searchText = $scope.textFilter.productSO.$;

			var searchPromise = CatalogDataService.searchProducts($scope.filterCategory, searchText, $scope.productFilters);

			searchPromise.then(function(result) {
				$scope.bundleList = result.products;
			}, function (error) {

			}).finally(function() {
				$scope.isSearching = false;
			});
			

			
		}


		function getProductFilters() {
			return CatalogDataService.getProductFiltersForCategory($scope.filterCategory).then(function(result) {
				$scope.productFilters = result;
				return result;
			});
		
		}

		
		/*
		 * Call addToCart for the cache service.
		 * Formerly had to construct a line item, now takes a product with
		 *  an optional .quantity property.
		 */
		function addProductToCart(product) {
			// var lineItem = {
			// 		lineItemSO: {
			// 			ProductId__c: product.productSO.Id,
			// 			Quantity__c: product.quantity || 1,
			// 			ProductId__r: {
			// 				Name: product.productSO.Name
			// 			}
			// 		},
			// 		sequence: CartDataService.itemsInCart + 1
			// 	};
			// CartDataService.addToCart(lineItem);
			CartDataService.addToCart(product);
		}

		function getCategories() {
			CatalogDataService.getCategories()
				.then(function(result) {
					$scope.categoryTree.childCategories = result;
				},
				function(error) {
					//Just logging, could throw
					console.log('Error: could not get categories.');
				});

		}
		
		function init(){
			getCategories();
			loadBundles();
			
		}
		
		init();
		
	}

})();

	