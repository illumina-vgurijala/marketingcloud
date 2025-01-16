
(function(){

	var appImpl = SVMX.Package("com.servicemax.client.triggersetting.ui.desktop.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},
		
		beforeInitialize: function() {
			
        },

        initialize: function() {
        	com.servicemax.client.triggersetting.ui.desktop.api.init();
        }

	}, {
		instance : null
	});

})();