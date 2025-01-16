
(function(){
    var impl = SVMX.Package("com.servicemax.client.admin.appfilters.responders");

	impl.init = function(){

		/**
		 * A do nothing responder, our caller will handle the data response directly from the event.
		 * Use this if you want a more generic and universal way of responding from the engine.
		 */
		impl.Class("GetSupportedRecordTypesResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onGetSupportedRecordTypesCompleted(data);
	        }
	    }, {});

	    impl.Class("GetAllSourceObjectsResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onGetAllSourceObjectsCompleted(data);
	        }
	    }, {});

	    impl.Class("GetApplicationFilterResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onGetApplicationFilterCompleted(data);
	        }
	    }, {});

	    impl.Class("SaveApplicationFilterResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onSaveApplicationFilterCompleted(data);
	        }
	    }, {});
	};

})();
