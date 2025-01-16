;(function() {
    angular.module('incentivesApp').service('incentiveMilestoneBenefitsService', incentiveMilestoneBenefitsService);

    incentiveMilestoneBenefitsService.$inject = ['aptBase.RemoteService'];

    function incentiveMilestoneBenefitsService(RemoteService) {

        var service = this;

        service.searchMilestones = searchMilestones;

        /**
         * returns list milestones
         */
        function searchMilestones(query) {
            return RemoteService.searchMilestones(query.searchTerm, query.agreementId).then(function(result) {
                return result;
            });
        }
    };

})();