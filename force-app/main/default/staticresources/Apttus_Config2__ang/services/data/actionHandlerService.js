;(function() {
	angular.module('ngCPQ')
		.service('ActionHandlerService', ActionHandlerService); 
			
	ActionHandlerService.$inject = ['$q','$log','RemoteService', 'ConfigurationDataService', 'CartDataService'];

	function ActionHandlerService($q, $log, RemoteService, ConfigurationDataService, CartDataService) {
		var service = this;

		service.performAction = performAction;

		/**
		 * perform action, some actions are navigational and some require submit to server
		 */
		function performAction(actionInfo) {
			console.log(actionInfo);
			if (!actionInfo.IsEnabled) {
				return $q.when();

			}
			
			var actionName = actionInfo.ActionName;
			
			if (actionName == 'AddMoreProducts') {
				return $q.when({targetType: "state", path: "catalog"});
				
			} else if (actionName == 'InstalledProducts') {
				return $q.when({targetType: "state", path: "assets"});
				
			} else if (actionName == 'GoToPricing') {
				return $q.when({targetType: "state", path: "cart"});
				
			} else if (actionName == 'EditPriceAgreement') {
				return $q.when({targetType: "dialog", path: "priceagrement"});
				
			// } else if (actionName == 'Finalize') {
			} else {
				var includeParams = ['cartLines', 'chargeLines', 'ruleActions'];
				var cartRequest = ConfigurationDataService.createCartRequestDO(null, null, null, includeParams);
				cartRequest.displayAction = angular.copy(actionInfo);
				
				return RemoteService.performAction(cartRequest).then(
					function (result){
						console.log('following action was performed-->');
						console.log(actionInfo);
						console.log('targetPageReference-->');
						console.log(result.targetPageReference);
					}
						
				);
				
			} 
			
			
		}
		
		
	}

})();