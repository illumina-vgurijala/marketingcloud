 ;(function() {
	angular.module('aptBase')
		.filter('aptNumberToPercent', numberToPercentFilter);

	numberToPercentFilter.$inject = ['$filter'];

	function numberToPercentFilter($filter) {
		return numberToPercent;
		/**
		 * Take a value that can be coerced into a number and return the
		 * 	corresponding percentage-formatted string.
		 * 	
		 * @param  {[type]} input [inputValue]
		 * @param  {[type]} customPrecision [systemProperties.precision]
		 * @return {[type]} [percentage-formatted string]
		 */
		function numberToPercent(input, customPrecision) {
			if (angular.isNumber(input)) {
				return $filter('aptNumberToQuantity')(input, customPrecision) + '%';
			}
			else {
				return '';
			}			
		}
	}

})();