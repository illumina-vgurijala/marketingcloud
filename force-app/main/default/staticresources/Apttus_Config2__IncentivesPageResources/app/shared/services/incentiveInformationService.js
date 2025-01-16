;(function() {
    angular.module('incentivesApp').service('incentiveInformationService', incentiveInformationService);

    incentiveInformationService.$inject = ['aptBase.RemoteService', 'SFDATATYPES', 'appConfig'];

    function incentiveInformationService(RemoteService, SFDATATYPES, appConfig) {

        var service = this;

        service.getInformationModel = getInformationModel;

        function getInformationModel(query) {
            return RemoteService.getIncentiveInfo(query).then(function(result) {
                var useTypeFieldFound,
                    useTypeFieldApiName = appConfig.nsPrefix + 'UseType__c';

                for (var i = 0; i < result.infoSectionFieldSet.length; i++) {
                    var currentField = result.infoSectionFieldSet[i];
                    
                    if(!useTypeFieldFound && currentField.apiName == useTypeFieldApiName) useTypeFieldFound = true;

                    _processDescribeFields(currentField, result.incentiveRecord);
                }

                for (var i = 0; i < result.infoDetailSectionFieldSet.length; i++) {
                    var currentField = result.infoDetailSectionFieldSet[i];
                    _processDescribeFields(currentField, result.incentiveRecord);
                }

                if(!useTypeFieldFound) {
                    _processDescribeFields(result.useTypeField, result.incentiveRecord);
                }

                return result;
            });
        }

        function _processDescribeFields(fieldDescibeInfo, dataObj) {
            if(fieldDescibeInfo.type == SFDATATYPES.REFERENCE || fieldDescibeInfo.type == SFDATATYPES.PICKLIST) {
                // if there are no options or no selected values then exist
                if(!fieldDescibeInfo.options || !dataObj[fieldDescibeInfo.apiName]) return;

                var selectedOptionIndex = Apttus.utils.elementIndex(
                    fieldDescibeInfo.options,
                    dataObj[fieldDescibeInfo.apiName],
                    "value");

                if(selectedOptionIndex > -1) {
                    dataObj[fieldDescibeInfo.apiName] = fieldDescibeInfo.options[selectedOptionIndex];
                }
            } else if(fieldDescibeInfo.type == SFDATATYPES.MULTIPICKLIST) {
                // if there are no options or no selected values then exist
                if(!fieldDescibeInfo.options || !dataObj[fieldDescibeInfo.apiName]) return;

                // split multipick values on standard ';' character used by SF for multipick fields
                var selectedValues = dataObj[fieldDescibeInfo.apiName].split(";");
                var selectedOptions = [];
                // iterate over selected values
                for(var i = 0; i < selectedValues.length; i++) {
                    var selectedOptionIndex = Apttus.utils.elementIndex(
                        fieldDescibeInfo.options,
                        selectedValues[i],
                        "value");

                    // if the selected options was found then add to selected list
                    if(selectedOptionIndex > -1) {
                        selectedOptions.push(fieldDescibeInfo.options[selectedOptionIndex]);
                    }
                }

                // set selected list of options
                fieldDescibeInfo.selectedValues = selectedOptions;

            }
        }
    }
})();