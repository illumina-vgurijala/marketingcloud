;(function() {
    angular.module('incentivesApp').controller('incentiveSummaryController', incentiveSummaryController);

    incentiveSummaryController.$inject = ['incentiveInformationService',
        'incentiveLimitsService',
        'incentiveScopeService',
        'navConfig',
        'appConfig',
        '$window',
        'INCENTIVESTEPCODES',
        'SFDATATYPES'];

    function incentiveSummaryController(incentiveInformationService,
                                        incentiveLimitsService,
                                        incentiveScopeService,
                                        navConfig,
                                        appConfig,
                                        $window,
                                        INCENTIVESTEPCODES,
                                        SFDATATYPES) {
        var vm = this;

        vm.showNav = false;
        vm.stepKeys = INCENTIVESTEPCODES;
        vm.labels = appConfig.labels;
        vm.nsPrefix = appConfig.nsPrefix;

        // initial settings for information component
        vm.incentiveInfoComponentSettings = {};

        vm.navigateTo = function (navStep) {
            if(!navStep.selected) window.top.location.href = navStep.url;
        };

        vm.incentiveInfoComponentSettings.advRelIncSettings = {
            selectedItemsOnlyView: true,
            show: false,
            columns: [],
            results: []
        };

        vm.incentiveInfoComponentSettings.advRelIncSettings.columns.push({
            name: "Name",
            displayName: "Name",
            dataType: "STRING",
            isVisible: true
        });

        vm.incentiveInfoComponentSettings.advRelIncSettings.columns.push({
            name: "Id",
            displayName: "Id",
            dataType: "ID",
            isVisible: false
        });

        vm.incentiveInfoComponentSettings.advRelIncSettings.selectedRecords = [];

        vm.sections = [];

        vm.limitsSettings = {};

        var incentiveScopeSvcCallback = function(result) {
            vm.incentiveScope = {
                dataModel: result.scopeModel
            };
        }

        var incentiveLimitsSvcCallback = function(result) {
            vm.limitsSettings.dataModel = result;

            incentiveScopeService.getIncentiveScope(vm.incentiveID).then(incentiveScopeSvcCallback);
        };

        var informationModelSvcCallback = function(result) {
            vm.incentiveInfoComponentSettings.dataModel = result;

            // handle "cannot combine with these" field since it is derived from a related list
            if(result.relatedIncentivesList) {
                vm.incentiveInfoComponentSettings.advRelIncSettings.selectedRecords = result.relatedIncentivesList;
                vm.incentiveInfoComponentSettings.advRelIncSettings.results = result.relatedIncentivesList;

                // CannotCombinewiththeseIncentives__c is a derived field which is manually created with no namespace
                // so there is no need to prefix with namespace
                var cannotCombFieldIndex = Apttus.utils.elementIndex(
                    result.infoSectionFieldSet,
                    "CannotCombinewiththeseIncentives__c",
                    "apiName");

                if(cannotCombFieldIndex > -1) {
                    vm.incentiveInfoComponentSettings.advRelIncSettings.headerTitle = result.infoSectionFieldSet[cannotCombFieldIndex].labelText;
                }
            }

            // flag all multipick fields as readonly
            for (var i = 0; i < result.infoDetailSectionFieldSet.length; i++) {
                var currentField = result.infoDetailSectionFieldSet[i];

                if(currentField.type == SFDATATYPES.MULTIPICKLIST) {
                    // if there are no options or no selected values then exist
                    if (!currentField.options || !result.incentiveRecord[currentField.apiName]) continue;

                    currentField.readOnly = true;
                }
            }

            // setup navigation now that we have the UseType for the current incentive
            vm.steps = navConfig.stepMap(result.incentiveRecord[appConfig.nsPrefix + 'UseType__c'].value);

            for(var stepName in vm.steps) {
                var currentStep = vm.steps[stepName];

                if(stepName !== INCENTIVESTEPCODES.COUPONS
                    && stepName !== INCENTIVESTEPCODES.SUMMARY) {
                    // setup model details for component animation
                    vm.sections.push({
                        name: stepName,
                        label: currentStep.label,
                        expanded: true
                    });
                }

            }

            incentiveLimitsService.getIncentiveLimits(vm.incentiveID).then(incentiveLimitsSvcCallback);

        };

        vm.loadIncentiveRecord = function(incentiveID) {
            vm.incentiveID = incentiveID;
            // read-only view section
            // get information view model
            incentiveInformationService.getInformationModel(incentiveID).then(informationModelSvcCallback);


        };

        return vm;
    };
})();