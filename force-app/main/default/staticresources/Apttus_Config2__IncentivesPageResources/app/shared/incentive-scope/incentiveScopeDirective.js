;(function() {
    var defaultSettings = { };

    angular.module('sharedWidgetsApp').directive('incentiveScope', incentiveScope);

    incentiveScope.$inject = ['appConfig', 'resourceUrls', 'SFDATATYPES'];

    function incentiveScope(appConfig, resourceUrls, SFDATATYPES) {
        return {
            restrict: 'E',
            scope: {
                settings: '=',
                uniqueId: '@'
            },
            templateUrl: resourceUrls.templateBase + '/incentive-scope/incentiveScopeView.html',
            controller: function($scope) { },
            compile: incentiveScopeCompFunct
        };

        function incentiveScopeCompFunct() {
            return {
                pre: function(scope, el, attrs) {
                    scope.settings = angular.merge({}, defaultSettings, scope.settings);
                    scope.labels = appConfig.labels;
                    scope.nsPrefix = appConfig.nsPrefix;
                    scope.dateTypes = SFDATATYPES;

                    scope.showSelectedIncentives = function() {
                        scope.settings.advRelIncSettings.show = true;
                    };
                },
                post: function(scope, el) {
                }
            };
        }
    }


})();