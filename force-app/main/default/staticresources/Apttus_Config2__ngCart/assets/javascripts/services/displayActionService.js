(function() {
  angular.module('ngCPQ').service('DisplayActionService', [
    'DisplayActionDataService', function(DisplayActionData) {
      var _filterByActionType;
      this.getDisplayActions = function(displayType, actionType) {
        return DisplayActionData.getDisplayActions(displayType).then(function(res) {
          var actions;
          return actions = _filterByActionType(actionType, res);
        });
      };
      this.setDisplayType = function(state) {
        var activeState, activeTab, type;
        activeState = state.current.name;
        activeTab = state.params.step;
        switch (activeState) {
          case 'configure':
            type = 'attributePageActions';
            break;
          case 'cart':
            type = 'cartPageActions';
            break;
          case 'category':
          case 'search':
          case 'catalog':
            type = 'catalogPageActions';
            break;
          case 'assets':
            type = 'assetPageActions';
            break;
          default:
            type = state.current.name;
        }
        if (activeTab === 'options' && activeState === 'configure') {
          type = 'optionPageActions';
        }

        return type;
      };

      /*
        Private methods
       */
      _filterByActionType = function(actionType, actions) {
        var actionsOfType;
        actionsOfType = actions.filter(function(action) {
          if (action.DisplayAs && action.IsEnabled) {
            return action.DisplayAs.indexOf(actionType) > -1;
          }
        }, actionType);
        return actionsOfType;
      };
      return this;
    }
  ]);

}).call(this);
