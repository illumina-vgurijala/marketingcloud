/**
 * This file needs a description 
 * @class com.servicemax.client.automation.impl
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */

(function(){
	
	var automationImpl = SVMX.Package("com.servicemax.client.automation.impl");
	
	automationImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
		__constructor : function(){
			this.__base();
		},
		
		beforeInitialize : function(){ 
			com.servicemax.client.automation.automationagent.impl.init();
		},
		
		initialize : function(){},
		afterInitialize : function(){}
		
	}, {});
})();

// end of file