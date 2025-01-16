(function() {
	var assetFilterCtrl, AssetFilter;

	assetFilterCtrl = function(ngCPQLabels, AssetService) {
		var assetCtrlRef = this;
		// console.log("ngCPQLabels.labels.FilterAssets : " + ngCPQLabels.labels.FilterAssets);
		// assetCtrlRef.startDateFilter;
		// assetCtrlRef.endDateFilter;

		// fetch filters from backend
		AssetService.getAssetFilterList().then(function(result){
			// filters
			var filterData = result;
			var iFilterList = [];
			var filterListKeys = Object.keys(filterData.assetFilterFields)
			filterListKeys.forEach(function(key) {
				var filterInstance = filterData.assetFilterFields[key];
				if (filterInstance.FieldType === "PICKLIST") {
					// add a collapse/expand model property to assist the UI
					filterInstance.viewCollapse = false;

					// add a 'selected' model attribute to each of the picklist items
					filterInstance.pickListEntries.forEach( function(picklistItem) {
						picklistItem.selected = false;
						picklistItem.FieldName = filterInstance.FieldName;
					});

					iFilterList.push(filterInstance);
				} else if (filterInstance.FieldType == "DATE") {
					filterInstance.viewCollapse = false;
					filterInstance.dateValue = "";
					iFilterList.push(filterInstance);
				}
			});
			
			console.log(iFilterList);

			assetCtrlRef.filterList = iFilterList;
			assetCtrlRef.lables = ngCPQLabels.labels;
		});

		this.clearSelectedFilters = function() {
			// click handler to clear all filters that have been selected
			for (var filterIdx in assetCtrlRef.filterList) {
				if (assetCtrlRef.filterList[filterIdx].FieldType === 'PICKLIST') {
					assetCtrlRef.filterList[filterIdx].pickListEntries.forEach(function(picklistItem) {
						picklistItem.selected = false;
					});
				}
				else if (assetCtrlRef.filterList[filterIdx].FieldType == 'DATE') {
					if (assetCtrlRef.filterList[filterIdx].dateValue != undefined &&
						  assetCtrlRef.filterList[filterIdx].dateValue.setDate != undefined) {
							assetCtrlRef.filterList[filterIdx].dateValue.setDate(null);
					}
				}
				// more types handled here...
			}

		};

		this.filterSelectHandler = function(modelData) {
			// console.log("Filter \"" + modelData.label + "\" selection changed to: " + modelData.selected);
			AssetService.handleFilterAddRemove(modelData); // make a call to asset service
		};
	};

	assetFilterCtrl.$inject = ['ngCPQLabels', 'AssetService'];

	AssetFilter = function(baseUrl) {
		return {
			restrict: 'E',
			scope: {},	
			controller: assetFilterCtrl,
			controllerAs: 'assetCtrl',
			templateUrl: baseUrl + "/templates/directives/assets-filter.html"
		};
	};

	AssetFilter.$inject = ['baseUrl'];

	angular.module('ngCPQ').directive('assetsFilter', AssetFilter);

}).call(this);