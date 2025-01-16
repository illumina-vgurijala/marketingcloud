;(function() {
	angular.module('aptBase')
		.filter('aptQuantityToNumber', quantityToNumberFilter);

	quantityToNumberFilter.$inject = ['aptBase.i18nService', 'aptBase.UtilService'];

	function quantityToNumberFilter(i18nService, UtilService) {
		return quantityToNumber;
		/**
		 * Take a string value that looks like a quantity and convert it into
		 * 	an number. All non-digit, non-decimal-separator characters are stripped
		 * 	out before number construction. If the decimal-separator character 
		 * 	appears more than once, all instances beyond the first are discarded.
		 * 	
		 * @param  {[type]} input [description]
		 * @return {[type]}       [description]
		 */
		function quantityToNumber(input, customPrecision) {
			var quantitySettings = i18nService.quantitySettings;
			if (typeof input !== 'string') {
				return input;

			}
			input = input.trim();
			var isNegative = input[0] == '-';
			var nonDigitRegex = /\D/g;
			var foundDecimal = false;
			var digitsOnly = input.replace(nonDigitRegex, function(match) {
				//Return '.' in place of the first instance of decimal separator.
				if (!foundDecimal && match == quantitySettings.decimal) {
					foundDecimal = true;
					return '.';

				} else if (!foundDecimal && match == '-') {
					isNegative = true;

				}
				return '';

			});
			var precision = 2;
			if (angular.isNumber(customPrecision)) {
				precision = customPrecision;
			
			} else if (angular.isNumber(quantitySettings.precision)) {
				precision = quantitySettings.precision;

			}
			var inputAsNumber = UtilService.round(digitsOnly, precision);
			inputAsNumber *= (1 - 2*isNegative); 
			return inputAsNumber;

		}

	}

})();