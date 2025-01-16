
(function(){

	var appImpl = SVMX.Package("com.servicemax.client.pmplan.ui.desktop.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},
		
		beforeInitialize: function() {
			com.servicemax.client.pmplan.ui.desktop.api.conditionrule.init();
			
        },

        initialize: function() {
        	com.servicemax.client.pmplan.ui.desktop.api.init();
        	com.servicemax.client.pmplan.ui.desktop.api.conditionrule.init();
        }

	}, {
		instance : null
	});

})();