;(function() {
    angular.module('incentivesApp').service('incentiveScopeService', incentiveScopeService);

    incentiveScopeService.$inject = ['aptBase.RemoteService', 'commonMethodsService', 'SFDATATYPES', 'appConfig', 'ObjectConstants'];

    function incentiveScopeService(RemoteService, commonMethodsService, SFDATATYPES, appConfig, ObjectConstants) {

        var service = this;
        service.getIncentiveScope = getIncentiveScope;
        const nsPrefix = appConfig.nsPrefix;

        function getIncentiveScope(incentiveID) {
            function getIncentiveScopeCallback(result) {
                result.scopeModel = {};

                for (var i = 0; i < result.fieldSet.length; i++) {
                    // handle special case for operator fields. They should be displayed as radio pick lists
                    if(result.fieldSet[i].apiName.indexOf("Oper__c") > -1) {
                        result.fieldSet[i].type = SFDATATYPES.RADIOPICKLIST;
                        if (result.fieldSet[i].apiName === nsPrefix + 'ProductScopeOper__c'
                            && isPromotionBuyX(result.incentive)) {
                            if (result.priceRule) {
                                result.incentive[result.fieldSet[i].apiName] = result.priceRule[`${nsPrefix}ProductCriteriaOper__c`];
                            }
                        } else {
                            result.fieldSet[i].options = result.scopeOperators;
                        }
                    }

                    if (result.fieldSet[i].type == SFDATATYPES.PICKLIST || result.fieldSet[i].type == SFDATATYPES.RADIOPICKLIST) {
                        var selectedOptions = commonMethodsService.findOption(result.fieldSet[i].options, result.incentive[result.fieldSet[i].apiName]);
                        if(selectedOptions) {
                            result.incentive[result.fieldSet[i].apiName] = selectedOptions;
                        }

                    } else if(commonMethodsService.isOptionsListField(result.fieldSet[i])) {
                        // handle special case where value is same as label and there is no name/value pair mapping involved
                        if(result.fieldSet[i].apiName.indexOf("ProductFamilyScope__c") > -1
                            || result.fieldSet[i].apiName.indexOf("RegionScope__c") > -1
                            || result.fieldSet[i].apiName.indexOf("CountryScope__c") > -1
                            || result.fieldSet[i].apiName.indexOf("AccountTypeScope__c") > -1) {
                            var values = result.incentive[result.fieldSet[i].apiName].split(';');
                            var selectedFamilies = [];
                            for(var c = 0; c < values.length; c++) {
                                selectedFamilies.push({
                                    label: values[c],
                                    value: values[c]
                                });
                            }

                            result.incentive[result.fieldSet[i].apiName] = selectedFamilies;
                        } else {
                        // get selected options and overwrite value from server
                        result.incentive[result.fieldSet[i].apiName] = commonMethodsService.getSelectedOptions(result.fieldSet[i], result.incentive);
                    }

                }

                    var fieldSettings = {
                        field: result.fieldSet[i]
                    };

                    fieldSettings.field.value = result.incentive[result.fieldSet[i].apiName];
                    fieldSettings.field.id = "scp" + fieldSettings.field.apiName;

                    if(result.fieldSet[i].type == SFDATATYPES.MULTIPICKLIST) {
                        fieldSettings.advSearch = {
                            headerTitle: result.fieldSet[i].labelText,
                            selectedItemsOnlyView: true,
                            show: false,
                            columns: [{
                                name: "label",
                                displayName: "Name",
                                dataType: "STRING",
                                isVisible: true
                            },
                            {
                                name: "value",
                                displayName: "Id",
                                dataType: "ID",
                                isVisible: false
                            }],
                            selectedRecords: result.incentive[result.fieldSet[i].apiName],
                            results: result.incentive[result.fieldSet[i].apiName],
                            sort: {
                                columnName: "Name",
                                ascending: true
                            }
                        };
                    }

                    result.scopeModel[result.fieldSet[i].apiName] = fieldSettings;
                }

                return result;
            }

            return RemoteService.getIncentiveScope(incentiveID).then(getIncentiveScopeCallback);
        }

        function isPromotionBuyX(incentive) {
            return incentive[nsPrefix + 'UseType__c'] === ObjectConstants.Incentive.USETYPE_PROMOTION
                && (incentive[nsPrefix + 'ApplicationMethod__c'] === ObjectConstants.Incentive.APPLICATION_METHOD_BUYXGETY
                    || incentive[nsPrefix + 'ApplicationMethod__c'] === ObjectConstants.Incentive.APPLICATION_METHOD_BUYXGETX);
        }
    }
})();