// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.pmplan.model\src\impl.js
(function(){

    var impl = SVMX.Package("com.servicemax.client.sal.pmplan.model.impl");

    impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

        __constructor : function(){
            this.__base();
            this.__self.instance = this;
        },

        beforeInitialize: function() {
            com.servicemax.client.sal.pmplan.model.operations.init();
        },

        initialize: function() {
            // check if jsr should be used, only valid when running from web
            var useJsr = SVMX.getClient().getApplicationParameter("svmx-sfm-sal-model-use-jsr");
            if(useJsr && useJsr === true){
                this.useJsr = true;
                //this.__logger.info("JSR is enabled. Will use this for server communication.");
            }else{
                this.useJsr = false;
            }
        },

        afterInitialize: function() {
        }
        
    }, {});


})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.pmplan.model\src\operations.js

(function(){
    var impl = SVMX.Package("com.servicemax.client.sal.pmplan.model.operations");

    var PMPLAN = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("PMPLAN");

	impl.init = function(){
		var Module = com.servicemax.client.sal.pmplan.model.impl.Module.instance;  
		
		impl.Class("GetPMPlanData", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetPMPlanData(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {}); 

	    impl.Class("GetPMTemplateData", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetPMTemplateDetails(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});  

	    impl.Class("SearchObject", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrSearchObject(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});   

	    impl.Class("SavePMPlanData", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrSavePMPlanData(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {}); 

	    impl.Class("GetCoverageScheduleData", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetCoverageScheduleData(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {}); 

	    impl.Class("GetCoverageTechnicalAtt", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrGetCoverageTechnicalAtt(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});   

	    impl.Class("ValidateExpression", com.servicemax.client.mvc.api.Operation, {
	         __constructor: function() { this.__base(); },

	        performAsync: function(request, responder) {
	            if(Module.useJsr){
	                SVMXJsr.JsrValidateExpression(request, function(result, evt){
	                    result = result || {};
	                    responder.result(result);
	                }, this); 
	            }
	        }
	    }, {});  
	};
})();

