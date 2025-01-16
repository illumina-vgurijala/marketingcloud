
(function(){

	var appImpl = SVMX.Package("com.servicemax.client.entitlement.ui.desktop.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},
		
		beforeInitialize: function() {
			com.servicemax.client.entitlement.ui.desktop.api.entitlement.init();
			com.servicemax.client.entitlement.ui.desktop.api.setting.init();
			com.servicemax.client.entitlement.ui.desktop.api.entitlementSelection.init();
			com.servicemax.client.entitlement.ui.desktop.api.entitlementHistory.init();
        },

        initialize: function() {
        	com.servicemax.client.entitlement.ui.desktop.api.init();
        }

	}, {
		instance : null
	});

})();