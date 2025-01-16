 ;(function() {
	angular.module('ngCPQ')
		.directive('apt-date', DateDirective);
	
	DateDirective.$inject = ['baseUrl'];
	DateController.$inject = [];

	function DateDirective(baseUrl) {
		var directive = {
			restrict: 'AE',
			templateUrl: baseUrl + '/views/date-directive.html',
			scope: {
				value: '=',
				dateFormat: '=',
				readOnly: '='
			},
			controller: DateController,
			controllerAs: 'DateCtrl',
			bindToController: true

		};
		return directive;

	}

	function DateController() {
		var ctrl = this;

		if (ctrl.value) {
			ctrl.dateValue = new Date(ctrl.value);
			
		} else {
			ctrl.dateValue = new Date();

			
		}

		ctrl.updateValue = function() {
			if (ctrl.readOnly) {
				return;

			}
			ctrl.value = ctrl.dateValue.getTime();

		};
		
	}
	
})();

	