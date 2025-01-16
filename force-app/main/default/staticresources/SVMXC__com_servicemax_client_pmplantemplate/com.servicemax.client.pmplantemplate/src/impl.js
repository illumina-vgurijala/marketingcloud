
(function(){

	var impl = SVMX.Package("com.servicemax.client.pmplantemplate.impl");

	impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
			this._logger = SVMX.getLoggingService().getLogger("APP-IMPL");
		},

		beforeInitialize: function() {

        },

        initialize: function() {
        	com.servicemax.client.pmplantemplate.commands.init();
        	com.servicemax.client.pmplantemplate.responders.init();
        	com.servicemax.client.pmplantemplate.engine.init();
        	com.servicemax.client.pmplantemplate.console.init();
        },

        afterInitialize: function() {
        }

	}, {
		instance : null
	});

	impl.Class("PMPLANEngineEventBus", com.servicemax.client.lib.api.EventDispatcher, {
	       __constructor: function() {
	           this.__base();
	       },

	       triggerEvent: function(e) {
	           SVMX.getLoggingService().getLogger("PMPLANEngineEventBus").info("Trigger event : " + e.type);
	           return this.__base(e);
	       }

	   }, {});
})();