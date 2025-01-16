;(function() {
    angular.module('incentivesApp').service('incentiveLimitsService', incentiveLimitsService);

    incentiveLimitsService.$inject = ['aptBase.RemoteService',
        'SFDATATYPES',
        'appConfig',
        'commonMethodsService',
        'CUSTOMFIELDNAMES'];

    function incentiveLimitsService(RemoteService, SFDATATYPES, appConfig, commonMethodsService, CUSTOMFIELDNAMES) {

        var service = this;

        service.getIncentiveLimits = getIncentiveLimits;

        function getIncentiveLimits(incentiveID) {
            function getIncentiveLimitsCallback(result) {
                for(var c = 0; c < result.limitRecords.length; c++) {
                    for (var i = 0; i < result.limitFields.length; i++) {
                        var currentApiName = result.limitFields[i].apiName;

                        // special default option for LimitAppliesToValueSource__c field
                        if(currentApiName === appConfig.nsPrefix + "LimitAppliesToValueSource__c"
                            && result.limitRecords[c].incentiveLimit[currentApiName] === undefined) {
                            //result.limitRecords[c].incentiveLimit[currentApiName] = result.limitFields[i].options[0];

                            result.limitRecords[c].incentiveLimit[currentApiName] = commonMethodsService.configureFieldSettings(result.limitFields[i],
                                result.limitFields[i].options[0],
                                "lmt");
                            continue;
                        } else if(currentApiName === CUSTOMFIELDNAMES.MAXLIMITVALUETYPEFIELDNAME) {
                            // MaxLimitValueType field is added manually based on field set settings and will not be namespaced
                            var limitValueTypeOption = (result.limitRecords[c].incentiveLimit[appConfig.nsPrefix + 'LimitValueSource__c'] === undefined ? 0 : 1);
                            result.limitRecords[c].incentiveLimit[currentApiName] = commonMethodsService.configureFieldSettings(result.limitFields[i],
                                result.limitFields[i].options[limitValueTypeOption],
                                "lmt");
                            continue;
                        }

                        var fieldSettings = commonMethodsService.configureFieldAndValue(
                            result.limitFields[i],
                            result.limitRecords[c].incentiveLimit,
                            "lmt",
                            result.limitRecords[c].fieldOverrides);

                        result.limitRecords[c].incentiveLimit[currentApiName] = fieldSettings;
                    }
                }
                

                return result;
            }

            return RemoteService.getIncentiveLimits(incentiveID).then(getIncentiveLimitsCallback);
        }
    }
})();