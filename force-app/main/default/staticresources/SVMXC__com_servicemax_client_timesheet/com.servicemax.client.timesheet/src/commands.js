
(function(){
    var impl = SVMX.Package("com.servicemax.client.timesheet.commands");

	impl.init = function(){

		impl.Class("GetWorkDetailOwnership", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "TIMESHEET.OPERATION.GetWorkDetailOwnership"});
	        }
	    }, {});
	    
		impl.Class("GetObjectMappingAndSVMXRules", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "TIMESHEET.OPERATION.GetObjectMappingAndSVMXRules"});
	        }
	    }, {});

		impl.Class("GetBusinessHours", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "TIMESHEET.OPERATION.GetBusinessHours"});
	        }
	    }, {});

	    impl.Class("GetAllTimezones", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "TIMESHEET.OPERATION.GetAllTimezones"});
	        }
	    }, {});

		 impl.Class("GetPriorPeriods", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "TIMESHEET.OPERATION.GetPriorPeriods"});
	        }
	    }, {});

	    impl.Class("GetAllTimesheetProcess", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "TIMESHEET.OPERATION.GetAllTimesheetProcess"});
	        }
	    }, {});

	    impl.Class("DeleteTimesheetProcess", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "TIMESHEET.OPERATION.DeleteTimesheetProcess"});
	        }
	    }, {});

	    impl.Class("SaveTimesheetConfiguration", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "TIMESHEET.OPERATION.SaveTimesheetConfiguration"});
	        }
	    }, {});

	    impl.Class("ChangeAppState", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            request.deliveryEngine.changeApplicationState(request.state);
	        }
	    }, {});

	    impl.Class("TimesheetResponder", com.servicemax.client.mvc.api.Responder, {

	        __constructor : function(callback){
	            this.__base();
	            this.__callback = callback;
	        },

	        result : function(data) {
				this.__callback.handler.call(this.__callback.context, data);
	        }
	    }, {});

	    impl.Class("ExecuteBatch", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "TIMESHEET.OPERATION.ExecuteBatch"});
	        }
	    }, {});
	};

})();
