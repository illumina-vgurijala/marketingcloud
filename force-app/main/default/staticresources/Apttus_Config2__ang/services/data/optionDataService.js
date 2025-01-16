;(function() {
	angular.module('ngCPQ')
		.service('OptionDataService', OptionDataService); 
			
	OptionDataService.$inject = ['$q','$log','RemoteService', 'ConfigurationDataService', 'OptionsCache'];

	function OptionDataService($q, $log, RemoteService, ConfigurationDataService, OptionsCache) {
		var service = this;
		var primaryNumber = 10000; 
		
		
		service.getOptionGroups = getOptionGroups;
		service.createOptionLineItemMap = createOptionLineItemMap;
		service.updateBundle = updateBundle;
		service.getNextPrimaryLineNumber = getNextPrimaryLineNumber;
		service.getNextItemSequence = getNextItemSequence;
		service.addOptionLineItem = addOptionLineItem;		
		
		function getNextPrimaryLineNumber() {
			return ++primaryNumber;
		}
		
		function getNextItemSequence(lineItemDO) {
			var itemSequence = 2;
			if(angular.isArray(lineItemDO.chargeLines)) {
				itemSequence +=  lineItemDO.chargeLines.length;
			}
			if(angular.isArray(lineItemDO.optionLines)) {
				itemSequence +=  lineItemDO.optionLines.length;
			}
			return itemSequence;
		}

		function addOptionLineItem(lineItemDO, optionLineItemDO) {
			if(!angular.isArray(lineItemDO.optionLines)) {
				lineItemDO.optionLines = [];
			}

			lineItemDO.optionLines.push(optionLineItemDO);
		}


		/**
		 * get attribute groups for given productId
		 */
		function getOptionGroups(productId) {
			var cachedOptionGroups = OptionsCache.getOptionGroupsForProduct(productId);
			
			if(cachedOptionGroups) {
				return $q.when(cachedOptionGroups);
			}
			
			var includeParams = ["optionGroups"];
			/* TODO: find if the product has attributes 
			var products = CatalogCache.getProductInfo(productId);
			if(!products) {
			products = LineItemCache.getProductInfo(productId);

			}*/
				
			var products = [{
				"Id": productId,
				"HasAttributes__c": true,
				"HasOptions__c": true
			}];

			var optionGroupRequest = ConfigurationDataService.createCatalogRequestDO(null, null, null, includeParams, products);
			var requestPromise = RemoteService.getProductDetails(optionGroupRequest);
			
			return requestPromise.then(function(response) {
				OptionsCache.updateOptionGroupsForProduct(productId, response.optionGroups[productId]);
				return response.optionGroups[productId];

			});

		}
		
		/**
		 * update option line item based on select/de-select 
		 */
		function updateBundle(lineItemDO) {
			
			//CartDataService.updateCartLineItems([].push(lineItemDO));
			
			RemoteService.updateCart(createCartRequest(lineItemDO)).then(
					function (result){
						console.log('bundle update was successful');
						console.log(result);
						//cartCtrl.lineItems = result; //TODO: get the updated line item DO

					},
					function (error) {
						//loadCartLineItems();
					}
			);
		
		}
		
		
		/**
		 * map with component id as key and line item as value
		 */
		function createOptionLineItemMap(componentLineItemMap, lineItemDO) {
			if(lineItemDO.hasOwnProperty('optionLines')) {
				mapComponentLines(componentLineItemMap, lineItemDO.optionLines);
			}
			
		}
		
		/**
		 * create a map of component id and line item 
		 */
		function mapComponentLines(componentLineItemMap, lineItemDOs) {
			for (var i=0; i<lineItemDOs.length; i++) {
				var lineItemDO = lineItemDOs[i];
				componentLineItemMap[lineItemDO.lineItemSO['ProductOptionId__c']] = lineItemDO; //use ns prefix
				if(lineItemDO.hasOwnProperty('optionLines')) {
					mapComponentLines(componentLineItemMap, lineItemDO.optionLines);
				}
			}
		}
		
		/**
		 * creates a cart request 
		 */
		function createCartRequest(lineItemDO){
			//delete lineItemDO.$$hashKey;
			return {
				"cartId": lineItemDO.lineItemSO.ConfigurationId__c,
				"lineItems": [angular.copy(lineItemDO)],
				"responseIncludes": [
					"cartLines",
					"optionLines",
					"chargeLines",
					"ruleActions"
				]
			};
			
		}

	}

})();