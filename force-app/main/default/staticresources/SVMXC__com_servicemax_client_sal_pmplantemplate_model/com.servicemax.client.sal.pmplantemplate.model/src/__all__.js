// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.pmplantemplate.model\src\impl.js
(function(){

    var impl = SVMX.Package("com.servicemax.client.sal.pmplantemplate.model.impl");

    impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

        __constructor : function(){
            this.__base();
        },

        beforeInitialize: function() {

        },

        initialize: function() {
            com.servicemax.client.sal.pmplantemplate.model.operations.init();
        },

        afterInitialize: function() {

        }

    }, {});

    impl.Class("PlatformSpecifics", com.servicemax.client.lib.api.Object, {
        __constructor : function(){

        }


    }, {});
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.pmplantemplate.model\src\operations.js

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

