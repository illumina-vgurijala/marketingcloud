;(function() {
	angular.module('ngCPQ')
		.service('DisplayActionDataService', DisplayActionDataService); 
			
	DisplayActionDataService.$inject = ['$q', '$log', 'ConfigurationDataService'];

	function DisplayActionDataService($q, $log, ConfigurationDataService) {
		var service = this;
		service.getDisplayActions = getDisplayActions; 

		/**
		 * Return the display actions for a particular type. Valid type strings:
				attributePageActions
				cartPageActions
				catalogPageActions
				optionPageActions
		 */
		function getDisplayActions(actionGroupType) {
			return ConfigurationDataService.getDisplayActions().then(function (result) {
				return result[actionGroupType];
			
			});

		}

	}

})();