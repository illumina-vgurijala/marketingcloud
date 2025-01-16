(function() {
	'use strict';
	angular.module('ngCPQ').service('AssetService', AssetServiceFunc);

	AssetServiceFunc.$inject = ['lodash', '$q', 'AssetDataService', 'ConfigurationDataService'];

	function AssetServiceFunc(_, $q, AssetDataService, ConfigDataService) {
		// selected filters list - when empty the asset lines items are not filtered at all
		// when non-empty, filter out any that don't match
		var assetServiceRef = this; // for access within closures

		this.assetFilterList = []; // initalized to empty

		this.getAssetActions = function() {
			// static data for now..
			var assetActions = [
				{
					"label" : "Cancel",
					"action": "Cancel"
				},
				{
					"label" : "Swap",
					"action": "Swap"
				},
				{
					"label" : "Change",
					"action": "Change"
				},
				{
					"label" : "New",
					"action": "New"
				},
				{
					"label" : "Manage",
					"action": "Manage"
				}	
			];

			return assetActions;
		};

		this.getAssetLineItems = function() {
			return AssetDataService.getAssetLineItemData().then(function(result){
				return result;
			});
		};

		this.getColumnMetadata = function() {
			return ConfigDataService.getDisplayColumns().then(function(result) {
				return result;
			});
		};

		this.getAssetFilterList = function() {
			return AssetDataService.getAssetFiltersData().then(function(result){
				return result;
			});
		}

		// clear the asset Filter array
		this.clearAssetFilterList = function() {
			this.assetFilterList.length = 0;
			// could also do this.assetFilterList = []
		};

		// This will change dramatically once selected filters are handled via REST call to the org
		this.handleFilterAddRemove = function(modelData) {
			console.log("AssetService:: Filter \"" + modelData.label + "\" selection changed to: " + modelData.selected);
			
			if (modelData == undefined || modelData == null || modelData.selected == undefined) {
				return;	
			}
			
			if (modelData.selected == false) {
				// handle removal of the filter
				var removed = _.remove(assetServiceRef.assetFilterList, function(filterObj) {
					return filterObj.label == modelData.label;
				});
				console.log("AssetService:: " + removed.length + " removed. Now: [" + assetServiceRef.assetFilterList.length + "]");
			} else {
				var filterArrayObj = _.find(assetServiceRef.assetFilterList, function(modelData) {
					return assetServiceRef.assetFilterList.label == modelData.label;
				});					

				if (filterArrayObj == undefined) {
					// handle addition of the filter
					assetServiceRef.assetFilterList.push(modelData);
					console.log("AssetService:: Added filter - " + modelData.label + " [" + assetServiceRef.assetFilterList.length + "]");
				}
			}

			var foobar = "";
			assetServiceRef.assetFilterList.forEach(function(each){
				foobar = foobar + " " + each.label;
			}); 
			console.log("Filters = " + foobar);
		}

		return this;
	}
})();