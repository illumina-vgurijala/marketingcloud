;(function() {
    var defaultSettings = { };

    angular.module('sharedWidgetsApp').directive('incentiveInformation', incentiveInformationDir);

    incentiveInformationDir.$inject = ['appConfig', 'resourceUrls', 'SFDATATYPES', '$sce'];

    function incentiveInformationDir(appConfig, resourceUrls, SFDATATYPES, $sce) {
        return {
            restrict: 'E',
            scope: {
                settings: '=',
                uniqueId: '@',
                search: '&',
                views: '='
            },
            templateUrl: resourceUrls.templateBase + '/incentive-information/incentiveInformationView.html',
            controller: function($scope) { },
            compile: incentiveInformationCompileFunc
        };

        function incentiveInformationCompileFunc() {
            return {
                pre: function(scope, el, attrs) {
                    scope.settings = angular.merge({}, defaultSettings, scope.settings);
                    scope.labels = appConfig.labels;
                    scope.sfDataTypes = SFDATATYPES;
                    scope.customFieldSection = {
                        expanded: true
                    };

                    scope.isOtherDataType = function(dataType) {
                        // loop through data types
                        for (field in SFDATATYPES) {
                            if(SFDATATYPES[field] == dataType) {
                                return false
                            }
                        }

                        return true;

                    };

                    scope.showSelectedIncentives = function() {
                        scope.settings.advRelIncSettings.show = true;
                    };

                    scope.StopProcessingMoreIncentivesExists = function() {
                        var index = Apttus.utils.elementIndex(
                            scope.settings.dataModel.infoSectionFieldSet,
                            appConfig.nsPrefix + 'StopProcessingMoreIncentives__c',
                            "apiName");
                        return (index > -1);
                    };

                    scope.renderHtml = function(html_code) {
                        return $sce.trustAsHtml(html_code);
                    };
                },
                post: function(scope, el) {
                }
            };
        }
    }


})();