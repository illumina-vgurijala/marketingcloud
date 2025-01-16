
(function(){

	var impl = SVMX.Package("com.servicemax.client.triggersetting.impl");

	impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
			this._logger = SVMX.getLoggingService().getLogger("APP-IMPL");
		},

		beforeInitialize: function() {

        },

        initialize: function() {
        	com.servicemax.client.triggersetting.commands.init();
        	com.servicemax.client.triggersetting.responders.init();
        	com.servicemax.client.triggersetting.engine.init();
        },

        afterInitialize: function() {
        }

	}, {
		instance : null
	});

	impl.Class("TRIGGERSETTINGEngineEventBus", com.servicemax.client.lib.api.EventDispatcher, {
	       __constructor: function() {
	           this.__base();
	       },

	       triggerEvent: function(e) {
	           SVMX.getLoggingService().getLogger("TRIGGERSETTINGEngineEventBus").info("Trigger event : " + e.type);
	           return this.__base(e);
	       }

	   }, {});
})();