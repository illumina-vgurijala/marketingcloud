 ;(function() {
	angular.module('ngCPQ')
		.directive('pageactions', PageAction);
	
	PageAction.$inject = ['baseUrl'];
	PageActionController.$inject = ['$scope', '$location', '$window', 'ConfigurationDataService', 'CartDataService', 'ActionHandlerService'];

	function PageAction(baseUrl) {
		var directive;
		directive = {
			restrict: 'AE',
			templateUrl: baseUrl + '/views/page-actions.html',
			scope: {
				pageName: '@',
				actionLocation: '='
			},
			link: function (scope, elm, attrs) {
				console.log('PageAction directive for pageName, ' + scope.pageName);
			},
			controller: PageActionController,
			controllerAs: 'PageActionCtrl',
			bindToController: true
		};
		return directive;

	}
	
	//handles page action data 
	function PageActionController($scope, $location, $window, ConfigurationDataService, CartDataService, ActionHandlerService) {
		console.log('PageActionController-->');	
			
		var PageActionCtrl = this;
		var pageName = 'optionPageActions';
		
		PageActionCtrl.allPageActions = {};
		PageActionCtrl.currentPageActions = [];
		PageActionCtrl.performAction = performAction;
		
		
		//perform action, invoke server call or redirect url 
		function performAction(actionName) {
			ActionHandlerService.performAction(actionName).then(function(result){
				console.log('redirecting data-->');
				console.log(result);
				
				if (result.targetType == 'state') {
					$location.path(result.path);
					
				} else if (result.targetType == 'page') {
					console.log('window path redirecting to : ' + result.path);
					window.location = result.path;
					
				}
			});
			
		}
		
		/**
		 * Get cart line items, set page info.
		 */
		function loadDisplayActions () {
			ConfigurationDataService.getDisplayActions().then(function(result) {
				PageActionCtrl.allPageActions = result;
				console.log('currentPageActions-->');
				console.log(result[pageName]);

				angular.forEach(result[pageName], function(pageAction, key){
					if (pageAction.IsEnabled == true) {
						PageActionCtrl.currentPageActions.push(pageAction);
					}
				});
				console.log(PageActionCtrl.currentPageActions);
				
			},
			function (error) {
				console.log(error);
			});
		}
		
		var init = function () {
			loadDisplayActions();
			
		};

		//Run initialization
		init();
		
	}
	
})();

	
	