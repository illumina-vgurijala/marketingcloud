
(function(){
    var impl = SVMX.Package("com.servicemax.client.opt.commands");

	impl.init = function(){
		impl.Class("processLatestRun", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.GET_PROCESS_LATEST_RUN"});
	        }
	    }, {});
		impl.Class("purgeLatestRun", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.GET_PURGE_LATEST_RUN"});
	        }
	    }, {});
		impl.Class("getJobListForPurge", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.GET_JOB_LIST_FOR_PURGE"});
	        }
	    }, {});
		impl.Class("getJobListForExecution", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.GET_JOB_LIST_FOR_EXECUTION"});
	        }
	    }, {});
		impl.Class("purgeSelectedRuns", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.GET_PURGE_SELECTED_RUNS"});
	        }
	    }, {});
		impl.Class("executionSelectedRuns", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.GET_EXECUTION_SELECTED_RUNS"});
	        }
	    }, {});
		impl.Class("loadDispatchProcessNames", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.LOAD_DISPATCH_PROCESS_NAME"});
	        }
	    }, {});
		impl.Class("saveOptConfiguration", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.SAVE_OPT_CONFIGURATION"});
	        }
	    }, {});
		
	};
	

})();
