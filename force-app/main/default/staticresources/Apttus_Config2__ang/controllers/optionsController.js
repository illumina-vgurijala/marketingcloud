(function(){
	angular.module('ngCPQ')
		.controller('OptionsController', OptionsController);

	OptionsController.$inject = ['$routeParams', 'CartDataService', 'OptionDataService'];    
	
	function OptionsController($routeParams, CartDataService, OptionDataService) {
		var OptionsCtrl = this;
		var txnLineNumber = $routeParams.txnLineNumber;
		var productId;
		OptionsCtrl.name = 'OptionsController-->OptionsCtrl';
		OptionsCtrl.parentLineItem = null;
		OptionsCtrl.componentLineItems = [];
		OptionsCtrl.optionGroups = [];
		
		OptionsCtrl.getLineItemDO = getLineItemDO;
		OptionsCtrl.updateBundle = updateBundle;
		OptionsCtrl.performAction = performAction;
		
		
		//update the context bundle line item 
		function performAction(actionName) {
			console.log(actionName);
			//OptionDataService.updateBundle(OptionsCtrl.parentLineItem);
			
		}
		
		//update the context bundle line item 
		function updateBundle() {
			console.log(OptionsCtrl.parentLineItem);
			OptionDataService.updateBundle(OptionsCtrl.parentLineItem);
			
		}
		
		//returns existing or newly added line items
		function getLineItemDO(parentLine2, option) {
			//console.log('-->getLineItemSO: optionId=' + option.Id);
			parentLine2 = OptionsCtrl.parentLineItem;//TODO: use cascaded parentLineItem
			//console.log(parentLine2);
			
			var lineItemDO = OptionsCtrl.componentLineItems[option.Id];
			if (angular.isDefined(lineItemDO)) {
				return lineItemDO;
				
			} else {
				var nextPrimaryLineNumber = OptionDataService.getNextPrimaryLineNumber();
				var nextItemSequence = OptionDataService.getNextItemSequence(parentLine2);
				//TODO: set values in server side for now
				var tempDO = {lineItemSO: {Id: null, ConfigurationId__c: parentLine2.chargeLines[0].lineItemSO.ConfigurationId__c,
										   "ProductId__c": parentLine2.chargeLines[0].lineItemSO.ProductId__c,
										   "OptionId__c": option.ComponentProductId__c,
										   "LineType__c": 'Option',
										   "ProductOptionId__c": option.Id, "Quantity__c": option.DefaultQuantity__c,
										   "LineNumber__c": parentLine2.chargeLines[0].lineItemSO.LineNumber__c,
										   "IsPrimaryLine__c": true,
										   "PrimaryLineNumber__c": nextPrimaryLineNumber,
										   "ItemSequence__c": nextItemSequence,
										   "ParentBundleNumber__c": parentLine2.chargeLines[0].lineItemSO.PrimaryLineNumber__c 
										   },
								"txnPrimaryLineNumber": nextPrimaryLineNumber		   
							  };
				
				tempDO.isSelected = (option.IsDefault__c || option.IsRequired__c);
				
				OptionsCtrl.componentLineItems[option.Id] = tempDO;
				OptionDataService.addOptionLineItem(parentLine2, tempDO);
				
				return tempDO;
				
			}
			
		}
		
		//loads parent line items
		function loadParentLineItem() {
			console.log('-->loadParentLineItem: txnLineNumber='+txnLineNumber);	
			if (!txnLineNumber) {
				return;

			}
			CartDataService.getLineItem(txnLineNumber)
				.then(function(result) {
					console.log('CartDataService-->getLineItem call complete');
					OptionsCtrl.parentLineItem = result;
					OptionDataService.createOptionLineItemMap(OptionsCtrl.componentLineItems, result);
					productId = result.lineItemSO.ProductId__c;
					
					OptionDataService.getOptionGroups(productId)
					.then(function(result) {
						OptionsCtrl.optionGroups = result;
						console.log(OptionsCtrl.optionGroups);
						
					});
					
				});

			

		}
		
	
		// at the bottom of your controller
		var init = function () {
			loadParentLineItem();
			
		};
		// and fire it after definition
		init();
		
	}
	
})();