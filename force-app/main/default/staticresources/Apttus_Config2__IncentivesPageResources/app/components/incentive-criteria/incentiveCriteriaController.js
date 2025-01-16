;(function() {
    angular.module('incentivesApp').controller('incentiveCriteriaController', incentiveCriteriaController);

    incentiveCriteriaController.$inject = ['incentiveAdvancedSearchService'];

    function incentiveCriteriaController(incentiveAdvancedSearchService) {
        var vm = this;

        var _performingPopup = false;

        var _valueDelimiter = ',';

        // intial widget settings
        vm.advancedSearchSettings = {
                    show: false,
                    currentPage: 1,
                    isModal: true,
                    query: {},
                    headerTitle: "Advanced Search"
                };
        
        var _advancedSearchCallback = function(result) {
            var index;

            if(_performingPopup) {
                // push selected items from widget to advanced search directive
                var selectedValues = (vm.selectedAdvancedDataStore === null ? [] : vm.selectedAdvancedDataStore.split(_valueDelimiter));

                // clear list of selected records
                vm.advancedSearchSettings.selectedRecords = [];
                vm.advancedSearchSettings.singleSelectItem = null;
                vm.advancedSearchSettings.singleSelectItemValue = null;

                if(vm.advancedSearchSettings.isSingleSelect && selectedValues.length == 1) {
                    // find selected record
                    index = Apttus.utils.elementIndex(result.records,
                        selectedValues[0],
                        vm.advancedSearchSettings.dataKeyColumn);

                    if(index > -1){
                        vm.advancedSearchSettings.selectedRecords.push(result.records[index]);
                        vm.advancedSearchSettings.singleSelectItem = result.records[index];
                        vm.advancedSearchSettings.singleSelectItemValue = result.records[index][vm.advancedSearchSettings.dataKeyColumn];
                    }
                } else {
                    // set selected records list
                    for(var i = 0; i < selectedValues.length; i++) {
                        // find selected record
                        index = Apttus.utils.elementIndex(result.records,
                            selectedValues[i],
                            vm.advancedSearchSettings.dataKeyColumn);

                        if(index > -1){
                            vm.advancedSearchSettings.selectedRecords.push(result.records[index]);
                        }
                    }
                }

                vm.advancedSearchSettings.show = true;
                _performingPopup = false;
            }

            // apply selection to results that were selected from previous view to new result set.
            for(var i = 0; i < result.records.length; i++) {
                index = Apttus.utils.elementIndex(vm.advancedSearchSettings.selectedRecords,
                    result.records[i][vm.advancedSearchSettings.dataKeyColumn],
                    vm.advancedSearchSettings.dataKeyColumn);

                // select records which were selected prior
                if(index > -1) {
                    result.records[i].selected = true;
                } else {
                    result.records[i].selected = false;
                }
            }

            vm.advancedSearchSettings.results = result.records;
        };

        vm.performSearch = function() {
            // reset to first page
            vm.advancedSearchSettings.currentPage = 1;
            vm.advancedSearchSettings.query.searchTerm = "";
            
            incentiveAdvancedSearchService.advancedSearch(vm.advancedSearchSettings.query)
                .then(_advancedSearchCallback);
        };

        vm.toggleModal = function() {
            _performingPopup = true;
            vm.performSearch();
        };

        vm.showAvailable = function() {
            _performingPopup = true;
            vm.advancedSearchSettings.view = vm.views.selected;
            vm.performSearch();
        };

        // just a place holder for function which is expected to be set from the page
        vm.updateWidgethWithSelectedValues = null;

        vm.advancedSearchClose = function() {
            if(!vm.advancedSearchSettings.cancelled) {
                var selectedRecords = (vm.advancedSearchSettings.isSingleSelect ? 
                    [vm.advancedSearchSettings.singleSelectItem] : 
                    vm.advancedSearchSettings.selectedRecords);

                if(vm.updateWidgethWithSelectedValues != null) {
                    vm.updateWidgethWithSelectedValues(vm.index, 
                        vm.valueFieldName, 
                        vm.labelFieldName, 
                        selectedRecords);
                } else {
                    updateSearchWidgetWithSelectedRecords(vm.index, 
                        vm.valueFieldName, vm.labelFieldName, 
                        selectedRecords);
                }
                
            }
        };

        vm.index = null;
        vm.selectedAdvancedDataStore = null;

        _performingPopup = false;

        return vm;
    };
})();