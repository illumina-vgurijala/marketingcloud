 ;(function() {
	angular.module('aptBase')
		.filter('aptNumberToCurrency', numberToCurrencyFilter);

	numberToCurrencyFilter.$inject = ['aptBase.i18nService', 'aptBase.UtilService'];

	function numberToCurrencyFilter(i18nService, UtilService) {
		return numberToCurrency;
		/**
		 * Take a value that can be coerced into a number and return the
		 * 	corresponding currency string.
		 * 	
		 * @param  {[type]} input [description]
		 * @return {[type]}       [description]
		 */
		function numberToCurrency(input, customPrecision) {
			var currencySettings = i18nService.currencySettings;
			//For now, just ignoring anything that can't be parsed as number
			var inputAsNumber = Number(input);
			if (isNaN(inputAsNumber)) {
				return input;

			}
			//Handle negative value
			var isNegative = inputAsNumber < 0;
			inputAsNumber *= (1 - 2*isNegative);
			var precision = 2;
			if (angular.isNumber(customPrecision)) {
				precision = customPrecision;
			
			} else if (angular.isNumber(currencySettings.precision)) {
				precision = currencySettings.precision;

			}
			//Use toFixed to get string representation with correct padding & rounding
			var inputAsFixed = UtilService.round(inputAsNumber, precision).toFixed(precision);
			//Create regexp that matches group lengths based on template
			var matches = inputAsFixed.match(currencySettings.groupingExp);
			var inputFormatted = '';
			if (matches) {
				matches.shift();
				//Always take initial group of digits
				inputFormatted += matches[0];
				//Insert separators for interior numbers if they exist
				var toGroup = matches[1];
				if (toGroup) {
					for (var i = 0; i < toGroup.length; i++) {
						if (i % currencySettings.groupLength === 0) {
							inputFormatted += currencySettings.separator;

						}
						inputFormatted += toGroup[i];
					}

				}
				//If decimal exists, add decimal point and decimal
				if (matches[2]) {
					inputFormatted += currencySettings.decimal + matches[2];
					
				}
				//Prepend or append currency symbol
				if (currencySettings.isSymbolBefore) {
					inputFormatted = currencySettings.symbol + inputFormatted;

				} else {
					inputFormatted += currencySettings.symbol;

				}

			}
			if (isNegative) {
				inputFormatted = '(' + inputFormatted + ')';
				
			}
			return inputFormatted;

		}

	}

})();