
(function(){
    var impl = SVMX.Package("com.servicemax.client.sal.pmplantemplate.model.operations");

	impl.init = function(){

		var PmPlanJsr=window.SVMXJsr;
	    impl.Class("GetFilterList", com.servicemax.client.mvc.api.Operation, {

	            __constructor: function() {
	                this.__base();
	            },

	            performAsync: function(request, responder) {
	            	var data = PmPlanJsr.JsrGetFilterList(request, function(data){
	            		responder.result(SVMX.toObject(data));	
	            	}, this);
	            }
	    }, {});

	    impl.Class("GetTaskTemplate", com.servicemax.client.mvc.api.Operation, {

	            __constructor: function() {
	                this.__base();
	            },

	            performAsync: function(request, responder) {
	            	var data = PmPlanJsr.JsrGetTaskTemplate(request, function(data){
	            		responder.result(SVMX.toObject(data));	
	            	}, this);
	            }
	    }, {});

	    impl.Class("GetActivityDateList", com.servicemax.client.mvc.api.Operation, {

	            __constructor: function() {
	                this.__base();
	            },

	            performAsync: function(request, responder) {
	            	var data = PmPlanJsr.JsrGetActivityDateList(request, function(data){
	            		responder.result(SVMX.toObject(data));	
	            	}, this);
	            }
	    }, {});

	    impl.Class("GetPicklistValues", com.servicemax.client.mvc.api.Operation, {

	            __constructor: function() {
	                this.__base();
	            },

	            performAsync: function(request, responder) {
	            	var data = PmPlanJsr.JsrGetPicklistValues(request, function(data){
	            		responder.result(SVMX.toObject(data));	
	            	}, this);
	            }
	    }, {});

	    impl.Class("SaveTemplateData", com.servicemax.client.mvc.api.Operation, {

	            __constructor: function() {
	                this.__base();
	            },

	            performAsync: function(request, responder) {
	            	var data = PmPlanJsr.JsrSaveTemplateData(request, function(data){
	            		responder.result(SVMX.toObject(data));	
	            	}, this);
	            }
	    }, {});

	    impl.Class("SearchObject", com.servicemax.client.mvc.api.Operation, {

	            __constructor: function() {
	                this.__base();
	            },

	            performAsync: function(request, responder) {
	            	var data = PmPlanJsr.JsrSearchObject(request, function(data){
	            		responder.result(SVMX.toObject(data));	
	            	}, this);
	            }
	    }, {});

	    impl.Class("GetRecordInfo", com.servicemax.client.mvc.api.Operation, {

	            __constructor: function() {
	                this.__base();
	            },

	            performAsync: function(request, responder) {
	            	var data = PmPlanJsr.JsrGetRecordInfo(request, function(data){
	            		responder.result(SVMX.toObject(data));	
	            	}, this);
	            }
	    }, {});

	    impl.Class("GetTechnicalAttribute", com.servicemax.client.mvc.api.Operation, {

	            __constructor: function() {
	                this.__base();
	            },

	            performAsync: function(request, responder) {
	            	var data = PmPlanJsr.JsrGetTechnicalAttribute(request, function(data){
	            		responder.result(SVMX.toObject(data));	
	            	}, this);
	            }
	    }, {});

	    impl.Class("GetSampleSchedules", com.servicemax.client.mvc.api.Operation, {

	            __constructor: function() {
	                this.__base();
	            },

	            performAsync: function(request, responder) {
	            	var data = PmPlanJsr.JsrGetSampleSchedules(request, function(data){
	            		responder.result(SVMX.toObject(data));	
	            	}, this);
	            }
	    }, {});
	};
})();