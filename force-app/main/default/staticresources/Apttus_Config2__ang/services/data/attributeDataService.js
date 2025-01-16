;(function() {
	angular.module('ngCPQ')
		.service('AttributeDataService', AttributeDataService); 
			
	AttributeDataService.$inject = ['$q','$log','RemoteService', 'ConfigurationDataService', 'CatalogCache', 'CartDataService' , 'AttributesCache'];

	function AttributeDataService($q, $log, RemoteService, ConfigurationDataService, CatalogCache, CartDataService , AttributesCache) {
		var service = this;

		service.getAttributeGroups = getAttributeGroups;
		service.getAttributeValueSO = getAttributeValueSO;
		service.getAttributeFields = getAttributeFields;
		service.newAttributeValueSO = newAttributeValueSO;

		/**
		 * get attribute groups for given productId
		 */
		function getAttributeGroups(productId) {
			var cachedAttributeGroups = AttributesCache.getAttributeGroupsForProduct(productId);
			
			if (cachedAttributeGroups) {
				return $q.when(cachedAttributeGroups);
				
			}

			var includeParams = ["attributeGroups"];
			/*
			var products = CatalogCache.getProductInfo(productId);
			if(!products) {
			products = LineItemCache.getProductInfo(productId);

			}*/

			var products = [{
				"Id": productId,
				"HasAttributes__c": true,
				"HasOptions__c": true
			}];

			var attributeGroupRequest = ConfigurationDataService.createCatalogRequestDO(null, null, null, includeParams, products);
			var requestPromise = RemoteService.getProductDetails(attributeGroupRequest);
			
			return requestPromise.then(function(response) {
				AttributesCache.putAttributeGroupsForProduct(productId, response.attributeGroups[productId]);
				return response.attributeGroups[productId];

			});

		}

		/**
		 * get attribute value so for given lineItemId
		 */
		function getAttributeValueSO(txnPrimaryLineNumber) {
			return CartDataService.getLineItemDetails(txnPrimaryLineNumber).then(function (lineItem) {
				var primaryLineSO = lineItem.chargeLines[0].lineItemSO;
				if (!primaryLineSO.AttributeValueId__r) {
					$log.debug('Making new ASO');
					return newAttributeValueSO(primaryLineSO.ProductId__c).then(function (valueSO) {
						primaryLineSO.AttributeValueId__r = valueSO;
						return valueSO;

					});

				}
				return primaryLineSO.AttributeValueId__r;

			});

		}

		/**
		 * get attribute fields
		 */
		function getAttributeFields() {
			var attributeFields = AttributesCache.getAttributeFields();
			
			if(attributeFields) {
				return $q.when(attributeFields);
			}
		
			var includeParams = ["attributeFields"];
			
			var attributeFieldRequest = ConfigurationDataService.createCatalogRequestDO(null, null, null, includeParams, null);
			var requestPromise = RemoteService.getConfigurationData(attributeFieldRequest);
			
			return requestPromise.then(function(response) {
				AttributesCache.putAttributeFields(response.attributeFields);
				return response.attributeFields;

			});

		}



		/**
		 * upsert Attribute Value SO for the given Line Item. 
		 */ 
		function upsertAttributesValueSO(lineItemId, attributeSO) {
			// if(!attributeSO.LineItemId__c) {
			// 		attributeSO.LineItemId__c = luineItemId;
	 
			// }

			// var lineItemDO = LineItemCache.getLineItem(lineItemId); // Use Cart Service to get the lineItemDO
			// lineItemDO.attributeValueSO = attributeSO;
				 
			// var lineItems = [];
			// lineItems.push(lineItemDO);
			// var updateAttributesRequest = ConfigurationDataService.createCartRequestDO(lineItems, false, false, null);
				 
			// var requestPromise = RemoteService.upsertAttributesConfiguration(updateAttributesRequest);
			// return requestPromise.then(function(response) {
			// 	var valueSO = response[0].attributeValueSO;
			// 	AttributesCache.putAttributeValueSOForLineItem(lineItemId, valueSO); // update attributes in lineItemCache
		
			// 	return response;
						 
			// });
		}

		/**
		 * Create an attrbiute value SO for a given product. Just a template,
		 * 	could cache and copy to save time looping.
		 * 	
		 * @param  {[type]} productId [description]
		 * @return {[type]}           [description]
		 */
		function newAttributeValueSO(productId) {
			var newSO = {};
			return getAttributeGroups(productId).then(function	(groups) {
				var nextGroup, nextAttr;
				for (var groupIndex = groups.length - 1; groupIndex >= 0; groupIndex--) {
					nextGroup = groups[groupIndex];
					for (var attrIndex = nextGroup.Attributes__r.length - 1; attrIndex >= 0; attrIndex--) {
						nextAttr = nextGroup.Attributes__r[attrIndex];
						newSO[nextAttr.Field__c] = "You can't stop the signal.";

					}

				}
				return newSO;
			});
			
		}

	}

	

})();