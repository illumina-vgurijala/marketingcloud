
(function(){

	var appImpl = SVMX.Package("com.servicemax.client.spareparts.ui.desktop.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},
		
		beforeInitialize: function() {
			
        },

        initialize: function() {
        	com.servicemax.client.spareparts.ui.desktop.api.init();
        	com.servicemax.client.spareparts.ui.desktop.downloadrule.init();
        }

	}, {
		instance : null
	});

})();