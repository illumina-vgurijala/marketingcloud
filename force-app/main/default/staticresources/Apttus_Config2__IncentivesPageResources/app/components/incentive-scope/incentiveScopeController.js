;(function() {
    angular.module('incentivesApp').controller('incentiveScopeController', incentiveScopeController);

    incentiveScopeController.$inject = ['incentiveAdvancedSearchService', 'commonMethodsService'];

    function incentiveScopeController(incentiveAdvancedSearchService, commonMethodsService) {
        var vm = this;

        var _valueDelimiter = '; ';

        /**
         * product advanced search
         */

        // initial widget settings
        vm.productAsSettings = {
                    show: false,
                    currentPage: 1,
                    isModal: true,
                    query: {},
                    results: null,
                    dataKeyColumn: "Id",
                    useServerSideQuery: true
        };

        var _productSearchCallback = function(result) {
            commonMethodsService.processAdvancedSearchResults(vm.productAsSettings,
                     {records: result},
                     vm.selectedProductsList,
                     _valueDelimiter,
                     true,
                     vm.selectedProductsDetails);

        };

        var _performProductSearch = function(advancedSearchQuery) {
            // reset to first page
            vm.productAsSettings.currentPage = 1;
            if (angular.isDefined(advancedSearchQuery)) {
                vm.productAsSettings.query.searchTerm = advancedSearchQuery.searchTerm;
            }
            incentiveAdvancedSearchService.searchProducts(vm.productAsSettings.query)
                .then(_productSearchCallback);
        };

        vm.toggleProductSearch = function() {
            _performProductSearch();
        };

        vm.showAvailableProducts = function() {
            vm.productAsSettings.view = vm.views.selected;
            _performProductSearch();
            
        };

        vm.onProductSearchClose = function() {
            if(!vm.productAsSettings.cancelled && vm.updateProductWidget) { // did user click close?
                vm.updateProductWidget(vm.valueFieldName, vm.labelFieldName, vm.productAsSettings.selectedRecords);
            }
        };

        vm.productAsSettings.searchMethod = _performProductSearch;
        /**
         * Account advanced search
         */

        // initial widget settings
        vm.accountAsSettings = {
                    show: false,
                    currentPage: 1,
                    isModal: true,
                    query: {},
                    results: null,
                    dataKeyColumn: "Id",
                    useServerSideQuery: true
        };

        var _accountSearchCallback = function(result) {
            commonMethodsService.processAdvancedSearchResults(vm.accountAsSettings,
                     {records: result},
                     vm.selectedAccountsList,
                     _valueDelimiter,
                     true,
                     vm.selectedAccountsDetails
                     );

        };

        var _performAccountSearch = function(advancedSearchQuery) {
            var newObj = {};

            // reset to first page
            vm.accountAsSettings.currentPage = 1;

            for(var propt in vm.accountAsSettings.query){
                if(propt != 'accountTypeRef') {
                    newObj[propt] = vm.accountAsSettings.query[propt];
                }
            }

            newObj.accountType = vm.accountAsSettings.query.accountTypeRef.val();
            if (angular.isDefined(advancedSearchQuery)) {
                newObj.searchTerm = advancedSearchQuery.searchTerm;
            }
            incentiveAdvancedSearchService.searchAccounts(newObj).then(_accountSearchCallback);
        };

        vm.toggleAccountSearch = function() {
            vm.accountAsSettings.query.searchTerm = "";
            _performAccountSearch();
        };

        vm.showAvailableAccounts = function() {
            vm.accountAsSettings.view = vm.views.selected;
            _performAccountSearch();
            
        };

        vm.onAccountSearchClose = function() {
            if(!vm.accountAsSettings.cancelled && vm.updateAccountWidget) { // did user click close?
                vm.updateAccountWidget(vm.valueFieldName, vm.labelFieldName, vm.accountAsSettings.selectedRecords);
            }
        };


        vm.accountAsSettings.searchMethod = _performAccountSearch;
        return vm;
    };
})();