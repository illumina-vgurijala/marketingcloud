(function() {
  var DisplayActions, displayActionsCtrl;

  displayActionsCtrl = function(CartService, DisplayActionService, ActionHandlerService, $state, $stateParams) {
    var actionsSet, vm;
    vm = this;
    vm.doAction = function(action) {
      // return console.log('execute action:', action);
      ActionHandlerService.performAction(action).then(function (response) {
        if (!response) {
          return;
        
        }
        if (response.targetType == "state") {
          $state.go(response.path);

        } else if (response.targetType == "page") {
          window.location = response.path;

        }
      });

    };
    actionsSet = DisplayActionService.setDisplayType($state);
    return DisplayActionService.getDisplayActions(actionsSet, 'Action').then(function(actions) {
      return vm.actions = actions;
    });
  };

  displayActionsCtrl.$inject = ['CartService', 'DisplayActionService', 'ActionHandlerService', '$state', '$stateParams'];

  DisplayActions = function(baseUrl) {
    var directive;
    directive = {
      scope: {},
      templateUrl: baseUrl + '/templates/directives/display-actions-block.html',
      controller: displayActionsCtrl,
      controllerAs: 'displayAction',
      bindToController: true
    };
    return directive;
  };

  DisplayActions.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('displayActions', DisplayActions);

}).call(this);
