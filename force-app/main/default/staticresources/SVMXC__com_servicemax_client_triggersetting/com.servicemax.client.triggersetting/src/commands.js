
(function(){
    var impl = SVMX.Package("com.servicemax.client.triggersetting.commands");

	impl.init = function(){

	    impl.Class("ChangeAppState", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            request.deliveryEngine.changeApplicationState(request.state);
	        }
	    }, {});

	    impl.Class("GetObjectName", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "TRIGGERSETTING.GET_OBJECT_NAME"});
	        }
	    }, {});

	    impl.Class("GetObjectTrigger", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "TRIGGERSETTING.GET_OBJECT_TRIGGER"});
	        }
	    }, {});

	    impl.Class("SaveTriggerSetting", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "TRIGGERSETTING.SAVE_TRIGGERSETTING"});
	        }
	    }, {});
	};

})();
