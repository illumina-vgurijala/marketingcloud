;(function() {
    angular.module('incentivesApp').controller('incentiveMilestoneBenefitsController', incentiveMilestoneBenefitsController);

    incentiveMilestoneBenefitsController.$inject = ['incentiveMilestoneBenefitsService'];

    function incentiveMilestoneBenefitsController(incentiveMilestoneBenefitsService) {
        var vm = this;

        var _performingPopup = false;

        var _valueDelimiter = '; ';

        // intial widget settings
        vm.milestoneSearchSettings = {
                    show: false,
                    currentPage: 1,
                    isModal: true,
                    query: {
                        searchTerm: '',
                        agreementId: null
                    },
                    dataKeyColumn: "Id",
                    headerTitle: "Search Milestones",
                    results: null
        };

        var _milestoneSearchCallback = function(result) {
            var index;

            if(_performingPopup) {
                // push selected items from widget to advanced search directive
                var selectedValues = (vm.selectedMilestonesDataStore === null ? [] : vm.selectedMilestonesDataStore.split(_valueDelimiter));

                // clear list of selected records
                vm.milestoneSearchSettings.selectedRecords = [];

                // set selected records list
                for(var i = 0; i < selectedValues.length; i++) {
                    // find selected record
                    index = Apttus.utils.elementIndex(result,
                        selectedValues[i],
                        vm.milestoneSearchSettings.dataKeyColumn);

                    if(index > -1){
                        vm.milestoneSearchSettings.selectedRecords.push(result[index]);
                    }
                }

                vm.milestoneSearchSettings.show = true;
                _performingPopup = false;
            }

            // apply selection to results that were selected from previous view to new result set.
            for(var i = 0; i < result.length; i++) {
                index = Apttus.utils.elementIndex(vm.milestoneSearchSettings.selectedRecords,
                    result[i][vm.milestoneSearchSettings.dataKeyColumn],
                    vm.milestoneSearchSettings.dataKeyColumn);

                // select records which were selected prior
                if(index > -1) {
                    result[i].selected = true;
                } else {
                    result[i].selected = false;
                }
            }

            vm.milestoneSearchSettings.results = result;
        };

        vm.searchMilestones = function() {
            // reset to first page
            vm.milestoneSearchSettings.currentPage = 1;
            vm.advancedSearchSettings.query.searchTerm = "";

            incentiveMilestoneBenefitsService.searchMilestones(vm.milestoneSearchSettings.query)
                .then(_milestoneSearchCallback);
        };

        vm.toggleModal = function() {
            _performingPopup = true;
            vm.searchMilestones();
        };

        vm.showAvailable = function() {
            _performingPopup = true;
            vm.milestoneSearchSettings.view = vm.views.selected;
            vm.searchMilestones();
        };

        vm.advancedSearchClose = function() {
            if(!vm.milestoneSearchSettings.cancelled) {
                updateSearchWidgetWithSelectedRecords(vm.index, vm.milestoneSearchSettings.selectedRecords);
            }
        };

        vm.index = null;

        _performingPopup = false;

        return vm;
    };
})();