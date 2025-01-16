(function(){
    var impl = SVMX.Package("com.servicemax.client.sal.spareparts.model.operations");

    var SPAREPARTS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPAREPARTS");

	impl.init = function(){
		var Module = com.servicemax.client.sal.spareparts.model.impl.Module.instance;  
		
		impl.Class("GetProfileData", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetProfileData(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});

	    impl.Class("GetSparePartConfig", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetSparePartConfig(request, function(result, evt){
	                    result = result || {};

	                    if(result.listproductstockstatus != null){
	                    	result.listproductstockstatus.forEach(function(obj){
	                    		obj.isUsed = false;
	                    	});
	                    }
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});

	    impl.Class("SaveSparePartConfig", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrSaveSparePartConfig(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});
	};
})();