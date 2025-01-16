
(function(){

	var impl = SVMX.Package("com.servicemax.client.opt.impl");

	impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
			this._logger = SVMX.getLoggingService().getLogger("APP-IMPL");
		},

		beforeInitialize: function() {

        },

        initialize: function() {
        	com.servicemax.client.opt.commands.init();
        	com.servicemax.client.opt.responders.init();
        	com.servicemax.client.opt.engine.init();
        	com.servicemax.client.opt.console.init();
        },

        afterInitialize: function() {
        }

	}, {
		instance : null
	});

	impl.Class("APFTEngineEventBus", com.servicemax.client.lib.api.EventDispatcher, {
	       __constructor: function() {
	           this.__base();
	       },

	       triggerEvent: function(e) {
	           SVMX.getLoggingService().getLogger("APFTEngineEventBus").info("Trigger event : " + e.type);
	           return this.__base(e);
	       }

	   }, {});
})();