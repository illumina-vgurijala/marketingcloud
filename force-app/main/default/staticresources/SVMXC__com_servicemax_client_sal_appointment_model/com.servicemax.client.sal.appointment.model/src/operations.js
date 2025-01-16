
(function(){
    var impl = SVMX.Package("com.servicemax.client.sal.appointment.model.operations");
	var APPOINTMENT ;
	
	impl.init = function(){
		
		APPOINTMENT = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("APPOINTMENT");
	
    
		var Module = com.servicemax.client.sal.appointment.model.impl.Module.instance;
		
		impl.Class("GetAppointmentSettings", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetAPPOINTMENTSETTINGS(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {}); 

	    impl.Class("GetWorkDetails", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetWorkOrderDetailInfo(request, function(result, evt){
	                    result = result || {};	                    
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});

	    impl.Class("BookAppointment", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrBookAppointment(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});
		

	    /*impl.Class("StartOptimaxJob", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrStartOptimaxJob(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});*/

	    impl.Class("GetOfferAppointments", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetOfferAppointments(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});  

		
	};
})();