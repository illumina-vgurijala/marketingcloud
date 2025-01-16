;(function() {
    var defaultSettings = { };

    angular.module('sharedWidgetsApp').directive('incentiveField', incentiveFieldDir);

    incentiveFieldDir.$inject = ['appConfig', 'resourceUrls', 'SFDATATYPES'];

    function incentiveFieldDir(appConfig, resourceUrls, SFDATATYPES) {
        return {
            restrict: 'E',
            scope: {
                settings: '=',
                id: '@'
            },
            templateUrl: resourceUrls.templateBase + '/incentive-field/incentiveFieldView.html',
            controller: function($scope) { },
            compile: incentiveFieldDirComp
        };

        function incentiveFieldDirComp() {
            return {
                pre: function(scope, el, attrs) {
                    scope.settings = angular.merge({}, defaultSettings, scope.settings);
                    scope.labels = appConfig.labels;
                    scope.dateTypes = SFDATATYPES;

                    scope.showSelectedIncentives = function() {
                        scope.settings.advSearch.show = true;
                    }
                },
                post: function(scope, el) {
                }
            };
        }
    }


})();