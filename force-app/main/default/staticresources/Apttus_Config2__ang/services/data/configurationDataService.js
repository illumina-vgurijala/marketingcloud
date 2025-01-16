;(function() {
	angular.module('ngCPQ')
		.service('ConfigurationDataService', configurationDataService);

	configurationDataService.$inject = ['$q', '$log', 'cartId', 'configRequestId', 'priceListId', 'RemoteService'];

	function configurationDataService($q, $log, cartId, configRequestId, priceListId, RemoteService) {
		var service = this;
		var configurationData;

		//Cart details taken from constants defined in VF page.
		service.cartId = cartId;
		service.configRequestId = configRequestId;
		service.priceListId = priceListId;

		service.getConfigurationData = getConfigurationData;
		service.getDisplayColumns = getDisplayColumns;
		service.getDisplayActions = getDisplayActions;
		service.getCustomSettings = getCustomSettings;

		service.createCatalogRequestDO = createCatalogRequestDO;
		service.createCartRequestDO = createCartRequestDO;

		service.defaultSearchFields = ["Name", "ProductCode", "Family"];
		
		/**
		 * Make a call to get all configuration data from server. For now, uses
		 * 	a list of default things to retreieve.
		 * @return {JSON} product configuration information
		 */
		function getConfigurationData() {
			if (configurationData) {
				return $q.when(configurationData);

			}
			var includes = [
				'customSettings',
				'displayActions',
				'displayColumns'
			];
			var dataRequest = createCatalogRequestDO(null, null, null, includes, null);
			var dataPromise = RemoteService.getConfigurationData(dataRequest);
			return dataPromise.then(function (result) {
				//Extend will add references to any properties in the result
				//Returns a reference to first param
				configurationData = {};
				return angular.extend(configurationData, result);

			});

		}

		function getDisplayColumns() {
			return getConfigurationData().then(function (result) {
				return result.displayColumns;

			});
			
		}

		function getDisplayActions() {
			return getConfigurationData().then(function (result) {
				return result.displayActions;

			});

		}

		function getCustomSettings() {
			return getConfigurationData().then(function (result) {
				return result.customSettings;

			});

		}
		
		/**
		 * Catalog request constructor
		 */
		function createCatalogRequestDO(categoryIds, searchText, productFilters, responseIncludes, products) {
			searchText = searchText || "";
			categoryIds = categoryIds || [];

			if(!products) {
				products = [];
			}

			if (!categoryIds) {
				categoryIds = [];
			
			} else if (typeof categoryIds === 'string') {
				//Split on spaces and/or commas
				var separatorRegex = /[\s,]+/;
				categoryIds = categoryIds.trim().split(separatorRegex);

			}
			if (!responseIncludes) {
	     responseIncludes = [
	     		"prices",
	     		"productFilters"
				];

			}
			if (!productFilters) {
				productFilters = [];

			}

			//Establish request object with defaults
			var catalogRequest = {
				"cartId": service.cartId,
				"configRequestId": service.configRequestId,
				"priceListId": service.priceListId,
				"categoryIds": categoryIds,
				"productSearchInfo": {
					"orderByFields": [],
					"searchAllProducts": false,
					"searchFields": [
						"Name",
						"ProductCode",
						"Family"
					],
					"productFilters": angular.copy(productFilters),
					"searchText": searchText

				},
				"responseIncludes": responseIncludes,
				"products": angular.copy(products)
				
			};

			return catalogRequest;

		}


		/**
		 * Cart request constructor
		 */
		function createCartRequestDO(lineItems, applyConstraintRules, updatePrice, responseIncludes) {
			updatePrice = (typeof updatePrice === "undefined" ? false : !!updatePrice);
			applyConstraintRules = (typeof applyConstraintRules === "undefined" ? false : !!applyConstraintRules);
			/**
			 * 
			 * @return {[type]}            [description]
			 */
			if (!lineItems) {
				lineItems = [];
			
			} else if (typeof lineItems === 'object' && lineItems.hasOwnProperty('lineItemSO')) {
				lineItems = [lineItems];

			}
			if (!responseIncludes) {
			 responseIncludes = [
					"cart",
					"cartLines",
					"optionLines",
					"chargeLines",
					"totalLines",
					"grandTotal"
				];

			}

			var cartRequest = {
				"cartId": service.cartId,
				"configRequestId": service.configRequestId,
				"lineItems": lineItems,
				"responseIncludes": responseIncludes,
				"applyConstraintRules": applyConstraintRules,
				"updatePrice": updatePrice

			};

			return cartRequest;

		}

	}

})();			