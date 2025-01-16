;(function() {
	angular.module('ngCPQ')
		.service('LineItemSupport', LineItemSupport); 
		
	LineItemSupport.$inject = ['ConfigurationDataService'];

	function LineItemSupport(ConfigurationDataService) {
		var txnPrimaryLineNumber = 10001;

		var service = this;
		service.newLineItemSO = newLineItemSO;
		service.newLineItemForProduct = newLineItemForProduct;
		service.newOptionLineItemForComponent = newOptionLineItemForComponent;

		//Return the simplest, empty SO.
		function newLineItemSO() {
			var newSO = {
				"Id": null,
				"ConfigurationId__c": ConfigurationDataService.cartId
			};
			return ConfigurationDataService.getDisplayColumns().then(function (result) {
				var displayColumns = result.cartLineItemColumns;
				for (var colIndex = 0, colLength = displayColumns.length; colIndex < colLength; colIndex++) {
					nextFieldName = displayColumns[colIndex].FieldName;
					if (displayColumns[colIndex].FieldType !== 'REFERENCE') {
						newSO[nextFieldName] = undefined;

					}

				}
				return newSO;

			});

		}

		function newLineItemForProduct(productSO, quantity) {
			quantity = quantity || 1;
			var txnPLN = txnPrimaryLineNumber++;
			return newLineItemSO().then(function (lineItemSO) {
				lineItemSO.LineType__c = 'Product/Service';
				lineItemSO.Quantity__c = quantity;
				lineItemSO.ProductId__c = productSO.Id;
				lineItemSO.ProductId__r = {
					"Id": productSO.Id,
					"Name": productSO.Name
				};
				lineItemSO.HasOptions__c = productSO.HasOptions__c;
				lineItemSO.HasAttributes__c = productSO.HasAttributes__c;
				lineItemDO = {
					"lineItemSO": lineItemSO,
					"txnPrimaryLineNumber": txnPLN,
					"sequence": txnPLN,
					"chargeLines": [
						{
							"lineItemSO": lineItemSO
						}
					],
					"optionLines": []
				};
				return lineItemDO;
				
			}); 

		}

		function newOptionLineItemForComponent(productOptionComponent) {
			var txnPLN = txnPrimaryLineNumber++;
			var componentProduct = productOptionComponent.ComponentProductId__r;
			return newLineItemSO().then(function (lineItemSO) {
				lineItemSO.LineType__c = 'Option';
				lineItemSO.PrimaryLineNumber__c = txnPLN;
				lineItemSO.ProductOptionId__c = productOptionComponent.Id;
				lineItemSO.Quantity__c = productOptionComponent.DefaultQuantity__c;
				lineItemSO.OptionId__c = componentProduct.Id;
				lineItemSO.OptionId__r = {
					"Id": componentProduct.Id,
					"Name": componentProduct.Name
				};
				lineItemSO.HasOptions__c = componentProduct.HasOptions__c;
				lineItemSO.HasAttributes__c = componentProduct.HasAttributes__c;
				lineItemSO.AttributeValueId__r = {};
				lineItemDO = {
					"lineItemSO": lineItemSO,
					"txnPrimaryLineNumber": txnPLN,
					"chargeLines": [
						{
							"lineItemSO": lineItemSO
						}
					],
					"optionLines": []
				};
				return lineItemDO;
				
			}); 

		}

	}

})();