
(function(){

	var appImpl = SVMX.Package("com.servicemax.client.opt.ui.desktop.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},

		beforeInitialize: function() {
			com.servicemax.client.opt.ui.desktop.api.setting.init();
			com.servicemax.client.opt.ui.desktop.api.execution.init();
			com.servicemax.client.opt.ui.desktop.api.purge.init();
        },

        initialize: function() {
        },

        afterInitialize: function() {
        	com.servicemax.client.opt.ui.desktop.api.init();
        }

	}, {
		instance : null
	});

})();