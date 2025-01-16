;(function() {
    var _value = "value",
        _delimiter = ";",
        _getOverride = function(fieldOverrides, apiName) {
            for (var i = 0; i < fieldOverrides.length; i++) {
                if (fieldOverrides[i].apiName === apiName) {
                    return fieldOverrides[i];
                }
            }

            return undefined;
        };

    angular.module('incentivesApp').service('commonMethodsService', commonMethodsService);

    commonMethodsService.$inject = ['SFDATATYPES', 'lodash'];

    function commonMethodsService(SFDATATYPES, _) {

        var service = this;

        service.isOptionsListField = isOptionsListField;

        function isOptionsListField(fieldDescibeInfo) {
            return (fieldDescibeInfo.type == SFDATATYPES.REFERENCE
                    || fieldDescibeInfo.type == SFDATATYPES.PICKLIST)
                    || (fieldDescibeInfo.type == SFDATATYPES.MULTIPICKLIST);
        }

        service.findOption = findOption;

        function findOption(options, searchValue) {
            var selectedOptionIndex = Apttus.utils.elementIndex(
                options,
                searchValue,
                _value);

            if(selectedOptionIndex > -1) {
                return options[selectedOptionIndex];
            }

            return null;
        };

        service.getSelectedOptions = getSelectedOptions;

        /**
         * based on field data type will locate selected value(s) from list of available name/value pair options
         * and return a list of selected option(s)
         * @param fieldDescibeInfo field describe wrapper with schema details
         * @param dataObj object containing values referenced by apiName property from fieldDescibeInfo parameter
         */
        function getSelectedOptions(fieldDescibeInfo, dataObj) {
            var returnOptions = [{
                label: dataObj[fieldDescibeInfo.apiName],
                value: dataObj[fieldDescibeInfo.apiName]
            }];

            if((fieldDescibeInfo.type == SFDATATYPES.REFERENCE || fieldDescibeInfo.type == SFDATATYPES.PICKLIST)
                && fieldDescibeInfo.options) {
                var option = findOption(fieldDescibeInfo.options, dataObj[fieldDescibeInfo.apiName]);
                if(option !== null) {
                    returnOptions = [option];
                }
            } else if(fieldDescibeInfo.type == SFDATATYPES.MULTIPICKLIST
                && fieldDescibeInfo.options) {
                // split multipick values on standard ';' character used by SF for multipick fields
                let selectedValues = [];
                if (dataObj[fieldDescibeInfo.apiName]) {
                    selectedValues = dataObj[fieldDescibeInfo.apiName].split(_delimiter);
                }
                var selectedOptions = [];

                // iterate over selected values
                for (var i = 0; i < selectedValues.length; i++) {
                    var option = findOption(fieldDescibeInfo.options, selectedValues[i]);

                    if (option !== null) {
                        // add to selected list
                        selectedOptions.push(option);
                    }
                }

                if (selectedOptions.length > 0) {
                    // set selected list of options
                    returnOptions = selectedOptions;
                }

            }

            return returnOptions;
        }

        service.processAdvancedSearchResults = processAdvancedSearchResults;

        function processAdvancedSearchResults(advSearchSettings,
                     result,
                     selectedValues,
                     selectedValuesDelimiter,
                     showAdvancedSearch,
                     selectedListDetails) {
            var index;

            if (showAdvancedSearch) {
                // push selected items from widget to advanced search directive
                var selectedValues = (selectedValues === null ? [] : selectedValues.split(selectedValuesDelimiter));

                advSearchSettings.singleSelectItem = null;
                advSearchSettings.singleSelectItemValue = null;

                if (advSearchSettings.isSingleSelect && selectedValues.length == 1 && advSearchSettings.selectedRecords.length === 0) {
                    // find selected record
                    index = Apttus.utils.elementIndex(result.records,
                        selectedValues[0],
                        advSearchSettings.dataKeyColumn);

                    if (index > -1) {
                        advSearchSettings.selectedRecords.push(result.records[index]);
                        advSearchSettings.singleSelectItem = result.records[index];
                        advSearchSettings.singleSelectItemValue = result.records[index][advSearchSettings.dataKeyColumn];
                    }
                } else if (advSearchSettings.selectedRecords.length === 0) {
                    // set selected records list
                    for (var i = 0; i < selectedValues.length; i++) {
                        // find selected record
                        index = Apttus.utils.elementIndex(result.records,
                            selectedValues[i],
                            advSearchSettings.dataKeyColumn);

                        if (index > -1) {
                            advSearchSettings.selectedRecords.push(result.records[index]);
                        } else if (selectedListDetails && selectedListDetails.length){
                            advSearchSettings.selectedRecords.push(selectedListDetails[i]);
                        }
                    }
                }
                
                if (!advSearchSettings.show) {
                    // update selected records array if modified without opening advanced search dialog
                    advSearchSettings.selectedRecords = _.filter(advSearchSettings.selectedRecords, function(selectedRecord) {
                        return selectedValues.indexOf(selectedRecord[advSearchSettings.dataKeyColumn]) > -1;
                    });
                }
                advSearchSettings.show = true;
            }

            // apply selection to results that were selected from previous view to new result set.
            for (var i = 0; i < result.records.length; i++) {
                index = Apttus.utils.elementIndex(advSearchSettings.selectedRecords,
                    result.records[i][advSearchSettings.dataKeyColumn],
                    advSearchSettings.dataKeyColumn);

                // select records which were selected prior
                if (index > -1) {
                    result.records[i].selected = true;
                } else {
                    result.records[i].selected = false;
                }
            }
            if(advSearchSettings.selectedRecords.length) {
                for (var i = 0; i < advSearchSettings.selectedRecords.length; i++) {              
                    advSearchSettings.selectedRecords[i].selected = true;
                }
            }

            advSearchSettings.results = result.records;
        }

        service.configureFieldSettings = configureFieldSettings;

        /**
         * given field schema info and corresponding data object will generate a field settings object
         * which can be passed to incentive-field directove for consumption.
         * @param fieldInfo
         * @param record
         * @param idPrefix
         * @returns {{field: {id: null, value: null}}}
         */
        function configureFieldSettings(fieldInfo, value, idPrefix) {
            var fieldSettings = {
                field: {
                    id: idPrefix + fieldInfo.apiName,
                    value: value
                }
            };

            fieldSettings.field = angular.merge({}, fieldInfo, fieldSettings.field);

            if (fieldInfo.type == SFDATATYPES.MULTIPICKLIST) {
                fieldSettings.advSearch = {
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
                    sort: {
                        columnName: "Name",
                        ascending: true
                    }
                };
            }

            return fieldSettings;
        }

        service.configureFieldAndValue = configureFieldAndValue;

        function configureFieldAndValue(fieldDescibeInfo, dataObj, idPrefix, fieldOverrides) {

            if (fieldOverrides) {
                // check for overrides and apply
                var fieldOverride = _getOverride(fieldOverrides, fieldDescibeInfo.apiName)
                if (fieldOverride) {
                    fieldDescibeInfo.options = fieldOverride.options;
                    for (field in fieldOverride) {
                        if (field !== "options") {
                            fieldDescibeInfo[field] = fieldOverride[field];
                        }

                    }
                }
            }


            var recordValue;

            if (fieldDescibeInfo.type == SFDATATYPES.PICKLIST || fieldDescibeInfo.type == SFDATATYPES.RADIOPICKLIST) {
                var selectedOptions = findOption(fieldDescibeInfo.options, dataObj[fieldDescibeInfo.apiName]);
                if(selectedOptions) {
                    recordValue = selectedOptions;
                }

            } else if (isOptionsListField(fieldDescibeInfo)) {
                // get selected options and overwrite value from server
                recordValue = getSelectedOptions(fieldDescibeInfo, dataObj);
            } else {
                recordValue = dataObj[fieldDescibeInfo.apiName];
            }

            return configureFieldSettings(fieldDescibeInfo,
                recordValue,
                idPrefix);
        }
    }
})();