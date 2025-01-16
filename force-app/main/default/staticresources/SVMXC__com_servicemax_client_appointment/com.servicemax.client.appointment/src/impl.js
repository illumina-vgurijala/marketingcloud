
(function(){

	var impl = SVMX.Package("com.servicemax.client.appointment.impl");

	impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
			this._logger = SVMX.getLoggingService().getLogger("APP-IMPL");
		},

		beforeInitialize: function() {

        },

        initialize: function() {
        	com.servicemax.client.appointment.commands.init();
        	com.servicemax.client.appointment.responders.init();
        	com.servicemax.client.appointment.engine.init();
        },

        afterInitialize: function() {
        }

	}, {
		instance : null
	});

	impl.Class("APPOINTMENTEngineEventBus", com.servicemax.client.lib.api.EventDispatcher, {
	       __constructor: function() {
	           this.__base();
	       },

	       triggerEvent: function(e) {
	           SVMX.getLoggingService().getLogger("APPOINTMENTEngineEventBus").info("Trigger event : " + e.type);
	           return this.__base(e);
	       }

	   }, {});
})();