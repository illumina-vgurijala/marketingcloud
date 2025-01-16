;(function() {
    angular.module('incentivesApp').service('incentiveAdvancedSearchService', incentiveAdvancedSearchService);

    incentiveAdvancedSearchService.$inject = ['aptBase.RemoteService'];

    function incentiveAdvancedSearchService(RemoteService) {

        var service = this;

        service.advancedSearch = advancedSearch;

        /**
         * returns list milestones
         */
        function advancedSearch(query) {
            return RemoteService.advancedSearch(query).then(function(result) {
                return result;
            });
        }


        service.searchProducts = searchProducts;

        /**
         * returns list products
         */
        function searchProducts(query) {
            return RemoteService.searchProducts(
                    query.searchTerm,
                    query.priceListVal,
                    query.priceListScopeOper,
                    query.productFamilyList,
                    query.productFamilyScopeOper
                ).then(function(result) {
                return result;
            });
        }


        service.searchAccounts = searchAccounts;

        /**
         * returns list products
         */
        function searchAccounts(query) {
            return RemoteService.searchAccounts(query).then(function(result) {
                return result;
            });
        }
    };

})();