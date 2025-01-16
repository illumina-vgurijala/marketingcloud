(function(){
    var impl = SVMX.Package("com.servicemax.client.sal.triggersetting.model.operations");

    var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("TRIGGERSETTING");

	impl.init = function(){
		var Module = com.servicemax.client.sal.triggersetting.model.impl.Module.instance;  
		
		impl.Class("GetObjectName", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetObjectName(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});

	    impl.Class("GetObjectTrigger", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetObjectTrigger(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});

	    impl.Class("SaveTriggerSetting", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrSaveTriggerSetting(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});
	};
})();