(function() {
  angular.module('ngCPQ').directive('searchedTerm', [
    'baseUrl', '$state', '$stateParams', function(baseUrl, $state, $stateParams) {
      return {
        restrict: 'AE',
        scope: {},
        controller: function() {
          var clearSearchedTerm, findProducts;
          findProducts = function() {
            return $state.go('search', {
              term: encodeURIComponent(this.term)
            });
          };
          clearSearchedTerm = function() {
            this.term = '';
            return this.hasSearchedTerm = false;
          };
          this.hasSearchedTerm = false;
          this.term = decodeURIComponent($stateParams.term);
          this.clearSearchedTerm = clearSearchedTerm;
          this.findProducts = findProducts;
          if (this.term) {
            return this.hasSearchedTerm = true;
          }
        },
        controllerAs: 'searchedTerm',
        bindToController: true,
        templateUrl: baseUrl + '/templates/directives/searched-term.html',
        link: function(scope, elem, attrs) {
          var button, buttons, i, input, len, results;
          input = elem.find('input');
          buttons = elem.find('button');
          input.on('keypress', function(e) {
            var key;
            key = e.which || e.keyCode;
            if (key === 13) {
              return $state.go('search', {
                term: encodeURIComponent(input[0].value)
              });
            }
          });
          results = [];
          for (i = 0, len = buttons.length; i < len; i++) {
            button = buttons[i];
            results.push(button.addEventListener('click', function(e) {
              return input[0].focus();
            }));
          }
          return results;
        }
      };
    }
  ]);

}).call(this);
