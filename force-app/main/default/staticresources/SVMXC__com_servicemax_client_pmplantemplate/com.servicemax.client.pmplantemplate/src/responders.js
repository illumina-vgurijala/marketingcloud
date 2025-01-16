
(function(){
    var impl = SVMX.Package("com.servicemax.client.pmplantemplate.responders");

	impl.init = function(){

	    impl.Class("GetFilterListResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null,
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onGetFilterListCompleted(data);
	        }
	    }, {});

	    impl.Class("GetTaskTemplateResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null,
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onGetTaskTemplateCompleted(data);
	        }
	    }, {});

	    impl.Class("GetActivityDateListResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null,
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onGetActivityDateListCompleted(data);
	        }
	    }, {});

	    impl.Class("GetPicklistValuesResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null,
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onGetPicklistValuesCompleted(data);
	        }
	    }, {});

	    impl.Class("SaveTemplateDataResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null,
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onSaveTemplateDataCompleted(data);
	        }
	    }, {});

	    impl.Class("SearchObjectResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null,
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onSearchObjectCompleted(data);
	        }
	    }, {});

	    impl.Class("GetRecordInfoResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null,
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onGetRecordInfoCompleted(data);
	        }
	    }, {});

	    impl.Class("GetTechnicalAttributeResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null,
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onGetTechnicalAttributeCompleted(data);
	        }
	    }, {});

	    impl.Class("GetSampleSchedulesResponder", com.servicemax.client.mvc.api.Responder, {
	    	__parent: null,
	        __constructor : function(engine){
	        	this.__base();
	        	this.__engine = engine;
	        },

	        result : function(data){
	        	this.__engine.onGetSampleSchedulesCompleted(data);
	        }
	    }, {});
	};

})();
