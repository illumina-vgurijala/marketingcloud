/**
 * This file needs a description
 * @class com.servicemax.client.sfwdelivery.commands
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
	var sfwCommands = SVMX.Package("com.servicemax.client.sfwdelivery.commands");

	sfwCommands.init = function(){

		sfwCommands.Class("GetWizardInfo", com.servicemax.client.mvc.api.Command, {

		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this._executeOperationAsync(request, responder, {operationId : "SFWDELIVERY.GET_WIZARD_INFO"});
		}
	}, {});

};
})();