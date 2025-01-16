
(function(){

	var appImpl = SVMX.Package("com.servicemax.client.timesheet.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
			this._logger = SVMX.getLoggingService().getLogger("APP-IMPL");
		},

		beforeInitialize: function() {
			com.servicemax.client.timesheet.commands.init();
			com.servicemax.client.timesheet.engine.init();
        }

	}, {
		instance : null
	});

	appImpl.Class("TimesheetEngineEventBus", com.servicemax.client.lib.api.EventDispatcher, {

       __constructor: function() {
           this.__base();
       },

       triggerEvent: function(e) {
           SVMX.getLoggingService().getLogger("QBMEngineEventBus").info("Trigger event : " + e.type);
           return this.__base(e);
       }
   }, {});
})();