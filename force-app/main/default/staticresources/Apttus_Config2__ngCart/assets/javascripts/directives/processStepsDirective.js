(function() {
  var ProcessSteps, processStepsCtrl;

  processStepsCtrl = function(DisplayActionService, $state, $stateParams) {
    var actionsSet, vm;
    vm = this;
    vm.doAction = function(action) {
      return console.log('execute action:', action);
    };
    actionsSet = DisplayActionService.setDisplayType($state);
    return DisplayActionService.getDisplayActions(actionsSet, 'Task').then(function(tasks) {
      return vm.tasks = tasks;
    });
  };

  processStepsCtrl.$inject = ['DisplayActionService', '$state', '$stateParams'];

  ProcessSteps = function(baseUrl) {
    var directive;
    directive = {
      scope: {},
      templateUrl: baseUrl + '/templates/directives/process-steps.html',
      controller: processStepsCtrl,
      controllerAs: 'processSteps',
      bindToController: true
    };
    return directive;
  };

  ProcessSteps.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('processSteps', ProcessSteps);

}).call(this);
