;(function() {
	angular.module('aptBase')
		.filter('truncateText', truncateTextFilter);

	truncateTextFilter.$inject = ['$filter'];

	function truncateTextFilter($filter) {
		return truncateString;
		/**
		 * Take an input string and truncate it to the desired limit 
		 * (number of characters) and append an ellipsis to it (3 extra 
		 * characters)
		 * 
		 * @param  {[type]} input [description]
		 * @param  {[type]} limit [description]
		 * @return {[type]}       [description]
		 */
		function truncateString(input, limit) {                        
			return input.length > limit ? $filter('limitTo')(input, limit) + "..." : input;
		}
	}
})();
