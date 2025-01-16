// assetDataService declaraion
// this service facilitates remoting calls to fetch Asset line item data 
// as well as Asset Filter data. This service will also support all other
// actions on asset data that requires remoting calls to Apex classes.
// 
// Author - Mihir Parikh
// (c)2015 - Apttus Corp.
//

(function() {
	'use strict';

	angular.module('ngCPQ').service('AssetDataService', AssetDataServiceFunc);

	AssetDataServiceFunc.$inject = ['$q', '$http', '$log', 'ConfigurationDataService', 'RemoteService'];
		
	function AssetDataServiceFunc($q, $http, $log, ConfigurationDataService, RemoteService) {
		var assetDataService = this;

		// assetDataService.assetLineItemData = {}; 
		
		// remoting call to get asset line items
		assetDataService.getAssetLineItemData = function() {
			var includeParams = ['cartLines', 'chargeLines', 'ruleActions'];
			var assetRequest = ConfigurationDataService.createCartRequestDO(null, null, null, includeParams);
			var requestPromise = RemoteService.getAssetLineItems(assetRequest);

			return requestPromise.then(function(result) {
				var lineItemData = result.assetLineItems; // asset line items array
				return lineItemData;
			});
		};

		// implementation pending
		assetDataService.getAssetFiltersData = function() {
			var includeParams = ['cartLines', 'chargeLines', 'ruleActions'];
			var assetFilterReqeust = ConfigurationDataService.createCartRequestDO(null, null, null, includeParams);
			var requestPromise = RemoteService.getAssetFilters(assetFilterReqeust);

			return requestPromise.then(function(result){
				return result;
			});
		};

		return assetDataService; // return the service object
	}
	
})();
