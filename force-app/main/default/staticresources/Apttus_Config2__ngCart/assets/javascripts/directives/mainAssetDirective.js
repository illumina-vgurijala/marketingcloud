(function() {
	var MainAsset, mainAssetCtrl;

	mainAssetCtrl = function($q, $stateParams, AssetService) {
		// get line items and column metadata
		var activate, mainAssetRef;
		mainAssetRef = this;
		mainAssetRef.view = $stateParams.view;

		mainAssetRef.linesPerPage = 25;

		activate = function() {
			return $q.all([AssetService.getAssetLineItems(), AssetService.getColumnMetadata()]).then(function(res){
				mainAssetRef.assetLineItems = res[0];
				// console.log("Asset Lines: " + res[0].length)
				var assetDisplayCols = res[1];
				// console.log("Display Columns: " + res[1].displayColumns.assetItemColumns.length)
				// this should be a reusable utility method - mparikh
				mainAssetRef.columnTypes = assetDisplayCols.assetItemColumns.map(function(element){
					var replace_r;
					if (element.FieldType === 'REFERENCE') {
						replace_r = element.FieldName.replace('__c', '__r');
						element.FieldName = replace_r;
					}
					if (element.FieldName.indexOf('ProductId__r') > -1) {
						element.FieldType = 'DETAIL';
					} else if (element.FieldName.indexOf('ChargeType') > -1) {
						element.FieldType = 'CHARGETYPE';
						mainAssetRef.chargeKey = element.FieldName; // why?
					} else if (element.FieldName.indexOf('Quantity') > -1) {
						element.FieldType = 'QUANTITY';
					} else if (element.FieldName.indexOf('AssetStatus') > -1) {
						element.FieldType = 'STRING';
					}
					return element;
				});
				mainAssetRef.tableColumns = mainAssetRef.columnTypes.filter(function(element){
					if(element.FieldName.indexOf('ChargeType') <= -1) {
						return true; // all elements that are NOT ChargeType
					}
				});
				return mainAssetRef.assetDisplayCols;
			});
		};
		
		activate();

		// fix this!
		return mainAssetRef.getColumnData = function(columnField) {
			return mainAssetRef.item.AssetLineItemSO[columnField];
		}
	};

	mainAssetCtrl.$inject = ['$q', '$stateParams', 'AssetService'];

	MainAsset = function(baseUrl) {
		var directive = {
			// restrict: 'AE',
			// scope: {},
			controller: mainAssetCtrl,
			controllerAs: 'mainAssetController',
			bindToController: true
		};	
		return directive;
	};

	MainAsset.$inject = ['baseUrl'];

	angular.module('ngCPQ').directive('mainAsset', MainAsset);

	

}).call(this);