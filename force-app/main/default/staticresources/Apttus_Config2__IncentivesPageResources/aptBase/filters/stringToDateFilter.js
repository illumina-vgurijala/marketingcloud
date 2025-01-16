;(function() {
	angular.module('aptBase')
		.filter('aptStringToDate', stringToDateFilter);

	stringToDateFilter.$inject = [
		'lodash',
		'aptBase.i18nService',
		'aptBase.UtilService'
	];

	function stringToDateFilter(_, i18nService, UtilService) {
		return stringToDate;
		
		function stringToDate(input) {
			if (typeof input !== 'string') {
				return input;

			}
			var dateSettings = i18nService.dateSettings;
			var digitGroups = input.match(dateSettings.groupingExp);
			// Return input if string cannot be matched to date format
			if (!digitGroups) {
				return input;

			}
			// Discard first element which is the full string match
			digitGroups.shift();
			digitGroups = _.map(digitGroups, _.parseInt);
			var year, month, day;
			_.forEach(dateSettings.ordering, function (ymdSymbol, symbolIndex) {
				var foundIndex;
				ymdSymbol = ymdSymbol[0].toLowerCase();
				if (ymdSymbol === 'y') {
					foundIndex = _.findIndex(digitGroups, function (numVal, nextIndex, currentArr) {
						return numVal === undefined ? false : numVal > 31 || (symbolIndex == 2);
						
					});
					year = digitGroups[foundIndex];

				} else if (ymdSymbol === 'm') {
					foundIndex = _.findIndex(digitGroups, function (numVal, nextIndex, currentArr) {
						return numVal === undefined ? false : numVal <= 12;
						
					});
					month = digitGroups[foundIndex]
					
				} else if (ymdSymbol === 'd') {
					foundIndex = _.findIndex(digitGroups, function (numVal, nextIndex, currentArr) {
						return numVal === undefined ? false : numVal <= 31;
						
					});
					day = digitGroups[foundIndex];

				}
				digitGroups[foundIndex] = undefined;
				
			});
			year = year ? (year < 100 ? 2000 + year : year) : 2000; 
			month = month || 1;
			day = day || 1;
			// Note that are zero-indexed with with January = 0, December = 11
			var dateVal = UtilService.newUTCDate(year, month - 1, day);
			return dateVal;

		}

	}

})();