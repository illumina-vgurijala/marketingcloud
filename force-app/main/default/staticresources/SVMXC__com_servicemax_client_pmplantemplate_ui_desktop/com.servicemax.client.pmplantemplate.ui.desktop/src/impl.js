
(function(){

	var appImpl = SVMX.Package("com.servicemax.client.pmplantemplate.ui.desktop.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},

		beforeInitialize: function() {

        },

        initialize: function() {
        },

        afterInitialize: function() {
        	com.servicemax.client.pmplantemplate.ui.desktop.api.init();
        	com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.init();
        	com.servicemax.client.pmplantemplate.ui.desktop.scheduleWindow.init();
        	com.servicemax.client.pmplantemplate.ui.desktop.conditionRuleCriteriaBased.init();
        }

	}, {
		instance : null
	});

})();