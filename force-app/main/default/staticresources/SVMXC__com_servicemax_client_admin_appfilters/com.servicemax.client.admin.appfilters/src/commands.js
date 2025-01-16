
(function(){
    var impl = SVMX.Package("com.servicemax.client.admin.appfilters.commands");

	impl.init = function(){
		impl.Class("GetSupportedRecordTypes", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.GET_SUPPORTED_RECORD_TYPES"});
	        }
	    }, {});

		impl.Class("GetAllSourceObjects", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.GET_ALL_SOURCE_OBJECTS"});
	        }
	    }, {});

	    impl.Class("GetApplicationFilter", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.GET_APPLICATION_FILTER"});
	        }
	    }, {});

	    impl.Class("SaveApplicationFilter", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "APFT.SAVE_APPLICATION_FILTER"});
	        }
	    }, {});
	};
})();
