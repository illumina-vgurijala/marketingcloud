(function() {
  var Messenger;

  Messenger = function(_) {
    this.messages = {
      page: {
        error: [],
        info: [],
        warning: []
      },
      prompt: []
    };
    this.notify = function(newMessages) {
      var newPrompts;
      newPrompts = _.remove(newMessages.error, function(msg) {
        return msg.IsPrompt__c && !msg.Ignored__c;
      });
      this.messages.prompt = this.messages.prompt.concat(newPrompts);
      this.messages.page.error = newMessages.error;
      this.messages.page.info = newMessages.info;
      return this.messages.page.warning = newMessages.warning;
    };
    return this;
  };

  Messenger.$inject = ['lodash'];

  angular.module('ngCPQ').service('messenger', Messenger);

}).call(this);
