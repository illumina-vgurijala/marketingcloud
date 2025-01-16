;(function() {
    var defaultSettings = { };

    angular.module('sharedWidgetsApp').directive('incentiveLimits', incentiveLimitsDir);

    incentiveLimitsDir.$inject = ['appConfig',
        'resourceUrls',
        'SFDATATYPES',
        'INCENTIVE',
        'CUSTOMFIELDNAMES'];

    function incentiveLimitsDir(appConfig,
                                resourceUrls,
                                SFDATATYPES,
                                INCENTIVE,
                                CUSTOMFIELDNAMES) {
        return {
            restrict: 'E',
            scope: {
                settings: '=',
                uniqueId: '@'
            },
            templateUrl: resourceUrls.templateBase + '/incentive-limits/incentiveLimitsView.html',
            controller: function($scope) { },
            compile: incentiveLimitsDirCompile
        };

        function incentiveLimitsDirCompile() {
            return {
                pre: function(scope, el, attrs) {
                    scope.settings = angular.merge({}, defaultSettings, scope.settings);
                    scope.labels = appConfig.labels;
                    scope.nsPrefix = appConfig.nsPrefix;
                    scope.dateTypes = SFDATATYPES;
                    scope.fieldSettings = {};
                    scope.CONST = INCENTIVE;
                    scope.CUSTOMFIELDNAMES = CUSTOMFIELDNAMES;

                    scope.limit = null;

                    scope.setLimit = function(limit) {
                        scope.limit = limit;
                    }

                    var _locateOverrideField = function(apiName, fieldOverrides) {
                        for(var i = 0; i < fieldOverrides.length; i++) {
                            if(fieldOverrides[i].apiName === apiName) {
                                return fieldOverrides[i];
                            }
                        }

                        return null;
                    };

                    // locate specified field schema info and set
                    scope.setupFieldSettings = function(partialApiName, currentIncentiveLimit) {
                        for(var i = 0; i < scope.settings.dataModel.limitFields.length; i++) {
                            if(scope.settings.dataModel.limitFields[i].apiName.indexOf(partialApiName) > -1) {
                                scope.fieldSettings.field = scope.settings.dataModel.limitFields[i];
                                scope.fieldSettings.field.value = currentIncentiveLimit.incentiveLimit[scope.fieldSettings.field.apiName];
                                scope.fieldSettings.field.id = "lmtFld" + scope.fieldSettings.field.apiName;
                                var override = _locateOverrideField(scope.fieldSettings.field.apiName,currentIncentiveLimit.fieldOverrides);

                                if(override !== null) {
                                    // override field options
                                    scope.fieldSettings.field.options = override.options;
                                }

                                return true;
                            }
                        }
                    };

                    // locate specified field and return its display label text
                    scope.getFieldLabel = function(partialApiName) {
                        for(var i = 0; i < scope.settings.dataModel.limitFields.length; i++) {
                            if(scope.settings.dataModel.limitFields[i].apiName.indexOf(partialApiName) > -1) {
                                return scope.settings.dataModel.limitFields[i].labelText;
                            }
                        }
                    }
                },
                post: function(scope, el) {
                }
            };
        }
    }


})();