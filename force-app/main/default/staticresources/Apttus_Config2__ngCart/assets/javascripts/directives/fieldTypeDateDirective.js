
/*
  Date fields should be displayed based on user locale, available as angular constants. 
  Editable date field should have date calendar widget attached to it. 
  Service filter function, that uses user locale should be used to format 
  date fields for display and while submitting to server.
  
  
  local
  constants
 */

(function() {
  var DateField, dateFieldCtrl;

  dateFieldCtrl = function(ngCPQLocale, Pikaday, moment) {
    var vm;
    return vm = this;
  };

  dateFieldCtrl.$inject = ['ngCPQLocale', 'Pikaday', 'moment'];

  DateField = function() {
    var directive;
    directive = {
      scope: {
        dateStart: '=',
        dateEnd: '='
      },
      template: '<div class="">1/1/15</div>',
      controller: dateFieldCtrl,
      controllerAs: 'date',
      bindToController: true
    };
    return directive;
  };

  angular.module('ngCPQ').directive('dateField', DateField);

}).call(this);
