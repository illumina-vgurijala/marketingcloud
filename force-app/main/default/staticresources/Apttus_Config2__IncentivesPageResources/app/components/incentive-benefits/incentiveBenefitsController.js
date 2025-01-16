;(function() {
    angular.module('incentivesApp').controller('incentiveBenefitsController', incentiveBenefitsController);

    incentiveBenefitsController.$inject = ['incentiveAdvancedSearchService'];

    function incentiveBenefitsController(incentiveAdvancedSearchService) {
        var vm = this;

        var _performingPopup = false;

        var _valueDelimiter = ';';

        // intial widget settings
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
                    // find selected record
                    index = Apttus.utils.elementIndex(result.records,
                        selectedValues[i],
                        vm.advancedSearchSettings.dataKeyColumn);

                    if(index > -1){
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

        vm.advancedSearchClose = function() {
            if(!vm.advancedSearchSettings.cancelled) {
                updateSearchWidgetWithSelectedRecords(vm.rowIndex,
                    vm.colIndex,
                    vm.valueFieldName, 
                    vm.labelFieldName, 
                    vm.advancedSearchSettings.selectedRecords);
            }
        };

        vm.index = null;

        _performingPopup = false;

        return vm;
    };
})();