;(function() {
	angular.module('ngCPQ')
		.service('ConstraintRuleDataService', ConstraintRuleDataService); 
	
	ConstraintRuleDataService.$inject = ['messenger'];

	function ConstraintRuleDataService(messenger) {
		var service = this;

		service.ruleActions = {};
		service.updateRuleActions = updateRuleActions;

		function getRuleActions() {
			return service.ruleActions;

		}

		/**
		 * Insert new rule actions into stored actions.
		 * Currently just overwrites, maybe should merge?
		 * 
		 * @param  {Object} newActions Actions structure
		 * @return {Object}            Reference to rule actions 
		 */
		function updateRuleActions(newActions) {
			if (newActions && (newActions.error.length || newActions.info.length || newActions.warning.length)) {
				service.ruleActions.error = newActions.error;
				service.ruleActions.info = newActions.info;
				service.ruleActions.warning = newActions.warning;
				
			} else {
				service.ruleActions.error = null;
				service.ruleActions.info = null;
				service.ruleActions.warning = null;
				
			}
			messenger.notify(service.ruleActions);
			return service.ruleActions;

		}

	}

})();