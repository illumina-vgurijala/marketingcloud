(function() {
	var app = angular.module('ngCPQ', ['ngRoute', 'ui.grid', 'ui.grid.pagination', 'dataFilters']);

	app
		.controller('RemoteCPQController', RemoteCPQController)
		.service('messenger', messenger)
		;
	
	//move this to aptUtils
	app.filter('keys', function(){
	    return function(input){
	      if(!angular.isObject(input)){
	        return 'null';
	      }
	      return Object.keys(input);
	    }
	  });

	RemoteCPQController.$inject =	['baseUrl', 'baseFileUrl', 'dataTemplate'];

	function RemoteCPQController(baseUrl, baseFileUrl, dataTemplate) {
		//Just used to display the template
		var ctrl = this;
		ctrl.dataTemplate = dataTemplate;
		ctrl.baseFileUrl = baseFileUrl;
		ctrl.baseUrl = baseUrl;

	}

	/**
	 * Sticking this in here for compatability w/ external
	 */
	function messenger() {
		this.notify = function (messages) {

		};

	}

	//configure routing
	app.config(['$routeProvider', 'baseUrl', 
		function($routeProvider, baseUrl) {
			$routeProvider
				.otherwise({
					redirectTo: '/workbench'
				})
				.when('/workbench', {
					templateUrl: baseUrl + '/views/workbench.html',
					controller: 'WorkbenchController',
					controllerAs: 'WorkbenchCtrl'
				})
				.when('/cpq', {
					redirectTo: '/catalog'
				})
				.when('/cart', {
					templateUrl: baseUrl + '/views/cart.html',
					controller: 'CartController',
					controllerAs: 'CartCtrl'
				})
				.when('/catalog', {
					templateUrl: baseUrl + '/views/catalog.html',
					controller: 'CatalogController',
					controllerAs: 'CatalogCtrl'
				})
				.when('/options/:txnLineNumber', {
					templateUrl: baseUrl + '/views/options.html',
					controller: 'OptionsController',
					controllerAs: 'OptionsCtrl'
				})
				.when('/attributes/:txnLineNumber', {
					templateUrl: baseUrl + '/views/attributes.html',
					controller: 'AttributesController',
					controllerAs: 'AttributesCtrl'
				});
	}]);
})();