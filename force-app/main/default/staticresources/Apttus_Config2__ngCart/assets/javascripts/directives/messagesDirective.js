(function() {
  var Messages, MessagesCtrl;

  MessagesCtrl = function(messenger) {
    this.pageErrors = function() {
      return this.messenger.messages.page.error;
    };
    this.messenger = messenger;
    return this;
  };

  MessagesCtrl.$inject = ['messenger'];

  Messages = function(baseUrl) {
    return {
      templateUrl: baseUrl + '/templates/directives/messages.html',
      controller: MessagesCtrl,
      controllerAs: 'messages',
      bindToController: true
    };
  };

  Messages.$inject = ['baseUrl'];

  angular.module('ngCPQ').directive('messages', Messages);

}).call(this);
