 ;(function() {
	 //option group directive
	angular.module('ngCPQ').directive('optiongroup', OptionGroup);
	OptionGroup.$inject = ['baseUrl'];
	function OptionGroup(baseUrl) {
		var directive;
		directive = {
			restrict: 'AE',
			scope: {
				group1: '=',
				level: '=',
				ctrl: '=',
			},
			link: function (scope, elm, attrs) {
	             console.log('invoking option group for, ' + scope.group1.label);
	            
	        },
			templateUrl: baseUrl + '/views/option-group.html'
		};
		return directive;

	}
	
	//sub group directive
	angular.module('ngCPQ').directive('subgroup', SubGroup);
	function SubGroup($compile) {
		var directive;
		directive = {
			restrict: 'AE',
			scope: {
			  group2: '=',
			  level: '=',
			  parentLine: '=',
			  ctrl: '='
			},
			link: function (scope, elm, attrs) {
				console.log(scope.group2);
				if ((angular.isDefined(scope.group2.childGroups)) && (scope.group2.childGroups.length > 0)) {
	            	var children = $compile('<optiongroup group1="group2" level="level+1" parentLine="parentLine" ctrl="ctrl"></optiongroup>')(scope);
	                elm.append(children);
				} 
            }
		};
		return directive;      
	}
	
	//option item directive
	angular.module('ngCPQ').directive('optionitems', OptionItems);
	function OptionItems(baseUrl) {
		var directive;
		directive = {
			restrict: 'AE',
			scope: {
				group3: '=',
				level: '=',
				parentLine: '=',
				ctrl: '='
			},
			templateUrl: baseUrl + '/views/option-items.html'
		};
		return directive;
	
	}
	
	//option item directive
	angular.module('ngCPQ').directive('optionitem', OptionItem);
	function OptionItem(baseUrl) {
		var directive;
		directive = {
			restrict: 'AE',
			scope: {
				option: '=',
				level: '=',
				parentLine: '=',
				ctrl: '='
			},
			link: function (scope, elm, attrs) {
				//console.log('option item link function ' + scope.option.label);
	            scope.lineItemDO = scope.ctrl.getLineItemDO(scope.parentLine, scope.option);
	            scope.lineItemSO = scope.lineItemDO.lineItemSO;
	        },
			templateUrl: baseUrl + '/views/option-item.html'
		};
		return directive;
	
	}
		
})();

	