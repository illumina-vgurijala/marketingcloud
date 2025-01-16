;(function() {
    angular.module('incentivesApp').controller('incentiveInformationController', incentiveInformationController);

    incentiveInformationController.$inject = ['incentiveAdvancedSearchService', 'commonMethodsService'];

    function incentiveInformationController(incentiveAdvancedSearchService, commonMethodsService) {
        var vm = this;

        var _performingPopup = false;

        var _valueDelimiter = '; ';

        // initial widget settings
        vm.advancedSearchSettings = {
                    show: false,
                    currentPage: 1,
                    isModal: true,
                    query: {},
                    headerTitle: "Advanced Search",
                    results: null
        };

        var _advancedSearchCallback = function(result) {
            var index;

            if(_performingPopup) {
                // push selected items from widget to advanced search directive
                var selectedValues = (vm.selectedAdvancedDataStore === null ? [] : vm.selectedAdvancedDataStore.split(_valueDelimiter));

                // clear list of selected records
                vm.advancedSearchSettings.selectedRecords = [];

                // set selected records list
                for(var i = 0; i < selectedValues.length; i++) {
                    // find selected record index
                    index = Apttus.utils.elementIndex(result.records,
                        selectedValues[i],
                        vm.advancedSearchSettings.dataKeyColumn);

                    if(index > -1) {
                        // if index found for record add to list of selected records
                        vm.advancedSearchSettings.selectedRecords.push(result.records[index]);
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
            
            if (vm.startDate != null) {
                vm.advancedSearchSettings.query.filters[3] = 
                    iInfoDateRangeFilter.replace(/\{0\}/g, vm.startDate);
            }

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
            if(!vm.advancedSearchSettings.cancelled) { // did user click close?
                vm.updateWidgethWithSelectedValues(vm.valueFieldName, vm.labelFieldName, vm.advancedSearchSettings.selectedRecords);
            }
        };

///Additional Fields
        vm.toggleFieldsModal = function(index) {
            vm.performFieldsSearch(index);
        };

        vm.showFieldsAvailable = function(index) {
            vm.infoSectionAdvancedSearchSettings[index].view = vm.views.selected;
            vm.performFieldsSearch(index);

        };

        vm.performFieldsSearch = function(index) {
            // reset to first page
            vm.infoSectionAdvancedSearchSettings[index].currentPage = 1;
            vm.infoSectionAdvancedSearchSettings[index].query.searchTerm = "";
            var _fieldSearchCallback = function(result) {
                commonMethodsService.processAdvancedSearchResults(vm.infoSectionAdvancedSearchSettings[index],
                         {records: result.records},
                         vm.infoSectionAdvancedSearchSettings[index].selectedRecordValue,
                         null,
                         true);
            };

            incentiveAdvancedSearchService.advancedSearch(vm.infoSectionAdvancedSearchSettings[index].query)
                .then(_fieldSearchCallback);
        };

        vm.advancedFieldSearchClose = function(index) {
            if(!vm.infoSectionAdvancedSearchSettings[index].cancelled) { // did user click close?
                vm.infoSectionAdvancedSearchSettings[index].updateWidgethWithSelectedFieldValues(vm.valueFieldName, vm.labelFieldName, vm.infoSectionAdvancedSearchSettings[index].selectedRecords);
            }
        };

        vm.selectedAdvancedDataStore = null;

        _performingPopup = false;

        return vm;
    };
})();