
(function(){

	var appImpl = SVMX.Package("com.servicemax.client.admin.appfilters.ui.desktop.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},

		beforeInitialize: function() {

        },

        initialize: function() {
        },

        afterInitialize: function() {
        	com.servicemax.client.admin.appfilters.ui.desktop.api.init();
        }

	}, {
		instance : null
	});

})();