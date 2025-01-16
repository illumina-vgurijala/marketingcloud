;(function() {
    var defaultSettings = {
        propertyNameDisplay: 'label'
    };

    angular.module('sharedWidgetsApp').directive('picklist', picklistDir);

    picklistDir.$inject = ['appConfig', 'resourceUrls'];

    function picklistDir(appConfig, resourceUrls) {
        return {
            restrict: 'E',
            scope: {
                settings: '='
            },
            templateUrl: resourceUrls.templateBase + '/controls/picklist/picklistView.html',
            controller: function($scope) { },
            compile: picklistDirectiveCompileFunc
        };

        function picklistDirectiveCompileFunc() {
            return {
                pre: function(scope, el, attrs) {
                    scope.settings = angular.merge({}, defaultSettings, scope.settings);
                    scope.labels = appConfig.labels;

                    scope.advSearchSettings = {
                        selectedItemsOnlyView: true,
                        show: false,
                        columns: [
                            {
                                name: "label",
                                displayName: appConfig.labels.name,
                                dataType: "STRING",
                                isVisible: true
                            },
                            {
                                name: "value",
                                displayName: "value",
                                dataType: "STRING",
                                isVisible: false
                            }
                        ],
                        selectedRecords: scope.settings.selectedValues,
                        headerTitle: scope.settings.labelText
                    };

                    scope.showAllSelectedValues = function() {
                        scope.advSearchSettings.show = true;
                    }
                },
                post: function(scope, el) {
                }
            };
        }
    }


})();