(function() {
	angular.module('ngCPQ')
		.service('AttributesCache', AttributesCache);

	function AttributesCache() {
		var cache = this;

		var productToAttributeGroupsMap, lineItemToAttributeValueMap, attributeFields;

		cache.putAttributeGroupsForProduct = putAttributeGroupsForProduct;
		cache.getAttributeGroupsForProduct = getAttributeGroupsForProduct;
		cache.putAttributeFields = putAttributeFields;
		cache.getAttributeFields = getAttributeFields;
		cache.getAttributeValueSOForLineItem = getAttributeValueSOForLineItem;
		cache.putAttributeValueSOForLineItem = putAttributeValueSOForLineItem;
		init();

		function init() {
			resetAttributes();

		}

	    /**
		 * reset attributes
		 */
		function resetAttributes() {
			cache.isValid = false;
			productToAttributeGroupsMap = {};
			lineItemToAttributeValueMap = {};

		}

	    /**
		 * update attribute groups for product
		 */
		function putAttributeGroupsForProduct(productId, AttributeGroups) {
			if(!productId) {
				return;
			}

			productToAttributeGroupsMap[productId] = AttributeGroups;
			cache.isValid = true;

		}

		/**
		 * get attribute groups for product
	     */
		function getAttributeGroupsForProduct(productId) {
			if(!productId || !cache.isValid) {
				return null;
			}

			if(productToAttributeGroupsMap[productId]) {
				return null;

			}

			return productToAttributeGroupsMap[productId];

		}

		/**
		 * update attribute fields
		 */
		function putAttributeFields(newAttributeFields) {
			if(!attributeFields) {
				return;
			
			}

			attributeFields = newAttributeFields;
			cache.isValid = true;

		}

		/**
		 * get attribute fields
		 */ 
		function getAttributeFields() {
			if(!attributeFields || !cache.isValid) {
			 return null;

			}
			return attributeFields;

		}

		/**
		 * get attribute value record for lineItem
		 */
		function getAttributeValueSOForLineItem(lineItemId) {

			if(!lineItemId || !cache.isValid) {
				return null;
			}

			if(!lineItemToAttributeValueMap[lineItemId]) {
				return null;
			}

			return lineItemToAttributeValueMap[lineItemId];

		}

		/**
		 * update attribute value record for lineItem
		 */
		function putAttributeValueSOForLineItem(lineItemId, attributeValueRecord) {

			if(!lineItemId) {
				return  null;
			}

			lineItemToAttributeValueMap[lineItemId] = attributeValueRecord;
			cache.isValid = true;
		}

	}

})();