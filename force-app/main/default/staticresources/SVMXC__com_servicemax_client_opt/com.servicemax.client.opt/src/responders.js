
(function(){
    var impl = SVMX.Package("com.servicemax.client.opt.responders");

	impl.init = function(){

		/**
		 * A do nothing responder, our caller will handle the data response directly from the event.
		 * Use this if you want a more generic and universal way of responding from the engine.
		 */
		impl.Class("processLatestRun", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onprocessLatestRunCompleted(data);
	        }
	    }, {});
		
		impl.Class("purgeLatestRun", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onpurgeLatestRunCompleted(data);
	        }
	    }, {});
		impl.Class("getJobListForPurge", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.ongetJobListForPurgeCompleted(data);
	        }
	    }, {});
		impl.Class("getJobListForExecution", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.ongetJobListForExecutionCompleted(data);
	        }
	    }, {});
		impl.Class("purgeSelectedRuns", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onpurgeSelectedRunsCompleted(data);
	        }
	    }, {});
		impl.Class("executionSelectedRuns", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onexecutionSelectedRunsCompleted(data);
	        }
	    }, {});
		impl.Class("loadDispatchProcessNames", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onloadDispatchProcessNamesCompleted(data);
	        }
	    }, {});
		impl.Class("saveOptConfiguration", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null, // name as __engine makes more sense but __parent is convention
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onsaveOptConfigurationCompleted(data);
	        }
	    }, {});
		
	};

})();
