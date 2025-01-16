;(function() {
    angular.module('incentivesApp').controller('incentiveNavigationController', incentiveNavigationController);

    incentiveNavigationController.$inject = ['navConfig'];

    function incentiveNavigationController(navConfig) {
        var vm = this;
        return vm;
    };
})();