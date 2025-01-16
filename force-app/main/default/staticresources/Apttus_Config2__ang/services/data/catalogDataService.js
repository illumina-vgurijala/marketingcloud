;(function() {
	angular.module('ngCPQ')
		.service('CatalogDataService', catalogDataService); 
			
	catalogDataService.$inject = ['$q', '$log', 'ConfigurationDataService', 'RemoteService', 'CatalogCache'];

	function catalogDataService($q, $log, ConfigurationDataService, RemoteService, CatalogCache) {
		var service = this;
		var createCatalogRequestDO = ConfigurationDataService.createCatalogRequestDO;
		service.transactionJSON = {};

		//Category methods
		service.getCategories = getCategories;
		service.getCatById = getCatById;
		service.getCategory = getCatById;
		service.getAncestors = getAncestors;
		service.getBreadcrumb = getBreadcrumb;

		//Product methods
		service.getCategoryIdsForLeaves = getCategoryIdsForLeaves;
		service.getCategoryTreeForLeaves = getCategoryTreeForLeaves;
		service.searchProducts = searchProducts;
		service.getProductById = getProductById;
		service.getProductsById = getProductsById;
		service.getProductFilters = getProductFilters;
		service.getProductFiltersForCategory = getProductFiltersForCategory;
		//Create a catalog request structure
		service.createCatalogRequestDO = createCatalogRequestDO;

		/**
		 * Get all categories.
		 * If the cache is valid, return immediately with cached categories.
		 * 	Else, make the remote request and load categories into the cache,
		 * 	then return the result.
		 * 
		 */
		function getCategories() {
			if (CatalogCache.isValid) {
				var cachedCategories = CatalogCache.getCategories();
				logTransaction(cachedCategories);
				return $q.when(cachedCategories);

			}
			//var responseIncludes = ['productFilters'];
			var responseIncludes = [];
			categoryRequest = createCatalogRequestDO(null, null, null, responseIncludes, null);
			var requestPromise = RemoteService.getCategories(categoryRequest);
			return requestPromise.then(function(response){
				CatalogCache.initializeCategories(response.categories);
				logTransaction(response, categoryRequest);
				return CatalogCache.getCategories();
			});

		}

		/**
		 * Get a category by its id.
		 * For now, this is just done by ensuring all categories have been
		 * 	retrieved, then ask the cache for a particular id. 
		 * 
		 */
		function getCatById(categoryId) {
			return getCategories().then(function(result) {
				return CatalogCache.getCategoryById(categoryId);

			});


		}	

		/**
		 * Get the array of ancestor categories for a particular category.
		 * For now, this is just done by ensuring all categories have been
		 * 	retrieved, then ask the cache for a particular lineage. 
		 * 
		 */
		function getAncestors(categoryId) {
			return CatalogCache.getAncestors(categoryId);

		}

		function getBreadcrumb(categoryId) {
			return getCategories().then(function(result) {
				return CatalogCache.getAncestors(categoryId);
			});
		}

		/**
		 * Get set of all categories that should be present in the tree when
		 * 	only a particular set of eaves should be included.
		 * 	
		 * @param  {[type]} leafIds [description]
		 * @return {[type]}         [description]
		 */
		function getCategoryIdsForLeaves(leafIds) {
			return getCategories().then(function(result) {
				//External code expects promise to resolve with a response object 
				//	instead of the actual array. This isn't how we want it. 
				var response = {};
				response.resultCategories = CatalogCache.getAncestorIdSet(leafIds);
				return response;
			});

		}

		function getCategoryTreeForLeaves(leafIds) {
			return [];

		}

		function getProductById(productId) {
			var product = CatalogCache.getProductById(productId);
			return $q.when(product);

		}

		function getProductsById(productIds) {
			var productIdArr = [].concat(productIds);
			var products = [];
			for (var productIndex = 0; productIndex < productIdArr.length; productIndex++) {
				products.push(CatalogCache.getProductById(productIdArr[productIndex]));

			}
			return $q.when(
				{
					"products": products
				}
			);

		}

		function getProductFiltersForCategory(categoryId) {
			var cachedFilters = CatalogCache.getProductFiltersForCategory(categoryId);
			if (cachedFilters) {
				return $q.when(cachedFilters);

			}
			includeParams = ['productFilters'];
			var searchRequest = createCatalogRequestDO(categoryId, null, null, includeParams, null);
			var filterPromise = RemoteService.searchProducts(searchRequest);
			return filterPromise.then(function (result) {
				CatalogCache.putProductFiltersForCategory(categoryId, result.productFilters);
				return CatalogCache.getProductFiltersForCategory(categoryId);
				
			});

		}

		/**
		 * Search for products
		 * @param  {string or object} searchText    text or searchRequest object
		 * @param  {array<string>} categoryId   ids of category to search in
		 * @param  {array<object>} searchText text to match
		 * @param  {array<object>} productFilters filters to apply
		 */
		function searchProducts(categoryId, searchText, productFilters) {
			// Using ugly string checking to see whether product filters are being used 
			var isProductFilterSelected = productFilters ? (JSON.stringify(productFilters).indexOf('"isSelected":true') >= 0) : false;
			var hasSearchText = searchText && searchText.length && searchText.length > 0;
			if (!hasSearchText && !isProductFilterSelected) {
				var cachedProducts = CatalogCache.getProductsForCategory(categoryId);
				if (cachedProducts) {
					$log.debug('Search Products: Returning cached products.');
					var response = {
						"products": cachedProducts,
						"resultCategoryIds": [categoryId]
					};
					return $q.when(response);

				}

			}
			var includeParams = ['prices'];
			if (!CatalogCache.getProductFiltersForCategory(categoryId)) {
				includeParams.push('productFilters');

			}
			var searchRequest = createCatalogRequestDO(categoryId, searchText, productFilters, includeParams, null);
			$log.debug('Search Products: Making product request.', searchRequest);

			var requestPromise = RemoteService.searchProducts(searchRequest);		
			return requestPromise.then(function(response) {
				logTransaction(response, searchRequest);
				CatalogCache.putProducts(response.products);
				if (response.productFilters) {
					CatalogCache.putProductFiltersForCategory(categoryId, response.productFilters);
					
				}
				return response;	

			});

		}


		/**
		 * Experimental method that does filtering in javascript
		 * @param  {[type]} categoryId     [description]
		 * @param  {[type]} searchText     [description]
		 * @param  {[type]} productFilters [description]
		 * @return {[type]}                [description]
		 */
		function queryForProducts(categoryId, searchText, productFilters) {
			var deferred = $q.defer();
			setTimeout(function () {
				filteredCachedProducts = filterCachedProducts(categoryId, searchText, productFilters);
				deferred.resolve(filteredCachedProducts);

			}, 0);
			return deferred.promise.then(function (cacheResult) {
				var productResponse = {};
				if (cacheResult) {
					productResponse.products = cacheResult;
					return productResponse;

				}
				var includeParams = ['prices']; 
				//includeParams.push('productFilters');
				var productRequest = createCatalogRequestDO(categoryId, searchText, productFilters, includeParams, null);
				return RemoteService.searchProducts(productRequest).then(function (response) {
					CatalogCache.putProducts(response.products);
					return response;
				});

			});

		}

		function filterCachedProducts(categoryId, searchText, productFilters) {
			var cachedProducts = CatalogCache.getProductsForCategory(categoryId);
			if (!cachedProducts || cachedProducts.length > 1000) {
				return null;

			}
			var filteredProducts = [];
			var nextProduct;
			for (var prodIndex = 0, prodLength = cachedProducts.length - 1; prodIndex < prodLength; prodIndex++) {
				nextProduct = cachedProducts[prodIndex];
				if (checkIfProductMeetsFilter(nextProduct, searchText, productFilters)) {
					filteredProducts.push(nextProduct);

				}

			}
			return filteredProducts;

		}

		function checkIfProductMeetsFilter(product, searchText, productFilters) {
			var isMet = true;
			if (searchText) {
				var searchFields = ConfigurationDataService.defaultSearchFields;
				var matchFound = false;
				var nextField;
				for (var fieldIndex = searchFields.length - 1; fieldIndex >= 0; fieldIndex--) {
					nextField = searchFields[fieldIndex];
					if (typeof nextField === 'string' && nextField.indexOf(searchText) >= 0) {
						matchFound = true;
						break;

					}

				}
				isMet = matchFound;

			}
			if (isMet && productFilters) {


			}
			return isMet;

		}


		function getProductFilters() {
			return $q.when([]);

		}
		
		function logTransaction(response, request) {
			transaction = {};
			if (!request) {
				transaction.request = "cache";

			} else {
				transaction.request = request;
				
			}
			transaction.response = response;
			service.transactionJSON = transaction;

		}
		
	}

})();

