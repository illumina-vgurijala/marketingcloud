
(function(){
    var impl = SVMX.Package("com.servicemax.client.appointment.commands");

	impl.init = function(){

	    impl.Class("ChangeAppState", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            request.deliveryEngine.changeApplicationState(request.state);
	        }
	    }, {});
	    impl.Class("GetAppointmentSettings", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APPOINTMENT.GET_APPOINTMENT_SETTINGS"});
	        }
	    }, {});
	    impl.Class("GetWorkDetails", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APPOINTMENT.GET_WORKDETAILS"});
	        }
	    }, {});
	    impl.Class("BookAppointment", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APPOINTMENT.BOOK_APPOINTMENT"});
	        }
	    }, {});
	    /*impl.Class("StartOptimaxJob", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APPOINTMENT.START_OPTIMAX_JOB"});
	        }
	    }, {});*/
	    impl.Class("GetOfferAppointments", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APPOINTMENT.GET_OFFER_APPOINTMENTS"});
	        }
	    }, {});
	};

})();
