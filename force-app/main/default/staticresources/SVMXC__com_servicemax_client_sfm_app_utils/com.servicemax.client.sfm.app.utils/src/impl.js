/**
 * This file needs a description 
 * @class com.servicemax.client.sfm.app.utils.impl
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */
//
(function(){
	
	var impl = SVMX.Package("com.servicemax.client.sfm.app.utils.impl");
	impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
		
		__constructor : function(){
			this.__base();
		},
		
		beforeInitialize : function(){
			com.servicemax.client.sfm.app.utils.pricingdefinition.init();
		},
		initialize : function(){},
		afterInitialize : function(){}
		
	}, {});
})();

// end of file