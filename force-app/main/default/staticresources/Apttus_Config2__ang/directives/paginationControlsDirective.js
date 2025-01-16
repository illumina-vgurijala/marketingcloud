(function() {
	angular.module('ngCPQ')
		.directive('paginationControls', PaginationControls);

	function paginationController($scope) {
		var page = this;
		page.next = next;
		page.previous = previous;
		page.calculatePages = calculatePages;
		page.goTo = goTo;

		init();

		function init() {
			$scope.$watch(function(){
				return page.items;
			}, calculatePages);

			page.size = 10;
			page.hideSizeOptions = !page.options;
			if (page.options === true) {
				page.sizeOptions = [
					{name: 2, value: 2}, 
					{name: 10, value: 10}, 
					{name: 20, value: 20}, 
					{name: 50, value: 50}, 
					{name: 100, value: 100}

				];
			
			} else {
				page.sizeOptions = page.options;
				
			}

			calculatePages();

		}

		function calculatePages() {
			if (page.items) {
				page.numberOfPages = Math.ceil(page.items/page.size);
				
			} else {
				page.numberOfPages = 1;

			}
			page.currentPage = 1;
			calculateIndecies();

		}

		function calculateIndecies() {
			page.start = (page.currentPage - 1) * page.size;
			page.end = Math.min(page.start + page.size, page.items);

		}

		function next() {
			page.currentPage = Math.min(page.currentPage + 1, page.numberOfPages);
			calculateIndecies();

		}

		function previous() {
			page.currentPage = Math.max(page.currentPage - 1, 1);
			calculateIndecies();

		}

		function goTo(pageNumber) {
			page.currentPage = Math.max(Math.min(pageNumber, page.numberOfPages), 1);
			calculateIndecies();
		}

	}

	function PaginationControls(baseUrl) {
		var directive;
		directive = {
			restrict: 'AE',
			transclude: true,
			controllerAs: 'page',
			bindToController: true,
			scope: {
				start: '=',
				end: '=',
				size: '=',
				items: '=',
				options: '='

			},
			controller: paginationController,
			templateUrl: baseUrl + '/views/pagination.html'
		};
		return directive;
	}

})();