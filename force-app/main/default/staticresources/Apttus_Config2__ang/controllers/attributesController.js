;(function() {
	angular.module('ngCPQ')
		.controller('AttributesController', AttributesController);

	AttributesController.$inject = ['$scope', '$routeParams', 'AttributeDataService'];

	function AttributesController($scope, $routeParams, AttributeDataService) {
 		var ctrl = this;
 		ctrl.attrSO = "Nothing yet";

		init();
		
		function init() {
			loadAttributeValueSO();
			
		}
		
		function loadAttributeValueSO() {
			AttributeDataService.getAttributeValueSO($routeParams.txnLineNumber)
				.then(function (result) {
					ctrl.attrSO = result;

				});

		}

		function loadAttributeFields() {
			
		}

		function loadAttributeGroups() {
			
		}


	
	}

})();