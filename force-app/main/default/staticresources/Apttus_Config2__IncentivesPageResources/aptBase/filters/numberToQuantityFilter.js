 ;(function() {
	angular.module('aptBase')
		.filter('aptNumberToQuantity', numberToQuantityFilter);

	numberToQuantityFilter.$inject = ['aptBase.i18nService', 'aptBase.UtilService'];

	function numberToQuantityFilter(i18nService, UtilService) {
		return numberToQuantity;
		/**
		 * Take a value that can be coerced into a number and return the
		 * 	corresponding quantity-formatted string.
		 * 	
		 * @param  {[type]} input [description]
		 * @return {[type]}       [description]
		 */
		function numberToQuantity(input, customPrecision) {
			var quantitySettings = i18nService.quantitySettings;
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
			
			} else if (angular.isNumber(quantitySettings.precision)) {
				precision = quantitySettings.precision;

			}
			//Use toFixed to get string representation with correct padding & rounding
			var inputAsFixed = UtilService.round(inputAsNumber, precision).toFixed(precision);
			//Create regexp that matches group lengths based on template
			var matches = inputAsFixed.match(quantitySettings.groupingExp);
			var inputFormatted = '';
			if (matches) {
				matches.shift();
				//Always take initial group of digits
				inputFormatted += matches[0];
				//Insert separators for interior numbers if they exist
				var toGroup = matches[1];
				if (toGroup) {
					for (var i = 0; i < toGroup.length; i++) {
						if (i % quantitySettings.groupLength === 0) {
							inputFormatted += quantitySettings.separator;

						}
						inputFormatted += toGroup[i];
					}

				}
				//If decimal exists, add decimal point and decimal
				if (matches[2]) {
					inputFormatted += quantitySettings.decimal + matches[2];
					
				}

			}
			if (isNegative) {
				inputFormatted = '-' + inputFormatted;
				
			}
			return inputFormatted;

		}

	}

})();