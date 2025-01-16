/**
 * This file needs a description 
 * @class com.servicemax.client.sfmconsole.ui.components.api
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */

(function(){
	
	var compsApi = SVMX.Package("com.servicemax.client.sfmconsole.ui.components.api");
	
	compsApi.Class("ViewComposite", com.servicemax.client.lib.api.EventDispatcher, {
		__constructor : function(){
			this.__base();
		}
	}, {});
	
	compsApi.Class("ViewContainer", compsApi.ViewComposite, {
		__constructor : function(){
			this.__base();
		}
	}, {});
	
	compsApi.Class("ViewPlan", compsApi.ViewContainer, {
		__constructor : function(){
			this.__base();
		}
	}, {});
	
	compsApi.Class("ViewModel", com.servicemax.client.lib.api.EventDispatcher, {
		__constructor : function(){
			this.__base();
		}
	}, {});
	
	compsApi.Class("ViewModelNode", com.servicemax.client.lib.api.EventDispatcher, {
		__constructor : function(){
			this.__base();
		}
	}, {});
	
	
	compsApi.Class("ViewEngine", com.servicemax.client.lib.api.Object, {
		__constructor : function(){
			this.__base();
		}
	}, {});
})();

// end of file