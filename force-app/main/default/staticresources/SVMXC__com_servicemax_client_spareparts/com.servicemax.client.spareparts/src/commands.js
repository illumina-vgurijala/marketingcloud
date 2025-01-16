
(function(){
    var impl = SVMX.Package("com.servicemax.client.spareparts.commands");

	impl.init = function(){

	    impl.Class("ChangeAppState", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            request.deliveryEngine.changeApplicationState(request.state);
	        }
	    }, {});

	    impl.Class("GetProfileData", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "SPAREPARTS.GET_PROFILE_DATA"});
	        }
	    }, {});

	    impl.Class("GetSparePartConfig", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "SPAREPARTS.GET_SPAREPART_CONFIG"});
	        }
	    }, {});

	    impl.Class("SaveSparePartConfig", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "SPAREPARTS.SAVE_SPAREPART_CONFIG"});
	        }
	    }, {});
	};

})();
